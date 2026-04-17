#!/bin/bash
# Fon Yönetim Ücretleri
# Fonların belirli kriterlere göre fon listesini yönetim ücretleriyle birlikte döndürür.

: <<'COMMENT'
--data-raw '

fontip=YAT
# Fon tipi
#
# YAT -> Yatırım fonları
# EMK -> Emeklilik fonları
#
# Bu parametre veri kümesini kökten değiştirir.
# En kritik filtrelerden biridir.


sfontur=
# Alt fon türü filtresi
#
# Örnek kategoriler:
#
# Hisse Senedi
# Borçlanma Araçları
# Para Piyasası
# Katılım
# Fon Sepeti
#
# Boş bırakılırsa:
#
# tüm alt türler dahil edilir


kurucukod=
# Fon kurucusu / portföy yönetim şirketi kodu
#
# Örnek:
#
# AKP   -> Ak Portföy
# ISY   -> İş Portföy
# TEF   -> TEB Portföy
#
# Boş:
#
# tüm kurucular


fongrup=
# Fon grubu filtresi
#
# UI'da:
#
# "Fon Grubu"
#
# alanına karşılık gelir.
#
# Çoğu kullanımda boş bırakılır.


fonturkod=
# Fon tür kodu
#
# Daha detaylı sınıflandırma filtresi.
#
# Genelde:
#
# internal classification
#
# amaçlıdır.
#
# Boş:
#
# tüm fon türleri


fonunvantip=
# Fon unvan tipi
#
# UI içsel filtre parametresi.
#
# Genelde boş bırakılır.
#
# Bazı kurumsal filtreleme senaryolarında kullanılır.


islemdurum=1
# İşlem durumu filtresi
#
# 1 -> aktif fonlar
# 0 -> pasif / kapanmış fonlar dahil
#
# Production kullanımda genelde:
#
# 1
'
COMMENT

curl 'https://www.tefas.gov.tr/api/DB/BindComparisonManagementFees' \
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
  --data-raw 'fontip=YAT&sfontur=&kurucukod=&fongrup=&fonturkod=&fonunvantip=&islemdurum=1'
