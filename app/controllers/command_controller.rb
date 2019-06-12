class CommandController < ApplicationController
  require 'resolv'
  include Utils::Cert
  include Utils::Domain

  layout 'admin'

  def command
    cmd = params[:command]
    msg = "command not exist or have not result"
    case cmd
    when 'test'
      render plain: "OK: #{params[:domain]}" and return
    when 'csob_back'
      @prms = params
      render 'csob_back' and return
    when 'csob_status'
      payment = CsobPaymentGateway::BasePayment.new(
        pay_id: '1e07754253e57EE'
      )
      status = payment.payment_status
      render plain: status.inspect and return
    when 'csob'

      payment = CsobPaymentGateway::BasePayment.new(
          total_price: '70000',
          cart_items:  [
              { name: 'Item1',   quantity: '1', amount: '70000', description: 'Item1' }
          ],
          order_id:    '12345678',
          description: 'Order from your-eshop.com - Total price 600 CZK',
          customer_id: '1235'
      )

      # payment = CsobPaymentGateway::BasePayment.new
      init   = payment.payment_init
      pay_id = init['payId']

      url = payment.payment_process_url

      redirect_to payment.payment_process_url and return
    when 'pokus'

      r = Tyb::Redirect.find(6)
      r.extend "Utils::#{r.export_module.camelize}".constantize

      c = r.certificate

      r.update_certificate

      render plain: "POKUS: #{r.inspect}" and return

    when 'register'
      return
      #kid = $configuration['lets_encrypt']['kid'].value
      key = OpenSSL::PKey.read $configuration['lets_encrypt']['key'].value
      dir = $configuration['lets_encrypt']['dir'].value

      client = Acme::Client.new(private_key: key, directory: dir)
      account = client.new_account(contact: 'mailto:tibor@seznam.cz', terms_of_service_agreed: true)

      kv = Tyb::Configuration.find(11)
      kv.value = account.kid
      kv.save

      render plain: "LETS ENCRYPT ACME REGISTER CLIENT: #{account.kid}" and return
    when 'check'
      r = Tyb::Certificate.check_update
      redirect_to check_tyb_certificates_path,  notice: "Cerificate check running. See log for detail." and return
    when 'domain'

      l = set_dns('stuchlik.info', 'test_value_' + Time.now.to_s)


      render plain: "domain: #{l}" and return

    when 'le'
      kid = $configuration['lets_encrypt']['kid'].value
      key = OpenSSL::PKey.read $configuration['lets_encrypt']['key'].value
      dir = $configuration['lets_encrypt']['dir'].value

      domain = 'devel.tyb.cz'
      certificate = Tyb::Certificate.find_by_domain domain
      cert_key = OpenSSL::PKey.read certificate.key

      # https://github.com/unixcharles/acme-client
      #client = Acme::Client.new(private_key: key, directory: 'https://acme-staging-v02.api.letsencrypt.org/directory')

      #account = client.new_account(contact: 'mailto:tibor@seznam.cz', terms_of_service_agreed: true)

      $client = Acme::Client.new(private_key: key, directory: dir, kid: kid)
      $order = $client.new_order(identifiers: [domain])
      $authorization = $order.authorizations.first
      $challenge = $authorization.dns

      #ulozim do db po aktualizaci dns, pokud je stejny neupdatuji dns
      set_dns(domain, $challenge.record_content)

      #kontroluji dns jestli je jiz token zpropagovany
      dns = Resolv::DNS.new
      r = dns.getresource("_acme-challenge.#{domain}", Resolv::DNS::Resource::IN::TXT)
      puts "kontroluji dns"
      while $challenge.record_content != r.data
        r = dns.getresource("_acme-challenge.#{domain}", Resolv::DNS::Resource::IN::TXT)
        sleep 10
      end

      # reknu LE ze je zpropagovano at si to overi
      if $challenge && $challenge.record_content == r.data
        $challenge.request_validation
        while $challenge.status == 'pending'
          sleep(4)
          $challenge.reload
        end
        $challenge = nil
      end

      # overeno - zazadam LE o cerifikat
      if !$challenge && $order && $order.status != 'valid'
        csr = Acme::Client::CertificateRequest.new(private_key: cert_key, subject: {common_name: domain})
        $order.finalize(csr: csr)
        sleep(1)
      end

      # certifikat stahnu
      if $order.status == 'valid'
        puts $order.certificate
      end

      render plain: "OK LE: #{$order.status}" and return
    when 'certdownload'
      @domain = params[:cert]
      @cert_res = cert_info(@domain, '/root/ca/')
      if params[:ca]
        dc = @cert_res[3]
        dn = "ca"
      else
        dc = @cert_res[2]
        dn = 'cert'
      end
      ext = params[:ext] == 'crt' ? "crt" : "pem"
      send_data(dc.to_s, {filename: dn + '.' + ext, type: 'application/x-download', :disposition => 'attachment'}) and return
    when 'certinfo'
      @domain = params[:cert]
      @cert_res = cert_info(@domain, '/root/ca/')
      # send_data(msg[2],{ filename: 'cert.crt', type: 'application/x-download', :disposition => 'attachment'}) and return
      render 'cert_info' and return
    when 'create'
      @domain = params[:domain] || request.host
      msg = create(@domain, '/root/ca/')
      redirect_to '/command/certinfo?cert=' + @domain
    end
  end

  private


end
