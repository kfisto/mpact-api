class AddIncludeField < ActiveRecord::Migration
  def self.up
  	add_column :entries, :include, :boolean, default: true
  end

  def self.down
  	remove_column :entries, :include
  end
end
