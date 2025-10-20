require 'rails_helper'

RSpec.describe ImageOptimizationService, type: :service do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:upload) { create(:upload, user: user, tenant: tenant) }
  let(:medium) { create(:medium, user: user, tenant: tenant, upload: upload) }
  let(:service) { ImageOptimizationService.new(medium) }

  before do
    # Mock file attachment
    allow(upload).to receive(:file).and_return(double(attached?: true, download: 'fake_image_data'))
    allow(medium).to receive(:image?).and_return(true)
    
    # Mock storage configuration
    storage_config = double('StorageConfigurationService')
    allow(StorageConfigurationService).to receive(:new).and_return(storage_config)
    allow(storage_config).to receive(:auto_optimize_enabled?).and_return(true)
    
    # Mock site settings
    allow(SiteSetting).to receive(:get).with('auto_optimize_images', false).and_return(true)
    allow(SiteSetting).to receive(:get).with('image_compression_level', 'lossy').and_return('lossy')
    allow(SiteSetting).to receive(:get).with('image_quality', 85).and_return(85)
    allow(SiteSetting).to receive(:get).with('image_compression_level_value', 6).and_return(6)
    allow(SiteSetting).to receive(:get).with('image_max_width', 2000).and_return(2000)
    allow(SiteSetting).to receive(:get).with('image_max_height', 2000).and_return(2000)
    allow(SiteSetting).to receive(:get).with('strip_image_metadata', true).and_return(true)
    allow(SiteSetting).to receive(:get).with('enable_webp_variants', true).and_return(true)
    allow(SiteSetting).to receive(:get).with('enable_avif_variants', true).and_return(true)
    allow(SiteSetting).to receive(:get).with('enable_responsive_variants', true).and_return(true)
    allow(SiteSetting).to receive(:get).with('responsive_breakpoints', '320,640,768,1024,1200,1920').and_return('320,640,768,1024,1200,1920')
  end

  describe '#initialize' do
    it 'initializes with medium' do
      expect(service.instance_variable_get(:@medium)).to eq(medium)
    end

    it 'loads settings correctly' do
      expect(service.quality).to eq(85)
      expect(service.max_width).to eq(2000)
      expect(service.max_height).to eq(2000)
      expect(service.strip_metadata).to be true
      expect(service.enable_webp).to be true
      expect(service.enable_avif).to be true
    end
  end

  describe 'compression level methods' do
    it 'returns compression level info' do
      expect(service.compression_level_info).to be_a(Hash)
      expect(service.compression_level_info[:name]).to eq('Lossy')
    end

    it 'returns compression level name' do
      expect(service.compression_level_name).to eq('lossy')
    end

    it 'returns expected savings' do
      expect(service.expected_savings).to eq('25-40%')
    end

    it 'returns recommended for' do
      expect(service.recommended_for).to eq('General web images, blog posts')
    end
  end

  describe 'class methods' do
    describe '.available_compression_levels' do
      it 'returns all compression levels' do
        levels = ImageOptimizationService.available_compression_levels
        expect(levels).to have_key('lossless')
        expect(levels).to have_key('lossy')
        expect(levels).to have_key('ultra')
        expect(levels).to have_key('custom')
      end
    end

    describe '.supported_formats' do
      it 'returns all supported formats' do
        formats = ImageOptimizationService.supported_formats
        expect(formats).to have_key('jpeg')
        expect(formats).to have_key('png')
        expect(formats).to have_key('webp')
        expect(formats).to have_key('avif')
        expect(formats).to have_key('heic')
        expect(formats).to have_key('jxl')
      end
    end

    describe '.modern_formats' do
      it 'returns only modern formats' do
        modern_formats = ImageOptimizationService.modern_formats
        expect(modern_formats).to have_key('webp')
        expect(modern_formats).to have_key('avif')
        expect(modern_formats).to have_key('heic')
        expect(modern_formats).to have_key('jxl')
        expect(modern_formats).not_to have_key('jpeg')
        expect(modern_formats).not_to have_key('png')
      end
    end

    describe '.traditional_formats' do
      it 'returns only traditional formats' do
        traditional_formats = ImageOptimizationService.traditional_formats
        expect(traditional_formats).to have_key('jpeg')
        expect(traditional_formats).to have_key('png')
        expect(traditional_formats).to have_key('gif')
        expect(traditional_formats).not_to have_key('webp')
        expect(traditional_formats).not_to have_key('avif')
      end
    end

    describe '.supports_format?' do
      it 'returns true for supported formats' do
        expect(ImageOptimizationService.supports_format?('webp')).to be true
        expect(ImageOptimizationService.supports_format?('avif')).to be true
        expect(ImageOptimizationService.supports_format?('jpeg')).to be true
      end

      it 'returns false for unsupported formats' do
        expect(ImageOptimizationService.supports_format?('xyz')).to be false
        expect(ImageOptimizationService.supports_format?('unknown')).to be false
      end
    end

    describe '.modern_format?' do
      it 'returns true for modern formats' do
        expect(ImageOptimizationService.modern_format?('webp')).to be true
        expect(ImageOptimizationService.modern_format?('avif')).to be true
        expect(ImageOptimizationService.modern_format?('heic')).to be true
      end

      it 'returns false for traditional formats' do
        expect(ImageOptimizationService.modern_format?('jpeg')).to be false
        expect(ImageOptimizationService.modern_format?('png')).to be false
        expect(ImageOptimizationService.modern_format?('gif')).to be false
      end
    end
  end

  describe '#should_optimize?' do
    it 'returns true when all conditions are met' do
      expect(service.send(:should_optimize?)).to be true
    end

    it 'returns false when medium is not an image' do
      allow(medium).to receive(:image?).and_return(false)
      expect(service.send(:should_optimize?)).to be false
    end

    it 'returns false when file is not attached' do
      allow(upload).to receive(:file).and_return(double(attached?: false))
      expect(service.send(:should_optimize?)).to be false
    end

    it 'returns false when optimization is disabled' do
      allow(SiteSetting).to receive(:get).with('auto_optimize_images', false).and_return(false)
      expect(service.send(:should_optimize?)).to be false
    end
  end

  describe '#optimize!' do
    before do
      # Mock image processing
      allow(service).to receive(:process_image).and_return('optimized_image_data')
      allow(service).to receive(:replace_file)
      allow(service).to receive(:generate_all_variants).and_return(['webp', 'avif'])
      allow(service).to receive(:generate_responsive_variants!).and_return(true)
      allow(service).to receive(:create_log_entry)
      allow(service).to receive(:update_log_entry)
    end

    it 'returns true when optimization succeeds' do
      expect(service.optimize!).to be true
    end

    it 'calls process_image with original file' do
      expect(service).to receive(:process_image).with('fake_image_data')
      service.optimize!
    end

    it 'calls replace_file with optimized data' do
      expect(service).to receive(:replace_file).with('optimized_image_data')
      service.optimize!
    end

    it 'generates variants when enabled' do
      expect(service).to receive(:generate_all_variants).with('fake_image_data')
      expect(service).to receive(:generate_responsive_variants!).with('fake_image_data')
      service.optimize!
    end

    it 'returns false when no size reduction is achieved' do
      allow(service).to receive(:process_image).and_return('same_size_data')
      allow('same_size_data').to receive(:size).and_return(1000)
      allow('fake_image_data').to receive(:size).and_return(1000)
      
      expect(service.optimize!).to be false
    end

    it 'handles errors gracefully' do
      allow(service).to receive(:process_image).and_raise(StandardError.new('Processing failed'))
      allow(service).to receive(:update_log_entry)
      
      expect(service.optimize!).to be false
    end
  end

  describe '#generate_all_variants' do
    before do
      allow(SiteSetting).to receive(:get).with('enable_webp_variants', true).and_return(true)
      allow(SiteSetting).to receive(:get).with('enable_avif_variants', true).and_return(true)
      allow(SiteSetting).to receive(:get).with('enable_heic_variants', true).and_return(true)
      allow(SiteSetting).to receive(:get).with('enable_jxl_variants', true).and_return(true)
      allow(service).to receive(:generate_variant).and_return('variant_data')
      allow(service).to receive(:store_variant)
    end

    it 'generates all enabled variants' do
      result = service.generate_all_variants('image_data')
      expect(result).to include('webp', 'avif', 'heic', 'jxl')
    end

    it 'skips disabled variants' do
      allow(SiteSetting).to receive(:get).with('enable_webp_variants', true).and_return(false)
      
      result = service.generate_all_variants('image_data')
      expect(result).not_to include('webp')
    end
  end

  describe '#generate_responsive_variants!' do
    before do
      allow(SiteSetting).to receive(:get).with('enable_responsive_variants', true).and_return(true)
      allow(SiteSetting).to receive(:get).with('responsive_breakpoints', '320,640,768,1024,1200,1920').and_return('320,640,768')
      allow(SiteSetting).to receive(:get).with('enable_webp_variants', true).and_return(true)
      allow(SiteSetting).to receive(:get).with('enable_avif_variants', true).and_return(true)
      allow(service).to receive(:generate_responsive_variant).and_return('responsive_data')
      allow(service).to receive(:store_responsive_variant)
    end

    it 'generates responsive variants for all breakpoints' do
      expect(service).to receive(:generate_responsive_variant).exactly(9).times # 3 breakpoints * 3 formats
      expect(service).to receive(:store_responsive_variant).exactly(9).times
      
      service.generate_responsive_variants!('image_data')
    end

    it 'returns false when responsive variants are disabled' do
      allow(SiteSetting).to receive(:get).with('enable_responsive_variants', true).and_return(false)
      
      expect(service.generate_responsive_variants!('image_data')).to be false
    end
  end

  describe 'variant generation methods' do
    before do
      # Mock image processing
      allow(ImageProcessing::Vips).to receive(:source).and_return(double(
        convert: double(saver: double(call: double(path: '/tmp/test.jpg'))),
        saver: double(call: double(path: '/tmp/test.jpg'))
      ))
      allow(File).to receive(:read).and_return('processed_data')
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:unlink)
    end

    describe '#generate_webp_variant' do
      it 'generates WebP variant' do
        result = service.send(:generate_webp_variant, 'image_data')
        expect(result).to eq('processed_data')
      end
    end

    describe '#generate_avif_variant' do
      it 'generates AVIF variant' do
        result = service.send(:generate_avif_variant, 'image_data')
        expect(result).to eq('processed_data')
      end
    end

    describe '#generate_responsive_variant' do
      it 'generates responsive variant' do
        result = service.send(:generate_responsive_variant, 'image_data', 640, 'webp')
        expect(result).to eq('processed_data')
      end
    end
  end

  describe 'file operations' do
    describe '#replace_file' do
      it 'replaces the original file' do
        file_double = double('file')
        allow(upload).to receive(:file).and_return(file_double)
        allow(file_double).to receive(:purge)
        allow(file_double).to receive(:attach)
        allow(file_double).to receive(:filename).and_return(double(to_s: 'test.jpg'))
        allow(file_double).to receive(:content_type).and_return('image/jpeg')
        allow(upload).to receive(:update!)
        
        service.send(:replace_file, 'new_data')
        
        expect(file_double).to have_received(:purge)
        expect(file_double).to have_received(:attach)
        expect(upload).to have_received(:update!)
      end
    end

    describe '#store_variant' do
      it 'stores variant metadata' do
        allow(ActiveStorage::Blob).to receive(:create_and_upload!).and_return(double(id: 123))
        allow(upload).to receive(:update!)
        
        service.send(:store_variant, 'variant_data', 'webp')
        
        expect(upload).to have_received(:update!)
      end
    end

    describe '#store_responsive_variant' do
      it 'stores responsive variant metadata' do
        allow(ActiveStorage::Blob).to receive(:create_and_upload!).and_return(double(id: 123))
        allow(upload).to receive(:update!)
        
        service.send(:store_responsive_variant, 'responsive_data', 'webp', 640)
        
        expect(upload).to have_received(:update!)
      end
    end
  end

  describe 'logging methods' do
    describe '#create_log_entry' do
      it 'creates log entry' do
        allow(ImageOptimizationLog).to receive(:create!).and_return(double(id: 1))
        
        service.send(:create_log_entry)
        
        expect(ImageOptimizationLog).to have_received(:create!)
      end
    end

    describe '#update_log_entry' do
      before do
        @log_entry = double('log_entry')
        service.instance_variable_set(:@log_entry, @log_entry)
        allow(@log_entry).to receive(:update!)
      end

      it 'updates log entry' do
        service.send(:update_log_entry, { status: 'success' })
        
        expect(@log_entry).to have_received(:update!)
      end
    end
  end
end
