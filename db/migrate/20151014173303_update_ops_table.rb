class UpdateOpsTable < ActiveRecord::Migration
def up
    change_column :ops, :description, :text, :limit => 2048
  end
  def down
    # This might cause trouble if you have strings longer
    # than 255 characters.
    change_column :ops, :description, :string
  end
end
