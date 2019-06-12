class CreateRedirects < ActiveRecord::Migration[5.2]
  def change
    create_table :redirects do |t|
      t.string :name
      t.string :backend
      t.text :data

      t.timestamps
    end
  end
end
