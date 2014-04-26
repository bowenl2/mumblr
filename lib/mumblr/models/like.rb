module Mumblr
  # Represents a post liked by a blog
  class Like < Model
    include DataMapper::Resource

    property :id, Serial

    belongs_to :blog
    belongs_to :post

    MAX_LIKES = 100

    def self.retrieve_from_blog(blog, tumblr_params)
      api_params = {
        limit: 20,
        offset: 0
      }

      if tumblr_params[:count]
        @wanted_count = tumblr_params[:count]
      else
        @wanted_count = MAX_LIKES
      end

      @raw_likes = []
      found_total = 0
      total_likes = nil

      loop do
        Model::logger.debug "Relevant likes collected: #{@raw_likes.count}"
        # If we want 50 and have 40 already, only ask for 10
        if @wanted_count and (@raw_likes.count + 20 > @wanted_count)
          api_params[:limit] = @wanted_count - @raw_likes.count
        else
          # Otherwise ask for the max (20)
          api_params[:limit] = 20
        end

        api_params[:offset] = found_total

        likes_res = client.blog_likes(blog.name, api_params)

        unless total_likes
          total_likes = likes_res['liked_count'].to_i
          Model::logger.debug "There are a total of: #{total_likes}"
        end
        likes_res_count = likes_res['liked_posts'].count
        found_total += likes_res_count

        Model::logger.debug "Retrieved #{likes_res_count} likes"
        # Filter:
        # We have to do this manually since we can't put in a type
        if tumblr_params[:type]
          likes_res['liked_posts'] = likes_res['liked_posts'].select{|p| p['type'] == tumblr_params[:type]}
          Model::logger.debug "After filtering, we will add #{likes_res['liked_posts'].count} posts"
        end

        # Extremely confusing:
        # If you request x number per page, and you're not on the last page,
        # you will still receive fewer than x results if some of
        # the results have been removed by the tumblr staff.
        # TODO fix that?
        @raw_likes += likes_res['liked_posts']

        # Stop if we have all the posts
        break if found_total >= total_likes

        # Stop if we have as many as we want
        break if @raw_likes.count >= @wanted_count
      end

      Model::logger.debug "Got #{@raw_likes.count} likes"

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
