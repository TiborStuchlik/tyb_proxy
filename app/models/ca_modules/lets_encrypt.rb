module CaModules::LetsEncrypt
  include Utils::Domain
  require 'resolv'
  include ActionView::Helpers::DateHelper


  def create_order_set_dns
    order, challenge = @order ||= init
    puts set_dns(domain, challenge.record_content)
    [challenge.record_content, order.expires]
  end

  def dns_wait
    def check_dns(dns)
      begin
        dt = dns.getresource("_acme-challenge.#{domain}", Resolv::DNS::Resource::IN::TXT).data
        if dt == token
          return true
        else
          return false
        end
      rescue
        return false
      end
    end
    dns = Resolv::DNS.new
    st = Time.now
    while !check_dns(dns)
      puts "Wait for propagate dns record: #{time_ago_in_words(st) }"
      update_columns(last_update_at: Time.now)
      sleep(10)
    end
    puts "wait 1 minute at end"
    12.times do |t|
      sleep(10)
      puts "#{10*(t+1)} seconds"
    end
    puts "dns propagated"
  end

  def dns_validation
    order, challenge = @order ||= init
    challenge.request_validation
    while challenge.status == 'pending'
      puts challenge.status
      sleep(2)
      challenge.reload
    end
    puts challenge.status
  end

  def create_csr
    order, challenge = @order ||= init
    key = cert_key || create_key
    csr = Acme::Client::CertificateRequest.new(private_key: key, subject: { common_name: domain })
    order.finalize(csr: csr)
    while order.status == 'processing'
      puts order.status
      sleep(1)
    end
    puts order.status
    [order.url, order.expires]
  end

  def get_certificate
    order ||= init(order_url)
    crts = order.certificate
    ms = crts.scan /-----BEGIN CERTIFICATE-----[^-]*-----END CERTIFICATE-----/
    [ms[0],ms[1]]
  end

  def export_certificate

  end

  def update_apache

  end

  private

  def init(url=nil)
    kid = $configuration['lets_encrypt']['kid'].value
    key = OpenSSL::PKey.read $configuration['lets_encrypt']['key'].value
    dir = $configuration['lets_encrypt']['dir'].value

    client = Acme::Client.new(private_key: key, directory: dir, kid: kid)
    if url
      return client.order(url: url)
    end
    order = client.new_order(identifiers: [domain])

    authorization = order.authorizations.first
    challenge = authorization.dns
    puts "Init LE: #{challenge.record_content}"
    [order ,challenge]
  end


end