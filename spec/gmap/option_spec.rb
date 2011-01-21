# -*- coding: utf-8 -*-

require "spec_helper"

module Gmap
  describe Option do
    describe ".parse" do
      # custom matcher
      # check if h1 includes h2
      Spec::Matchers.define :include_hash do |h2|
        match do |h1|
          h2.all? {|k, v| h1[k] == v}
        end
      end

      # genome_index
      context "with -g genome_index" do
        it "should return {'genome_index' => genome_index}" do
          Option.parse(%w|-g mouse|).should include_hash({"genome_index" => "mouse"})
        end
      end

      # chromosome number
      context "with -n chrnum" do
        it "should return {'chrnum' => chrnum}" do
          Option.parse(%w|-n 1-19,X,Y|).should include_hash({"chrnum" => "1-19,X,Y"})
        end
      end

      # output directory
      context "with -o output_dir" do
        it "should return {'output_dir' => output_dir}" do
          Option.parse(%w|-o /path/to/output_dir|).should include_hash({"output_dir" => "/path/to/output_dir"})
        end
      end

      # threads
      context "with -p threads" do
        it "should return {'threads' => threads}" do
          Option.parse(%w|-p 2|).should include_hash({"threads" => 2})
        end
      end

      # queue
      context "with -q queue" do
        it "should return {'queue' => queue}" do
          Option.parse(%w|-q node.q|).should include_hash({"queue" => "node.q"})
        end
      end

      # tool_name
      context "with -t tool_name" do
        it "should return {'tool' => valid_tool_name}" do
          Option.parse(%w|-t tophat|).should include_hash({"tool" => "tophat"})
        end
      end

      # help
      context "with -h" do
        it "should return {'help' => help_message}" do
          Option.parse(%w|-h|).should have_key("help")
        end
      end

      # input_files
      context "with leading arguments" do
        it "should return {'input_files' => [input_file1, input_file2, ...]}" do
          Option.parse(%w|input_file1 input_file2|).should include_hash({"input_files" => %w|input_file1 input_file2|})
        end
      end
    end
  end
end
