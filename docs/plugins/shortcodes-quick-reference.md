# Shortcodes Quick Reference

## 📝 Content Shortcodes

### Button
```
[button url="/contact" style="primary" size="medium"]Click Me[/button]
```
Styles: primary, secondary, success, danger
Sizes: small, medium, large

### Alert Box
```
[alert type="info"]Your message here[/alert]
```
Types: info, success, warning, danger

### Recent Posts
```
[recent_posts count="5" category="tech"]
```

### Code Block
```
[code lang="ruby"]
puts "Hello World"
[/code]
```

## 🎨 Layout Shortcodes

### Columns
```
[columns count="2"]
Content split into columns
[/columns]
```
Count: 2-4

### Toggle/Spoiler
```
[toggle title="Click to reveal"]
Hidden content here
[/toggle]
```

### Accordion
```
[accordion]
[accordion_item title="Question 1"]Answer 1[/accordion_item]
[accordion_item title="Question 2"]Answer 2[/accordion_item]
[/accordion]
```

## 🖼️ Media Shortcodes

### Gallery
```
[gallery ids="1,2,3" columns="3" size="medium"]
```
Columns: 1-6
Size: thumbnail, medium, large

### YouTube
```
[youtube id="VIDEO_ID"]
```

## 💼 Business Shortcodes

### Pricing Table
```
[pricing title="Pro Plan" price="29" period="month" 
         features="Feature 1|Feature 2|Feature 3" 
         button_text="Subscribe" button_url="/subscribe"]
```

### Testimonial
```
[testimonial author="John Doe" role="CEO, Company Inc"]
This product changed my life!
[/testimonial]
```

### Progress Bar
```
[progress percentage="75" label="Completion" color="green"]
```
Colors: blue, green, red, yellow, purple

### Countdown
```
[countdown date="2025-12-31"]
```

## 📞 Forms

### Contact Form
```
[contact_form email="contact@example.com"]
```

## 🔧 Quick Tips

- Test shortcodes at `/admin/shortcodes`
- Copy examples with one click
- Nest shortcodes for complex layouts
- Plugins can add custom shortcodes
- All shortcodes work in posts and pages

## 📚 Full Documentation

See `SHORTCODES_GUIDE.md` for complete details.



