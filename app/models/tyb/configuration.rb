class Tyb::Configuration < ApplicationRecord

  after_save :clean_cache

  def value_view
    if value.size > 40
      value.mb_chars.limit(40).to_s + "..."
    else
      value
    end
  end

  def self.get_all_configuration
    @tyb_configurations = Tyb::Configuration.all
    cfg = {}
    @tyb_configurations.each do |c|
      cfg[c.group] ||= {}
      cfg[c.group][c.name] = c
    end
    cfg
  end

  private

  def clean_cache
    $configuration = Tyb::Configuration.get_all_configuration
  end

end
