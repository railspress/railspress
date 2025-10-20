require 'rails_helper'

RSpec.describe OptimizeImageJob, type: :job do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:upload) { create(:upload, user: user, tenant: tenant) }
  let(:medium) { create(:medium, user: user, tenant: tenant, upload: upload) }

  before do
    # Mock file attachment
    allow(upload).to receive(:file).and_return(double(attached?: true))
    allow(medium).to receive(:image?).and_return(true)
  end

  describe '#perform' do
    let(:job) { OptimizeImageJob.new }

    context 'when medium exists and is valid' do
      before do
        allow(Medium).to receive(:find_by).with(id: medium.id).and_return(medium)
        allow(ImageOptimizationService).to receive(:new).and_return(double(optimize!: true))
      end

      it 'processes the optimization successfully' do
        expect(ImageOptimizationService).to receive(:new).with(
          medium,
          optimization_type: 'upload',
          request_context: {}
        )

        job.perform(medium_id: medium.id)
      end

      it 'logs the start of optimization' do
        allow(Rails.logger).to receive(:info)
        
        job.perform(medium_id: medium.id)
        
        expect(Rails.logger).to have_received(:info).with("Starting image optimization for medium #{medium.id}")
      end

      it 'logs successful completion' do
        allow(Rails.logger).to receive(:info)
        optimization_service = double('ImageOptimizationService')
        allow(ImageOptimizationService).to receive(:new).and_return(optimization_service)
        allow(optimization_service).to receive(:optimize!).and_return(true)
        
        job.perform(medium_id: medium.id)
        
        expect(Rails.logger).to have_received(:info).with("Main image optimization completed for medium #{medium.id}")
        expect(Rails.logger).to have_received(:info).with("Image optimization process completed for medium #{medium.id}")
      end

      it 'logs skipped optimization' do
        allow(Rails.logger).to receive(:info)
        optimization_service = double('ImageOptimizationService')
        allow(ImageOptimizationService).to receive(:new).and_return(optimization_service)
        allow(optimization_service).to receive(:optimize!).and_return(false)
        
        job.perform(medium_id: medium.id)
        
        expect(Rails.logger).to have_received(:info).with("Main image optimization skipped for medium #{medium.id}")
        expect(Rails.logger).to have_received(:info).with("Image optimization process completed for medium #{medium.id}")
      end

      it 'passes optimization_type parameter' do
        optimization_service = double('ImageOptimizationService')
        allow(ImageOptimizationService).to receive(:new).and_return(optimization_service)
        allow(optimization_service).to receive(:optimize!).and_return(true)
        
        job.perform(medium_id: medium.id, optimization_type: 'bulk')
        
        expect(ImageOptimizationService).to have_received(:new).with(
          medium,
          optimization_type: 'bulk',
          request_context: {}
        )
      end

      it 'passes request_context parameter' do
        optimization_service = double('ImageOptimizationService')
        allow(ImageOptimizationService).to receive(:new).and_return(optimization_service)
        allow(optimization_service).to receive(:optimize!).and_return(true)
        
        request_context = { user_agent: 'Test Agent', ip_address: '127.0.0.1' }
        
        job.perform(medium_id: medium.id, request_context: request_context)
        
        expect(ImageOptimizationService).to have_received(:new).with(
          medium,
          optimization_type: 'upload',
          request_context: request_context
        )
      end
    end

    context 'when medium does not exist' do
      before do
        allow(Medium).to receive(:find_by).with(id: 999).and_return(nil)
      end

      it 'returns early without processing' do
        expect(ImageOptimizationService).not_to receive(:new)
        
        job.perform(medium_id: 999)
      end
    end

    context 'when medium has no upload' do
      before do
        allow(Medium).to receive(:find_by).with(id: medium.id).and_return(medium)
        allow(medium).to receive(:upload).and_return(nil)
      end

      it 'returns early without processing' do
        expect(ImageOptimizationService).not_to receive(:new)
        
        job.perform(medium_id: medium.id)
      end
    end

    context 'when upload has no file attached' do
      before do
        allow(Medium).to receive(:find_by).with(id: medium.id).and_return(medium)
        allow(medium).to receive(:upload).and_return(upload)
        allow(upload).to receive(:file).and_return(double(attached?: false))
      end

      it 'returns early without processing' do
        expect(ImageOptimizationService).not_to receive(:new)
        
        job.perform(medium_id: medium.id)
      end
    end

    context 'when medium is not an image' do
      before do
        allow(Medium).to receive(:find_by).with(id: medium.id).and_return(medium)
        allow(medium).to receive(:upload).and_return(upload)
        allow(upload).to receive(:file).and_return(double(attached?: true))
        allow(medium).to receive(:image?).and_return(false)
      end

      it 'returns early without processing' do
        expect(ImageOptimizationService).not_to receive(:new)
        
        job.perform(medium_id: medium.id)
      end
    end

    context 'when optimization service raises an error' do
      before do
        allow(Medium).to receive(:find_by).with(id: medium.id).and_return(medium)
        allow(medium).to receive(:upload).and_return(upload)
        allow(upload).to receive(:file).and_return(double(attached?: true))
        allow(medium).to receive(:image?).and_return(true)
        allow(ImageOptimizationService).to receive(:new).and_raise(StandardError.new('Service error'))
      end

      it 'logs the error and continues' do
        allow(Rails.logger).to receive(:error)
        
        job.perform(medium_id: medium.id)
        
        expect(Rails.logger).to have_received(:error).with("Image optimization failed for medium #{medium.id}: Service error")
      end

      it 'logs the backtrace' do
        allow(Rails.logger).to receive(:error)
        error = StandardError.new('Service error')
        error.set_backtrace(['line1', 'line2'])
        allow(ImageOptimizationService).to receive(:new).and_raise(error)
        
        job.perform(medium_id: medium.id)
        
        expect(Rails.logger).to have_received(:error).with("line1\nline2")
      end
    end
  end

  describe 'job configuration' do
    it 'uses the default queue' do
      expect(OptimizeImageJob.queue_name).to eq('default')
    end

    it 'is a subclass of ApplicationJob' do
      expect(OptimizeImageJob.superclass).to eq(ApplicationJob)
    end
  end

  describe 'integration with ImageOptimizationService' do
    let(:optimization_service) { double('ImageOptimizationService') }

    before do
      allow(Medium).to receive(:find_by).with(id: medium.id).and_return(medium)
      allow(medium).to receive(:upload).and_return(upload)
      allow(upload).to receive(:file).and_return(double(attached?: true))
      allow(medium).to receive(:image?).and_return(true)
      allow(ImageOptimizationService).to receive(:new).and_return(optimization_service)
    end

    it 'calls optimize! on the service' do
      expect(optimization_service).to receive(:optimize!).and_return(true)
      
      OptimizeImageJob.perform_now(medium_id: medium.id)
    end

    it 'handles service returning false' do
      allow(optimization_service).to receive(:optimize!).and_return(false)
      allow(Rails.logger).to receive(:info)
      
      OptimizeImageJob.perform_now(medium_id: medium.id)
      
      expect(Rails.logger).to have_received(:info).with("Main image optimization skipped for medium #{medium.id}")
    end

    it 'handles service returning true' do
      allow(optimization_service).to receive(:optimize!).and_return(true)
      allow(Rails.logger).to receive(:info)
      
      OptimizeImageJob.perform_now(medium_id: medium.id)
      
      expect(Rails.logger).to have_received(:info).with("Main image optimization completed for medium #{medium.id}")
    end
  end

  describe 'parameter validation' do
    it 'requires medium_id parameter' do
      expect { OptimizeImageJob.new.perform }.to raise_error(ArgumentError)
    end

    it 'accepts optional optimization_type parameter' do
      allow(Medium).to receive(:find_by).with(id: medium.id).and_return(nil)
      
      expect { OptimizeImageJob.new.perform(medium_id: medium.id, optimization_type: 'bulk') }.not_to raise_error
    end

    it 'accepts optional request_context parameter' do
      allow(Medium).to receive(:find_by).with(id: medium.id).and_return(nil)
      
      expect { OptimizeImageJob.new.perform(medium_id: medium.id, request_context: {}) }.not_to raise_error
    end
  end

  describe 'background job behavior' do
    it 'can be enqueued' do
      expect { OptimizeImageJob.perform_later(medium_id: medium.id) }.not_to raise_error
    end

    it 'can be performed immediately' do
      allow(Medium).to receive(:find_by).with(id: medium.id).and_return(nil)
      
      expect { OptimizeImageJob.perform_now(medium_id: medium.id) }.not_to raise_error
    end
  end
end
