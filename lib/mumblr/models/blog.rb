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

    def self.retrieve(base_hostname, tumblr_params)
      base_hostname = normalize_base_hostname(base_hostname)
      Model::logger.debug("Resolved blog to base hostname: #{base_hostname}")
      blog = Blog.first_or_create({name: base_hostname}, api_hash(base_hostname))
      Post.retrieve_from_blog(blog, tumblr_params)
      Model::logger.debug("Got blog: #{blog}")
      blog
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

    def self.retrieve_likes(base_hostname, options={})
      base_hostname = normalize_base_hostname(base_hostname)
      Model::logger.debug("")
      blog = Blog.first_or_create({name: base_hostname}, api_hash(base_hostname))
      Post.retrieve_from_blog(blog, tumblr_params)
      Model::logger.debug("Got blog: #{blog}")
      blog
    end

    # options:
    #
    # type: one of: text, quote, link, answer, video, audio, photo, chat
    # after_time:
    # before_time:
    # count:
    def likes_posts_contents(options={})
      tumblr_params = {
        offset: 0,
        limit: 20
      }
      unless @raw_likes
        @raw_likes = []
        loop do
          STDERR.puts "So far we have #{@raw_likes.length}"
          tumblr_params[:offset] = @raw_likes.length
          likes_res = client.blog_likes(@base_hostname, tumblr_params)
          # Extremely confusing:
          # If you request x number per page, and you're not on the last page,
          # you will still receive fewer than x results if some of
          # the results have been removed by the tumblr staff.
          break if likes_res['liked_posts'].length == 0
          STDERR.puts "Just got #{likes_res['liked_posts'].length} more"
          @raw_likes += likes_res['liked_posts']
          total_likes = likes_res['liked_count'].to_i
          STDERR.puts "There are a total of: #{total_likes}"
        end
      end

      url_list = extract_from_posts(@raw_likes)
      url_list.each { |url| download(url, @base_hostname, 'likes') }
    end

  end
end
