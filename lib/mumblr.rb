require "mumblr/version"
require "tumblr_client"

module Mumblr
  def base_hostname(input)

  end

  # options:
  #
  # types: array of: text, quote, link, answer, video, audio, photo, chat
  # after_time:
  # before_time:
  # count:
  def posts_content(blog, options={})
    blog_posts_hash = client.posts(blog)
    posts_hash = blog_posts_hash['posts']
    extract_from_posts(posts_hash)
  end

  def blog_likes_content(blog, options={})

  end

  def extract_from_posts(posts_hash)
    posts_hash.each do |post_hash|
      # TODO: Unnecessary metaprogramming
      post_type = post_hash['type'].to_sym
      case post_type
      when :photo
        extract_photos post_hash
      when :video
        extract_videos post_hash
      else
        throw StandardError, "Unhandled post type: #{post_type}"
      end
    end
  end

  def extract_photos(post_hash)
    post_hash['photos'].each do |photo|
      puts photo['original_size']['url']
    end
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
