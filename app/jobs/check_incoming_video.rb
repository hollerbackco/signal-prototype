class CheckIncomingVideo
  include Sidekiq::Worker

  def self.get_cache_key(convo_id, guid)
    "#{convo_id}:#{guid}"
  end

  def perform(convo_id, guid, dry_run=false)
    #look up redis

    key = CheckIncomingVideo.get_cache_key(convo_id, guid)
    payload = REDIS.get(key)

    return if payload.nil?
    payload = JSON.parse(payload)

    p payload.to_s
    if(payload["processed"] == false)
      p "[incoming video] guid:#{guid} convo_id:#{convo_id} has not been processed"
      #notify user
      if(!dry_run)
        Hollerback::Push.send(nil, payload["sender_id"], {:alert => "Message send failed. Please retry.", :sound => "default"}.to_json)
      else
        p "dry run push on incoming"
      end
    else
      p "incoming video processed"
    end
  end

end