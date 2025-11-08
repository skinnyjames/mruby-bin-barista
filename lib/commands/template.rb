module Barista
  module Commands
    # This command is for the build pipeline
    # It doesn't return, but writes to a file
    # For processing templates that return a string
    # see Task#erb
    class Template < Base
      attr_reader :src, :dest, :string, :vars

      def initialize(src, dest, string: false, vars: {})
        @src = src
        @dest = dest
        @string = string
        @vars = vars
      end

      def execute
        template_str = string ? src : File.read(src)
        erb = ERB.new(template_str)

        obj = Object.new
        vars.each do |k, v|
          obj.define_singleton_method(k) do
            v
          end
        end

        processed = erb.result(obj)

        File.open(dest, "w") do |io|
          io << processed
        end
      end
    end
  end
end
