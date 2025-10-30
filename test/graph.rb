module Barista
  class GraphSpec
    include Theorem::Hypothesis
  
    test "can add a node" do
      with_graph(nodes: ["foo", "bar"]) do |graph|
        expect(graph.nodes).to eql(["foo", "bar"])
      end
    end

    test "returns a vertex with no edges" do
      with_graph do |graph|
        v1 = graph.add("foo")
        expect(v1.class).to be(::Barista::Graph::Vertex)
        expect(v1.incoming_names).to eql([])
      end
    end

    test "add_edge connects two nodes" do
      with_graph(nodes: ["foo", "bar"]) do |graph|
        graph.add_edge("foo", "bar")
    
        foo = graph.vertices["foo"]
        expect(foo.incoming_names).to eql([])
        expect(foo.has_outgoing?).to be(true)

        bar = graph.vertices["bar"]
        expect(bar.incoming_names).to eql(["foo"])
        expect(bar.has_outgoing?).to be(false)
      end
    end

    test "can connect a node hierarchy" do
      with_graph(
        nodes: ["foo", "bar", "buzz"],
        edges: [%w[foo bar], %w[foo buzz], %w[bar buzz]]
      ) do |graph|
        buzz = graph.vertices["buzz"]
        
        expect(buzz.incoming_names).to eql(["foo", "bar"])
        expect(buzz.has_outgoing?).to be(false)

        bar = graph.vertices["bar"]
        expect(bar.incoming_names).to eql(["foo"])
        expect(bar.has_outgoing?).to be(true)

        foo = graph.vertices["foo"]
        expect(foo.incoming_names).to eql([])
        expect(foo.has_outgoing?).to be(true)
      end
    end

    test "returns a list of tasks that match the filtered tree" do
      with_graph(nodes: ["a", "b", "c", "d", "e"], edges: [%w[a e], %w[c e]]) do |graph|
        expect(graph.filter(["e", "b"])).to eql(["e", "b", "a", "c"])
      end
    end

    test "filters with a nested hierarchy" do
      with_graph(nodes: ["a", "b", "c", "d", "e", "f", "g", "h"], edges: [%w[a c], %w[c d], %w[c f], %w[c h], %w[h e]]) do |graph|
        expect(graph.filter(["e"])).to eql(["e", "h", "c", "a"])
      end
    end

    # test "raises an exception on cyclical reference" do
    #   with_graph(nodes: ["foo", "bar", "baz", "buzz"], edges: [{ "foo", "bar" }, { "bar", "baz" }, { "buzz", "foo" }]) do |graph|
    #     expect -> { graph.add_edge("baz", "buzz") }.to raise_error
    #   end
    # end

    def with_graph(nodes: [], edges: [], &block)
      graph = ::Barista::Graph.new

      nodes.each do |node|
        graph.add(node)
      end

      edges.each do |tuple|
        graph.add_edge(tuple[0], tuple[1])
      end

      block.call graph
    end
  end
end