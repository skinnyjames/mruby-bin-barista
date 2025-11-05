spec("docker builds") do |config|
  task "linux" do |args|
    def build
      command("rm -rf test/tmp")
      command("mkdir -p platforms/linux")
      command("docker build --file docker/Dockerfile.linux --output ./platforms/linux  -t barista/linux:latest .")
    end
  end

  task "osx" do |args|
    def build
      command("rm -rf test/tmp")
      command("mkdir -p platforms/macos-intel")
      command("docker build --file docker/Dockerfile.osx --output ./platforms/osx  -t barista/osx:latest .")
    end
  end

  task "windows" do |args|
    def build
      command("rm -rf test/tmp")
      command("mkdir -p platforms/windows")
      command("docker build --file docker/Dockerfile.windows --output ./platforms/windows  -t barista/windows:latest .")
    end
  end

  task "all" do
    dependency "linux"
    dependency "osx"
    dependency "windows"

    def build
      command("echo 'all done!'")
    end
  end
end