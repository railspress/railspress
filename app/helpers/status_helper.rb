# frozen_string_literal: true

module StatusHelper
  # Get status badge CSS classes
  def status_badge_class(status)
    badge_classes = {
      'draft' => 'bg-gray-100 text-gray-800',
      'published' => 'bg-green-100 text-green-800',
      'scheduled' => 'bg-blue-100 text-blue-800',
      'pending_review' => 'bg-yellow-100 text-yellow-800',
      'private_post' => 'bg-purple-100 text-purple-800',
      'private_page' => 'bg-purple-100 text-purple-800',
      'trash' => 'bg-red-100 text-red-800'
    }
    
    badge_classes[status.to_s] || 'bg-gray-100 text-gray-800'
  end

  # Get status badge HTML for posts/pages
  def status_badge(record)
    status = record.status
    
    badge_classes = {
      'draft' => 'bg-gray-500/10 text-gray-400 border-gray-500/20',
      'published' => 'bg-green-500/10 text-green-400 border-green-500/20',
      'scheduled' => 'bg-blue-500/10 text-blue-400 border-blue-500/20',
      'pending_review' => 'bg-yellow-500/10 text-yellow-400 border-yellow-500/20',
      'private_post' => 'bg-purple-500/10 text-purple-400 border-purple-500/20',
      'private_page' => 'bg-purple-500/10 text-purple-400 border-purple-500/20',
      'trash' => 'bg-red-500/10 text-red-400 border-red-500/20'
    }
    
    status_labels = {
      'draft' => 'Draft',
      'published' => 'Published',
      'scheduled' => 'Scheduled',
      'pending_review' => 'Pending Review',
      'private_post' => 'Private',
      'private_page' => 'Private',
      'trash' => 'Trashed'
    }
    
    classes = badge_classes[status] || 'bg-gray-500/10 text-gray-400'
    label = status_labels[status] || status.titleize
    
    content_tag(:span, label, class: "px-2 py-1 text-xs font-medium rounded border #{classes}")
  end
  
  # Get status icon
  def status_icon(status)
    icons = {
      'draft' => '📝',
      'published' => '✅',
      'scheduled' => '⏰',
      'pending_review' => '👀',
      'private_post' => '🔒',
      'private_page' => '🔒',
      'trash' => '🗑️'
    }
    
    icons[status.to_s] || '📄'
  end
  
  # Get all statuses for filter dropdown
  def post_statuses_for_select
    [
      ['All Statuses', ''],
      ['Draft', 'draft'],
      ['Published', 'published'],
      ['Scheduled', 'scheduled'],
      ['Pending Review', 'pending_review'],
      ['Private', 'private_post']
    ]
  end
  
  def page_statuses_for_select
    [
      ['All Statuses', ''],
      ['Draft', 'draft'],
      ['Published', 'published'],
      ['Scheduled', 'scheduled'],
      ['Pending Review', 'pending_review'],
      ['Private', 'private_page']
    ]
  end
  
  # Get status counts for dashboard
  def post_status_counts
    {
      total: Post.not_trashed.count,
      draft: Post.draft_status.count,
      published: Post.published_status.count,
      scheduled: Post.scheduled_status.count,
      pending: Post.pending_review_status.count,
      private: Post.private_post_status.count,
      trash: Post.trash_status.count
    }
  end
  
  def page_status_counts
    {
      total: Page.not_trashed.count,
      draft: Page.draft_status.count,
      published: Page.published_status.count,
      scheduled: Page.scheduled_status.count,
      pending: Page.pending_review_status.count,
      private: Page.private_page_status.count,
      trash: Page.trash_status.count
    }
  end
end

