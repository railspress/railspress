# SlickForms Public Forms Controller
# Handles public form display and submission

class Plugins::SlickForms::FormsController < ApplicationController
  before_action :set_form, only: [:show, :embed]
  
  def show
    # Display public form
    render layout: 'application'
  end
  
  def embed
    # Display form for embedding in other sites
    render layout: false
  end
  
  private
  
  def set_form
    @form = get_form_by_id(params[:form_id])
    redirect_to root_path, alert: 'Form not found.' unless @form
  end
  
  def get_form_by_id(id)
    return nil unless table_exists?('slick_forms')
    result = ActiveRecord::Base.connection.execute(
      "SELECT * FROM slick_forms WHERE id = #{id} AND active = 1"
    ).first
    result&.symbolize_keys
  end
  
  def table_exists?(table_name)
    ActiveRecord::Base.connection.table_exists?(table_name)
  end
end


