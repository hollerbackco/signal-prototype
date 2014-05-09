module SignalApp
  class ApiApp < BaseApp
    get '/contacts' do
      contact_book = Signal::ContactBook.new(current_user)
      contacts = contact_book.contacts_on_hollerback

      success_json data: contacts.as_json
    end

    route :get, :post, '/contacts/check' do
      contacts = if params.key? "numbers"
                   numbers = params["numbers"]
                   if numbers.is_a? String
                     numbers = numbers.split(",")
                   end
                   contacts = Signal::ContactChecker.new.find_by_phone(numbers)
                 else
                   unless ensure_params(:c)
                     return error_json 400, msg: "missing required params"
                   end

                   if params.key? "access_token"
                     login(:api_token)

                     TrackUserActive.perform_async(params[:access_token]) #track user active
                     IntercomPublisher.perform_async(current_user.id, IntercomPublisher::Method::UPDATE, request.user_agent, request.ip)

                     contacts = prepare_contacts(params["c"])
                     hashed_numbers = prepare_only_hashed_numbers(params["c"])

                     #UpdateContactBook.perform_async(current_user.id, contacts)
                     contact_book = Signal::ContactBook.new(current_user)
                     contact_book.update(contacts)
                     contacts = contact_book.contacts_on_hollerback
                   else
                     hashed_numbers = prepare_only_hashed_numbers(params["c"])
                     contacts = Signal::ContactChecker.new.find_by_hashed_phone(hashed_numbers)
                   end

                   contacts
                 end

      success_json data: contacts.as_json
    end

    #the invite endpoint where explicit invites that were sent are posted
    #this endpoint creates the invites too
    post '/me/invites' do

      if !ensure_params(:invites)
        return error_json 400, msg: "missing required invites param"
      end

       phones, emails = filter_invites()


        #kick off a sidekiq task and just return to the user immediately
        CreateInvite.perform_async(current_user.id, phones, emails)

      success_json();

    end

    #the invite confirm endpoint that confirms that implicit invites were confirmed
    #this invite only confirms that the invites were made and sent by the user for tracking purposes
    post '/me/invites/confirm' do

      if !ensure_params(:invites)
        return error_json 400, msg: "missing required invites param"
      end

      phones, emails = filter_invites()

      TrackInvites.perform_async(current_user.id, phones)

      success_json();
    end

    def filter_invites()
      invites = params[:invites]

      if (invites.is_a?(String))
        invites = invites.split(",")
      end

      #split phones & emails
      phones = []
      emails = []
      invites.each do |invite|
        if (invite.include?('@'))
          emails << invite
        else
          phones << invite
        end
      end

      #cleanse the phones
      phones = parse_phones(phones, current_user.phone_country_code, current_user.phone_area_code)

      logger.debug invites

      return phones, emails
    end



    helpers do

      def prepare_only_hashed_numbers(contact_params)
        contact_params.map { |c| c["p"].split(",") }.flatten
      end

      def prepare_contacts(contact_params)
        contact_params.map do |c|
          name = c["n"]
          numbers = c["p"].split(",")
          numbers.map do |number|
            {"name" => name, "phone" => number}
          end
        end.flatten
      end
    end
  end
end
