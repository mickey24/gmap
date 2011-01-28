# -*- coding: utf-8 -*-

module Gmap
  module Utility
    extend self

    class InvalidConfigError < StandardError; end
    class InvalidChrnumError < StandardError; end

    def get_config(argv)
      config = Config.load
      config.merge(Option.parse(argv))
    end

    def validate_config(config)
      # check tool path
      [ "ruby_path",
        "qsub_path",
      ].each do |key|
        path = config[key]
        raise InvalidConfigError, "config not found: #{key}" unless path
        raise InvalidConfigError, "invalid path: #{key}: #{config[key]}" unless File.executable?(path)
      end

      # check tool name
      tool = config["tool"]
      raise InvalidConfigError, "tool name is not specified" unless tool
      raise InvalidConfigError, "invalid tool name: #{tool}" unless ["tophat", "bowtie", "soap2"].include?(tool)

      # check tool path
      required_tools = {
        "tophat" => ["tophat", "bowtie", "samtools"],
        "bowtie" => ["bowtie"],
        "soap2"  => ["soap2"],
      }
      required_tools[tool].each do |required_tool|
        tool_path_key = "#{required_tool}_path"
        tool_path = config[tool_path_key]
        raise InvalidConfigError, "config not found: #{tool_path_key}" unless tool_path
        raise InvalidConfigError, "invalid path: #{tool_path_key}: #{tool_path}" unless File.executable?(tool_path)
      end

      # check other configs
      [ "jobname_prefix",
        "queue",
        "threads",
        "output_dir",
      ].each do |key|
        raise InvalidConfigError, "config not found: #{key}" unless config[key]
      end

      # check genome_index
      genome_index = config["genome_index"]
      raise InvalidConfigError, "genome index is not specified" unless genome_index

      # check input files
      input_files = config["input_files"]
      raise InvalidConfigError, "input file is not specified" unless input_files && !input_files.empty?

      input_files.each do |input_file|
        raise InvalidConfigError, "file not found: input file: #{input_file}" unless File.exist?(input_file)
      end

      # check genome_config
      genome_config = config["genome_config"]
      raise InvalidConfigError, "config not found: genome_config" unless genome_config

      # check genome_config[genome_index]
      target_genome_config = genome_config[genome_index]
      raise InvalidConfigError, "config not found: #{genome_index} in genome_config" unless target_genome_config
      raise InvalidConfigError, "config not found: genome_path in genome_config[#{genome_index}]" unless target_genome_config["genome_path"]
      raise InvalidConfigError, "config not found: chrnum in genome_config[#{genome_index}]" unless target_genome_config["chrnum"]

      # check genome_path and chrnum are valid
      chrnum = parse_chrnum(config["chrnum"] || target_genome_config["chrnum"])
      chrnum.each do |i|
        genome_path_suffix = {
          "tophat" => ".1.ebwt",
          "bowtie" => ".1.ebwt",
          "soap2"  => ".%s.index.amb",
        }
        one_genome_path_base = target_genome_config["genome_path"] % i

        if !["fa", "fasta", "fna"].any?{|ext| File.exist?("#{one_genome_path_base}#{genome_path_suffix[tool] % ext}")}
          raise InvalidConfigError, "invalid genome path or chrnum: genome index file for chrnum = #{i} not found"
        end
      end

      # check project_config
      project_config = config["project_config"]
      raise InvalidConfigError, "config not found: project_config" unless project_config

      # check project_config[srp] and project_config[srp][tool]
      config["input_files"].each do |input_file|
        srp = get_srp_name(input_file)

        target_project_name = (srp && project_config[srp]) ? srp : "default"
        target_project_config = project_config[target_project_name]
        raise InvalidConfigError, "config not found: #{srp} and default settings in project_config" unless target_project_config

        target_tool_config = target_project_config[tool]
        raise InvalidConfigError, "config not found: #{tool} in project_config[#{target_project_name}]" unless target_tool_config
      end

      true
    end

    def parse_chrnum(str)
      raise InvalidChrnumError, "empty string" unless !str.empty?
      raise InvalidChrnumError, "invalid chrnum format: #{str}" unless str[-1].chr != ","

      str.split(",").map {|s|
        raise InvalidChrnumError, "invalid chrnum format: #{str}" unless !s.empty?
        raise InvalidChrnumError, "invalid chrnum format: #{str}" unless /\A(?:[0-9]+(?:-[0-9]+)?|[A-Za-z]+(?:-[A-Za-z]+)?)\Z/ =~ s

        if s.include?("-")
          pair = s.split("-")
          first, last = pair[0], pair[1]
          raise InvalidChrnumError, "range: #{str} is descending order" unless first < last

          (first..last).to_a
        else
          s
        end
      }.flatten
    end

    def get_srp_name(path)
      # extract SRPxxxx from the absolute path
      if %r!/(SRP\d+)(?:/|\Z)! =~ File.expand_path(path)
        $1
      else
        nil
      end
    end

    def get_srp_srx_srr_path(path)
      # extract SRPxxxx/SRXxxxx/SRRxxxx from the absolute path
      if %r!/(SRP\d+/SRX\d+/SRR\d+)(?:_1)?\.f(?:ast)?[aq]\Z! =~ File.expand_path(path)
        $1
      else
        nil
      end
    end

    def get_output_dir(config, path)
      # if input_file path includes SRPxxxx/SRXxxxx/SRRxxxx, then
      # try to create dir like input_file path under the output directory
      srp_srx_srr_path = get_srp_srx_srr_path(path)
      output_dir = nil

      # check whether output_dir is specified or not
      if config["output_dir"]
        if srp_srx_srr_path
          output_dir = "#{config["output_dir"]}/#{srp_srx_srr_path}"
        else
          output_dir = "#{config["output_dir"]}/#{File.basename(path, '.*')}"
        end
      else
        if srp_srx_srr_path
          output_dir = "result/#{srp_srx_srr_path}"
        else
          output_dir = "result/#{File.basename(path, '.*')}"
        end
      end

      output_dir
    end

    def get_mate_pair_file_name(path)
      # check and return the mate pair file name if exists
      if /(.*)_1(\.f(?:ast)?[aq])\Z/ =~ path
        mate_pair = "#{$1}_2#{$2}"
        File.file?(mate_pair) ? mate_pair : nil
      else
        nil
      end
    end

    def create_directories(dir, mode = nil)
      # create target and its intermediate directories at once
      if !File.exist?(dir)
        if mode
          system "/bin/mkdir -p #{dir} -m #{mode}"
        else
          system "/bin/mkdir -p #{dir}"
        end
        true
      else
        false
      end
    end
  end
end
