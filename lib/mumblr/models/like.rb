module Mumblr
  # Represents a post liked by a blog
  class Like < Model
    include DataMapper::Resource

    property :id, Serial

    belongs_to :blog
    belongs_to :post

    MAX_LIKES = 100

    def self.retrieve_from_blog(blog, tumblr_params)
      tumblr_params[:offset] = 0
      if tumblr_params[:count]
        @wanted_count = tumblr_params[:count]
      else
        @wanted_count = MAX_LIKES
      end

      unless @raw_likes
        @raw_likes = []
        loop do
          STDERR.puts "So far we have #{@raw_likes.length}"
          tumblr_params[:offset] = @raw_likes.length
          likes_res = client.blog_likes(blog.name, tumblr_params)
          # Extremely confusing:
          # If you request x number per page, and you're not on the last page,
          # you will still receive fewer than x results if some of
          # the results have been removed by the tumblr staff.
          Model::logger.debug "Just got #{likes_res['liked_posts'].length} more"
          break if likes_res['liked_posts'].length == 0
          @raw_likes += likes_res['liked_posts']
          total_likes = likes_res['liked_count'].to_i
          Model::logger.debug "There are a total of: #{total_likes}"

          # Stop if we have all the posts
          break if @raw_likes.count >= total_likes

          # Stop if we have as many as we want
          break if @raw_posts.count >= @wanted_count
        end
      end

      Model::logger.debug "Got #{@raw_posts.count} likes"

      @raw_likes.each do |post_hash|
        # Reference the post being liked
        post = Post.from_api(post_hash, blog)
        # Extract its contents
        PostContent.api_extract_from_post(post, post_hash)
        # Link the liking blog with the post
        first_or_create({post_id: post.id,
                          blog_id: blog.id})
      end
      blog.likes
    end # self.retrieve_from_blog


  end
end
