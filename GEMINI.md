# TEFAS Scraper - Project Overview

Bu proje, TEFAS (Turkey Electronic Fund Distribution Platform) verilerini çekmek için **Model Context Protocol (MCP) server** ve **CLI tool** sağlar.

## Temel Teknolojiler

*   **Python 3.12:** Ana programlama dili
*   **FastMCP:** MCP server implementasyonu  
*   **Gemini CLI:** MCP client olarak kullanılır
*   **requests:** TEFAS API çağrıları için HTTP client
*   **python-dateutil:** Tarih hesaplamaları için

## Proje Yapısı

```
tefas_scraper/
├── mcp_server.py              # Ana dosya: MCP server + CLI tool (tek dosya, standalone)
├── requirements.txt           # Python bağımlılıkları
├── .gemini/settings.json      # MCP server kaydı (Gemini CLI için)
├── tefas_scraper_extension/   # Eski implementasyon (opsiyonel FastAPI server)
│   ├── main.py                # FastAPI alternatif server
│   └── scraper.py             # TefasScraper sınıfı (artık mcp_server.py içinde)
└── tefasUrlExploration/       # Legacy bash scriptler (referans için)
```

## Ana Dosya: mcp_server.py

**Özellikler:**
- ✅ Tek standalone dosya
- ✅ Hem MCP server hem CLI tool olarak çalışır
- ✅ TefasScraper sınıfı dahil (external dependency yok)
- ✅ Komut satırından doğrudan kullanılabilir
- ✅ Gemini CLI ile entegre

## MCP Araçları (MCP Tools)

Server üç ana araç sunar:

### 1. `analyze_fund`
Kapsamlı fon analizi verileri (getiriler, portföy dağılımı, risk metrikleri, fiyat serileri).

**Parametreler:**
- `fund_type`: Fon tipi (ör: YAT, EMK)
- `fund_code`: Fon kodu (ör: TTE, TLY, AFA)
- `start_date`: Başlangıç tarihi (DD.MM.YYYY) - opsiyonel
- `end_date`: Bitiş tarihi (DD.MM.YYYY) - opsiyonel
- `price_range`: Zaman aralığı (1H, 1M, 3M, 6M, YTD, 1Y, 3Y, 5Y) - opsiyonel

### 2. `get_fund_history_info`
Tarihsel bağlayıcı bilgiler (fiyat, katılımcı sayısı, portföy büyüklüğü).

**Parametreler:**
- `fund_code`: Fon kodu
- `start_date`: Başlangıç tarihi (YYYY-MM-DD)
- `end_date`: Bitiş tarihi (YYYY-MM-DD)
- `fund_type`: Fon tipi (varsayılan: "ALL")

### 3. `get_fund_allocation_history`
Tarihsel portföy dağılım verileri.

**Parametreler:** `get_fund_history_info` ile aynı

## Kurulum (Installation)

```bash
# 1. Bağımlılıkları yükle
pip install -r requirements.txt

# 2. MCP server otomatik olarak .gemini/settings.json'a kayıtlı

# 3. Kaydı doğrula
gemini mcp list
```

## Kullanım (Usage)

### 1. Gemini CLI ile (MCP Server)

```bash
# Fon analizi
gemini "TLY fonu için son 1 aylık analiz verilerini getir" -y

# Tarihsel bilgi
gemini "TTE fonu için 2024-01-01 ve 2024-01-31 arası genel bilgileri getir" -y

# Portföy dağılımı
gemini "AFA fonunun Ocak 2024 portföy dağılımını göster" -y

# Karşılaştırma
gemini "TLY ve DFI fonu için son 1 aylık analiz verileriyle karşılaştır" -y
```

### 2. Komut Satırı (CLI) ile

```bash
# Fon analizi
python mcp_server.py --cli analyze --fund-type YAT --fund-code TTE --price-range 1M --pretty

# Tarihsel bilgi
python mcp_server.py --cli history-info --fund-code TTE --start-date 2024-01-01 --end-date 2024-01-31 --pretty

# Portföy dağılımı
python mcp_server.py --cli history-allocation --fund-code TTE --start-date 2024-01-01 --end-date 2024-01-31 --pretty

# Help
python mcp_server.py --help
```

### 3. Python Modülü Olarak

```python
# mcp_server.py içindeki TefasScraper sınıfını kullan
from mcp_server import TefasScraper

scraper = TefasScraper()

# Fon analizi
result = scraper.get_fund_analysis("YAT", "TTE", price_range="1M")

# Tarihsel bilgi
result = scraper.get_history("BindHistoryInfo", "TTE", "2024-01-01", "2024-01-31")
```

## Test Sonuçları

### ✅ CLI Testi
```bash
$ python mcp_server.py --cli analyze --fund-type YAT --fund-code TTE --price-range 1M --pretty
# Başarıyla gerçek TEFAS verileri döndü
```

### ✅ Gemini CLI Testi
```bash
$ gemini "TLY fonu için son 1 aylık analiz verilerini getir" -y
# Çıktı:
TERA PORTFÖY BİRİNCİ SERBEST FON (TLY) için son 1 aylık analiz verileri:
- Son Fiyat: 2646.246782
- Günlük Getiri: %1.1338
- 1 Aylık Getiri: %28.979564
...
```

## Teknik Detaylar

### Mimari Kararlar
1. **Tek Dosya:** Tüm fonksiyonalite `mcp_server.py` içinde (standalone)
2. **Dual Mode:** Aynı dosya hem MCP server hem CLI tool olarak çalışır
3. **No External Modules:** TefasScraper sınıfı dahili (sadece pip dependencies)
4. **WAF Protection:** Uygun headers ve referer kullanımı
5. **Error Handling:** Structured JSON hata yanıtları

### Bağımlılıklar
```
fastapi           # Sadece eski main.py için
uvicorn[standard] # Sadece eski main.py için
python-multipart  # Sadece eski main.py için
requests          # ✅ Aktif kullanımda
python-dateutil   # ✅ Aktif kullanımda
fastmcp           # ✅ MCP server için
```

## Legacy Dosyalar

### tefas_scraper_extension/
- `main.py`: FastAPI server (alternatif, opsiyonel)
- `scraper.py`: Eski TefasScraper sınıfı (artık mcp_server.py içinde)

### tefasUrlExploration/
Bash scriptler ve API keşif araçları. Referans için saklanıyor, aktif kullanımda değil.

## Git Workflow

```bash
# Checkpoint oluştur
git add .
git commit -m "feat: MCP server with CLI support - standalone single file"

# Branch'ler arası geçiş
git checkout -b feature/new-endpoint  # Yeni özellik için
git checkout main                      # Ana branch'e dön
git merge feature/new-endpoint         # Başarılı özelliği merge et
```

## Geliştirme Notları

*   MCP server stdio transport kullanır (Gemini CLI entegrasyonu için)
*   Tüm API çağrıları WAF koruması içerir
*   Hata yönetimi structured JSON döndürür
*   CLI exit code'ları: 0 (başarılı), 1 (hata)

## Başarı Kriterleri

✅ MCP server Gemini CLI ile çalışıyor  
✅ CLI mode komut satırından çalışıyor  
✅ Tek standalone dosya (mcp_server.py)  
✅ Gerçek TEFAS verileri alınıyor  
✅ Test edildi ve doğrulandı
