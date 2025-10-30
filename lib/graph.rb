module Barista
  class GraphCyclicalError < StandardError; end

  class Graph
    attr_reader :nodes, :vertices

    def initialize(nodes = [], vertices = {})
      @nodes = nodes
      @vertices = vertices
    end

    def add(node)
      if vertex = vertices[node]
        return vertex
      end

      vertex = Vertex.new(name: node)
      vertices[node] = vertex
      nodes << node

      vertex
    end

    def add_edge(from, to)
      return if from == to

      from_vertex = add(from)
      to_vertex = add(to)

      return if to_vertex.incoming[from]

      Graph::Visitor.visit(vertex: from_vertex, callback: ensure_non_cylical(to))

      from_vertex.has_outgoing = true

      to_vertex.incoming[from] = from_vertex
      to_vertex.incoming_names << from

      vertices[from] = from_vertex
      vertices[to] = to_vertex
    end

    def filter(names, result = names.dup)
      return result.uniq if names.empty?

      name = names.shift
      vertex = vertices[name]
      result = (result + vertex.incoming_names)

      result.concat filter((vertex.incoming_names - names), result)
      filter(names, result)
    end

    def ensure_non_cylical(to)
      ->(vertex, path) do
        if vertex.name == to
          raise GraphCyclicalError.new("Cyclical reference detected: #{to} <- #{path.join(" <- ")}")
        end
      end
    end
  end

  class Graph::Vertex
    attr_accessor :name, :incoming, :incoming_names, :has_outgoing

    def initialize(name:, incoming: {}, incoming_names: [], has_outgoing: false)
      @name = name
      @incoming = incoming
      @incoming_names = incoming_names
      @has_outgoing = has_outgoing
    end

    def has_outgoing?
      has_outgoing
    end
  end

  class Graph::Visitor
    def self.visit(vertex:, callback:, visited: {}, path: [])
      node = vertex.name
      incoming = vertex.incoming
      incoming_names = vertex.incoming_names

      return if visited[node]

      path << node
      visited[node] = true

      incoming_names.each do |name|
        visit(vertex: incoming[name], callback: callback, visited: visited, path: path)
      end

      callback.call(vertex, path)
      path.pop
    end
  end
end