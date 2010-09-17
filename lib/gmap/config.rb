# -*- coding: utf-8 -*-

module Gmap
  module Config
    extend self

    def load_config
      # open $HOME/.gmap
      home_dir = File.expand_path("~")
      config_path = "#{home_dir}/.gmap"
      YAML.load_file(config_path)
    end
  end
end
