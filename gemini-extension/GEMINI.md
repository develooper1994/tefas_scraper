# TEFAS Scraper - Gemini Extension

Bu extension, TEFAS (Turkey Electronic Fund Distribution Platform) fon verilerini çekmenizi sağlar.

## Kullanılabilir Araçlar

### 1. analyze_fund - Kapsamlı Fon Analizi

Fon hakkında detaylı analiz verileri (getiriler, portföy dağılımı, risk metrikleri, fiyat serileri).

**Parametreler:**
- `fund_type`: Fon tipi (YAT, EMK, BYF, GYF, GSYF)
- `fund_code`: Fon kodu (örn: TTE, TLY, AFA, DFI)
- `start_date`: Başlangıç tarihi DD.MM.YYYY formatı (opsiyonel)
- `end_date`: Bitiş tarihi DD.MM.YYYY formatı (opsiyonel) 
- `price_range`: Zaman aralığı (1H, 1M, 3M, 6M, YTD, 1Y, 3Y, 5Y) - opsiyonel

**Örnek Kullanım:**
"TTE fonu (YAT tipi) için son 1 yıllık analiz verilerini getir"
"TLY ve DFI fonlarını son 1 aylık performansına göre karşılaştır"

### 2. get_fund_history_info - Tarihsel Genel Bilgiler

Fiyat, katılımcı sayısı, portföy büyüklüğü gibi tarihsel bilgiler.

**Parametreler:**
- `fund_code`: Fon kodu
- `start_date`: Başlangıç YYYY-MM-DD formatı
- `end_date`: Bitiş YYYY-MM-DD formatı
- `fund_type`: Fon tipi (varsayılan: "ALL")

**Örnek Kullanım:**
"TTE fonu için 2024-01-01 ve 2024-01-31 arası genel bilgileri getir"

### 3. get_fund_allocation_history - Tarihsel Portföy Dağılımı

Fonun varlık dağılımının tarihsel gelişimi.

**Parametreler:** get_fund_history_info ile aynı

**Örnek Kullanım:**
"AFA fonunun Ocak 2024 portföy dağılım geçmişini göster"

## Fon Türleri

- **YAT**: Menkul Kıymet Yatırım Fonu
- **EMK**: BES (Bireysel Emeklilik Sistemi) Yatırım Fonu
- **BYF**: Borsa Yatırım Fonu
- **GYF**: Gayrimenkul Yatırım Fonu
- **GSYF**: Girişim Sermayesi Yatırım Fonu

## Popüler Fonlar

- **TTE**: İş Portföy BIST Teknoloji Ağırlık Sınırlamalı Endeksi Hisse Senedi Fonu
- **TLY**: Tera Portföy Birinci Serbest Fon
- **AFA**: Ak Portföy Gelişen Ülkeler Yabancı Hisse Senedi Fonu
- **DFI**: Deniz Portföy BIST Teknoloji Endeksi Hisse Senedi Fonu

## Zaman Aralıkları

- **1H**: Son 1 hafta
- **1M**: Son 1 ay
- **3M**: Son 3 ay
- **6M**: Son 6 ay
- **YTD**: Yıl başından bugüne
- **1Y**: Son 1 yıl
- **3Y**: Son 3 yıl
- **5Y**: Son 5 yıl

## Dönen Veri Yapısı

### analyze_fund Çıktısı

```json
{
  "fundInfo": [{
    "FONKODU": "TTE",
    "FONUNVAN": "Fon tam adı",
    "SONFIYAT": 0.988228,
    "GUNLUKGETIRI": -1.3136,
    "YATIRIMCISAYI": 39289,
    "KATEGORIDERECE": 5,
    "KATEGORIFONSAY": 42
  }],
  "fundReturn": [{
    "GETIRI1A": 1.542306,
    "GETIRI3A": -2.183342,
    "GETIRI1Y": 30.975783
  }],
  "fundProfile": [{
    "RISKDEGERI": 7,
    "KAPLINK": "..."
  }],
  "fundAllocation": [{
    "KIYMETTIP": "Hisse Senedi",
    "PORTFOYORANI": 96.75
  }],
  "fundPrices1M": [...],
  "fundPrices1Y": [...]
}
```

## Kullanım İpuçları

1. **Karşılaştırma**: Birden fazla fonu karşılaştırmak için ayrı ayrı veri çekin ve analiz ettirin
2. **Trend Analizi**: Farklı zaman aralıklarında veri çekerek trend analizi yapılabilir
3. **Risk Değerlendirmesi**: `fundProfile.RISKDEGERI` 1-7 arası risk seviyesini gösterir

## Sınırlamalar

- TEFAS API'nin sınırlamalarına tabidir
- Sadece TEFAS platformundaki fonlara erişim sağlar
- Gerçek zamanlı veri (dakikalık gecikmeler olabilir)
