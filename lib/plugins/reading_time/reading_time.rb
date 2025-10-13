# Reading Time Plugin
# Calculates estimated reading time for posts

class ReadingTime < Railspress::PluginBase
  plugin_name 'Reading Time'
  plugin_version '1.0.0'
  plugin_description 'Displays estimated reading time for posts and pages'
  plugin_author 'RailsPress'

  WORDS_PER_MINUTE = 200

  def activate
    super
    inject_helper_methods
  end

  private

  def inject_helper_methods
    ApplicationController.helper_method :reading_time if defined?(ApplicationController)
  end

  # Calculate reading time for content
  def self.calculate(content)
    return 0 if content.blank?
    
    # Strip HTML tags and count words
    text = ActionView::Base.full_sanitizer.sanitize(content.to_s)
    word_count = text.split.size
    
    minutes = (word_count.to_f / WORDS_PER_MINUTE).ceil
    minutes < 1 ? 1 : minutes
  end

  # Format reading time
  def self.format(minutes)
    if minutes == 1
      "1 min read"
    else
      "#{minutes} min read"
    end
  end
end

# Helper module
module ReadingTimeHelper
  def reading_time(content)
    minutes = ReadingTime.calculate(content)
    ReadingTime.format(minutes)
  end

  def reading_time_minutes(content)
    ReadingTime.calculate(content)
  end
end

# Include helper
if defined?(ApplicationController)
  ApplicationController.helper(ReadingTimeHelper)
end

ReadingTime.new





