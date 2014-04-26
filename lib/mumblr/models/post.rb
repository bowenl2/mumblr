
module Mumblr
  class Post < Model
    include DataMapper::Resource

    property :id, Serial
    property :tumblr_id, String
    property :url, String
    property :type, String
    property :timestamp, Integer
    property :reblog_key, String

    belongs_to :blog
    has n, :post_contents


    MAX_POSTS = 500 # to retrieve per blog

    #######################
    # API Utility methods #
    #######################
    def self.retrieve_from_blog(blog, options={})
      Model::logger.debug "Requested contents of #{blog.name}"
      unless @raw_posts
        Model::logger.debug "Retrieving from API..."
        @raw_posts = []
        # FIXME should retrieve from oldest->newest for caching reasons
        loop do
          options[:offset] = @raw_posts.count
          Model::logger.debug "Retrieving 20 from offset: #{@raw_posts.count}"
          @response = Model.client.posts(blog.name, options)
          @post_count = @response['blog']['posts'].to_i
          Model::logger.debug "\tPost count:#{@post_count}"
          posts = @response['posts']
          if posts.length == 0
            Model::logger.warn "Retrieved zero posts when asking for 20"
            break
          end
          @raw_posts += posts
          break if @raw_posts.count >= MAX_POSTS or @raw_posts.count >= @post_count
        end
        @raw_posts.each do |post_hash|
          post = from_api(post_hash, blog)
          PostContent.api_extract_from_post(post, post_hash)
        end
      end

    end

    def self.from_api(post_hash, blog)
      Model::logger.debug("Creating post from tumblr_id: #{post_hash['id']}")
      begin
        first_or_create({tumblr_id: post_hash['id']}, {
                          blog_id: blog.id,
                          #blog: Blog.first(name: post_hash['blog_name']),
                          url: post_hash['post_url'],
                          type: post_hash['type'],
                          timestamp: post_hash['timestamp'],
                          reblog_key: post_hash['reblog_key']
                        })
      rescue DataMapper::SaveFailureError => e
        binding.pry
      end
    end
  end
end
