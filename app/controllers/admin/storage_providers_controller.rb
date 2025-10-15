class Admin::StorageProvidersController < Admin::BaseController
  before_action :set_storage_provider, only: %i[show edit update destroy toggle]

  # GET /admin/storage_providers
  def index
    @storage_providers = StorageProvider.ordered
  end

  # GET /admin/storage_providers/1
  def show
  end

  # GET /admin/storage_providers/new
  def new
    @storage_provider = StorageProvider.new
  end

  # GET /admin/storage_providers/1/edit
  def edit
  end

  # POST /admin/storage_providers
  def create
    @storage_provider = StorageProvider.new(storage_provider_params)

    respond_to do |format|
      if @storage_provider.save
        format.html { redirect_to admin_storage_providers_path, notice: "Storage provider was successfully created." }
        format.json { render :show, status: :created, location: @storage_provider }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @storage_provider.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/storage_providers/1
  def update
    respond_to do |format|
      if @storage_provider.update(storage_provider_params)
        format.html { redirect_to admin_storage_providers_path, notice: "Storage provider was successfully updated." }
        format.json { render :show, status: :ok, location: @storage_provider }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @storage_provider.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/storage_providers/1
  def destroy
    @storage_provider.destroy!

    respond_to do |format|
      format.html { redirect_to admin_storage_providers_path, notice: "Storage provider was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  # PATCH /admin/storage_providers/1/toggle
  def toggle
    @storage_provider.update!(active: !@storage_provider.active)
    
    respond_to do |format|
      format.html { redirect_to admin_storage_providers_path, notice: "Storage provider status updated." }
      format.json { render json: { active: @storage_provider.active } }
    end
  end

  private

  def set_storage_provider
    @storage_provider = StorageProvider.find(params[:id])
  end

  def storage_provider_params
    params.require(:storage_provider).permit(
      :name, 
      :provider_type, 
      :active, 
      :position,
      config: [
        :local_path,
        :access_key_id,
        :secret_access_key,
        :region,
        :bucket,
        :endpoint,
        :project,
        :credentials,
        :storage_account_name,
        :storage_access_key,
        :container
      ]
    )
  end
end

