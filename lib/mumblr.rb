require "mumblr/version"
require "tumblr_client"
require "pry"
require "open-uri"
require "progressbar"
require "data_mapper"

module Mumblr
  class Mumblr
    def self.load_database(db_path)
      DataMapper::Model.raise_on_save_failure = true
      DataMapper::Property::String.length(255)
      connection_string = "sqlite://#{db_path}"
      require 'mumblr/models/model'
      model_glob = File.join(File.dirname(__FILE__), "mumblr/models/**.rb")
      Dir[model_glob].each { |model| require model }
      DataMapper.setup(:default, connection_string)
      DataMapper.finalize
      #unless File.exists?(db_path)
      DataMapper.auto_upgrade!
      #end
    end
  end
end
