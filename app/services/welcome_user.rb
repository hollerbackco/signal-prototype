class WelcomeUser
  attr_accessor :user

  def initialize(user, will=nil)
    @user = user
    @will = will
  end

  def run
    filename = "batch/welcome.mp4"
    send_video_to_user(filename, user)
  end

  def send_video_to_user(filename, user)
    return unless will_user
    conversation = user.conversations.create
    conversation.name = "Will from Signal"
    conversation.members << will_user
    conversation.save
    membership = Membership.where(conversation_id: conversation.id, user_id: will_user.id).first

    publisher = ContentPublisher.new(membership)

    video = conversation.videos.create({
      user: will_user,
      filename: filename
    })

    publisher.publish(video, {
      needs_reply: true,
      is_reply: false
    })
  end

  def will_user
    @will ||= User.find_by_username("will")
  end
end
