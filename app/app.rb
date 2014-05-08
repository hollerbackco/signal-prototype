# load all the necessary files for the app to run
#require File.expand_path('./app/routes/base')

# load models and jobs
%w[models jobs services].each do |dir|
  Dir.open("./app/#{dir}").each do |file|
    next if file =~ /^\./
    require File.expand_path("./app/#{dir}/#{file}")
  end
end

# load routes
%w[api web].each do |app|
  require File.expand_path("./app/routes/#{app}")
  Dir.glob("./app/routes/#{app}/*.rb").each do |relative_path|
    require relative_path
  end
end
