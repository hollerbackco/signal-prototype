module Signal
  class Statistics
    def initialize
    end

    def conversations_count
      SignalApp::BaseApp.settings.cache.fetch "stat-conversations-count" do
        Conversation.count
      end
    end

    def users_count
      SignalApp::BaseApp.settings.cache.fetch "stat-users-count" do
        User.count
      end
    end

    def videos_sent_count
      SignalApp::BaseApp.settings.cache.fetch "stat-videos-sent" do
        Video.count
      end
    end

    def videos_received_count
      SignalApp::BaseApp.settings.cache.fetch "stat-videos-received" do
        Message.received.watchable.count
      end
    end

    def videos_unread_count
      SignalApp::BaseApp.settings.cache.fetch "stat-videos-unread" do
        Message.unseen.received.count
        #User.all.map{ |u| u.unread_videos.count }.sum
      end
    end

    def memberships_count
      SignalApp::BaseApp.settings.cache.fetch "stat-memberships-sent" do
        Membership.count
      end
    end

    def members_in_conversations_avg
      SignalApp::BaseApp.settings.cache.fetch "stat-avg-members-per-convo-count" do
        if conversations_count > 0
          memberships_count.to_f / conversations_count.to_f
        else
          0
        end
      end
    end

    def videos_in_conversations_avg
      SignalApp::BaseApp.settings.cache.fetch "stat-avg-videos-per-convo-count" do
        if conversations_count > 0
          videos_sent_count.to_f / conversations_count.to_f
        else
          0
        end
      end
    end

    def batch_enqueue(messages)
      video_compute_queue.batch_send(messages)
    end

    def uncache_all
      SignalApp::BaseApp.settings.cache.delete "stat-conversations-count"
      SignalApp::BaseApp.settings.cache.delete "stat-users-count"
      SignalApp::BaseApp.settings.cache.delete "stat-videos-sent"
      SignalApp::BaseApp.settings.cache.delete "stat-videos-unread"
      SignalApp::BaseApp.settings.cache.delete "stat-memberships-sent"
      SignalApp::BaseApp.settings.cache.delete "stat-avg-members-per-convo-count"
      SignalApp::BaseApp.settings.cache.delete "stat-avg-videos-per-convo-count"
      SignalApp::BaseApp.settings.cache.delete "stat-videos-received-count"
    end

    private

    def video_compute_queue
      return @queue if @queue
      @sqs = AWS::SQS.new
      @queue ||= @sqs.queues.create("video-compute")
    end
  end
end
