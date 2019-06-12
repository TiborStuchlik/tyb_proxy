class ApplicationController < ActionController::Base
  before_action :set_configuration
  skip_before_action :verify_authenticity_token
  include ReverseProxy::Controller
  layout false

  def index

    @url = URI(request.original_url)
    @host = @url.host
    @subdomain = ""

    @redir = $redirects[@host]
    if @redir
      puts request.original_url
      puts @redir
    else
      go_render :host_not_register, "Backend for #{@host} not defined."
      return
    end

    reverse_proxy @redir, headers: {}, http: {} do |config|

      config.on_connect do |http, r|
        r.delete("connection")
        puts "..... spojuji"
      end

      # We got a 404!
      config.on_missing do |code, response|
        go_render :not_found, "Not Found"
        return
      end

      config.on_error do |a,b|
        go_render :error, "Error"
        return
      end

=begin
      config.on_communication_error do |e|
        go_render :communication_error, e.message
        return
      end
=end

      # There's also other callbacks:
      # - on_set_cookies
      # - on_connect
      # - on_response
      # - on_set_cookies
      # - on_success
      # - on_redirect
      # - on_missing
      # - on_error
      # - on_complete
     end
  end

  private

  def go_render( r, m)
    #@url = URI(request.original_url)
    @message = m
    @result = r
    @reponse = response
    @request = request
    render :info and return
  end

  def set_configuration
    unless $configuration
      $configuration = Tyb::Configuration.get_all_configuration
    end
    Tyb::Redirect.all_redirects
  end

end
