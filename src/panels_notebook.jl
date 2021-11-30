### A Pluto.jl notebook ###
# v0.16.4

using Markdown
using InteractiveUtils

# ╔═╡ b019d660-9f77-11eb-1527-278a3e1b087c
begin
	using Pkg

	Pkg.add("HTTP")
	using HTTP
	
	Pkg.add(; path="https://github.com/MarkNahabedian/NahaJuliaLib.jl")
	using NahaJuliaLib

	workspace = mktempdir()
	from_workspace = "https://raw.githubusercontent.com/MarkNahabedian/PanelCutting.jl/master/workspace_for_binder"

	for f in ["Project.toml", "Manifest.toml"]
		from = uri_add_path(from_workspace, f)
		to = joinpath(workspace, f)
		response = HTTP.request("GET", from)
		@assert response.status == 200
		open(to, "w") do f
			write(f, String(response.body))
		end
	end
	Pkg.activate(workspace)
	workspace
end

# ╔═╡ ab2e6b79-24f3-4736-8e9e-8362a7efd718
begin
	using Revise
	using Unitful
	using UnitfulUS
	using Match
	using DataStructures
	# using UnitfulCurrency
	using NativeSVG
	using DisplayAs
	using UUIDs
	using Plots
	using Printf
	using Logging
	using VectorLogging
	using PanelCutting
end

# ╔═╡ 202a21c7-e92a-4636-9859-c27626a96edc
WantedPanel

# ╔═╡ 60eb1ca9-cf1f-46d6-b9b9-ee9fb41723d1
md"""
  # Setup

  Prefer inches.
  """

# ╔═╡ e25b3bb7-93b3-4859-be30-ef912041479f
Logging.global_logger(VectorLogger())

# ╔═╡ 60fdb133-5d21-4445-90f9-3bbe49fb743b
begin
  Unitful.preferunits(u"inch")
end

# ╔═╡ 0f1516c2-e12d-439c-b57d-3af903cbf3f6
WantedPanel

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
		cost_per_cut = money(1.50),
		available_stock = [
    AvailablePanel("4 x 8 x 1/2", 4u"ft", 8u"ft", money(95.00)),
    AvailablePanel("5 x 5 x 1/2", 5u"ft", 5u"ft", money(49.00)),
    AvailablePanel("30 x 60 x 1/2", 30u"inch", 60u"inch", money(30.00)),
    AvailablePanel("30 x 30 x 1/2", 30u"inch", 30u"inch", money(19.00))
  ])
end

# ╔═╡ 85f95152-93a2-42cd-80f3-c3d7d931dbfe
md"""
# Describing the Cuts using SVG
"""

# ╔═╡ 134ac318-adb5-4939-96f7-3b70b12ffe43
#=
macro thismodule()
	:($__module__)
end
=#

# ╔═╡ 4cd74059-f59b-46e4-be23-bfbd95e4d96d
md"""
# Generic Dot Code
"""

# ╔═╡ f89c8f2e-8bdf-4d4e-8090-3f6a56e0ce85
  function PanelCutting.dotID(panel::AbstractPanel)
	t = split(string(typeof(panel)), ".")[end]
 	"$(t)_$(string(panel.uid))"
  end

# ╔═╡ dcbc9193-fa7a-435b-8f68-05b77e1d9b36
md"""
# Panel Progression Graph

A GraphViz graph that describes what panels are cut from what other panels.
"""

# ╔═╡ bd178f5d-7701-4a09-ba6d-0b80712bc3e2
begin
	# This graph just shows panels by their types and uids and
	# the relationships between them,
	function PanelCutting.dotgraph(io::IO, state::SearchState)::Nothing
		rpg = makePanelGraph(state)
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

end

# ╔═╡ 75012d46-535c-4d51-9948-f3c611c7a72c
md"""
# Plots
"""

# ╔═╡ 9b16e856-dd32-400c-833a-cc2a3db5bf92
function plot_doneness_to_cost(searcher::Searcher)
  as = allstates(searcher)
  costs = (s -> s.accumulated_cost).(as)
  costs = (c -> unmoney(c)).(costs)
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
				# Run the GraphViz dot command, inlining the SVG output
				# into the report:
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
	rpg = PanelGraph()
	injest(rpg, fp)
	injest(rpg, sp)
	PanelCutting.nodes(rpg) .|> (key -> (elideTerminalPanels(rpg, key)))
end

# ╔═╡ c5f24393-4c92-4dcf-8a14-8f81c03cc2f0
md"""
## Two Panels From One Sheet of Stock
"""

# ╔═╡ 4a9ebc9b-b91c-4ff6-ba55-2c32093044be
let
  searcher = Searcher(BOULTER_PLYWOOD, wanda_box_panels[1:2])
  search(searcher)
  # ***** debug graph transformations:
  g = makePanelGraph(searcher.cheapest)
  base_path = "c:/Users/Mark Nahabedian/.julia/dev/PanelCutting/src/"
  message = "Wrote graph file"
  @info message, path=dotgraph(base_path*"two-panels-0.svg", g)
  applyRule!(g, addCutNodes)
  @info message, path=dotgraph(base_path*"two-panels-1.svg", g)
  applyRule!(g, elideBoughtPanels)
  @info message, path=dotgraph(base_path*"two-panels-2.svg", g)
  applyRule!(g, elideTerminalPanels)
  @info message, path=dotgraph(base_path*"two-panels-3.svg", g)
  # Back to our regularly scheduloed report
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

# ╔═╡ 70685b9d-b660-4443-ae7f-a0659456dc4f
md"""
  # Experiments
  """

# ╔═╡ bb38f4c1-4443-4b33-a526-b5cc653f437b
+(area.(Set(wanda_box_panels))...)

# ╔═╡ 2b814578-5137-4805-bedf-2c7759d87048
# typeof(20u"USD")

# ╔═╡ 7e368048-6a64-4439-8114-493f7f45ddfd
# 20u"USD" isa Quantity{N, CURRENCY} where N

# ╔═╡ 4049d967-f932-4eec-b6fc-711a5df79531
# zero(Quantity{Real, CURRENCY})

# ╔═╡ 758a62c8-512c-45a0-be1c-a3ec903e57b4
Logging.global_logger()

# ╔═╡ Cell order:
# ╠═b019d660-9f77-11eb-1527-278a3e1b087c
# ╠═ab2e6b79-24f3-4736-8e9e-8362a7efd718
# ╠═202a21c7-e92a-4636-9859-c27626a96edc
# ╟─60eb1ca9-cf1f-46d6-b9b9-ee9fb41723d1
# ╠═e25b3bb7-93b3-4859-be30-ef912041479f
# ╠═60fdb133-5d21-4445-90f9-3bbe49fb743b
# ╠═0f1516c2-e12d-439c-b57d-3af903cbf3f6
# ╠═ecacafd3-5f70-41d9-b6cd-6b4893186b2a
# ╟─f6a43438-d7b0-442d-bb05-9e4488855665
# ╠═65adef2d-9a53-4310-81a0-5dbb6d0918ca
# ╟─85f95152-93a2-42cd-80f3-c3d7d931dbfe
# ╟─134ac318-adb5-4939-96f7-3b70b12ffe43
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
# ╟─70685b9d-b660-4443-ae7f-a0659456dc4f
# ╠═bb38f4c1-4443-4b33-a526-b5cc653f437b
# ╠═2b814578-5137-4805-bedf-2c7759d87048
# ╠═7e368048-6a64-4439-8114-493f7f45ddfd
# ╠═4049d967-f932-4eec-b6fc-711a5df79531
# ╠═758a62c8-512c-45a0-be1c-a3ec903e57b4
