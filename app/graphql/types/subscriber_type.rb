module Types
  class SubscriberType < Types::BaseObject
    description "A newsletter subscriber"

    field :id, ID, null: false
    field :email, String, null: false
    field :name, String, null: true
    field :status, String, null: false
    field :source, String, null: true
    field :tags, [String], null: true
    field :lists, [String], null: true
    field :confirmed_at, GraphQL::Types::ISO8601DateTime, null: true
    field :unsubscribed_at, GraphQL::Types::ISO8601DateTime, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    
    # Check if can receive emails
    field :can_receive_emails, Boolean, null: false
    
    def can_receive_emails
      object.can_receive_emails?
    end
  end
end




