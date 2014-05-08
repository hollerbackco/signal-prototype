module HollerbackApp
  class ApiApp < BaseApp
    get '/me/sync' do
      last_sync_at = Time.now
      updated_at = Time.parse(params[:updated_at]) if params[:updated_at]
      before_last_message_at = Time.parse(params[:before_last_message_at]) if params[:before_last_message_at]


      user_agent = Hollerback::UserAgent.new(request.user_agent)
      count = params[:count] #HollerbackApp::IOS_MAX_SYNC_OBJECTS if user_agent.ios? && @app_version &&  GEM::RUBY_VERSION.new(@app_version) >  GEM::RUBY_VERSION.new('1.1.5')

      sync_objects = []

      #get the memberships
      memberships, ids = Membership.sync_objects(user: current_user, since: updated_at, before: before_last_message_at, count: count, :api_version => @api_version)
      sync_objects = sync_objects.concat(memberships);

      #get the messages associated with these memberships
      sync_objects = sync_objects.concat(Message.sync_objects(user: current_user, since: updated_at, before: before_last_message_at, membership_ids: ids, api_version: @api_version))

      #the following operation is a very long running query
      ConversationRead.perform_async(current_user.id)

      data = success_json(
        meta: {
          last_sync_at: last_sync_at
        },
        data: sync_objects.as_json
      )
      data
    end
  end
end
