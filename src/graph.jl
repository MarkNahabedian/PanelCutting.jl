
md"""
# Panel Graph

AbstractPanels are related to one another through a directed graph
based on various relations.  Here we construct the inverse directed graph,
which could be one-to-many, as a Dict.
"""

struct PanelGraph
    arcs::Set{Pair}
    
    PanelGraph() = new(Set{Pair{AbstractPanel, AbstractPanel}}())
end

function injest(rpg::PanelGraph, pair::Pair)
    push!(rpg.arcs, pair)
end

function Base.haskey(rpg::PanelGraph, key)::Bool
    for p in rpg.arcs
	if p.first == key
	    return true
	end
    end
    return false
end

Base.keys(rpg::PanelGraph) =
    Set([p.first for p in rpg.arcs])

Base.values(rpg::PanelGraph) =
    Set([p.second for p in rpg.arcs])

nodes(rpg::PanelGraph) = union(keys(rpg), values(rpg))

arcs(rpg::PanelGraph) = rpg.arcs

Base.getindex(rpg::PanelGraph, key) =
    (p -> p.second).(filter(p -> p.first == key, rpg.arcs))

havingKey(rpg::PanelGraph, key) =
    filter(p -> p.first == key, rpg.arcs)

havingValue(rpg::PanelGraph, value) =
    filter(p -> p.second == value, rpg.arcs)

query(rpg::PanelGraph, from, to) =
    filter(p -> p.first == from && p.second == to, rpg.arcs)

query(rpg::PanelGraph, fromtype::Type, to) =
    filter(p -> isa(p.first, fromtype) && p.second == to, rpg.arcs)

query(rpg::PanelGraph, from, toType::Type) =
    filter(p -> p.first == from && isa(p.second, toType), rpg.arcs)

query(rpg::PanelGraph, fromType::Type, toType::Type) =
    filter(p -> isa(p.first, fromType) && isa(p.second, toType), rpg.arcs)

function injest(rpg::PanelGraph, panel::AbstractPanel)
end

function injest(rpg::PanelGraph, panel::BoughtPanel)
    push!(rpg.arcs, (panel.was) => panel)
    injest(rpg, panel.was)
end

function injest(rpg::PanelGraph, panel::TerminalPanel)
    push!(rpg.arcs, (panel.was) => panel)
    injest(rpg, panel.was)
end

function injest(rpg::PanelGraph, panel::Panel)
    push!(rpg.arcs, (panel.cut_from) => panel)
    injest(rpg, panel.cut_from)
end

function makePanelGraph(state::SearchState)::PanelGraph
    rpg = PanelGraph()
    for f in state.finished
	injest(rpg, f)
    end
    for s in state.scrapped
	injest(rpg, s)
    end
    return rpg
end

function transform!(rpg::PanelGraph, addarcs, removearcs)
    setdiff!(rpg.arcs, removearcs)
    union!(rpg.arcs, addarcs)
    return nothing
end

function applyRule!(rpg::PanelGraph, rule)
    nodes(rpg) .|>
	(node -> rule(rpg, node)) .|>
	(ar -> transform!(rpg, ar...))
end

export PanelGraph, nodes, arcs, havingKey, havingValue, query,
    injest, makePanelGraph
export transform, applyRule!

