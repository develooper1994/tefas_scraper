# Tefas Scraper

## Tefas Url Exploration

### Test Scripts

    API_URL="https://www.tefas.gov.tr/api/DB/<api_name>"
    REFERER_URL="https://www.tefas.gov.tr/TarihselVeriler.aspx"

    Fon türleri:
    - YAT: Menkul Kıymet Yatırım Fonu
    - EMK: BES(Birey Emeklilik Sistemi) Yatırım Fonu
    - BYF: Borsa Yatırım Fonu
    - GYF: Gayrimenkul Yatırım Fonu
    - GSYF: Giriim Sermayesi Yatırım Fonu

    > BindHistoryInfo(genel bilgilendirme): Unix cinsinden(saniye) sorgunun yapıldığı zamanı, Son fiyat bilgisini, Fonun tam adı, Tedahüldeki pay sayısını, Yatırımcı sayısı, Portföy büyüklüğünü

    ```bash
    ./tefasBindHistoryInfo.sh YAT TLY 11.11.2025 11.11.2025
    ./tefasBindHistoryInfo.sh YAT TLY 11.11.2025 11.11.2025 --humanize
    ```

    > BindHistoryAllocation(portföy dağılımı): Unix cinsinden(saniye) sorgunun yapıldığı zamanı, Fonun tam adı, Varlık dağılımı(belli tanımlı varlık portföyde yoksa null döner. "--humanize" seçeneği null olanları göstermez.)

    ```bash
    ./tefasBindHistoryAllocation.sh YAT TLY 11.11.2025 11.11.2025
    ./tefasBindHistoryAllocation.sh YAT TLY 11.11.2025 11.11.2025 --humanize
    ```

    > GetAllFundAnalyzeData (comprehensive data): Fund's full name, Portfolio size, Investor Count, Share quantity, Fund category, Number of funds in its category, Rank in its category, Daily return, Last price, Market share, fund returns (1 month, 3 months, 6 months, 1 year, 3 years, 5 years), fund profile (ISIN code, first and last transaction time, min and max buy and sell, TEFAS status (open/closed for TEFAS, open for buy but closed for sell, etc.), buy and sell value dates, risk value), portfolio distribution (fund code, fund's full name, assets and their ratios), fundchange (empty), fundPrices (again! fundPrices1H (list of all prices in the last 1 week), fundPrices1A (list of all prices in the last 1 month), fundPrices3A (list of all prices in the last 3 months), fundPrices6A (list of all prices in the last 6 months), fundPricesYB (list of all prices since the beginning of the year), fundPrices1Y (list of all prices in the last 1 year), fundPrices3Y (list of all prices in the last 3 years), fundPrices5Y (list of all prices in the last 5 years)), fundComparisonWarning (1,2,3), isFavorite

    ```bash
    # Usage:
    #   ./tefasGetAllFundAnalyzeData.sh -t <FUND_TYPE> -c <FUND_CODE> [-s <START_DATE>] [-e <END_DATE>] [-h] [-n] [-r <RANGE>]
    #   Or:
    #   ./tefasGetAllFundAnalyzeData.sh --fund-type <FUND_TYPE> --fund-code <FUND_CODE> [--start-date <START_DATE>] [--end-date <END_DATE>] [--humanize] [--no-date] [--price-range <RANGE>]
    #
    # Parameters:
    #   -t, --fund-type <FUND_TYPE>    : Fund type (e.g., YAT, EMK). Required.
    #   -c, --fund-code <FUND_CODE>    : Fund code (e.g., TLY, AFA). Required.
    #   -s, --start-date <START_DATE> : Start date (DD.MM.YYYY format). Optional.
    #   -e, --end-date <END_DATE>     : End date (DD.MM.YYYY format). Optional.
    #   -h, --humanize                : Display output in human-readable format. Optional.
    #   -n, --no-date                   : Exclude date from price series output. Useful for piping prices. Optional.
    #   -r, --price-range <RANGE>     : Price range. Required if --end-date is provided without --start-date.
    #                                   RANGE values: 1H (1 Week), 1M (1 Month), 3M (3 Months), 6M (6 Months), YTD (Year To Date), 1Y (1 Year), 3Y (3 Years), 5Y (5 Years).
    #   --help                        : Show this help message.
    #
    # Date Parameter Logic:
    #   - If only --start-date (-s) is provided, --end-date (-e) defaults to today's date.
    #   - If --end-date (-e) is provided, --price-range (-r) becomes mandatory, and the start date is calculated based on this range.
    #   - If --price-range (-r) is provided and --end-date (-e) is not, --end-date (-e) defaults to today's date.
    #
    # Examples:
    #   ./tefasGetAllFundAnalyzeData.sh -t YAT -c TLY -h -r 1Y
    #   ./tefasGetAllFundAnalyzeData.sh --fund-type YAT --fund-code TLY --start-date 01.01.2025 --end-date 31.01.2025
    #   ./tefasGetAllFundAnalyzeData.sh -t YAT -c TLY -e 31.10.2025 -r 3M
    #   ./tefasGetAllFundAnalyzeData.sh -t YAT -c TLY -s 01.01.2025
    #   ./tefasGetAllFundAnalyzeData.sh -t YAT -c TLY -r 1M -n # Output: 1787.387020,1802.095808,... (comma-separated prices)
    ```
