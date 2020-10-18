# frozen_string_literal: true

module RexyAdmin
  module Serializer
    class MyError < StandardError
      def initialize(message)
        super(message)
      end
    end
  end
end
