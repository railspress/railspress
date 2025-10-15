# Toggle Switches Guide

This guide covers the minimalistic toggle switch system implemented for RailsPress admin interface. All checkboxes in the admin area are automatically styled as modern toggle switches.

## Features

- **Automatic Styling**: All `input[type="checkbox"]` elements are automatically styled as toggle switches
- **Minimalistic Design**: Clean, modern appearance with smooth animations
- **Accessibility**: Full keyboard navigation, screen reader support, and ARIA compliance
- **Responsive**: Works perfectly on desktop and mobile devices
- **Dark Mode**: Automatic adaptation to dark themes
- **Multiple Sizes**: Small, default, and large variants
- **Color Variants**: Default, success, warning, and danger colors
- **Special States**: Loading, error, success, and disabled states

## Basic Usage

### Automatic Styling

All checkboxes are automatically styled as toggle switches:

```erb
<!-- This will automatically become a toggle switch -->
<%= check_box_tag 'setting', '1', false %>

<!-- Form checkboxes are also automatically styled -->
<%= form.check_box :active %>
```

### Helper Methods

Use the provided helper methods for better structure and consistency:

```erb
<!-- Simple toggle switch with label -->
<%= toggle_switch_tag('setting', '1', false, 'Enable Feature') %>

<!-- Toggle switch with description -->
<%= toggle_switch_tag('setting', '1', false, 'Enable Feature', 
    description: 'Turn this feature on or off') %>

<!-- Form integration -->
<%= form_with model: @model do |form| %>
  <%= toggle_switch(form, :active, 'Active Status', 
      description: 'Enable or disable this item') %>
<% end %>
```

## Helper Methods

### Basic Helpers

#### `toggle_switch_tag(name, value, checked, label_text, **options)`
Creates a toggle switch with a label.

```erb
<%= toggle_switch_tag('notifications', '1', false, 'Email Notifications') %>
```

#### `toggle_switch(form, field_name, label_text, **options)`
Creates a toggle switch for a form field.

```erb
<%= form_with model: @post do |form| %>
  <%= toggle_switch(form, :published, 'Published') %>
<% end %>
```

### Size Variants

#### `small_toggle_switch_tag(name, value, checked, label_text, **options)`
Creates a small toggle switch.

```erb
<%= small_toggle_switch_tag('setting', '1', false, 'Compact Setting') %>
```

#### `large_toggle_switch_tag(name, value, checked, label_text, **options)`
Creates a large toggle switch.

```erb
<%= large_toggle_switch_tag('setting', '1', false, 'Large Setting') %>
```

### Color Variants

#### `success_toggle_switch_tag(name, value, checked, label_text, **options)`
Creates a green success toggle switch.

```erb
<%= success_toggle_switch_tag('feature', '1', true, 'Feature Enabled') %>
```

#### `warning_toggle_switch_tag(name, value, checked, label_text, **options)`
Creates an amber warning toggle switch.

```erb
<%= warning_toggle_switch_tag('warning', '1', false, 'Warning Mode') %>
```

#### `danger_toggle_switch_tag(name, value, checked, label_text, **options)`
Creates a red danger toggle switch.

```erb
<%= danger_toggle_switch_tag('danger', '1', false, 'Dangerous Setting') %>
```

### Group Helpers

#### `toggle_switch_group(**options)`
Creates a group of toggle switches.

```erb
<!-- Vertical group (default) -->
<%= toggle_switch_group do %>
  <%= toggle_switch_tag('option1', '1', false, 'Option 1') %>
  <%= toggle_switch_tag('option2', '1', true, 'Option 2') %>
<% end %>

<!-- Horizontal group -->
<%= toggle_switch_group(direction: 'horizontal') do %>
  <%= toggle_switch_tag('option1', '1', false, 'Option 1') %>
  <%= toggle_switch_tag('option2', '1', true, 'Option 2') %>
<% end %>
```

## Options

### Common Options

- `description`: Additional description text below the label
- `size`: Size variant (`'sm'`, `'default'`, `'lg'`)
- `color`: Color variant (`'default'`, `'success'`, `'warning'`, `'danger'`)
- `wrapper_class`: Additional CSS classes for the wrapper
- `disabled`: Disable the toggle switch

### Example with Options

```erb
<%= toggle_switch_tag('advanced', '1', false, 'Advanced Settings', 
    description: 'Enable advanced configuration options',
    size: 'lg',
    color: 'warning',
    wrapper_class: 'custom-class') %>
```

## Styling

### CSS Classes

The toggle switches use these CSS classes:

- `.toggle-with-label`: Basic toggle with label
- `.toggle-with-description`: Toggle with label and description
- `.toggle-sm`: Small size variant
- `.toggle-lg`: Large size variant
- `.toggle-success`: Success color variant
- `.toggle-warning`: Warning color variant
- `.toggle-danger`: Danger color variant
- `.toggle-loading`: Loading state
- `.toggle-error`: Error state
- `.toggle-group`: Vertical group
- `.toggle-group-horizontal`: Horizontal group

### Custom Styling

You can add custom styles by targeting the CSS classes:

```css
/* Custom toggle switch styling */
.toggle-with-label {
  margin-bottom: 1rem;
}

.toggle-content label {
  font-weight: 600;
  color: #your-color;
}
```

## Examples

### Settings Page

```erb
<div class="settings-section">
  <h3>General Settings</h3>
  
  <%= toggle_switch_group do %>
    <%= toggle_switch_tag('settings[notifications]', '1', false, 'Email Notifications', 
        description: 'Receive email notifications for important updates') %>
    
    <%= toggle_switch_tag('settings[analytics]', '1', true, 'Analytics Tracking', 
        description: 'Allow analytics tracking to improve the service') %>
    
    <%= toggle_switch_tag('settings[maintenance]', '1', false, 'Maintenance Mode', 
        description: 'Put the site in maintenance mode') %>
  <% end %>
</div>
```

### Form Integration

```erb
<%= form_with model: @user, class: 'space-y-6' do |form| %>
  <div class="form-section">
    <h3>User Preferences</h3>
    
    <%= toggle_switch(form, :email_notifications, 'Email Notifications', 
        description: 'Receive notifications via email') %>
    
    <%= toggle_switch(form, :sms_notifications, 'SMS Notifications', 
        description: 'Receive notifications via SMS') %>
    
    <%= success_toggle_switch(form, :premium, 'Premium User', 
        description: 'Grant premium access to this user') %>
  </div>
<% end %>
```

### Different Sizes

```erb
<div class="size-examples">
  <%= small_toggle_switch_tag('compact', '1', false, 'Compact Setting') %>
  <%= toggle_switch_tag('normal', '1', true, 'Normal Setting') %>
  <%= large_toggle_switch_tag('large', '1', false, 'Large Setting') %>
</div>
```

### Color Variants

```erb
<div class="color-examples">
  <%= toggle_switch_tag('default', '1', true, 'Default Color') %>
  <%= success_toggle_switch_tag('success', '1', true, 'Success Color') %>
  <%= warning_toggle_switch_tag('warning', '1', true, 'Warning Color') %>
  <%= danger_toggle_switch_tag('danger', '1', true, 'Danger Color') %>
</div>
```

## Accessibility

### Keyboard Navigation

- **Tab**: Navigate to the toggle switch
- **Space**: Toggle the switch on/off
- **Enter**: Toggle the switch on/off

### Screen Reader Support

- Proper `label` elements with `for` attributes
- ARIA attributes for state communication
- Semantic HTML structure

### Focus Management

- Clear focus indicators
- Proper focus order
- Focus trap in modal contexts

## Browser Support

- **Modern Browsers**: Chrome, Firefox, Safari, Edge (latest versions)
- **Mobile Browsers**: iOS Safari, Chrome Mobile
- **Fallbacks**: Graceful degradation for older browsers

## Performance

- **CSS-Only Animations**: Hardware-accelerated transitions
- **Minimal JavaScript**: No JavaScript required for basic functionality
- **Optimized Rendering**: Efficient CSS selectors

## Migration from Checkboxes

Existing checkboxes are automatically styled. To improve the user experience:

1. **Wrap with labels**: Ensure proper label association
2. **Add descriptions**: Use the `description` option for context
3. **Group related toggles**: Use `toggle_switch_group` for organization
4. **Choose appropriate colors**: Use color variants for semantic meaning

### Before (Basic Checkbox)

```erb
<div class="flex items-center">
  <input type="checkbox" name="setting" value="1" class="mr-2">
  <label>Enable Feature</label>
</div>
```

### After (Toggle Switch)

```erb
<%= toggle_switch_tag('setting', '1', false, 'Enable Feature', 
    description: 'Turn this feature on or off') %>
```

## Demo

Visit `/admin/ai_demo` to see the toggle switches in action with various examples and integration patterns.

## Troubleshooting

### Common Issues

1. **Toggle not appearing**: Ensure the CSS file is included
2. **Styling conflicts**: Check for conflicting CSS rules
3. **Accessibility issues**: Verify proper label associations

### Debug Mode

Enable debug mode by adding this to your CSS:

```css
/* Debug toggle switches */
input[type="checkbox"] {
  border: 2px solid red !important;
}
```

## Future Enhancements

- **Animation Customization**: More animation options
- **Custom Themes**: Theme system for different color schemes
- **Advanced States**: More sophisticated state management
- **Integration**: Better integration with form libraries


