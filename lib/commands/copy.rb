module Barista
  module Commands
    class Copy < Base
      attr_reader :src, :dest, :chdir, :env
    
      def initialize(src, dest, chdir: nil, env: {})
        @src = src
        @dest = dest
        @chdir = chdir
        @env = env
      end

      def execute
        cmd = File.directory?(src) ? "cp -R #{src} #{dest}" : "cp #{src} #{dest}"  

        Command.new(cmd, chdir: chdir, env: env)
          .forward_output(&on_output)
          .forward_error(&on_error)
          .execute
      end
    end
  end
end
