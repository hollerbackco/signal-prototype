#= require '../models/conversation'
class window.Conversations extends Backbone.Collection
  model: Conversation
  url: "/api/me/conversations?access_token=Lx3w35OdtGxXBUx6kzrZyJoEmQ3NyYY3RVjNDZWEjnOGY0Z7oekyzQ00"
  initialize: ->

  parse: (response) ->
    response.data.conversations

