module Railspress
  class ThemeLoader
    class << self
      attr_accessor :current_theme, :themes_path

      def initialize_loader
        @themes_path = Rails.root.join('app', 'themes')
        @current_theme = nil
        load_active_theme
      end

      # Load the active theme from database
      def load_active_theme
        # Skip loading theme if database tables don't exist yet (e.g., during migrations)
        return unless ActiveRecord::Base.connection.table_exists?('themes')
        
        active_theme = Theme.active.first
        if active_theme
          @current_theme = active_theme.name.underscore
          setup_theme_paths
          load_theme_initializer
        end
      end

      # Set up view paths for theme templates
      def setup_theme_paths
        return unless @current_theme

        theme_views_path = Rails.root.join('app', 'themes', @current_theme, 'views')
        
        if Dir.exist?(theme_views_path)
          # Get current paths and add theme path at the beginning
          controller_paths = ActionController::Base.view_paths.paths.dup
          mailer_paths = ActionMailer::Base.view_paths.paths.dup
          
          # Remove any existing theme paths first
          controller_paths.reject! { |path| path.to_s.include?('app/themes') }
          mailer_paths.reject! { |path| path.to_s.include?('app/themes') }
          
          # Add new theme path at the beginning
          theme_resolver = ActionView::FileSystemResolver.new(theme_views_path.to_s)
          controller_paths.unshift(theme_resolver)
          mailer_paths.unshift(theme_resolver)
          
          # Set the new paths
          ActionController::Base.view_paths = ActionView::PathSet.new(controller_paths)
          ActionMailer::Base.view_paths = ActionView::PathSet.new(mailer_paths)
        end
      end

      # Load theme's initializer if exists
      def load_theme_initializer
        return unless @current_theme

        initializer_path = Rails.root.join('app', 'themes', @current_theme, 'theme.rb')
        
        if File.exist?(initializer_path)
          load initializer_path
          Rails.logger.info "Loaded theme initializer: #{@current_theme}"
        end
      end

      # Get theme configuration from PublishedThemeVersion
      def theme_config
        return {} unless @current_theme

        # First try to get from PublishedThemeVersion
        active_theme = Theme.active.first
        if active_theme
          published_version = PublishedThemeVersion.for_theme(active_theme.name).latest.first
          if published_version
            config_file = published_version.published_theme_files.find_by(file_path: 'config/theme.json')
            if config_file
              return JSON.parse(config_file.content)
            end
          end
        end

        # Fallback to filesystem
        config_path = Rails.root.join('app', 'themes', @current_theme, 'config', 'theme.json')
        
        if File.exist?(config_path)
          JSON.parse(File.read(config_path))
        else
          {}
        end
      end

      # Get all available themes
      def available_themes
        return [] unless Dir.exist?(@themes_path)

        Dir.glob(@themes_path.join('*')).select { |f| File.directory?(f) }.map do |theme_dir|
          theme_name = File.basename(theme_dir)
          config_path = File.join(theme_dir, 'config', 'theme.json')
          
          if File.exist?(config_path)
            config = JSON.parse(File.read(config_path))
            {
              name: theme_name,
              display_name: config['name'] || theme_name.titleize,
              version: config['version'] || '1.0.0',
              author: config['author'] || 'Unknown',
              description: config['description'] || 'No description',
              screenshot: config['screenshot'] || nil,
              path: theme_dir
            }
          else
            {
              name: theme_name,
              display_name: theme_name.titleize,
              version: '1.0.0',
              author: 'Unknown',
              description: 'No description',
              screenshot: nil,
              path: theme_dir
            }
          end
        end
      end

      # Activate a theme
      def activate_theme(theme_name)
        theme_path = @themes_path.join(theme_name)
        
        unless Dir.exist?(theme_path)
          Rails.logger.error "Theme not found: #{theme_name}"
          return false
        end

        # Update database
        Theme.where.not(name: theme_name.camelize).update_all(active: false)
        theme_record = Theme.find_or_create_by(name: theme_name.camelize) do |t|
          config_path = theme_path.join('config', 'theme.json')
          config = File.exist?(config_path) ? JSON.parse(File.read(config_path)) : {}
          t.description = config['description'] || 'No description'
          t.author = config['author'] || 'Unknown'
          t.version = config['version'] || '1.0.0'
        end
        theme_record.update(active: true)

        # Clear old theme paths
        clear_theme_paths

        # Reload theme
        @current_theme = theme_name
        setup_theme_paths
        load_theme_initializer

        # Clear view cache
        ActionView::LookupContext::DetailsKey.clear
        
        # Clear Rails cache
        Rails.cache.clear if Rails.cache.respond_to?(:clear)

        Rails.logger.info "Activated theme: #{theme_name}"
        true
      end
      
      # Clear theme-specific view paths
      def clear_theme_paths
        # Remove old theme view paths
        if @current_theme
          old_theme_views = Rails.root.join('app', 'themes', @current_theme, 'views')
          
          # Create new view paths without theme paths (since the array might be frozen)
          controller_paths = ActionController::Base.view_paths.paths.reject { |path| path.to_s.include?('app/themes') }
          mailer_paths = ActionMailer::Base.view_paths.paths.reject { |path| path.to_s.include?('app/themes') }
          
          # Set the new paths
          ActionController::Base.view_paths = ActionView::PathSet.new(controller_paths)
          ActionMailer::Base.view_paths = ActionView::PathSet.new(mailer_paths)
        end
      end

      # Get theme asset path
      def theme_asset_path(asset_type)
        return nil unless @current_theme

        Rails.root.join('app', 'themes', @current_theme, 'assets', asset_type)
      end

      # Get theme stylesheet
      def theme_stylesheet
        return nil unless @current_theme

        stylesheet_path = theme_asset_path('stylesheets')
        return nil unless stylesheet_path && Dir.exist?(stylesheet_path)

        # Look for main stylesheet
        main_css = Dir.glob(stylesheet_path.join('*.css')).first
        main_css ? File.basename(main_css, '.css') : nil
      end

      # Get theme javascript
      def theme_javascript
        return nil unless @current_theme

        js_path = theme_asset_path('javascripts')
        return nil unless js_path && Dir.exist?(js_path)

        # Look for main javascript
        main_js = Dir.glob(js_path.join('*.js')).first
        main_js ? File.basename(main_js, '.js') : nil
      end

      # Check if template exists in theme
      def template_exists?(template_path)
        return false unless @current_theme

        full_path = Rails.root.join('app', 'themes', @current_theme, 'views', "#{template_path}.html.erb")
        File.exist?(full_path)
      end

      # Get theme helper modules
      def theme_helpers
        return [] unless @current_theme

        helpers_path = Rails.root.join('app', 'themes', @current_theme, 'helpers')
        return [] unless Dir.exist?(helpers_path)

        Dir.glob(helpers_path.join('*.rb')).map do |helper_file|
          require helper_file
          File.basename(helper_file, '.rb').camelize.constantize
        end
      end

      private

      def load_theme_config(theme_name)
        config_path = @themes_path.join(theme_name, 'config.yml')
        File.exist?(config_path) ? YAML.load_file(config_path) : {}
      end
    end
  end
end

