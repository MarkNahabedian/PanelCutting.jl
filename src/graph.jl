
md"""
# Panel Graph

AbstractPanels are related to one another through a directed graph
based on various relations.  Here we construct the inverse directed graph,
which could be one-to-many.
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

function query(pg::PanelGraph, from, to)
    function querytest(elt, val)
        if val isa Type
            elt isa val
        else
            elt == val
        end
    end
    filter(p -> querytest(p.first, from) && querytest(p.second, to),
           pg.arcs)
end

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
    function inj(panels)
        for p in panels
            injest(rpg, p)
        end
    end
    inj(state.bought)
    inj(state.finished)
    inj(state.scrapped)
    inj(state.working)
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

export PanelGraph, nodes, arcs, query, injest, makePanelGraph
export transform, applyRule!

