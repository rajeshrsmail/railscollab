=begin
RailsCollab
-----------

=end

class ImType < ActiveRecord::Base
	def icon_url
	 return "/images/im/#{self.icon}"
	end
end