require_dependency "storytime/application_controller"

module Storytime
  module Dashboard
    class MediaController < DashboardController
      respond_to :json, only: [:create, :destroy]

      def index
        redirect_to url_for([:dashboard, Storytime::Post]) unless Storytime.enable_file_upload

        @media = Media.order("created_at DESC").page(params[:page]).per(9)
        authorize @media

        @large_gallery = false if params[:large_gallery] == "false"

        render partial: "gallery", content_type: Mime::HTML if request.xhr?
      end

      def create
        @media = Media.new(media_params)
        @media.user = current_user

        authorize @media
        @media.save
        respond_with :dashboard, @media do |format|
          format.json{ render :show }
        end
      end
      
      def destroy
        @media = Media.find(params[:id])
        authorize @media
        @media.destroy
        respond_with @media
      end

    private

      def media_params
        params.require(:media).permit(:file)
      end

    end
  end
end
