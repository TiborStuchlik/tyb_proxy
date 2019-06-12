
class Tyb::Certificate < ApplicationRecord
  require 'utils/accept_ec_public_key'
  include ActionView::Helpers::DateHelper

  audited
  belongs_to :ca, :class_name => 'Tyb::Ca' , required: false
  has_many :redirects, :class_name => 'Tyb::Redirect'

  validates :domain, presence: true
  validates :ca_id, presence: { message: 'Self signed certificate not implemented, comming soon.'}

  before_save :auto_audit_comment
  after_save :certificate_control

  attr_accessor :key_size, :key_type, :sub_action, :audit_comment_arry

  def self.check_update
    msg = []
    $configuration = Tyb::Configuration.get_all_configuration unless $configuration
    begin
    cs = Tyb::Certificate.where(autoupdate: true)
    csn = cs.map {|c| c.name }
    msg << "Find #{cs.size} updatable certificate: #{csn.join(', ')}"
    to_update = []
    cs.each do |c|
      if c.status > 0 && c.status < 6
        to = $configuration['tyb_proxy']['certificate_update_timeout'].value.to_i
        timeout = to > 0 ? to.minutes : 20.minutes
        pte = c.last_update_at + timeout
        if pte < Time.now
           Tyb::Log.create({status: 2, title: 'CERTIFICATE PROCESS ERROR', content: "Certificate '#{c.name}' process takes longer than #{to} minutes. Will be restarted."})
          c.do_certificate
        else
          Tyb::Log.create({status: 1, title: 'CERTIFICATE PROCESS IN PROGRESS', content: "Certificate '#{c.name}' is in process #{c.distance_of_time_in_words(c.last_update_at,Time.now)}"})
        end
      end
      if c.will_updated?
        if c.status > 0 && c.status < 6
          msg << "In progress: #{c.name}. Skipped, wait for finish"
        else

          to_update << c
          msg << "Will update: #{c.name}"
          c.update_columns status: 0
          puts "do certificate 1"
          c.do_certificate
        end
      else
        if c.status == 0
          msg << "Force update: #{c.name}"
        end
      end
    end
     msg << "Total count to update: #{to_update.size}"
    Tyb::Log.create({status: 0, title: 'Certificates check', content: msg.join('<br>')})
    rescue => err
      Tyb::Log.create({status: 2, title: 'Certificates check ERROR', content: err.message})
    end

  end

  def will_updated?
    if cert
      ds = cert.not_before
      de = cert.not_after
      pcv = $configuration['tyb_proxy']['percent_crumb_validity'].value.to_f
      if pcv > 10
        opcv = pcv / 100
      else
        opcv = 0.66
      end
      t80 = (de.to_i - ds.to_i) * opcv
      df = ds + t80
      df < Time.now
    else
      return false
    end
  end

  def do_certificate
    if !cert_key
      create_key
    end
    ObtainCertificateJob.perform_later self
  end

  def create_certificate( days, type='RSA', size='2048')
    if !self.cert_key
      #create_key(type, size)
    end
    unless self.ca
      return "CA must be set, self signed certificate not supported now"
    end
    begin
      ca_key = OpenSSL::PKey.read( self.ca.key)
    rescue
      return "CA have not valid private key"
    end
    begin
      ca_cert = OpenSSL::X509::Certificate.new self.ca.certificate
      if ca_cert.not_after < Time.now
        return "CA certificate expired"
      end
    rescue
      return "CA have not valid certificate"
    end
    days = days.to_i
    days = 1 if days < 1
    self.certificate = create_cert( ca_cert, ca_key, days)
    self.audit_comment_arry ||= []
    self.audit_comment_arry << 'new_certificate'
    nil
  end

  def verify
    return unless cert
    test_txt = "sign_me_and_verify"
    puk = cert.public_key
    dg = OpenSSL::Digest::SHA256.new
    prk = cert_key
    sign = prk.sign(dg,test_txt)
    puk.verify(dg, sign, test_txt)
  end

  def create_key_x( type, size )
    puts "budu vytvaret #{type} klic s delkou #{size} bitu"
    if type == "RSA"
      self.key = OpenSSL::PKey::RSA.generate(size.to_i)
    elsif type == "DSA"
      self.key = OpenSSL::PKey::DSA.generate(size.to_i)
    elsif type == "EC"
      self.key = OpenSSL::PKey::EC.generate(size).to_pem
    else
      return nil
    end
    self.certificate = nil
    self.audit_comment_arry ||= []
    self.audit_comment_arry << 'new_key'
    true
  end

  def ca_name
    ca ? ca.name : 'Self signed'
  end

  def audit
    audits.count
  end

  def cert_key
    if !@cert_key
      begin
        #@cert_key = OpenSSL::PKey::RSA.new(key)
        @cert_key = OpenSSL::PKey.read(key)

      rescue
      end
    end
    @cert_key
  end

  def key_info
    return unless cert_key
    n = @cert_key.class.name.demodulize
    if n == 'EC'
      s = cert_key.group.curve_name
    elsif n == 'RSA'
      s = @cert_key.n.num_bytes * 8
    else
      s = "unknown"
    end
    "#{n} #{s}"
  end

  def date_time_end
    if !@date_time_end
      if cert
        @date_time_end = cert.not_after

      end
    end
    @date_time_end
  end

  def cert
    if !@cert
      begin
        @cert = OpenSSL::X509::Certificate.new(certificate)
      rescue
      end
    end
    @cert
  end

  def name
    read_attribute(:name).blank? ? domain : read_attribute(:name)
  end

  def message
    if autoupdate
      if cert
        "budu kontrolovat platnost, pripadne aktualizuji"
      else
        if generated
          "vytvorim certifikat a budu aktualizovat"
        else
          "az bude certifikat budu aktualizovat"
        end
      end
    else
      if generated
        if cert
          "bez aktualizace"
        else
          "vytvorim cert, ale neaktualizuji ho"
        end
      else
        "bez akce"
      end
    end
  end

  def add_audit_comment(m)
    @audit_comment_arry ||= []
    @audit_comment_arry << m
  end

  def export_certificates
    redirects.each {|r| r.export_certificates_write_apache}
  end

  private

  def auto_audit_comment
    audit_comment_arry ||= []
    audit_comment_arry << audit_comment if audit_comment
    audit_comment_arry << "new_certificate" if certificate_changed?
    audit_comment_arry << "new_ca_certificate" if ca_certificate_changed?
    res = audit_comment_arry.join(' ')
    self.audit_comment = res
  end

  def certificate_control
    if cert
      #self.date_time_end_at = cert.not_after
    else
      if generated && status == 0
        do_certificate
      end
    end
  end

  def create_key
    type = gen_key_type || 'RSA'
    size = gen_key_size || '2048'
    puts "budu vytvaret #{type} klic s delkou #{size} bitu"
    if type == "RSA"
      tkey = OpenSSL::PKey::RSA.generate(size.to_i)
    elsif type == "DSA"
      tkey = OpenSSL::PKey::DSA.generate(size.to_i)
    elsif type == "EC"
      tkey = OpenSSL::PKey::EC.generate(size)
    else
      return nil
    end
    self.add_audit_comment 'new_key'
    self.key = tkey.to_pem
    tkey
  end

  def create_cert_x( ca_cert, ca_key, days)
    keypair = cert_key

    if keypair.class == OpenSSL::PKey::EC
      OpenSSL::X509::Request.prepend Tyb::AcceptECPublicKey
    end

    req            = OpenSSL::X509::Request.new
    req.version    = 0
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
    cert.not_after  = cert.not_before + (60 * 60 * 24 * days )
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

    cert
  end

end
