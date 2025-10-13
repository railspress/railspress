# Theme Switching - Complete Test Guide

**Ensure themes work correctly in both admin and frontend**

---

## 🎯 What To Test

Theme switching should work seamlessly in:
1. **Admin Panel** - View active theme, switch themes
2. **Frontend** - Display active theme immediately
3. **Preview** - Test themes before activating
4. **Persistence** - Theme choice persists across sessions

---

## ✅ Complete Testing Checklist

### Part 1: Initial State

- [ ] Login to admin: http://localhost:3000/admin
- [ ] Go to **Themes**: http://localhost:3000/admin/themes
- [ ] Verify you see:
  - Green status bar showing "Currently Active on Frontend: Default"
  - Active theme card with "✓ Active" badge
  - Available themes grid (Default, Dark, ScandiEdge)
  - Each theme has "Activate" and "Preview" buttons

### Part 2: Theme Switching in Admin

**Test switching from Default to Dark theme:**

1. [ ] Find **"Dark"** theme in the grid
2. [ ] Click **"Activate"** button
3. [ ] Confirm the activation dialog
4. [ ] Verify you see success message: "✓ Theme 'Dark' activated successfully!"
5. [ ] Verify status bar now shows: "Currently Active: Dark"
6. [ ] Verify Dark theme card now has "Current Theme" label
7. [ ] Verify Default theme now has "Activate" button

**Test switching to ScandiEdge:**

8. [ ] Click **"Activate"** on ScandiEdge theme
9. [ ] Confirm activation
10. [ ] Verify success message appears
11. [ ] Verify status bar updates to "ScandiEdge"

### Part 3: Frontend Verification

**Verify theme changes reflect on frontend:**

1. [ ] Click **"View Live Site"** button (top right)
2. [ ] Or click **"Open Frontend"** in status bar
3. [ ] Or visit: http://localhost:3000
4. [ ] Verify the frontend shows the active theme style:
   - **Default**: Classic design with light colors
   - **Dark**: Dark background, high contrast
   - **ScandiEdge**: Minimal Scandinavian design

**Test each theme:**

5. [ ] Switch to **Default** in admin
6. [ ] Visit frontend - should show Default theme
7. [ ] Switch to **Dark** in admin
8. [ ] Visit frontend - should show Dark theme
9. [ ] Switch to **ScandiEdge** in admin
10. [ ] Visit frontend - should show ScandiEdge theme

### Part 4: Preview Function

**Test theme preview without activating:**

1. [ ] Go back to Admin → Themes
2. [ ] Find a non-active theme
3. [ ] Click **"Preview"** button (eye icon)
4. [ ] New tab opens with preview
5. [ ] Verify preview shows the theme
6. [ ] Close preview tab
7. [ ] Verify actual frontend still shows active theme (unchanged)

**Preview all themes:**

8. [ ] Preview Default theme
9. [ ] Preview Dark theme
10. [ ] Preview ScandiEdge theme
11. [ ] Verify each looks different

### Part 5: Persistence Test

**Verify theme persists across sessions:**

1. [ ] Activate **ScandiEdge** theme
2. [ ] Logout of admin
3. [ ] Visit frontend: http://localhost:3000
4. [ ] Verify ScandiEdge is still active
5. [ ] Login again
6. [ ] Go to Admin → Themes
7. [ ] Verify ScandiEdge shows as active
8. [ ] Refresh frontend
9. [ ] Verify ScandiEdge still active

### Part 6: Customization Workflow

**Test theme customization:**

1. [ ] Activate a theme (any)
2. [ ] Click **"Customize Theme"** in status bar
3. [ ] Verify template customizer opens
4. [ ] Make a change (edit some text)
5. [ ] Save changes
6. [ ] Visit frontend
7. [ ] Verify your changes appear
8. [ ] Switch to another theme
9. [ ] Verify frontend changes to new theme
10. [ ] Switch back to customized theme
11. [ ] Verify customizations are preserved

### Part 7: Multi-Tab Testing

**Test theme switching with multiple tabs:**

1. [ ] Open frontend in Tab 1
2. [ ] Open admin themes in Tab 2
3. [ ] Note current theme in Tab 1
4. [ ] Switch theme in Tab 2
5. [ ] Refresh Tab 1
6. [ ] Verify Tab 1 shows new theme

### Part 8: Error Handling

**Test edge cases:**

1. [ ] Try to activate non-existent theme (if possible)
2. [ ] Verify error message appears
3. [ ] Try to delete active theme
4. [ ] Verify warning: "Cannot delete active theme"
5. [ ] Activate a different theme
6. [ ] Delete the previously active theme
7. [ ] Verify deletion succeeds

---

## 🎨 Visual Verification

### Default Theme
**Check for:**
- Light background
- Classic navigation
- Standard footer
- Simple card designs

### Dark Theme
**Check for:**
- Dark background (#1a1a1a)
- High contrast text
- Dark cards
- Light text on dark backgrounds

### ScandiEdge Theme
**Check for:**
- Minimal design
- Scandinavian colors (off-white, sage, blue)
- Inter font
- Modern components
- Dark mode toggle

---

## 🔧 Troubleshooting

### Issue: Theme doesn't change on frontend

**Solutions:**
1. **Clear cache:**
   ```bash
   rails cache:clear
   ```

2. **Restart server:**
   ```bash
   ./railspress restart
   ```

3. **Hard refresh browser:**
   - Chrome/Firefox: Cmd+Shift+R (Mac) or Ctrl+Shift+R (Windows)

4. **Check database:**
   ```ruby
   # In rails console
   Theme.active.first.name  # Should match what you activated
   ```

### Issue: Preview shows wrong theme

**Solutions:**
1. Check URL has `?theme=theme_name` parameter
2. Verify theme exists in `app/themes/theme_name/`
3. Check theme has `views/` directory
4. Check theme has `layouts/application.html.erb`

### Issue: Theme activation fails

**Solutions:**
1. Check theme directory structure:
   ```
   app/themes/theme_name/
   ├── config.yml
   ├── theme.rb
   ├── views/
   └── assets/
   ```

2. Verify config.yml is valid YAML
3. Check Rails logs for errors
4. Ensure theme name is lowercase with underscores

### Issue: Changes don't apply immediately

**Solutions:**
1. Theme switching requires view path reload
2. In development: Changes apply immediately
3. In production: May need server restart
4. Clear browser cache if CSS doesn't update

---

## 📝 Expected Behavior

### When Activating a Theme (Admin)

**Immediate:**
1. ✅ Database updated (`themes` table, `active` column)
2. ✅ View paths cleared and reloaded
3. ✅ Theme initializer executed
4. ✅ Success message shown
5. ✅ Status bar updates
6. ✅ Theme card shows "Current Theme"

**On Frontend Request:**
1. ✅ ApplicationController loads theme via Themeable concern
2. ✅ Theme views directory prepended to view paths
3. ✅ Theme's `layouts/application.html.erb` used
4. ✅ Theme assets loaded
5. ✅ Theme helpers available

### Theme Hierarchy

**View Resolution Order:**
```
1. app/themes/[active_theme]/views/
2. app/views/
3. Rails default views
```

**Example:**
```
Request: GET /posts/123
Active Theme: scandiedge

Lookup order:
1. app/themes/scandiedge/views/posts/show.html.erb  ✅ (used if exists)
2. app/views/posts/show.html.erb                    (fallback)
```

---

## 🧪 Automated Test Script

Save this as a test script to verify theme switching:

```ruby
# test/theme_switching_test.rb
require 'test_helper'

class ThemeSwitchingTest < ActionDispatch::IntegrationTest
  test "theme switches on activation" do
    # Login as admin
    post auth_sign_in_path, params: {
      user: { email: 'admin@railspress.com', password: 'password' }
    }
    
    # Activate Dark theme
    patch activate_admin_theme_path('dark')
    assert_redirected_to admin_themes_path
    
    # Verify theme is active in database
    assert Theme.find_by(name: 'Dark').active?
    
    # Visit frontend
    get root_path
    assert_response :success
    
    # Verify Dark theme layout is used
    # (Check for Dark theme-specific elements)
  end
  
  test "preview doesn't affect active theme" do
    # Activate Default theme
    Railspress::ThemeLoader.activate_theme('default')
    
    # Preview Dark theme
    get theme_preview_path(theme: 'dark')
    assert_response :success
    
    # Verify Default is still active
    assert_equal 'Default', Theme.active.first.name
  end
end
```

---

## 📊 Test Results Checklist

After completing all tests, you should have verified:

### Database
- [x] Active theme marked in `themes` table
- [x] Only one theme active at a time
- [x] Theme activation persists

### Admin Panel
- [x] Active theme shown in status bar
- [x] Theme cards show correct status
- [x] Activation button works
- [x] Preview button works
- [x] Success/error messages appear

### Frontend
- [x] Active theme renders correctly
- [x] Theme styles apply
- [x] Theme layouts used
- [x] Theme assets load

### Preview
- [x] Preview opens in new tab
- [x] Preview shows correct theme
- [x] Preview doesn't affect active theme
- [x] Can preview all themes

### Switching
- [x] Can switch between all themes
- [x] Changes apply immediately
- [x] No errors in logs
- [x] Browser cache doesn't interfere

---

## 🚀 Quick Test

**5-Minute Verification:**

```
1. Login: http://localhost:3000/admin
2. Go to: Themes
3. Activate: Dark theme
4. Visit: Frontend (new tab)
5. Verify: Dark theme active ✓

6. Return to: Admin → Themes
7. Activate: ScandiEdge theme
8. Refresh: Frontend tab
9. Verify: ScandiEdge theme active ✓

10. Return to: Admin → Themes
11. Activate: Default theme
12. Refresh: Frontend tab
13. Verify: Default theme active ✓
```

**All 3 theme switches working = ✅ PASS**

---

## 📦 Available Themes

### 1. Default Theme
**Path**: `app/themes/default/`
**Style**: Classic, clean, professional
**Colors**: Blues and grays
**Best for**: Blogs, content sites

### 2. Dark Theme
**Path**: `app/themes/dark/`
**Style**: Dark mode, high contrast
**Colors**: Blacks and whites
**Best for**: Modern, tech-focused sites

### 3. ScandiEdge Theme
**Path**: `app/themes/scandiedge/`
**Style**: Minimal Scandinavian design
**Colors**: Off-white, sage, blue accents
**Features**: Dark mode toggle, Inter font
**Best for**: Modern, professional brands

---

## 🔄 Theme Activation Flow

```
┌─────────────────────┐
│ Admin clicks        │
│ "Activate" button   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Confirm dialog      │
│ shows               │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ POST to activate    │
│ endpoint            │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ ThemeLoader:        │
│ 1. Deactivate old   │
│ 2. Activate new     │
│ 3. Clear paths      │
│ 4. Setup new paths  │
│ 5. Load initializer │
│ 6. Clear cache      │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Redirect to themes  │
│ Show success msg    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Status bar updates  │
│ "Currently Active"  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ User visits         │
│ frontend            │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ New theme renders   │
│ immediately         │
└─────────────────────┘
```

---

## 🎨 Visual Differences Between Themes

### Default Theme
```
Header: White background, blue links
Content: Light cards, gray backgrounds
Footer: Simple, 3 columns
Font: System default
```

### Dark Theme
```
Header: Black background (#1a1a1a)
Content: Dark cards, white text
Footer: Dark, high contrast
Font: System default
```

### ScandiEdge Theme
```
Header: Minimal, off-white (#fafafa)
Content: Clean cards, muted colors
Footer: Scandinavian style, organized
Font: Inter (custom)
Special: Dark mode toggle button
```

---

## 🔍 What to Look For

### Admin Panel (After Activation)

**Status Bar:**
```
✅ Shows "Currently Active on Frontend: [Theme Name]"
✅ Has "Customize Theme" button
✅ Has "Open Frontend" button
```

**Theme Cards:**
```
✅ Active theme shows "Current Theme" label
✅ Active theme has emerald border
✅ Inactive themes show "Activate" button
✅ All themes have "Preview" button
```

**Feedback:**
```
✅ Success message after activation
✅ Page updates without manual refresh
✅ No errors in browser console
```

### Frontend (After Activation)

**Visual Changes:**
```
✅ Header changes style
✅ Content changes layout/colors
✅ Footer changes design
✅ Overall feel matches theme
```

**Technical:**
```
✅ Correct theme CSS loads
✅ Theme assets load
✅ No missing images
✅ No 404 errors
✅ No JavaScript errors
```

---

## 🚀 Quick Verification Commands

### Check Active Theme (Rails Console)

```ruby
# Start Rails console
rails console

# Check active theme
Theme.active.first.name
# => "Default" or "Dark" or "Scandiedge"

# Check theme loader
Railspress::ThemeLoader.current_theme
# => "default" or "dark" or "scandiedge"
```

### Check View Paths

```ruby
# In Rails console
ActionController::Base.view_paths.paths.map(&:to_s)
# Should include: "/path/to/app/themes/[active_theme]/views"
```

### Verify Database

```sql
-- Check themes table
SELECT name, active FROM themes;

-- Should show one active = true
```

---

## 📊 Test Matrix

| Test | Default | Dark | ScandiEdge | Result |
|------|---------|------|------------|--------|
| Activate from admin | ✓ | ✓ | ✓ | PASS |
| Renders on frontend | ✓ | ✓ | ✓ | PASS |
| Preview works | ✓ | ✓ | ✓ | PASS |
| Persists on refresh | ✓ | ✓ | ✓ | PASS |
| Shows in status bar | ✓ | ✓ | ✓ | PASS |
| Customization works | ✓ | ✓ | ✓ | PASS |

**All tests PASS = Theme switching works correctly ✅**

---

## 🎯 Success Criteria

Theme switching is working correctly if:

✅ **Admin shows active theme** in status bar  
✅ **Clicking "Activate" switches theme** immediately  
✅ **Frontend reflects changes** on refresh  
✅ **Preview doesn't affect active theme**  
✅ **Theme persists** across sessions  
✅ **No errors** in console or logs  
✅ **All 3 themes** can be activated  
✅ **Customizations persist** per theme  

---

## 💡 Pro Tips

### Tip 1: Use Preview First
Before activating, click "Preview" to see how the theme looks with your content.

### Tip 2: Have Frontend Open
Keep a frontend tab open while switching themes in admin to see changes immediately.

### Tip 3: Clear Cache
If theme doesn't change, run:
```bash
./railspress cache:clear
```

### Tip 4: Check Browser Console
Open browser dev tools to catch any asset loading errors.

### Tip 5: Test with Real Content
Create some posts/pages before testing themes to see how they render actual content.

---

## 📞 Access Points

| Feature | URL |
|---------|-----|
| **Admin Themes** | http://localhost:3000/admin/themes |
| **Frontend** | http://localhost:3000 |
| **Theme Customizer** | http://localhost:3000/admin/template_customizer |
| **Preview Default** | http://localhost:3000/themes/preview?theme=default |
| **Preview Dark** | http://localhost:3000/themes/preview?theme=dark |
| **Preview ScandiEdge** | http://localhost:3000/themes/preview?theme=scandiedge |

**Login:**
- Email: `admin@railspress.com`
- Password: `password`

---

## ✅ Final Verification

**Run this complete flow:**

```
1. Start server: ./railspress start
2. Login to admin
3. Go to Themes
4. Current theme: Note which is active
5. Switch to: Different theme
6. Success message: Should appear
7. Status bar: Should update
8. Frontend visit: Should show new theme
9. Switch back: To original theme
10. Frontend refresh: Should show original
```

**If all 10 steps work perfectly:**
## ✅ THEME SWITCHING VERIFIED ✅

---

**Test Duration**: 10-15 minutes  
**Complexity**: Medium  
**Required**: Admin access  
**Tools Needed**: Web browser, Rails console (optional)

---

*Ensure your themes work perfectly everywhere!* 🎨✨



