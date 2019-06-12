class Tyb::CasController < ApplicationController
  before_action :set_tyb_ca, only: [:show, :edit, :update, :destroy]
  layout 'admin'

  # GET /tyb/cas
  def index
    @tyb_cas = Tyb::Ca.all
  end

  # GET /tyb/cas/1
  def show
  end

  # GET /tyb/cas/new
  def new
    @tyb_ca = Tyb::Ca.new
  end

  # GET /tyb/cas/1/edit
  def edit
  end

  # POST /tyb/cas
  def create
    @tyb_ca = Tyb::Ca.new(tyb_ca_params)

    if @tyb_ca.save
      redirect_to @tyb_ca, notice: 'Ca was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /tyb/cas/1
  def update
    if @tyb_ca.update(tyb_ca_params)
      redirect_to @tyb_ca, notice: 'Ca was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /tyb/cas/1
  def destroy
    @tyb_ca.destroy
    redirect_to tyb_cas_url, notice: 'Ca was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tyb_ca
      @tyb_ca = Tyb::Ca.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def tyb_ca_params
      params.require(:tyb_ca).permit(:name, :path, :key, :certificate, :data, :apache_config, :last_check)
    end
end
