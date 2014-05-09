sid = ENV['TWILIO_SID']
secret = ENV['TWILIO_SECRET']
phone = ENV['TWILIO_PHONE']

Signal::SMS.configure sid, secret, phone
