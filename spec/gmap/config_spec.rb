# -*- coding: utf-8 -*-

require "spec_helper"
require "yaml"

module Gmap
  describe Config do
    let(:sample_config) {
      YAML.load(<<EOM)
ruby_path      : /path/to/ruby
qsub_path      : /path/to/qsub

tophat_dir     : /path/to/tophat_dir
bowtie_dir     : /path/to/bowtie_dir
soap2_dir      : /path/to/soap2_dir

jobname_prefix : m
queue          : node.q
threads        : 2
output_dir     : /path/to/output_dir

genome_config:
 mouse:
  genome_path : /path/to/genome/mouse/%s
  chrnum      : 1-19,X,Y

project_config:
 SRP000198:
  tophat    : "--solexa-quals -r 200 --mate-std-dev 50"
  bowtie    : "-X 250 -I 150"
  soap2     : "-x 250 -m 150"
EOM
    }

    describe ".load_config" do
      it "should load config from $HOME/.gmap" do
        home_dir = "/path/to/home_dir"
        File.should_receive(:expand_path).with("~").and_return(home_dir)
        YAML.should_receive(:load_file).with("#{home_dir}/.gmap").and_return(sample_config)

        Config.load_config.should == sample_config
      end
    end
  end
end
