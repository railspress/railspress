# SlickForms Admin Controller
# Handles form management in the admin panel

class Admin::SlickForms::FormsController < Admin::BaseController
  before_action :set_form, only: [:show, :edit, :update, :destroy, :duplicate, :preview]
  
  def index
    @forms = get_all_forms
    @stats = {
      total_forms: @forms.size,
      total_submissions: get_submission_count,
      active_forms: @forms.count { |f| f[:active] }
    }
  end
  
  def show
    @submissions = get_form_submissions(@form[:id])
    @stats = {
      total_submissions: @submissions.size,
      today_submissions: get_today_submissions(@form[:id]),
      conversion_rate: calculate_conversion_rate(@form[:id])
    }
  end
  
  def new
    @form = {
      name: '',
      title: '',
      description: '',
      fields: [],
      settings: {},
      active: true
    }
  end
  
  def create
    form_data = form_params
    
    # Create form record
    form_id = create_form_record(form_data)
    
    if form_id
      redirect_to admin_slick_forms_form_path(form_id), notice: 'Form was successfully created.'
    else
      render :new, alert: 'Failed to create form.'
    end
  end
  
  def edit
    # Form data is already loaded in set_form
  end
  
  def update
    if update_form_record(@form[:id], form_params)
      redirect_to admin_slick_forms_form_path(@form[:id]), notice: 'Form was successfully updated.'
    else
      render :edit, alert: 'Failed to update form.'
    end
  end
  
  def destroy
    if delete_form_record(@form[:id])
      redirect_to admin_slick_forms_forms_path, notice: 'Form was successfully deleted.'
    else
      redirect_to admin_slick_forms_forms_path, alert: 'Failed to delete form.'
    end
  end
  
  def duplicate
    new_form_id = duplicate_form_record(@form[:id])
    if new_form_id
      redirect_to admin_slick_forms_form_path(new_form_id), notice: 'Form was successfully duplicated.'
    else
      redirect_to admin_slick_forms_forms_path, alert: 'Failed to duplicate form.'
    end
  end
  
  def preview
    # Render form preview
    render layout: 'admin'
  end
  
  def import
    # Handle form import
    redirect_to admin_slick_forms_forms_path, notice: 'Form import feature coming soon.'
  end
  
  private
  
  def set_form
    @form = get_form_by_id(params[:id])
    redirect_to admin_slick_forms_forms_path, alert: 'Form not found.' unless @form
  end
  
  def form_params
    params.require(:form).permit(:name, :title, :description, :active, fields: [], settings: {})
  end
  
  # Private helper methods using ActiveRecord models
  def get_all_forms
    SlickForm.accessible_by(current_tenant).order(created_at: :desc)
  end
  
  def get_form_by_id(id)
    SlickForm.accessible_by(current_tenant).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    nil
  end
  
  def create_form_record(data)
    form = SlickForm.new(data)
    form.tenant = current_tenant if respond_to?(:current_tenant)
    form.save ? form.id : nil
  end
  
  def update_form_record(id, data)
    form = SlickForm.accessible_by(current_tenant).find(id)
    form.update(data)
  rescue ActiveRecord::RecordNotFound
    false
  end
  
  def delete_form_record(id)
    form = SlickForm.accessible_by(current_tenant).find(id)
    form.destroy
    true
  rescue ActiveRecord::RecordNotFound
    false
  end
  
  def duplicate_form_record(id)
    form = SlickForm.accessible_by(current_tenant).find(id)
    new_form = form.dup
    new_form.name = "#{form.name} (Copy)"
    new_form.title = "#{form.title} (Copy)"
    new_form.submissions_count = 0
    new_form.save ? new_form.id : nil
  rescue ActiveRecord::RecordNotFound
    nil
  end
  
  def get_form_submissions(form_id)
    SlickFormSubmission.where(slick_form_id: form_id)
                       .accessible_by(current_tenant)
                       .recent
  end
  
  def get_submission_count
    SlickFormSubmission.accessible_by(current_tenant).ham.count
  end
  
  def get_today_submissions(form_id)
    SlickFormSubmission.where(slick_form_id: form_id)
                       .accessible_by(current_tenant)
                       .ham
                       .where('DATE(created_at) = ?', Date.today)
                       .count
  end
  
  def calculate_conversion_rate(form_id)
    # This would calculate form views vs submissions
    # For now, return a placeholder
    0.0
  end
end
