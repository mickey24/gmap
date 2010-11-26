#!/usr/bin/env ruby

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'gmap'

if __FILE__ == $PROGRAM_NAME
  Gmap::ToolRunner.new("info").run(ARGV)
end
