class AddStarCountToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :star_count, :integer
  end
end
