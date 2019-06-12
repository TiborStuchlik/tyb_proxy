class Domain

  def matches?(request)
    #(request.subdomain.present? && request.subdomain.start_with?('foobar')
    true
  end

end