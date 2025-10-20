class Admin::Consent::ConsentConfigurationsController < Admin::BaseController
  before_action :set_consent_configuration, only: [:show, :edit, :update, :destroy]

  # GET /admin/consent/configurations
  def index
    @consent_configs = ConsentConfiguration.includes(:tenant).ordered
    @consent_configs = @consent_configs.page(params[:page]).per(20)
  end

  # GET /admin/consent/configurations/1
  def show
  end

  # GET /admin/consent/configurations/new
  def new
    @consent_configuration = ConsentConfiguration.new
  end

  # GET /admin/consent/configurations/1/preview
  def preview
    @consent_configuration = ConsentConfiguration.find(params[:id])
    
    # Create a temporary configuration with updated settings for preview
    if params[:consent_configuration]
      # Start with the original configuration and modify it
      @preview_config = @consent_configuration.dup
      
      # Update banner settings with form data
      banner_settings = @consent_configuration.banner_settings_with_defaults.dup
      
      # Text settings
      banner_settings['text']['title'] = params[:consent_configuration][:banner_title] if params[:consent_configuration][:banner_title].present?
      banner_settings['text']['description'] = params[:consent_configuration][:banner_description] if params[:consent_configuration][:banner_description].present?
      banner_settings['text']['accept_all'] = params[:consent_configuration][:accept_all_text] if params[:consent_configuration][:accept_all_text].present?
      banner_settings['text']['reject_all'] = params[:consent_configuration][:reject_all_text] if params[:consent_configuration][:reject_all_text].present?
      
      # Color settings
      banner_settings['colors']['background'] = params[:consent_configuration][:banner_background_color] if params[:consent_configuration][:banner_background_color].present?
      banner_settings['colors']['text'] = params[:consent_configuration][:banner_text_color] if params[:consent_configuration][:banner_text_color].present?
      banner_settings['colors']['button_accept'] = params[:consent_configuration][:accept_button_bg_color] if params[:consent_configuration][:accept_button_bg_color].present?
      banner_settings['colors']['button_reject'] = params[:consent_configuration][:reject_button_bg_color] if params[:consent_configuration][:reject_button_bg_color].present?
      banner_settings['colors']['button_neutral'] = params[:consent_configuration][:neutral_button_bg_color] if params[:consent_configuration][:neutral_button_bg_color].present?
      
      # Apply the updated banner settings
      @preview_config.banner_settings = banner_settings
      
      # Also update other form fields if they exist
      @preview_config.name = params[:consent_configuration][:name] if params[:consent_configuration][:name].present?
      @preview_config.banner_type = params[:consent_configuration][:banner_type] if params[:consent_configuration][:banner_type].present?
      @preview_config.consent_mode = params[:consent_configuration][:consent_mode] if params[:consent_configuration][:consent_mode].present?
    else
      @preview_config = @consent_configuration
    end
    
    render layout: 'consent_preview'
  end

  # POST /admin/consent/configurations
  def create
    @consent_configuration = ConsentConfiguration.new(consent_configuration_params)

    if @consent_configuration.save
      redirect_to admin_consent_consent_configuration_path(@consent_configuration), notice: 'Consent configuration was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /admin/consent/configurations/1
  def update
    # Extract banner settings from form parameters
    banner_settings = @consent_configuration.banner_settings_with_defaults.dup
    
    # Update text settings
    if params[:consent_configuration][:banner_title].present?
      banner_settings['text']['title'] = params[:consent_configuration][:banner_title]
    end
    if params[:consent_configuration][:banner_description].present?
      banner_settings['text']['description'] = params[:consent_configuration][:banner_description]
    end
    if params[:consent_configuration][:accept_all_text].present?
      banner_settings['text']['accept_all'] = params[:consent_configuration][:accept_all_text]
    end
    if params[:consent_configuration][:reject_all_text].present?
      banner_settings['text']['reject_all'] = params[:consent_configuration][:reject_all_text]
    end
    
    # Update color settings
    if params[:consent_configuration][:banner_background_color].present?
      banner_settings['colors']['background'] = params[:consent_configuration][:banner_background_color]
    end
    if params[:consent_configuration][:banner_text_color].present?
      banner_settings['colors']['text'] = params[:consent_configuration][:banner_text_color]
    end
    if params[:consent_configuration][:accept_button_bg_color].present?
      banner_settings['colors']['button_accept'] = params[:consent_configuration][:accept_button_bg_color]
    end
    if params[:consent_configuration][:reject_button_bg_color].present?
      banner_settings['colors']['button_reject'] = params[:consent_configuration][:reject_button_bg_color]
    end
    if params[:consent_configuration][:neutral_button_bg_color].present?
      banner_settings['colors']['button_neutral'] = params[:consent_configuration][:neutral_button_bg_color]
    end
    
    # Update the model with only the allowed attributes
    update_params = consent_configuration_params.except(
      :banner_title, :banner_description, :accept_all_text, :reject_all_text,
      :banner_background_color, :banner_text_color, :accept_button_bg_color,
      :reject_button_bg_color, :neutral_button_bg_color, :modal_background_color, :modal_text_color
    )
    update_params[:banner_settings] = banner_settings
    
    if @consent_configuration.update(update_params)
      redirect_to edit_admin_consent_consent_configuration_path(@consent_configuration), notice: 'Consent configuration was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /admin/consent/configurations/1
  def destroy
    @consent_configuration.destroy
    redirect_to admin_consent_consent_configurations_path, notice: 'Consent configuration was successfully deleted.'
  end

  private

  def set_consent_configuration
    @consent_configuration = ConsentConfiguration.find(params[:id])
  end

  def consent_configuration_params
    params.require(:consent_configuration).permit(
      :name, :banner_type, :consent_mode, :active, :tenant_id,
      :consent_categories, :pixel_consent_mapping, :banner_settings, :geolocation_settings,
      # These are used for form processing but not stored as individual attributes
      :banner_title, :banner_description, :accept_all_text, :reject_all_text,
      :banner_background_color, :banner_text_color, :accept_button_bg_color, 
      :reject_button_bg_color, :neutral_button_bg_color, :modal_background_color, :modal_text_color
    )
  end
end
