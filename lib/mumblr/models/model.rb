require "data_mapper"
require "logger"

module Mumblr
  class Model
    def self.normalize_base_hostname(base_hostname)
      if match = /(?:http:\/\/)?(?<bhn>(?!www).+)\.tumblr\.com/.match(base_hostname) or match = /(?:http:\/\/)(?<bhn>)(?:\/)/.match(base_hostname)
        match['bhn']
      end
    end

    def self.logger
      unless @logger
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::DEBUG
      end
      @logger
    end

    class << self
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
  end
end
