module Utils::DefaultExportModule

  def module_process
    'default abstract process, nothing do'
  end

  def module_pre_process
    'default abstract process, nothing do'
    self.apache_written = false
  end

  def module_status
    'DEM: nothing do'
  end

  private

end