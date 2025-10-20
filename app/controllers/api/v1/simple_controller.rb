module Api
  module V1
    class SimpleController < BaseController
      def index
        render json: { message: "Hello World", success: true }
      end
    end
  end
end

