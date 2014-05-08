namespace :email do
  desc "email waitlisters"
  task :waitlisters do |t|

    Waitlister.all.each do |waitlister|

      begin
      Mail.deliver do
        to waitlister.email
        from 'no-reply@hollerback.co'
        subject "Hollerback is now live in the AppStore"

        #body

        end
      rescue Exception => ex
        Honeybadger.notify(ex, {:message => "couldn't send email to #{waitlister.email}"})
      end
    end


  end

end