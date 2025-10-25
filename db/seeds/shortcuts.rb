puts "Creating shortcuts..."

tenant = Tenant.first

# Global shortcuts (show everywhere)
[
  {
    name: 'Open Command Palette',
    description: 'Open command palette',
    action_type: 'execute',
    action_value: 'openPalette',
    icon: '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 9l4-4 4 4m0 6l-4 4-4-4"/></svg>',
    category: 'system',
    shortcut_set: 'global',
    keybinding: 'cmd+k'
  },
  {
    name: 'Go to Dashboard',
    description: 'Navigate to admin dashboard',
    action_type: 'navigate',
    action_value: '/admin',
    icon: '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/></svg>',
    category: 'navigation',
    shortcut_set: 'global',
    keybinding: 'cmd+shift+d'
  },
  {
    name: 'Go to Posts',
    description: 'Navigate to posts list',
    action_type: 'navigate',
    action_value: '/admin/posts',
    icon: '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>',
    category: 'navigation',
    shortcut_set: 'global',
    keybinding: 'cmd+shift+p'
  },
  {
    name: 'Go to Pages',
    description: 'Navigate to pages list',
    action_type: 'navigate',
    action_value: '/admin/pages',
    icon: '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>',
    category: 'navigation',
    shortcut_set: 'global',
    keybinding: 'cmd+shift+g'
  },
  {
    name: 'Go to Users',
    description: 'Navigate to users list',
    action_type: 'navigate',
    action_value: '/admin/users',
    icon: '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z"/></svg>',
    category: 'navigation',
    shortcut_set: 'global',
    keybinding: 'cmd+shift+u'
  }
].each do |data|
  Shortcut.find_or_create_by!(
    name: data[:name],
    shortcut_set: data[:shortcut_set],
    tenant: tenant
  ) do |s|
    s.assign_attributes(data)
    s.active = true
    s.position = 0
  end
end

# Write-specific shortcuts
[
  {
    name: 'Save Post',
    description: 'Save current post',
    action_type: 'execute',
    action_value: 'savePost',
    icon: '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-3m-1 4l-3-3m0 0l-3 3m3-3v12"/></svg>',
    category: 'content',
    shortcut_set: 'write',
    keybinding: 'cmd+s'
  },
  {
    name: 'Toggle AI Assistant',
    description: 'Show/hide AI sidebar',
    action_type: 'execute',
    action_value: 'toggleAISidebar',
    icon: '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"/></svg>',
    category: 'tools',
    shortcut_set: 'write',
    keybinding: 'cmd+i'
  },
  {
    name: 'Toggle Right Sidebar',
    description: 'Show/hide right sidebar',
    action_type: 'execute',
    action_value: 'toggleRightSidebar',
    icon: '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"/></svg>',
    category: 'tools',
    shortcut_set: 'write',
    keybinding: 'cmd+b'
  },
  {
    name: 'New Post',
    description: 'Create a new post',
    action_type: 'navigate',
    action_value: '/admin/posts/new',
    icon: '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"/></svg>',
    category: 'content',
    shortcut_set: 'write',
    keybinding: 'cmd+n'
  },
  {
    name: 'Preview Post',
    description: 'Preview current post',
    action_type: 'execute',
    action_value: 'previewPost',
    icon: '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>',
    category: 'content',
    shortcut_set: 'write',
    keybinding: 'cmd+p'
  },
  {
    name: 'Publish Post',
    description: 'Publish current post',
    action_type: 'execute',
    action_value: 'publishPost',
    icon: '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"/></svg>',
    category: 'content',
    shortcut_set: 'write',
    keybinding: 'cmd+shift+enter'
  }
].each do |data|
  Shortcut.find_or_create_by!(
    name: data[:name],
    shortcut_set: data[:shortcut_set],
    tenant: tenant
  ) do |s|
    s.assign_attributes(data)
    s.active = true
    s.position = 0
  end
end

puts "✓ Shortcuts created"
