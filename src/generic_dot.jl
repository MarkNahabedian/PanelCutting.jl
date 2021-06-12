
md"""
# Generic Dot Code
"""

md"""
Write a GraphViz dot file describing the panel cutting progression
described in a SearchState.
"""
function dotgraph end

function rundot(path)
    Base.run(`dot -Tsvg -O $path`)
end

function dotgraph(path::String, graph)
    open(path, "w") do io
        dotgraph(io, graph)
    end
    return path
end

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

