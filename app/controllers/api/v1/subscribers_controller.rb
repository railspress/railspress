module Api
  module V1
    class SubscribersController < BaseController
      skip_before_action :authenticate_api_user!, only: [:create, :unsubscribe, :confirm]
      before_action :set_subscriber, only: [:show, :update, :destroy]
      
      # GET /api/v1/subscribers
      def index
        unless current_api_user.can_edit_others_posts?
          return render_error('You do not have permission to view subscribers', :forbidden)
        end
        
        subscribers = Subscriber.all
        
        # Filter by status
        subscribers = subscribers.where(status: params[:status]) if params[:status].present?
        
        # Filter by source
        subscribers = subscribers.by_source(params[:source]) if params[:source].present?
        
        # Search
        subscribers = subscribers.search(params[:q]) if params[:q].present?
        
        # Paginate
        @subscribers = paginate(subscribers.recent)
        
        render_success(
          @subscribers.map { |s| subscriber_serializer(s) }
        )
      end
      
      # GET /api/v1/subscribers/:id
      def show
        unless current_api_user.can_edit_others_posts?
          return render_error('You do not have permission to view subscribers', :forbidden)
        end
        
        render_success(subscriber_serializer(@subscriber, detailed: true))
      end
      
      # POST /api/v1/subscribers
      # Public endpoint for newsletter signups
      def create
        @subscriber = Subscriber.new(subscriber_create_params)
        @subscriber.status = 'pending'
        @subscriber.source = params[:source] || 'api'
        @subscriber.ip_address = request.remote_ip
        @subscriber.user_agent = request.user_agent
        
        if @subscriber.save
          render_success(
            {
              message: 'Successfully subscribed! Please check your email to confirm.',
              subscriber: subscriber_serializer(@subscriber)
            },
            {},
            :created
          )
        else
          render_error(@subscriber.errors.full_messages.join(', '))
        end
      end
      
      # PATCH/PUT /api/v1/subscribers/:id
      def update
        unless current_api_user.administrator?
          return render_error('Only administrators can update subscribers', :forbidden)
        end
        
        if @subscriber.update(subscriber_update_params)
          render_success(subscriber_serializer(@subscriber))
        else
          render_error(@subscriber.errors.full_messages.join(', '))
        end
      end
      
      # DELETE /api/v1/subscribers/:id
      def destroy
        unless current_api_user.administrator?
          return render_error('Only administrators can delete subscribers', :forbidden)
        end
        
        @subscriber.destroy
        render_success({ message: 'Subscriber deleted successfully' })
      end
      
      # POST /api/v1/subscribers/unsubscribe
      # Public endpoint for unsubscribing
      def unsubscribe
        subscriber = Subscriber.find_by(unsubscribe_token: params[:token])
        
        unless subscriber
          return render_error('Invalid unsubscribe token', :not_found)
        end
        
        subscriber.unsubscribe!
        
        render_success({
          message: 'Successfully unsubscribed',
          email: subscriber.email
        })
      end
      
      # POST /api/v1/subscribers/confirm
      # Public endpoint for confirming subscription
      def confirm
        subscriber = Subscriber.find_by(unsubscribe_token: params[:token])
        
        unless subscriber
          return render_error('Invalid confirmation token', :not_found)
        end
        
        if subscriber.confirmed_status?
          return render_success({
            message: 'Already confirmed',
            email: subscriber.email
          })
        end
        
        subscriber.confirm!
        
        render_success({
          message: 'Email confirmed! You are now subscribed.',
          email: subscriber.email
        })
      end
      
      # GET /api/v1/subscribers/stats
      def stats
        unless current_api_user.can_edit_others_posts?
          return render_error('You do not have permission to view stats', :forbidden)
        end
        
        render_success(Subscriber.stats)
      end
      
      private
      
      def set_subscriber
        @subscriber = Subscriber.find(params[:id])
      end
      
      def subscriber_create_params
        params.require(:subscriber).permit(:email, :name)
      end
      
      def subscriber_update_params
        params.require(:subscriber).permit(:email, :name, :status, :source, tags: [], lists: [])
      end
      
      def subscriber_serializer(subscriber, detailed: false)
        data = {
          id: subscriber.id,
          email: subscriber.email,
          name: subscriber.name,
          status: subscriber.status,
          source: subscriber.source,
          tags: subscriber.tags || [],
          lists: subscriber.lists || [],
          created_at: subscriber.created_at.iso8601
        }
        
        if detailed
          data.merge!(
            confirmed_at: subscriber.confirmed_at&.iso8601,
            unsubscribed_at: subscriber.unsubscribed_at&.iso8601,
            ip_address: subscriber.ip_address,
            user_agent: subscriber.user_agent,
            metadata: subscriber.metadata
          )
        end
        
        data
      end
    end
  end
end








