# -*- coding: utf-8 -*-

module Gmap
  module Utility
    extend self

    class InvalidChrnumError < StandardError; end

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
  end
end
