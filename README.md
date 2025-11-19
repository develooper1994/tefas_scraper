# TEFAS Scraper

TEFAS (Turkey Electronic Fund Distribution Platform) verilerini çekmek için **MCP Server** ve **CLI Tool**.

## Özellikler

- ✅ **MCP Server**: Gemini CLI ile entegre Model Context Protocol sunucusu
- ✅ **CLI Tool**: Komut satırından doğrudan kullanılabilir
- ✅ **Tek Dosya**: Tüm fonksiyonalite `mcp_server.py` içinde
- ✅ **Gerçek Zamanlı Veri**: TEFAS API'den canlı veriler

## Hızlı Başlangıç

### Kurulum

```bash
# 1. Bağımlılıkları yükle
pip install -r requirements.txt

# 2. MCP server'ı doğrula
gemini mcp list
```

### Kullanım

#### 1. Gemini CLI ile (Önerilen)

```bash
# Fon analizi
gemini "TLY fonu için son 1 aylık analiz verilerini getir" -y

# Karşılaştırma
gemini "TLY ve DFI fonu için son 1 aylık analiz verileriyle karşılaştır" -y

# Tarihsel bilgi
gemini "TTE fonu için 2024-01-01 ve 2024-01-31 arası genel bilgileri getir" -y
```

#### 2. Komut Satırı ile

```bash
# Fon analizi
python mcp_server.py --cli analyze --fund-type YAT --fund-code TTE --price-range 1M --pretty

# Tarihsel bilgi
python mcp_server.py --cli history-info --fund-code TTE --start-date 2024-01-01 --end-date 2024-01-31 --pretty

# Portföy dağılımı
python mcp_server.py --cli history-allocation --fund-code TTE --start-date 2024-01-01 --end-date 2024-01-31 --pretty

# Yardım
python mcp_server.py --help
```

#### 3. Python Modülü Olarak

```python
from mcp_server import TefasScraper

scraper = TefasScraper()

# Fon analizi
result = scraper.get_fund_analysis("YAT", "TTE", price_range="1M")
print(result)

# Tarihsel bilgi
result = scraper.get_history("BindHistoryInfo", "TTE", "2024-01-01", "2024-01-31")
print(result)
```

## MCP Araçları

Server üç ana araç sunar:

### `analyze_fund`
Kapsamlı fon analizi (getiriler, portföy dağılımı, risk metrikleri, fiyat serileri)

**Parametreler:**
- `fund_type`: Fon tipi (YAT, EMK, BYF, GYF, GSYF)
- `fund_code`: Fon kodu (ör: TTE, TLY, AFA)
- `start_date`: Başlangıç tarihi (DD.MM.YYYY) - opsiyonel
- `end_date`: Bitiş tarihi (DD.MM.YYYY) - opsiyonel
- `price_range`: Zaman aralığı (1H, 1M, 3M, 6M, YTD, 1Y, 3Y, 5Y) - opsiyonel

### `get_fund_history_info`
Tarihsel genel bilgiler (fiyat, katılımcı sayısı, portföy büyüklüğü)

**Parametreler:**
- `fund_code`: Fon kodu
- `start_date`: Başlangıç (YYYY-MM-DD)
- `end_date`: Bitiş (YYYY-MM-DD)
- `fund_type`: Fon tipi (varsayılan: "ALL")

### `get_fund_allocation_history`
Tarihsel portföy dağılımı

**Parametreler:** `get_fund_history_info` ile aynı

## Fon Türleri

- **YAT**: Menkul Kıymet Yatırım Fonu
- **EMK**: BES (Bireysel Emeklilik Sistemi) Yatırım Fonu
- **BYF**: Borsa Yatırım Fonu
- **GYF**: Gayrimenkul Yatırım Fonu
- **GSYF**: Girişim Sermayesi Yatırım Fonu

## Dönen Veriler

### BindHistoryInfo (Genel Bilgi)
- Unix timestamp (saniye)
- Son fiyat bilgisi
- Fonun tam adı
- Tedavüldeki pay sayısı
- Yatırımcı sayısı
- Portföy büyüklüğü

### BindHistoryAllocation (Portföy Dağılımı)
- Unix timestamp (saniye)
- Fonun tam adı
- Varlık dağılımı (null olanlar hariç)

### GetAllFundAnalyzeData (Kapsamlı Analiz)
- Fon bilgileri (tam ad, kategori, sıralama)
- Portföy büyüklüğü ve yatırımcı sayısı
- Günlük getiri ve son fiyat
- Getiri oranları (1A, 3A, 6A, 1Y, 3Y, 5Y)
- Risk değeri
- Portföy dağılımı
- Fiyat serileri (1H, 1A, 3A, 6A, YB, 1Y, 3Y, 5Y)
- KAP linki

## Tarih Formatları

- **CLI ve analyze_fund**: `DD.MM.YYYY` (örn: `15.11.2025`)
- **history araçları**: `YYYY-MM-DD` (örn: `2025-11-15`)

## Zaman Aralıkları (Price Range)

- `1H`: Son 1 hafta
- `1M`: Son 1 ay
- `3M`: Son 3 ay
- `6M`: Son 6 ay
- `YTD`: Yıl başından bugüne
- `1Y`: Son 1 yıl
- `3Y`: Son 3 yıl
- `5Y`: Son 5 yıl

## Proje Yapısı

```
tefas_scraper/
├── mcp_server.py              # Ana dosya (MCP server + CLI tool)
├── requirements.txt           # Python bağımlılıkları
├── .gemini/settings.json      # MCP server kaydı
├── tefas_scraper_extension/   # Eski implementasyon (opsiyonel)
└── tefasUrlExploration/       # Legacy bash scriptler (referans)
```

## Test Edilmiş Örnekler

```bash
# ✅ Başarılı Test 1: Gemini CLI
$ gemini "TLY fonu için son 1 aylık analiz verilerini getir" -y
# Çıktı: TERA PORTFÖY BİRİNCİ SERBEST FON (TLY)
#        Son Fiyat: 2646.246782, Günlük Getiri: %1.1338, 1 Aylık: %28.979564

# ✅ Başarılı Test 2: CLI Tool
$ python mcp_server.py --cli analyze --fund-type YAT --fund-code TTE --price-range 1M --pretty
# Gerçek TEFAS verileri JSON formatında
```

## Bağımlılıklar

```
requests          # HTTP client
python-dateutil   # Tarih hesaplamaları
fastmcp           # MCP server
```

## Teknik Detaylar

- **Dil**: Python 3.12+
- **Transport**: stdio (MCP)
- **WAF Koruması**: Otomatik header ve referer yönetimi
- **Hata Yönetimi**: Structured JSON responses
- **Session Yönetimi**: Persistent HTTP session

## Lisans

Bu proje açık kaynaklıdır.

---

**Not**: Legacy bash scriptler `tefasUrlExploration/` klasöründe referans için saklanmaktadır.
