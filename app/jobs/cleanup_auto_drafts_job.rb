class CleanupAutoDraftsJob < ApplicationJob
  queue_as :default

  def perform
    # Delete auto_drafts older than 24 hours
    deleted_count = Post.stale_auto_drafts.destroy_all.count
    Rails.logger.info "Cleaned up #{deleted_count} stale auto_drafts"
  end
end

