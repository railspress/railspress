module Types
  class MutationType < Types::BaseObject
    description "The mutation root of the RailsPress GraphQL API"
    
    # Example mutations - can be expanded
    # TODO: Add full CRUD mutations for posts, pages, comments, etc.
    
    field :test_field, String, null: false do
      description "An example field added by the generator"
    end

    def test_field
      "Hello World from RailsPress GraphQL!"
    end
  end
end






