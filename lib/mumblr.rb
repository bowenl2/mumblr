require "mumblr/version"
require "tumblr_client"
require "pry"
require "open-uri"
require "progressbar"

class Mumblr
  def initialize(base_hostname)
    @base_hostname = base_hostname
    @dest_base = File.expand_path('~/mumblr-data')
    populate_filecache
    normalize_base_hostname
  end

  # TODO
  def populate_filecache
    # Crawl everything in @dest_base
  end

  def download(file_url, username, origin=nil)
    dest_path = File.join(@dest_base, username, origin)
    FileUtils.mkdir_p(dest_path) unless File.exists?(dest_path)
    dest_path = File.join(dest_path, File.basename(file_url))
    # TODO Check for cache
    if File.exists?(dest_path)
      STDERR.puts("Skipping #{dest_path} (exists)")
      return
    end
    pbar = nil
    begin
      open(dest_path, 'wb') do |dest_file|
        open(file_url,
             content_length_proc: lambda {|t|
               if t && 0 < t
                 pbar = ProgressBar.new("...", t)
                 pbar.file_transfer_mode
               end
             },
             progress_proc: lambda {|s|
               pbar.set s if pbar
             }) do |f|
          IO.copy_stream(f, dest_file)
        end
      end
    rescue
      STDERR.puts("error with #{file_url}")
    end
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
    tumblr_params = {
      offset: 0,
      limit: 20
    }
    unless @raw_likes
      @raw_likes = []
      loop do
        STDERR.puts "So far wehave #{@raw_likes.length}"
        tumblr_params[:offset] = @raw_likes.length
        likes_res = client.blog_likes(@base_hostname, tumblr_params)
        # The counts of total_likes are actually inaccurate.
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
    if match = /(?:http:\/\/)(?<bhn>(?!www).+)\.tumblr\.com/.match(@base_hostname) or match = /(?:http:\/\/)(?<bhn>)(?:\/)/.match(@base_hostname)
      @base_hostname = match['bhn']
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
