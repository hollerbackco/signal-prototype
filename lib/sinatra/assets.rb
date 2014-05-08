require 'sinatra/base'

module Sinatra
  module Assets
    module Helpers
      def stylesheet_tag(source)
        source_name = source_name_for(source, "css")
        "<link href=\"#{stylesheet_path(source_name)}\" rel=\"stylesheet\" />"
      end

      def javascript_tag(source)
        source_name = source_name_for(source, "js")
        "<script src=\"#{javascript_path(source_name)}\"></script>"
      end

      def image_tag(source)
        ext = File.extname source
        filename = File.basename(source, ext) + "@2x#{ext}"
        "<img src=\"#{image_path(source)}\" data-at2x=\"#{image_path(filename)}\" />"
      end

      def video_tag(source)
        "<video width=100% controls><source src=\"#{source}\" type=\"video/mp4\"/></video>"
      end

      private

      def source_name_for(source, ext)
        source = production? ? "#{source}.min.#{ext}" : "#{source}.#{ext}"
      end
    end
  end
end
