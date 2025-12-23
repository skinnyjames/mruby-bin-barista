module Barista
  module Commands
    class Command < Base
      attr_reader :command, :chdir, :shell, :env
      
      def initialize(command, chdir: nil, shell: nil, env: {})
        @command = command
        @chdir = chdir
        @env = env
        @shell = shell
      end

      def execute
        on_output.call("running command: #{command}")
        dir = chdir || "."
        if windows? && !shell
          cmd = "powershell.exe -Command \"cd #{dir}; #{command}\""
        elsif shell
          cmd = "#{shell} -c \"cd #{dir}; #{command}\""
        else
          cmd = "cd #{dir}; #{command}"
        end
        IO.popen(cmd, File::NONBLOCK | File::RDONLY) do |io|
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
