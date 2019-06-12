class Utils::Certificate
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  require 'openssl'
  #attr_accessor :ca_cert_file, :ca_key_file, :cert_path, :ca_cert_path
  attr_accessor :cert, :days, :configuration, :with_apache

  def create(d, c, wa)
    create_certificate(d, c, wa)
  end

  def date_time_end
     @cert.not_after if @cert
  end

  def edition
    @edition ||= find_last
  end

  def ca_cert
    if !@ca_cert
      begin
        f = File.new @cert_path + 'chain.pem', 'r'
        @ca_cert = OpenSSL::X509::Certificate.new(f.read)
      rescue
      ensure
        f.close unless f.nil?
      end
    end
    @ca_cert
  end

  def persisted?
    false
  end

  private

  def initialize(r)
    @redirect = r
    @cert = nil
    return if r.new_record?
    @root_path = r.ca.path.end_with?('/') ? r.ca.path : "#{r.ca.path}/"
    @cert_path = "#{@root_path}live/#{r.name}/"
    @archive_path = "#{@root_path}archive/#{r.name}/"

    begin
      f = File.new @cert_path + 'cert.pem', 'r'
      @cert = OpenSSL::X509::Certificate.new(f.read)
    rescue
    ensure
      f.close unless f.nil?
    end
  end

  # def method_missing(m, *args, &block)
  #   puts "missing"
  # end

  def find_last
    if @redirect.ca.internal
      Dir.glob( @archive_path  + '*').map {|d| File.basename(d).to_i}.max || -1
    else
      Dir.glob( @archive_path  + 'cert*.pem').map {|d| File.basename(d, '.pem').sub('cert','').to_i}.max || -1
    end
  end

  def create_certificate(d, c, wa)

    path = @redirect.ca.path.end_with?('/') ? @redirect.ca.path : "#{@redirect.ca.path}/"
    domain = @redirect.name
    d = d.to_i
    d = 1 if d < 1

    #zkontroluje jestli existuje slozka v archive || vytvori
    archive = path + 'archive/'
    return "directory not exist: #{archive}" if !File.directory?(archive)
    old = archive + domain + "/"
    if !File.directory?(old)
      Dir.mkdir(old)
    end

    # najde v ni posledni cislo slozky a vytvori dalsi || prvni 0
    last_dir = find_last
    last_dir += 1
    actual = old + last_dir.to_s + '/'
    Dir.mkdir(actual)

    # vytvori certifikat a klic, a ulozi do nove slozky
    cert_key = build_cert(domain, path, d, c)
    fc = File.new(actual + 'cert.pem', 'w')
    fc.write(cert_key[0])
    fc.close
    fc = File.new(actual + 'privkey.pem', 'w')
    fc.write(cert_key[1])
    fc.close

    # ve slozce live vytvori slozku pro domenu || nastavi
    live = path + 'live/' + domain + '/'
    Dir.mkdir(live) if !File.directory?(live)

    # prenastavy linky na nove vytvorene cert+key v archive slozce
    Dir.glob(live + '*').each {|d| File.delete(d)}
    File.symlink(actual + 'cert.pem', live + 'cert.pem')
    File.symlink(actual + 'privkey.pem', live + 'privkey.pem')
    File.symlink( path + 'ca/' + 'ca.crt', live + 'chain.pem')

    "Certifikat byl vytvoren ve verzi: " + last_dir.to_s
  end

  def build_cert(domain, path, d, c)
    rc = File.read path + 'ca/ca.crt'
    ca_cert = OpenSSL::X509::Certificate.new rc
    ca_key = OpenSSL::PKey::RSA.new(File.read(path + '/ca/ca.key'))

    keypair = OpenSSL::PKey::RSA.new(2048)

    req = OpenSSL::X509::Request.new
    req.version = 0
    subject = OpenSSL::X509::Name.new
    subject.add_entry('C', 'CZ')
    subject.add_entry('CN', domain)
    req.public_key = keypair.public_key
    req.subject = subject
    req.sign(keypair, OpenSSL::Digest::SHA1.new)

    cert = OpenSSL::X509::Certificate.new
    cert.version = 2
    cert.serial = rand(999999)
    cert.not_before = Time.new
    cert.not_after = cert.not_before + (60 * 60 * 24 * d)
    cert.public_key = req.public_key
    cert.subject = req.subject
    cert.issuer = ca_cert.subject

    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = cert
    ef.issuer_certificate = ca_cert

    cert.extensions = [
        ef.create_extension('basicConstraints', 'CA:FALSE', true),
        ef.create_extension('extendedKeyUsage', 'serverAuth,clientAuth,emailProtection,codeSigning,timeStamping', false),
        ef.create_extension('subjectKeyIdentifier', 'hash'),
        ef.create_extension('subjectAltName', "DNS:#{domain}"),
        #ef.create_extension( 'authorityInfoAccess', 'caIssuers;URI:http://www.tyb.cz' ),
        ef.create_extension('authorityKeyIdentifier', 'keyid:always,issuer:always'),
        ef.create_extension('keyUsage', %w(nonRepudiation digitalSignature keyEncipherment dataEncipherment).join(","), true)
    ]

    cert.sign(ca_key, OpenSSL::Digest::SHA256.new)

    [cert, keypair]
  end

end