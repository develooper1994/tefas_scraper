#!/usr/bin/env bash

# TEFAS BindComparisonFundSizes - Fon Büyüklükleri Karşılaştırma
#
# Bu script, TEFAS üzerindeki fonların portföy büyüklüklerini ve pay adetlerini karşılaştırmak için kullanılır.
#
# Kullanım:
#   ./tefasBindComparisonFundSizes.sh [-t <fund_type>] [-s <start_date>] [-e <end_date>] [-o <output_format>]
#
# Parametreler:
#   -t, --fund-type      Fon tipi: 'YAT' (Yatırım Fonları), 'EMK' (Emeklilik Fonları). Varsayılan: 'YAT'.
#   -s, --start-date     Başlangıç tarihi (GG.AA.YYYY). Varsayılan: 1 ay öncesi.
#   -e, --end-date       Bitiş tarihi (GG.AA.YYYY). Varsayılan: Bugün.
#   -o, --output-format  Çıktı formatı: 'humanize' veya 'json'. Varsayılan: 'json'.
#   -h, --help           Yardım mesajını gösterir.
#
# Örnekler:
#   # Son 1 aydaki büyüklük değişimlerini listele:
#   ./tefasBindComparisonFundSizes.sh -o humanize
#
#   # 2024 yılının ilk ayındaki büyüklük değişimlerini listele:
#   ./tefasBindComparisonFundSizes.sh -s 01.01.2024 -e 31.01.2024 -o humanize

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
  echo "Usage: $0 [-t <fund_type>] [-s <start_date>] [-e <end_date>] [-o <output_format>]"
  echo "Fetches comparative fund sizes from TEFAS."
  echo ""
  echo "Options:"
  echo "  -t, --fund-type      Fund type: 'YAT' (Investment), 'EMK' (Pension). Default is 'YAT'."
  echo "  -s, --start-date     Start date (DD.MM.YYYY). Default is 1 month ago."
  echo "  -e, --end-date       End date (DD.MM.YYYY). Default is today."
  echo "  -o, --output-format  Output format: 'humanize' or 'json'. Default is 'json'."
  echo "  -h, --help           Display this help message."
  echo ""
  echo "Example:"
  echo "  $0 -t YAT -o humanize"
  exit 0
}

# 🔹 Default values
FUND_TYPE="YAT"
START_DATE=$(date -d "1 month ago" +%d.%m.%Y)
END_DATE=$(date +%d.%m.%Y)
OUTPUT_FORMAT="json"

# 🔹 Parse arguments
TEMP=$(getopt -o t:s:e:o:h --long fund-type:,start-date:,end-date:,output-format:,help -n 'tefasBindComparisonFundSizes.sh' -- "$@")
if [ $? != 0 ]; then echo "Terminating..." >&2; exit 1; fi
eval set -- "$TEMP"

while true; do
  case "$1" in
    -t | --fund-type ) FUND_TYPE="$2"; shift 2 ;;
    -s | --start-date ) START_DATE="$2"; shift 2 ;;
    -e | --end-date ) END_DATE="$2"; shift 2 ;;
    -o | --output-format ) OUTPUT_FORMAT="$2"; shift 2 ;;
    -h | --help ) usage ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

COOKIES_FILE=$(mktemp)
API_URL="https://www.tefas.gov.tr/api/DB/BindComparisonFundSizes"
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
  --data "calismatipi=2&fontip=$FUND_TYPE&sfontur=&kurucukod=&fongrup=&bastarih=$START_DATE&bittarih=$END_DATE&fonturkod=&fonunvantip=&strperiod=1,1,1,1,1,1,1&islemdurum=1")

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
    "💰 Last Size: \(.SONPORTFOYDEGERI // "0") TL\n" +
    "📊 Size Change: %\(.PORTBUYUKLUKDEGISIM // "0")\n" +
    "👥 Last Share Count: \(.SONPAYADEDI // "0")\n" +
    "📈 Net Return (Period): %\(.NETGETIRIORANI // "0")\n" +
    "---------------------------------------------"
  '
else
  echo "$RESPONSE" | jq .
fi
