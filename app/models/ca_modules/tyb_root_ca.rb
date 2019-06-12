module CaModules::TybRootCa
  require 'utils/accept_ec_public_key'

  def create_order_set_dns
    ["virtual_token", 7.days.from_now]
  end

  def dns_wait
    true
  end

  def dns_validation
    true
  end

  def create_csr
    ['virtual_cert_url', 1.days.from_now]
  end

  def get_certificate
    create_cert
  end

  def export_certificate

  end

  def update_apache

  end

  private

  def create_cert
    keypair = cert_key || create_key
    ca_cert = OpenSSL::X509::Certificate.new ca.certificate
    ca_key = OpenSSL::PKey.read ca.key
    tdays = days > 0 ? days : 1
    if keypair.class == OpenSSL::PKey::EC
      OpenSSL::X509::Request.prepend Utils::AcceptECPublicKey
    end

    req = OpenSSL::X509::Request.new
    req.version = 0
    subject = OpenSSL::X509::Name.new
    subject.add_entry('C','CZ')
    subject.add_entry('CN', domain)
    req.public_key = keypair.public_key
    req.subject = subject
    req.sign( keypair, OpenSSL::Digest::SHA1.new )

    cert            = OpenSSL::X509::Certificate.new
    cert.version    = 2
    cert.serial     = rand( 999999 )
    cert.not_before = Time.new
    cert.not_after  = cert.not_before + (60 * 60 * 24 * tdays )
    cert.public_key = req.public_key
    cert.subject    = req.subject
    cert.issuer     = ca_cert.subject

    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = cert
    ef.issuer_certificate  = ca_cert

    cert.extensions = [
        ef.create_extension( 'basicConstraints', 'CA:FALSE', true ),
        ef.create_extension( 'extendedKeyUsage', 'serverAuth,clientAuth,emailProtection,codeSigning,timeStamping', false ),
        ef.create_extension( 'subjectKeyIdentifier', 'hash' ),
        ef.create_extension( 'subjectAltName', "DNS:#{domain}" ),
        #ef.create_extension( 'authorityInfoAccess', 'caIssuers;URI:http://www.tyb.cz' ),
        ef.create_extension( 'authorityKeyIdentifier', 'keyid:always,issuer:always' ),
        ef.create_extension( 'keyUsage', %w(nonRepudiation digitalSignature keyEncipherment dataEncipherment).join(","), true )
    ]

    cert.sign( ca_key, OpenSSL::Digest::SHA256.new )
    [cert, ca_cert]
  end

end