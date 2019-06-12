class CreateTybConfigurations < ActiveRecord::Migration[5.2]
  def change
    create_table :tyb_configurations do |t|
      t.string :group
      t.string :name
      t.text :value
      t.string :value_type
      t.text :data

      t.timestamps
    end
  end
end
