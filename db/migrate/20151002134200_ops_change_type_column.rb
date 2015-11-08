class OpsChangeTypeColumn < ActiveRecord::Migration
  def self.up
	rename_column :ops, :type, :category
  end

  def self.down
  	rename_column :ops, :category, :type
  end
end
