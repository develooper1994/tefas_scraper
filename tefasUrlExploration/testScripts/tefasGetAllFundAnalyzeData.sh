#!/usr/bin/env bash
# tefasGetAllFundAnalyzeData.sh
# Use --help for usage information.

set -euo pipefail

usage() {
  echo "Usage: $0 -t <FUND_TYPE> -c <FUND_CODE> [-s <START_DATE>] [-e <END_DATE>] [-h] [-r <RANGE>]"
  echo "Or:     $0 --fund-type <FUND_TYPE> --fund-code <FUND_CODE> [--start-date <START_DATE>] [--end-date <END_DATE>] [--humanize] [--price-range <RANGE>]"
  echo ""
  echo "Parameters:"
  echo "  -t, --fund-type <FUND_TYPE>    : Fund type (e.g., YAT, EMK). Required."
  echo "  -c, --fund-code <FUND_CODE>    : Fund code (e.g., TLY, AFA). Required."
  echo "  -s, --start-date <START_DATE> : Start date (DD.MM.YYYY format). Optional."
  echo "  -e, --end-date <END_DATE>     : End date (DD.MM.YYYY format). Optional."
  echo "  -h, --humanize                : Display output in human-readable format. Optional.
  -n, --no-date                   : Exclude date from price series output. Useful for piping prices. Optional."
  echo "  -r, --price-range <RANGE>     : Price range. Required if --end-date is provided without --start-date."
  echo "                                  RANGE values: 1H (1 Week), 1M (1 Month), 3M (3 Months), 6M (6 Months), YTD (Year To Date), 1Y (1 Year), 3Y (3 Years), 5Y (5 Years)."
  echo "  --help                        : Show this help message."
  echo ""
  echo "Date Parameter Logic:"
  echo "  - If only --start-date (-s) is provided, --end-date (-e) defaults to today's date."
  echo "  - If --end-date (-e) is provided, --price-range (-r) becomes mandatory, and the start date is calculated based on this range."
  echo "  - If --price-range (-r) is provided and --end-date (-e) is not, --end-date (-e) defaults to today's date."
  echo ""
  echo "Examples:"
  echo "  ./tefasGetAllFundAnalyzeData.sh -t YAT -c TLY -h -r 1Y"
  echo "  ./tefasGetAllFundAnalyzeData.sh --fund-type YAT --fund-code TLY --start-date 01.01.2025 --end-date 31.01.2025"
  echo "  ./tefasGetAllFundAnalyzeData.sh -t YAT -c TLY -e 31.10.2025 -r 3M"
  echo "  ./tefasGetAllFundAnalyzeData.sh -t YAT -c TLY -s 01.01.2025"
  exit 0
}

if [[ $# -eq 0 ]]; then
  usage
fi

# Default values
FUND_TYPE=""
FUND_CODE=""
START_DATE=""
END_DATE=""
HUMANIZE=""
NO_DATE=""
PRICE_RANGE=""
JQ_PRICE_RANGE=""

# Parametreleri ayrıştırma
TEMP=$(getopt -o "t:c:s:e:hnr:" -l "fund-type:,fund-code:,start-date:,end-date:,humanize,no-date,price-range:,help" -n "$0" -- "$@")
eval set -- "$TEMP"

while true ; do
    case "$1" in
        -t|--fund-type)
            case "$2" in
                "") echo "Error: --fund-type requires a value." ; exit 1 ;;
                *) FUND_TYPE="$2" ; shift 2 ;;
            esac ;;
        -c|--fund-code)
            case "$2" in
                "") echo "Error: --fund-code requires a value." ; exit 1 ;;
                *) FUND_CODE="$2" ; shift 2 ;;
            esac ;;
        -s|--start-date)
            case "$2" in
                "") echo "Error: --start-date requires a value." ; exit 1 ;;
                *) START_DATE="$2" ; shift 2 ;;
            esac ;;
        -e|--end-date)
            case "$2" in
                "") echo "Error: --end-date requires a value." ; exit 1 ;;
                *) END_DATE="$2" ; shift 2 ;;
            esac ;;
        -h|--humanize) HUMANIZE="--humanize" ; shift ;;
        -n|--no-date) NO_DATE="--no-date" ; shift ;;
        -r|--price-range)
            case "$2" in
                "") echo "Error: --price-range requires a value." ; exit 1 ;;
                *) PRICE_RANGE="$2" ; shift 2 ;;
            esac ;;
        --help) usage ; exit 0 ;;
        --) shift ; break ;;
        *) echo "Internal error!" ; exit 1 ;;
    esac
done

# Mandatory parameter check
if [[ -z "$FUND_TYPE" || -z "$FUND_CODE" ]]; then
  echo "Error: --fund-type (-t) and --fund-code (-c) are required parameters."
  echo "Usage: $0 -t <FUND_TYPE> -c <FUND_CODE> [-s <START_DATE>] [-e <END_DATE>] [-h] [-r <RANGE>]"
  echo "Or: $0 --fund-type <FUND_TYPE> --fund-code <FUND_CODE> [--start-date <START_DATE>] [--end-date <END_DATE>] [--humanize] [--price-range <RANGE>]"
  echo "Example: $0 -t YAT -c TLY -h -r 1Y"
  exit 1
fi

# Date validation and calculation logic
# 1. If only START_DATE is given and PRICE_RANGE is not, set END_DATE to today.
if [[ -n "$START_DATE" && -z "$END_DATE" && -z "$PRICE_RANGE" ]]; then
  END_DATE=$(date +%d.%m.%Y)
fi

# 2. If END_DATE is given, PRICE_RANGE is mandatory (if START_DATE is also not given).
if [[ -n "$END_DATE" && -z "$PRICE_RANGE" && -z "$START_DATE" ]]; then
  echo "Error: When --end-date is used, --price-range or --start-date is mandatory."
  echo "Usage: $0 --fund-type <FUND_TYPE> --fund-code <FUND_CODE> [--start-date <START_DATE>] [--end-date <END_DATE>] [--humanize] [--price-range <RANGE>]"
  exit 1
fi

# 3. If PRICE_RANGE is given, calculate START_DATE from END_DATE (which might be today).
if [[ -n "$PRICE_RANGE" ]]; then
  if [[ -z "$END_DATE" ]]; then
    END_DATE=$(date +%d.%m.%Y)
  fi

  # Convert END_DATE to YYYY-MM-DD format for date arithmetic
  END_DATE_YMD=$(echo "$END_DATE" | awk -F'.' '{print $3"-"$2"-"$1}')

  # Map PRICE_RANGE to JQ_PRICE_RANGE for API compatibility
  case "$PRICE_RANGE" in
    1H) JQ_PRICE_RANGE="1H" ;;
    1M) JQ_PRICE_RANGE="1A" ;;
    3M) JQ_PRICE_RANGE="3A" ;;
    6M) JQ_PRICE_RANGE="6A" ;;
    YTD) JQ_PRICE_RANGE="YB" ;;
    1Y) JQ_PRICE_RANGE="1Y" ;;
    3Y) JQ_PRICE_RANGE="3Y" ;;
    5Y) JQ_PRICE_RANGE="5Y" ;;
    *) JQ_PRICE_RANGE="$PRICE_RANGE" ;; # Fallback, though should be caught by earlier error
  esac

  # Calculate START_DATE based on PRICE_RANGE
  case "$PRICE_RANGE" in
    1H) START_DATE=$(date -d "$END_DATE_YMD - 1 week" +%d.%m.%Y) ;;
    1M) START_DATE=$(date -d "$END_DATE_YMD - 1 month" +%d.%m.%Y) ;;
    3M) START_DATE=$(date -d "$END_DATE_YMD - 3 months" +%d.%m.%Y) ;;
    6M) START_DATE=$(date -d "$END_DATE_YMD - 6 months" +%d.%m.%Y) ;;
    YTD) START_DATE=$(date -d "$(echo "$END_DATE_YMD" | cut -d'-' -f1)-01-01" +%d.%m.%Y) ;; # Year To Date
    1Y) START_DATE=$(date -d "$END_DATE_YMD - 1 year" +%d.%m.%Y) ;;
    3Y) START_DATE=$(date -d "$END_DATE_YMD - 3 years" +%d.%m.%Y) ;;
    5Y) START_DATE=$(date -d "$END_DATE_YMD - 5 years" +%d.%m.%Y) ;;
    *) echo "Error: Invalid --price-range value: $PRICE_RANGE" ; exit 1 ;;
  esac
fi

# 4. Final check: If after all calculations, START_DATE or END_DATE are still empty, it's an error.
if [[ -z "$START_DATE" || -z "$END_DATE" ]]; then
  echo "Error: Start and end dates could not be determined. Please use --start-date and --end-date or --price-range parameters correctly."
  echo "Usage: $0 --fund-type <FUND_TYPE> --fund-code <FUND_CODE> [--start-date <START_DATE>] [--end-date <END_DATE>] [--humanize] [--price-range <RANGE>]"
  exit 1
fi

URL="https://www.tefas.gov.tr/api/DB/GetAllFundAnalyzeData"
REFERER="https://www.tefas.gov.tr/FonAnaliz.aspx"

# Headers for WAF bypass
USER_AGENT="Mozilla/5.0 (X11; Linux x86_64; rv:132.0) Gecko/20100101 Firefox/132.0"
ACCEPT="application/json, text/javascript, */*; q=0.01"
ACCEPT_LANGUAGE="tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7"
ACCEPT_ENCODING="gzip, deflate, br"
CONNECTION="keep-alive"
SEC_FETCH_DEST="empty"
SEC_FETCH_MODE="cors"
SEC_FETCH_SITE="same-origin"

# Create temporary file and clean up on exit
TMP=$(mktemp /tmp/tefas_getall_XXXXXX) || { echo "tmpfile creation failed"; exit 1; }
trap 'rm -f "$TMP"' EXIT

# Make the request, save output to tmp
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
  --data "fonTip=$FUND_TYPE&fonKod=$FUND_CODE&bastarih=$START_DATE&bittarih=$END_DATE" \
  --compressed -L -k --max-time 25 -o "$TMP"

# Simple WAF / HTML check: does tmp content contain "<html" or "DOCTYPE"?
if grep -qiE '<html|<!doctype' "$TMP"; then
  echo "⚠️ Muhtemel WAF / HTML yanıtı döndü. İlk 30 satır:"
  head -n 30 "$TMP"
  exit 2
fi

# Humanize option check
if [[ "$HUMANIZE" == "--humanize" ]]; then
  if command -v jq >/dev/null 2>&1; then
    if [[ -n "$PRICE_RANGE" ]]; then
      jq -r --arg pr "$PRICE_RANGE" --arg jq_pr "$JQ_PRICE_RANGE" --arg no_date "$NO_DATE" '
        .fundInfo[0] as $info |
        .fundReturn[0] as $ret |
        .fundProfile[0] as $prof |
        "Fund: \($info.FONKODU) - \($info.FONUNVAN)
Category: \($info.FONKATEGORI) (\($info.KATEGORIDERECE) / \($info.KATEGORIFONSAY))
Investor Count: \($info.YATIRIMCISAYI) | Market Share: \($info.PAZARPAYI)%
Risk: \($prof.RISKDEGERI)

Last Price: \($info.SONFIYAT) TL | Daily Return: \($info.GUNLUKGETIRI)%
Return:
  1 Month: \($ret.GETIRI1A)% | 3 Months: \($ret.GETIRI3A)% | 6 Months: \($ret.GETIRI6A)% | 1 Year: \($ret.GETIRI1Y)%
Portfolio Distribution:
" + (
  .fundAllocation | map("  - \(.KIYMETTIP): \(.PORTFOYORANI)%") | join("\n")
) + "
KAP Link: \($prof.KAPLINK)
Price Series (\($pr)):
" + (
  .[("fundPrices" + $jq_pr)] | map(if $no_date == "--no-date" then "  - Price: \(.FIYAT)" else "  - Date: \(.TARIH), Price: \(.FIYAT)" end) | join("\n")
) + "
--------------------------------------"
      ' "$TMP"
    else
      jq -r '
        .fundInfo[] as $info |
        .fundReturn[] as $ret |
        .fundProfile[] as $prof |
        "Fund: \($info.FONKODU) - \($info.FONUNVAN)
Category: \($info.FONKATEGORI) (\($info.KATEGORIDERECE) / \($info.KATEGORIFONSAY))
Investor Count: \($info.YATIRIMCISAYI) | Market Share: \($info.PAZARPAYI)%
Risk: \($prof.RISKDEGERI)

Last Price: \($info.SONFIYAT) TL | Daily Return: \($info.GUNLUKGETIRI)%
Return:
  1 Month: \($ret.GETIRI1A)% | 3 Months: \($ret.GETIRI3A)% | 6 Months: \($ret.GETIRI6A)% | 1 Year: \($ret.GETIRI1Y)%
Portfolio Distribution:
" + (
  .fundAllocation | map("  - \(.KIYMETTIP): \(.PORTFOYORANI)%") | join("\n")
) + "
KAP Link: \($prof.KAPLINK)
--------------------------------------"
      ' "$TMP"
    fi
  else
    echo "⚠️ jq not found, showing raw JSON:"
    cat "$TMP"
  fi
else
  # Normal pretty-print or specific price range
  if command -v jq >/dev/null 2>&1; then
    if [[ -n "$PRICE_RANGE" ]]; then
      jq --arg pr "$PRICE_RANGE" --arg jq_pr "$JQ_PRICE_RANGE" --arg no_date "$NO_DATE" '.[("fundPrices" + $jq_pr)] | map(if $no_date == "--no-date" then {FIYAT: .FIYAT} else {TARIH: .TARIH, FIYAT: .FIYAT} end)' "$TMP"
    else
      jq . "$TMP" || cat "$TMP"
    fi
  else
    echo "⚠️ jq not found, showing raw JSON:"
    cat "$TMP"
  fi
fi

exit 0
