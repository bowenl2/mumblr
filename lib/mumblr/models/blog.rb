require 'pry'

module Mumblr
  class Blog < Model
    include DataMapper::Resource

    property :id, Serial
    property :url, String
    property :name, String
    property :posts_retrieved_at, DateTime
    property :created_at, DateTime

    has n, :posts
    has n, :likes

    def self.retrieve(base_hostname)
      base_hostname = normalize_base_hostname(base_hostname)
      Model::logger.debug("Resolved blog to base hostname: #{base_hostname}")
      blog = Blog.first_or_create({name: base_hostname},
                           api_hash(base_hostname))
      Model::logger.debug("Got blog: #{blog}")
      blog
    end

    def retrieve_posts(tumblr_params)
      Post.retrieve_from_blog(self, tumblr_params)
      posts
    end

    def retrieve_likes(tumblr_params)
      Like.retrieve_from_blog(self, tumblr_params)
      likes
    end

    def self.api_hash(name)
      Model::logger.debug("Retrieving from API for hostname: #{name}")
      api_hash = Model.client.blog_info(name)
      {
        url: api_hash['blog']['url'],
        name: api_hash['blog']['name'],
        created_at:  DateTime.now
      }
    end

  end
end
