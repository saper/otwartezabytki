# -*- encoding : utf-8 -*-
module Api
  module V1
    class RelicsController < ApiController
      before_filter :api_authenticate
      before_filter :api_authorize, :only => [:create]

      def index
        p = params.slice(:query, :place, :from, :to, :categories, :state, :existance, :location, :has_photos, :has_description, :order)
        params[:search] = p.merge(:q => p.delete(:query))

        @relics = tsearch.perform
      end

      def show
        @relic = Relic.find(params[:id])
      end

      def create
        @relic = Relic.new(params[:relic])
        @relic.user_id = @user.id
        @relic.created_via_api = true

        if @relic.save
          render :show
        else
          render :json => {:errors => @relic.errors}, :status => :unprocessable_entity
        end
      end

    end
  end
end
