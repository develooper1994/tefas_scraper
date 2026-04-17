#!/bin/bash
# Fon büyüklüğü (AUM / net varlık değeri) karşılaştırma çağrısıdır

: <<'COMMENT'

--data-raw '

calismatipi=2
# Çalışma tipi
#
# 1 -> listeleme
# 2 -> karşılaştırma / veri üretme
#
# Bu endpoint için standart değer:
#
# 2


fontip=YAT
# Fon tipi
#
# YAT -> yatırım fonu
# EMK -> emeklilik fonu
#
# Veri kümesini doğrudan değiştirir.


sfontur=
# Alt fon türü filtresi
#
# Örnek:
#
# Hisse Senedi
# Borçlanma Araçları
# Para Piyasası
# Katılım
#
# Boş:
#
# tüm alt türler


kurucukod=
# Fon kurucusu filtresi
#
# Portföy yönetim şirketi
#
# Örnek:
#
# AKP
# ISY
# TEB
#
# Boş:
#
# tüm kurucular


fongrup=
# Fon grubu filtresi
#
# UI'daki:
#
# Fon Grubu
#
# dropdown karşılığı
#
# Boş:
#
# tüm gruplar


bastarih=18.03.2026
# Başlangıç tarihi
#
# Format:
#
# dd.MM.yyyy
#
# Bu endpoint'te:
#
# zaman aralığının ilk günü


bittarih=17.04.2026
# Bitiş tarihi
#
# zaman aralığının son günü


fonturkod=
# Fon tür kodu
#
# internal classification filtresi
#
# genelde boş bırakılır


fonunvantip=
# Fon unvan tipi
#
# UI iç filtre parametresi
#
# çoğu zaman boş


strperiod=1,1,1,1,1,1,1
# Dönem seçimi maskesi
#
# index sırası:
#
# 0 -> 1 Ay
# 1 -> 3 Ay
# 2 -> 6 Ay
# 3 -> 1 Yıl
# 4 -> 3 Yıl
# 5 -> 5 Yıl
# 6 -> YTD
#
# 1 -> dahil
# 0 -> dahil değil
#
# Bu endpoint'te:
#
# UI uyumluluğu için var
# hesaplamada çoğu zaman kullanılmaz


islemdurum=1
# İşlem durumu
#
# 1 -> aktif fonlar
# 0 -> pasif fonlar dahil

'

COMMENT

curl 'https://www.tefas.gov.tr/api/DB/BindComparisonFundSizes' \
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
  --data-raw 'calismatipi=2&fontip=YAT&sfontur=&kurucukod=&fongrup=&bastarih=18.03.2026&bittarih=17.04.2026&fonturkod=&fonunvantip=&strperiod=1,1,1,1,1,1,1&islemdurum=1'