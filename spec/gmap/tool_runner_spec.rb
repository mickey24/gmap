# -*- coding: utf-8 -*-

require "spec_helper"

module Gmap
  describe ToolRunner do
    before do
      # dismiss all method calls for logger object
      Logger.should_receive(:new).and_return(mock("mock logger").as_null_object)
    end
    let(:tool_runner)   { ToolRunner.new }
    let(:sample_tool_runner_config) {
      config = sample_config
      config["chrnum"] = "1"
      config
    }

    describe "#validate_config" do
      context "with more than one chromosome numbers" do
        it {
          invalid_config = sample_tool_runner_config
          invalid_config["chrnum"] = "1-19,X,Y"

          lambda {
            tool_runner.__send__(:validate_config, invalid_config)
          }.should raise_error(ToolRunner::InvalidOptionError, "please specify one chromosome number by -n option")
        }
      end
      
      context "with correct config" do
        it {
          config = sample_tool_runner_config
          Utility.should_receive(:validate_config).and_return(true)

          tool_runner.__send__(:validate_config, config).should be_true
        }
      end
    end
  end
end
