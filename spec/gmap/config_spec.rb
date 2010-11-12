# -*- coding: utf-8 -*-

require "spec_helper"
require "yaml"

module Gmap
  describe Config do
    let(:current_dir) { "/path/to/current_dir" }
    let(:home_dir)    { "/path/to/home_dir" }

    before do
      Dir.stub(:getwd).and_return(current_dir)
      File.stub(:expand_path).with("~").and_return(home_dir)
    end

    describe ".load" do
      context "when ./.gmap exists" do
        it "should load config ./.gmap" do
          File.should_receive(:exists?).with("#{current_dir}/.gmap").and_return(true)
          YAML.should_receive(:load_file).with("#{current_dir}/.gmap").and_return(sample_config)

          Config.load.should == sample_config
        end
      end

      context "when ./.gmap doesn't exist and $HOME/.gmap exists" do
        it "should load config from $HOME/.gmap" do
          File.should_receive(:exists?).with("#{current_dir}/.gmap").and_return(false)
          File.should_receive(:exists?).with("#{home_dir}/.gmap").and_return(true)
          YAML.should_receive(:load_file).with("#{home_dir}/.gmap").and_return(sample_config)

          Config.load.should == sample_config
        end
      end

      context "when both ./.gmap and $HOME/.gmap don't exist" do
        it "should raise #{Gmap::Config::ConfigNotFoundError}" do
          File.should_receive(:exists?).with("#{current_dir}/.gmap").and_return(false)
          File.should_receive(:exists?).with("#{home_dir}/.gmap").and_return(false)

          lambda { Config.load }.should raise_error(Config::ConfigNotFoundError)
        end
      end
    end
  end
end
