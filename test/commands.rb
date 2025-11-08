class CommandsTest
  include Theorem::Hypothesis

  let(:dockerfile) do
    <<~EOF
    FROM <%= image %>

    <%= content %>

    ENTRYPOINT ["<%= entrypoint %>"]
    EOF
  end

  let(:dockerfile_expected) do
    <<~EOF
    FROM ubuntu:latest

    RUN echo 'hello'

    ENTRYPOINT ["barista"]
    EOF
  end

  test "Commands::Template happy path" do
    vars = {image: "ubuntu:latest", content: "RUN echo 'hello'", entrypoint: "barista"}
    task = ::Barista::Task.new("some-task")
    processed = task.erb(dockerfile, string: true, vars: vars)

    expect(processed).to eql(dockerfile_expected)
  end
end