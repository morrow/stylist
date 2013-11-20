class StylistController < ApplicationController

  before_filter :authenticate_user, :get_stylesheet
  respond_to :json

  def create
    render json: @stylist.set_with_object(params)
  end

  def update
    render json: @stylist.set_with_object(params)
  end

  def show
    render json: @stylist.get_with_object(params)
  end

  def destroy
    render json: @stylist.rm_with_object(params)
  end

  def get_stylesheet
    @stylist = Stylist.new(params)
  end

end
