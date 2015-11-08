class EditRequests < ActiveRecord::Migration
  def self.up
  	remove_column :requests, :entry_id
  	add_column :requests, :entry_id, :integer
  end

  def self.down
  	remove_column :requests, :entry_id
  	add_column :requests, :entry_id
  end
end
