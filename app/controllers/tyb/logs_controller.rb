class Tyb::LogsController < ApplicationController
  before_action :set_tyb_log, only: [:show, :edit, :update, :destroy]
  layout 'admin'

  # GET /tyb/logs
  def index
    @tyb_logs = Tyb::Log.last(300).reverse
  end

  # GET /tyb/logs/1
  def show
  end

  # GET /tyb/logs/new
  def new
    @tyb_log = Tyb::Log.new
  end

  # GET /tyb/logs/1/edit
  def edit
  end

  # POST /tyb/logs
  def create
    @tyb_log = Tyb::Log.new(tyb_log_params)

    if @tyb_log.save
      redirect_to @tyb_log, notice: 'Log was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /tyb/logs/1
  def update
    if @tyb_log.update(tyb_log_params)
      redirect_to @tyb_log, notice: 'Log was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /tyb/logs/1
  def destroy
    @tyb_log.destroy
    redirect_to tyb_logs_url, notice: 'Log was successfully destroyed.'
  end

  def clear
    Tyb::Log.delete_all
    redirect_to tyb_logs_url, notice: 'Logs was successfully cleared.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tyb_log
      @tyb_log = Tyb::Log.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def tyb_log_params
      params.require(:tyb_log).permit(:status, :title, :content, :data)
    end
end
