class Tyb::ConfigurationsController < ApplicationController
  layout "admin"
  before_action :set_tyb_configuration, only: [:show, :edit, :update, :destroy]

  # GET /tyb/configurations
  def index
    @tyb_configurations = Tyb::Configuration.all
    @cfg = {}
    @tyb_configurations.each do |c|
      @cfg[c.group] ||= []
      @cfg[c.group] << c
    end
  end

  # GET /tyb/configurations/1
  def show
  end

  # GET /tyb/configurations/new
  def new
    @tyb_configuration = Tyb::Configuration.new
  end

  # GET /tyb/configurations/1/edit
  def edit
  end

  # POST /tyb/configurations
  def create
    @tyb_configuration = Tyb::Configuration.new(tyb_configuration_params)

    if @tyb_configuration.save
      redirect_to @tyb_configuration, notice: 'Configuration was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /tyb/configurations/1
  def update
    if @tyb_configuration.update(tyb_configuration_params)
      redirect_to @tyb_configuration, notice: 'Configuration was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /tyb/configurations/1
  def destroy
    @tyb_configuration.destroy
    redirect_to tyb_configurations_url, notice: 'Configuration was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tyb_configuration
      @tyb_configuration = Tyb::Configuration.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def tyb_configuration_params
      params.require(:tyb_configuration).permit(:group, :name, :value, :value_type, :data)
    end
end
