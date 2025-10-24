module Admin::TableHelper
  def format_table_actions(resource, actions = [:view, :edit, :delete])
    resource_name = resource.class.name.downcase
    html = '<div class="table-actions">'
    
    if actions.include?(:view)
      # Show frontend view in same tab (only if resource has a slug)
      if resource.respond_to?(:slug) && resource.slug.present?
        html += link_to('', blog_post_path(resource.slug), 
                        class: 'btn-view', title: 'View', target: '_self')
      end
    end
    
    if actions.include?(:edit)
      # Go to write page
      if resource_name == 'post'
        html += link_to('', write_admin_post_path(resource), 
                        class: 'btn-edit', title: 'Edit')
      else
        html += link_to('', send("edit_admin_#{resource_name}_path", resource), 
                        class: 'btn-edit', title: 'Edit')
      end
    end
    
    if actions.include?(:delete)
      # Trash without confirm - flash notice at top
      html += link_to('', send("admin_#{resource_name}_path", resource), 
                      class: 'btn-delete', title: 'Delete',
                      method: :delete,
                      data: { turbo_method: :delete })
    end
    
    html += '</div>'
    html.html_safe
  end
end

