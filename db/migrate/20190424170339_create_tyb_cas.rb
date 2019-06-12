class CreateTybCas < ActiveRecord::Migration[5.2]
  def change
    create_table :tyb_cas do |t|
      t.string :name
      t.string :path
      t.text :key
      t.text :certificate
      t.text :data
      t.text :apache_config
      t.datetime :last_check

      t.timestamps
    end
  end
end
