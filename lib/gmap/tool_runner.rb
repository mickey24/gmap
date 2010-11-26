# -*- coding: utf-8 -*-

require 'logger'

module Gmap
  class ToolRunner < RunnerBase
    private

    def validate_config(config)
      # check -n option
      chrnum = config["chrnum"]
      raise InvalidOptionError, "please specify one chromosome number by -n option" unless chrnum && Utility.parse_chrnum(chrnum).size == 1

      # accept only one input file
      input_files = config["input_files"]
      raise InvalidOptionError, "please specify one input file" unless input_files && input_files.size == 1

      # validate config
      Utility.validate_config(config)
    end

    def run_core(config)
      # do common process

      # prepare variables
      tool = config["tool"]
      log.info("tool name: #{tool}")

      input_file1 = config["input_files"][0]
      log.debug("input file: #{input_file1}")

      input_file2 = Utility.get_mate_pair_file_name(input_file1)
      log.debug("mate pair: #{input_file2}") if input_file2

      threads = config["threads"]
      chrnum  = config["chrnum"]

      genome_index  = config["genome_index"]
      genome_config = config["genome_config"]
      log.info("genome index: #{genome_index}")

      genome_path   = genome_config[genome_index]["genome_path"] % chrnum

      project_config = config["project_config"]
      srp            = Utility.get_srp_name(input_file1)
      tool_config    = srp && project_config[srp] && project_config[srp][tool]
      if tool_config
        log.info("project config: #{srp}") if srp
      else
        log.info("use default project config")
        tool_config = project_config["default"][tool]
      end

      log.info("chrnum: #{chrnum}")

      # run the specified tool
      send("run_#{tool}", config, threads, chrnum, genome_path, tool_config, input_file1, input_file2)
    end

    def run_tophat(config, threads, chrnum, genome_path, tool_config, input_file1, input_file2)
      log.debug("genome path: #{genome_path}")

      # create output directories
      output_dir = "#{Utility.get_output_dir(config, input_file1)}/tophat/#{chrnum}"
      log.info("output dir: #{output_dir}")
      if !config["dry_run"]
        Utility.create_directories(output_dir)
      end

      # set environment variable
      tophat_path   = config["tophat_path"]
      bowtie_path   = config["bowtie_path"]
      samtools_path = config["samtools_path"]
      env_path      = "#{File.dirname(tophat_path)}:#{File.dirname(bowtie_path)}:#{File.dirname(samtools_path)}:/usr/bin:/bin"
      ENV['PATH']   = env_path
      log.debug("env path: #{env_path}")

      # generate command string
      tophat_opts = "-p #{threads} #{tool_config}"
      tophat_cmd  = "#{tophat_path} #{tophat_opts}"
      tophat_cmd  += " -o #{output_dir}"
      tophat_cmd  += " #{genome_path}"
      tophat_cmd  += " #{input_file1}"
      tophat_cmd  += " #{input_file2}" if input_file2

      log.info(tophat_cmd)
      if config["dry_run"]
        log.info("dry run: don't run command")
      else
        log.info("start tophat")
        system tophat_cmd
        log.info("finish tophat")
      end
    end

    def run_bowtie(config, threads, chrnum, genome_path, tool_config, input_file1, input_file2)
      log.debug("genome path: #{genome_path}")

      # create output directories
      output_dir = "#{Utility.get_output_dir(config, input_file1)}/bowtie"
      log.info("output dir: #{output_dir}")
      if !config["dry_run"]
        Utility.create_directories(output_dir)
      end

      # generate command string
      bowtie_path = config["bowtie_path"]
      bowtie_opts = "-p #{threads} #{tool_config}"
      bowtie_cmd  = "#{bowtie_path} #{bowtie_opts}"
      bowtie_cmd  += " #{genome_path}"
      bowtie_cmd  += input_file2 ? " -1 #{input_file1} -2 #{input_file2}" : " #{input_file1}"
      bowtie_cmd  += " #{output_dir}/#{chrnum}"

      log.info(bowtie_cmd)
      if config["dry_run"]
        log.info("dry run: don't run command")
      else
        log.info("start bowtie")
        system bowtie_cmd
        log.info("finish bowtie")
      end
    end

    def run_soap2(config, threads, chrnum, genome_path, tool_config, input_file1, input_file2)
      # add suffix to genome_path and check file exists
      found = false
      [".fa.index", ".fna.index", ".fasta.index"].each do |ext|
        if File.file?("#{genome_path}#{ext}.amb")
          genome_path += ext
          found = true
          break
        end
      end
      log.debug("genome path: #{genome_path}")

      # create output directories
      output_dir = "#{Utility.get_output_dir(config, input_file1)}/soap2"
      log.info("output dir: #{output_dir}")
      if !config["dry_run"]
        Utility.create_directories(output_dir)
      end

      # generate command string
      soap2_path = config["soap2_path"]
      soap2_opts =  "-a #{input_file1}"
      soap2_opts += " -b #{input_file2}" if input_file2
      soap2_opts += " -D #{genome_path} -o #{output_dir}/#{chrnum}"
      soap2_opts += " -2 #{output_dir}/#{chrnum}_2" if input_file2
      soap2_opts += " -p #{threads} #{tool_config}"
      soap2_cmd  =  "#{soap2_path} #{soap2_opts}"

      log.info(soap2_cmd)
      if config["dry_run"]
        log.info("dry run: don't run command")
      else
        log.info("start soap2")
        system soap2_cmd
        log.info("finish soap2")
      end
    end
  end
end
