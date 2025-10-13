class Admin::AccessLevelsController < Admin::BaseController
  before_action :ensure_admin

  # GET /admin/access_levels
  def index
    @roles = load_roles_with_permissions
  end

  # PATCH /admin/access_levels/update_permissions
  def update_permissions
    # This would update role permissions if using a more complex permission system
    # For now, we'll just show what permissions each role has
    
    redirect_to admin_access_levels_path, notice: 'Role permissions are defined in the User model.'
  end

  private

  def ensure_admin
    unless current_user&.administrator?
      redirect_to admin_root_path, alert: 'Access denied. Administrator privileges required.'
    end
  end

  def load_roles_with_permissions
    [
      {
        name: 'Administrator',
        key: 'administrator',
        description: 'Full access to all features and settings',
        color: 'red',
        user_count: User.administrator.count,
        permissions: [
          { name: 'Full Admin Access', granted: true, description: 'Complete control over the site' },
          { name: 'Manage Users', granted: true, description: 'Create, edit, and delete users' },
          { name: 'Manage Plugins', granted: true, description: 'Activate and configure plugins' },
          { name: 'Manage Themes', granted: true, description: 'Change and customize themes' },
          { name: 'Manage Settings', granted: true, description: 'Configure all site settings' },
          { name: 'Publish Posts', granted: true, description: 'Publish any post or page' },
          { name: 'Edit Others Posts', granted: true, description: 'Edit content from other users' },
          { name: 'Delete Posts', granted: true, description: 'Delete any post or page' },
          { name: 'Moderate Comments', granted: true, description: 'Approve, edit, delete comments' },
          { name: 'Upload Files', granted: true, description: 'Upload to media library' },
          { name: 'API Access', granted: true, description: 'Access REST and GraphQL APIs' }
        ]
      },
      {
        name: 'Editor',
        key: 'editor',
        description: 'Can publish and manage posts including those of other users',
        color: 'blue',
        user_count: User.editor.count,
        permissions: [
          { name: 'Full Admin Access', granted: false, description: 'Complete control over the site' },
          { name: 'Manage Users', granted: false, description: 'Create, edit, and delete users' },
          { name: 'Manage Plugins', granted: false, description: 'Activate and configure plugins' },
          { name: 'Manage Themes', granted: false, description: 'Change and customize themes' },
          { name: 'Manage Settings', granted: false, description: 'Configure all site settings' },
          { name: 'Publish Posts', granted: true, description: 'Publish any post or page' },
          { name: 'Edit Others Posts', granted: true, description: 'Edit content from other users' },
          { name: 'Delete Posts', granted: true, description: 'Delete any post or page' },
          { name: 'Moderate Comments', granted: true, description: 'Approve, edit, delete comments' },
          { name: 'Upload Files', granted: true, description: 'Upload to media library' },
          { name: 'API Access', granted: true, description: 'Access REST and GraphQL APIs' }
        ]
      },
      {
        name: 'Author',
        key: 'author',
        description: 'Can publish and manage their own posts',
        color: 'green',
        user_count: User.author.count,
        permissions: [
          { name: 'Full Admin Access', granted: false, description: 'Complete control over the site' },
          { name: 'Manage Users', granted: false, description: 'Create, edit, and delete users' },
          { name: 'Manage Plugins', granted: false, description: 'Activate and configure plugins' },
          { name: 'Manage Themes', granted: false, description: 'Change and customize themes' },
          { name: 'Manage Settings', granted: false, description: 'Configure all site settings' },
          { name: 'Publish Posts', granted: true, description: 'Publish their own posts and pages' },
          { name: 'Edit Others Posts', granted: false, description: 'Edit content from other users' },
          { name: 'Delete Posts', granted: false, description: 'Delete only their own content' },
          { name: 'Moderate Comments', granted: false, description: 'Limited comment moderation' },
          { name: 'Upload Files', granted: true, description: 'Upload to media library' },
          { name: 'API Access', granted: true, description: 'Access REST and GraphQL APIs' }
        ]
      },
      {
        name: 'Contributor',
        key: 'contributor',
        description: 'Can write and manage their own posts but cannot publish',
        color: 'yellow',
        user_count: User.contributor.count,
        permissions: [
          { name: 'Full Admin Access', granted: false, description: 'Complete control over the site' },
          { name: 'Manage Users', granted: false, description: 'Create, edit, and delete users' },
          { name: 'Manage Plugins', granted: false, description: 'Activate and configure plugins' },
          { name: 'Manage Themes', granted: false, description: 'Change and customize themes' },
          { name: 'Manage Settings', granted: false, description: 'Configure all site settings' },
          { name: 'Publish Posts', granted: false, description: 'Can only submit for review' },
          { name: 'Edit Others Posts', granted: false, description: 'Edit content from other users' },
          { name: 'Delete Posts', granted: false, description: 'Cannot delete posts' },
          { name: 'Moderate Comments', granted: false, description: 'Cannot moderate comments' },
          { name: 'Upload Files', granted: false, description: 'Cannot upload files' },
          { name: 'API Access', granted: true, description: 'Limited API access' }
        ]
      },
      {
        name: 'Subscriber',
        key: 'subscriber',
        description: 'Can only manage their profile',
        color: 'gray',
        user_count: User.subscriber.count,
        permissions: [
          { name: 'Full Admin Access', granted: false, description: 'Complete control over the site' },
          { name: 'Manage Users', granted: false, description: 'Create, edit, and delete users' },
          { name: 'Manage Plugins', granted: false, description: 'Activate and configure plugins' },
          { name: 'Manage Themes', granted: false, description: 'Change and customize themes' },
          { name: 'Manage Settings', granted: false, description: 'Configure all site settings' },
          { name: 'Publish Posts', granted: false, description: 'Cannot create or publish posts' },
          { name: 'Edit Others Posts', granted: false, description: 'Cannot edit any posts' },
          { name: 'Delete Posts', granted: false, description: 'Cannot delete posts' },
          { name: 'Moderate Comments', granted: false, description: 'Cannot moderate comments' },
          { name: 'Upload Files', granted: false, description: 'Cannot upload files' },
          { name: 'API Access', granted: false, description: 'No API access' }
        ]
      }
    ]
  end
end






