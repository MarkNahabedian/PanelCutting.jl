md"""
# Panel Graph

AbstractPanels are related to one another through a directed graph
based on various relations.  Here we construct the inverse directed graph,
which could be one-to-many.
"""

export PanelGraph, injest, makePanelGraph
export nodes, edges, query

struct PanelGraph
    graph::DiGraph
    
    PanelGraph() = new(DiGraph())
end

# Delegation to the underlying DiGraph:

NahaGraphs.add_edge!(pg::PanelGraph, edge::Pair) = add_edge!(pg.graph, edge)

function Base.haskey(pg::PanelGraph, key)::Bool
    haskey(pg.graph, key)
end

Base.keys(pg::PanelGraph) = keys(pg.graph)

Base.values(pg::PanelGraph) = values(pg.graph)

NahaGraphs.nodes(pg::PanelGraph) = union(keys(pg), values(pg))

NahaGraphs.edges(pg::PanelGraph) = edges(pg.graph)

Base.getindex(pg::PanelGraph, key) =
    (p -> p.second).(filter(p -> p.first == key, edges(pg)))

NahaGraphs.query(pg::PanelGraph, from, to) = query(pg.graph, from, to)


# Building the graph from the panel structure

function injest(pg::PanelGraph, pair::Pair)
    add_edge!(pg.graph, pair)
end

function injest(pg::PanelGraph, panel::AbstractPanel)
    # No-op default method
end

function injest(pg::PanelGraph, panel::BoughtPanel)
    add_edge!(pg, (panel.was) => panel)
    injest(pg, panel.was)
end

function injest(pg::PanelGraph, panel::TerminalPanel)
    add_edge!(pg, (panel.was) => panel)
    injest(pg, panel.was)
end

function injest(pg::PanelGraph, panel::Panel)
    add_edge!(pg, (panel.cut_from) => panel)
    injest(pg, panel.cut_from)
end

function makePanelGraph(state::SearchState)::PanelGraph
    pg = PanelGraph()
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

