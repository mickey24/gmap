# -*- coding: utf-8 -*-

require 'logger'

module Gmap
  class SgeRunner < RunnerBase
    private

    def validate_config(config)
      Utility.validate_config(config)
    end

    def run_core(config)
      log.formatter = lambda {|a,b,c,d| "#{d}\n"}

      tool = config["tool"]
      log.info("tool name: #{tool}")

      ruby_path = config["ruby_path"]
      qsub_path = config["qsub_path"]

      jobname_prefix = config["jobname_prefix"]
      queue          = config["queue"]
      threads        = config["threads"]

      genome_index         = config["genome_index"]
      genome_config        = config["genome_config"]
      target_genome_config = genome_config[genome_index]
      log.info("genome index: #{genome_index}")

      project_config = config["project_config"]

      # for each input file and each chrnum
      input_files = config["input_files"]
      input_files.each do |input_file1|
        log.info("input file: #{input_file1}")

        input_file2 = Utility.get_mate_pair_file_name(input_file1)
        log.info("mate pair: #{input_file2}") if input_file2

        # output directories
        output_dir = "#{Utility.get_output_dir(config, input_file1)}/#{tool}"
        log.info("output dir: #{output_dir}")

        qsub_log_dir = "#{output_dir}/qsub_logs"
        log.debug("qsub log dir: #{qsub_log_dir}")

        # project config
        srp = Utility.get_srp_name(input_file1)
        tool_config = srp && project_config[srp] && project_config[srp][tool]
        if tool_config
          log.info("project config: #{srp}") if srp
        else
          log.info("use default project config")
          tool_config = project_config["default"][tool]
        end

        # qsub commands to be executed
        qsub_cmds = []

        # for each chrnum, print log messages and generate qsub command strings
        chrnum = Utility.parse_chrnum(config['chrnum'] || target_genome_config['chrnum'])
        log.info("chrnum: #{chrnum.join(",")}")
        chrnum.each do |num|
          # command strings
          runner_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "bin", "gmap_tool_runner.rb"))
          runner_opts = "-t #{tool} -g #{genome_index} -n #{num}"

          # specify the base output dir (without SRPxxxx/SRXxxxx/SRRxxxx)
          runner_opts += " -o #{config['output_dir']}" if config['output_dir']
          runner_cmd  =  "#{ruby_path} #{runner_path} #{runner_opts} #{input_file1}"

          # qsub opts & command strings
          tool_prefix = tool[0]
          qsub_opts = "-N #{jobname_prefix}#{tool_prefix}_#{num} -b y -cwd -q #{queue} -l nc=#{threads} -j y -o #{qsub_log_dir}/#{num}"
          qsub_cmd = "#{qsub_path} #{qsub_opts} #{runner_cmd}"

          log.debug("qsub command: #{qsub_cmd}")
          qsub_cmds.push(qsub_cmd)
        end

        # yes/no
        ans = ""
        dry_run = nil
        puts "submit jobs? (y/n)"

        while (dry_run.nil?)
          ans = $stdin.gets.chomp!.downcase
          if ["y", "yes", "n", "no"].include?(ans)
            dry_run = ["n", "no"].include?(ans)
          else
            puts "please answer 'y' or 'n'"
          end
        end

        if !dry_run
          # create output directories
          Utility.create_directories(qsub_log_dir)

          # submit a job by qsub
          qsub_cmds.each do |cmd|
            system cmd
          end
        end

      end
    end
  end
end
