module Utils::Apache
  include Utils::Cmd

  def module_process
    return unless auto_write_apache
    export_certificate
    write_config
  end

  def module_pre_process
    return unless auto_write_apache
    self.apache_written = false
    true
  end

  def module_status
    'APACHE Module'
  end

  private

  def export_certificate
    c = certificate
    if c && validate_cert_path && c.key && c.ca_certificate && c.certificate
      path = cert_path
      puts path
      FileUtils.mkdir_p(path)
      File.write(path + '/cert.pem', c.certificate)
      File.write(path + '/privkey.pem', c.key)
      File.write(path + '/chain.pem', c.ca_certificate)
    else
      return "certificate path, certificates and key must be valid"
    end
    nil
  end

  def write_config
    Tyb::Redirect.all_redirects true
    return unless auto_write_apache
    unless sam = save_apache_config(prepare_config)
      puts ">>>>>> pokus o restart apache"
      s, m = apache_graceful
      if s == 0
        update_columns apache_written: true, status_text: nil
      else
        delete_apache_config
        update_columns status_text: "Konfiguration ERROR. Redirect OK."
        return
      end
    else
      error sam
      return
    end
    nil
  end

end