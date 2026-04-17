#!/usr/bin/env bash
# TEFAS tefasFundRequest.sh - [EXPERIMENTAL] Direct ASP.NET Page Request
#
# NOTE: This script is purely experimental and NOT intended for automated data extraction.
# It returns the full ASP.NET generated HTML page instead of structured JSON.
# DO NOT TEST in automated pipelines.

set -euo pipefail

# 🔧 Gereken komutlar kontrolü
for cmd in curl; do
  command -v $cmd >/dev/null 2>&1 || {
    echo "❌ Required command not found: $cmd"
    exit 1
  }
done

# 📚 Help function
usage() {
  echo "Usage: $0 -c <fund_code>"
  echo "Makes a direct request to the fund analysis page."
  echo ""
  echo "Options:"
  echo "  -c, --fund-code      TEFAS fund code (e.g., 'TTE', 'AFA')"
  echo "  -h, --help           Display this help message."
  exit 0
}

# 🔹 Default values
FUND_CODE=""

# 🔹 Parse arguments
TEMP=$(getopt -o c:h --long fund-code:,help -n 'tefasFundRequest.sh' -- "$@")
if [ $? != 0 ]; then echo "Terminating..." >&2; exit 1; fi
eval set -- "$TEMP"

while true; do
  case "$1" in
    -c | --fund-code ) FUND_CODE="$2"; shift 2 ;;
    -h | --help ) usage ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

if [[ -z "$FUND_CODE" ]]; then
  echo "❌ Error: Fund code is mandatory."
  usage
fi

COOKIES_FILE=$(mktemp)
# Note: This is a GET request to the main aspx page
URL="https://www.tefas.gov.tr/FonAnaliz.aspx?FonKod=$FUND_CODE"

echo "⚠️  Executing experimental request for $FUND_CODE..." >&2

# 🔹 Execution (No JSON parsing here as it returns HTML)
curl -s -c "$COOKIES_FILE" \
  -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
  -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8" \
  "$URL"

rm -f "$COOKIES_FILE"
