class UpdateRequestsTable < ActiveRecord::Migration
  def self.up
	rename_column :requests, :entryid, :entry_id
  end

  def self.down
  	rename_column :requests, :entry_id, :entryid
  end
end
