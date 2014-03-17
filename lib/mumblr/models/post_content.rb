module Mumblr
  class PostContent < Model
    include DataMapper::Resource

    property :id, Serial
    property :url, String
    property :retrieved_at, DateTime

    belongs_to :post

    ###############
    # API Methods #
    ###############
    def self.api_extract_from_post(post, post_hash)
      post_type = post_hash['type'].to_sym
      Model::logger.debug("Extracting content URLs from type: #{post_type}")
      case post_type
      when :photo
        api_extract_photos post, post_hash
      when :video
        api_extract_videos post, post_hash
      else
        Model::logger.debug("\tSkipping post type: #{post_type}")
      end
    end

    def self.api_extract_photos(post, post_hash)
      post_hash['photos'].each do |photo|
        first_or_create({url: photo['original_size']['url'] }, {
                           post_id: post.id
                        })
      end
    end

    def self.api_extract_videos(post, post_hash)
      first_or_create({ url: post_hash['video_url'] }, {
                         post_id: post.id
                       })
    end

    # TODO Refactor this so the callbacks can be passed in
    # origin: 'like' or nil
    def download(directory, origin=nil)
      dest_path = File.join(directory, post.blog.name, origin)
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

  end
end
