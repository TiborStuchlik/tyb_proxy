# 0. certifikat je v poradku, kontroluje se expirace u automatickych
# 1. je potreba vystavit novy certifikat
# 2. je podana zadost na overeni domeny a ulozen token
# 3. domena je overena
# 4. je odeslana zadost CSR na novy certifikat
# 5. cerifikat je stazen a ulozen
class ObtainCertificateJob < ApplicationJob
  queue_as :default

  def perform(c)
    c.extend "CaModules::#{c.ca.modul.camelize}".constantize
    c.update_columns( last_update_at: Time.now)
    begin

      case c.status
      when 0
        puts "Set up obtain procedure for certificate '#{c.domain}' for CA '#{c.ca.name}'"
        token, expires = c.create_order_set_dns
        c.update_columns( status: 1, token: token, token_expired_at: expires)
        # create_order_set_dns - return toke + token_expires
      when 1
        puts "Check DNS for: #{c.token}"
        c.dns_wait
        c.update_column(:status, 2)
        # dns_wait
      when 2
        puts "Validate DNS"
        c.dns_validation
        c.update_column(:status, 3)
        # dns_validation
      when 3
        puts "Create and send CSR"
        url, expires = c.create_csr
        c.update_columns( status: 4, order_url: url, token_expired_at: expires)
        # create_csr
      when 4
        puts "Getting certificate"
        c.certificate, c.ca_certificate = c.get_certificate
        c.status = 5
        c.save
        # get_certificate
      when 5
        #export certificate
        c.export_certificates
        c.update_column(:status, 6)
      end
    end while c.status < 6

  end

  private


end
