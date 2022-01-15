
md"""
# Generic Dot Code
"""

md"""
The `graph` argumrnt to these functions should support the
following methods:

  - nodes
  - edges
  - graph_attributes
  - node_attributes
  - edge_attributes
  - dotID
  - dotnode
  - dotedge

See the documentation for those methods.

Default *no-op* methods are provided here where reasonable.
"""

export  nodes, edges, graph_attributes, node_attributes, edge_attributes


"""
   nodes(graph)
Return a collection of all of the nodes of `graph`.
"""


"""
    edges(graph)
Return a collection of all of the edges of `graph`.
Each element of the collections is a Pair associating one
nodeof the graph with another.
"""


"""
    graph_attributes(graph)
Return a Dict of graph level attributes (for the Dot `graph` statement)
"""
graph_attributes(graph) = Dict{Symbol, AbstractString}()


"""
    node_attributes(graph)
Return a Dict of node attributes that should apply to all nodes of `graph`.
"""
node_attributes(graph) = Dict{Symbol, AbstractString}()


"""
    edge_attributes(graph)
Return a Dict of attributes that should apply to all edges of `graph`.
"""
edge_attributes(graph) = Dict{Symbol, AbstractString}()



"""
    dotescape(::AbstractString)::AbstractString
Escape an `ID` in the GraphViz Dot language.  'ID' is
the fundamental token in Dot.
"""
function dotescape(s::AbstractString)::AbstractString
    "\"" *
        replace(s, "\"" => "\\\"") *
        "\""
end


dotescape(s::Symbol) = dotescape(string(s))


md"""
Write a GraphViz dot file describing the panel cutting progression
described in a SearchState.
"""
function dotgraph end

md"""
    rundot(path)
Run the GraphViz dot command on the specified dot file
to produce an SVG file with the same basename.
"""
function rundot(path)
    Base.run(`dot -Tsvg -O $path`)
end

md"""
    dotgraph(path::String, graph)
Write the graph to the specified file.
If the file extension is `dot` then a GraphViz dot file is written.
Otherwise a dot description of `graph` is piped through the dot command,
the output of which will be written to `psth`.
"""
function dotgraph(path::String, graph)
    ext = last(splitext(path))[2:end]
    if ext == "dot"
        open(path, "w") do io
            dotgraph(io, graph)
        end
    else
        # If the file type is anything other than "dot" then run the
        # dot command to generate the file
        dot = IOBuffer()
        err = IOBuffer()
        cmd = `dot -T$ext -o$path`
        try
            proc = run(pipeline(cmd, stdin=dot,
                                stderr=err
                                # stderr=path*".stderr"
                                ))
            @info("dot exit status", status=proc.exitcode, cmd=cmd)
        catch e
            @warn("Error running dot: $e")
        end
        dotgraph(dot, graph)
        err = read(err, String)
        if length(err) > 0
            @warn("Error running dot", err=err)
        end
    end
    return path
end

md"""
    dotgraph(io::IO, graph)
Write a dot description of `graph` to `io`.
"""
function dotgraph(io::IO, graph)
    write(io, "digraph panels {\n")
    for (word, fun) in (("graph", graph_attributes),
                        ("node", node_attributes),
                        ("edge", edge_attributes))
        attrs = fun(graph)
        if !isempty(attrs)
            write(io, "$word [$(dot_attributes_string(attrs))]\n")
        end
    end
    for node in nodes(graph)
        dotnode(io, graph, node)
    end
    for arc in edges(graph)
        dotedge(io, graph, arc.first, arc.second)
    end
    write(io, "}\n")
end


"""
    dotID(node)
Return a string to be used as the id of node in a GraphViz dot file.
"""
function dotID end


"""
    dotnode(io::IO, graph, node)
Write a Dot node statement to `io` describing `node`.
"""
function dotnode(io::IO, graph, node)
    write(io, """  "$(dotescape(dotID(node)))"\n""")
end


"""
    dotedge(io::IO, graph, from, to)
Write a Dot edge statement to `io` describing an edge from
`from` to `to`.
"""
function dotedge(io::IO, graph, from, to)
    diarc(io, from, to)
end

function dot_attributes_string(attrs::Dict)::String
    a = []
    for (key, val) in attrs
        push!(a, "$(dotescape(key))=$(dotescape(val))")
    end
    join(a, "; ")
end

function dot_attributes_string(; kwargs...)::String
    attrs = []
    for (key, val) in kwargs
        push!(attrs, "$(dotescape(key))=$(dotescape(val))")
    end
    join(attrs, "; ")
end

function diarc(io::IO, arc::Pair, kwargs...)
    diarc(io, arc.first, arc.second; kwargs...)
end

function diarc(io::IO, from, to; kwargs...)
    attrs = dot_attributes_string(; kwargs...)
    write(io, "  $(dotescape(dotID(from))) -> $(dotescape(dotID(to))) [$attrs]\n")
end

export dotescape, dotgraph, dotID, rundot, dotnode, dotedge, diarc, dot_attributes_string

