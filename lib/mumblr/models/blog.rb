
module Mumblr
  class Blog < Model
    include DataMapper::Resource

    property :id, Serial
    property :name, String
    property :created_at, DateTime

    has n, :posts
    has n, :likes

    def self.retrieve(name)
      unless blog = self.first(name: name)

      end
      blog
    end

    def self.api_from_blog(base_hostname)

    end

    def posts_contents(options={})
      unless @raw_posts
        @raw_posts = []
        loop do
          options[:offset] = @raw_posts.count
          @raw_posts += client.posts(@base_hostname, option)
        end
      end
      extract_from_posts(@raw_posts['posts'])
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
