# -*- coding: utf-8 -*-

require 'yaml'

module Gmap
  module Config
    extend self

    def load
      config_file_name = ".gmap"

      current_dir = Dir.getwd
      config_path = "#{current_dir}/#{config_file_name}"

      if File.exists?(config_path)
        # load current_dir/.gmap
        YAML.load_file(config_path)
      else
        # load $HOME/.gmap
        home_dir = File.expand_path("~")
        config_path = "#{home_dir}/#{config_file_name}"
        YAML.load_file(config_path)
      end
    end
  end
end
