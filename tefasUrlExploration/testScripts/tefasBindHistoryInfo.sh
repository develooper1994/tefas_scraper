#!/usr/bin/env bash
# TEFAS BindHistoryInfo - WAF dostu versiyon

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
  echo "Usage: $0 -f <fund_code> -s <start_date> -e <end_date> [-t <fund_type>] [-o <output_format>]"
  echo "Fetches historical binding information for a TEFAS fund."
  echo ""
  echo "Options:"
  echo "  -f, --fund-code      TEFAS fund code (e.g., 'AFA', 'TCD')"
  echo "  -s, --start-date     Start date in YYYY-MM-DD format (e.g., '2023-01-01')"
  echo "  -e, --end-date       End date in YYYY-MM-DD format (e.g., '2023-12-31')"
  echo "  -t, --fund-type      Fund type (e.g., 'DEBT', 'EQUITY'). Default is 'ALL'."
  echo "  -o, --output-format  Output format: 'humanize' for readable output, 'json' for raw JSON. Default is 'json'."
  echo "  -h, --help           Display this help message."
  echo ""
  echo "Example:"
  echo "  $0 -f AFA -s 2023-01-01 -e 2023-01-31 -o humanize"
  exit 0
}

# 🔹 Default values
FUND_TYPE="ALL"
OUTPUT_FORMAT="json"
FUND_CODE=""
START_DATE=""
END_DATE=""

# 🔹 Parse arguments
TEMP=$(getopt -o f:s:e:t:o:h --long fund-code:,start-date:,end-date:,fund-type:,output-format:,help -n 'tefasBindHistoryInfo.sh' -- "$@")
if [ $? != 0 ]; then echo "Terminating..." >&2; exit 1; fi
eval set -- "$TEMP"

while true; do
  case "$1" in
    -f | --fund-code ) FUND_CODE="$2"; shift 2 ;;
    -s | --start-date ) START_DATE="$2"; shift 2 ;;
    -e | --end-date ) END_DATE="$2"; shift 2 ;;
    -t | --fund-type ) FUND_TYPE="$2"; shift 2 ;;
    -o | --output-format ) OUTPUT_FORMAT="$2"; shift 2 ;;
    -h | --help ) usage ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

# 🔹 Validate mandatory parameters
if [[ -z "$FUND_CODE" || -z "$START_DATE" || -z "$END_DATE" ]]; then
  echo "❌ Error: Fund code, start date, and end date are mandatory."
  usage
fi

# 🔹 Validate date format
if ! date -d "$START_DATE" &>/dev/null || ! date -d "$END_DATE" &>/dev/null; then
  echo "❌ Error: Invalid date format. Please use YYYY-MM-DD."
  exit 1
fi

COOKIES_FILE=$(mktemp)
API_URL="https://www.tefas.gov.tr/api/DB/BindHistoryInfo"
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
  --data "fontip=$FUND_TYPE&bastarih=$START_DATE&bittarih=$END_DATE&fonkod=$FUND_CODE")

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
    "📅 Date: \(.TARIH | tonumber / 1000 | strftime("%Y-%m-%d"))\n" +
    "🏷  Fund Code: \(.FONKODU)\n" +
    "📘 Fund Title: \(.FONUNVAN)\n" +
    "💰 Price: \(.FIYAT)\n" +
    "👥 Participant Count: \(.KISISAYISI)\n" +
    "📊 Portfolio Size: \(.PORTFOYBUYUKLUK)\n" +
    "💵 Shares in Circulation: \(.TEDPAYSAYISI)\n" +
    "---------------------------------------------"
  '
else
  echo "$RESPONSE" | jq .
fi
