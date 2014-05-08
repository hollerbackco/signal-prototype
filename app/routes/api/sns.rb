# session routes
module HollerbackApp
  class ApiApp < BaseApp
    post '/sns/et' do
      obj = JSON.parse request.body.read
      p obj 
      if obj.key? "Message"
        msg = JSON.parse obj["Message"]
        jobId = msg["jobId"]
        if msg["state"] == "COMPLETED"
          StreamJob.find_by_job_id(jobId).complete!
        end
      end
    end
  end
end
