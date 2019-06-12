class Tyb::Ca < ApplicationRecord
  has_many :certificates, :class_name => 'Tyb::Certificate'

  def cert
    if !@cert && !certificate.blank?
      begin @cert = OpenSSL::X509::Certificate.new(certificate); rescue; end
    end
    @cert
  end

  def privkey
    if !@privkey
      begin @privkey = OpenSSL::PKey.read(key); rescue; end
    end
    @privkey
  end
end
