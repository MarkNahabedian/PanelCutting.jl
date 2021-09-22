
md"""
# Generic Dot Code
"""

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
    ext = splitext(path)[2][2:end]
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
    for node in nodes(graph)
        dotnode(io, graph, node)
    end
    for arc in arcs(graph)
        diarc(io, graph, arc.first, arc.second)
    end
    write(io, "}\n")
end

"""
    dotID(node)
Return a string to be used at the id of node in a GraphViz dot file.
"""
function dotID end

function dotnode(io::IO, graph, node)
    write(io, """  "$(dotID(node))"\n""")
end

function diarc(io::IO, graph, arc::Pair)
    diarc(io, graph, arc.from, arc.to)
end

function diarc(io::IO, graph, from, to)
    write(io, """  "$(dotID(from))" -> "$(dotID(to))"\n""")
end

export dotgraph, dotID, rundot, dotnode, diarc

