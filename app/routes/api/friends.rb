module SignalApp
  class ApiApp < BaseApp

    helpers do
      def friend_objects_for_user(friendships, user)
        friendships.map do |friendship|
          friend = friendship.friend
          {
            id: friend.id,
            username: friend.username,
            name: friend.also_known_as(for: user),
            last_sent_at: friendship.updated_at
          }
        end
      end
    end

    post '/me/users/search' do
      user = User.find_by_username(params[:username].downcase)

      if user
        success_json data: {id: user.id, username: user.username}
      else
        success_json data: nil
      end
    end

    get '/me/friends/unadded' do
      success_json data: current_user.unadded_friends.map {|user| {id: user.id, username: user.username}}
    end

    get '/me/friends' do
      recent_friendships = current_user.friendships.order("updated_at DESC").limit(3)
      friendships = current_user.friendships

      data = {
        recent_friends: friend_objects_for_user(recent_friendships, current_user),
        friends: friend_objects_for_user(friendships, current_user)
      }

      success_json data: data.as_json
    end

    post '/me/friends/add' do
      if usernames = params[:username] and usernames.is_a? String
        usernames = [params[:username]]
      end

      friends = User.where(:username => usernames)
      if friends.any?
        friendships = friends.map do |friend|
          current_user.friendships.where(friend_id: friend.id).first_or_create
        end

        success_json data: friend_objects_for_user(friendships, current_user)
      else
        success_json data: []
      end
    end

    post '/me/friends/remove' do
      if usernames = params[:username] and usernames.is_a? String
        usernames = [params[:username]]
      end

      friends = User.where(:username => usernames)
      if friends.any?
        friends.each do |friend|
          friendship = current_user.friendships.where(friend_id: friend.id).first
          friendship and friendship.destroy
        end

        success_json data: nil
      else
        success_json data: []
      end
    end
  end
end
