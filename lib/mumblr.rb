require "mumblr/version"
require "tumblr_client"
require "pry"

class Mumblr
  def initialize(base_hostname)
    @base_hostname = base_hostname
  end

  # options:
  #
  # types: array of: text, quote, link, answer, video, audio, photo, chat
  # after_time:
  # before_time:
  # count:
  def blog_content(options={})
    unless @raw_posts
      @raw_posts = client.posts(@base_hostname, options)
    end

    extract_from_posts(@raw_posts['posts'])
  end

  def blog_likes_content(options={})
    unless @raw_likes
      count_needed = options[:count]
      @raw_likes = []
      loop do
        # TODO add offset to options
        likes_res = client.blog_likes(@base_hostname, options)
        @raw_likes += likes_res[''] # todo what key
        if @raw_likes.length >= likes_res['total_posts'].to_i
          break
        end
      end
    end

    extract_from_posts(@raw_likes['liked_posts'])
  end

  private

  def extract_from_posts(posts_hash)
    posts_hash.flat_map do |post_hash|
      # TODO: Unnecessary metaprogramming
      post_type = post_hash['type'].to_sym
      case post_type
      when :photo
        extract_photos post_hash
      when :video
        extract_videos post_hash
      else
        STDERR.puts("\tSkipping post type: #{post_type}")
      end
    end
  end

  def extract_photos(post_hash)
    post_hash['photos'].map { |photo| photo['original_size']['url'] }
  end

  def extract_videos(post_hash)
    post_hash['video_url']
  end

  def normalize_base_hostname

  end

  def client
    unless @client
      Tumblr.configure do |config|
        config.consumer_key = ENV['MUMBLR_API_KEY']
        config.consumer_secret = ENV['MUMBLR_API_SECRET']
      end
      @client = Tumblr::Client.new
    end
    @client
  end
end
