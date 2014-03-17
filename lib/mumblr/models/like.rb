module Mumblr
  class Like < Model
    include DataMapper::Resource

    property :id, Serial

    belongs_to :blog
    belongs_to :post
  end
end
