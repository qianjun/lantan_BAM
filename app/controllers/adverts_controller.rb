#encoding: utf-8
class AdvertsController < ApplicationController
  layout "role"
  before_filter :sign?

  def index
    @adverts = Advert.where(:store_id=>params[:store_id])
  end


  def create
    advert = Advert.create(params[:advert].merge(:store_id=>params[:store_id]))
    if advert.save
      redirect_to   store_adverts_path(params[:store_id])
    else
      flash[:notice] = "创建失败";
      redirect_to   store_adverts_path(params[:store_id])
    end
  end

  def edit
    @advert = Advert.find(params[:id])
  end

  def update
    if Advert.find(params[:id]).update_attributes(params[:advert])
      redirect_to   store_adverts_path(params[:store_id])
    else
      flash[:notice] = "更新失败";
      redirect_to   store_adverts_path(params[:store_id])
    end
  end
end
