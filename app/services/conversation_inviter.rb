module Signal
  class ConversationInviter
    attr_accessor :inviter, :conversation, :usernames, :phones, :name

    def initialize(user, numbers, usernames, name=nil)
      self.inviter = user
      self.phones = numbers || []
      self.usernames = usernames || []
      self.name = name
    end

    def invite
      #if self.conversation = fetch_conversation_if_exists
        #return true
      #end

      success = Conversation.transaction do
        self.conversation = create_conversation

        usernames.each do |username|
          if user = User.find_by_username(username)
            next if conversation.members.exists?(user)
            conversation.members << user #creates the membership
            if friendship = inviter.friendships.where(:friend_id => user.id).first
              friendship.touch
            end
          end
        end

        actual_invites = [] #used for analytics: phones that were actually new invites
        parsed_phones.each do |phone|
          if users = User.where(phone_normalized: phone) and users.any?
            user = users.first
            next if conversation.members.exists?(user)
            conversation.members << user
          else

            unless Invite.where(phone: phone).any?
              actual_invites << phone    #great this is a first time invite
            end

            invite = Invite.create(
              phone: phone,
              inviter: inviter,
              conversation: conversation,
              cohort: inviter.cohort
            )

            #let's schedule a reminder in 24hrsi
            if REDIS.get("app:copy:invite_reminder_flag") == "true"
              InviteReminder.perform_in(24.hours, invite.id)
            end
          end
        end
        if inviter_membership.auto_generated_name != name
          conversation.name = name
          conversation.save
        end

        #TODO: Notify Recipients
        memberships = Membership.where(:conversation_id => conversation.id, :following => false)
        NotifyRecipients.on_new_conversation(memberships, inviter)

        p "actual invites: " + actual_invites.to_s
        run_analytics(actual_invites)
      end
    end

    def parsed_phones
      self.phones.map do |phone|
        Phoner::Phone.parse(phone, country_code: inviter.phone_country_code, area_code: inviter.phone_area_code).to_s
      end.compact.uniq
    end

    def self.parse(user, numbers)
      numbers.map do |phone|
        Phoner::Phone.parse(phone, country_code: user.phone_country_code, area_code: user.phone_area_code).to_s
      end.compact
    end

    def errors
      conversation.errors
    end

    def inviter_membership
      membership = inviter.memberships.find(:first, conditions: {conversation_id: conversation.id})
    end

    private

    # TODO: too slow.
    # one idea is to do a md5 checksum on the conversation phone numbers
    # returns nil if no conversation exists
    def fetch_conversation_if_exists
      # all members phone numbers should be included to do a proper lookup
      numbers = parsed_phones + [inviter.phone_normalized]
      inviter.conversations.find_by_phones(numbers).first
    end

    def create_conversation
      conversation = Conversation.create(creator: inviter)

      #creates a membership
      conversation.members << inviter

      membership = inviter.memberships.find(:first, conditions: {conversation_id: conversation.id})
      membership.following = true #as the creator follow the membership
      membership.save

      conversation
    end

    def run_analytics(actual_invites)
      ConversationCreate.perform_async(inviter.id, conversation.id, phones, actual_invites)
    end
  end
end
