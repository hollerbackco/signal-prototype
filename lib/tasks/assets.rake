namespace :assets do

  desc 'grab image screen'
  task :generate_images do
    Video.where("filename is not null").each do |video|
      unless video.image_url.blank?
        puts video.image_url
        next
      end
      video_key = video.filename

      Dir.mktmpdir do |dir|
        # grab video from s3
        begin
          files = Hollerback::S3Cacher.get([video_key], Video::BUCKET_NAME, dir)
        rescue
          puts "no file"
          next
        end

        # grab screenshot
        begin
          movie =  Hollerback::Stitcher::Movie.new(files.first.to_s)
          image = movie.screengrab dir, :large

          # sent the file to s3
          output_path = video_key.split(".").first << "-image.png"

          send_file_to_s3 image, output_path
        rescue FFMPEG::Error
          puts "!!!!!!!!!!!!!!!!!!!!! ERROR"
        end
      end
      puts video.image_url
    end
  end

  desc 'compile assets'
  task :compile => [:compile_js, :compile_css] do
  end
  task :precompile => :compile

  desc 'compile javascript assets'
  task :compile_js do
    sprockets = HollerbackApp::WebApp.settings.sprockets
    asset     = sprockets['application.js']
    outpath   = File.join(HollerbackApp::WebApp.settings.compile_path, 'js')
    outfile   = Pathname.new(outpath).join('application.min.js') # may want to use the digest in the future?

    FileUtils.mkdir_p outfile.dirname

    asset.write_to(outfile)
    asset.write_to("#{outfile}.gz")
    puts "successfully compiled js assets"
  end

  desc 'compile css assets'
  task :compile_css do
    sprockets = HollerbackApp::WebApp.settings.sprockets
    asset     = sprockets['application.css']
    outpath   = File.join(HollerbackApp::WebApp.settings.compile_path, 'css')
    outfile   = Pathname.new(outpath).join('application.min.css') # may want to use the digest in the future?

    FileUtils.mkdir_p outfile.dirname

    asset.write_to(outfile)
    asset.write_to("#{outfile}.gz")
    puts "successfully compiled css assets"
  end

  def bucket
    @bucket ||= AWS::S3.new.buckets[Video::BUCKET_NAME]
  end

  def send_file_to_s3(file, s3path)
    obj = bucket.objects[s3path]
    upload_to_s3(file, obj)
    s3path
  end

  #todo temp fix to s3 upload problem
  # ref: https://github.com/aws/aws-sdk-ruby/issues/241
  def upload_to_s3(path, s3_obj)
    retries = 3
    begin
      s3_obj.write(File.open(path, 'rb', :encoding => 'BINARY'))
    rescue => ex
      retries -= 1
      if retries > 0
        puts "ERROR during S3 upload: #{ex.inspect}. Retries: #{retries} left"
        retry
      else
         # oh well, we tried...
        raise
      end
    end
  end
end
