class SubscribersController < ApplicationController
  skip_before_action :authenticate_user!, only: [:create, :unsubscribe, :confirm]
  
  # POST /subscribe
  def create
    @subscriber = Subscriber.new(subscriber_params)
    @subscriber.status = 'pending'
    @subscriber.source = params[:source] || 'website'
    @subscriber.ip_address = request.remote_ip
    @subscriber.user_agent = request.user_agent
    
    if @subscriber.save
      respond_to do |format|
        format.html do
          redirect_back fallback_location: root_path, notice: 'Successfully subscribed! Please check your email to confirm.'
        end
        format.json do
          render json: { success: true, message: 'Successfully subscribed' }, status: :created
        end
      end
    else
      respond_to do |format|
        format.html do
          redirect_back fallback_location: root_path, alert: @subscriber.errors.full_messages.join(', ')
        end
        format.json do
          render json: { success: false, errors: @subscriber.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end
  
  # GET /unsubscribe/:token
  def unsubscribe
    @subscriber = Subscriber.find_by(unsubscribe_token: params[:token])
    
    unless @subscriber
      redirect_to root_path, alert: 'Invalid unsubscribe link'
      return
    end
    
    @subscriber.unsubscribe!
    
    render :unsubscribe
  end
  
  # GET /confirm/:token
  def confirm
    @subscriber = Subscriber.find_by(unsubscribe_token: params[:token])
    
    unless @subscriber
      redirect_to root_path, alert: 'Invalid confirmation link'
      return
    end
    
    if @subscriber.confirmed_status?
      @already_confirmed = true
    else
      @subscriber.confirm!
    end
    
    render :confirm
  end
  
  private
  
  def subscriber_params
    params.require(:subscriber).permit(:email, :name)
  end
end





