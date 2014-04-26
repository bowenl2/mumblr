
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
      @wanted_count = options[:count]
      @wanted_count = MAX_POSTS unless @wanted_count and @wanted_count < MAX_POSTS
      unless @raw_posts
        Model::logger.debug "Retrieving from API..."
        @raw_posts = []
        # FIXME should retrieve from oldest->newest for caching reasons
        loop do
          # If we want 50 and have 40 already, only ask for 10
          if @wanted_count and (@raw_posts.count + 20 > @wanted_count)
            options[:limit] = @wanted_count - @raw_posts.count
          # Otherwise ask for the max (20)
          else
            options[:limit] = 20
          end
          options[:offset] = @raw_posts.count
          Model::logger.debug "Retrieving #{options[:limit]} from offset: #{@raw_posts.count}"
          @response = Model.client.posts(blog.name, options)
          @post_count = @response['blog']['posts'].to_i
          Model::logger.debug "\tPost count:#{@post_count}"
          posts = @response['posts']
          if posts.length == 0
            Model::logger.warn "Retrieved zero posts when asking for 20"
            break
          end
          @raw_posts += posts

          # Stop if we have all the posts
          break if @raw_posts.count >= @post_count

          # Stop if we have as many as we want
          break if options[:count] and options[:count] > 0 and @raw_posts.count >= @wanted_count
        end
        Model::logger.debug "Got #{@raw_posts.count} posts"
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
