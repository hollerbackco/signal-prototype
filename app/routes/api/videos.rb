module HollerbackApp
  class ApiApp < BaseApp
    get '/me/conversations/:conversation_id/videos' do
      begin
        ConversationRead.perform_async(current_user.id)
        membership = current_user.memberships.find(params[:conversation_id])

        messages = membership.messages.watchable.seen.where(:message_type => Message::Type::VIDEO).order("created_at DESC").scoped

        if params[:page]
          messages = messages.paginate(:page => params[:page], :per_page => (params[:perPage] || 10))
          last_page = messages.current_page == messages.total_pages
        end

        success_json({
                         data: messages.as_json,
                         meta: {
                             last_page: last_page
                         }
                     })
      rescue ActiveRecord::RecordNotFound
        not_found
      end
    end

    get '/me/conversations/:conversation_id/history' do
      begin
        ConversationRead.perform_async(current_user.id)
        membership = current_user.memberships.find(params[:conversation_id])

        messages = membership.messages.seen.where(:message_type => Message::Type::VIDEO).scoped

        if params[:page]
          messages = messages.paginate(:page => params[:page], :per_page => (params[:perPage] || 10))
          last_page = messages.current_page == messages.total_pages
        end

        begin
          Message.set_message_display_info(messages, @api_version)
        rescue Exception => e
          logger.error e
        end


        success_json({
                         data: messages.as_json,
                         meta: {
                             last_page: last_page
                         }
                     })
      rescue ActiveRecord::RecordNotFound
        not_found
      end
    end

    post '/me/videos/:id/read' do
      messages = current_user.messages.all_by_guid(params[:id])
      if messages.any?
        messages.each(&:seen!)
        VideoRead.perform_async(messages.map(&:id), current_user.id)
      end
      success_json data: messages.first.as_json
    end


    post '/me/conversations/:id/videos' do
      if !ensure_params(:filename)
        return error_json 400, msg: "missing filename param"
      end

      begin
        # the id sent in the url is a reference to the users meembership model
        membership = current_user.memberships.find(params[:id])
        conversation = membership.conversation

        # generate the piece of content
        video = Video.new(
            user: current_user,
            conversation: conversation,
            filename: params[:filename]
        )

        if video.save
          publisher = ContentPublisher.new(membership)
          publisher.publish(video)

          success_json data: publisher.sender_message.as_json
        else
          error_json 400, for: video
        end

      rescue ActiveRecord::RecordNotFound
        not_found
      end
    end
  end
end
