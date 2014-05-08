class window.ConversationItemView extends Backbone.View
  tagName: "li"
  className: "conversation"
  template: HandlebarsTemplates["web/templates/conversation_item"]
  initialize: ->
    @render()

  render: ->
    @$el.html @template(@model.toJSON())
