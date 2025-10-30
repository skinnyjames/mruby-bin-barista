module Barista
  module Commands
    class Base
      include Emittable

      def execute
        raise Barista::Error.new("#{self.class}#execute must be implemented")
      end

      def description
        raise Barista::Error.new("#{self.class}#description must be implemented")
      end
    end
  end
end
