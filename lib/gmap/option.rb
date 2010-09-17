# -*- coding: utf-8 -*-

require 'optparse'

module Gmap
  module Option
    extend self

    class InvalidOptionError < StandardError; end

    def parse_option(argv)
      argv = argv.dup
      opts = {}

      # generate option parser
      parser = OptionParser.new do |parser|
        parser.banner = "usage: #{$0} [options] input_file(s)"

        # dry_run
        parser.on("-d", "[optional] show what commands would have been executed.") do
          opts["dry_run"] = true
        end

        # genome_index
        parser.on("-g GENOME_INDEX", String,
          "[required] the genome index name to be searched.") do |v|
          opts["genome_index"] = v
        end

        # chromosome number
        parser.on("-n NUMBER", String,
          "[optional] the chromosome id to be searched.  e.g. 1-19,X,Y") do |v|
          opts["chrnum"] = v
        end

        # output_dir
        parser.on("-o OUTPUT_DIR", String,
          "[optional] the name of the directory in which gmap will write all of its output.") do |v|
          opts["output_dir"] = v
        end

        # threads
        parser.on("-p THREADS", Integer,
          "[optional] the number of threads per one job.") do |v|
          opts["threads"] = v
        end

        # queue
        parser.on("-q QUEUE", String,
          "[optional] the job queue that jobs are submitted.") do |v|
          opts["queue"] = v
        end

        # tool_name
        parser.on("-t TOOL_NAME", String,
          "[required] mapping tools to be used (tophat, bowtie, soap2).") do |v|
          opts["tool"] = v
        end

        # help
        parser.on_tail('-h', '--help', '[optional] display this help and exit.') do
          opts["help"] = parser.to_s
        end
      end

      begin
        parser.parse!(argv)
      rescue OptionParser::InvalidOption, OptionParser::InvalidArgument
        raise InvalidOptionError, $!.to_s
      end

      # other arguments are input file names
      opts["input_files"] = argv

      opts
    end
  end
end
