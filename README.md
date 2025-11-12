# Tefas Scraper

## Tefas Url Exploration

### Test Scripts

    Fon türleri:
    - YAT: Menkul Kıymet Yatırım Fonu
    - EMK: BES(Birey Emeklilik Sistemi) Yatırım Fonu
    - BYF: Borsa Yatırım Fonu
    - GYF: Gayrimenkul Yatırım Fonu
    - GSYF: Giriim Sermayesi Yatırım Fonu

    > BindHistoryInfo

    ```bash
    ./tefasBindHistoryInfo.sh YAT 11.11.2025 11.11.2025 TLY
    ./tefasBindHistoryInfo.sh YAT 11.11.2025 11.11.2025 TLY --humanize
    ```

    > BindHistoryAllocation

    ```bash
    ./tefasBindHistoryAllocation.sh YAT 11.11.2025 11.11.2025 TLY
    ./tefasBindHistoryAllocation.sh YAT 11.11.2025 11.11.2025 TLY --humanize
    ```

    > GetAllFundAnalyzeData

    ```bash
    ./tefasGetAllFundAnalyzeData.sh YAT TLY 11.11.2025 11.11.2025
    ./tefasGetAllFundAnalyzeData.sh YAT TLY 11.11.2025 11.11.2025 --humanize
    ```
