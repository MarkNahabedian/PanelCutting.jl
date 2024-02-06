
import Graphs
import MetaGraphsNext

export PanelGraph, injest

Base.isless(p1::AbstractPanel, p2::AbstractPanel) =
    isless(p1.uid, p2.uid)


"""
PanelGraph is a directed graph constructed from a tree of
`AbstractPanel`s.  It servesd as a reverse index and as a platform on
which graph utilities can be applied.
"""
struct PanelGraph{T}
    graph
    
    PanelGraph{T}() where T =
        new{T}(MetaGraphsNext.MetaGraph(Graphs.DiGraph();
                                        label_type=T))
end

Base.length(pg::PanelGraph) = length(pg.graph)


# Most of the graph code in PanelCutting just adds AbstractPanel to
# AbstractPanel edges to a graph and assumes those AbstractPanel nodes
# will be added implicitly.  This is the fnction that adds the
# vertices when needed.
function ensure_vertex(pg::PanelGraph{T}, p::T) where T
    if !haskey(pg.graph, p)
        @assert Graphs.add_vertex!(pg.graph, p)
    end
    p
end


# The nodes and edges functions provide a layer of abstraction around
# the MetaGraphsNext implementation:

nodes(pg::PanelGraph) = MetaGraphsNext.labels(pg.graph)

edges(pg::PanelGraph) =
    map(e -> e[1] => e[2], MetaGraphsNext.edge_labels(pg.graph))

Base.getindex(pg::PanelGraph, key) =
    (p -> p.second).(filter(p -> p.first == key, edges(pg)))


add_edge!(pg::PanelGraph{T}, edge1::T, edge2::T) where T =
    Graphs.add_edge!(pg.graph,
                     ensure_vertex(pg, edge1),
                     ensure_vertex(pg, edge2))

add_edge!(pg::PanelGraph, edge::Pair) =
    add_edge!(pg, edge.first, edge.second)


function PanelGraph(copy_from::PanelGraph{T}) where T
    new_graph = PanelGraph{T}()
    for n in nodes(copy_from)
        ensure_vertex(new_graph, n)
    end
    for e in edges(copy_from)
        add_edge!(new_graph, e...)
    end
    new_graph
end

function PanelGraph(state::SearchState)::PanelGraph
    pg = PanelGraph{AbstractPanel}()
    function inj(panels)
        for p in panels
            injest(pg, p)
        end
    end
    inj(state.bought)
    inj(state.finished)
    inj(state.scrapped)
    inj(state.working)
    return pg
end

injest(pg::PanelGraph{T}, edge::Pair{T, T}) where T =
    add_edge!(pg, edge.first, edge.second)

function injest(pg::PanelGraph, panel::AbstractPanel)
    # No-op default method
end

function injest(pg::PanelGraph, panel::BoughtPanel)
    add_edge!(pg, panel.was, panel)
    injest(pg, panel.was)
end

function injest(pg::PanelGraph, panel::TerminalPanel)
    add_edge!(pg, (panel.was), panel)
    injest(pg, panel.was)
end

function injest(pg::PanelGraph, panel::Panel)
    add_edge!(pg, (panel.cut_from), panel)
    injest(pg, panel.cut_from)
end

function query(pg::PanelGraph, from, to)::Set
    function querytest(p, val)
        if val isa Type
            p isa val
        else
            p == val
        end
    end
    Set(filter(e -> querytest(e.first, from) && querytest(e.second, to),
               edges(pg)))
end

