class HelloTupac < Railspress::PluginBase
  plugin_name 'Hello Tupac!'
  plugin_version '1.0.0'
  plugin_description 'This is not just a plugin, it symbolizes the hope and enthusiasm of an entire generation summed up in two words sung most famously by Tupac Shakur: Keep ya head up.'
  plugin_author 'RailsPress Team'
  
  # Tupac Shakur quotes
  TUPAC_QUOTES = [
    "Reality is wrong. Dreams are for real.",
    "Keep ya head up.",
    "Only God can judge me.",
    "I'm not perfect, but I'll always be real.",
    "For every dark night, there's a brighter day.",
    "They got money for war but can't feed the poor.",
    "The only thing that comes to a sleeping man is dreams.",
    "You gotta make a change.",
    "Behind every sweet smile is a bitter sadness.",
    "I'd rather die like a man than live like a coward.",
    "I'm a reflection of the community.",
    "I ain't mad at cha.",
    "Ain't nothin' like the old school.",
    "Even though you're fed up, keep your head up.",
    "I'm gonna spark the brain that changes the world.",
    "My only fear of death is coming back reincarnated.",
    "Trust nobody.",
    "It's just me against the world.",
    "Out on bail, fresh out of jail, California dreamin'.",
    "All eyez on me.",
    "Alcohol and booty calls.",
    "Cause life goes on.",
    "With G's in my pocket.",
    "Have a party at my funeral.",
    "Until I get free.",
    "I live my life in tha fast lane.",
    "Life goes on homie.",
    "Get money.",
    "Evade b*ches.",
    "Evade tricks."
  ].freeze unless defined?(TUPAC_QUOTES)
  
  def activate
    super
    Rails.logger.info "Hello Tupac! plugin activated - Keep ya head up!"
    
    # Register the admin sidebar hook
    register_admin_sidebar_hook
  end
  
  def deactivate
    super
    Rails.logger.info "Hello Tupac! plugin deactivated"
  end
  
  private
  
  def register_admin_sidebar_hook
    # Add content to the admin right topbar (next to Go to Site button)
    add_action('admin_right_topbar_content') do
      render_topbar_quote
    end
  end
  
  def render_topbar_quote
    quote = TUPAC_QUOTES.sample
    # Escape the quote for HTML attributes to prevent issues with quotes
    escaped_quote = quote.gsub('"', '&quot;').gsub("'", '&#39;')
    
    # Return HTML that will be rendered in the topbar
    "<div class='hello-tupac-quote inline-flex items-center gap-2 px-3 py-1 bg-gradient-to-r from-purple-500/10 to-pink-500/10 border border-purple-500/20 rounded-lg text-xs text-purple-200 max-w-xs truncate cursor-help' title='#{escaped_quote} — Tupac Shakur' data-tooltip='#{escaped_quote} — Tupac Shakur'>
      <svg class='w-3 h-3 text-purple-400 flex-shrink-0' fill='currentColor' viewBox='0 0 20 20'>
        <path fill-rule='evenodd' d='M3.172 5.172a4 4 0 015.656 0L10 6.343l1.172-1.171a4 4 0 115.656 5.656L10 17.657l-6.828-6.829a4 4 0 010-5.656z' clip-rule='evenodd'/>
      </svg>
      <span class='truncate'>#{quote}</span>
    </div>".html_safe
  end
  
  # Helper method to get a random quote
  def self.get_quote
    TUPAC_QUOTES.sample
  end
end

# Auto-initialize if active
if Plugin.exists?(name: 'Hello Tupac!', active: true)
  HelloTupac.new
end
