module Types
  module NodeType
    include Types::BaseInterface
    
    description "An object with an ID"
    
    field :id, ID, null: false, description: "ID of the object"
  end
end





