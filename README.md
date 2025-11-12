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

    > GetAllFundAnalyzeData(daha fazla veri): Fonun tam adı, Portföy büyüklüğünü, Yatırımcı Sayısı, Pay adet, Fon kategorisi, Fonun kategorisindeki fon sayısı, Kategorisindeki derecesi, Günlük getiri, Son fiyat, Pazar payı, fon getirileri(1ay, 3ay, 6ay, 1yıl, 3yıl, 5yıl), fon profili(ışın kodu, ilk ve son işlem saati, min ve max alış ve satış, tefas durumu(tefasa açık kapalı, alıma açık fakat satışa açık, vb.), alış ve satış valörleri, risk değeri), portföy dağılımı(fon kodu, fonun tam ismi, varlıklar ve oranları), fundchange(boş geliyor), fundPrices(eskiden yeniden! fundPrices1H(son 1 haftadaki tüm fiyatların listesi), fundPrices1A(son 1aylık tüm fiyatların listesi), fundPrices3A(son 3aylık tüm fiyatların listesi), fundPrices6A(son 6aylık tüm fiyatların listesi), fundPricesYB(son yıl başından beri tüm fiyatların listesi), fundPrices1Y(son 1yıllık tüm fiyatların listesi), fundPrices3Y(son 3yıllık tüm fiyatların listesi), fundPrices5Y(son 5yıllık tüm fiyatların listesi)), fundComparisonWarning(1,2,3), isFavorite

    ```bash
    ./tefasGetAllFundAnalyzeData.sh YAT TLY 11.11.2025 11.11.2025
    ./tefasGetAllFundAnalyzeData.sh YAT TLY 11.11.2025 11.11.2025 --humanize
    ```
