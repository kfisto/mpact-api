class UpdateEntryTable < ActiveRecord::Migration
def self.up
	add_column :entries, :location, :string
	add_column :entries, :bio, :string
	create_table :requests do |t|
  		t.string :entryid
  		t.string :request
  	end
  	# add_column :entries, :data, :binary, :limit => 8192
  end

  def self.down
  	remove_column :entries, :location
  	remove_column :entries, :bio
  	drop_table :requests
  end
end
