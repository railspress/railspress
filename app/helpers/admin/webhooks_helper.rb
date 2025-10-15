module Admin::WebhooksHelper
  def event_description(event)
    descriptions = {
      'post.created' => 'Triggered when a new post is created',
      'post.updated' => 'Triggered when a post is updated',
      'post.published' => 'Triggered when a post is published',
      'post.deleted' => 'Triggered when a post is deleted',
      'page.created' => 'Triggered when a new page is created',
      'page.updated' => 'Triggered when a page is updated',
      'page.published' => 'Triggered when a page is published',
      'page.deleted' => 'Triggered when a page is deleted',
      'comment.created' => 'Triggered when a new comment is created',
      'comment.approved' => 'Triggered when a comment is approved',
      'comment.spam' => 'Triggered when a comment is marked as spam',
      'user.created' => 'Triggered when a new user is created',
      'user.updated' => 'Triggered when a user is updated',
      'media.uploaded' => 'Triggered when media is uploaded'
    }
    
    descriptions[event] || 'Webhook event description not available'
  end
end
