API
===

1. Main web api;
2. Sidekiq background workers;

Design Principles and Resources
-------------------------------

http://www.12factor.net/
http://dl.dropboxusercontent.com/u/1579953/talks/modern_architecture.pdf

- logs as first class citizens
- long running tasks on jobs queue


Server
------
production server is located at http://signal-prototype.herokuapp.com/api/


Dependencies
------------
Only runs on postgres. Installing postgres:
http://www.moncefbelyamani.com/how-to-install-postgresql-on-a-mac-with-homebrew-and-lunchy/


Installing Locally
------------------

    bundle install
    createdb signal_dev
    rake db:migrate
    rerun -- thin start


The Envelope
------------
Every response is contained by an envelope. That is, each response has a predictable set of keys with which you can expect to interact:

    {
        "meta": {
            "code": 200
        },
        "data": {
            ...
        }
    }


Routes
------

## AUTHENTICATION
User must register and verify with phone. User authenticates with email
and password.

### POST /email/available
Checks to see if an email is currently in use

  params
    email*

  response
    {
      data: true
    }

### POST /register
The endpoint registers a user and sends a verification code to the supplied phone
number

    params
        email*
        username*
        password*
        phone*             string, i.e. '+18885558888'

    response
        {
          user: {
            id: 1,
            phone: "+18885558888",
            username: "username",
            created_at: timestamp,
            phone_hashed: "",
            is_new: true
          }
        }

### POST /verify
Verifies a users phone number.  Code is a four characters long and sent
to the users phone as a text

    params
        phone*
        code*
        device_token*
        platform*
        password*

    response
        {
          access_token: "anaccesstoken",
          user: {
            id: 1,
            phone: "+18885558888",
            username: "username",
            created_at: timestamp,
            phone_hashed: "",
            is_new: false
          }
        }



### POST /session
get an access token

    params
        email*
        password*
        device_token*
        platform*

    response
        {
          access_token: "anaccesstoken",
          user: {
            id: 1,
            phone: "+18885558888",
            username: "username",
            created_at: timestamp,
            phone_hashed: "",
            is_new: false
          }
        }

## CONTACTS

### POST /contacts/check
send hashed numbers. it will return users on the service

    params
        access_token*   string
        c[0][:n]        string
        c[0][:p]        string

    response
        {
            data: [list of users]
        }


## SYNC

### GET /me/sync
Sends conversation and video data.  If no timestamp is sent, the entire
list will be sent.  If a timestamp is supplied, only new/updated objects  will be
returned.

    params
      updated_at    iso8601 date

    response
      {
          "data": [
              {
                  "type": "conversation",
                  "sync": {
                      "created_at": "2014-05-12T17:27:36+00:00",
                      "deleted_at": null,
                      "following": true,
                      "id": 8,
                      "is_archived": false,
                      "last_message_at": "2014-05-12T17:27:36+00:00",
                      "most_recent_subtitle": null,
                      "most_recent_thumb_url": null,
                      "name": "how's life?",
                      "unseen_count": "0",
                      "user_id": 16,
                      "unread_count": "0",
                      "is_deleted": false,
                      "members": [
                          {
                              "username": "yogi",
                              "user_id": 17,
                              "following": false,
                              "name": "yogi"
                          },
                          {
                              "username": "me",
                              "user_id": 16,
                              "following": true,
                              "name": "me"
                          }
                      ],
                      "sender_name": "me",
                      "updated_at": "2014-05-12T17:27:36+00:00"
                  }
              },
              {
                  "type": "message",
                  "sync": {
                      "created_at": "2014-05-11T21:16:17+00:00",
                      "needs_reply": true,
                      "sender_name": "yogi",
                      "sent_at": "2014-05-11T21:16:17+00:00",
                      "type": "text",
                      "conversation_id": 2,
                      "sender_id": 17,
                      "user": {
                          "name": "yogi"
                      },
                      "is_deleted": false,
                      "text": {
                          "guid": "afd15239-f042-4458-92ba-162b49e05a0b",
                          "text": "Yea. I've seen it..really good movie"
                      },
                      "is_read": false
                  }
              }
              ]
      }


## CONVERSATIONS

### POST /me/conversations
create a new conversation

    params
        access_token*     string
        invites*          array of phone numbers
        name*             string

    response
        {
          "data": {
                  "created_at": "2014-05-12T17:27:36+00:00",
                  "deleted_at": null,
                  "following": true,
                  "id": 8,
                  "is_archived": false,
                  "last_message_at": "2014-05-12T17:27:36+00:00",
                  "most_recent_subtitle": null,
                  "most_recent_thumb_url": null,
                  "name": "how's life?",
                  "user_id": 16,
                  "unread_count": 0,
                  "is_deleted": false,
                  "members": [
                      {
                          "username": "yogi",
                          "user_id": 17,
                          "following": false
                      },
                      {
                          "username": "me",
                          "user_id": 16,
                          "following": true
                      }
                  ],
                  "updated_at": "2014-05-12T17:27:36+00:00"
              }
        }


### POST /me/conversations/:id/text
create a new text message in conversation :id

    params
        access_token*   string
        guid*           string
        text*           string

    response
        {
            "data": {
                "conversation_id": 2,
                "created_at": "2014-05-12T17:25:32+00:00",
                "guid": "aed15239-f042-4458-92ba-162b49e05a0b",
                "id": 2,
                "text": "whats up man?",
                "updated_at": "2014-05-12T17:25:32+00:00",
                "user_id": 16
        }



### GET /me/conversations/:id/members
get info about a conversation

    params
        access_token*     string

    response
        {
          data: [
                    {
                        "username": "me",
                        "user_id": 16,
                        "following": true
                    },
                    {
                        "username": "yogi",
                        "user_id": 17,
                        "following": false
                    }
                ]
        }

### POST /me/conversations/:id/watch_all
watch all unread messages of a conversation or specific types of messages (text, video, or image)

    params
        access_token*     string
        message_types     array of strings       nil => mark all as watched, mark one or more message types as watched i.e. [text], [text, video]

    response
       {
         data: nil
       }

### POST /me/conversations/:id/archive
archive a conversation

     params
         access_token*    string

     response
        {
         data: {
            created_at: "2014-04-29T12:58:02-04:00",
            deleted_at: null,
            id: 7118,
            is_archived: true,
            last_message_at: "2014-04-29T12:58:02-04:00",
            most_recent_subtitle: null,
            most_recent_thumb_url: null,
            name: "Tester Baby",
            user_id: 606,
            unread_count: 0,
            is_deleted: false,
            updated_at: "2014-04-29T12:58:02-04:00"
         }
        }

### POST /me/conversations/:id/follow
follow a conversation

    params
        access_token*   string

    response
        {
            data: nil
        }

### POST /me/conversations/:id/unfollow
unfollow a conversation

    params
        access_token*   string

    response
        {
            data: nil
        }

### GET /me/conversations/:id/messages
Get all of the messages in the conversation (both read and unread)

    params
        access_token*   string

    response
        {
            "data": [
                     {
                         "created_at": "2014-05-12T17:25:32+00:00",
                         "needs_reply": false,
                         "sender_name": "me",
                         "sent_at": "2014-05-12T17:25:32+00:00",
                         "type": "text",
                         "conversation_id": 2,
                         "sender_id": 16,
                         "user": {
                             "name": "me"
                         },
                         "is_deleted": false,
                         "text": {
                             "guid": "aed15239-f042-4458-92ba-162b49e05a0b",
                             "text": "whats up man?"
                         },
                         "is_read": true
                     },
                     {
                         "created_at": "2014-05-11T21:16:17+00:00",
                         "needs_reply": true,
                         "sender_name": "yogi",
                         "sent_at": "2014-05-11T21:16:17+00:00",
                         "type": "text",
                         "conversation_id": 2,
                         "sender_id": 17,
                         "user": {
                             "name": "yogi"
                         },
                         "is_deleted": false,
                         "text": {
                             "guid": "afd15239-f042-4458-92ba-162b49e05a0b",
                             "text": "Yea. I've seen it..really good movie"
                         },
                         "is_read": false
                     }
                 ]
        }

## Invites

### POST /me/invites
explicit invites endpoint through add friends

    params
        access_token*
        invites*    array of emails and phones

    response
        data: nil

### POST /me/invites/confirm
a confirmation endpoint for when a user sends a text

    params
        access_token*
        invites*    array of phones

    response
        data: nil



TODO
----
- install graphite/statsd to start measuring performance and monitor server activity