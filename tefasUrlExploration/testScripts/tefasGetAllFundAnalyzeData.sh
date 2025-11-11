#!/bin/bash
# tefasGetAllFundAnalyzeData.sh
# Kullanım: ./tefasGetAllFundAnalyzeData.sh <FON_TIPI> <FON_KODU> <BAS_TARIH> <BIT_TARIH>
# Örnek: ./tefasGetAllFundAnalyzeData.sh YAT TLY 01.01.2025 31.01.2025

set -u
FON_TIPI="${1:-YAT}"
FON_KODU="${2:-TLY}"
BAS_TARIH="${3:-01.01.2025}"
BIT_TARIH="${4:-31.01.2025}"

URL="https://www.tefas.gov.tr/api/DB/GetAllFundAnalyzeData"
REFERER="https://www.tefas.gov.tr/FonAnaliz.aspx"

# WAF taklidi için başlıklar
USER_AGENT="Mozilla/5.0 (X11; Linux x86_64; rv:132.0) Gecko/20100101 Firefox/132.0"
ACCEPT="application/json, text/javascript, */*; q=0.01"
ACCEPT_LANGUAGE="tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7"
ACCEPT_ENCODING="gzip, deflate, br"
CONNECTION="keep-alive"
SEC_FETCH_DEST="empty"
SEC_FETCH_MODE="cors"
SEC_FETCH_SITE="same-origin"

# Geçici dosya oluştur ve çıkışta temizle
TMP=$(mktemp /tmp/tefas_getall_XXXXXX) || { echo "tmpfile creation failed"; exit 1; }
trap 'rm -f "$TMP"' EXIT

# İsteği yap, çıktıyı tmp'ye kaydet
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
  --compressed -L -k --max-time 25 -o "$TMP"

# Basit WAF / HTML kontrolü: tmp içeriğinde "<html" veya "DOCTYPE" var mı?
if grep -qiE '<html|<!doctype' "$TMP"; then
  echo "⚠️ Muhtemel WAF / HTML yanıtı döndü. İlk 30 satır:"
  head -n 30 "$TMP"
  exit 2
fi

# JSON ise biçimlendir ve stdout'a yaz (geçici dosya daha sonra temizlenir)
if command -v jq >/dev/null 2>&1; then
  jq . "$TMP" || { echo "⚠️ jq ile parse edilemedi, ham içerik gösteriliyor:"; cat "$TMP"; }
elif python -c 'import sys, json
try:
  json.load(sys.stdin)
  print("OK")
except Exception:
  sys.exit(1)' < "$TMP" >/dev/null 2>&1; then
  python -m json.tool < "$TMP"
else
  # Ne jq ne de python JSON parse edebildi — ham göster
  cat "$TMP"
fi

# trap cleanup will remove $TMP automatically on exit
exit 0
