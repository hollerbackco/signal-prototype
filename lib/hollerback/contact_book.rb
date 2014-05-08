module Hollerback
  class ContactBook
    attr_accessor :user, :contacts, :contact_ids

    def initialize(user)
      @user = user
      @contacts = user.contacts
      @contact_ids = []
    end

    def update(contact_objs=[])
      Upsert.batch(Contact.connection, Contact.table_name) do |upsert|
        contact_objs.each do |obj|
          upsert.row({user_id: user.id, phone_hashed: obj["phone"]}, name: obj['name'][0..254], created_at: Time.now, updated_at: Time.now)
        end
      end
      self.contact_ids = get_contacts_from_phone(contact_objs.map {|obj| obj["phone"]}).map(&:id)
    end

    def contacts_on_hollerback
      contacts = Contact.joins(:aliased_user)
        .includes(:aliased_user)
        .where("contacts.user_id = ?", user.id)
        .where("users.id != ?", user.id)

      if contact_ids.any?
        contacts = contacts.where("contacts.id" => self.contact_ids)
      end

      contacts
    end

    private

    def get_contacts_from_phone(phones=[])
      Contact.where(user_id: user.id, phone_hashed: phones)
    end
  end
end
