# İstek Özetleri (redakte edilmiş)

Tarih: 2026-04-17

Not: Tam, redakte edilmiş payload'lar `tefasUrlExploration/_private/full_payloads_redacted.txt` içinde saklıdır. Bu dizin `.gitignore` ile hariç tutulmuştur.

Aşağıda her istek için kısa özet, önemli header'lar ve kırpılmış (redakte edilmiş) payload örneği bulunmaktadır.

---

1) `tefasUrlExploration/testScripts/tefasBindComparisonFundReturns.sh`
- Method: POST
- URL: https://www.tefas.gov.tr/api/DB/BindComparisonFundReturns
- Önemli header'lar: `Content-Type`, `Origin`, `Referer`, `X-Requested-With`
- Kırpılmış payload örneği:
  - calismatipi=2
  - fontip=YAT
  - strperiod=1,1,1,1,1,1,1
  - islemdurum=1
- Payload boyutu (dosyada görünen): ~148 karakter
- Kısa açıklama: Fon getirileri karşılaştırma sorgusu; filtreler (çalışma tipi, fon tipi, periyot) gönderilir.

2) `tefasUrlExploration/testScripts/tefasBindComparisonManagementFees.sh`
- Method: POST
- URL: https://www.tefas.gov.tr/api/DB/BindComparisonManagementFees
- Kırpılmış payload örneği:
  - fontip=YAT
  - islemdurum=1
- Payload boyutu: ~76 karakter
- Açıklama: Yönetim ücreti filtreli karşılaştırma verisi talebi.

3) `tefasUrlExploration/testScripts/tefasBindComparisonFundSizes.sh`
- Method: POST
- URL: https://www.tefas.gov.tr/api/DB/BindComparisonFundSizes
- Kırpılmış payload örneği:
  - calismatipi=2
  - fontip=YAT
  - bastarih=18.03.2026
  - bittarih=17.04.2026
  - strperiod=1,1,1,1,1,1,1
  - islemdurum=1
- Payload boyutu: ~154 karakter
- Açıklama: Fon büyüklükleri/AUM karşılaştırma isteği (tarih aralığıyla).

4) `tefasUrlExploration/testScripts/request.sh` (ASP.NET AJAX POST — büyük payload)
- Method: POST (AJAX / form postback)
- URL: https://www.tefas.gov.tr/FonAnaliz.aspx?FonKod=TLY
- Önemli header'lar: `Content-Type`, `X-MicrosoftAjax`, `X-Requested-With`, `Referer`
- Kırpılmış payload (ÖNEMLİ: büyük token blob'ları redakte edildi):
  - ctl00$MainContent$ScriptManager1=ctl00$MainContent$UpdatePanel1|ctl00$MainContent$RadioButtonListPeriod$6
  - __EVENTTARGET=ctl00$MainContent$RadioButtonListPeriod$6
  - __EVENTARGUMENT=
  - __LASTFOCUS=
  - __VIEWSTATE=<VIEWSTATE_REDACTED>
  - __EVENTVALIDATION=<EVENTVALIDATION_REDACTED>
- Payload boyutu: çok büyük (repo görünümlerinde kısmen kırpılmış/uzun bloblar mevcut)
- Açıklama: Fon analiz sayfasına yapılan postback; sayfaya özgü ASP.NET viewstate/eventvalidation içeren büyük form verileri taşır.

5) `tefasUrlExploration/testScripts/tefasBindHistoryAllocation.sh`
- Method: POST
- URL: https://www.tefas.gov.tr/api/DB/BindHistoryAllocation
- Kırpılmış payload örneği:
  - fontip=$FUND_TYPE
  - bastarih=$START_DATE
  - bittarih=$END_DATE
  - fonkod=$FUND_CODE
- Not: Komutlar cookie dosyası (`COOKIES_FILE`) kullanıyor; cookie değerleri paylaşıma redakte edilmelidir.

6) `tefasUrlExploration/testScripts/tefasBindHistoryInfo.sh`
- Method: POST
- URL: https://www.tefas.gov.tr/api/DB/BindHistoryInfo
- Kırpılmış payload örneği: aynı yapı (fontip, bastarih, bittarih, fonkod)

7) `tefasUrlExploration/testScripts/tefasGetAllFundAnalyzeData.sh`
- Method: POST
- URL: https://www.tefas.gov.tr/api/DB/GetAllFundAnalyzeData
- Kırpılmış payload örneği:
  - fonTip=$FUND_TYPE
  - fonKod=$FUND_CODE
  - bastarih=$START_DATE
  - bittarih=$END_DATE

8) `mcp_server.py` (kod içi istekler)
- Method: POST (via `requests.post(data=...)`)
- Örnek payload (kod): {"fonTip": fund_type, "fonKod": fund_code, "bastarih": current_start_date, "bittarih": current_end_date}

9) `tefas_scraper_extension/scraper.py` (kod içi istekler)
- Method: POST
- Örnek payload (kod): {"fonTip": fund_type, "fonKod": fund_code, "bastarih": current_start_date, "bittarih": current_end_date}

---

Redaction politikası:
- `__VIEWSTATE`, `__EVENTVALIDATION` ve benzeri büyük token blob'ları `<..._REDACTED>` ile değiştirildi.
- Cookie veya Authorization içeren veriler özetlenip gizlendi.

Öneriler:
- Kısa örnekler paylaşmak genellikle yeterli; tam kırpılmış payload'lar gerekiyorsa `tefasUrlExploration/_private/full_payloads_redacted.txt` dosyasını kullanın.
- Tam blob'lar (viewstate) yerine hash veya placeholder kullanın; böylece veri güvenliği sağlanır.
