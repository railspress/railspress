require 'rails_helper'

RSpec.describe ImageOptimizationLog, type: :model do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:upload) { create(:upload, user: user, tenant: tenant) }
  let(:medium) { create(:medium, user: user, tenant: tenant, upload: upload) }
  let(:log_entry) do
    create(:image_optimization_log,
           medium: medium,
           upload: upload,
           user: user,
           tenant: tenant,
           filename: 'test.jpg',
           content_type: 'image/jpeg',
           original_size: 1000000,
           optimized_size: 750000,
           compression_level: 'lossy',
           quality: 85,
           processing_time: 1.5,
           status: 'success',
           optimization_type: 'upload')
  end

  describe 'associations' do
    it { should belong_to(:medium) }
    it { should belong_to(:upload) }
    it { should belong_to(:user) }
    it { should belong_to(:tenant) }
  end

  describe 'validations' do
    it { should validate_presence_of(:filename) }
    it { should validate_presence_of(:content_type) }
    it { should validate_presence_of(:compression_level) }
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:optimization_type) }
  end

  describe 'serialization' do
    it 'serializes variants_generated as JSON' do
      log_entry.variants_generated = ['webp', 'avif']
      log_entry.save!
      log_entry.reload
      expect(log_entry.variants_generated).to eq(['webp', 'avif'])
    end

    it 'serializes responsive_variants_generated as JSON' do
      log_entry.responsive_variants_generated = ['webp_640w', 'avif_1024w']
      log_entry.save!
      log_entry.reload
      expect(log_entry.responsive_variants_generated).to eq(['webp_640w', 'avif_1024w'])
    end

    it 'serializes warnings as JSON' do
      log_entry.warnings = ['Warning: Large file size', 'Warning: Low quality']
      log_entry.save!
      log_entry.reload
      expect(log_entry.warnings).to eq(['Warning: Large file size', 'Warning: Low quality'])
    end
  end

  describe 'callbacks' do
    describe 'before_save :calculate_savings' do
      it 'calculates bytes_saved' do
        log_entry.original_size = 1000000
        log_entry.optimized_size = 750000
        log_entry.save!
        
        expect(log_entry.bytes_saved).to eq(250000)
      end

      it 'calculates size_reduction_percentage' do
        log_entry.original_size = 1000000
        log_entry.optimized_size = 750000
        log_entry.save!
        
        expect(log_entry.size_reduction_percentage).to eq(25.0)
      end

      it 'handles zero original size' do
        log_entry.original_size = 0
        log_entry.optimized_size = 100
        log_entry.save!
        
        expect(log_entry.size_reduction_percentage).to be_nil
      end
    end
  end

  describe 'scopes' do
    let!(:successful_log) { create(:image_optimization_log, status: 'success', tenant: tenant) }
    let!(:failed_log) { create(:image_optimization_log, status: 'failed', tenant: tenant) }
    let!(:skipped_log) { create(:image_optimization_log, status: 'skipped', tenant: tenant) }

    describe '.successful' do
      it 'returns only successful logs' do
        expect(ImageOptimizationLog.successful).to include(successful_log)
        expect(ImageOptimizationLog.successful).not_to include(failed_log, skipped_log)
      end
    end

    describe '.failed' do
      it 'returns only failed logs' do
        expect(ImageOptimizationLog.failed).to include(failed_log)
        expect(ImageOptimizationLog.failed).not_to include(successful_log, skipped_log)
      end
    end

    describe '.skipped' do
      it 'returns only skipped logs' do
        expect(ImageOptimizationLog.skipped).to include(skipped_log)
        expect(ImageOptimizationLog.skipped).not_to include(successful_log, failed_log)
      end
    end

    describe '.recent' do
      it 'returns logs ordered by created_at desc' do
        expect(ImageOptimizationLog.recent.first).to eq(skipped_log)
      end
    end

    describe '.today' do
      it 'returns logs from today' do
        expect(ImageOptimizationLog.today.count).to eq(3)
      end
    end

    describe '.this_week' do
      it 'returns logs from this week' do
        expect(ImageOptimizationLog.this_week.count).to eq(3)
      end
    end

    describe '.this_month' do
      it 'returns logs from this month' do
        expect(ImageOptimizationLog.this_month.count).to eq(3)
      end
    end
  end

  describe 'status check methods' do
    it 'returns true for success status' do
      log_entry.status = 'success'
      expect(log_entry.success?).to be true
      expect(log_entry.failed?).to be false
      expect(log_entry.skipped?).to be false
      expect(log_entry.partial?).to be false
    end

    it 'returns true for failed status' do
      log_entry.status = 'failed'
      expect(log_entry.failed?).to be true
      expect(log_entry.success?).to be false
      expect(log_entry.skipped?).to be false
      expect(log_entry.partial?).to be false
    end

    it 'returns true for skipped status' do
      log_entry.status = 'skipped'
      expect(log_entry.skipped?).to be true
      expect(log_entry.success?).to be false
      expect(log_entry.failed?).to be false
      expect(log_entry.partial?).to be false
    end

    it 'returns true for partial status' do
      log_entry.status = 'partial'
      expect(log_entry.partial?).to be true
      expect(log_entry.success?).to be false
      expect(log_entry.failed?).to be false
      expect(log_entry.skipped?).to be false
    end
  end

  describe 'formatting methods' do
    describe '#size_reduction_mb' do
      it 'converts bytes to MB' do
        log_entry.bytes_saved = 1048576 # 1 MB
        expect(log_entry.size_reduction_mb).to eq(1.0)
      end

      it 'rounds to 2 decimal places' do
        log_entry.bytes_saved = 1572864 # 1.5 MB
        expect(log_entry.size_reduction_mb).to eq(1.5)
      end
    end

    describe '#processing_time_formatted' do
      it 'formats milliseconds for times under 1 second' do
        log_entry.processing_time = 0.5
        expect(log_entry.processing_time_formatted).to eq('500ms')
      end

      it 'formats seconds for times over 1 second' do
        log_entry.processing_time = 1.5
        expect(log_entry.processing_time_formatted).to eq('1.5s')
      end

      it 'rounds milliseconds to whole numbers' do
        log_entry.processing_time = 0.1234
        expect(log_entry.processing_time_formatted).to eq('123ms')
      end
    end
  end

  describe 'compression level info methods' do
    describe '#compression_level_name' do
      it 'returns formatted name for known levels' do
        log_entry.compression_level = 'lossy'
        expect(log_entry.compression_level_name).to eq('Lossy')
      end

      it 'capitalizes unknown levels' do
        log_entry.compression_level = 'custom'
        expect(log_entry.compression_level_name).to eq('Custom')
      end
    end

    describe '#compression_level_description' do
      it 'returns description for known levels' do
        log_entry.compression_level = 'lossy'
        expect(log_entry.compression_level_description).to eq('Balanced quality and compression')
      end

      it 'returns default for unknown levels' do
        log_entry.compression_level = 'unknown'
        expect(log_entry.compression_level_description).to eq('Custom settings')
      end
    end

    describe '#expected_savings' do
      it 'returns expected savings for known levels' do
        log_entry.compression_level = 'lossy'
        expect(log_entry.expected_savings).to eq('25-40%')
      end

      it 'returns default for unknown levels' do
        log_entry.compression_level = 'unknown'
        expect(log_entry.expected_savings).to eq('Variable')
      end
    end

    describe '#recommended_for' do
      it 'returns recommendation for known levels' do
        log_entry.compression_level = 'lossy'
        expect(log_entry.recommended_for).to eq('General web images, blog posts')
      end

      it 'returns default for unknown levels' do
        log_entry.compression_level = 'unknown'
        expect(log_entry.recommended_for).to eq('Advanced users')
      end
    end
  end

  describe '#api_response' do
    it 'returns complete API response hash' do
      response = log_entry.api_response
      
      expect(response).to include(:id, :filename, :content_type, :original_size, :optimized_size)
      expect(response).to include(:bytes_saved, :size_reduction_percentage, :size_reduction_mb)
      expect(response).to include(:compression_level, :compression_level_name, :quality)
      expect(response).to include(:processing_time, :processing_time_formatted, :status)
      expect(response).to include(:optimization_type, :variants_generated, :responsive_variants_generated)
      expect(response).to include(:error_message, :warnings, :user, :medium, :upload)
      expect(response).to include(:created_at, :updated_at)
    end

    it 'includes user information' do
      response = log_entry.api_response
      expect(response[:user]).to include(:id, :email)
    end

    it 'includes medium information' do
      response = log_entry.api_response
      expect(response[:medium]).to include(:id, :title)
    end

    it 'includes upload information' do
      response = log_entry.api_response
      expect(response[:upload]).to include(:id, :title)
    end
  end

  describe 'class methods for analytics' do
    let!(:log1) { create(:image_optimization_log, status: 'success', bytes_saved: 100000, tenant: tenant) }
    let!(:log2) { create(:image_optimization_log, status: 'success', bytes_saved: 200000, tenant: tenant) }
    let!(:log3) { create(:image_optimization_log, status: 'failed', bytes_saved: 0, tenant: tenant) }

    describe '.total_images_optimized' do
      it 'returns count of successful optimizations' do
        expect(ImageOptimizationLog.total_images_optimized).to eq(2)
      end
    end

    describe '.total_bytes_saved' do
      it 'returns sum of bytes saved' do
        expect(ImageOptimizationLog.total_bytes_saved).to eq(300000)
      end
    end

    describe '.average_size_reduction' do
      it 'returns average size reduction percentage' do
        log1.update!(size_reduction_percentage: 20.0)
        log2.update!(size_reduction_percentage: 30.0)
        
        expect(ImageOptimizationLog.average_size_reduction).to eq(25.0)
      end
    end

    describe '.average_processing_time' do
      it 'returns average processing time' do
        log1.update!(processing_time: 1.0)
        log2.update!(processing_time: 2.0)
        
        expect(ImageOptimizationLog.average_processing_time).to eq(1.5)
      end
    end

    describe '.compression_level_stats' do
      it 'returns stats grouped by compression level' do
        log1.update!(compression_level: 'lossy')
        log2.update!(compression_level: 'ultra')
        
        stats = ImageOptimizationLog.compression_level_stats
        expect(stats['lossy']).to eq(1)
        expect(stats['ultra']).to eq(1)
      end
    end

    describe '.optimization_type_stats' do
      it 'returns stats grouped by optimization type' do
        log1.update!(optimization_type: 'upload')
        log2.update!(optimization_type: 'bulk')
        
        stats = ImageOptimizationLog.optimization_type_stats
        expect(stats['upload']).to eq(1)
        expect(stats['bulk']).to eq(1)
      end
    end

    describe '.daily_stats' do
      it 'returns daily optimization counts' do
        stats = ImageOptimizationLog.daily_stats(30)
        expect(stats).to be_a(Hash)
      end
    end

    describe '.user_stats' do
      it 'returns stats grouped by user' do
        stats = ImageOptimizationLog.user_stats
        expect(stats).to be_a(Hash)
      end
    end

    describe '.tenant_stats' do
      it 'returns stats grouped by tenant' do
        stats = ImageOptimizationLog.tenant_stats
        expect(stats).to be_a(Hash)
      end
    end

    describe '.top_savings' do
      it 'returns logs ordered by bytes saved' do
        top_savings = ImageOptimizationLog.top_savings(10)
        expect(top_savings.first).to eq(log2)
        expect(top_savings.second).to eq(log1)
      end
    end

    describe '.failed_optimizations' do
      it 'returns only failed optimizations' do
        failed = ImageOptimizationLog.failed_optimizations(10)
        expect(failed).to include(log3)
        expect(failed).not_to include(log1, log2)
      end
    end

    describe '.generate_report' do
      it 'generates comprehensive report' do
        report = ImageOptimizationLog.generate_report
        
        expect(report).to include(:total_optimizations, :successful_optimizations, :failed_optimizations)
        expect(report).to include(:total_bytes_saved, :total_size_saved_mb, :average_size_reduction)
        expect(report).to include(:average_processing_time, :compression_level_breakdown)
        expect(report).to include(:optimization_type_breakdown, :daily_optimizations)
        expect(report).to include(:top_users, :top_tenants)
      end
    end

    describe '.export_to_csv' do
      it 'exports logs to CSV format' do
        csv_data = ImageOptimizationLog.export_to_csv
        expect(csv_data).to include('id,filename,content_type,original_size,optimized_size')
        expect(csv_data).to include(log1.id.to_s)
        expect(csv_data).to include(log2.id.to_s)
      end
    end
  end
end
