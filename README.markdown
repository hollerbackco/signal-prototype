API
===

1. Main web api;
2. Sidekiq background workers;
3. Poller services listens to video-stitch-ready sqs queue. Marks stitched; videos as complete.

Design Principles and Resources
-------------------------------

http://www.12factor.net/
http://dl.dropboxusercontent.com/u/1579953/talks/modern_architecture.pdf

- logs as first class citizens
- long running tasks on jobs queue


Server
------
production server is located at http://www.hollerback.co/api/
dev server is located at http://lit-sea-1934.herokuapp.com/api/


Dependencies
------------
Only runs on postgres. Installing postgres:
http://www.moncefbelyamani.com/how-to-install-postgresql-on-a-mac-with-homebrew-and-lunchy/


Installing Locally
------------------

    bundle install
    createdb hollerback_dev
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
        },
        "pagination": {
            "next_url": "...",
            "next_max_id": "13872296"
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
          data: [{
              type: "conversation",
              sync: {
                  id: 1,
                  name: "Jeff",
                  unread_count: 2,
                  is_deleted: false,
                  most_recent_thumb_url: "http://url",
                  most_recent_subtitle: "hello",
                  last_message_at: timestamp
              }
          },{
              type: "message",
              sync: {
                  guid: "aldsfkj-asdfkj-sdf",
                  conversation_id: 12,
                  url: "http://url",
                  thumb_url: "http://thumburl",
                  subtitle: "hello",
                  sent_at: timestamp,
                  created_at: timestamp
                  sender_name: "Sender Name",
                  needs_reply: true
              }
          }]
      }


## CONVERSATIONS

### POST /me/conversations
create a conversation

    params
        access_token*     string
        invites*          array of phone numbers
        part_urls*        array of part urls

    response
        {
          data: {
            id: 1,
            unread_count: 10,
            members: [list of users],
            invites: [{phone: "+18885558888"}],
            videos: [{
              isRead: false,
              id: 1,
              created_at: timestamp,
              url: "http://url",
              meta: {}
            }]
          }
        }


### POST /me/conversations/:id/videos/parts
Creates a video stitch request, marks videos as read.

    params
        access_token*      string
        urls**             string     send a url location of the file
        part_urls**        string     bucket/key
        subtitle           string
        watched_ids        array of strings

    response
        {
          data: {
            guid: "asfd,
          }
        }

### GET /me/conversations/:id/members
get info about a conversation

    params
        access_token*     string

    response
        {
          data: [list of users]
        }

### POST /me/conversations/:id/goodbye

    params
        dwatched_id*       string
      
    response
        {
          data: nil
        }


### POST /me/conversations/:id/leave
get info about a conversation

    params
        access_token*     string

    response
        {
          data: nil
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

## DEPRECATED

### GET /me/conversations
list of conversations

    params
        access_token*     string

    response
        {
          data: [{
            unread_count: 10,
            members: [list of users],
            invites: [{phone: "+18885558888"}],
            videos: [{
              isRead: false,
              id: 1,
              created_at: timestamp,
              url: "http://url",
              meta: {}
            }]
          }]
        }



### POST /me/videos/:id/read
mark a video as read

    params
        access_token*     string

    response
        {
          data: {
            conversation_id: 1,
            id: 18,
            created_at: timestamp,
            isRead: true,
            user: {..},
            url: ""
          }
        }

TODO
----
- install graphite/statsd to start measuring performance and monitor server activity
