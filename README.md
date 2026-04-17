## TEFAS Scraper

TEFAS (Türkiye Elektronik Fon Dağılım Platformu) verilerini çekmek, analiz etmek ve Gemini/CLI üzerinden erişim sağlamak için hazırlanmış bir araç seti.

Özet
-----
- MCP sunucusu ve komut satırı arayüzü (CLI) sağlar.
- TEFAS'ın açık API uç noktalarından fon analizleri, tarihsel veriler ve karşılaştırmalı raporlar alır.

Özellikler
---------
- MCP (FastMCP) araçları: `analyze_fund`, `get_fund_history_info`, `get_fund_allocation_history`, `compare_fund_returns`, `compare_fund_sizes`, `compare_fund_fees`.
- CLI modunda doğrudan çağrılabilir: `python mcp_server.py --cli <command>`.
- Alternatif HTTP API (FastAPI) örneği: `tefas_scraper_extension/main.py`.

Gereksinimler
------------
- Python 3.12+ (önerilir)
- Python bağımlılıkları: `pip install -r requirements.txt`

Kurulum
-------
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

Hızlı Başlangıç
---------------
- MCP sunucusu (stdio transport, Gemini ile entegrasyon için):

```bash
python mcp_server.py
```

- CLI örnekleri:

```bash
# Fon analizi (price range ile)
python mcp_server.py --cli analyze --fund-type YAT --fund-code TTE --price-range 1M --pretty

# Tarihsel bilgi (history-info)
python mcp_server.py --cli history-info --fund-code TTE --start-date 2024-01-01 --end-date 2024-01-31 --pretty

# Portföy dağılımı geçmişi
python mcp_server.py --cli history-allocation --fund-code TTE --start-date 2024-01-01 --end-date 2024-01-31 --pretty

# Getiri karşılaştırması
python mcp_server.py --cli compare-returns --fund-type YAT --periods 0,0,0,1,0,0,0 --pretty

# Büyüklük karşılaştırması (DD.MM.YYYY formatıyla)
python mcp_server.py --cli compare-sizes --start-date 01.01.2024 --end-date 31.01.2024 --pretty
```

- FastAPI (alternatif HTTP) çalıştırma:

```bash
uvicorn tefas_scraper_extension.main:app --reload --port 8000
```

API / MCP Araçları
------------------
- `analyze_fund` — parametreler: `fund_type` (zorunlu), `fund_code` (zorunlu), `start_date` (DD.MM.YYYY), `end_date` (DD.MM.YYYY), `price_range` (1H,1M,3M,6M,YTD,1Y,3Y,5Y).
- `get_fund_history_info` — parametreler: `fund_code`, `start_date` (YYYY-MM-DD), `end_date` (YYYY-MM-DD), `fund_type` (opsiyonel).
- `get_fund_allocation_history` — aynı format ve zorunluluklar `get_fund_history_info` ile uyumlu.
- `compare_fund_returns` — `fund_type` ve `periods` (ör. `1,1,1,1,1,1,1`).
- `compare_fund_sizes` — tarihler DD.MM.YYYY formatında beklenir.
- `compare_fund_fees` — `fund_type` parametresi.

Tarih Formatlarına Dikkat
------------------------
- `analyze_fund` ve bazı karşılaştırma araçları DD.MM.YYYY tarih formatı bekler.
- `history-*` uç noktaları YYYY-MM-DD formatı bekler.
Karışık formatlar geçersiz girişlere veya `ValueError` hatalarına yol açabilir. Lütfen örnekleri dikkatle takip edin.

Test Etme / CLI Kombinasyonlarını Deneme
---------------------------------------
Aşağıdaki küçük komut dosyası, CLI komutlarını ve tipik argüman kombinasyonlarını çalıştırıp hata veren kombinasyonları yakalamaya uygundur. Bu, gerçek TEFAS çağrıları gerçekleştireceği için dikkatle ve kısıtlı sıklıkta çalıştırınız.

```bash
#!/usr/bin/env bash
set +e
echo "Basit CLI testi başlıyor..."
commands=(
	"python mcp_server.py --cli analyze --fund-type YAT --fund-code TTE --price-range 1M --pretty"
	"python mcp_server.py --cli analyze --fund-code TTE --price-range 1M --pretty"  # eksik fund-type -> parser hatası
	"python mcp_server.py --cli history-info --fund-code TTE --start-date 2024-01-01 --end-date 2024-01-31 --pretty"
	"python mcp_server.py --cli history-info --fund-code TTE --start-date 01.01.2024 --end-date 31.01.2024 --pretty" # yanlış format -> ValueError beklenir
	"python mcp_server.py --cli compare-sizes --start-date 01.01.2024 --end-date 31.01.2024 --pretty"
)

for cmd in "${commands[@]}"; do
	echo "=> $cmd"
	eval $cmd
	rc=$?
	if [ $rc -ne 0 ]; then
		echo "FAILED (exit $rc): $cmd"
	else
		echo "OK: $cmd"
	fi
	echo "---"
done
```

Not: Bu script hataları yakalayacak, ancak asıl amaç hangi argüman kombinasyonunun servis veya kodda hata çıkardığını gözlemlemektir. Eğer `history-info` için DD.MM.YYYY formatı gönderirseniz `ValueError` alırsınız; bu davranış bilinmektedir.

Troubleshooting (Hızlı İpuçları)
--------------------------------
- Eğer `ValueError: Invalid date format` görüyorsanız, doğru formatı kullandığınızdan emin olun (endpoint'e bağlı olarak DD.MM.YYYY veya YYYY-MM-DD).
- `Failed to decode JSON` veya aldığınız cevap HTML içeriyorsa (WAF/robot engellemesi), istek frekansı veya User-Agent nedeniyle servis tarafından engellenmiş olabilirsiniz.
- Boş yanıt (`Empty response from server`) dönerse parametreleri kontrol edin.
- `BrokenPipeError` ile karşılaşırsanız, çıktıyı küçük parçalara bölün veya `--pretty` seçeneğini kaldırın.

Geliştirme ve Katkı
-------------------
- Test eklemek için `pytest` ve `responses`/`requests-mock` kullanılması önerilir.
- Önerilen ilk PR'lar: (1) `requirements.txt` için versiyon sabitleme, (2) test iskeleti (`tests/`), (3) TLS ve retry iyileştirmesi.

Test Sonuçları (Yerel)
----------------------
Testler yerel venv içinde çalıştırıldı. Sonuç: `3 passed`.

Lisans
-----
Projede bir `LICENSE` dosyası bulunmaktadır; lisans koşullarına uyun.

---

**Not**: Bash scriptler `tefasUrlExploration/` klasöründe referans için saklanmaktadır.
