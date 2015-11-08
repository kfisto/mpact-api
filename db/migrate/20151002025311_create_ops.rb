class CreateOps < ActiveRecord::Migration
  def self.up
  	create_table :ops do |t|
  		t.string :description
  		t.integer :type
  		t.string :what
  		t.string :when
  		t.string :where
  	end
  end

  def self.down
	drop_table :ops
  end
end
