class Tyb::Redirect < ApplicationRecord
  belongs_to :certificate, :class_name => 'Tyb::Certificate', required: false
  #attr_accessor :errors
  before_save :generate_config, :module_pre_process
  after_save :module_process
  after_initialize :init

  def error m
    @errors ||= []
    @errors.add(:apache_config, m)
  end

  def self.all_redirects(refresh = false)
    if !$redirects || refresh then
      @tyb_redirects = Tyb::Redirect.where(internal: true)
      cfg = {}
      @tyb_redirects.each do |c|
        cfg[c.host] ||= {}
        cfg[c.host] = c.backend
      end
      $redirects = cfg
    end
    $redirects
  end

  def validate_cert_path
    return false if cert_path.blank?
    begin
      FileUtils.mkdir_p(cert_path)
    rescue
      return false
    end
    true
  end

  def export_certificates_write_apache
    module_pre_process
    module_process
  end

  private

  def prepare_config
    path = cert_path ? cert_path : $configuration['tyb_proxy']['selfsigned_path'].value
    bck = internal ? $configuration['tyb_proxy']['host'].value : backend
    b_uri = URI(backend)
    cable = 'ws://' + b_uri.host + ':' + b_uri.port.to_s
    {
        path: path,
        server_name: host,
        ca_path: path,
        backend: bck,
        cable: cable,
    }
  end

  def generate_config
    if apache_config.blank?
      return unless ca = get_ca
      return unless txt = ca.apache_config
      self.apache_config = txt
    end
  end

  def get_ca
    if certificate && certificate.ca
      certificate.ca
    end
  end

  def init
    begin
      unless export_module.blank?
        klass = "Utils::#{export_module.camelize}".constantize
        extend klass
        return
      end
    rescue
    end
    klass = Utils::DefaultExportModule
    extend klass
  end

end
