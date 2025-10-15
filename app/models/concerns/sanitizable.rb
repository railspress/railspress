module Sanitizable
  extend ActiveSupport::Concern

  included do
    # Define which attributes should be sanitized
    class_attribute :sanitizable_attributes
    self.sanitizable_attributes = []

    before_validation :sanitize_content_attributes
  end

  class_methods do
    # Define attributes that should be sanitized
    # Example: sanitize_content :body, :excerpt
    def sanitize_content(*attributes)
      self.sanitizable_attributes += attributes.map(&:to_s)
    end
  end

  private

  def sanitize_content_attributes
    self.class.sanitizable_attributes.each do |attribute|
      next unless respond_to?(attribute)
      next if send(attribute).blank?

      # Get the current value
      value = send(attribute)

      # Skip if it's ActionText (already handled)
      next if value.is_a?(ActionText::RichText)

      # Sanitize the content
      sanitized = Railspress::HtmlSanitizer.sanitize_content(value.to_s)
      
      # Set the sanitized value
      send("#{attribute}=", sanitized)
    end
  end
end








