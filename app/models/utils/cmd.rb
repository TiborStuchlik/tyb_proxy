module Utils::Cmd
  require 'net/http'
  require 'open3'

  def save_apache_config(prm={})
    begin
      return save_apache_cfg prm
    rescue => err
      #log(err.message)
      return false
    end
  end

  def delete_apache_config
    delete_apache_cfg
  end

  private

  def delete_apache_cfg
    #error 'delete apache configuration'
    begin
      File.delete('/etc/httpd/tyb/' + name + '.conf')
      #error 'OK'
    rescue => err
      #log err.message
    end
  end

  def save_apache_cfg(prm = {})
    begin
      path = $configuration['apache']['config_path'].value
      f = File.new( path + '/' + name + '.conf', 'w')
      cfg = apache_config % prm
      f.write(cfg)
      log('write apache config')
      ret = true
    rescue IOError => e
      log(e.message)

      ret = false
    ensure
      f.close unless f.nil?
    end
    ret
  end

  def apache_graceful
    c = $configuration['apache']['reload command']
    cmd = c ? c.value : "sudo /usr/bin/systemctl xreload httpd.service"
    #cmd = 'sudo /usr/bin/systemctl reload httpd.service'
    run_cmd(cmd)
  end

  def run_cmd(cmd)
    exit_status = "undefined"
    o = "undefined"
    e = "undefined"

    Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
      exit_status = wait_thr.value
      o = stdout.read
      o = "none" if o == ""
      e = stderr.read
      e = "none" if e == ""
    end

    s = exit_status.exitstatus
    msg = "command: '<code>#{cmd}</code>', pid: #{exit_status.pid}, status: #{s}, output: #{o}, error: #{e}"
    r = s == 0 ? "OK - " : "ERROR - "
    msg = r + msg

    [exit_status.exitstatus, msg]
  end

end