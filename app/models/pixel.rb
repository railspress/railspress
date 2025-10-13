class Pixel < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant(:tenant, optional: true)
  
  # Versioning
  has_paper_trail
  
  # Enums
  enum pixel_type: {
    google_analytics: 0,
    google_tag_manager: 1,
    facebook_pixel: 2,
    tiktok_pixel: 3,
    linkedin_insight: 4,
    twitter_pixel: 5,
    pinterest_tag: 6,
    snapchat_pixel: 7,
    reddit_pixel: 8,
    hotjar: 9,
    clarity: 10,
    mixpanel: 11,
    segment: 12,
    heap: 13,
    custom: 99
  }
  
  enum position: {
    head: 0,        # <head> section
    body_start: 1,  # After <body>
    body_end: 2     # Before </body>
  }
  
  # Validations
  validates :name, presence: true
  validates :pixel_type, presence: true
  validates :position, presence: true
  validate :requires_pixel_id_or_custom_code
  validate :custom_code_is_safe
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_position, ->(pos) { where(position: pos) }
  scope :by_provider, ->(provider) { where(provider: provider) }
  scope :ordered, -> { order(position: :asc, created_at: :asc) }
  
  # Instance methods
  
  # Render the pixel code
  def render_code
    return '' unless active?
    
    if custom?
      sanitize_custom_code(custom_code || '')
    else
      generate_provider_code
    end
  end
  
  # Check if pixel is properly configured
  def configured?
    if custom?
      custom_code.present?
    else
      pixel_id.present?
    end
  end
  
  private
  
  def requires_pixel_id_or_custom_code
    if custom? && custom_code.blank?
      errors.add(:custom_code, "can't be blank for custom pixels")
    elsif !custom? && pixel_id.blank?
      errors.add(:pixel_id, "can't be blank for #{pixel_type} pixels")
    end
  end
  
  def custom_code_is_safe
    return unless custom_code.present?
    
    # Basic security checks
    dangerous_patterns = [
      /<script[^>]*src=/i,  # External scripts
      /eval\(/i,            # eval() calls
      /document\.write/i,   # document.write
      /on\w+=/i            # Inline event handlers
    ]
    
    dangerous_patterns.each do |pattern|
      if custom_code.match?(pattern)
        errors.add(:custom_code, "contains potentially dangerous code pattern")
        break
      end
    end
  end
  
  def sanitize_custom_code(code)
    # Return code as-is but wrapped in comment for admin reference
    # In production, you might want more strict sanitization
    code
  end
  
  def generate_provider_code
    case pixel_type.to_sym
    when :google_analytics
      google_analytics_code
    when :google_tag_manager
      google_tag_manager_code
    when :facebook_pixel
      facebook_pixel_code
    when :tiktok_pixel
      tiktok_pixel_code
    when :linkedin_insight
      linkedin_insight_code
    when :twitter_pixel
      twitter_pixel_code
    when :pinterest_tag
      pinterest_tag_code
    when :snapchat_pixel
      snapchat_pixel_code
    when :reddit_pixel
      reddit_pixel_code
    when :hotjar
      hotjar_code
    when :clarity
      clarity_code
    when :mixpanel
      mixpanel_code
    when :segment
      segment_code
    when :heap
      heap_code
    else
      ''
    end
  end
  
  # Provider-specific code generators
  
  def google_analytics_code
    <<~HTML
      <!-- Google Analytics -->
      <script async src="https://www.googletagmanager.com/gtag/js?id=#{pixel_id}"></script>
      <script>
        window.dataLayer = window.dataLayer || [];
        function gtag(){dataLayer.push(arguments);}
        gtag('js', new Date());
        gtag('config', '#{pixel_id}');
      </script>
    HTML
  end
  
  def google_tag_manager_code
    if position.to_sym == :head || position.to_sym == :body_start
      <<~HTML
        <!-- Google Tag Manager -->
        <script>(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
        new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
        j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
        'https://www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
        })(window,document,'script','dataLayer','#{pixel_id}');</script>
        <!-- End Google Tag Manager -->
      HTML
    else
      <<~HTML
        <!-- Google Tag Manager (noscript) -->
        <noscript><iframe src="https://www.googletagmanager.com/ns.html?id=#{pixel_id}"
        height="0" width="0" style="display:none;visibility:hidden"></iframe></noscript>
        <!-- End Google Tag Manager (noscript) -->
      HTML
    end
  end
  
  def facebook_pixel_code
    <<~HTML
      <!-- Meta Pixel Code -->
      <script>
      !function(f,b,e,v,n,t,s)
      {if(f.fbq)return;n=f.fbq=function(){n.callMethod?
      n.callMethod.apply(n,arguments):n.queue.push(arguments)};
      if(!f._fbq)f._fbq=n;n.push=n;n.loaded=!0;n.version='2.0';
      n.queue=[];t=b.createElement(e);t.async=!0;
      t.src=v;s=b.getElementsByTagName(e)[0];
      s.parentNode.insertBefore(t,s)}(window, document,'script',
      'https://connect.facebook.net/en_US/fbevents.js');
      fbq('init', '#{pixel_id}');
      fbq('track', 'PageView');
      </script>
      <noscript><img height="1" width="1" style="display:none"
      src="https://www.facebook.com/tr?id=#{pixel_id}&ev=PageView&noscript=1"
      /></noscript>
      <!-- End Meta Pixel Code -->
    HTML
  end
  
  def tiktok_pixel_code
    <<~HTML
      <!-- TikTok Pixel Code -->
      <script>
      !function (w, d, t) {
        w.TiktokAnalyticsObject=t;var ttq=w[t]=w[t]||[];ttq.methods=["page","track","identify","instances","debug","on","off","once","ready","alias","group","enableCookie","disableCookie"],ttq.setAndDefer=function(t,e){t[e]=function(){t.push([e].concat(Array.prototype.slice.call(arguments,0)))}};for(var i=0;i<ttq.methods.length;i++)ttq.setAndDefer(ttq,ttq.methods[i]);ttq.instance=function(t){for(var e=ttq._i[t]||[],n=0;n<ttq.methods.length;n++)ttq.setAndDefer(e,ttq.methods[n]);return e},ttq.load=function(e,n){var i="https://analytics.tiktok.com/i18n/pixel/events.js";ttq._i=ttq._i||{},ttq._i[e]=[],ttq._i[e]._u=i,ttq._t=ttq._t||{},ttq._t[e]=+new Date,ttq._o=ttq._o||{},ttq._o[e]=n||{};var o=document.createElement("script");o.type="text/javascript",o.async=!0,o.src=i+"?sdkid="+e+"&lib="+t;var a=document.getElementsByTagName("script")[0];a.parentNode.insertBefore(o,a)};
        ttq.load('#{pixel_id}');
        ttq.page();
      }(window, document, 'ttq');
      </script>
      <!-- End TikTok Pixel Code -->
    HTML
  end
  
  def linkedin_insight_code
    <<~HTML
      <!-- LinkedIn Insight Tag -->
      <script type="text/javascript">
      _linkedin_partner_id = "#{pixel_id}";
      window._linkedin_data_partner_ids = window._linkedin_data_partner_ids || [];
      window._linkedin_data_partner_ids.push(_linkedin_partner_id);
      </script><script type="text/javascript">
      (function(l) {
      if (!l){window.lintrk = function(a,b){window.lintrk.q.push([a,b])};
      window.lintrk.q=[]}
      var s = document.getElementsByTagName("script")[0];
      var b = document.createElement("script");
      b.type = "text/javascript";b.async = true;
      b.src = "https://snap.licdn.com/li.lms-analytics/insight.min.js";
      s.parentNode.insertBefore(b, s);})(window.lintrk);
      </script>
      <noscript>
      <img height="1" width="1" style="display:none;" alt="" src="https://px.ads.linkedin.com/collect/?pid=#{pixel_id}&fmt=gif" />
      </noscript>
      <!-- End LinkedIn Insight Tag -->
    HTML
  end
  
  def twitter_pixel_code
    <<~HTML
      <!-- Twitter Pixel Code -->
      <script>
      !function(e,t,n,s,u,a){e.twq||(s=e.twq=function(){s.exe?s.exe.apply(s,arguments):s.queue.push(arguments);
      },s.version='1.1',s.queue=[],u=t.createElement(n),u.async=!0,u.src='https://static.ads-twitter.com/uwt.js',
      a=t.getElementsByTagName(n)[0],a.parentNode.insertBefore(u,a))}(window,document,'script');
      twq('config','#{pixel_id}');
      </script>
      <!-- End Twitter Pixel Code -->
    HTML
  end
  
  def pinterest_tag_code
    <<~HTML
      <!-- Pinterest Tag -->
      <script>
      !function(e){if(!window.pintrk){window.pintrk = function () {
      window.pintrk.queue.push(Array.prototype.slice.call(arguments))};var
        n=window.pintrk;n.queue=[],n.version="3.0";var
        t=document.createElement("script");t.async=!0,t.src=e;var
        r=document.getElementsByTagName("script")[0];
        r.parentNode.insertBefore(t,r)}}("https://s.pinimg.com/ct/core.js");
      pintrk('load', '#{pixel_id}', {em: '<user_email_address>'});
      pintrk('page');
      </script>
      <noscript>
        <img height="1" width="1" style="display:none;" alt=""
          src="https://ct.pinterest.com/v3/?event=init&tid=#{pixel_id}&noscript=1" />
      </noscript>
      <!-- End Pinterest Tag -->
    HTML
  end
  
  def snapchat_pixel_code
    <<~HTML
      <!-- Snapchat Pixel Code -->
      <script type='text/javascript'>
      (function(e,t,n){if(e.snaptr)return;var a=e.snaptr=function()
      {a.handleRequest?a.handleRequest.apply(a,arguments):a.queue.push(arguments)};
      a.queue=[];var s='script';r=t.createElement(s);r.async=!0;
      r.src=n;var u=t.getElementsByTagName(s)[0];
      u.parentNode.insertBefore(r,u);})(window,document,
      'https://sc-static.net/scevent.min.js');
      snaptr('init', '#{pixel_id}', {
      'user_email': '__INSERT_USER_EMAIL__'
      });
      snaptr('track', 'PAGE_VIEW');
      </script>
      <!-- End Snapchat Pixel Code -->
    HTML
  end
  
  def reddit_pixel_code
    <<~HTML
      <!-- Reddit Pixel -->
      <script>
      !function(w,d){if(!w.rdt){var p=w.rdt=function(){p.sendEvent?p.sendEvent.apply(p,arguments):p.callQueue.push(arguments)};p.callQueue=[];var t=d.createElement("script");t.src="https://www.redditstatic.com/ads/pixel.js",t.async=!0;var s=d.getElementsByTagName("script")[0];s.parentNode.insertBefore(t,s)}}(window,document);
      rdt('init','#{pixel_id}');
      rdt('track', 'PageVisit');
      </script>
      <!-- End Reddit Pixel -->
    HTML
  end
  
  def hotjar_code
    <<~HTML
      <!-- Hotjar Tracking Code -->
      <script>
          (function(h,o,t,j,a,r){
              h.hj=h.hj||function(){(h.hj.q=h.hj.q||[]).push(arguments)};
              h._hjSettings={hjid:#{pixel_id},hjsv:6};
              a=o.getElementsByTagName('head')[0];
              r=o.createElement('script');r.async=1;
              r.src=t+h._hjSettings.hjid+j+h._hjSettings.hjsv;
              a.appendChild(r);
          })(window,document,'https://static.hotjar.com/c/hotjar-','.js?sv=');
      </script>
      <!-- End Hotjar Tracking Code -->
    HTML
  end
  
  def clarity_code
    <<~HTML
      <!-- Microsoft Clarity -->
      <script type="text/javascript">
      (function(c,l,a,r,i,t,y){
          c[a]=c[a]||function(){(c[a].q=c[a].q||[]).push(arguments)};
          t=l.createElement(r);t.async=1;t.src="https://www.clarity.ms/tag/"+i;
          y=l.getElementsByTagName(r)[0];y.parentNode.insertBefore(t,y);
      })(window, document, "clarity", "script", "#{pixel_id}");
      </script>
      <!-- End Microsoft Clarity -->
    HTML
  end
  
  def mixpanel_code
    <<~HTML
      <!-- Mixpanel -->
      <script type="text/javascript">
      (function(f,b){if(!b.__SV){var e,g,i,h;window.mixpanel=b;b._i=[];b.init=function(e,f,c){function g(a,d){var b=d.split(".");2==b.length&&(a=a[b[0]],d=b[1]);a[d]=function(){a.push([d].concat(Array.prototype.slice.call(arguments,0)))}}var a=b;"undefined"!==typeof c?a=b[c]=[]:c="mixpanel";a.people=a.people||[];a.toString=function(a){var d="mixpanel";"mixpanel"!==c&&(d+="."+c);a||(d+=" (stub)");return d};a.people.toString=function(){return a.toString(1)+".people (stub)"};i="disable time_event track track_pageview track_links track_forms track_with_groups add_group set_group remove_group register register_once alias unregister identify name_tag set_config reset opt_in_tracking opt_out_tracking has_opted_in_tracking has_opted_out_tracking clear_opt_in_out_tracking start_batch_senders people.set people.set_once people.unset people.increment people.append people.union people.track_charge people.clear_charges people.delete_user people.remove".split(" ");
      for(h=0;h<i.length;h++)g(a,i[h]);var j="set set_once union unset remove delete".split(" ");a.get_group=function(){function b(c){d[c]=function(){call2_args=arguments;call2=[c].concat(Array.prototype.slice.call(call2_args,0));a.push([e,call2])}}for(var d={},e=["get_group"].concat(Array.prototype.slice.call(arguments,0)),c=0;c<j.length;c++)b(j[c]);return d};b._i.push([e,f,c])};b.__SV=1.2;e=f.createElement("script");e.type="text/javascript";e.async=!0;e.src="undefined"!==typeof MIXPANEL_CUSTOM_LIB_URL?
      MIXPANEL_CUSTOM_LIB_URL:"file:"===f.location.protocol&&"//cdn.mxpnl.com/libs/mixpanel-2-latest.min.js".match(/^\\/\\//)?"https://cdn.mxpnl.com/libs/mixpanel-2-latest.min.js":"//cdn.mxpnl.com/libs/mixpanel-2-latest.min.js";g=f.getElementsByTagName("script")[0];g.parentNode.insertBefore(e,g)}})(document,window.mixpanel||[]);
      mixpanel.init("#{pixel_id}");
      </script>
      <!-- End Mixpanel -->
    HTML
  end
  
  def segment_code
    <<~HTML
      <!-- Segment -->
      <script type="text/javascript">
      !function(){var analytics=window.analytics=window.analytics||[];if(!analytics.initialize)if(analytics.invoked)window.console&&console.error&&console.error("Segment snippet included twice.");else{analytics.invoked=!0;analytics.methods=["trackSubmit","trackClick","trackLink","trackForm","pageview","identify","reset","group","track","ready","alias","debug","page","once","off","on","addSourceMiddleware","addIntegrationMiddleware","setAnonymousId","addDestinationMiddleware"];analytics.factory=function(e){return function(){var t=Array.prototype.slice.call(arguments);t.unshift(e);analytics.push(t);return analytics}};for(var e=0;e<analytics.methods.length;e++){var key=analytics.methods[e];analytics[key]=analytics.factory(key)}analytics.load=function(key,e){var t=document.createElement("script");t.type="text/javascript";t.async=!0;t.src="https://cdn.segment.com/analytics.js/v1/" + key + "/analytics.min.js";var n=document.getElementsByTagName("script")[0];n.parentNode.insertBefore(t,n);analytics._loadOptions=e};analytics._writeKey="#{pixel_id}";;analytics.SNIPPET_VERSION="4.15.3";
      analytics.load("#{pixel_id}");
      analytics.page();
      }}();
      </script>
      <!-- End Segment -->
    HTML
  end
  
  def heap_code
    <<~HTML
      <!-- Heap Analytics -->
      <script type="text/javascript">
      window.heap=window.heap||[],heap.load=function(e,t){window.heap.appid=e,window.heap.config=t=t||{};var r=document.createElement("script");r.type="text/javascript",r.async=!0,r.src="https://cdn.heapanalytics.com/js/heap-"+e+".js";var a=document.getElementsByTagName("script")[0];a.parentNode.insertBefore(r,a);for(var n=function(e){return function(){heap.push([e].concat(Array.prototype.slice.call(arguments,0)))}},p=["addEventProperties","addUserProperties","clearEventProperties","identify","resetIdentity","removeEventProperty","setEventProperties","track","unsetEventProperty"],o=0;o<p.length;o++)heap[p[o]]=n(p[o])};
      heap.load("#{pixel_id}");
      </script>
      <!-- End Heap Analytics -->
    HTML
  end
end
