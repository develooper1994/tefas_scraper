#!/bin/bash
# tefasGetAllFundAnalyzeData.sh
# Kullanım: ./tefasGetAllFundAnalyzeData.sh <FON_TIPI> <FON_KODU> <BAS_TARIH> <BIT_TARIH>

FON_TIPI="${1:-YAT}"
FON_KODU="${2:-TLY}"
BAS_TARIH="${3:-01.01.2025}"
BIT_TARIH="${4:-31.01.2025}"

URL="https://www.tefas.gov.tr/api/DB/GetAllFundAnalyzeData"
REFERER="https://www.tefas.gov.tr/FonAnaliz.aspx"

# WAF önlemleri: gerçek tarayıcı davranışı taklidi
USER_AGENT="Mozilla/5.0 (X11; Linux x86_64; rv:132.0) Gecko/20100101 Firefox/132.0"
ACCEPT="application/json, text/javascript, */*; q=0.01"
ACCEPT_LANGUAGE="tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7"
ACCEPT_ENCODING="gzip, deflate, br"
CONNECTION="keep-alive"
SEC_FETCH_DEST="empty"
SEC_FETCH_MODE="cors"
SEC_FETCH_SITE="same-origin"

# Tarayıcı cookie ve header davranışını benzetmek için rastgele token
BOUNDARY=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 12)

# Curl isteği
curl -s "$URL" \
  -H "User-Agent: $USER_AGENT" \
  -H "Accept: $ACCEPT" \
  -H "Accept-Language: $ACCEPT_LANGUAGE" \
  -H "Accept-Encoding: $ACCEPT_ENCODING" \
  -H "Connection: $CONNECTION" \
  -H "Origin: https://www.tefas.gov.tr" \
  -H "Referer: $REFERER" \
  -H "X-Requested-With: XMLHttpRequest" \
  -H "Sec-Fetch-Dest: $SEC_FETCH_DEST" \
  -H "Sec-Fetch-Mode: $SEC_FETCH_MODE" \
  -H "Sec-Fetch-Site: $SEC_FETCH_SITE" \
  -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" \
  --data "fontip=$FON_TIPI&fonkod=$FON_KODU&basTarih=$BAS_TARIH&bitTarih=$BIT_TARIH" \
  --compressed \
  -L \
  -k \
  --max-time 25 \
  -o response.json

# Yanıt kontrolü
if file response.json | grep -q 'HTML'; then
  echo "⚠️ WAF engeli veya yönlendirme sayfası döndü."
  head -n 10 response.json
else
  echo "✅ Veri çekildi. Çıktı dosyası: response.json"
  jq . response.json 2>/dev/null || cat response.json
fi
