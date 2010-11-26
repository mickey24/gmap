# -*- coding: utf-8 -*-

require 'logger'

module Gmap
  class RunnerBase
    class InvalidOptionError < StandardError; end

    def initialize(log_level = "debug")
      # initialize logger
      raise ArgumentError, "invalid log_level : #{log_level}" unless ["DEBUG", "INFO", "WARN", "ERROR", "FATAL"].include?(log_level.upcase)
      log.level = Logger.const_get(log_level.upcase)
      log.datetime_format = "%Y/%m/%d %H:%M:%S "
    end

    def run(argv)
      log.debug("load config file and parse commandline options")
      config = Utility.get_config(argv)
      log.debug("config : #{config}")

      log.debug("check config validity")
      begin
        # validate config
        validate_config(config)
      rescue
        err = $!
        log.debug($!.inspect)
        log.fatal($!.to_s)
        exit 1
      end
      log.debug("config is valid")

      run_core(config)

      log.info("finish")
    end

    private
    
    def log
      @log ||= Logger.new(STDOUT)
    end

    # virtual methods
    def validate_config(config)
      raise NotImplementedError, "override validate_config(config)"
    end

    def run_core(config)
      raise NotImplementedError, "override run_core(config)"
    end
  end
end
