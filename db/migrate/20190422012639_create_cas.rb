class CreateCas < ActiveRecord::Migration[5.2]
  def change
    create_table :cas do |t|
      t.string :name
      t.boolean :internal
      t.string :path
      t.text :key
      t.text :certificate
      t.text :data

      t.timestamps
    end
  end
end
