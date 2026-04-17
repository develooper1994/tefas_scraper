
import json
import os
from datetime import datetime, timedelta
from dateutil.relativedelta import relativedelta
import requests
import urllib3
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

# Disable insecure request warnings only if TLS verification is explicitly disabled
if not os.getenv('TEFAS_VERIFY_TLS', 'true').lower() in ('1', 'true', 'yes'):
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


class TefasScraper:
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        })

        # TLS verification and retry/backoff
        self.verify_tls = os.getenv('TEFAS_VERIFY_TLS', 'true').lower() in ('1', 'true', 'yes')
        self.session.verify = self.verify_tls
        max_retries = int(os.getenv('TEFAS_MAX_RETRIES', '3'))
        backoff = float(os.getenv('TEFAS_BACKOFF_FACTOR', '0.3'))
        retry = Retry(total=max_retries, backoff_factor=backoff, status_forcelist=(429, 500, 502, 503, 504), allowed_methods=["GET", "POST"])
        adapter = HTTPAdapter(max_retries=retry)
        self.session.mount("https://", adapter)
        self.session.mount("http://", adapter)

    def _make_request(self, url, data=None):
        try:
            if data:
                response = self.session.post(url, data=data, timeout=25, verify=self.verify_tls)
            else:
                response = self.session.get(url, timeout=10, verify=self.verify_tls)
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
