# Gemini CLI Extension Mağazasında Yayınlama Rehberi

## 🎯 Özet

`geminicli.com/extensions/` sitesinde extension'ınızın görünmesi için şu adımları izleyin:

## ✅ Ön Hazırlık (Tamamlandı)

- [x] Extension GitHub'da public repo olarak yayınlandı
- [x] `gemini-extension.json` mevcut
- [x] `GEMINI.md` context file hazır
- [x] README.md dokümantasyonu var
- [x] Extension local olarak test edildi

## 📋 Yayınlama Adımları

### 1. GitHub Repository Hazırlığı

```bash
# Tag oluştur
git tag v1.0.0
git push origin v1.0.0

# GitHub'da Release oluştur
# https://github.com/develooper1994/tefas_scraper/releases/new
```

**Release Bilgileri:**
- **Tag:** v1.0.0
- **Title:** TEFAS Scraper v1.0.0 - MCP Server & CLI Tool
- **Description:** 
  ```markdown
  ## 🚀 Features
  - MCP Server for Gemini CLI integration
  - CLI tool for command-line usage
  - Real-time TEFAS fund data
  - Three analysis tools:
    - analyze_fund
    - get_fund_history_info
    - get_fund_allocation_history
  
  ## 📦 Installation
  \`\`\`bash
  gemini extensions install https://github.com/develooper1994/tefas_scraper
  \`\`\`
  
  ## 🧪 Quick Test
  \`\`\`bash
  gemini "TLY fonu için son 1 aylık analiz verilerini getir" -y
  \`\`\`
  ```

### 2. Repository Metadata Güncelleme

GitHub repo settings'den:

1. **About** bölümünü düzenle:
   - **Description:** "TEFAS data scraper MCP server for Gemini CLI"
   - **Topics (tags):** 
     - `gemini-cli`
     - `gemini-extension`
     - `mcp-server`
     - `tefas`
     - `turkish-finance`
     - `fund-analysis`

2. **Homepage:** `https://github.com/develooper1994/tefas_scraper`

3. **License:** Ekle (MIT veya Apache 2.0 önerilen)

### 3. Extension Installation Test

Kullanıcıların kurulum yapabilmesini test et:

```bash
# Başka bir makinede veya temiz bir dizinde
gemini extensions install https://github.com/develooper1994/tefas_scraper

# Test
gemini "TTE fonu analizi" -y
```

### 4. Community Visibility

#### A. Official Gallery'de Görünmek (Önerilen)

**Seçenek 1: GitHub Stars & Adoption (Organik)**
- Extension'ı GitHub'da paylaş
- README.md'yi detaylı yaz
- Examples ve screenshots ekle
- Community adoption arttıkça otomatik olarak featured olabilir

**Seçenek 2: Direct Contact (Hızlandırılmış)**
Google'ın Gemini CLI team'ine ulaş:
- Google Cloud Console support
- GitHub issue: https://github.com/google-gemini/gemini-cli
- Community forums

**Seçenek 3: Partner Program**
- Google Cloud Partner olarak başvur
- Official partner extension olarak listelenebilir

#### B. Community Promotion

1. **GitHub README**
   ```markdown
   ## 📦 Installation
   
   Install directly from Gemini CLI:
   \`\`\`bash
   gemini extensions install https://github.com/develooper1994/tefas_scraper
   \`\`\`
   ```

2. **Blog Post / Medium Article**
   - "Building a TEFAS Scraper for Gemini CLI"
   - Use case scenarios
   - Screenshots

3. **Social Media**
   - Twitter/X: @GoogleDevs mention
   - LinkedIn tech groups
   - Reddit: r/GoogleCloud, r/Gemini

4. **Documentation Site**
   - GitHub Pages
   - Detailed usage guide
   - Video tutorial (opsiyonel)

### 5. Kalite Standartları

Extension'ın featured olması için:

- [x] Clear README with examples
- [x] Working installation via `gemini extensions install`
- [x] Comprehensive GEMINI.md for AI context
- [x] Error handling
- [x] Good documentation
- [ ] Video demo (opsiyonel)
- [ ] CI/CD tests (opsiyonel)

## 📊 Mevcut Durum

### ✅ Hazır Olanlar:
- GitHub repo: https://github.com/develooper1994/tefas_scraper
- Working MCP server
- Installation package in `gemini-extension/`
- Comprehensive documentation

### 🔄 Yapılacaklar:

1. **Hemen:**
   ```bash
   # Tag ve Release oluştur
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. **GitHub Settings:**
   - About description ekle
   - Topics/tags ekle
   - License ekle (LICENSE dosyası)

3. **Promotion:**
   - README.md'ye installation badge ekle
   - Screenshots ekle
   - Social media paylaş

4. **Google Contact (Opsiyonel):**
   - Google Cloud support'a extension hakkında bilgi ver
   - Featured extension olmak için başvur

## 🎯 Installation URL

Kullanıcılar extension'ı şöyle kurabilir:

```bash
# Direct GitHub install
gemini extensions install https://github.com/develooper1994/tefas_scraper

# Veya belli bir version
gemini extensions install https://github.com/develooper1994/tefas_scraper --ref v1.0.0
```

## 📈 Tracking Success

Extension başarısını takip et:

- GitHub Stars
- Installation sayısı (GitHub traffic)
- Issues/PR contributions
- Social media mentions

## 🔮 Gelecek Adımlar

Extension popüler oldukça:
1. Official gallery'de featured olabilir
2. Google blog post'unda bahsedilebilir
3. Partner program'a davet alabilirsin
4. Gemini CLI showcase'inde gösterilebilir

---

**Önemli Not:** `geminicli.com/extensions/` sitesi Google tarafından yönetiliyor. Featured olmak için Google'ın internal review sürecinden geçmen gerekebilir. Ancak, GitHub'da yayınlayarak extension'ı herkes kullanabilir!
