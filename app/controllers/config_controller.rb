=begin
RailsCollab
-----------

=end

class ConfigController < ApplicationController

  before_filter :login_required
  before_filter :process_session
  after_filter  :user_track
  
end