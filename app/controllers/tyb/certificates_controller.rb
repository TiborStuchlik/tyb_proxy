
class Tyb::CertificatesController < ApplicationController
  before_action :set_tyb_certificate, only: [:show, :edit, :update, :destroy, :new_key, :new_certificate, :download, :clear]
  before_action :set_all_tyb_cas, only: [:new, :edit]
  layout 'admin'

  # GET /tyb/certificates
  def index
    @tyb_certificates = Tyb::Certificate.order(:ca_id)
  end

  # GET /tyb/certificates/1
  def show
  end

  # GET /tyb/certificates/new
  def new
    @tyb_certificate = Tyb::Certificate.new
  end

  # GET /tyb/certificates/1/edit
  def edit
  end

  # POST /tyb/certificates
  def create
    @tyb_certificate = Tyb::Certificate.new(tyb_certificate_params)

    if @tyb_certificate.save
      redirect_to @tyb_certificate, notice: 'Certificate was successfully created.'
    else
      set_all_tyb_cas
      @cas = Tyb::Ca.all
      render :new
    end
  end

  # PATCH/PUT /tyb/certificates/1
  def update
    tc = params[:tyb_certificate]
    if tc && tc[:sub_action]
      sa = tc[:sub_action]
      if sa == 'new_key'
        @tyb_certificate.create_key(tc[:key_type], tc[:key_size])
      elsif sa == 'new_certificate'
        if res = @tyb_certificate.create_certificate(tc[:days], tc[:key_type], tc[:key_size])
          redirect_to new_certificate_tyb_certificate_path, alert: res and return
        end
      end
      @tyb_certificate.audit_comment = @tyb_certificate.audit_comment_arry.join(' ') if @tyb_certificate.audit_comment_arry
    end

    if @tyb_certificate.update(tyb_certificate_params)
      redirect_to @tyb_certificate, notice: 'Certificate was successfully updated.'
    else
      set_all_tyb_cas
      render :edit
    end
  end

  # DELETE /tyb/certificates/1
  def destroy
    @tyb_certificate.destroy
    redirect_to tyb_certificates_url, notice: 'Certificate was successfully destroyed.'
  end

  def new_key
    @types = %w{RSA DSA}
    @sizes = %w{4096 2048 1024 512 256}
  end

  def new_certificate
    #@tyb_certificate.key_size = 2048
    @types = %w{RSA DSA}
    @sizes =%w{4096 2048 1024 512 256}
    @key = @tyb_certificate.cert_key
  end

  def clear
    @tyb_certificate.status = 0
    @tyb_certificate.key = nil
    @tyb_certificate.certificate = nil
    @tyb_certificate.ca_certificate = nil
    @tyb_certificate.token = nil
    @tyb_certificate.date_time_end_at = nil
    @tyb_certificate.last_update_at = nil
    @tyb_certificate.token_expired_at = nil
    @tyb_certificate.order_url = nil
    @tyb_certificate.save
    redirect_to check_tyb_certificates_path
  end

  def download
    #render inline: "Download: " + params[:what]
    ext = params[:ext]
    if params[:what] == 'key'
      dc = @tyb_certificate.key
      dn = 'privkey'
    elsif params[:what] == 'cert'
      dc = @tyb_certificate.certificate
      dn = 'cert'
    else
    end
    send_data( dc.to_s,{ filename: dn + '.' + ext, type: 'application/x-download', :disposition => 'attachment'}) and return
  end

  def check
    @tyb_certificates = Tyb::Certificate.order(:ca_id, :name)
  end

  private

  # def set_for_manual
  #   @gen_checkbox = false
  #   @gem_manual = 'inline'
  #   @gen_generated = 'none'
  # end
  #
  # def set_for_generated
  #   @gen_checkbox = true
  #   @gem_manual = 'none'
  #   @gen_generated = 'inline'
  # end

  def set_all_tyb_cas
    @cas = Tyb::Ca.all
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_tyb_certificate
    @tyb_certificate = Tyb::Certificate.find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def tyb_certificate_params
    params.require(:tyb_certificate).permit(
        :ca_id,
        :certificate,
        :ca_certificate,
        :name,
        :domain,
        :generated,
        :autoupdate,
        :key,
        :days,
        :gen_key_type,
        :gen_key_size,
        :sub_action)
  end

end
