# PanelCutGraph rewrites a PanelGraph to provide the same information
# in fewer nodes.

export PanelCutGraph

struct PanelCutGraph
    state::SearchState
    pg::PanelGraph
    graph::DiGraph
    
    function PanelCutGraph(state::SearchState, pg::PanelGraph)
        pcg = new(state, pg, DiGraph(pg.graph))
        applyRule!(pcg, insertCutNodes)
        applyRule!(pcg, elideBoughtPanels)
        applyRule!(pcg, elideTerminalPanels)
        pcg
    end

    PanelCutGraph(state::SearchState) =
        PanelCutGraph(state, makePanelGraph(state))
end

# Delegate to the underlying graphs
NahaGraphs.edges(pcg::PanelCutGraph) = edges(pcg.graph)
NahaGraphs.nodes(pcg::PanelCutGraph) = nodes(pcg.graph)
NahaGraphs.add_edge!(pcg::PanelCutGraph, edge) = add_edge!(pcg.graph, edge)
NahaGraphs.remove_edge!(pcg::PanelCutGraph, edge) = remove_edge!(pcg.graph, edge)
NahaGraphs.query(pcg::PanelCutGraph, from, to) = query(pcg.graph, from, to)

# Delegation for Dict support:
Base.keys(g::PanelCutGraph) = keys(g.graph)
Base.values(g::PanelCutGraph) = values(g.graph)
Base.haskey(g::PanelCutGraph, key) = haskey(g.graph, key)
Base.getindex(g::PanelCutGraph, key) = getindex(g.graph, key)

# Same display attributes as PanelGraph:
NahaGraphs.graph_attributes(pcg::PanelCutGraph) = graph_attributes(pcg.pg)
NahaGraphs.node_attributes(pcg::PanelCutGraph) = node_attributes(pcg.pg)
NahaGraphs.edge_attributes(pcg::PanelCutGraph) = edge_attributes(pcg.pg)

function NahaGraphs.dotnode(io::IO, graph::PanelCutGraph, panel::AbstractPanel)
    dotnode(io, graph.pg, panel)
end

 function NahaGraphs.dotedge(io::IO, graph::PanelCutGraph, from, to)
    dotedge(io, graph.pg, from, to)
end

struct CutNode
    panel1::Panel
    panel2::Union{Nothing, Panel}
end

function NahaGraphs.dotID(n::CutNode)
    return "CutNode_$(n.panel1.cut_from.uid)"
end

dotshape(::CutNode) = "trapezium"

function dotlabel(node::CutNode)
    join([
        dotID(node),
        "at: $(prettydistance(node.panel1.cut_at))",
        pretty(node.panel1.cut_axis),
    ], "\n")
end


#=

Each rule function takes a node as argument and returns two sets: edges
to add, and edges to remove.  The rule function uses transformingGraph
and the functions it prvides to accumulate these sets.

applyRule! takes a graph and a rule function as arguments.  It applies
the rule function to each node

=#


md"""
Compute the arguments to transform! in order to insert a
CutNode wherever a panel is cut.
"""
function insertCutNodes(pcg::PanelCutGraph, key)
    transformingGraph!() do check, add, remove
	check(key isa CuttablePanel)
	arcs = query(pcg, key, Panel)
	check(length(arcs) == 2)
	arc1, arc2 = Tuple(arcs)
	check(key == arc1.second.cut_from)
	check(key == arc2.second.cut_from)
	cutnode = CutNode(arc1.second, arc2.second)
	add(key => cutnode)
	remove(arc1)
	remove(arc2)
	add(cutnode => cutnode.panel1)
        add(cutnode => cutnode.panel2)
    end
end


md"""
Compute the arguments to transform! in order to elide a Panel that is
succeeded by a TerminalPanel.
"""
function elideTerminalPanels(rpg::PanelCutGraph, terminal)
    transformingGraph!() do check, add, remove
        check(terminal isa TerminalPanel)
        arcs2 = query(rpg, Panel, terminal)
        check(length(arcs2) == 1)
        arc2 = first(arcs2)
        panel = arc2.first
        arcs1 = query(rpg, CutNode, panel)
        check(length(arcs1) == 1)
        arc1 = first(arcs1)
        precursor = arc1.first
        add(precursor => terminal)
        remove(arc1)
        remove(arc2)
    end
end


md"""
Compute the arguments to transform! to elide BoughtPanels.
"""
function elideBoughtPanels(rpg::PanelCutGraph, bought)
    transformingGraph!() do check, add, remove
	check(bought isa BoughtPanel)
	arcs1 = query(rpg, AvailablePanel, bought)
	check(length(arcs1) == 1)
	arc1 = first(arcs1)
	arcs2 = query(rpg, bought, CutNode)  # insertCutNodes has already been applied.
	check(length(arcs2) == 1)
	arc2 = first(arcs2)
	remove(arc1)
	remove(arc2)
	add(arc1.first => arc2.second)
    end
end
