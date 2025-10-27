class StockPhotoBookmark < ApplicationRecord
  acts_as_tenant(:tenant)
  belongs_to :user
  
  validates :provider, presence: true, inclusion: { in: %w[unsplash pexels pixabay] }
  validates :provider_photo_id, presence: true, uniqueness: { scope: :user_id }
  serialize :photo_data, coder: JSON
  
  scope :recent, -> { order(created_at: :desc) }
end
