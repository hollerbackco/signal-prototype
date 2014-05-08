namespace :app do

  desc "Reactivate users that haven't been active and put them on a re-engagement track"
  task :reactivate_users, [:dry_run] do |t, args|
    dry_run = true
    if(args.dry_run)
      dry_run = (args.dry_run == "false" ) ? false : true
    end
    Reactivator.perform_async(dry_run)
  end

end