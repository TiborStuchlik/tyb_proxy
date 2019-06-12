module Utils::BestHosting
  require "mechanize"

  def module_process
    return unless auto_write_apache
    update_certificate
    #update_configuration
  end

  def module_pre_process
    return unless auto_write_apache
    self.apache_written = false
    true
  end

  def module_status
    'BEST-HOSTING Module'
  end

  private

  def update_certificate

    url = 'https://best-hosting.cz/cs'
    username = 'UUU'
    password = 'PPP'

    begin

      a = Mechanize.new {|agent|
        agent.user_agent = 'TYBOT'
      }

      puts "login..."
      p = a.get(url + '/prihlaseni/')
      login = p.form(id: 'login_form')
      login.user_login = username
      login.password1 = password
      lr = a.submit(login, login.buttons.first)
      puts "loged to best_hosting getting form"

      p = a.get(url + cert_path)
      f = p.form(id: 'virtual_host')
      f.user_input_simple = certificate.certificate #cert
      f.user_input_simple2 = certificate.key #key
      f.user_input_simple3 = certificate.ca_certificate #ca
      puts "updating form"
      r = a.submit(f, f.buttons.first)
      puts "hotovo"
    rescue
      update_columns status_text: "ERROR - Best-hosting configuration."
    end
    update_columns apache_written: true, status_text: nil

  end

end