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
      unless url
        Model::logger.warn("Skipping download for #{id} (no URL specified)")
      end
      dest_path = File.join(directory, post.blog.name)
      dest_path = File.join(dest_path, origin) if origin
      FileUtils.mkdir_p(dest_path) unless File.exists?(dest_path)
      dest_path = File.join(dest_path, File.basename(url))
      # TODO Check for cache
      if File.exists?(dest_path)
        STDERR.puts("Skipping #{dest_path} (exists)")
        return
      end
      pbar = nil
      content_length = nil
      begin
        open(dest_path, 'wb') do |dest_file|
          open(url,
               content_length_proc: lambda {|t|
                 content_length = t
                 if t && 0 < t
                   title = File.basename(url)
                   pbar = ProgressBar.new(title, t)
                   pbar.format = "%-15s %3d%% %s %s"
                   pbar.file_transfer_mode
                 end
               },
               progress_proc: lambda {|s|
                 pbar.set s if pbar
                 pbar.finish if pbar and s == content_length
               }) do |f|
            IO.copy_stream(f, dest_file)
            retrieved_at = DateTime.now
            save
            full_dest = File.expand_path(dest_path)
            STDERR.puts("file://#{full_dest}")
          end
        end
        retrieved_at = DateTime.now
      rescue
        STDERR.puts("error with #{url}")
      end
    end

  end
end
