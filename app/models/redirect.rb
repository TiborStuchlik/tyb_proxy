class Redirect < ApplicationRecord
  #require 'utils/cert'
  include Utils::Cmd
  include Utils::Cert
  #include Utils::Certificate
  belongs_to :ca
  attr_accessor :saved_message, :log, :loga, :certificate, :with_certificate
  after_initialize :init
  before_save :set_apache_config_unsaved #:to_apache
  after_save :go_save_apache_config
  after_rollback :delete_apache_config
  before_destroy :delete_apache_config

  def log msg, code = nil
    @loga << msg
  end

  private


  def set_apache_config_unsaved
    self.apache_saved = false
    if apache_config.blank?
      b_uri = URI(backend)
      cable = 'ws://' + b_uri.host + ':' + b_uri.port.to_s
      self.apache_config = ca.apache_config % {
          path: ca.path,
          server_name: name,
          ca_path: ca.path + '/' + 'ca',
          backend: backend,
          cable: cable,
      }
    end
    true
  end

  def go_save_apache_config
    if !certificate.cert
      log "konfigurace apache neulozena, certificate missing."
      return
    end

    if save_apache_config
      update_column( :apache_saved, true)
    else
      log "konfigurace apache neulozena"
    end
  end

  def del_apache
    delete_apache_config
  end

  def set_ok
    update_column( :apache_saved, true)
  end

  def init
    @loga = []
    log "Initialize: #{id}"
    @certificate = Utils::Certificate.new(self)
  end
end
