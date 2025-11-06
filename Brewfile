spec("docker builds") do |config|
  task "docker-linux" do |args|
    def build
      command("rm -rf test/tmp")
      command("docker build --file docker/Dockerfile.linux -t skinnyjames/mruby-cross-linux:latest .")
    end
  end

  task "docker-osx" do |args|
    def build
      command("rm -rf test/tmp")
      command("mkdir -p platforms/macos-intel")
      command("docker build --file docker/Dockerfile.osx -t skinnyjames/mruby-cross-osx:latest .")
    end
  end

  task "docker-windows" do |args|
    def build
      command("rm -rf test/tmp")
      command("mkdir -p platforms/windows")
      command("docker build --file docker/Dockerfile.windows -t skinnyjames/mruby-cross-windows:latest .")
    end
  end

  task "linux" do
    def build
      command("mkdir -p platforms/linux")
      command("docker build --file docker/export/Dockerfile.linux --output ./platforms/linux .")
    end
  end

  task "osx" do
    def build
      command("mkdir -p platforms/macos-intel")
      command("docker build --file docker/export/Dockerfile.osx --output ./platforms/osx .")
    end
  end

  task "windows" do
    def build
      command("mkdir -p platforms/windows")
      command("docker build --file docker/export/Dockerfile.windows --output ./platforms/windows .")
    end
  end

  task "all" do
    dependency "linux"
    dependency "osx"
    dependency "windows"

    def build
    end
  end

  task "dockerpublish" do |args|
    dependency "docker-linux"
    dependency "docker-osx"
    dependency "docker-windows"

    def build
      name = args[:name] || "skinnyjames"
      command("docker push #{name}/mruby-cross-linux:latest")
      command("docker push #{name}/mruby-cross-osx:latest")
      command("docker push #{name}/mruby-cross-windows:latest")
      command("echo 'all done!'")
    end
  end
end