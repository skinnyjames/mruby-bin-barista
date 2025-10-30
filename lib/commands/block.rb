module Barista
  module Commands
    class Block < Base
      attr_reader :block
    
      def initialize(&block)
        @block = block
      end

      def execute
        block.call
      end
    end
  end
end
