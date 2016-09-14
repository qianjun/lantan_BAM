#encoding: utf-8
class DepotsController < ApplicationController
  layout "role"
  before_filter :sign?
  before_filter :find_store

  def index
    @store = find_store
    @depots = @store.depots.paginate(:page => params[:page] ||= 1, :per_page => Depot::PerPage)
  end

  def create
    #depot = Depot.find_by_name params[:depot_name]
    #@status = 0
    #if depot.nil?
      @depot = Depot.create({:name => params[:depot_name], :store_id => params[:store_id], :status => 1})
    #else
    #  @status = 1
    #end
      respond_to do |format|
        format.html { redirect_to :url => depots }
        format.json { head :no_content }
      end
  end

  def edit
  end

  def update
  end

  def destroy
  end

  private

  def find_store
    @store = Store.find_by_id(params[:store_id]) || not_found
  end
end