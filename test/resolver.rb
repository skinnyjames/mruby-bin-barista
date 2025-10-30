class ResolverSpec
  include Theorem::Hypothesis

  test "resolves git" do
    resolver = resolve(git: "https://something.git")

    expect(resolver.class).to be(::Barista::GitResolver)
  end

  test "resolves github" do
    resolver = resolve(github: "skinnyjames/theorem")

    expect(resolver.class).to be(::Barista::GithubResolver)
  end

  test "resolves http" do
    resolver = resolve(http: "http://skinnyjames.net/something.tar.gz")

    expect(resolver.class).to be(::Barista::HTTPResolver)
  end

  test "resolves local" do
    resolver = resolve(path: "../some/dep")

    expect(resolver.class).to be(::Barista::LocalResolver)
  end

  def resolve(**args)
    ::Barista::Resolver.locate(**args)
  end
end
