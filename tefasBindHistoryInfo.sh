#!/usr/bin/env bash
# tefasBindHistoryInfo.sh
# TEFAS BindHistoryInfo sorgulayıcı (humanize)
# Kullanım: ./tefasBindHistoryInfo.sh [FONTIP] [BAŞTARİH] [BİTTARİH] [FONKOD] [--humanize]

set -euo pipefail

FONTIP=${1:-YAT}
BASTARIH=${2:-$(date '+%d.%m.%Y')}
BITTARIH=${3:-${BASTARIH}}
FONKOD=${4:-}
HUMANIZE=false

if [[ "${5:-}" == "--humanize" ]]; then
  HUMANIZE=true
fi

REQUIRED_CMDS=(curl jq)
for cmd in "${REQUIRED_CMDS[@]}"; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "❌ '${cmd}' yüklü değil. Lütfen yükleyin." >&2
    exit 1
  fi
done

# kısaltmalar JSON olarak
FIELDS_JSON='{
  "FIYAT":"Fon Fiyatı",
  "TEDPAYSAYISI":"Tedavüldeki Pay Sayısı",
  "KISISAYISI":"Katılımcı Sayısı",
  "PORTFOYBUYUKLUK":"Portföy Büyüklüğü",
  "BORSABULTENFIYAT":"Borsa Bülten Fiyatı"
}'

response=$(curl -s -X POST "https://www.tefas.gov.tr/api/DB/BindHistoryInfo" \
  -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)" \
  -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" \
  -H "Origin: https://www.tefas.gov.tr" \
  -H "Referer: https://www.tefas.gov.tr/TarihselVeriler.aspx" \
  -H "X-Requested-With: XMLHttpRequest" \
  --data "fontip=${FONTIP}&bastarih=${BASTARIH}&bittarih=${BITTARIH}&fonkod=${FONKOD}" \
  --max-time 30)

if ! printf '%s' "$response" | jq empty >/dev/null 2>&1; then
  echo "❌ Geçersiz yanıt veya WAF engeli:"
  echo "---------------------------------------------"
  printf '%s\n' "$response" | head -n 20
  exit 1
fi

if ! $HUMANIZE; then
  printf '%s\n' "$response" | jq .
  exit 0
fi

# --humanize aktifse okunabilir çıktı
printf '%s\n' "$response" | jq -r --argjson fields "$FIELDS_JSON" '
  def human_date($v):
    if ($v == null) then "" 
    else ($v | tonumber? // null) as $n 
      | if $n == null then ($v|tostring) else ($n/1000 | tonumber | strftime("%Y-%m-%d")) end
    end;

  if (.data | length) == 0 then
    "Veri bulunamadı."
  else
    .data[] |
    (
      "📅 Tarih: " + (human_date(.TARIH)) + "\n" +
      "🏷  Fon Kodu: " + (.FONKODU // "-") + "\n" +
      "📘 Fon Unvanı: " + (.FONUNVAN // "-") + "\n" +
      (
        del(.TARIH, .FONKODU, .FONUNVAN)
        | to_entries
        | map(
            "- " + .key + " (" + ($fields[.key] // "Açıklama yok") + "): " + ((.value // "")|tostring)
          )
        | join("\n")
      ) + "\n---------------------------------------------"
    )
  end
'
