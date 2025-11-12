#!/usr/bin/env bash
# TEFAS BindHistoryAllocation - WAF dostu versiyon

set -euo pipefail

# 🔧 Gereken komutlar kontrolü
for cmd in curl jq awk date; do
  command -v $cmd >/dev/null 2>&1 || {
    echo "❌ Gerekli uygulama bulunamadı: $cmd"
    exit 1
  }
done

# 🔹 Parametre kontrolü
if [[ $# -lt 4 ]]; then
  echo "Kullanım: $0 <fonTip> <basTarih> <bitTarih> <fonKod> [--humanize|json]"
  exit 1
fi

FONTIP=$1
FONKOD=$2
BASTARIH=$3
BITTARIH=$4
OPTION=${5:-}

COOKIES_FILE=$(mktemp)
API_URL="https://www.tefas.gov.tr/api/DB/BindHistoryAllocation"
REFERER_URL="https://www.tefas.gov.tr/TarihselVeriler.aspx"

# 🔹 Ön GET isteği (cookie alma)
curl -s -c "$COOKIES_FILE" \
  -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
  "$REFERER_URL" >/dev/null

sleep 1  # WAF dostu bekleme

# 🔹 POST isteği
RESPONSE=$(curl -s -b "$COOKIES_FILE" -X POST "$API_URL" \
  -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" \
  -H "Origin: https://www.tefas.gov.tr" \
  -H "Referer: $REFERER_URL" \
  -H "X-Requested-With: XMLHttpRequest" \
  -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
  --data "fontip=$FONTIP&bastarih=$BASTARIH&bittarih=$BITTARIH&fonkod=$FONKOD")

rm -f "$COOKIES_FILE"

# 🔹 Hata kontrolü
if ! echo "$RESPONSE" | jq empty >/dev/null 2>&1; then
  echo "❌ Geçersiz yanıt veya bağlantı hatası:"
  echo "$RESPONSE"
  exit 1
fi

if [[ "$OPTION" == "--humanize" ]]; then
  echo "$RESPONSE" | jq -r '
    .data[] |
    "📅 Tarih: \(.TARIH | tonumber / 1000 | strftime("%Y-%m-%d"))\n" +
    "🏷 Fon Kodu: \(.FONKODU)\n" +
    "📘 Fon Unvanı: \(.FONUNVAN)\n" +
    "💹 Hisse Senedi (HS): \(.HS // "N/A")\n" +
    "💵 Yabancı Yatırım Fonu (YYF): \(.YYF // "N/A")\n" +
    "💰 Fon Büyüklüğü (BilFiyat): \(.BilFiyat // "N/A")\n" +
    "---------------------------------------------"
  '
else
  echo "$RESPONSE" | jq .
fi
