class CreateTybRedirects < ActiveRecord::Migration[5.2]
  def change
    create_table :tyb_redirects do |t|
      t.string :name
      t.string :backend
      t.references :certificate
      t.text :data

      t.timestamps
    end
  end
end
