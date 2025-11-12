#!/usr/bin/env bash
# tefasGetAllFundAnalyzeData.sh
# Kullanım bilgisi için --help parametresini kullanın.

set -euo pipefail

usage() {
  echo "Kullanım: $0 -t <FON_TIPI> -k <FON_KODU> [-s <BAS_TARIH>] [-e <BIT_TARIH>] [-h] [-p <RANGE>]"
  echo "Veya:     $0 --fon-tip <FON_TIPI> --fon-kod <FON_KODU> [--bas-tarih <BAS_TARIH>] [--bit-tarih <BIT_TARIH>] [--humanize] [--price-range <RANGE>]"
  echo ""
  echo "Parametreler:"
  echo "  -t, --fon-tip <FON_TIPI>    : Fon tipi (örn: YAT, EMK). Zorunlu."
  echo "  -k, --fon-kod <FON_KODU>    : Fon kodu (örn: TLY, AFA). Zorunlu."
  echo "  -s, --bas-tarih <BAS_TARIH> : Başlangıç tarihi (GG.AA.YYYY formatında). Opsiyonel."
  echo "  -e, --bit-tarih <BIT_TARIH> : Bitiş tarihi (GG.AA.YYYY formatında). Opsiyonel."
  echo "  -h, --humanize              : Çıktıyı insan tarafından okunabilir formatta gösterir. Opsiyonel."
  echo "  -p, --price-range <RANGE>   : Fiyat aralığı. Eğer --bit-tarih verilirse zorunlu olur."
  echo "                                RANGE değerleri: 1H (1 Hafta), 1A (1 Ay), 3A (3 Ay), 6A (6 Ay), YB (Yıl Başı), 1Y (1 Yıl), 3Y (3 Yıl), 5Y (5 Yıl)."
  echo "  --help                      : Bu yardım menüsünü gösterir."
  echo ""
  echo "Tarih Parametreleri Mantığı:"
  echo "  - Eğer sadece --bas-tarih (-s) verilirse, --bit-tarih (-e) bugünün tarihi olarak kabul edilir."
  echo "  - Eğer --bit-tarih (-e) verilirse, --price-range (-p) zorunlu hale gelir ve başlangıç tarihi bu aralığa göre hesaplanır."
  echo "  - Eğer --price-range (-p) verilirse ve --bit-tarih (-e) verilmezse, --bit-tarih (-e) bugünün tarihi olarak kabul edilir."
  echo ""
  echo "Örnekler:"
  echo "  ./tefasGetAllFundAnalyzeData.sh -t YAT -k TLY -h -p 1Y"
  echo "  ./tefasGetAllFundAnalyzeData.sh --fon-tip YAT --fon-kod TLY --bas-tarih 01.01.2025 --bit-tarih 31.01.2025"
  echo "  ./tefasGetAllFundAnalyzeData.sh -t YAT -k TLY -e 31.10.2025 -p 3A"
  echo "  ./tefasGetAllFundAnalyzeData.sh -t YAT -k TLY -s 01.01.2025"
  exit 0
}

if [[ $# -eq 0 ]]; then
  usage
fi

# Varsayılan değerler
FON_TIPI=""
FON_KODU=""
BAS_TARIH=""
BIT_TARIH=""
HUMANIZE=""
PRICE_RANGE=""

# Parametreleri ayrıştırma
TEMP=$(getopt -o "t:k:s:e:hp:" -l "fon-tip:,fon-kod:,bas-tarih:,bit-tarih:,humanize,price-range:,help" -n "$0" -- "$@")
eval set -- "$TEMP"

while true ; do
    case "$1" in
        -t|--fon-tip)
            case "$2" in
                "") echo "Hata: --fon-tip için değer gerekli." ; exit 1 ;;
                *) FON_TIPI="$2" ; shift 2 ;;
            esac ;;
        -k|--fon-kod)
            case "$2" in
                "") echo "Hata: --fon-kod için değer gerekli." ; exit 1 ;;
                *) FON_KODU="$2" ; shift 2 ;;
            esac ;;
        -s|--bas-tarih)
            case "$2" in
                "") echo "Hata: --bas-tarih için değer gerekli." ; exit 1 ;;
                *) BAS_TARIH="$2" ; shift 2 ;;
            esac ;;
        -e|--bit-tarih)
            case "$2" in
                "") echo "Hata: --bit-tarih için değer gerekli." ; exit 1 ;;
                *) BIT_TARIH="$2" ; shift 2 ;;
            esac ;;
        -h|--humanize) HUMANIZE="--humanize" ; shift ;;
        -p|--price-range)
            case "$2" in
                "") echo "Hata: --price-range için değer gerekli." ; exit 1 ;;
                *) PRICE_RANGE="$2" ; shift 2 ;;
            esac ;;
        --help) usage ; exit 0 ;;
        --) shift ; break ;;
        *) echo "İç hata!" ; exit 1 ;;
    esac
done

# Zorunlu parametre kontrolü
if [[ -z "$FON_TIPI" || -z "$FON_KODU" ]]; then
  echo "Hata: --fon-tip (-t) ve --fon-kod (-k) zorunlu parametrelerdir."
  echo "Kullanım: $0 -t <FON_TIPI> -k <FON_KODU> [-s <BAS_TARIH>] [-e <BIT_TARIH>] [-h] [-p <RANGE>]"
  echo "Veya: $0 --fon-tip <FON_TIPI> --fon-kod <FON_KODU> [--bas-tarih <BAS_TARIH>] [--bit-tarih <BIT_TARIH>] [--humanize] [--price-range <RANGE>]"
  echo "Örnek: $0 -t YAT -k TLY -h -p 1Y"
  exit 1
fi

# Tarih doğrulama ve hesaplama mantığı
# 1. Sadece BAS_TARIH verilmişse ve PRICE_RANGE yoksa, BIT_TARIH'i bugüne ayarla.
if [[ -n "$BAS_TARIH" && -z "$BIT_TARIH" && -z "$PRICE_RANGE" ]]; then
  BIT_TARIH=$(date +%d.%m.%Y)
fi

# 2. BIT_TARIH verilmişse, PRICE_RANGE zorunludur (eğer BAS_TARIH de verilmemişse).
if [[ -n "$BIT_TARIH" && -z "$PRICE_RANGE" && -z "$BAS_TARIH" ]]; then
  echo "Hata: --bit-tarih kullanıldığında --price-range veya --bas-tarih zorunludur."
  echo "Kullanım: $0 --fon-tip <FON_TIPI> --fon-kod <FON_KODU> [--bas-tarih <BAS_TARIH>] [--bit-tarih <BIT_TARIH>] [--humanize] [--price-range <RANGE>]"
  exit 1
fi

# 3. PRICE_RANGE verilmişse, BAS_TARIH'i BIT_TARIH'ten (bugün olabilir) hesapla.
if [[ -n "$PRICE_RANGE" ]]; then
  if [[ -z "$BIT_TARIH" ]]; then
    BIT_TARIH=$(date +%d.%m.%Y)
  fi

  # BIT_TARIH'i YYYY-MM-DD formatına çevir
  BIT_TARIH_YMD=$(echo "$BIT_TARIH" | awk -F'.' '{print $3"-"$2"-"$1}')

  # PRICE_RANGE'e göre BAS_TARIH'i hesapla
  case "$PRICE_RANGE" in
    1H) BAS_TARIH=$(date -d "$BIT_TARIH_YMD - 1 week" +%d.%m.%Y) ;;
    1A) BAS_TARIH=$(date -d "$BIT_TARIH_YMD - 1 month" +%d.%m.%Y) ;;
    3A) BAS_TARIH=$(date -d "$BIT_TARIH_YMD - 3 months" +%d.%m.%Y) ;;
    6A) BAS_TARIH=$(date -d "$BIT_TARIH_YMD - 6 months" +%d.%m.%Y) ;;
    YB) BAS_TARIH=$(date -d "$(echo "$BIT_TARIH_YMD" | cut -d'-' -f1)-01-01" +%d.%m.%Y) ;; # Yılbaşı
    1Y) BAS_TARIH=$(date -d "$BIT_TARIH_YMD - 1 year" +%d.%m.%Y) ;;
    3Y) BAS_TARIH=$(date -d "$BIT_TARIH_YMD - 3 years" +%d.%m.%Y) ;;
    5Y) BAS_TARIH=$(date -d "$BIT_TARIH_YMD - 5 years" +%d.%m.%Y) ;;
    *) echo "Hata: Geçersiz --price-range değeri: $PRICE_RANGE" ; exit 1 ;;
  esac
fi

# 4. Tüm hesaplamalardan sonra BAS_TARIH veya BIT_TARIH hala boşsa hata ver.
if [[ -z "$BAS_TARIH" || -z "$BIT_TARIH" ]]; then
  echo "Hata: Başlangıç ve bitiş tarihleri belirlenemedi. Lütfen --bas-tarih ve --bit-tarih veya --price-range parametrelerini doğru kullanın."
  echo "Kullanım: $0 --fon-tip <FON_TIPI> --fon-kod <FON_KODU> [--bas-tarih <BAS_TARIH>] [--bit-tarih <BIT_TARIH>] [--humanize] [--price-range <RANGE>]"
  exit 1
fi

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
  --data "fonTip=$FON_TIPI&fonKod=$FON_KODU&bastarih=$BAS_TARIH&bittarih=$BIT_TARIH" \
  --compressed -L -k --max-time 25 -o "$TMP"

# Basit WAF / HTML kontrolü: tmp içeriğinde "<html" veya "DOCTYPE" var mı?
if grep -qiE '<html|<!doctype' "$TMP"; then
  echo "⚠️ Muhtemel WAF / HTML yanıtı döndü. İlk 30 satır:"
  head -n 30 "$TMP"
  exit 2
fi

# Humanize opsiyonu kontrolü
if [[ "$HUMANIZE" == "--humanize" ]]; then
  if command -v jq >/dev/null 2>&1; then
    if [[ -n "$PRICE_RANGE" ]]; then
      jq -r --arg pr "$PRICE_RANGE" '
        .fundInfo[0] as $info |
        .fundReturn[0] as $ret |
        .fundProfile[0] as $prof |
        "Fon: \($info.FONKODU) - \($info.FONUNVAN)
Kategori: \($info.FONKATEGORI) (\($info.KATEGORIDERECE) / \($info.KATEGORIFONSAY))
Yatırımcı Sayısı: \($info.YATIRIMCISAYI) | Pazar Payı: \($info.PAZARPAYI)%
Risk: \($prof.RISKDEGERI)

Son Fiyat: \($info.SONFIYAT) TL | Günlük Getiri: \($info.GUNLUKGETIRI)%
Getiri:
  1 Ay: \($ret.GETIRI1A)% | 3 Ay: \($ret.GETIRI3A)% | 6 Ay: \($ret.GETIRI6A)% | 1 Yıl: \($ret.GETIRI1Y)%
Portföy Dağılımı:
" + (
  .fundAllocation | map("  - \(.KIYMETTIP): \(.PORTFOYORANI)%") | join("\n")
) + "
KAP Link: \($prof.KAPLINK)
Fiyat Serisi (\($pr)):
" + (
  .[("fundPrices" + $pr)] | map("  - Tarih: \(.TARIH), Fiyat: \(.FIYAT)") | join("\n")
) + "
--------------------------------------"
      ' "$TMP"
    else
      jq -r '
        .fundInfo[] as $info |
        .fundReturn[] as $ret |
        .fundProfile[] as $prof |
        "Fon: \($info.FONKODU) - \($info.FONUNVAN)
Kategori: \($info.FONKATEGORI) (\($info.KATEGORIDERECE) / \($info.KATEGORIFONSAY))
Yatırımcı Sayısı: \($info.YATIRIMCISAYI) | Pazar Payı: \($info.PAZARPAYI)%
Risk: \($prof.RISKDEGERI)

Son Fiyat: \($info.SONFIYAT) TL | Günlük Getiri: \($info.GUNLUKGETIRI)%
Getiri:
  1 Ay: \($ret.GETIRI1A)% | 3 Ay: \($ret.GETIRI3A)% | 6 Ay: \($ret.GETIRI6A)% | 1 Yıl: \($ret.GETIRI1Y)%
Portföy Dağılımı:
" + (
  .fundAllocation | map("  - \(.KIYMETTIP): \(.PORTFOYORANI)%") | join("\n")
) + "
KAP Link: \($prof.KAPLINK)
--------------------------------------"
      ' "$TMP"
    fi
  else
    echo "⚠️ jq bulunamadı, ham JSON gösteriliyor:"
    cat "$TMP"
  fi
else
  # Normal pretty-print veya belirli fiyat aralığı
  if command -v jq >/dev/null 2>&1; then
    if [[ -n "$PRICE_RANGE" ]]; then
      jq --arg pr "$PRICE_RANGE" '.[("fundPrices" + $pr)] | map({TARIH: .TARIH, FIYAT: .FIYAT})' "$TMP"
    else
      jq . "$TMP" || cat "$TMP"
    fi
  else
    echo "⚠️ jq bulunamadı, ham JSON gösteriliyor:"
    cat "$TMP"
  fi
fi

exit 0
