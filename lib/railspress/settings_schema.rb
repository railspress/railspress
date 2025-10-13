# frozen_string_literal: true

module Railspress
  class SettingsSchema
    attr_reader :sections, :plugin_name
    
    def initialize(plugin_name)
      @plugin_name = plugin_name
      @sections = []
    end
    
    # Define a settings section
    def section(title, **options, &block)
      section = Section.new(title, options)
      section.instance_eval(&block) if block_given?
      @sections << section
      section
    end
    
    # Get all fields from all sections
    def all_fields
      @sections.flat_map(&:fields)
    end
    
    # Get field by key
    def find_field(key)
      all_fields.find { |f| f.key == key.to_s }
    end
    
    # Validate settings hash
    def validate(settings)
      errors = {}
      
      all_fields.each do |field|
        value = settings[field.key]
        field_errors = field.validate(value)
        errors[field.key] = field_errors if field_errors.any?
      end
      
      errors
    end
    
    # Section class
    class Section
      attr_reader :title, :description, :fields
      
      def initialize(title, options = {})
        @title = title
        @description = options[:description]
        @fields = []
      end
      
      # Field types
      def text(key, label, **options)
        add_field(TextField.new(key, label, options))
      end
      
      def textarea(key, label, **options)
        add_field(TextareaField.new(key, label, options))
      end
      
      def number(key, label, **options)
        add_field(NumberField.new(key, label, options))
      end
      
      def checkbox(key, label, **options)
        add_field(CheckboxField.new(key, label, options))
      end
      
      def select(key, label, choices, **options)
        add_field(SelectField.new(key, label, choices, options))
      end
      
      def radio(key, label, choices, **options)
        add_field(RadioField.new(key, label, choices, options))
      end
      
      def email(key, label, **options)
        add_field(EmailField.new(key, label, options))
      end
      
      def url(key, label, **options)
        add_field(UrlField.new(key, label, options))
      end
      
      def color(key, label, **options)
        add_field(ColorField.new(key, label, options))
      end
      
      def file(key, label, **options)
        add_field(FileField.new(key, label, options))
      end
      
      def wysiwyg(key, label, **options)
        add_field(WysiwygField.new(key, label, options))
      end
      
      def code(key, label, **options)
        add_field(CodeField.new(key, label, options))
      end
      
      def custom(key, label, **options, &block)
        add_field(CustomField.new(key, label, options, &block))
      end
      
      private
      
      def add_field(field)
        @fields << field
        field
      end
    end
    
    # Base field class
    class BaseField
      attr_reader :key, :label, :options
      
      def initialize(key, label, options = {})
        @key = key.to_s
        @label = label
        @options = options
      end
      
      def required?
        @options[:required] == true
      end
      
      def default
        @options[:default]
      end
      
      def description
        @options[:description]
      end
      
      def placeholder
        @options[:placeholder]
      end
      
      def validate(value)
        errors = []
        
        if required? && value.blank?
          errors << "#{label} is required"
        end
        
        if @options[:min] && value.to_i < @options[:min]
          errors << "#{label} must be at least #{@options[:min]}"
        end
        
        if @options[:max] && value.to_i > @options[:max]
          errors << "#{label} must be at most #{@options[:max]}"
        end
        
        if @options[:pattern] && value.present? && !value.match?(@options[:pattern])
          errors << "#{label} format is invalid"
        end
        
        errors
      end
      
      def input_type
        'text'
      end
      
      def render_options
        {
          type: input_type,
          required: required?,
          placeholder: placeholder,
          description: description
        }.compact
      end
    end
    
    # Specific field types
    class TextField < BaseField
      def input_type; 'text'; end
    end
    
    class TextareaField < BaseField
      def input_type; 'textarea'; end
      def rows; @options[:rows] || 4; end
    end
    
    class NumberField < BaseField
      def input_type; 'number'; end
      def min; @options[:min]; end
      def max; @options[:max]; end
      def step; @options[:step] || 1; end
    end
    
    class CheckboxField < BaseField
      def input_type; 'checkbox'; end
    end
    
    class SelectField < BaseField
      attr_reader :choices
      
      def initialize(key, label, choices, options = {})
        super(key, label, options)
        @choices = choices
      end
      
      def input_type; 'select'; end
    end
    
    class RadioField < BaseField
      attr_reader :choices
      
      def initialize(key, label, choices, options = {})
        super(key, label, options)
        @choices = choices
      end
      
      def input_type; 'radio'; end
    end
    
    class EmailField < BaseField
      def input_type; 'email'; end
    end
    
    class UrlField < BaseField
      def input_type; 'url'; end
    end
    
    class ColorField < BaseField
      def input_type; 'color'; end
    end
    
    class FileField < BaseField
      def input_type; 'file'; end
      def accept; @options[:accept]; end
    end
    
    class WysiwygField < BaseField
      def input_type; 'wysiwyg'; end
      def editor; @options[:editor] || 'trix'; end
    end
    
    class CodeField < BaseField
      def input_type; 'code'; end
      def language; @options[:language] || 'plaintext'; end
    end
    
    class CustomField < BaseField
      def initialize(key, label, options = {}, &block)
        super(key, label, options)
        @render_block = block
      end
      
      def input_type; 'custom'; end
      
      def render(form_builder, value)
        @render_block.call(form_builder, value) if @render_block
      end
    end
  end
end






