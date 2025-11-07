class SpecTest
  include Theorem::Hypothesis

  let(:top) do
    spec("new-barista-project") do |config|
      task "grind" do |args| 
        def build
          @@out << "grind"

          ruby do
            File.open("test/tmp/beans.txt", "w") { |io| io << "grind #{args[:type] || 'arabica'} beans" }
          end
        end
      end

      task "milk" do |args|
        def build
          @@out << "steam"
          command("echo 'steaming milk'")

          ruby do
            File.open("test/tmp/milk.txt", "w") { |io| io << "Milk Steamed!" }
          end
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
    if Dir.exist?("test/tmp")
      Dir.glob("test/tmp/*") { |f| File.delete(f) }
      Dir.delete("test/tmp") 
    end
    Dir.mkdir("test/tmp")

    @@out = []
  end

  test "runs only what is needed" do
    top.execute('brew')
    expect(@@out).to include(%w[grind steam])
    expect(@@out.last).to eql("brew")
    
    @@out.clear

    top.execute('brew')
    expect(@@out).to eql(%w[brew])

    @@out.clear
    
    sleep 1
    File.open("test/tmp/milk.txt", "w") { |io| io.puts "new" }
    sleep 1

    top.execute('brew')
    expect(@@out).to eql(%w[steam brew])
  end
end