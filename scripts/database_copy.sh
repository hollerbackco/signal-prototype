#!/bin/bash

heroku pgbackups:capture --expire --app calm-peak-4397
heroku pgbackups:restore DATABASE `heroku pgbackups:url --app calm-peak-4397` \
  --app lit-sea-1934 --confirm lit-sea-1934
heroku run rake db:migrate --app lit-sea-1934
heroku restart --app lit-sea-1934

curl -X POST http://still-depths-4143.herokuapp.com/hubot/say -d message="Development DB synced" -d room='60453_hollerback@conf.hipchat.com'
