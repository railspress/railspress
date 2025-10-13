module Types
  class SearchResultsType < Types::BaseObject
    description "Search results across posts and pages"
    
    field :posts, [Types::PostType], null: false
    field :pages, [Types::PageType], null: false
    field :total, Integer, null: false
  end
end





