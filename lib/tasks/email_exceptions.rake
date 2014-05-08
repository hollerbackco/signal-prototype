namespace "email" do
  desc "extract app exceptions and email them"
  task :ios_exceptions do
    entries = Keen.extraction("app:exceptions", :timeframe => "yesterday")
    #create a map of the entries
    entry_map = []
    entries.each do |entry|
      item = entry_map.detect { |item| item["exception"] == entry["exception"] }
      if item
        item["count"] = item["count"] + 1
        unless item["app_version"].detect { |saved_version| saved_version == entry["app_ver"] }
          item["app_version"] << entry["app_ver"]
        end

        unless item["user_id"].detect { |saved_id| saved_id == entry["user_id"] }
          item["user_id"] << entry["user_id"]
        end
      else
        entry_map << {"exception" => entry["exception"], "count" => 1, "app_version" => [entry["app_ver"]], "user_id" => [entry["user_id"]]}
      end
    end
    entries = entry_map

    xm = Builder::XmlMarkup.new(:indent => 2)
    xm.table {
      xm.tr { entries[0].keys.each { |key| xm.th(key) } }
      entries.each { |row| xm.tr { row.values.each {|value| xm.td(value) } } }
    }
    puts "#{xm}"
    Mail.deliver do
      to 'joe@hollerback.co'
      from 'no-reply@hollerback.co'
      subject "IOS Exception Daily Digest #{Date.yesterday}"


      html_part do
        body "#{xm}"
      end
    end
  end
end