# -*- coding: utf-8 -*-

require "spec_helper"

module Gmap
  describe Utility do
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
        it "should return nil" do
          File.should_receive(:expand_path).and_return("/path/to/SRR000789.fastq")

          Utility.get_srp_name("./SRR000789.fastq").should be_nil
        end
      end
    end
  end
end
