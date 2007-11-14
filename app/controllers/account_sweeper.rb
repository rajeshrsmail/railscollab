=begin
RailsCollab
-----------

=end

class AccountSweeper < ActionController::Caching::Sweeper

  observe User
  
  def after_create(data)
  	expire_account(data)
  end
  
  def after_save(data)
  	expire_account(data)
  end
  
  def after_destroy(data)
  	expire_account(data)
  end
  
  def expire_account(data)
    puts "==Expire account=="
  	expire_page(:controller => 'account', :action => 'avatar', :id => data.id, :format => 'png')
  end
end