module Barista
  module Commands
    class Mkdir < Base
      attr_reader :directory, :parent, :args

      def initialize(directory, parent: true, **args)
        @directory = directory
        @parent = parent
        @args = args
      end

      def execute
        cmd = parent ? "mkdir -p #{directory}" : "mdkir #{directory}"  

        Command.new(cmd, **args)
          .forward_output(&on_output)
          .forward_error(&on_error)
          .execute
      end
    end
  end
end
