=begin
RailsCollab
-----------

=end

class Tag < ActiveRecord::Base
	belongs_to :project
	belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
	
	belongs_to :rel_object, :polymorphic => true
	
	before_create :process_params
	 
	def process_params
	  write_attribute("created_on", Time.now.utc)
	end
	
	def objects
		return Tag.find_objects(self.name)
	end
	
	def self.find_objects(tag_name, project, is_public)
		project_cond = is_public ? 'AND is_private = 0' : ''
		
		Tag.find(:all, :conditions => ["project_id = ? #{project_cond} AND tag = ? ", project.id, tag_name]).collect do |tag|
			tag.rel_object
		end
	end
	
	def self.clear_by_object(object)
		Tag.delete_all(['project_id = ? AND rel_object_type = ? AND rel_object_id = ?', object.project_id, object.class.to_s, object.id])
	end
	
	def self.set_to_object(object, taglist, force_user=0)
		self.clear_by_object(object)
		set_private = object.is_private.nil? ? false : object.is_private
		set_user = force_user == 0 ? (object.updated_by.nil? ? object.created_by : object.updated_by) : force_user
		
		Tag.transaction do
		  	taglist.each do |tag_name|
				Tag.create(:tag => tag_name, :project => object.project, :rel_object => object, :created_by => set_user, :is_private => set_private)
			end
		end
	end
	
	def self.list_by_object(object)
		return Tag.find(:all, :conditions => ['rel_object_type = ? AND rel_object_id = ?', object.class.to_s, object.id]).collect do |tag|
			tag.tag
		end
	end
	
	def self.list_by_project(project, is_public)
		project_cond = is_public ? 'AND is_private = 0' : ''
		
		tags = Tag.find(:all, :group => 'tag', :conditions => "project_id = #{project.id} #{project_cond}", :order => 'tag', :select => 'tag')
		
		return tags.collect do |tag|
			tag.tag
		end
	end
	
	def self.count_by(tag_name, project, is_public)
		project_cond = is_public ? 'AND is_private = 0' : ''
		
		tags = Tag.find(:all, :conditions => ["project_id = #{project.id} #{project_cond} AND tag = ?", tag_name], :select => 'id')
		
		return tags.length
	end
end