# 🔐 RailsPress Login Credentials

## Admin Access

**Email**: `admin@railspress.com`  
**Password**: `password`

---

## How to Access

### 1. Login Page
Visit: **http://localhost:3000/auth/sign_in**

### 2. Admin Dashboard
After login: **http://localhost:3000/admin**

### 3. Template Customizer (GrapesJS)
**http://localhost:3000/admin/template_customizer**

### 4. Theme File Editor (Monaco)
**http://localhost:3000/admin/theme_editor**

### 5. GraphQL Playground
**http://localhost:3000/graphiql**

---

## Quick Login Steps

1. Open browser to: `http://localhost:3000/auth/sign_in`
2. Enter email: `admin@railspress.com`
3. Enter password: `password`
4. Click "Log in"
5. You'll be redirected to the admin dashboard

---

## Change Password (Recommended!)

### Via Admin Interface
1. Login
2. Click your email in top-right
3. Go to "Profile Settings"
4. Change password

### Via Console
```ruby
rails console

user = User.find_by(email: 'admin@railspress.com')
user.update!(password: 'your-new-secure-password', password_confirmation: 'your-new-secure-password')
```

### Via CLI
```bash
./bin/railspress-cli user update 1 --password=new-password
```

---

## Create Additional Users

### Via Admin
1. Login
2. Go to Users
3. Click "Add New"
4. Fill in details

### Via CLI
```bash
./bin/railspress-cli user create editor@example.com --role=editor --password=secure123
```

### Via Console
```ruby
User.create!(
  email: 'editor@example.com',
  password: 'secure123',
  password_confirmation: 'secure123',
  role: 'editor'
)
```

---

## Available Roles

| Role | Capabilities |
|------|--------------|
| **administrator** | Full system access |
| **editor** | Edit all posts/pages |
| **author** | Create own posts |
| **contributor** | Submit for review |
| **subscriber** | Read-only access |

---

## Troubleshooting

### Forgot Password?

**Reset via console:**
```ruby
rails console

user = User.find_by(email: 'admin@railspress.com')
user.update!(password: 'newpass', password_confirmation: 'newpass')
```

### Can't Access Admin?

**Check user role:**
```ruby
rails console

user = User.find_by(email: 'admin@railspress.com')
puts user.role  # Should be "administrator"
user.update!(role: 'administrator') if user.role != 'administrator'
```

### Session Issues?

**Clear sessions:**
```bash
rails console

# Clear all sessions
Rails.cache.clear
```

---

## Security Notes

⚠️ **Important**: Change the default password immediately in production!

**For production:**
1. Use strong passwords (16+ characters)
2. Enable two-factor authentication (Devise 2FA ready)
3. Limit admin user access
4. Monitor login attempts
5. Use HTTPS only

---

## Quick Access Commands

```bash
# Check who's logged in (console)
rails console
User.administrators

# Create new admin
./bin/railspress-cli user create newadmin@example.com --role=administrator

# List all users
./bin/railspress-cli user list

# Reset admin password
rails runner "User.find_by(email: 'admin@railspress.com').update!(password: 'newpass', password_confirmation: 'newpass')"
```

---

**Now you can access everything!** 🎉

**Login URL**: http://localhost:3000/auth/sign_in



