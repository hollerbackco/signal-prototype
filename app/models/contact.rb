class Contact < ActiveRecord::Base
  belongs_to :user
  belongs_to :aliased_user, class_name: "User",
    primary_key: "phone_hashed", foreign_key: "phone_hashed"

  delegate :username, to: :aliased_user #the delegate will delegate the invokation of the :username symbol to the aliased_user

  def as_json(options={})
    options = options.merge(:only => [:name, :created_at, :phone_hashed])
    options = options.merge(:methods => [:username])
    super(options)
  end
end
