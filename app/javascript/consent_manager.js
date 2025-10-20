/**
 * RailsPress Consent Manager
 * Enterprise-grade consent management system that rivals OneTrust
 * Handles GDPR, CCPA, and other privacy regulations
 */

class ConsentManager {
  constructor(config = {}) {
    this.config = {
      apiEndpoint: '/api/v1/consent',
      storageKey: 'railspress_consent',
      storageExpiry: 365 * 24 * 60 * 60 * 1000, // 1 year
      debug: false,
      ...config
    };
    
    this.consentData = null;
    this.bannerElement = null;
    this.modalElement = null;
    this.pixelManager = null;
    
    this.init();
  }
  
  async init() {
    try {
      // Load existing consent data
      this.consentData = this.loadConsentData();
      
      // Get user's IP and geolocation
      const region = await this.getUserRegion();
      
      // Load consent configuration
      const config = await this.loadConsentConfiguration();
      
      if (config && this.shouldShowBanner(config, region)) {
        this.showBanner(config, region);
      } else {
        this.applyConsentToPixels();
      }
      
      // Initialize pixel manager
      this.initPixelManager();
      
    } catch (error) {
      console.error('ConsentManager initialization error:', error);
    }
  }
  
  async loadConsentConfiguration() {
    try {
      const response = await fetch('/api/v1/consent/configuration');
      if (response.ok) {
        return await response.json();
      }
    } catch (error) {
      console.error('Failed to load consent configuration:', error);
    }
    return null;
  }
  
  async getUserRegion() {
    try {
      // Try to get region from stored data first
      const stored = localStorage.getItem('railspress_region');
      if (stored) {
        const data = JSON.parse(stored);
        if (data.timestamp && (Date.now() - data.timestamp) < 24 * 60 * 60 * 1000) {
          return data.region;
        }
      }
      
      // Get region from server
      const response = await fetch('/api/v1/consent/region');
      if (response.ok) {
        const data = await response.json();
        // Cache the region for 24 hours
        localStorage.setItem('railspress_region', JSON.stringify({
          region: data.region,
          timestamp: Date.now()
        }));
        return data.region;
      }
    } catch (error) {
      console.error('Failed to get user region:', error);
    }
    return 'unknown';
  }
  
  shouldShowBanner(config, region) {
    if (!config.banner_settings.enabled) {
      return false;
    }
    
    // Check if user has already given consent
    if (this.consentData && Object.keys(this.consentData).length > 0) {
      return false;
    }
    
    // Check region-specific requirements
    const regionSettings = config.geolocation_settings.region_specific_settings[region];
    if (regionSettings && regionSettings.require_explicit_consent === false) {
      return false;
    }
    
    return true;
  }
  
  showBanner(config, region) {
    // Create banner HTML
    const bannerHTML = this.generateBannerHTML(config);
    const cssHTML = this.generateBannerCSS(config);
    
    // Inject CSS
    this.injectCSS(cssHTML);
    
    // Inject banner HTML
    document.body.insertAdjacentHTML('beforeend', bannerHTML);
    
    // Get elements
    this.bannerElement = document.getElementById('consent-banner');
    this.modalElement = document.getElementById('consent-preferences-modal');
    
    // Show banner with animation
    setTimeout(() => {
      this.bannerElement.classList.add('show');
    }, 100);
    
    // Store config for later use
    this.currentConfig = config;
    this.currentRegion = region;
  }
  
  hideBanner() {
    if (this.bannerElement) {
      this.bannerElement.classList.remove('show');
      setTimeout(() => {
        this.bannerElement.remove();
      }, 300);
    }
  }
  
  showPreferencesModal() {
    if (this.modalElement) {
      this.modalElement.style.display = 'flex';
      // Populate form with current consent data
      this.populatePreferencesForm();
    }
  }
  
  hidePreferencesModal() {
    if (this.modalElement) {
      this.modalElement.style.display = 'none';
    }
  }
  
  async acceptAll() {
    const consent = this.getDefaultConsent(true);
    await this.saveConsent(consent);
    this.hideBanner();
    this.applyConsentToPixels();
    
    // Auto-hide after delay if configured
    if (this.currentConfig?.banner_settings.auto_hide_after_accept) {
      setTimeout(() => {
        this.hideBanner();
      }, this.currentConfig.banner_settings.auto_hide_delay || 3000);
    }
  }
  
  async rejectAll() {
    const consent = this.getDefaultConsent(false);
    await this.saveConsent(consent);
    this.hideBanner();
    this.applyConsentToPixels();
  }
  
  async acceptNecessary() {
    const consent = this.getNecessaryOnlyConsent();
    await this.saveConsent(consent);
    this.hideBanner();
    this.applyConsentToPixels();
  }
  
  async savePreferences() {
    const formData = this.getPreferencesFormData();
    await this.saveConsent(formData);
    this.hidePreferencesModal();
    this.applyConsentToPixels();
  }
  
  getDefaultConsent(acceptAll = false) {
    const consent = {};
    const categories = this.currentConfig.consent_categories_with_defaults;
    
    Object.keys(categories).forEach(category => {
      const settings = categories[category];
      if (acceptAll || settings.default_enabled || settings.required) {
        consent[category] = {
          granted: true,
          granted_at: new Date().toISOString(),
          consent_text: settings.name,
          ip_address: this.getUserIP(),
          user_agent: navigator.userAgent
        };
      }
    });
    
    return consent;
  }
  
  getNecessaryOnlyConsent() {
    const consent = {};
    const categories = this.currentConfig.consent_categories_with_defaults;
    
    Object.keys(categories).forEach(category => {
      const settings = categories[category];
      if (settings.required) {
        consent[category] = {
          granted: true,
          granted_at: new Date().toISOString(),
          consent_text: settings.name,
          ip_address: this.getUserIP(),
          user_agent: navigator.userAgent
        };
      }
    });
    
    return consent;
  }
  
  getPreferencesFormData() {
    const consent = {};
    const checkboxes = this.modalElement.querySelectorAll('input[type="checkbox"][data-category]');
    
    checkboxes.forEach(checkbox => {
      const category = checkbox.dataset.category;
      const categories = this.currentConfig.consent_categories_with_defaults;
      const settings = categories[category];
      
      if (settings.required || checkbox.checked) {
        consent[category] = {
          granted: checkbox.checked,
          granted_at: new Date().toISOString(),
          consent_text: settings.name,
          ip_address: this.getUserIP(),
          user_agent: navigator.userAgent
        };
      }
    });
    
    return consent;
  }
  
  populatePreferencesForm() {
    const checkboxes = this.modalElement.querySelectorAll('input[type="checkbox"][data-category]');
    
    checkboxes.forEach(checkbox => {
      const category = checkbox.dataset.category;
      if (this.consentData && this.consentData[category]) {
        checkbox.checked = this.consentData[category].granted;
      }
    });
  }
  
  async saveConsent(consent) {
    try {
      // Save to localStorage
      const consentData = {
        ...consent,
        timestamp: Date.now(),
        version: this.currentConfig?.version || '1.0'
      };
      
      localStorage.setItem(this.config.storageKey, JSON.stringify(consentData));
      this.consentData = consentData;
      
      // Send to server
      await fetch(this.config.apiEndpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: JSON.stringify({
          consent: consent,
          region: this.currentRegion,
          timestamp: new Date().toISOString()
        })
      });
      
      this.log('Consent saved successfully');
      
    } catch (error) {
      console.error('Failed to save consent:', error);
    }
  }
  
  loadConsentData() {
    try {
      const stored = localStorage.getItem(this.config.storageKey);
      if (stored) {
        const data = JSON.parse(stored);
        // Check if consent is still valid (not expired)
        if (data.timestamp && (Date.now() - data.timestamp) < this.config.storageExpiry) {
          return data;
        }
      }
    } catch (error) {
      console.error('Failed to load consent data:', error);
    }
    return null;
  }
  
  applyConsentToPixels() {
    if (!this.consentData) {
      return;
    }
    
    // Get all pixel elements
    const pixels = document.querySelectorAll('[data-pixel-type]');
    
    pixels.forEach(pixel => {
      const pixelType = pixel.dataset.pixelType;
      const requiredConsent = this.getRequiredConsentForPixel(pixelType);
      
      if (requiredConsent && this.hasConsent(requiredConsent)) {
        // User has consent, load the pixel
        this.loadPixel(pixel);
      } else {
        // User doesn't have consent, hide or disable the pixel
        this.disablePixel(pixel);
      }
    });
    
    // Also handle dynamically loaded pixels
    this.observePixelChanges();
  }
  
  getRequiredConsentForPixel(pixelType) {
    if (!this.currentConfig) {
      return null;
    }
    
    const mapping = this.currentConfig.pixel_consent_mapping_with_defaults;
    
    for (const [category, pixels] of Object.entries(mapping)) {
      if (pixels.includes(pixelType)) {
        return category;
      }
    }
    
    return null;
  }
  
  hasConsent(category) {
    return this.consentData && this.consentData[category] && this.consentData[category].granted;
  }
  
  loadPixel(pixelElement) {
    // Remove disabled class and show pixel
    pixelElement.classList.remove('consent-disabled');
    pixelElement.style.display = '';
    
    // If pixel has data-src attribute, load it
    const dataSrc = pixelElement.dataset.src;
    if (dataSrc) {
      pixelElement.src = dataSrc;
    }
    
    // Execute any pixel scripts
    const scripts = pixelElement.querySelectorAll('script');
    scripts.forEach(script => {
      const newScript = document.createElement('script');
      newScript.textContent = script.textContent;
      document.head.appendChild(newScript);
    });
  }
  
  disablePixel(pixelElement) {
    // Add disabled class and hide pixel
    pixelElement.classList.add('consent-disabled');
    pixelElement.style.display = 'none';
    
    // Remove src to prevent loading
    pixelElement.removeAttribute('src');
  }
  
  observePixelChanges() {
    // Watch for new pixel elements being added to the DOM
    const observer = new MutationObserver(mutations => {
      mutations.forEach(mutation => {
        mutation.addedNodes.forEach(node => {
          if (node.nodeType === Node.ELEMENT_NODE) {
            if (node.dataset && node.dataset.pixelType) {
              // New pixel element added
              this.applyConsentToPixels();
            }
            
            // Check for pixel elements in the added node
            const pixels = node.querySelectorAll && node.querySelectorAll('[data-pixel-type]');
            if (pixels && pixels.length > 0) {
              this.applyConsentToPixels();
            }
          }
        });
      });
    });
    
    observer.observe(document.body, {
      childList: true,
      subtree: true
    });
  }
  
  initPixelManager() {
    // Initialize pixel manager for dynamic pixel loading
    this.pixelManager = {
      loadPixel: (pixelType, pixelData) => {
        const requiredConsent = this.getRequiredConsentForPixel(pixelType);
        
        if (!requiredConsent || this.hasConsent(requiredConsent)) {
          // Load the pixel
          this.executePixelCode(pixelType, pixelData);
        } else {
          this.log(`Pixel ${pixelType} blocked due to missing consent for ${requiredConsent}`);
        }
      },
      
      executePixelCode: (pixelType, pixelData) => {
        // Execute pixel-specific code
        switch (pixelType) {
          case 'google_analytics':
            this.loadGoogleAnalytics(pixelData);
            break;
          case 'facebook_pixel':
            this.loadFacebookPixel(pixelData);
            break;
          case 'tiktok_pixel':
            this.loadTikTokPixel(pixelData);
            break;
          // Add more pixel types as needed
          default:
            this.log(`Unknown pixel type: ${pixelType}`);
        }
      }
    };
  }
  
  loadGoogleAnalytics(pixelData) {
    if (window.gtag) {
      return; // Already loaded
    }
    
    // Load Google Analytics
    const script = document.createElement('script');
    script.async = true;
    script.src = `https://www.googletagmanager.com/gtag/js?id=${pixelData.pixel_id}`;
    document.head.appendChild(script);
    
    script.onload = () => {
      window.dataLayer = window.dataLayer || [];
      function gtag(){dataLayer.push(arguments);}
      window.gtag = gtag;
      gtag('js', new Date());
      gtag('config', pixelData.pixel_id);
    };
  }
  
  loadFacebookPixel(pixelData) {
    if (window.fbq) {
      return; // Already loaded
    }
    
    // Load Facebook Pixel
    !function(f,b,e,v,n,t,s)
    {if(f.fbq)return;n=f.fbq=function(){n.callMethod?
    n.callMethod.apply(n,arguments):n.queue.push(arguments)};
    if(!f._fbq)f._fbq=n;n.push=n;n.loaded=!0;n.version='2.0';
    n.queue=[];t=b.createElement(e);t.async=!0;
    t.src=v;s=b.getElementsByTagName(e)[0];
    s.parentNode.insertBefore(t,s)}(window, document,'script',
    'https://connect.facebook.net/en_US/fbevents.js');
    
    window.fbq('init', pixelData.pixel_id);
    window.fbq('track', 'PageView');
  }
  
  loadTikTokPixel(pixelData) {
    if (window.ttq) {
      return; // Already loaded
    }
    
    // Load TikTok Pixel
    !function (w, d, t) {
      w.TiktokAnalyticsObject=t;var ttq=w[t]=w[t]||[];ttq.methods=["page","track","identify","instances","debug","on","off","once","ready","alias","group","enableCookie","disableCookie"],ttq.setAndDefer=function(t,e){t[e]=function(){t.push([e].concat(Array.prototype.slice.call(arguments,0)))}};for(var i=0;i<ttq.methods.length;i++)ttq.setAndDefer(ttq,ttq.methods[i]);ttq.instance=function(t){for(var e=ttq._i[t]||[],n=0;n<ttq.methods.length;n++)ttq.setAndDefer(e,ttq.methods[n]);return e},ttq.load=function(e,n){var i="https://analytics.tiktok.com/i18n/pixel/events.js";ttq._i=ttq._i||{},ttq._i[e]=[],ttq._i[e]._u=i,ttq._t=ttq._t||{},ttq._t[e]=+new Date,ttq._o=ttq._o||{},ttq._o[e]=n||{};var o=document.createElement("script");o.type="text/javascript",o.async=!0,o.src=i+"?sdkid="+e+"&lib="+t;var a=document.getElementsByTagName("script")[0];a.parentNode.insertBefore(o,a)};
      ttq.load(pixelData.pixel_id);
      ttq.page();
    }(window, document, 'ttq');
  }
  
  generateBannerHTML(config) {
    const settings = config.banner_settings_with_defaults;
    
    return `
      <div id="consent-banner" class="consent-banner">
        <div class="consent-banner-content">
          <div class="consent-banner-header">
            <h3 class="consent-banner-title">${settings.text.title}</h3>
            <button class="consent-banner-close" onclick="ConsentManager.hideBanner()">
              <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414 1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"></path>
              </svg>
            </button>
          </div>
          <div class="consent-banner-body">
            <p class="consent-banner-description">${settings.text.description}</p>
          </div>
          <div class="consent-banner-actions">
            ${this.generateBannerButtons(settings)}
          </div>
        </div>
      </div>
      <div id="consent-preferences-modal" class="consent-preferences-modal">
        <div class="consent-modal-content">
          <div class="consent-modal-header">
            <h3 class="consent-modal-title">Cookie Preferences</h3>
            <button class="consent-modal-close" onclick="ConsentManager.hidePreferencesModal()">
              <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414 1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"></path>
              </svg>
            </button>
          </div>
          <div class="consent-modal-body">
            ${this.generatePreferencesForm(config.consent_categories_with_defaults)}
          </div>
          <div class="consent-modal-actions">
            <button class="consent-btn consent-btn-secondary" onclick="ConsentManager.hidePreferencesModal()">
              ${settings.text.close}
            </button>
            <button class="consent-btn consent-btn-primary" onclick="ConsentManager.savePreferences()">
              ${settings.text.save_preferences}
            </button>
          </div>
        </div>
      </div>
    `;
  }
  
  generateBannerCSS(config) {
    // This would generate the CSS based on the config
    // For now, return the default CSS
    return `
      .consent-banner {
        position: fixed;
        bottom: 0;
        left: 0;
        right: 0;
        background: #1f2937;
        color: white;
        padding: 20px;
        box-shadow: 0 -4px 6px -1px rgba(0, 0, 0, 0.1);
        z-index: 9999;
        font-family: system-ui, -apple-system, sans-serif;
        transform: translateY(100%);
        transition: transform 300ms ease-in-out;
      }
      
      .consent-banner.show {
        transform: translateY(0);
      }
      
      .consent-banner-content {
        max-width: 1200px;
        margin: 0 auto;
        display: flex;
        flex-direction: column;
        gap: 16px;
      }
      
      .consent-banner-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
      }
      
      .consent-banner-title {
        font-size: 18px;
        font-weight: 600;
        margin: 0;
        color: white;
      }
      
      .consent-banner-close {
        background: none;
        border: none;
        color: white;
        cursor: pointer;
        padding: 4px;
        border-radius: 4px;
        transition: background-color 0.2s;
      }
      
      .consent-banner-close:hover {
        background-color: rgba(255, 255, 255, 0.1);
      }
      
      .consent-banner-description {
        font-size: 14px;
        margin: 0;
        line-height: 1.5;
        color: white;
      }
      
      .consent-banner-actions {
        display: flex;
        gap: 12px;
        flex-wrap: wrap;
      }
      
      .consent-btn {
        padding: 10px 20px;
        border: none;
        border-radius: 6px;
        font-size: 14px;
        font-weight: 500;
        cursor: pointer;
        transition: all 0.2s;
        font-family: system-ui, -apple-system, sans-serif;
      }
      
      .consent-btn-primary {
        background-color: #10b981;
        color: white;
      }
      
      .consent-btn-primary:hover {
        opacity: 0.9;
        transform: translateY(-1px);
      }
      
      .consent-btn-secondary {
        background-color: #ef4444;
        color: white;
      }
      
      .consent-btn-secondary:hover {
        opacity: 0.9;
        transform: translateY(-1px);
      }
      
      .consent-btn-neutral {
        background-color: #6b7280;
        color: white;
      }
      
      .consent-btn-neutral:hover {
        opacity: 0.9;
        transform: translateY(-1px);
      }
      
      .consent-preferences-modal {
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background-color: rgba(0, 0, 0, 0.5);
        z-index: 10000;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 20px;
      }
      
      .consent-modal-content {
        background: white;
        border-radius: 8px;
        max-width: 600px;
        width: 100%;
        max-height: 80vh;
        overflow-y: auto;
        box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
      }
      
      .consent-modal-header {
        padding: 20px;
        border-bottom: 1px solid #e5e7eb;
        display: flex;
        justify-content: space-between;
        align-items: center;
      }
      
      .consent-modal-title {
        font-size: 18px;
        font-weight: 600;
        margin: 0;
        color: #111827;
      }
      
      .consent-modal-close {
        background: none;
        border: none;
        color: #6b7280;
        cursor: pointer;
        padding: 4px;
        border-radius: 4px;
        transition: background-color 0.2s;
      }
      
      .consent-modal-close:hover {
        background-color: #f3f4f6;
      }
      
      .consent-modal-body {
        padding: 20px;
      }
      
      .consent-modal-actions {
        padding: 20px;
        border-top: 1px solid #e5e7eb;
        display: flex;
        justify-content: flex-end;
        gap: 12px;
      }
      
      .consent-category {
        margin-bottom: 20px;
        padding: 16px;
        border: 1px solid #e5e7eb;
        border-radius: 6px;
      }
      
      .consent-category-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 8px;
      }
      
      .consent-category-title {
        font-size: 16px;
        font-weight: 500;
        margin: 0;
        color: #111827;
      }
      
      .consent-category-description {
        font-size: 14px;
        color: #6b7280;
        margin: 0;
        line-height: 1.5;
      }
      
      .consent-toggle {
        position: relative;
        display: inline-block;
        width: 44px;
        height: 24px;
      }
      
      .consent-toggle input {
        opacity: 0;
        width: 0;
        height: 0;
      }
      
      .consent-slider {
        position: absolute;
        cursor: pointer;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background-color: #ccc;
        transition: 0.4s;
        border-radius: 24px;
      }
      
      .consent-slider:before {
        position: absolute;
        content: "";
        height: 18px;
        width: 18px;
        left: 3px;
        bottom: 3px;
        background-color: white;
        transition: 0.4s;
        border-radius: 50%;
      }
      
      .consent-toggle input:checked + .consent-slider {
        background-color: #10b981;
      }
      
      .consent-toggle input:checked + .consent-slider:before {
        transform: translateX(20px);
      }
      
      .consent-toggle input:disabled + .consent-slider {
        background-color: #6b7280;
        cursor: not-allowed;
      }
      
      @media (max-width: 768px) {
        .consent-banner-actions {
          flex-direction: column;
        }
        
        .consent-btn {
          width: 100%;
        }
        
        .consent-modal-content {
          margin: 10px;
        }
      }
    `;
  }
  
  generateBannerButtons(settings) {
    const buttons = [];
    
    if (settings.show_accept_all) {
      buttons.push(`<button class="consent-btn consent-btn-primary" onclick="ConsentManager.acceptAll()">${settings.text.accept_all}</button>`);
    }
    
    if (settings.show_reject_all) {
      buttons.push(`<button class="consent-btn consent-btn-secondary" onclick="ConsentManager.rejectAll()">${settings.text.reject_all}</button>`);
    }
    
    if (settings.show_necessary_only) {
      buttons.push(`<button class="consent-btn consent-btn-neutral" onclick="ConsentManager.acceptNecessary()">${settings.text.necessary_only}</button>`);
    }
    
    if (settings.show_manage_preferences) {
      buttons.push(`<button class="consent-btn consent-btn-neutral" onclick="ConsentManager.showPreferencesModal()">${settings.text.manage_preferences}</button>`);
    }
    
    return buttons.join('');
  }
  
  generatePreferencesForm(categories) {
    let formHTML = '';
    
    Object.keys(categories).forEach(category => {
      const settings = categories[category];
      const requiredClass = settings.required ? 'required' : '';
      const disabledAttr = settings.required ? 'disabled' : '';
      const checkedAttr = settings.default_enabled ? 'checked' : '';
      
      formHTML += `
        <div class="consent-category ${requiredClass}">
          <div class="consent-category-header">
            <h4 class="consent-category-title">${settings.name}</h4>
            <label class="consent-toggle">
              <input type="checkbox" ${checkedAttr} ${disabledAttr} data-category="${category}">
              <span class="consent-slider"></span>
            </label>
          </div>
          <p class="consent-category-description">${settings.description}</p>
        </div>
      `;
    });
    
    return formHTML;
  }
  
  injectCSS(css) {
    const style = document.createElement('style');
    style.textContent = css;
    document.head.appendChild(style);
  }
  
  getUserIP() {
    // This would typically be set by the server
    return window.userIP || 'unknown';
  }
  
  getCSRFToken() {
    const token = document.querySelector('meta[name="csrf-token"]');
    return token ? token.getAttribute('content') : '';
  }
  
  log(message) {
    if (this.config.debug) {
      console.log('[ConsentManager]', message);
    }
  }
}

// Initialize ConsentManager when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  window.ConsentManager = new ConsentManager();
});

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
  module.exports = ConsentManager;
}
