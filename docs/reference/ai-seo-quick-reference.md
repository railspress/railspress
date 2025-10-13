# AI SEO Plugin - Quick Reference

**One-page cheat sheet for AI-powered SEO generation**

---

## 🚀 Quick Setup

```
1. Admin → Plugins → AI SEO → Activate
2. Plugins → AI SEO → Settings
3. Choose Provider: OpenAI
4. Enter API Key: sk-...
5. Select Model: gpt-3.5-turbo
6. Save Settings
```

**Done! SEO auto-generates on publish.**

---

## ⚙️ Essential Settings

```ruby
AI Provider: openai | anthropic | google
API Key: YOUR_KEY_HERE (required)
Model: gpt-3.5-turbo (cheap) or gpt-4 (quality)

Auto-Generate on Save: No  (save API costs)
Auto-Generate on Publish: Yes (generate when ready)
Overwrite Existing: No (preserve manual edits)

Use Response Cache: Yes (reduce costs 90%)
Cache TTL: 24 hours
```

---

## 📊 What Gets Generated

```
✅ Meta Title (60 chars, SEO-optimized)
✅ Meta Description (160 chars, compelling)
✅ Meta Keywords (5 relevant keywords)
✅ Focus Keyphrase (primary keyword)
✅ OG Title (social media)
✅ OG Description (social sharing)
✅ Twitter Title (Twitter card)
✅ Twitter Description (Twitter card)
```

---

## 🔌 API Endpoints

### Generate SEO
```bash
POST /api/v1/ai_seo/generate
Body: {"content_type": "post", "content_id": 123}
```

### Analyze Content
```bash
POST /api/v1/ai_seo/analyze
Body: {"content": "text...", "title": "Title"}
```

### Batch Generate
```bash
POST /api/v1/ai_seo/batch_generate
Body: {"content_type": "post", "content_ids": [1,2,3]}
```

### Check Status
```bash
GET /api/v1/ai_seo/status
```

---

## 💰 Cost Optimization

```
1. Use GPT-3.5 Turbo ($0.002/request)
2. Enable caching (90% savings)
3. Only auto-generate on publish
4. Set rate limit: 100/hour
5. Use batch processing

Result: $0.02-0.20/month for typical blog
```

---

## 🎯 Use Cases

### Automatic (Recommended)
```
1. Create/edit post
2. Publish
3. AI auto-generates SEO
4. Done!
```

### Manual (Editor)
```
1. Edit post/page
2. Click "Generate SEO with AI"
3. Wait 3-5 seconds
4. SEO fields auto-populate
5. Review and save
```

### API (Programmatic)
```javascript
await fetch('/api/v1/ai_seo/generate', {
  method: 'POST',
  body: JSON.stringify({
    content_type: 'post',
    content_id: 123
  })
});
```

---

## 🔧 Common Settings

### Conservative (Low Cost)
```
Provider: OpenAI
Model: gpt-3.5-turbo
Auto on Save: No
Auto on Publish: Yes
Cache: Yes, 48 hours
Rate Limit: 50/hour
```

### Balanced (Recommended)
```
Provider: OpenAI
Model: gpt-3.5-turbo
Auto on Save: No
Auto on Publish: Yes
Cache: Yes, 24 hours
Rate Limit: 100/hour
```

### Premium (Quality)
```
Provider: Anthropic
Model: claude-3-opus
Auto on Save: Yes
Auto on Publish: Yes
Cache: Yes, 12 hours
Rate Limit: 200/hour
```

---

## ✅ Checklist

### Initial Setup
- [ ] Activate plugin
- [ ] Enter API key
- [ ] Select model
- [ ] Configure auto-generation
- [ ] Enable caching
- [ ] Set rate limits
- [ ] Save settings

### Testing
- [ ] Create test post
- [ ] Click "Generate SEO"
- [ ] Verify meta tags appear
- [ ] Check API usage
- [ ] Test auto-generation

### Optimization
- [ ] Enable caching
- [ ] Disable auto-save generation
- [ ] Set appropriate rate limits
- [ ] Monitor costs

---

## 🎨 Example Output

**Input:**
```
Title: "Getting Started with Rails"
Content: "Ruby on Rails is a powerful web framework..."
```

**AI Output:**
```
Meta Title: "Rails Guide: Getting Started with Ruby on Rails | 2025"
Meta Description: "Learn Ruby on Rails from scratch. Complete beginner guide with examples, best practices, and expert tips. Start building web apps today."
Keywords: "ruby on rails, rails tutorial, web development, rails guide, programming"
Focus: "ruby on rails tutorial"
```

---

## 📞 Quick Links

| Resource | URL |
|----------|-----|
| **Activate Plugin** | /admin/plugins |
| **Configure** | /admin/plugins/[id]/settings |
| **API Docs** | `AI_SEO_PLUGIN_GUIDE.md` |
| **OpenAI** | https://platform.openai.com |
| **Anthropic** | https://console.anthropic.com |

---

## 🆘 Need Help?

**Check logs:**
```bash
tail -f log/development.log | grep "AI SEO"
```

**Test API:**
```bash
curl http://localhost:3000/api/v1/ai_seo/status
```

**Enable debug logging:**
```
Settings → Advanced → Log AI Responses: Yes
```

---

**Full Guide**: `AI_SEO_PLUGIN_GUIDE.md`

*RailsPress AI SEO Plugin v1.0.0*



