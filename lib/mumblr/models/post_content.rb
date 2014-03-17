module Mumblr
  class PostContent < Model
    include DataMapper::Resource

    property :id, Serial
    property :url, String
    property :retrieved_at, DateTime

    belongs_to :post

    # TODO Refactor this so the callbacks can be passed in
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

  end
end
