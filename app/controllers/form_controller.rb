=begin
RailsCollab
-----------

=end

class FormController < ApplicationController

  layout 'project_website'
  
  verify :method => :post,
  		 :only => [ :delete ],
  		 :add_flash => { :flash_error => "Invalid request" },
         :redirect_to => { :controller => 'project' }

  before_filter :login_required
  before_filter :process_session
  before_filter :obtain_form, :except => [:index, :add]
  after_filter  :user_track, :only => [:index, :submit]
  
  def index
    if not ProjectForm.can_be_created_by(@logged_user, @active_project)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'form'
      return
    end
    
    if @logged_user.member_of_owner?
  		@forms = @active_project.project_forms
    else
  		@forms = @active_project.visible_forms
  	end
  end
  
  def submit
    if not @form.can_be_submitted_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'form'
      return
    end
    
    case request.method
      when :post
        form_attribs = params[:form]
        
        if @form.submit(form_attribs, @logged_user)
          ApplicationLog::new_log(@form, @logged_user, :add)
          flash[:flash_success] = @form.success_message
          redirect_back_or_default :controller => 'form'
        else
          flash[:flash_error] = "Error submitting form"
          redirect_back_or_default :controller => 'form'
        end
    end
    
    @visible_forms = @active_project.visible_forms
    @content_for_sidebar = 'submit_sidebar'
  end
  
  def add
    @form = ProjectForm.new
    
    if not ProjectForm.can_be_created_by(@logged_user, @active_project)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'time'
      return
    end
    
    case request.method
      when :post
        form_attribs = params[:form]
        form_object_attribs = params[:form_objects]
                
        @form.update_attributes(form_attribs)
        @form.update_attributes(form_object_attribs)
        
        @form.project = @active_project
        @form.created_by = @logged_user
        
        if @form.save
          ApplicationLog::new_log(@form, @logged_user, :add)
          flash[:flash_success] = "Successfully added form"
          redirect_back_or_default :controller => 'form'
        end
    end
  end
  
  def edit
    if not @form.can_be_edited_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'form'
      return
    end
    
    case request.method
      when :post
        form_attribs = params[:form]
        form_object_attribs = params[:form_objects]
        
        @form.update_attributes(form_attribs)
        @form.update_attributes(form_object_attribs)
        
        @form.project = @active_project
        @form.updated_by = @logged_user
        
        if @form.save
          ApplicationLog::new_log(@form, @logged_user, :edit)
          flash[:flash_success] = "Successfully edited form"
          redirect_back_or_default :controller => 'form'
        end
    end
  end
  
  def delete
    if not @form.can_be_deleted_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'form'
      return
    end
    
    ApplicationLog::new_log(@form, @logged_user, :delete)
    @form.destroy
    
    flash[:flash_success] = "Successfully deleted form"
    redirect_back_or_default :controller => 'form'
  end

private

  def obtain_form
    begin
      @form = ProjectForm.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:flash_error] = "Invalid form"
      redirect_back_or_default :controller => 'form'
      return false
    end
    
    return true
  end
end