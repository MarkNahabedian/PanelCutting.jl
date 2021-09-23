using Markdown
using Logging
using UUIDs

begin

  struct NonlocalTransfer <: Exception
    uid

    function NonlocalTransfer()
      new(UUIDs.uuid1())
    end
  end

  function Base.showerror(io::IO, e::NonlocalTransfer)
    print(io, "NonlocalTransfer not caught!")
  end

  function transformingGraph(f)
	addset = Set()
	removeset = Set()
	exittag = NonlocalTransfer()
	add(arc) = push!(addset, arc)
	remove(arc) = push!(removeset, arc)
	function check(condition)
	  if !condition
		throw(exittag)
	  end
	end
	try
	  f(check, add, remove)
	catch e
	  if e != exittag
		rethrow(e)
	  end
	end
	return addset, removeset
  end

end

begin
  struct PanelCutGraph
    state::SearchState
    rpg::PanelGraph

    function PanelCutGraph(state::SearchState)
      pcg = new(state, makePanelGraph(state))
	  applyRule!(pcg.rpg, addCutNodes)
	  applyRule!(pcg.rpg, elideBoughtPanels)
	  applyRule!(pcg.rpg, elideTerminalPanels)
      pcg
    end
  end

  PanelCutting.arcs(pcg::PanelCutGraph) = arcs(pcg.rpg)

  PanelCutting.nodes(pcg::PanelCutGraph) = PanelCutting.nodes(pcg.rpg)

  struct CutNode
    panel1::Panel
    panel2::Panel
  end

  function PanelCutting.dotID(n::CutNode)
    return "CutNode_$(n.panel1.cut_from.uid)"
  end

  function PanelCutting.dotnode(io::IO, pcg::PanelCutGraph, n::CutNode)
    write(io, """  "$(dotID(n))"[shape=pentagon; label="$(dotnodelabel(pcg, n))"]\n""")
    return n
  end

  function dotnodelabel(pcg::PanelCutGraph, n::CutNode)::String
    from = if n.panel1.cut_axis isa LengthAxis
      "from end"
    elseif n.panel1.cut_axis isa WidthAxis
      "from side"
    end
    return "cut $(n.panel1.cut_at) $(from)"
  end
	
  md"""
  Compute the arguments to transform! in order to insert a
  CutNode wherever a panel is cut.
  """
  function addCutNodes(rpg::PanelGraph, key)
	transformingGraph() do check, add, remove
	  check(key isa CuttablePanel)
	  arcs = query(rpg, key, Panel)
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
  function elideTerminalPanels(rpg::PanelGraph, terminal)
    transformingGraph() do check, add, remove
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
  function elideBoughtPanels(rpg::PanelGraph, bought)
	transformingGraph() do check, add, remove
	  check(bought isa BoughtPanel)
	  arcs1 = query(rpg, AvailablePanel, bought)
	  check(length(arcs1) == 1)
	  arc1 = first(arcs1)
	  arcs2 = query(rpg, bought, Any)
	  check(length(arcs2) == 1)
	  arc2 = first(arcs2)
	  remove(arc1)
	  remove(arc2)
	  add(arc1.first => arc2.second)
	end
  end

#=
  function dotnodelabel(graph::PanelCutGraph, panel::BoughtPanel)::String
    return *("{",
			join(["$(split(string(typeof(panel)), ".")[end])",
                    "l: $(panel.length)",
                    "w: $(panel.width)",
                    "cost: $(panel.cost)"],
                   "|"),
              "}")
  end

  function dotnodelabel(graph::PanelCutGraph, panel::AvailablePanel)::String
    return *("{",
			join(["$(split(string(typeof(panel)), ".")[end])",
                    "l: $(panel.length)",
                    "w: $(panel.width)",
                    "cost: $(panel.cost)"],
                   "|"),
              "}")
  end

  function dotnodelabel(graph::PanelCutGraph, panel::FinishedPanel)::String
    return *("{",
			join(["$(split(string(typeof(panel)), ".")[end])",
					"$(panel.label)",
                    "l: $(panel.length)",
                    "w: $(panel.width)",
                    "x: $(panel.x)",
                    "y: $(panel.y)",
                    "cost: $(panel.cost)"],
                   "|"),
              "}")
  end

  function dotnodelabel(graph::PanelCutGraph, panel::AbstractPanel)::String
    return *("{",
			join(["$(split(string(typeof(panel)), ".")[end])",
                    "l: $(panel.length)",
                    "w: $(panel.width)",
                    "x: $(panel.x)",
                    "y: $(panel.y)",
                    "cost: $(panel.cost)"],
                   "|"),
              "}")
  end

  function PanelCutting.dotnode(io::IO, graph::PanelCutGraph, panel::AbstractPanel)
    write(io, """  "$(dotID(panel))"[shape=record; label="$(dotnodelabel(graph, panel))"]\n""")
  end
=#
end



@testset "Graph Rewrite" begin
    # Some test data
    wanda_box_panels = [
        WantedPanel(length=25u"inch", width=30u"inch", label="back")
        WantedPanel(length=25u"inch", width=22u"inch", label="right side")
        WantedPanel(length=25u"inch", width=22u"inch", label="left side")
        WantedPanel(length=22u"inch", width=30u"inch", label="top")
        WantedPanel(length=22u"inch", width=30u"inch", label="bottom")
    ]
    sort(wanda_box_panels; lt=smaller, rev=true)

    BOULTER_PLYWOOD = Supplier(
	name = "Boulter Plywood",
	kerf = (1/8)u"inch",
	cost_per_cut = money(1.50),
	available_stock = [
            AvailablePanel("4 x 8 x 1/2", 4u"ft", 8u"ft", money(95.00)),
            AvailablePanel("5 x 5 x 1/2", 5u"ft", 5u"ft", money(49.00)),
            AvailablePanel("30 x 60 x 1/2", 30u"inch", 60u"inch", money(30.00)),
            AvailablePanel("30 x 30 x 1/2", 30u"inch", 30u"inch", money(19.00))
        ])

    logger = Logging.ConsoleLogger(show_limited=false)   # VectorLogger()
    with_logger(logger) do
        searcher = Searcher(BOULTER_PLYWOOD, wanda_box_panels[1:2])
        search(searcher)
        # ***** debug graph transformations:
        g = makePanelGraph(searcher.cheapest)
        base_path = "c:/Users/Mark Nahabedian/.julia/dev/PanelCutting/test/"
        message = "Wrote graph file"
        @info message, path=dotgraph(base_path*"two-panels-0.svg", g)
        applyRule!(g, addCutNodes)
        @info message, path=dotgraph(base_path*"two-panels-1.svg", g)
        applyRule!(g, elideBoughtPanels)
        @info message, path=dotgraph(base_path*"two-panels-2.svg", g)
        applyRule!(g, elideTerminalPanels)
        @info message, path=dotgraph(base_path*"two-panels-3.svg", g)
        # Back to our regularly scheduloed report
        # report(searcher)
    end

end
