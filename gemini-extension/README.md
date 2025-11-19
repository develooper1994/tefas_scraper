# Gemini CLI Extension

Bu klasör TEFAS Scraper'ı Gemini CLI extension olarak yüklemek için gerekli dosyaları içerir.

## Kurulum

### Otomatik Kurulum (Önerilen)

```bash
cd gemini-extension
./install.sh
```

### Manuel Kurulum

1. Extension klasörünü oluşturun:
```bash
mkdir -p ~/.gemini/extensions/tefas-scraper
```

2. Dosyaları kopyalayın:
```bash
cp GEMINI.md ~/.gemini/extensions/tefas-scraper/
cp EXTENSION_README.md ~/.gemini/extensions/tefas-scraper/README.md
```

3. `gemini-extension.json` oluşturun ve path'leri güncelleyin:
```json
{
  "name": "tefas-scraper",
  "version": "1.0.0",
  "description": "TEFAS data scraper for Gemini CLI",
  "mcpServers": {
    "tefas_scraper": {
      "command": "/path/to/venv/bin/python",
      "args": ["/path/to/mcp_server.py"],
      "env": {}
    }
  },
  "contextFileName": "GEMINI.md"
}
```

4. Doğrulayın:
```bash
gemini extensions list | grep tefas
```

## Dosyalar

- **install.sh**: Otomatik kurulum scripti
- **gemini-extension.json.template**: Extension config template
- **GEMINI.md**: AI context file (Gemini'ye talimatlar)
- **EXTENSION_README.md**: Extension dokümantasyonu

## Mağazada Yayınlama

Bu extension'ı Gemini CLI extension mağazasında yayınlamak isterseniz:

1. GitHub repo oluşturun
2. Release tag'i oluşturun (v1.0.0)
3. Gemini extension registry'ye PR gönderin

## Lisans

Open Source
