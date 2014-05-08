module HollerbackApp
  class WebApp < BaseApp
    helpers ::Sinatra::Assets::Helpers
    helpers ::Sprockets::Helpers
    helpers ::Split::Helper

    set :views, File.join(app_root, 'app', 'views')

    # google analytics
    set :google_analytics_key, ENV["GOOGLE_ANALYTICS"]

    # assets
    set :public_folder, File.join(app_root, 'public')
    set :sprockets, ::Sprockets::Environment.new(root)
    set :precompile, [ /\w+\.(?!js|css).+/, /application.(css|js)$/ ]
    set :assets_prefix, '/assets'
    set :assets_path, File.join(app_root, 'app', "assets")
    set :vendors_path, File.join(app_root, 'vendor', "assets")
    set :compile_path, File.join(app_root, 'public', "assets")

    configure do
      # application assets
      %w(stylesheets javascripts images fonts).each do |directory|
        sprockets.append_path(File.join(settings.assets_path, directory))
      end

      # vendor assets
      %w(stylesheets javascripts).each do |directory|
        sprockets.append_path(File.join(settings.vendors_path, directory))
      end

      #sprockets.append_path HandlebarsAssets.path

      sprockets.context_class.instance_eval do
        include ::Sinatra::Assets::Helpers
      end

      # configure Compass so it can find images
      Compass.configuration do |compass|
        compass.project_path = settings.assets_path
        compass.images_dir   = 'images'
        compass.output_style = development? ? :expanded : :compressed
      end

      # configure Sprockets::Helpers
      Sprockets::Helpers.configure do |config|
        config.environment = settings.sprockets
        config.prefix      = settings.assets_prefix
        config.digest      = true # digests are great for cache busting
        config.manifest    = Sprockets::Manifest.new(
          settings.sprockets,
          File.join(
            settings.app_root, 'public', 'assets', 'manifest.json'
          )
        )

        # clean that thang out (defaults to keeping 2 previous versions I believe)
        config.manifest.clean

        # scoop up the images so they can come along for the party
        images = Dir.glob(File.join(settings.assets_path, 'images', '**', '*')).map do |filepath|
          filepath.split('/').last
        end

        # note: .coffee files need to be referenced as .js for some reason
        # note 2: in this case, we're not using Sprockets' directive processor (https://github.com/sstephenson/sprockets#the-directive-processor) but you can do that if you like.
        javascript_files = Dir.glob(File.join(settings.assets_path, 'javascripts', '**', '*')).map do |filepath|
          filepath.split('/').last.gsub(/coffee/, 'js')
        end

        # write the digested files out to public/assets (makes it so Nginx can serve them directly)
        config.manifest.compile(%w(style.css) | javascript_files | images)
      end
    end

    # we are deploying to heroku, which does not have a JVM, which YUI needs, so let's
    # only require and config the compressors / minifiers for dev env
    configure :development do
      require 'yui/compressor'
      require 'uglifier'
      sprockets.css_compressor = YUI::CssCompressor.new
      #sprockets.js_compressor  = Uglifier.new(mangle: true)
    end
  end
end
