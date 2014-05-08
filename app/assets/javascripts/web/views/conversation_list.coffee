class window.ConversationListView extends Backbone.View
  initialize: ->
    @subviews = []
    @render()

  render: ->
    console.log @model.models
    @model.forEach (conversation) =>
      console.log conversation
      subview = new ConversationItemView(model: conversation)
      @subviews.push subview
      @$el.append subview.$el
