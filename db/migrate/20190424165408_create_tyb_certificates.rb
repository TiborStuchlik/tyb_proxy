class CreateTybCertificates < ActiveRecord::Migration[5.2]
  def change
    create_table :tyb_certificates do |t|
      t.references :ca, foreign_key: true
      t.string :name
      t.text :certificate
      t.text :key
      t.text :data

      t.timestamps
    end
  end
end
