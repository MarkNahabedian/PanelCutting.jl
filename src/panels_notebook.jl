### A Pluto.jl notebook ###
# v0.14.7

using Markdown
using InteractiveUtils

# ╔═╡ b019d660-9f77-11eb-1527-278a3e1b087c
begin
  using Pkg
  # Pkg.activate(mktempdir())
  Pkg.activate(mkpath("c:/Users/Mark Nahabedian/.julia/dev/PanelCutting"))

  # Pkg.add.([
  #       # Unitful version constrained by UnitfulCurrency
  #   Pkg.PackageSpec(name="Unitful", version="0.17.0"),
  #   Pkg.PackageSpec(name="UnitfulUS" #= , version="0.2.0" =#),
  #       Pkg.PackageSpec(name="UnitfulCurrency"),
  #       "Match",
  #   # Pkg.PackageSpec(name="Match", version="1.1.0"),
  #       "DataStructures",
  #   # Pkg.PackageSpec(name="DataStructures", version="0.18.9"),
  #       "DisplayAs",
  #   # Pkg.PackageSpec(name="DisplayAs", version="0.1.2"),
  #   Pkg.PackageSpec(; name="NativeSVG",
  #                   path="c:/Users/Mark Nahabedian/.julia/dev/NativeSVG.jl"),
  #       "MacroTools",
  #       "Plots",
  #       # "BackendPackage"
  #       ])

  using Revise
  using Unitful
  using UnitfulUS
  using Match
  using DataStructures
  using UnitfulCurrency
  using NativeSVG
  using DisplayAs
  using UUIDs
  using Plots
  using Printf

  using PanelCutting

  import MacroTools
end

# ╔═╡ 5f5c5ef3-efed-4afd-b304-5b37a9a81bd2
LOAD_PATH

# ╔═╡ 60eb1ca9-cf1f-46d6-b9b9-ee9fb41723d1
md"""
  # Setup

  Prefer inches.
  """

# ╔═╡ 60fdb133-5d21-4445-90f9-3bbe49fb743b
begin
  Unitful.preferunits(u"inch")
end

# ╔═╡ ecacafd3-5f70-41d9-b6cd-6b4893186b2a
begin
  wanda_box_panels = [
    WantedPanel(length=25u"inch", width=30u"inch", label="back")
    WantedPanel(length=25u"inch", width=22u"inch", label="right side")
    WantedPanel(length=25u"inch", width=22u"inch", label="left side")
    WantedPanel(length=22u"inch", width=30u"inch", label="top")
    WantedPanel(length=22u"inch", width=30u"inch", label="bottom")
  ]
  sort(wanda_box_panels; lt=smaller, rev=true)
end

# ╔═╡ f6a43438-d7b0-442d-bb05-9e4488855665
md"""
  ### Supplier Data

  Taken from boulterplywood.com
  """

# ╔═╡ 65adef2d-9a53-4310-81a0-5dbb6d0918ca
begin    # Supplier Data
	
  BOULTER_PLYWOOD = Supplier(
		name = "Boulter Plywood",
		kerf = (1/8)u"inch",
		cost_per_cut = 1.50u"USD",
		available_stock = [
    AvailablePanel("4 x 8 x 1/2", 4u"ft", 8u"ft", 95u"USD"),
    AvailablePanel("5 x 5 x 1/2", 5u"ft", 5u"ft", 49u"USD"),
    AvailablePanel("30 x 60 x 1/2", 30u"inch", 60u"inch", 30u"USD"),
    AvailablePanel("30 x 30 x 1/2", 30u"inch", 30u"inch", 19u"USD")
  ])
end

# ╔═╡ df84b1ad-cbd5-4f7b-a37e-30534b17adcf
md"""
# Reverse Graph

AbstractPanels are related to one another through a directed graph
based on various relations.  Here we construct the inverse directed graph,
which could be one-to-many, as a Dict.
"""

# ╔═╡ 148e3f7f-4ac6-4e57-be5d-fb4082bf1154
begin
	struct ReversePanelGraph
		arcs::Set{Pair}
	
		ReversePanelGraph() = new(Set{Pair{AbstractPanel, AbstractPanel}}())
	end
	
	function Base.haskey(rpg::ReversePanelGraph, key)::Bool
		for p in rpg.arcs
			if p.first == key
				return true
			end
		end
		return false
	end

	Base.keys(rpg::ReversePanelGraph) =
		Set([p.first for p in rpg.arcs])

	Base.values(rpg::ReversePanelGraph) =
		Set([p.second for p in rpg.arcs])
	
	nodes(rpg::ReversePanelGraph) = union(keys(rpg), values(rpg))
	
	arcs(rpg::ReversePanelGraph) = rpg.arcs

	Base.getindex(rpg::ReversePanelGraph, key) =
		(p -> p.second).(filter(p -> p.first == key, rpg.arcs))

	havingKey(rpg::ReversePanelGraph, key) =
		filter(p -> p.first == key, rpg.arcs)
	
	havingValue(rpg::ReversePanelGraph, value) =
		filter(p -> p.second == value, rpg.arcs)

	function injest(rpg::ReversePanelGraph, panel::AbstractPanel)
	end

	function injest(rpg::ReversePanelGraph, panel::BoughtPanel)
	  push!(rpg.arcs, (panel.was) => panel)
	  injest(rpg, panel.was)
	end

	function injest(rpg::ReversePanelGraph, panel::TerminalPanel)
		push!(rpg.arcs, (panel.was) => panel)
		injest(rpg, panel.was)
	end

	function injest(rpg::ReversePanelGraph, panel::Panel)
		push!(rpg.arcs, (panel.cut_from) => panel)
		injest(rpg, panel.cut_from)
	end

	function makeReversePanelGraph(state::SearchState)::ReversePanelGraph
		rpg = ReversePanelGraph()
		for f in state.finished
			injest(rpg, f)
		end
		for s in state.scrapped
			injest(rpg, s)
		end
		return rpg
	end

	function transform!(rpg::ReversePanelGraph, addarcs, removearcs)
		setdiff!(rpg.arcs, removearcs)
		union!(rpg.arcs, addarcs)
		return nothing
	end

	function applyRule!(rpg::ReversePanelGraph, rule)
	  nodes(rpg) .|>
		(node -> rule(rpg, node)) .|>
		(ar -> transform!(rpg, ar...))
	end
end

# ╔═╡ 85f95152-93a2-42cd-80f3-c3d7d931dbfe
md"""
# Describing the Cuts using SVG
"""

# ╔═╡ 2e1e9fc8-6209-4968-bf7e-fa97b72ebef3
const STYLESHEET = """
  g.everything {
  }
  g.everything * { 
    vector-effect: non-scaling-stroke;
  }
  .cut {
    stroke-width: 1px;
    stroke: rgb(0%,50%, 50%);
    stroke-dasharray: 4 4;
  }
  .factory-edge {
    stroke-width: 1px; stroke: blue;
    fill: none;
  }
  .finished {
    stroke: none;
    fill: rgba(0%, 50%, 0%, 50%);
  }
  text.finished {
	color: white;
    text-anchor: middle;
	font-family: sans-serif;
    font-size: 2px;
	vector-effect: non-scaling-stroke;
  }
"""

# ╔═╡ 134ac318-adb5-4939-96f7-3b70b12ffe43
#=
macro thismodule()
	:($__module__)
end
=#

# ╔═╡ d5b1c891-9529-4876-839f-cddd94d3d800
#= this macro does not play well with Pluto notebooks

begin
	# Abstract measurements in svg user space from the dimensions we use
	# for measuring panels:
	@Unitful.unit svgd "svgd" SVGDistance 0.01u"inch" false
	Unitful.register(@thismodule)
end
=#

# ╔═╡ 9d0fb461-46e4-4436-a367-5cdf3406474f
"""
turn a Unitful length quantity to a floating point number we can use in SVG.
"""
function svgdistance(d)::Real
	ustrip(Real, u"inch", d)
end

# ╔═╡ c2a34850-17eb-43ca-b6c1-262dc67d6006
function panelrect(io::IO, panel::AbstractPanel, cssclass::String)
	# It's confusing that panel.width corresponds to SVG length
	# and panel.length corresponds to SVG width.  Sorry.
	# This is a consequence of the x and y coordinaces of a panel
	# corresponding with the panel's length and width respectively.
	g(io) do
		write(io, string("<!-- $(panel.label): ",
				 "$(panel.width) by $(panel.length), ",
				 "at $(panel.x), $(panel.y) -->\n"))
		rect(io; class=cssclass,
			 x=svgdistance(panel.x),
			 y=svgdistance(panel.y),
			 width=svgdistance(panel.length),
			 height=svgdistance(panel.width)) do
		  if panel isa FinishedPanel
		    title(io) do
			  print(io, "$(panel.length) × $(panel.width)")
		    end
		  end
		end
		if panel isa FinishedPanel
		  NativeSVG.text(io;
				class = cssclass,
				x = svgdistance(panel.x + panel.length / 2),
				y = svgdistance(panel.y + panel.width / 2)) do
			write(io, "$(panel.length) × $(panel.width)")
		  end
		end

	end
end

# ╔═╡ 099be731-dd16-4f56-af53-269e38ada04b
# Space between panels in an SVG drawing, and space between panels and SVG edge.
const SVG_PANEL_MARGIN = 2u"inch"

# ╔═╡ 495229d3-c8f8-4410-be90-3737655207ce
function toSVG(state::SearchState)
  buf = IOBuffer()
  toSVG(buf, state)
  return take!(buf)
end

# ╔═╡ bcbcf050-ee5f-4531-b432-7e2006fccc1e
function toSVG(io::IO, state::SearchState)::Nothing
	rpg = makeReversePanelGraph(state)
	write(io, """<?xml version="1.0" encoding="UTF-8"?>\n""")
	write(io, """<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"\n""")
	write(io, """          "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">\n""")
	# Outermost SVG:
	vpwidth = svgdistance(maximum(major.(keys(rpg))) + 2 * SVG_PANEL_MARGIN)
	vpheight = svgdistance(sum(minor.(filter(p -> p isa BoughtPanel, keys(rpg)))) + 
		2 * SVG_PANEL_MARGIN)
	svg(io; xmlns="http://www.w3.org/2000/svg",
		width="90%",
		viewBox="0 0 $(vpwidth) $(vpheight)",
		style="background-color: pink") do
		style(io; type="text/css") do
		  write(io, STYLESHEET)
		end
		g(io; class="everything") do
			y = SVG_PANEL_MARGIN
			for stock in filter((p) -> p isa BoughtPanel, keys(rpg))
				# We want to have the longer dimension of panel run
				# horizontally.  If so, we can apply a 90 degree rotation.
				# Here we just translate successive stock panels (BoughtPanel)
				# by its minor dimension and margins to space them out.
				# The toSVG method of BoughtPanel will deal with rotation.
				tx = svgdistance(SVG_PANEL_MARGIN)
				ty = svgdistance(y)
				g(io; transform="translate($(tx), $(ty))") do
					toSVG(io, stock, rpg)
					y += minor(stock) + SVG_PANEL_MARGIN
				end
			end
		end
	end
end

# ╔═╡ ffe9f05a-4348-4967-ba9d-5b0cc57dd70b
function toSVG(io::IO, panel::AbstractPanel, rpg::ReversePanelGraph)::Nothing
end

# ╔═╡ 738201a6-b769-4586-81cd-c8e73c9a6ad9
function toSVG(io::IO, panel::BoughtPanel, rpg::ReversePanelGraph)::Nothing
	# We want to have the longer dimension of panel run horizontally.
	# This is already anticipated above wnere we calculate the SVG viewBox.
	transform = ""
	if panel.length != major(panel)
		tx = svgdistance(0u"inch")
		ty = svgdistance(panel.width)
		transform = "rotate(90) translate($tx $ty)"
	end
	g(io; class="BoughtPanel",
		  transform=transform) do
		panelrect(io, panel, "factory-edge")
		for p in rpg[panel]
			toSVG(io, p, rpg)
		end
	end
end

# ╔═╡ deb5d973-3fb6-48c9-87da-ed50eb4cd33d
function toSVG(io::IO, panel::Panel, rpg::ReversePanelGraph)::Nothing
	g(io; class="Panel") do
		for p in rpg[panel]
			toSVG(io, p, rpg)
		end
		endX = panel.x + panel.length
		endY = panel.y + panel.width
		if panel.cut_axis isa LengthAxis
			startX = endX
			startY = panel.y
		else
			startX = panel.x
			startY = endY
		end
		startX, startY, endX, endY = svgdistance.((startX, startY, endX, endY))
		d = "M $startX $startY L $endX $endY"
		NativeSVG.path(io; class="cut", d=d)
	end
end

# ╔═╡ c90350c2-9c91-43df-b7ed-2ed77f960e6d
function toSVG(io::IO, panel::FinishedPanel, rpg::ReversePanelGraph)::Nothing
	g(io; class="FinishedPanel") do
		panelrect(io, panel, "finished")
	end
end

# ╔═╡ 4cd74059-f59b-46e4-be23-bfbd95e4d96d
md"""
# Generic Dot Code
"""

# ╔═╡ dcbc9193-fa7a-435b-8f68-05b77e1d9b36
md"""
# Panel Progression Graph

A GraphViz graph that describes what panels are cut from what other panels.
"""

# ╔═╡ bd178f5d-7701-4a09-ba6d-0b80712bc3e2
begin
	# This graph just shows panels by their types and uids and
	# the relationships between them,
	function dotgraph(io::IO, state::SearchState)::Nothing
		rpg = makeReversePanelGraph(state)
		dotgraph(io, rpg)
		return
	end

end

# ╔═╡ 6bafdc76-dd65-47a6-9c34-90353408c488
md"""
# Panel Cut Graph

The Panel Cut Graph is limited to describing starting and ending panels and the cuts that are made.  Irrelevant panels are elided.
"""

# ╔═╡ b879cd1d-938a-4839-9c00-20d989ff5d45
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

# ╔═╡ 7408dbb2-f396-4e8f-9686-d7ac1a522647
begin
  struct PanelCutGraph
    state::SearchState
    rpg::ReversePanelGraph

    function PanelCutGraph(state::SearchState)
      pcg = new(state, makeReversePanelGraph(state))
	  applyRule!(pcg.rpg, addCutNodes)
	  applyRule!(pcg.rpg, elideTerminalPanels)
	  applyRule!(pcg.rpg, elideBoughtPanels)
      pcg
    end
  end

  arcs(pcg::PanelCutGraph) = arcs(pcg.rpg)

  nodes(pcg::PanelCutGraph) = nodes(pcg.rpg)

  struct CutNode
    panel1::Panel
    panel2::Panel
  end

  function dotID(n::CutNode)
    return "CutNode_$(n.panel1.cut_from.uid)"
  end

  function dotnode(io::IO, pcg::PanelCutGraph, n::CutNode)
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
  function addCutNodes(rpg::ReversePanelGraph, key)
	transformingGraph() do check, add, remove
	  check(isa(key, CuttablePanel))
	  arcs = havingKey(rpg, key)
	  check(length(arcs) == 2)
	  arc1, arc2 = Tuple(arcs)
	  check(arc1.second isa Panel)
	  check(arc2.second isa Panel)
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
  function elideTerminalPanels(rpg::ReversePanelGraph, terminal)
    transformingGraph() do check, add, remove
      check(terminal isa TerminalPanel)
      arcs2 = havingValue(rpg, terminal)
      check(length(arcs2) == 1)
	  arc2 = first(arcs2)
      panel = arc2.first
      check(panel isa Panel)
      arcs1 = havingValue(rpg, panel)
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
  function elideBoughtPanels(rpg::ReversePanelGraph, bought)
	transformingGraph() do check, add, remove
	  check(bought isa BoughtPanel)
	  arcs1 = havingValue(rpg, bought)
	  check(length(arcs1) == 1)
	  arc1 = first(arcs1)
	  check(arc1.first isa AvailablePanel)
	  arcs2 = havingKey(rpg, bought)
	  check(length(arcs2) == 1)
	  arc2 = first(arcs2)
	  remove(arc1)
	  remove(arc2)
	  add(arc1.first => arc2.second)
	end
  end

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

  function dotnode(io::IO, graph::PanelCutGraph, panel::AbstractPanel)
    write(io, """  "$(dotID(panel))"[shape=record; label="$(dotnodelabel(graph, panel))"]\n""")
  end

end

# ╔═╡ f89c8f2e-8bdf-4d4e-8090-3f6a56e0ce85
begin
	
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

  function dotnode(io::IO, graph, node)
	write(io, """  "$(dotID(node))"\n""")
  end

  function diarc(io::IO, graph, arc::Pair)
    diarc(io, graph, arc.from, arc.to)
  end

  function diarc(io::IO, graph, from, to)
    write(io, """  "$(dotID(from))" -> "$(dotID(to))"\n""")
  end
	
  function dotID(panel::AbstractPanel)
	t = split(string(typeof(panel)), ".")[end]
 	"$(t)_$(string(panel.uid))"
  end

end

# ╔═╡ 75012d46-535c-4d51-9948-f3c611c7a72c
md"""
# Plots
"""

# ╔═╡ 9b16e856-dd32-400c-833a-cc2a3db5bf92
function plot_doneness_to_cost(searcher::Searcher)
  as = allstates(searcher)
  costs = (s -> s.accumulated_cost).(as)
  costs = (c -> ustrip(Real, u"USD", c)).(costs)
  done = doneness.(as)
  scatter(costs, done)
end

# ╔═╡ 1ea2113a-27f1-427a-a78e-23ef4bf52b33
md"""
# Report

Generate an HTML fragment that provides a detailed report of our cut search and results.
"""

# ╔═╡ 0d804f8e-838a-49a0-983e-d517d7588f56
cat = `"c:/Program Files/Git/usr/bin/cat.exe"`

# ╔═╡ 2883b685-b394-408f-b1ec-eb4804ead5f8
"""
    runCmd(cmd::Cmd, cmdOutput::IO)::IO
Run the external command `cmd`, which will write output to `cmdOutput`.
The stream that's returns can be written to to provide inoput to the
command.  The second return value is the stderr stream.
"""
function runCmd(cmd::Cmd, cmdOutput::IO)
	cmdInput = Pipe()
	err = Pipe()
	proc = Base.run(pipeline(cmd,
			stdin=cmdInput,
			stdout=cmdOutput,
			stderr=err),
		wait=false)
	process_running(proc) || throw(Exception("Problem starting $cmd"))
	close(cmdInput.out)
	close(err.in)
	return cmdInput, err
end

# ╔═╡ f8b1780e-9614-4414-93e1-205233d3fb16
function report(searcher::Searcher;
                includeCutDiagram=true,
                includeCutGraph=true)
    io = IOBuffer()
    function elt(f, io, tagname; attrs...)
        NativeSVG.element(f, tagname, io; attrs...)
    end
    elt(io, :div) do
        elt(io, :h2) do
            write(io, "Panel Cut Report")
        end
        elt(io, :p) do
            write(io, "Report of what stock to purchase and what" *
                " cuts to make to get panels of these aizes")
        end
        function th(io, heading)
            elt(io, :th) do
                write(io, heading)
            end
        end
        function td(io, val; attrs...)
            elt(io, :td; attrs...) do
		if val isa String
		    write(io, val)
		else
                    show(io, val)
		end
            end
        end
	# Table of wanted panels:
        elt(io, :table) do
            elt(io, :thread) do
                elt(io, :tr) do
                    for heading in ("Label", "Length", "Width", "Ok to Flip?")
                        th(io, heading)
                    end
                end
            end
            elt(io, :tbody) do
                for panel in searcher.wanted
                    elt(io, :tr) do
                        td(io, panel.label; align="center")
                        td(io, panel.length; align="right")
                        td(io, panel.width; align="right")
                        td(io, if panel isa FlippedPanel
                               "yes"
                           else
                               "no"
			   end;
			   align="center")
                    end
                end
            end
        end
        if searcher.cheapest == nothing
            elt(io, :p; style="font-weight: bold") do
                write(io, "No solution has been found!")
            end
            return
        else
            elt(io, :p) do
                write(io, "The best solution has a cost of " *
                    "$(searcher.cheapest.accumulated_cost).")
            end
        end
        # Table of panel areas
        elt(io, :div) do
            elt(io, :table) do
                elt(io, :thread) do
                    elt(io, :tr) do
                        th(io, "Panel")
                        th(io, "Area")
                        th(io, "%")
                    end
                end
                elt(io, :tbody) do
                    bought_area = sum(area.(searcher.cheapest.bought))
                    function panel_group(panels)
                        for p in panels
                            elt(io, :tr; style=style) do
                                td(io, p.label; align="center")
                                td(io, area(p); align="right")
                                td(io, @sprintf("%.2f%%",
						100 * convert(Float64, area(p)/bought_area));
				   align="right")
                                if p == panels[1]
				    frac = convert(Float64, sum(area.(panels)) / bought_area)
				    td(io, @sprintf("%.2f%%", 100 * frac);
				       rowspan=length(panels),
				       valign="top",
				       align="right")
                                end
                            end
                        end
                    end
                    panel_group(searcher.cheapest.bought)
                    panel_group(searcher.cheapest.scrapped)
                    panel_group(searcher.cheapest.finished)
                end
            end
        end
        if includeCutDiagram
            toSVG(io, searcher.cheapest)
        end
        if includeCutGraph
            elt(io, :div) do
                dot, err = runCmd(`dot -Tsvg`, io)
                dotgraph(dot, PanelCutGraph(searcher.cheapest))
                close(dot)
                err = read(err)
                if length(err) > 0
                    throw(Exception("Error running dot: $err"))
                end
            end
        end
    end
    return HTML(String(take!(io)))
end

# ╔═╡ 58cd80ab-5a98-4b34-9bc2-a414d766a486
md"""
# Examples / Testing
"""

# ╔═╡ e3f1b65c-1bb2-44ee-bbec-8bda4e1ae6c3
let
	p1, p2 = cut(BoughtPanel(BOULTER_PLYWOOD.available_stock[1]),
		LengthAxis(), 10u"inch";
		kerf=BOULTER_PLYWOOD.kerf,
		cost=BOULTER_PLYWOOD.cost_per_cut)
	fp = FinishedPanel(p1, WantedPanel(length=10u"inch", width=p1.width, label="foo"))
	sp = ScrappedPanel(was=p2)
	rpg = ReversePanelGraph()
	injest(rpg, fp)
	injest(rpg, sp)
	nodes(rpg) .|> (key -> (elideTerminalPanels(rpg, key)))
end

# ╔═╡ c5f24393-4c92-4dcf-8a14-8f81c03cc2f0
md"""
## Two Panels From One Sheet of Stock
"""

# ╔═╡ 4a9ebc9b-b91c-4ff6-ba55-2c32093044be
let
  searcher = Searcher(BOULTER_PLYWOOD, wanda_box_panels[1:2])
  search(searcher)
  report(searcher)
end

# ╔═╡ 40eda0d7-3871-48d6-9976-e9dd7829265d
md"""
## Panels for a Complete Five Sided Box
"""

# ╔═╡ aeaa6940-4f97-4286-97d4-7ad6dc6013b1
let
	searcher = Searcher(BOULTER_PLYWOOD, wanda_box_panels)
	search(searcher)
	@assert length(searcher.cheapest.finished) == length(wanda_box_panels)
	report(searcher)
end

# ╔═╡ a968cf5a-bed4-4939-980f-86e90903b756
md"""
## A Complete Box Allowing Flipping
"""

# ╔═╡ 81b8240b-e3c0-427d-b57a-b07e52963f15
let
	searcher = Searcher(BOULTER_PLYWOOD, flipped.(wanda_box_panels))
	search(searcher)
	report(searcher)
end

# ╔═╡ 1d99d3f7-f1a7-46f4-92d5-10a5b2677276
md"""
## An Example that Requires Flipped and Unflipped Panels for Optimality
"""

# ╔═╡ f1cf4d1c-2844-4bb5-b230-2e948af91852
let
	biggest = sort(BOULTER_PLYWOOD.available_stock, by=area, rev=true)[1]
	supplier = Supplier(name = "test",
		cost_per_cut = BOULTER_PLYWOOD.cost_per_cut,
		kerf = BOULTER_PLYWOOD.kerf,
		available_stock = [biggest])
	wanted = [
		WantedPanel(
			length = 1.1 * biggest.width,
			width = (biggest.length - 15u"inch") / 2,
			label = "panel 1"),
		WantedPanel(
			length = 1.1 * biggest.width,
			width = (biggest.length - 15u"inch") / 2,
			label = "panel 2"),
		WantedPanel(
			length = 14u"inch",
			width = 20u"inch",
			label = "panel 3"),
		WantedPanel(
			length = 14u"inch",
			width = 20u"inch",
			label = "panel 4")
		]
	searcher = Searcher(BOULTER_PLYWOOD, flipped.(wanted))
	search(searcher)
	report(searcher)
end

# ╔═╡ 2d6b3e56-0858-4b7a-9bd7-5d5fa2b835c9
md"""
# allsubtypes
"""

# ╔═╡ 97d24eee-024e-4079-948a-49245fd3c734
function allsubtypes(t, result=Set())
	push!(result, t)
	for t1 in subtypes(t)
		allsubtypes(t1, result)
	end
	return result
end

# ╔═╡ 52956b53-22a2-47c2-bb8d-d70ea63dcff6
allsubtypes(AbstractPanel)

# ╔═╡ 70685b9d-b660-4443-ae7f-a0659456dc4f
md"""
  # Experiments
  """

# ╔═╡ bb38f4c1-4443-4b33-a526-b5cc653f437b
+(area.(Set(wanda_box_panels))...)

# ╔═╡ 2b814578-5137-4805-bedf-2c7759d87048
typeof(20u"USD")

# ╔═╡ 7e368048-6a64-4439-8114-493f7f45ddfd
20u"USD" isa Quantity{N, CURRENCY} where N

# ╔═╡ 4049d967-f932-4eec-b6fc-711a5df79531
zero(Quantity{Real, CURRENCY})

# ╔═╡ Cell order:
# ╠═b019d660-9f77-11eb-1527-278a3e1b087c
# ╠═5f5c5ef3-efed-4afd-b304-5b37a9a81bd2
# ╟─60eb1ca9-cf1f-46d6-b9b9-ee9fb41723d1
# ╠═60fdb133-5d21-4445-90f9-3bbe49fb743b
# ╠═ecacafd3-5f70-41d9-b6cd-6b4893186b2a
# ╟─f6a43438-d7b0-442d-bb05-9e4488855665
# ╠═65adef2d-9a53-4310-81a0-5dbb6d0918ca
# ╟─df84b1ad-cbd5-4f7b-a37e-30534b17adcf
# ╠═148e3f7f-4ac6-4e57-be5d-fb4082bf1154
# ╟─85f95152-93a2-42cd-80f3-c3d7d931dbfe
# ╠═2e1e9fc8-6209-4968-bf7e-fa97b72ebef3
# ╟─134ac318-adb5-4939-96f7-3b70b12ffe43
# ╠═d5b1c891-9529-4876-839f-cddd94d3d800
# ╠═9d0fb461-46e4-4436-a367-5cdf3406474f
# ╠═c2a34850-17eb-43ca-b6c1-262dc67d6006
# ╠═099be731-dd16-4f56-af53-269e38ada04b
# ╠═495229d3-c8f8-4410-be90-3737655207ce
# ╠═bcbcf050-ee5f-4531-b432-7e2006fccc1e
# ╠═ffe9f05a-4348-4967-ba9d-5b0cc57dd70b
# ╠═738201a6-b769-4586-81cd-c8e73c9a6ad9
# ╠═deb5d973-3fb6-48c9-87da-ed50eb4cd33d
# ╠═c90350c2-9c91-43df-b7ed-2ed77f960e6d
# ╟─4cd74059-f59b-46e4-be23-bfbd95e4d96d
# ╠═f89c8f2e-8bdf-4d4e-8090-3f6a56e0ce85
# ╟─dcbc9193-fa7a-435b-8f68-05b77e1d9b36
# ╠═bd178f5d-7701-4a09-ba6d-0b80712bc3e2
# ╟─6bafdc76-dd65-47a6-9c34-90353408c488
# ╠═b879cd1d-938a-4839-9c00-20d989ff5d45
# ╠═7408dbb2-f396-4e8f-9686-d7ac1a522647
# ╟─75012d46-535c-4d51-9948-f3c611c7a72c
# ╠═9b16e856-dd32-400c-833a-cc2a3db5bf92
# ╟─1ea2113a-27f1-427a-a78e-23ef4bf52b33
# ╠═f8b1780e-9614-4414-93e1-205233d3fb16
# ╠═0d804f8e-838a-49a0-983e-d517d7588f56
# ╠═2883b685-b394-408f-b1ec-eb4804ead5f8
# ╟─58cd80ab-5a98-4b34-9bc2-a414d766a486
# ╠═e3f1b65c-1bb2-44ee-bbec-8bda4e1ae6c3
# ╟─c5f24393-4c92-4dcf-8a14-8f81c03cc2f0
# ╠═4a9ebc9b-b91c-4ff6-ba55-2c32093044be
# ╟─40eda0d7-3871-48d6-9976-e9dd7829265d
# ╠═aeaa6940-4f97-4286-97d4-7ad6dc6013b1
# ╟─a968cf5a-bed4-4939-980f-86e90903b756
# ╠═81b8240b-e3c0-427d-b57a-b07e52963f15
# ╟─1d99d3f7-f1a7-46f4-92d5-10a5b2677276
# ╠═f1cf4d1c-2844-4bb5-b230-2e948af91852
# ╟─2d6b3e56-0858-4b7a-9bd7-5d5fa2b835c9
# ╠═97d24eee-024e-4079-948a-49245fd3c734
# ╠═52956b53-22a2-47c2-bb8d-d70ea63dcff6
# ╟─70685b9d-b660-4443-ae7f-a0659456dc4f
# ╠═bb38f4c1-4443-4b33-a526-b5cc653f437b
# ╠═2b814578-5137-4805-bedf-2c7759d87048
# ╠═7e368048-6a64-4439-8114-493f7f45ddfd
# ╠═4049d967-f932-4eec-b6fc-711a5df79531
