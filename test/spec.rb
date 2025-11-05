class SpecTest
  include Theorem::Hypothesis

  let(:top) do
    spec("new-barista-project") do |config|
      import path: "test/fixtures/gems/theorem"

      task "grind" do |args| 
        def build
          @@out << "grind"
          command("echo 'grind #{args[:type] || 'arabica'} beans' > test/tmp/beans.txt")
        end
      end

      task "milk" do |args|
        def build
          @@out << "steam"
          command("echo 'steaming milk'")
          command("echo 'milk steamed!' > test/tmp/milk.txt")
        end
      end

      task "brew" do |args|
        dependency "milk" do
          files "test/tmp/milk.txt"
        end   

        dependency "grind" do
          files "test/tmp/beans.txt"  
        end
    
        def build
          (args[:times] || 1).times do
            @@out << "brew"
            command("echo 'drip drip drip'")
          end

          command("echo 'all done!!'")
        end  
      end
    end
  end

  before_each do
    `rm -Rf test/tmp`
    `mkdir -p test/tmp`
    @@out = []
  end

  after_each do
    `rm -Rf test/tmp`
  end

  test "runs only what is needed" do
    top.execute('brew')
    expect(@@out).to include(%w[grind steam])
    expect(@@out.last).to eql("brew")
    
    @@out.clear

    top.execute('brew')
    expect(@@out).to eql(%w[brew])

    @@out.clear
    
    puts File::Stat.new("test/tmp/milk.txt").mtime
    File.open("test/tmp/milk.txt", "w") {|io| io.puts "new" }
    puts File::Stat.new("test/tmp/milk.txt").mtime

    top.execute('brew')
    expect(@@out).to eql(%w[steam brew])
  end
end