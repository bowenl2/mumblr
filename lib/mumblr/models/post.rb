
module Mumblr
  class Post < Model
    property :id, Serial
    property :url, String
    property :type, String
    property :timestamp, Integer
    property :reblog_key, String
    property :source_url, String
    property :source_title, String

    belongs_to :blog

    #######################
    # API Utility methods #
    #######################

    def api_extract_photos(post_hash)
      # TODO Make these PostContent items
      post_hash['photos'].map { |photo| photo['original_size']['url'] }
    end

    def api_extract_videos(post_hash)
      post_hash['video_url']
    end

    def api_extract_contents(posts_hash)
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

  end
end
