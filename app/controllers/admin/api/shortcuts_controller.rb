class Admin::Api::ShortcutsController < Admin::BaseController
  # GET /admin/api/shortcuts?set=write
  def index
    set = params[:set] || 'admin'
    @shortcuts = Shortcut.active.for_set(set).ordered
    
    render json: { 
      shortcuts: @shortcuts.map { |s| shortcut_json(s) }
    }
  end
  
  private
  
  def shortcut_json(shortcut)
    {
      id: shortcut.id,
      name: shortcut.name,
      description: shortcut.description,
      action_type: shortcut.action_type,
      action_value: shortcut.action_value,
      icon: shortcut.icon,
      category: shortcut.category,
      keybinding: shortcut.keybinding,
      shortcut_set: shortcut.shortcut_set
    }
  end
end
