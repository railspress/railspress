module Api
  module V1
    module DocsHelper
      def method_badge_class(method)
        case method.upcase
        when 'GET'
          'bg-blue-500/10 text-blue-400'
        when 'POST'
          'bg-green-500/10 text-green-400'
        when 'PATCH', 'PUT'
          'bg-yellow-500/10 text-yellow-400'
        when 'DELETE'
          'bg-red-500/10 text-red-400'
        else
          'bg-gray-500/10 text-gray-400'
        end
      end
    end
  end
end




