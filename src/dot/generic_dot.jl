# Code for writing GraphViz Dot files from graphs.

md"""
# Generic Dot Code
"""

md"""
The `graph` argumrnt to these functions should support the
following methods:

  - nodes
  - edges
  - dotID
  - dotnode
  - dotedge

See the documentation for those methods.

Default *no-op* methods are provided here where reasonable.
"""

export dotID, dotgraph, dotnode, dotedge
export dotescape, diarc, dot_attributes_string
export rundot, DotError


"""
   nodes(graph)

Return a collection of all of the nodes of `graph`.
"""
function nodes end


"""
    edges(graph)

Return a collection of all of the edges of `graph`.
Each element of the collections is a Pair associating one
nodeof the graph with another.
"""
function edges end


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
Write a GraphViz dot file for the specified graph.
"""
function dotgraph end

struct DotError <: Exception
    command
    error
    stdout
    stderr
end

function Base.showerror(io::IO, e::DotError)
    write(io, "Error running dot:\n($e.command)\n$(e.stderr)\n")
end


DOT_COMMAND = Graphviz_jll.dot()

md"""
    rundot(path)

Run the GraphViz dot command on the specified dot file
to produce an SVG file with the same basename.
"""
function rundot(path)
    out = IOBuffer()
    err = IOBuffer()
    cmd = `$DOT_COMMAND -Tsvg -O $path`
    try
        Base.run(pipeline(cmd; stdout=out, stderr=err))
    catch e
        throw(DotError(cmd, e, String(take!(out)), String(take!(err))))
    end
end


"""
    dotgraph(path::String, graph, dotstyle)

Write the graph to the specified file.
If the file extension is `dot` then a GraphViz dot file is written.
Otherwise a dot description of `graph` is piped through the dot command,
the output of which will be written to `psth`.
"""
function dotgraph(path::String, graph, dotstyle;
                  dot_command=DOT_COMMAND)
    _, ext = splitext(path)
    if ext == ".dot"
        open(path, "w") do io
            dotgraph(io, graph, dotstyle)
        end
    else
        # If the file type is anything other than "dot" then run the
        # dot command to generate the file:
        ext = ext[2:end]
        cmd = `$dot_command -T$ext -o$path`
        proc = run(cmd,
                   Base.PipeEndpoint(),
                   IOBuffer(),
                   IOBuffer();
                   wait=false)
        dotgraph(proc.in, graph, dotstyle)
        close(proc.in)
        wait(proc)
        @assert isempty(take!(proc.out))
        error_message = String(take!(proc.err))
        if error_message != ""
            throw(DotError(cmd, nothing, nothing,
                           read(error_message, String)))
        end
    end
    return path
end


md"""
    dotgraph(io::IO, graph, dotstyle)

Write a dot description of `graph` to `io`.
"""
function dotgraph(io::IO, graph, dotstyle)
    write(io, "digraph panels {\n")
    for (word, fun) in (("graph", graph_attributes),
                        ("node", node_attributes),
                        ("edge", edge_attributes))
        attrs = fun(dotstyle)
        if !isempty(attrs)
            write(io, "$word [$(dot_attributes_string(attrs))]\n")
        end
    end
    for node in nodes(graph)
        dotnode(io, graph, dotstyle, node)
    end
    for arc in edges(graph)
        dotedge(io, graph, dotstyle, arc.first, arc.second)
    end
    write(io, "}\n")
end


"""
    dotID(node)

Return a string to be used as the id of node in a GraphViz dot file.
"""
function dotID(x)
    string(x)
end


"""
    dotnode(io::IO, graph, dotstyle, node)

Write a Dot node statement to `io` describing `node`.
"""
function dotnode(io::IO, graph, dotstyle, node)
    id = dotescape(dotID(node))
    attrs = dot_attributes_string(node_attributes(dotstyle, node))
    if !isempty(attrs)
        attrs = " [" * attrs * "]"
    end
    write(io, """  $id$attrs\n""")
end


"""
    dotedge(io::IO, graph, dotstyle, from, to)

Write a Dot edge statement to `io` describing an edge from
`from` to `to`.
"""
function dotedge(io::IO, graph, dotstyle, from, to)
    diarc(io, from, to; edge_attributes(dotstyle, from, to)...)
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

"""
diark is a convenience function for `dotedge` methods to call.
"""
function diarc(io::IO, from, to; kwargs...)
    attrs = dot_attributes_string(; kwargs...)
    if !isempty(attrs)
        attrs = " [" * attrs * "]"
    end
    write(io, "  $(dotescape(dotID(from))) -> $(dotescape(dotID(to)))$attrs\n")
end

