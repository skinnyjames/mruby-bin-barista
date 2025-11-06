module Barista
  module Commands
    class Command < Base
      attr_reader :command, :chdir, :env
      
      def initialize(command, chdir: nil, env: {})
        @command = command
        @chdir = chdir
        @env = env
      end

      def execute
        on_output.call("running command: #{command}")
        dir = chdir || "."
        IO.popen("cd #{dir}; #{command}", File::NONBLOCK | File::RDONLY) do |io|
          io.nonblock!
          loop do
            begin
              while res = io.readline
                on_output.call(res.chomp)
              end
              Fiber.yield
            rescue Errno::EAGAIN => ex
              Fiber.yield
            rescue EOFError
              break
            rescue StandardError => ex
              Fiber.yield
              puts "WTF: #{ex}"
            end
          end
        end

        code = $?
        raise Barista::Error.new("command #{command} failed with exit #{code}") unless code == 0
      end

      def description
        <<~EOF
        #{command}#{chdir}#{env.to_s}
        EOF
      end
    end
  end
end
