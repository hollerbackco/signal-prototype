sid = ENV['TWILIO_SID']
secret = ENV['TWILIO_SECRET']
phone = ENV['TWILIO_PHONE']

Hollerback::SMS.configure sid, secret, phone
