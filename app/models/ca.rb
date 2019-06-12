class Ca < ApplicationRecord

  serialize :data

  has_many :redirects

end
