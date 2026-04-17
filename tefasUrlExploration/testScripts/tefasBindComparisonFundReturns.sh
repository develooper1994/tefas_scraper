#!/usr/bin/env bash

# TEFAS BindComparisonFundReturns - Fon Getirileri Karşılaştırma
#
# Bu script, TEFAS üzerindeki fonların farklı zaman periyotlarındaki getirilerini karşılaştırmak için kullanılır.
#
# Kullanım:
#   ./tefasBindComparisonFundReturns.sh [-t <fund_type>] [-p <periods>] [-o <output_format>]
#
# Parametreler:
#   -t, --fund-type      Fon tipi: 'YAT' (Yatırım Fonları), 'EMK' (Emeklilik Fonları). Varsayılan: 'YAT'.
#   -p, --periods        Virgülle ayrılmış 1/0 dizisi (1A, 3A, 6A, 1Y, 3Y, 5Y, YTD).
#                        Örn: '0,0,0,1,0,0,0' sadece 1 yıllık getiriyi getirir. Varsayılan: '1,1,1,1,1,1,1'.
#   -o, --output-format  Çıktı formatı: 'humanize' (okunabilir) veya 'json' (raw). Varsayılan: 'json'.
#   -h, --help           Yardım mesajını gösterir.
#
# Örnekler:
#   # Tüm fonların tüm getiri periyotlarını listele:
#   ./tefasBindComparisonFundReturns.sh -o humanize
#
#   # Emeklilik fonlarının sadece YTD (Yılbaşından bugüne) getirilerini listele:
#   ./tefasBindComparisonFundReturns.sh -t EMK -p 0,0,0,0,0,0,1 -o humanize

set -euo pipefail

# 🔧 Gereken komutlar kontrolü
for cmd in curl jq awk date; do
  command -v $cmd >/dev/null 2>&1 || {
    echo "❌ Required command not found: $cmd"
    exit 1
  }
done

# 📚 Help function
usage() {
  echo "Usage: $0 [-t <fund_type>] [-p <periods>] [-o <output_format>]"
  echo "Fetches comparative fund returns from TEFAS."
  echo ""
  echo "Options:"
  echo "  -t, --fund-type      Fund type: 'YAT' (Investment), 'EMK' (Pension). Default is 'YAT'."
  echo "  -p, --periods        Comma-separated 1s/0s for periods (1M,3M,6M,1Y,3Y,5Y,YTD)."
  echo "                       Default is '1,1,1,1,1,1,1' (all periods)."
  echo "  -o, --output-format  Output format: 'humanize' or 'json'. Default is 'json'."
  echo "  -h, --help           Display this help message."
  echo ""
  echo "Example:"
  echo "  $0 -t YAT -p 0,0,0,1,0,0,0 -o humanize"
  exit 0
}

# 🔹 Default values
FUND_TYPE="YAT"
PERIODS="1,1,1,1,1,1,1"
OUTPUT_FORMAT="json"

# 🔹 Parse arguments
TEMP=$(getopt -o t:p:o:h --long fund-type:,periods:,output-format:,help -n 'tefasBindComparisonFundReturns.sh' -- "$@")
if [ $? != 0 ]; then echo "Terminating..." >&2; exit 1; fi
eval set -- "$TEMP"

while true; do
  case "$1" in
    -t | --fund-type ) FUND_TYPE="$2"; shift 2 ;;
    -p | --periods ) PERIODS="$2"; shift 2 ;;
    -o | --output-format ) OUTPUT_FORMAT="$2"; shift 2 ;;
    -h | --help ) usage ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

COOKIES_FILE=$(mktemp)
API_URL="https://www.tefas.gov.tr/api/DB/BindComparisonFundReturns"
REFERER_URL="https://www.tefas.gov.tr/FonKarsilastirma.aspx"

# 🔹 Ön GET isteği (cookie alma)
curl -s -c "$COOKIES_FILE" \
  -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
  "$REFERER_URL" >/dev/null

sleep 1

# 🔹 POST isteği
RESPONSE=$(curl -s -b "$COOKIES_FILE" -X POST "$API_URL" \
  -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" \
  -H "Origin: https://www.tefas.gov.tr" \
  -H "Referer: $REFERER_URL" \
  -H "X-Requested-With: XMLHttpRequest" \
  -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
  --data "calismatipi=2&fontip=$FUND_TYPE&sfontur=&kurucukod=&fongrup=&bastarih=Başlangıç&bittarih=Bitiş&fonturkod=&fonunvantip=&strperiod=$PERIODS&islemdurum=1")

rm -f "$COOKIES_FILE"

# 🔹 Hata kontrolü
if ! echo "$RESPONSE" | jq empty >/dev/null 2>&1; then
  echo "❌ Invalid response or connection error:"
  echo "$RESPONSE"
  exit 1
fi

if [[ "$OUTPUT_FORMAT" == "humanize" ]]; then
  echo "$RESPONSE" | jq -r '
    .data[] |
    "🏷 Fund: \(.FONKODU) - \(.FONUNVAN)\n" +
    "📈 1 Month: \(.GETIRI1A // "0")% | 3 Months: \(.GETIRI3A // "0")% | 6 Months: \(.GETIRI6A // "0")%\n" +
    "📅 1 Year: \(.GETIRI1Y // "0")% | 3 Years: \(.GETIRI3Y // "0")% | 5 Years: \(.GETIRI5Y // "0")%\n" +
    "🚀 YTD: \(.GETIRIYB // "0")%\n" +
    "---------------------------------------------"
  '
else
  echo "$RESPONSE" | jq .
fi
