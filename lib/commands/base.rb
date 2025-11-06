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
      
      def detected_os
        Barista.os
      end

      def mac?
        detected_os == "MacOS"
      end
    
      def linux?
        detected_os == "Linux"
      end

      def windows?
        detected_os == "Windows"
      end
    end
  end
end
