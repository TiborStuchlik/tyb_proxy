module Utils::AcceptECPublicKey
  def public_key= value
    if OpenSSL::PKey::EC::Point === value
      key = OpenSSL::PKey::EC.new value.group
      key.public_key = value
      value = key
    end
    super value
  end
end