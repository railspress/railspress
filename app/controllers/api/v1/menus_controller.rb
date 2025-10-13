module Api
  module V1
    class MenusController < BaseController
      skip_before_action :authenticate_api_user!, only: [:index, :show]
      before_action :set_menu, only: [:show, :update, :destroy]
      
      # GET /api/v1/menus
      def index
        menus = Menu.includes(:menu_items)
        
        # Filter by location
        menus = menus.by_location(params[:location]) if params[:location].present?
        
        @menus = paginate(menus)
        
        render_success(
          @menus.map { |menu| menu_serializer(menu) }
        )
      end
      
      # GET /api/v1/menus/:id
      def show
        render_success(menu_serializer(@menu, detailed: true))
      end
      
      # POST /api/v1/menus
      def create
        unless current_api_user.can_edit_others_posts?
          return render_error('You do not have permission to create menus', :forbidden)
        end
        
        @menu = Menu.new(menu_params)
        
        if @menu.save
          render_success(menu_serializer(@menu), {}, :created)
        else
          render_error(@menu.errors.full_messages.join(', '))
        end
      end
      
      # PATCH/PUT /api/v1/menus/:id
      def update
        unless current_api_user.can_edit_others_posts?
          return render_error('You do not have permission to edit menus', :forbidden)
        end
        
        if @menu.update(menu_params)
          render_success(menu_serializer(@menu))
        else
          render_error(@menu.errors.full_messages.join(', '))
        end
      end
      
      # DELETE /api/v1/menus/:id
      def destroy
        unless current_api_user.administrator?
          return render_error('Only administrators can delete menus', :forbidden)
        end
        
        @menu.destroy
        render_success({ message: 'Menu deleted successfully' })
      end
      
      private
      
      def set_menu
        @menu = Menu.find(params[:id])
      end
      
      def menu_params
        params.require(:menu).permit(:name, :location)
      end
      
      def menu_serializer(menu, detailed: false)
        data = {
          id: menu.id,
          name: menu.name,
          location: menu.location,
          items_count: menu.menu_items.count
        }
        
        if detailed
          data[:items] = serialize_menu_items(menu.root_items)
        end
        
        data
      end
      
      def serialize_menu_items(items)
        items.map do |item|
          {
            id: item.id,
            label: item.label,
            url: item.url,
            target: item.target,
            css_class: item.css_class,
            position: item.position,
            children: serialize_menu_items(item.children.ordered)
          }
        end
      end
    end
  end
end




