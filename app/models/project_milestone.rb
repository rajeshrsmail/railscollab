=begin
RailsCollab
-----------

Copyright (C) 2007 James S Urquhart (jamesu at gmail.com)

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
=end

class ProjectMilestone < ActiveRecord::Base
	include ActionController::UrlWriter
	
	belongs_to :project
	
	belongs_to :company, :foreign_key => 'assigned_to_company_id'
	belongs_to :user, :foreign_key => 'assigned_to_user_id'

	belongs_to :completed_by, :class_name => 'User', :foreign_key => 'completed_by_id'
	
	belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
	belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
		
	has_many :project_task_lists, :foreign_key => 'milestone_id', :order => 'project_task_lists.order DESC', :dependent => :nullify
	has_many :project_messages, :foreign_key => 'milestone_id', :dependent => :nullify
	
	has_many :tags, :as => 'rel_object', :dependent => :destroy
	
	before_create :process_params
	before_update :process_update_params
	 
	def process_params
	  write_attribute("created_on", Time.now.utc)
	  write_attribute("completed_on", nil)
	  
	  if self.assigned_to_user_id.nil?
	   write_attribute("assigned_to_user_id", 0)
	  end
	  if self.assigned_to_company_id.nil?
	    write_attribute("assigned_to_company_id", 0)
	  end
	end
	
	def process_update_params
		write_attribute("updated_on", Time.now.utc)
		
		if self.assigned_to_user_id.nil?
	      write_attribute("assigned_to_user_id", 0)
	    end
	    if self.assigned_to_company_id.nil?
	      write_attribute("assigned_to_company_id", 0)
	    end
	end
	
	def object_name
		self.name
	end
	
	def object_url
		url_for :only_path => true, :controller => 'milestone', :action => 'view', :id => self.id, :active_project => self.project_id
	end
	
	def tags
	 return Tag.list_by_object(self).join(',')
	end
	
	def tags=(val)
	 Tag.clear_by_object(self)
	 Tag.set_to_object(self, val.split(',')) unless val.nil?
	end
	
	def assigned_to=(obj)
		self.company = obj.class == Company ? obj : nil
		self.user = obj.class == User ? obj : nil
	end
	
	def assigned_to
		if self.company
			self.company
		elsif self.user
			self.user
		else
			nil
		end
	end
	
	def assigned_to_id=(val)
        # Set assigned_to accordingly
        assign_id = val.to_i
        if assign_id == 0
        	self.assigned_to = nil
        elsif assign_id > 1000
          self.assigned_to = User.find(assign_id-1000)
        else
          self.assigned_to = Company.find(assign_id)
        end
	end
	
	def assigned_to_id
		if self.company
			self.company.id
		elsif self.user
			self.user.id+1000
		else
			0
		end
	end
	
	def is_upcomming?
		return self.due_date.to_date > (Date.today+1)
	end
	
	def is_late?
		return self.due_date.to_date < Date.today
	end
	
	def is_today?
		return self.due_date.to_date == Date.today
	end
	
	def is_completed?
	 return (self.completed_on != nil)
	end
	
	def days_left
		return (self.due_date.to_date-Date.today).to_i
	end
	
	def days_late
		return (Date.today-self.due_date.to_date).to_i
	end
	
	def send_comment_notifications(comment)
	end
	
	# Core Permissions
	
	def self.can_be_created_by(user, project)
	  user.has_permission(project, :can_manage_messages)
	end
	
	def can_be_edited_by(user)
	 if (!self.project.has_member(user))
	   return false
	 end
	 
	 if user.has_permission(project, :can_manage_milestones)
	   return true
	 end
	 
	 if self.created_by == user
	   return true
	 end
	 
	 return false
	end
	
	def can_be_deleted_by(user)
	 if !self.project.has_member(user)
	   return false
	 end
	 
	 if user.has_permission(project, :can_manage_milestones)
	   return true
	 end
	 
	 return false
	end
	
	def can_be_seen_by(user)
	 if !self.project.has_member(user)
	   return false
	 end
	 
	 if user.has_permission(project, :can_manage_milestones)
	   return true
	 end
	 
	 if self.is_private and !user.member_of_owner?
	   return false
	 end
	 
	 return true
	end
	
	# Specific Permissions

    def can_be_managed_by(user)
      return user.has_permission(self.project, :can_manage_milestones)
    end
    
    def status_can_be_changed_by(user)
	 if self.can_be_edited_by(user)
	   return true
	 end
	 
	 if (!self.assigned_to.nil?) and (self.assigned_to == user or self.assigned_to == user.company)
	   return true
	 end
	 
	 return false
    end
    
    def comment_can_be_added_by(user)
	 return self.project.has_member(user)
    end
	
	# Helpers
	
	def self.all_by_user(user)
		projects = user.active_projects
		
		project_ids = projects.collect do |p|
			p.id
		end.join ','
		
		if project_ids.length == 0
			return []
		end
		
		return self.find(:all, :conditions => "completed_on IS NULL AND project_id IN (#{project_ids})")
	end
	
	def self.todays_by_user(user)
		from_date = Date.today
		to_date = Date.today+1
		
		projects = user.active_projects
		
		project_ids = projects.collect do |p|
			p.id
		end.join ','
		
		if project_ids.length == 0
			return []
		end
		
		return self.find(:all, :conditions => "completed_on IS NULL AND (due_date >= '#{from_date}' AND due_date < '#{to_date}') AND project_id IN (#{project_ids})")
	end
	
	def self.late_by_user(user)
		due_date = Date.today
      
		projects = user.active_projects
		
		project_ids = projects.collect do |p|
			p.id
		end.join ','
		
		if project_ids.length == 0
			return []
		end
		
		self.find(:all, :conditions => "due_date < '#{due_date}' AND completed_on IS NULL AND project_id IN (#{project_ids})")
	end
	
	def self.select_list(project)
	 items = ProjectMilestone.find(:all, :conditions => "project_id = #{project.id}").collect do |milestone|
	   [milestone.name, milestone.id]
	 end
	 
	 return [["-- None --", 0]] + items
	end
	
	# Accesibility
	
	attr_accessible :name, :description, :due_date, :assigned_to_id
	
	# Validation
	
	validates_presence_of :name
end