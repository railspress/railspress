class Admin::ChannelsController < Admin::BaseController
  before_action :set_channel, only: [:show, :edit, :update, :destroy]
  
  def index
    @channels = Channel.all.order(:name)
  end
  
  def show
    @overrides = @channel.channel_overrides.includes(:resource).order(:resource_type, :path)
    @overrides_by_type = @overrides.group_by(&:resource_type)
  end
  
  def new
    @channel = Channel.new
  end
  
  def create
    @channel = Channel.new(channel_params)
    
    if @channel.save
      redirect_to admin_channel_path(@channel), notice: 'Channel was successfully created.'
    else
      render :new
    end
  end
  
  def edit
  end
  
  def update
    if @channel.update(channel_params)
      redirect_to admin_channel_path(@channel), notice: 'Channel was successfully updated.'
    else
      render :edit
    end
  end
  
  def destroy
    @channel.destroy
    redirect_to admin_channels_path, notice: 'Channel was successfully deleted.'
  end
  
  private
  
  def set_channel
    @channel = Channel.find(params[:id])
  end
  
  def channel_params
    params.require(:channel).permit(:name, :slug, :domain, :locale, metadata: {}, settings: {})
  end
end

