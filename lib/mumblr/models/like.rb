module Mumblr
  # Represents a post liked by a blog
  class Like < Model
    include DataMapper::Resource

    property :id, Serial

    belongs_to :blog
    belongs_to :post

    def retrieve_from_blog(blog)
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

    end
  end
end
