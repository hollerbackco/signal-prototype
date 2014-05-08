class Pledger < ActiveRecord::Base
  acts_as_nested_set

  START_OFFSET = 100000
  BASE = 36

  attr_accessible :access_token, :access_secret, :name, :username, :parent_id
  serialize :meta

  def share_code
    username
  end

  def total_count
    entries_count + friends.count + friends_of_friends.count
  end

  def entries_count
    1
  end

  def friends
    children
  end

  def friends_of_friends
    Pledger.where(:parent_id => friends)
  end
end
