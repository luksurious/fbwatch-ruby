class AddUniqueIndexToResName < ActiveRecord::Migration
  def change
    add_index :resources, :username, :unique
  end
end
