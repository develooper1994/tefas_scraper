# TEFAS Scraper - Gemini CLI Extension

TEFAS (Turkey Electronic Fund Distribution Platform) fon verilerini Gemini CLI ile kolayca çekin.

## Kurulum

Extension otomatik olarak yüklü. Kontrol edin:

```bash
gemini extensions list | grep tefas
```

## Hızlı Kullanım

```bash
# Fon analizi
gemini "TLY fonu için son 1 aylık analiz verilerini getir" -y

# Karşılaştırma  
gemini "TLY ve DFI fonlarını karşılaştır" -y

# Tarihsel veri
gemini "TTE fonu için 2024 ocak ayı portföy dağılımını göster" -y
```

## Özellikler

- ✅ Gerçek zamanlı TEFAS verileri
- ✅ Fon analizi ve karşılaştırma
- ✅ Tarihsel portföy dağılımı
- ✅ Risk metrikleri ve getiri hesaplamaları

## Dokümantasyon

Detaylı bilgi için `GEMINI.md` dosyasına bakın.

## Lisans

Open Source
