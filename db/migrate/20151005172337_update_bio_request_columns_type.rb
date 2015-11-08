class UpdateBioRequestColumnsType < ActiveRecord::Migration
  def up
    change_column :entries, :bio, :text
    change_column :requests, :request, :text
  end
  def down
    # This might cause trouble if you have strings longer
    # than 255 characters.
    change_column :entries, :bio, :string
    change_column :requests, :request, :text
  end
end
