# -*- coding: utf-8 -*-

require "spec_helper"

module Gmap
  describe Utility do
    describe ".validate_config" do
      before do
        File.stub(:executable?).and_return(true)
        File.stub(:exist?).and_return(true)
      end

      [ "ruby_path",
        "qsub_path",
      ].each do |key|
        context "without #{key} key" do
          it {
            invalid_config = sample_config.reject{|k, v| k == key}

            lambda {
              Utility.validate_config(invalid_config)
            }.should raise_error(Utility::InvalidConfigError, "config not found: #{key}")
          }
        end

        context "when #{key} is invalid" do
          it "should raise #{Utility::InvalidConfigError} with 'invalid path: #{key} : \#{tool_path}'" do
            invalid_config = sample_config
            tool_path = invalid_config[key]

            File.should_receive(:executable?).with(tool_path).and_return(false)

            lambda {
              Utility.validate_config(invalid_config)
            }.should raise_error(Utility::InvalidConfigError, "invalid path: #{key}: #{tool_path}")
          end
        end
      end

      context "without tool key" do
        it {
          invalid_config = sample_config.reject{|k, v| k == "tool"}

          lambda {
            Utility.validate_config(invalid_config)
          }.should raise_error(Utility::InvalidConfigError, "tool name is not specified")
        }
      end

      context "when tool name is invalid" do
        invalid_tool_name = "invalid_tool_name"

        it "should raise #{Utility::InvalidConfigError} with 'invalid tool name: \#{invalid_tool_name}'" do
          invalid_config = sample_config
          invalid_config["tool"] = invalid_tool_name

          lambda {
            Utility.validate_config(invalid_config)
          }.should raise_error(Utility::InvalidConfigError, "invalid tool name: #{invalid_tool_name}")
        end
      end

      [ "tophat",
        "bowtie",
        "soap2",
      ].each do |tool|
        context "when tool == #{tool}" do

          required_tools = {
            "tophat" => ["tophat", "bowtie", "samtools"],
            "bowtie" => ["bowtie"],
            "soap2"  => ["soap2"],
          }

          required_tools[tool].each do |required_tool|
            tool_path_key = "#{required_tool}_path"
            context "and without #{tool_path_key} key" do
              it {
                invalid_config = sample_config
                invalid_config["tool"] = tool
                invalid_config = invalid_config.reject{|k, v| k == tool_path_key}

                lambda {
                  Utility.validate_config(invalid_config)
                }.should raise_error(Utility::InvalidConfigError, "config not found: #{tool_path_key}")
              }
            end

            context "and #{tool_path_key} is invalid" do
              it "should raise error #{Utility::InvalidConfigError} with 'invalid path: #{tool_path_key}: \#{tool_path}'" do
                invalid_config = sample_config
                invalid_config["tool"] = tool
                tool_path = invalid_config[tool_path_key]

                File.should_receive(:executable?).with(tool_path).and_return(false)

                lambda {
                  Utility.validate_config(invalid_config)
                }.should raise_error(Utility::InvalidConfigError, "invalid path: #{tool_path_key}: #{tool_path}")
              end
            end
          end
        end
      end

      [ "jobname_prefix",
        "queue",
        "threads",
        "output_dir",
      ].each do |key|
        context "without #{key} key" do
          it {
            invalid_config = sample_config.reject{|k, v| k == key}

            lambda {
              Utility.validate_config(invalid_config)
            }.should raise_error(Utility::InvalidConfigError, "config not found: #{key}")
          }
        end
      end

      context "without genome_index" do
        it "should raise #{Utility::InvalidConfigError} with 'genome index is not specified'" do
          invalid_config = sample_config.reject{|k, v| k == "genome_index"}

          lambda {
            Utility.validate_config(invalid_config)
          }.should raise_error(Utility::InvalidConfigError, "genome index is not specified")
        end
      end

      context "without input files" do
        it {
          invalid_config = sample_config
          invalid_config["input_files"] = []

          lambda {
            Utility.validate_config(invalid_config)
          }.should raise_error(Utility::InvalidConfigError, "input file is not specified")
        }
      end

      context "with invalid input files (input files not found)" do
        it "should raise error #{Utility::InvalidConfigError} with 'file not found: input file: \#{invalid_input_file}'" do
          invalid_config = sample_config
          invalid_input_file = "/path/to/invalid_input_file.fastq"
          invalid_config["input_files"] = [invalid_input_file]

          File.should_receive(:exist?).with(invalid_input_file).and_return(false)

          lambda {
            Utility.validate_config(invalid_config)
          }.should raise_error(Utility::InvalidConfigError, "file not found: input file: #{invalid_input_file}")
        end
      end

      # genome_config
      context "without genome_config key" do
        it {
          invalid_config = sample_config.reject{|k, v| k == "genome_config"}

          lambda {
            Utility.validate_config(invalid_config)
          }.should raise_error(Utility::InvalidConfigError, "config not found: genome_config")
        }
      end

      context "with genome_config key" do
        context "and without the specified genome config" do
          it {
            invalid_config = sample_config
            invalid_config["genome_index"] = "invalid_genome_index"

            lambda {
              Utility.validate_config(invalid_config)
            }.should raise_error(Utility::InvalidConfigError, "config not found: invalid_genome_index in genome_config")
          }
        end

        [ "genome_path",
          "chrnum",
        ].each do |key|
          context "and with the specified genome config and without #{key}" do
            it {
              invalid_config = sample_config
              genome_index = invalid_config["genome_index"]
              target_genome_config = invalid_config["genome_config"][genome_index]
              invalid_config["genome_config"][genome_index] = target_genome_config.reject{|k, v| k == key}

              lambda {
                Utility.validate_config(invalid_config)
              }.should raise_error(Utility::InvalidConfigError, "config not found: #{key} in genome_config[#{genome_index}]")
            }
          end
        end
      end

      # project_config
      context "without project_config key" do
        it {
          invalid_config = sample_config.reject{|k, v| k == "project_config"}

          lambda {
            Utility.validate_config(invalid_config)
          }.should raise_error(Utility::InvalidConfigError, "config not found: project_config")
        }
      end

      context "with project_config key" do
        context "and without the specified project config and default project_config" do
          it {
            invalid_config = sample_config
            srp = File.basename(invalid_config["input_files"][0])
            invalid_config["project_config"] = {}

            lambda {
              Utility.validate_config(invalid_config)
            }.should raise_error(Utility::InvalidConfigError, "config not found: #{srp} and default settings in project_config")
          }
        end

        context "and with the specified project config and without tool setting" do
          it {
            invalid_config = sample_config
            srp = File.basename(invalid_config["input_files"][0])
            tool = invalid_config["tool"]
            invalid_config["project_config"][srp].reject!{|k, v| k == tool}

            lambda {
              Utility.validate_config(invalid_config)
            }.should raise_error(Utility::InvalidConfigError, "config not found: #{tool} in project_config[#{srp}]")
          }
        end

        context "and with the default project config and without tool setting" do
          it {
            invalid_config = sample_config
            srp = File.basename(invalid_config["input_files"][0])
            tool = invalid_config["tool"]
            invalid_config["project_config"].reject!{|k, v| k == srp}
            invalid_config["project_config"]["default"].reject!{|k, v| k == tool}

            lambda {
              Utility.validate_config(invalid_config)
            }.should raise_error(Utility::InvalidConfigError, "config not found: #{tool} in project_config[default]")
          }
        end
      end
    end

    describe ".parse_chrnum" do
      context "with a valid argument" do
        it "should parse one number" do
          Utility.parse_chrnum("1").should == ["1"]
        end

        it "should parse one letter" do
          Utility.parse_chrnum("Mt").should == ["Mt"]
        end

        it "should parse comma-separated chromosome numbers" do
          Utility.parse_chrnum("1,2,Mt,X").should == ["1","2","Mt","X"]
        end

        it "should parse hyphen-separated two numbers as a chromosome range" do
          Utility.parse_chrnum("1-4").should == ["1","2","3","4"]
        end

        it "should parse mixed hyphen and comma separated chromosome numbers" do
          Utility.parse_chrnum("1-3,Mt,X").should == ["1","2","3","Mt","X"]
        end
      end

      context "with an invalid argument" do
        it "should raise #{Utility::InvalidChrnumError} when an empty string is given" do
          lambda {
            Utility.parse_chrnum("")
          }.should raise_exception(Utility::InvalidChrnumError, "empty string")
        end

        it "should raise #{Utility::InvalidChrnumError} when the string beginning with a comma is given" do
          lambda {
            Utility.parse_chrnum(",1")
          }.should raise_exception(Utility::InvalidChrnumError, "invalid chrnum format: ,1")
        end

        it "should raise #{Utility::InvalidChrnumError} when the string followed by a comma is given" do
          lambda {
            Utility.parse_chrnum("1,")
          }.should raise_exception(Utility::InvalidChrnumError, "invalid chrnum format: 1,")
        end

        it "should raise #{Utility::InvalidChrnumError} when there is no chrnum between two cammas" do
          lambda {
            Utility.parse_chrnum("1,,3")
          }.should raise_exception(Utility::InvalidChrnumError, "invalid chrnum format: 1,,3")
        end

        it "should raise #{Utility::InvalidChrnumError} when a descending range is given" do
          lambda {
            Utility.parse_chrnum("3-1")
          }.should raise_exception(Utility::InvalidChrnumError, "range: 3-1 is descending order")
        end

        it "should raise #{Utility::InvalidChrnumError} when an invalid range is given" do
          lambda {
            Utility.parse_chrnum("-")
          }.should raise_exception(Utility::InvalidChrnumError, "invalid chrnum format: -")
        end
      end
    end

    describe ".get_srp_name" do
      context "with a path including SRPxxxx" do
        it "should return 'SRPxxxx'" do
          File.should_receive(:expand_path).and_return("/path/to/SRP000123/SRX000456/SRR000789.fastq")

          Utility.get_srp_name("./SRR000789.fastq").should == "SRP000123"
        end
      end

      context "with a path without SRPxxxx" do
        it {
          File.should_receive(:expand_path).and_return("/path/to/SRR000789.fastq")

          Utility.get_srp_name("./SRR000789.fastq").should be_nil
        }
      end
    end

    describe ".get_srp_srx_srr_path" do
      context "with a path including SRPxxxx/SRXxxxx/SRRxxxx.fastq" do
        it "should return 'SRPxxxx/SRXxxxx/SRRxxxx'" do
          File.should_receive(:expand_path).and_return("/path/to/SRP000123/SRX000456/SRR000789.fastq")

          Utility.get_srp_srx_srr_path("./SRR000789.fastq").should == "SRP000123/SRX000456/SRR000789"
        end
      end

      context "with a path without SRPxxxx/SRXxxxx/SRRxxxx.fastq" do
        it {
          File.should_receive(:expand_path).and_return("/path/to/SRR000789.fastq")

          Utility.get_srp_srx_srr_path("./SRR000789.fastq").should be_nil
        }
      end
    end

    describe ".get_output_dir" do
      context "if config['output_dir'] exists" do
        context "and path contains SRPxxxx/SRXxxxx/SRRxxxx" do
          it "should return config['output_dir']/SRPxxxx/SRXxxxx/SRRxxxx" do
            config = sample_config

            Utility.get_output_dir(config, "/path/to/SRP000123/SRX000456/SRR000789.fastq").should == "#{config["output_dir"]}/SRP000123/SRX000456/SRR000789"
          end
        end

        context "and path doesn't contain SRPxxxx/SRXxxxx/SRRxxxx" do
          it "should return config['output_dir']/\#{basename of path}" do
            config = sample_config

            Utility.get_output_dir(config, "/path/to/reads.fastq").should == "#{config["output_dir"]}/reads"
          end
        end
      end

      context "if config['output_dir'] doesn't exist" do
        context "and path contains SRPxxxx/SRXxxxx/SRRxxxx" do
          it "should return result/SRPxxxx/SRXxxxx/SRRxxxx" do
            config = sample_config
            config = config.reject{|k, v| k == "output_dir"}

            Utility.get_output_dir(config, "/path/to/SRP000123/SRX000456/SRR000789.fastq").should == "result/SRP000123/SRX000456/SRR000789"
          end
        end

        context "and path doesn't contain SRPxxxx/SRXxxxx/SRRxxxx" do
          it "should return result/\#{basename of path}" do
            config = sample_config
            config = config.reject{|k, v| k == "output_dir"}

            Utility.get_output_dir(config, "/path/to/reads.fastq").should == "result/reads"
          end
        end
      end
    end

    describe ".get_mate_pair_file_name" do
      context "if filename contains _1" do
        context "and the matepair file _2 exists" do
          it "should return the mate pair file name" do
            File.should_receive(:file?).and_return(true)

            Utility.get_mate_pair_file_name("./reads_1.fastq").should == "./reads_2.fastq"
          end
        end

        context "and the matepair file _2 doesn't exist" do
          it {
            File.should_receive(:file?).and_return(false)

            Utility.get_mate_pair_file_name("./reads_1.fastq").should be_nil
          }
        end
      end

      context "if filename doesn't contain _1" do
        it {
          Utility.get_mate_pair_file_name("./reads.fastq").should be_nil
        }
      end
    end

    describe ".create_directories" do
      context "if the specified directory path exists" do
        context "and mode is specified" do
          it "should execute /bin/mkdir with -p and -m" do
            dirs = "/path/to/dirs"
            mode = "755"
            File.should_receive(:exist?).and_return(false)
            Utility.should_receive(:system).with("/bin/mkdir -p #{dirs} -m #{mode}")

            Utility.create_directories(dirs, mode).should be_true
          end
        end

        context "and mode is not specified" do
          it "should execute /bin/mkdir with -p" do
            dirs = "/path/to/dirs"
            File.should_receive(:exist?).and_return(false)
            Utility.should_receive(:system).with("/bin/mkdir -p #{dirs}")

            Utility.create_directories(dirs).should be_true
          end
        end
      end

      context "if the specified directory path exists" do
        it {
          File.should_receive(:exist?).and_return(true)

          Utility.create_directories("/path/to/dirs").should be_false
        }
      end
    end
  end
end
