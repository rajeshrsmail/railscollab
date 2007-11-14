=begin
RailsCollab
-----------

=end

module AccountHelper
    include ActionView::Helpers::AdministrationHelper
    
	def account_tabbed_navigation(current=0)
	 items = [{:id => 0, :title => 'My account', :url => '/account/index', :selected => true}]
		
     items[current][:selected] = true
	 return items
	end
	
	def account_crumbs(current="Index")
	 [{:title => 'Dashboard', :url => '/dashboard'},
	  {:title => 'Account', :url => '/account'},
	  {:title => current}]
	end
  
end