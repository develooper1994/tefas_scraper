#!/usr/bin/env python3
"""
TEFAS Scraper - MCP Server & CLI Tool
Exposes TEFAS scraping functionality via MCP and command-line interface.

Usage:
  # As MCP Server (stdio)
  python mcp_server.py
  
  # As CLI Tool
  python mcp_server.py --cli analyze --fund-type YAT --fund-code TTE --price-range 1M
  python mcp_server.py --cli history-info --fund-code TTE --start-date 2024-01-01 --end-date 2024-01-31
"""

import json
import argparse
import sys
import os
from datetime import datetime, timedelta
from dateutil.relativedelta import relativedelta
import requests
import urllib3
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

# Determine TLS verification setting from environment (default: True)
VERIFY_TLS_DEFAULT = os.getenv('TEFAS_VERIFY_TLS', 'true').lower() in ('1', 'true', 'yes')
if not VERIFY_TLS_DEFAULT:
    # Only disable warnings if TLS verification is explicitly disabled
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


# ============================================================================
# TEFAS Scraper Core Class
# ============================================================================

class TefasScraper:
    """Core TEFAS scraper implementation"""
    
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "X-Requested-With": "XMLHttpRequest",
            "Origin": "https://www.tefas.gov.tr"
        })
        self.base_url = "https://www.tefas.gov.tr"

        # TLS verification controlled via TEFAS_VERIFY_TLS environment variable (default: true)
        self.verify_tls = os.getenv('TEFAS_VERIFY_TLS', 'true').lower() in ('1', 'true', 'yes')
        self.session.verify = self.verify_tls

        # Configure retry/backoff for transient errors
        max_retries = int(os.getenv('TEFAS_MAX_RETRIES', '3'))
        backoff = float(os.getenv('TEFAS_BACKOFF_FACTOR', '0.3'))
        status_forcelist = (429, 500, 502, 503, 504)
        retry = Retry(
            total=max_retries,
            backoff_factor=backoff,
            status_forcelist=status_forcelist,
            allowed_methods=["GET", "POST"]
        )
        adapter = HTTPAdapter(max_retries=retry)
        self.session.mount("https://", adapter)
        self.session.mount("http://", adapter)

    def _ensure_session(self, referer_path="/FonKarsilastirma.aspx"):
        """Ensures session cookies are active by visiting a main page"""
        url = f"{self.base_url}{referer_path}"
        try:
            self.session.get(url, verify=self.verify_tls, timeout=10)
            self.session.headers.update({"Referer": url})
        except Exception as e:
            print(f"Warning: Failed to establish session: {e}", file=sys.stderr)

    def _make_request(self, url, data=None):
        try:
            if data:
                response = self.session.post(url, data=data, timeout=30, verify=self.verify_tls)
            else:
                response = self.session.get(url, timeout=15, verify=self.verify_tls)
            response.raise_for_status()
            
            # Debug: Check if empty
            if not response.text.strip():
                return {"data": [], "info": "Empty response from server"}
                
            return response.json()
        except requests.exceptions.RequestException as e:
            raise Exception(f"Request failed: {e}")
        except json.JSONDecodeError:
            content_preview = response.text[:500].replace('\n', ' ').replace('\r', '')
            if "<html" in response.text.lower() or "<!doctype" in response.text.lower():
                raise Exception(f"Received an HTML response (WAF block). Preview: {content_preview}")
            else:
                raise Exception(f"Failed to decode JSON response. Preview: {content_preview}")

    def get_fund_analysis(self, fund_type: str, fund_code: str, start_date: str = None, end_date: str = None, price_range: str = None):
        """Fetches comprehensive fund analysis data.
                Date format: DD.MM.YYYY
        """
        self._ensure_session("/FonAnaliz.aspx")
        
        current_start_date = start_date
        current_end_date = end_date

        if price_range:
            if not current_end_date:
                end_date_dt = datetime.today()
            else:
                try:
                    end_date_dt = datetime.strptime(current_end_date, "%d.%m.%Y")
                except ValueError:
                    raise ValueError("Invalid end_date format. Please use DD.MM.YYYY.")

            range_map = {
                "1H": timedelta(weeks=1), "1M": relativedelta(months=1),
                "3M": relativedelta(months=3), "6M": relativedelta(months=6),
                "1Y": relativedelta(years=1), "3Y": relativedelta(years=3),
                "5Y": relativedelta(years=5)
            }
            if price_range in range_map:
                start_date_dt = end_date_dt - range_map[price_range]
            elif price_range == "YTD":
                start_date_dt = datetime(end_date_dt.year, 1, 1)
            else:
                raise ValueError(f"Invalid price_range value: {price_range}")

            current_start_date = start_date_dt.strftime("%d.%m.%Y")
            current_end_date = end_date_dt.strftime("%d.%m.%Y")

        elif current_start_date and not current_end_date:
            current_end_date = datetime.today().strftime("%d.%m.%Y")

        if not current_start_date or not current_end_date:
            raise ValueError("Start and end dates must be provided or calculable from price_range.")

        url = f"{self.base_url}/api/DB/GetAllFundAnalyzeData"
        data = {"fonTip": fund_type, "fonKod": fund_code, "bastarih": current_start_date, "bittarih": current_end_date}
        return self._make_request(url, data)

    def get_history(self, endpoint, fund_code, start_date, end_date, fund_type="ALL"):
        """Historical data ('BindHistoryInfo' or 'BindHistoryAllocation').
            Date format: YYYY-MM-DD
        """
        self._ensure_session("/TarihselVeriler.aspx")
        
        try:
            datetime.strptime(start_date, '%Y-%m-%d')
            datetime.strptime(end_date, '%Y-%m-%d')
        except ValueError:
            raise ValueError("Invalid date format. Please use YYYY-MM-DD.")
            
        api_url = f"{self.base_url}/api/DB/{endpoint}"
        data = {"fontip": fund_type, "bastarih": start_date, "bittarih": end_date, "fonkod": fund_code}
        return self._make_request(api_url, data)

    def compare_returns(self, fund_type="YAT", periods="1,1,1,1,1,1,1"):
        """Compares fund returns."""
        self._ensure_session("/FonKarsilastirma.aspx")
        url = f"{self.base_url}/api/DB/BindComparisonFundReturns"
        data = {
            "calismatipi": "2", "fontip": fund_type, "sfontur": "", "kurucukod": "", 
            "fongrup": "", "bastarih": "Başlangıç", "bittarih": "Bitiş", 
            "fonturkod": "", "fonunvantip": "", "strperiod": periods, "islemdurum": "1"
        }
        return self._make_request(url, data)

    def compare_sizes(self, fund_type="YAT", start_date=None, end_date=None):
        """Compares fund sizes."""
        self._ensure_session("/FonKarsilastirma.aspx")
        if not end_date:
            end_date = datetime.today().strftime("%d.%m.%Y")
        if not start_date:
            start_date = (datetime.today() - relativedelta(months=1)).strftime("%d.%m.%Y")
            
        url = f"{self.base_url}/api/DB/BindComparisonFundSizes"
        data = {
            "calismatipi": "2", "fontip": fund_type, "sfontur": "", "kurucukod": "", 
            "fongrup": "", "bastarih": start_date, "bittarih": end_date, 
            "fonturkod": "", "fonunvantip": "", "strperiod": "1,1,1,1,1,1,1", "islemdurum": "1"
        }
        return self._make_request(url, data)

    def compare_fees(self, fund_type="YAT"):
        """Compares fund management fees."""
        self._ensure_session("/FonKarsilastirma.aspx")
        url = f"{self.base_url}/api/DB/BindComparisonManagementFees"
        data = {
            "calismatipi": "2", "fontip": fund_type, "sfontur": "", "kurucukod": "", 
            "fongrup": "", "bastarih": "Başlangıç", "bittarih": "Bitiş", 
            "fonturkod": "", "fonunvantip": "", "strperiod": "1,1,1,1,1,1,1", "islemdurum": "1"
        }
        return self._make_request(url, data)


# ============================================================================
# MCP Server Implementation
# ============================================================================

def create_mcp_server():
    """Create and configure the MCP server"""
    from fastmcp import FastMCP
    
    mcp = FastMCP("tefas-scraper", dependencies=["requests", "python-dateutil"])
    scraper = TefasScraper()

    @mcp.tool()
    def analyze_fund(
        fund_type: str,
        fund_code: str,
        start_date: str = None,
        end_date: str = None,
        price_range: str = None
    ) -> str:
        """
        Fetches comprehensive fund analysis data from TEFAS.
        
        Args:
            fund_type: Fund type (e.g., YAT, EMK)
            fund_code: Fund code (e.g., TLY, AFA, TTE)
            start_date: Start date in DD.MM.YYYY format (optional)
            end_date: End date in DD.MM.YYYY format (optional)
            price_range: Price range (1H, 1M, 3M, 6M, YTD, 1Y, 3Y, 5Y) - optional
        """
        try:
            result = scraper.get_fund_analysis(fund_type, fund_code, start_date, end_date, price_range)
            return json.dumps(result, ensure_ascii=False, indent=2)
        except Exception as e:
            return json.dumps({"error": str(e)}, ensure_ascii=False)

    @mcp.tool()
    def get_fund_history_info(
        fund_code: str,
        start_date: str,
        end_date: str,
        fund_type: str = "ALL"
    ) -> str:
        """
        Fetches historical binding information for a TEFAS fund.
        
        Args:
            fund_code: TEFAS fund code (e.g., 'AFA', 'TCD', 'TTE')
            start_date: Start date in YYYY-MM-DD format
            end_date: End date in YYYY-MM-DD format
            fund_type: Fund type (default: 'ALL')
        """
        try:
            result = scraper.get_history("BindHistoryInfo", fund_code, start_date, end_date, fund_type)
            return json.dumps(result, ensure_ascii=False, indent=2)
        except Exception as e:
            return json.dumps({"error": str(e)}, ensure_ascii=False)

    @mcp.tool()
    def get_fund_allocation_history(
        fund_code: str,
        start_date: str,
        end_date: str,
        fund_type: str = "ALL"
    ) -> str:
        """
        Fetches historical portfolio allocation data for a TEFAS fund.
        
        Args:
            fund_code: TEFAS fund code
            start_date: Start date in YYYY-MM-DD format
            end_date: End date in YYYY-MM-DD format
            fund_type: Fund type (default: 'ALL')
        """
        try:
            result = scraper.get_history("BindHistoryAllocation", fund_code, start_date, end_date, fund_type)
            return json.dumps(result, ensure_ascii=False, indent=2)
        except Exception as e:
            return json.dumps({"error": str(e)}, ensure_ascii=False)

    @mcp.tool()
    def compare_fund_returns(
        fund_type: str = "YAT",
        periods: str = "1,1,1,1,1,1,1"
    ) -> str:
        """
        Compares fund returns across different time periods.
        
        Args:
            fund_type: Fund type (YAT or EMK)
            periods: Comma-separated 1s/0s for (1M,3M,6M,1Y,3Y,5Y,YTD)
        """
        try:
            result = scraper.compare_returns(fund_type, periods)
            return json.dumps(result, ensure_ascii=False, indent=2)
        except Exception as e:
            return json.dumps({"error": str(e)}, ensure_ascii=False)

    @mcp.tool()
    def compare_fund_sizes(
        fund_type: str = "YAT",
        start_date: str = None,
        end_date: str = None
    ) -> str:
        """
        Compares fund portfolio sizes and share counts.
        
        Args:
            fund_type: Fund type (YAT or EMK)
            start_date: Start date in DD.MM.YYYY format (default: 1 month ago)
            end_date: End date in DD.MM.YYYY format (default: today)
        """
        try:
            result = scraper.compare_sizes(fund_type, start_date, end_date)
            return json.dumps(result, ensure_ascii=False, indent=2)
        except Exception as e:
            return json.dumps({"error": str(e)}, ensure_ascii=False)

    @mcp.tool()
    def compare_fund_fees(
        fund_type: str = "YAT"
    ) -> str:
        """
        Compares fund management fees and expense ratios.
        
        Args:
            fund_type: Fund type (YAT or EMK)
        """
        try:
            result = scraper.compare_fees(fund_type)
            return json.dumps(result, ensure_ascii=False, indent=2)
        except Exception as e:
            return json.dumps({"error": str(e)}, ensure_ascii=False)
    
    return mcp


# ============================================================================
# CLI Implementation
# ============================================================================

def cli_main():
    """CLI entry point"""
    parser = argparse.ArgumentParser(
        description='TEFAS Scraper - Get fund data from TEFAS',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Analyze fund with price range
  %(prog)s --cli analyze --fund-type YAT --fund-code TTE --price-range 1M
  
  # Get history info
  %(prog)s --cli history-info --fund-code TTE --start-date 2024-01-01 --end-date 2024-01-31

  # Compare returns for all YAT funds
  %(prog)s --cli compare-returns --fund-type YAT --periods 0,0,0,1,0,0,0 --pretty
  
  # Get allocation history
  %(prog)s --cli history-allocation --fund-code TTE --start-date 2024-01-01 --end-date 2024-01-31

  # Compare fund sizes
  %(prog)s --cli compare-sizes --start-date 01.01.2024 --end-date 31.01.2024 --pretty
        """
    )
    
    parser.add_argument('--cli', choices=['analyze', 'history-info', 'history-allocation', 
                                         'compare-returns', 'compare-sizes', 'compare-fees'],
                        help='CLI command to execute')
    parser.add_argument('--fund-type', help='Fund type (e.g., YAT, EMK)')
    parser.add_argument('--fund-code', help='Fund code (e.g., TTE, AFA, TLY)')
    parser.add_argument('--start-date', help='Start date (YYYY-MM-DD or DD.MM.YYYY)')
    parser.add_argument('--end-date', help='End date (YYYY-MM-DD or DD.MM.YYYY)')
    parser.add_argument('--price-range', help='Price range (1H, 1M, 3M, 6M, YTD, 1Y, 3Y, 5Y)')
    parser.add_argument('--periods', help='Comma-separated periods for comparison (e.g., 1,1,1,1,1,1,1)')
    parser.add_argument('--pretty', action='store_true', help='Pretty print JSON output')
    
    args = parser.parse_args()
    
    if not args.cli:
        # No CLI flag, run as MCP server
        return None
    
    scraper = TefasScraper()
    
    try:
        if args.cli == 'analyze':
            if not args.fund_type or not args.fund_code:
                parser.error("--fund-type and --fund-code are required for analyze")
            
            result = scraper.get_fund_analysis(
                args.fund_type,
                args.fund_code,
                args.start_date,
                args.end_date,
                args.price_range
            )
        
        elif args.cli == 'history-info':
            if not args.fund_code or not args.start_date or not args.end_date:
                parser.error("--fund-code, --start-date, and --end-date are required for history-info")
            
            result = scraper.get_history(
                "BindHistoryInfo",
                args.fund_code,
                args.start_date,
                args.end_date,
                args.fund_type or "ALL"
            )
        
        elif args.cli == 'history-allocation':
            if not args.fund_code or not args.start_date or not args.end_date:
                parser.error("--fund-code, --start-date, and --end-date are required for history-allocation")
            
            result = scraper.get_history(
                "BindHistoryAllocation",
                args.fund_code,
                args.start_date,
                args.end_date,
                args.fund_type or "ALL"
            )
        
        elif args.cli == 'compare-returns':
            periods = args.periods
            if not periods and args.price_range:
                # Map price_range to periods bitmask (1M,3M,6M,1Y,3Y,5Y,YTD)
                mapping = {
                    "1M": "1,0,0,0,0,0,0", "3M": "0,1,0,0,0,0,0", "6M": "0,0,1,0,0,0,0",
                    "1Y": "0,0,0,1,0,0,0", "3Y": "0,0,0,0,1,0,0", "5Y": "0,0,0,0,0,1,0",
                    "YTD": "0,0,0,0,0,0,1"
                }
                periods = mapping.get(args.price_range, "1,1,1,1,1,1,1")
            
            result = scraper.compare_returns(
                args.fund_type or "YAT",
                periods or "1,1,1,1,1,1,1"
            )

        elif args.cli == 'compare-sizes':
            result = scraper.compare_sizes(
                args.fund_type or "YAT",
                args.start_date,
                args.end_date
            )

        elif args.cli == 'compare-fees':
            result = scraper.compare_fees(
                args.fund_type or "YAT"
            )
        
        # Print result
        indent = 2 if args.pretty else None
        try:
            print(json.dumps(result, ensure_ascii=False, indent=indent))
            sys.stdout.flush()
        except BrokenPipeError:
            # Python's default handler for SIGPIPE
            devnull = os.open(os.devnull, os.O_WRONLY)
            os.dup2(devnull, sys.stdout.fileno())
            sys.exit(1)
        return 0
    
    except Exception as e:
        try:
            print(json.dumps({"error": str(e)}, ensure_ascii=False, indent=2), file=sys.stderr)
        except BrokenPipeError:
            sys.exit(1)
        return 1


# ============================================================================
# Main Entry Point
# ============================================================================

if __name__ == "__main__":
    # Try CLI mode first
    result = cli_main()
    
    if result is None:
        # No CLI args, run as MCP server
        mcp = create_mcp_server()
        mcp.run()
    else:
        sys.exit(result)
