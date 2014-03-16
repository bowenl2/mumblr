require "mumblr/version"
require "tumblr_client"
require "pry"
require "open-uri"
require "progressbar"

module Mumblr
  def load_database(connection_string)
    model_glob = File.join(File.dirname(__FILE__), "mumblr/models/**.rb")
    Dir[model_glob].each { |model| require model }
    DataMapper.setup(:default, connection_string)
  end

  def normalize_base_hostname
    if match = /(?:http:\/\/)(?<bhn>(?!www).+)\.tumblr\.com/.match(@base_hostname) or match = /(?:http:\/\/)(?<bhn>)(?:\/)/.match(@base_hostname)
      match['bhn']
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
