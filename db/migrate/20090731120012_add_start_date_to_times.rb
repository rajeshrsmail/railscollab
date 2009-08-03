class AddStartDateToTimes < ActiveRecord::Migration
  def self.up
    add_column :project_times, :start_date, :datetime
  end

  def self.down
    remove_column :project_times, :start_date
  end
end
