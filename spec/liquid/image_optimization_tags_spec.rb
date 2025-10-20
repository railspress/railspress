require 'rails_helper'

RSpec.describe 'Image Optimization Liquid Tags', type: :feature do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:upload) { create(:upload, user: user, tenant: tenant) }
  let(:medium) { create(:medium, user: user, tenant: tenant, upload: upload) }

  before do
    ActsAsTenant.current_tenant = tenant
    
    # Mock file attachment and variants
    allow(upload).to receive(:file).and_return(double(attached?: true))
    allow(upload).to receive(:url).and_return('/uploads/test.jpg')
    allow(upload).to receive(:webp_url).and_return('/uploads/test.webp')
    allow(upload).to receive(:avif_url).and_return('/uploads/test.avif')
    allow(upload).to receive(:responsive_webp_url).and_return('/uploads/test_640w.webp')
    allow(upload).to receive(:responsive_avif_url).and_return('/uploads/test_640w.avif')
    allow(upload).to receive(:generate_srcset).and_return('/uploads/test_320w.webp 320w, /uploads/test_640w.webp 640w')
    
    # Mock optimization log
    allow(ImageOptimizationLog).to receive(:where).and_return(double(count: 1))
    allow(ImageOptimizationLog).to receive(:successful).and_return(double(count: 1))
    allow(ImageOptimizationLog).to receive(:total_bytes_saved).and_return(100000)
  end

  describe 'image_optimized tag' do
    it 'renders optimized image with fallbacks' do
      template = Liquid::Template.parse('{% image_optimized medium: medium, alt: "Test image" %}')
      result = template.render('medium' => medium)
      
      expect(result).to include('<picture>')
      expect(result).to include('<source')
      expect(result).to include('type="image/avif"')
      expect(result).to include('type="image/webp"')
      expect(result).to include('<img')
      expect(result).to include('alt="Test image"')
    end

    it 'renders responsive image with srcset' do
      template = Liquid::Template.parse('{% image_optimized medium: medium, responsive: true %}')
      result = template.render('medium' => medium)
      
      expect(result).to include('srcset=')
      expect(result).to include('sizes=')
    end

    it 'renders with custom sizes' do
      template = Liquid::Template.parse('{% image_optimized medium: medium, sizes: "(max-width: 768px) 100vw, 50vw" %}')
      result = template.render('medium' => medium)
      
      expect(result).to include('sizes="(max-width: 768px) 100vw, 50vw"')
    end

    it 'renders with lazy loading' do
      template = Liquid::Template.parse('{% image_optimized medium: medium, lazy: true %}')
      result = template.render('medium' => medium)
      
      expect(result).to include('loading="lazy"')
    end

    it 'renders with custom CSS classes' do
      template = Liquid::Template.parse('{% image_optimized medium: medium, class: "custom-class" %}')
      result = template.render('medium' => medium)
      
      expect(result).to include('class="custom-class"')
    end

    it 'handles missing medium gracefully' do
      template = Liquid::Template.parse('{% image_optimized medium: nil %}')
      result = template.render
      
      expect(result).to be_empty
    end
  end

  describe 'background_image_optimized tag' do
    it 'renders optimized background image' do
      template = Liquid::Template.parse('{% background_image_optimized medium: medium, class: "hero-bg" %}')
      result = template.render('medium' => medium)
      
      expect(result).to include('<div')
      expect(result).to include('class="hero-bg"')
      expect(result).to include('style=')
      expect(result).to include('background-image:')
    end

    it 'renders with custom styles' do
      template = Liquid::Template.parse('{% background_image_optimized medium: medium, style: "background-size: cover;" %}')
      result = template.render('medium' => medium)
      
      expect(result).to include('background-size: cover;')
    end

    it 'renders with responsive background' do
      template = Liquid::Template.parse('{% background_image_optimized medium: medium, responsive: true %}')
      result = template.render('medium' => medium)
      
      expect(result).to include('@media')
      expect(result).to include('background-image:')
    end
  end

  describe 'optimization_stats tag' do
    it 'renders optimization statistics' do
      template = Liquid::Template.parse('{% optimization_stats %}')
      result = template.render
      
      expect(result).to include('Total Images Optimized')
      expect(result).to include('Total Bytes Saved')
      expect(result).to include('Average Size Reduction')
    end

    it 'renders with custom format' do
      template = Liquid::Template.parse('{% optimization_stats format: "json" %}')
      result = template.render
      
      expect(result).to start_with('{')
      expect(result).to end_with('}')
    end

    it 'renders with date filtering' do
      template = Liquid::Template.parse('{% optimization_stats start_date: "2024-01-01", end_date: "2024-12-31" %}')
      result = template.render
      
      expect(result).to include('Total Images Optimized')
    end
  end

  describe 'bulk_optimize tag' do
    it 'renders bulk optimization button' do
      template = Liquid::Template.parse('{% bulk_optimize %}')
      result = template.render
      
      expect(result).to include('<button')
      expect(result).to include('Bulk Optimize Images')
      expect(result).to include('onclick=')
    end

    it 'renders with custom text' do
      template = Liquid::Template.parse('{% bulk_optimize text: "Optimize All Images" %}')
      result = template.render
      
      expect(result).to include('Optimize All Images')
    end

    it 'renders with custom CSS class' do
      template = Liquid::Template.parse('{% bulk_optimize class: "btn-primary" %}')
      result = template.render
      
      expect(result).to include('class="btn-primary"')
    end
  end

  describe 'error handling' do
    it 'handles invalid parameters gracefully' do
      template = Liquid::Template.parse('{% image_optimized medium: "invalid" %}')
      result = template.render
      
      expect(result).to be_empty
    end

    it 'handles missing required parameters' do
      template = Liquid::Template.parse('{% image_optimized %}')
      result = template.render
      
      expect(result).to be_empty
    end

    it 'handles template syntax errors' do
      template = Liquid::Template.parse('{% image_optimized medium: medium %}')
      result = template.render('medium' => medium)
      
      expect(result).not_to be_nil
    end
  end

  describe 'integration with optimization system' do
    it 'uses actual optimization data when available' do
      # Create actual optimization log
      log = create(:image_optimization_log, 
                   medium: medium, 
                   upload: upload, 
                   user: user, 
                   tenant: tenant,
                   status: 'success',
                   bytes_saved: 50000,
                   size_reduction_percentage: 25.0)
      
      template = Liquid::Template.parse('{% optimization_stats %}')
      result = template.render
      
      expect(result).to include('1') # Total optimizations
      expect(result).to include('50,000') # Bytes saved
      expect(result).to include('25.0') # Size reduction percentage
    end

    it 'handles empty optimization data' do
      allow(ImageOptimizationLog).to receive(:count).and_return(0)
      allow(ImageOptimizationLog).to receive(:total_bytes_saved).and_return(0)
      
      template = Liquid::Template.parse('{% optimization_stats %}')
      result = template.render
      
      expect(result).to include('0') # No optimizations
    end
  end

  describe 'performance considerations' do
    it 'does not cause N+1 queries' do
      # Create multiple mediums
      mediums = create_list(:medium, 5, user: user, tenant: tenant)
      
      template = Liquid::Template.parse('{% for medium in mediums %}{% image_optimized medium: medium %}{% endfor %}')
      
      expect {
        template.render('mediums' => mediums)
      }.not_to exceed_query_limit(10) # Reasonable limit for the queries needed
    end

    it 'caches optimization statistics' do
      template = Liquid::Template.parse('{% optimization_stats %}{% optimization_stats %}')
      
      expect(ImageOptimizationLog).to receive(:count).once.and_return(1)
      expect(ImageOptimizationLog).to receive(:total_bytes_saved).once.and_return(100000)
      
      template.render
    end
  end

  describe 'accessibility features' do
    it 'includes proper alt text' do
      template = Liquid::Template.parse('{% image_optimized medium: medium, alt: "Descriptive alt text" %}')
      result = template.render('medium' => medium)
      
      expect(result).to include('alt="Descriptive alt text"')
    end

    it 'includes loading attribute for lazy loading' do
      template = Liquid::Template.parse('{% image_optimized medium: medium, lazy: true %}')
      result = template.render('medium' => medium)
      
      expect(result).to include('loading="lazy"')
    end

    it 'includes proper ARIA attributes' do
      template = Liquid::Template.parse('{% image_optimized medium: medium, aria_label: "Image description" %}')
      result = template.render('medium' => medium)
      
      expect(result).to include('aria-label="Image description"')
    end
  end

  describe 'SEO features' do
    it 'includes proper meta attributes' do
      template = Liquid::Template.parse('{% image_optimized medium: medium, itemprop: "image" %}')
      result = template.render('medium' => medium)
      
      expect(result).to include('itemprop="image"')
    end

    it 'includes Open Graph attributes' do
      template = Liquid::Template.parse('{% image_optimized medium: medium, og_image: true %}')
      result = template.render('medium' => medium)
      
      expect(result).to include('property="og:image"')
    end
  end
end
