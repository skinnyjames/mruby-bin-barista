class SpecTest
  include Theorem::Hypothesis

  let(:top) do
    spec("new-barista-project") do |config|
      import path: "test/fixtures/gems/theorem"

      task "grind" do |args| 
        def build
          command("echo 'grind #{args[:type] || 'arabica'} beans' > beans.txt")
        end
      end

      task "milk" do |args|
        def build
          command("echo 'steaming milk'")
          command("echo 'milk steamed!' > milk.txt")
        end
      end

      task "brew" do |args|
        dependency "milk" do
          files "milk.txt"
        end   

        dependency "grind" do
          files "beans.txt"  
        end
    
        def build
          (args[:times] || 1).times do
            command("echo 'drip drip drip'")
          end

          command("echo 'all done!!'")
        end  
      end
    end
  end

  test "gemspec thing" do
    puts top.execute('brew')
  end
end