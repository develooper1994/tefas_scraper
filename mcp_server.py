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
from datetime import datetime, timedelta
from dateutil.relativedelta import relativedelta
import requests
import urllib3

# Disable insecure request warnings
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


# ============================================================================
# TEFAS Scraper Core Class
# ============================================================================

class TefasScraper:
    """Core TEFAS scraper implementation"""
    
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        })

    def _make_request(self, url, data=None):
        try:
            if data:
                response = self.session.post(url, data=data, timeout=25, verify=False)
            else:
                response = self.session.get(url, timeout=10, verify=False)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            raise Exception(f"Request failed: {e}")
        except json.JSONDecodeError:
            if "<html" in response.text.lower() or "<!doctype" in response.text.lower():
                raise Exception("Received an HTML response, possibly from a WAF.")
            else:
                raise Exception(f"Failed to decode JSON response: {response.text[:500]}")

    def get_fund_analysis(self, fund_type: str, fund_code: str, start_date: str = None, end_date: str = None, price_range: str = None):
        """
        Fetches comprehensive fund analysis data.
        Date format: DD.MM.YYYY
        """
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

        url = "https://www.tefas.gov.tr/api/DB/GetAllFundAnalyzeData"
        data = {"fonTip": fund_type, "fonKod": fund_code, "bastarih": current_start_date, "bittarih": current_end_date}
        self.session.headers.update({"Referer": "https://www.tefas.gov.tr/FonAnaliz.aspx"})
        return self._make_request(url, data)

    def get_history(self, endpoint, fund_code, start_date, end_date, fund_type="ALL"):
        """
        Generic fetcher for historical data ('BindHistoryInfo' or 'BindHistoryAllocation').
        Date format: YYYY-MM-DD
        """
        try:
            datetime.strptime(start_date, '%Y-%m-%d')
            datetime.strptime(end_date, '%Y-%m-%d')
        except ValueError:
            raise ValueError("Invalid date format. Please use YYYY-MM-DD.")
            
        api_url = f"https://www.tefas.gov.tr/api/DB/{endpoint}"
        referer_url = "https://www.tefas.gov.tr/TarihselVeriler.aspx"
        
        # Make a preliminary request to get cookies
        self.session.get(referer_url, verify=False)
        self.session.headers.update({"Referer": referer_url})

        data = {"fontip": fund_type, "bastarih": start_date, "bittarih": end_date, "fonkod": fund_code}
        return self._make_request(api_url, data)


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
  
  # Get allocation history
  %(prog)s --cli history-allocation --fund-code TTE --start-date 2024-01-01 --end-date 2024-01-31
        """
    )
    
    parser.add_argument('--cli', choices=['analyze', 'history-info', 'history-allocation'],
                        help='CLI command to execute')
    parser.add_argument('--fund-type', help='Fund type (e.g., YAT, EMK)')
    parser.add_argument('--fund-code', help='Fund code (e.g., TTE, AFA, TLY)')
    parser.add_argument('--start-date', help='Start date (YYYY-MM-DD or DD.MM.YYYY)')
    parser.add_argument('--end-date', help='End date (YYYY-MM-DD or DD.MM.YYYY)')
    parser.add_argument('--price-range', help='Price range (1H, 1M, 3M, 6M, YTD, 1Y, 3Y, 5Y)')
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
        
        # Print result
        indent = 2 if args.pretty else None
        print(json.dumps(result, ensure_ascii=False, indent=indent))
        return 0
    
    except Exception as e:
        print(json.dumps({"error": str(e)}, ensure_ascii=False, indent=2), file=sys.stderr)
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
