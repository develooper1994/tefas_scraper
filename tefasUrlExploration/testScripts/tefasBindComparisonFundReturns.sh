#!/bin/bash
# Fon Getirileri Listesi
# Fonların belirli kriterlere göre fon listesini getiriyle birlikte döndürür.

: <<'COMMENT'

--data-raw '

Parametre	        Anlam	                Kritik mi
calismatipi	        çalışma tipi	        EVET
fontip	            fon tipi	            EVET
strperiod	        dönem seçimi	        EVET
islemdurum	        aktif fon filtresi	    EVET
kurucukod	        fon kurucusu	        opsiyonel
fongrup	            fon grubu	            opsiyonel
bastarih	        başlangıç tarihi	    opsiyonel
bittarih	        bitiş tarihi	        opsiyonel
sfontur	            alt fon türü	        opsiyonel
fonturkod	        fon tür kodu	        opsiyonel
fonunvantip	        unvan tipi	            opsiyonel

calismatipi=2        # Çalışma tipi:
                     #   1 -> Fon listesi
                     #   2 -> Fon getirileri / karşılaştırma (bu endpoint için ana kullanım)

fontip=YAT           # Fon tipi:
                     #   YAT -> Yatırım fonu
                     #   EMK -> Emeklilik fonu

sfontur=              # Alt fon türü filtresi
                     #   Boş -> tüm alt türler
                     #   Örnek: Hisse, Borçlanma, Para Piyasası vb.

kurucukod=            # Fon kurucusu / portföy yönetim şirketi kodu
                     #   Boş -> tüm kurucular
                     #   Örnek: AKP, ISY, TEF vb.

fongrup=              # Fon grubu filtresi
                     #   Boş -> tüm gruplar
                     #   UI'da "Fon Grubu" dropdown'ına karşılık gelir

bastarih=Başlangıç   # Başlangıç tarihi filtresi
                     #   "Başlangıç" -> tarih filtresi yok (placeholder)
                     #   Gerçek kullanım:
                     #       01.01.2024
                     #   Format:
                     #       dd.MM.yyyy

bittarih=Bitiş       # Bitiş tarihi filtresi
                     #   "Bitiş" -> tarih filtresi yok (placeholder)

fonturkod=           # Fon tür kodu
                     #   Daha spesifik sınıflandırma filtresi
                     #   Boş -> tüm türler

fonunvantip=         # Fon unvan tipi
                     #   Genelde boş bırakılır
                     #   UI iç filtre parametresi

strperiod=1,1,1,1,1,1,1
                     # Getiri periyotları (checkbox bit mask mantığı)
                     #
                     # Sıra sabit:
                     #
                     #   index 0 -> 1 Ay
                     #   index 1 -> 3 Ay
                     #   index 2 -> 6 Ay
                     #   index 3 -> 1 Yıl
                     #   index 4 -> 3 Yıl
                     #   index 5 -> 5 Yıl
                     #   index 6 -> YTD (Year To Date)
                     #
                     # 1 -> dahil
                     # 0 -> dahil değil
                     #
                     # Örnek:
                     #
                     # sadece 1 yıl:
                     # strperiod=0,0,0,1,0,0,0

islemdurum=1         # İşlem durumu:
                     #   1 -> aktif fonlar
                     #   0 -> pasif / kapalı fonlar dahil
'

COMMENT

curl 'https://www.tefas.gov.tr/api/DB/BindComparisonFundReturns' \
  -H 'Accept: application/json, text/javascript, */*; q=0.01' \
  -H 'Accept-Language: en-US,en;q=0.9,tr-TR;q=0.8,tr;q=0.7' \
  -H 'Connection: keep-alive' \
  -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
  -H 'DNT: 1' \
  -H 'Origin: https://www.tefas.gov.tr' \
  -H 'Referer: https://www.tefas.gov.tr/FonKarsilastirma.aspx' \
  -H 'Sec-Fetch-Dest: empty' \
  -H 'Sec-Fetch-Mode: cors' \
  -H 'Sec-Fetch-Site: same-origin' \
  -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36' \
  -H 'X-Requested-With: XMLHttpRequest' \
  -H 'sec-ch-ua: "Google Chrome";v="147", "Not.A/Brand";v="8", "Chromium";v="147"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "Windows"' \
  --data-raw 'calismatipi=2&fontip=YAT&sfontur=&kurucukod=&fongrup=&bastarih=Başlangıç&bittarih=Bitiş&fonturkod=&fonunvantip=&strperiod=1,1,1,1,1,1,1&islemdurum=1'
