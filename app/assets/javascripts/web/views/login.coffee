class window.LoginView extends Backbone.View
  initialize: ->
    @conversation = new Conversations()
    @conversation.fetch()
