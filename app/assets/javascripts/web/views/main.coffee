class window.MainView extends Backbone.View
  template: HandlebarsTemplates["web/templates/main"]

  initialize: ->
    @conversations = new Conversations()
    promise = @conversations.fetch()

    promise.done =>
      @render()

  render: ->
    @$el.html @template()

    @conversationList = new ConversationListView
      el: @$("#conversation-list")
      model: @conversations


