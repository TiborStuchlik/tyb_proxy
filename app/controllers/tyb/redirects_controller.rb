class Tyb::RedirectsController < ApplicationController
  before_action :set_tyb_redirect, only: [:show, :edit, :update, :destroy]
  layout 'admin'

  # GET /tyb/redirects
  def index
    @tyb_redirects = Tyb::Redirect.all
  end

  # GET /tyb/redirects/1
  def show
  end

  # GET /tyb/redirects/new
  def new
    @certificates = Tyb::Certificate.all
    @tyb_redirect = Tyb::Redirect.new
  end

  # GET /tyb/redirects/1/edit
  def edit
    @certificates = Tyb::Certificate.all
  end

  # POST /tyb/redirects
  def create
    @tyb_redirect = Tyb::Redirect.new(tyb_redirect_params)

    if @tyb_redirect.save
      redirect_to @tyb_redirect, notice: 'Redirect was successfully created.'
    else
      @certificates = Tyb::Certificate.all
      render :new
    end
  end

  # PATCH/PUT /tyb/redirects/1
  def update
    if @tyb_redirect.update(tyb_redirect_params)
      if @tyb_redirect.errors.size > 0
        @certificates = Tyb::Certificate.all
        render :edit
      else
        redirect_to @tyb_redirect, notice: 'Redirect was successfully updated.'
      end
    else
      @certificates = Tyb::Certificate.all
      render :edit
    end
  end

  # DELETE /tyb/redirects/1
  def destroy
    @tyb_redirect.destroy
    redirect_to tyb_redirects_url, notice: 'Redirect was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tyb_redirect
      @tyb_redirect = Tyb::Redirect.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def tyb_redirect_params
      params.require(:tyb_redirect).permit(:name,
                                           :internal,
                                           :backend,
                                           :certificate_id,
                                           :host,
                                           :auto_write_apache,
                                           :apache_config,
                                           :cert_path,
                                           :export_module )
    end
end
