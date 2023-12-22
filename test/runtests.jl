
using InteractiveUtils
using PanelCutting
using Unitful
using UnitfulUS
# using UnitfulCurrency
using Test
using Logging


@testset "AllOf" begin
    ao = AllOf([1, 2, 3], (:a, :b))
    @test length(ao) == 5
    @test ao[2] == 2
    @test ao[5] == :b
    @test collect(ao) == [1, 2, 3, :a, :b]
end

function allsubtypes(t, result=Set())
    push!(result, t)
    for t1 in subtypes(t)
	allsubtypes(t1, result)
    end
    return result
end

include("example_makers.jl")

include("test_overlap.jl")

@testset "Axes" begin
    @test LengthAxis() isa Axis
    @test WidthAxis() isa Axis
    @test other(WidthAxis()) == LengthAxis()
    @test other(LengthAxis()) == WidthAxis()

    @test area([2 3]) == 6
end

@testset "cut math" begin
    at = 8u"inch"
    plw = [2u"ft" 1u"ft"]
    pxy = [1u"inch" 2u"inch"]
    vmult(a, b) = map(*, a, b)
    lw(axis) = (at * unit_vector(axis) +
        vmult(plw, unit_vector(other(axis))))
    @test lw(LengthAxis()) == [at plw[2]]
    @test lw(WidthAxis()) == [plw[1] at]
end

@testset "PanelIdentity" begin
    for paneltype in filter(isconcretetype, allsubtypes(AbstractPanel))
        @test example(paneltype) != example(paneltype)
    end
end

@testset "BoughtPanel uniqueness" begin
    # Though two BoughtPanels might be derived from the same
    # AvailablePanel, we need to be able to distinguish between them
    # because making a cut in one of them does not alter tje other.
    ap = AvailablePanel(; label = "4 x 8 x 1/2",
                        width = 4u"ft",
                        length = 8u"ft",
                        thickness = 0.5u"inch",
                        cost = money(95.00))
    @test BoughtPanel(ap) != BoughtPanel(ap)
end

@testset "PanelIntegrity" begin
    # Make sure we can't associate the wrong kinds or sizes of panels
    # with one another
end

@testset "cut: stock too short" begin
    axis = LengthAxis()
    panel1 = BoughtPanel(AvailablePanel("30 by 60", 30u"inch", 60u"inch", 0.5u"inch", 20))
    panels = cut(panel1, axis, panel1.length * 1.1)
    @test isempty(panels)
end

@testset "Cutting" begin
    let
        KERF = (1/8)u"inch"
        panel1 = BoughtPanel(AvailablePanel("30 by 60", 30u"inch", 60u"inch", 0.5u"inch", money(20.00)))

        # Cut panel1 at 25" down LengthAxis:
        panel2, panel3 = cut(panel1, LengthAxis(), 25u"inch"; kerf=KERF)
        @test panel2.length == 25u"inch"
        @test panel2.width == 30u"inch"
        @test panel3.length == panel1.length - panel2.length - KERF
        @test panel3.width == 30u"inch"
        @test panel2.x == panel1.x
        @test panel2.y == panel1.y
        @test panel3.x == panel1.x + panel2.length + KERF
        @test panel3.y == panel1.y
        
        # Cut panel2 at 10" down WidthAxis:
        panel4, panel5 = cut(panel2, WidthAxis(), 10u"inch", kerf=KERF)
        @test panel4.width == 10u"inch"
        @test panel4.length == panel2.length
        @test panel4.x == panel2.x
        @test panel4.y == panel2.y
        @test panel5.x == panel2.x
        @test panel5.y == panel4.y + panel4.width + KERF
        @test panel5.length == panel2.length
        @test panel5.width == panel2.width - panel4.width - KERF
    end
    let
        KERF = (1/8)u"inch"
        panel1 = BoughtPanel(AvailablePanel("4 x 8 x 1/2", 4u"ft", 8u"ft", 0.5u"inch", money(95.00)))
        at = 22u"inch"
        cut1, cut2 = cut(panel1, LengthAxis(), at, kerf=KERF)
        @test cut1.length == at
        @test cut1.width == panel1.width
        @test cut2.width == panel1.width
        @test cut2.length ≈ panel1.length - at - KERF
    end
end

# A bunch of common test assertions relating a Panel to the
# CuttablePanel it was cut from.
function panel_test(panel::Panel, kerf)
    parent = panel.cut_from
    if panel.x == parent.x && panel.y == parent.y
        # The first panel returned by cut, the intended panel
        if panel.cut_axis isa LengthAxis
            @test panel.length == panel.cut_at
            @test panel.width == parent.width
        else
            @test panel.width == panel.cut_at
            @test panel.length == parent.length
        end
    else
        # the off-cut
        offset = panel.cut_at + kerf
        if panel.cut_axis isa LengthAxis
            @test panel.length == parent.length - offset
            @test panel.width == parent.width
            @test panel.x == parent.x + offset
            @test panel.y == parent.y
        else
            @test panel.width == parent.width - offset
            @test panel.length == parent.length
            @test panel.x == parent.x
            @test panel.y == parent.y + offset
        end
    end
end

@testset "trivial cut" begin
    axis = LengthAxis()
    kerf = (1/8)u"inch"
    cut_cost = money(1)
    panel1 = BoughtPanel(AvailablePanel("30 by 60", 30u"inch", 60u"inch", 0.5u"inch", 20))
    panels = cut(panel1, axis, panel1.length; kerf=kerf, cost=cut_cost)
    @test length(panels) == 1
    panel2 = panels[1]
    @test panel2 isa Panel
    @test panel2.cut_from == panel1
    @test panel2.cut_at == panel1.length
    @test panel2.cut_axis == axis
    @test panel2.cost == panel1.cost
    @test panel2.x == panel1.x
    @test panel2.y == panel1.y
    panel_test(panel2, kerf)
end

@testset "close shave" begin
    kerf= (1/8)u"inch"
    cut_cost = 1
    panel1 = BoughtPanel(AvailablePanel("30 by 60", 30u"inch", 60u"inch", 0.5u"inch", 20))
    panels = cut(panel1, LengthAxis(),
                 panel1.length - kerf;
                 kerf=kerf, cost=cut_cost)
    @test length(panels) == 1
    panel2 = panels[1]
    @test panel2.cut_from == panel1
    @test panel2 isa Panel
    @test panel2.cost == panel1.cost + cut_cost
    panel_test(panel2, kerf)
end

@testset "Cut" begin
    kerf= (1/8)u"inch"
    cut_cost = 1
    panel1 = BoughtPanel(AvailablePanel("30 by 60", 30u"inch", 60u"inch", 0.5u"inch", 20))
    panel2, panel3 = cut(panel1, LengthAxis(), 25u"inch";
                         kerf=kerf, cost=cut_cost)
    total_cost = panel1.cost + cut_cost
    @test panel2.length == 25u"inch"
    @test panel2.width == 30u"inch"
    @test panel2.cut_from == panel1
    @test panel3.cut_from == panel1
    @test panel2.cut_at == panel3.cut_at
    @test panel2.cut_axis == panel3.cut_axis
    panel_test(panel2, kerf)
    panel_test(panel3, kerf)
    total_area = area(panel2) + area(panel3)
    @test panel1.length == panel2.length + kerf + panel3.length
    @test panel2.cost == total_cost * area(panel2) / total_area
    @test panel3.cost == total_cost * area(panel3) / total_area
end

# Each element of searcher.cheapest.bought should be the progenitor of
# at leat one searcher.cheapest.finished panel.
function unuesd_bought_panels(state::SearchState)
    finished_bought = Set(map(progenitor, state.finished))
    symdiff(Set(state.bought), finished_bought)
end

function make_test_graphs(state::SearchState, basename::String)
    pg = PanelGraph(state)
    function make_graph(g, fname)
        dotgraph(fname, g, PanelsDotStyle())
        rundot(fname)
        @info(fname)
    end
    make_graph(pg, joinpath(@__DIR__, "$basename.dot"))
    #=
    Since we switched from NahaGraphs to MetaGraphsNext, the graph
    transformation code from NahaGraphs isn't evailable.  not a big
    deal since the PanelCutGraph was not being constructed as
    intended.  A problem for another day.
    make_graph(PanelCutGraph(state, pg),
               joinpath(@__DIR__, "$basename-pcg.dot"))
    =#
end

@testset "Search: fits in one" begin
    supplier = Supplier(
        name="test",
        cost_per_cut=1.50,
        kerf=(1/8)u"inch",
        # 4ft long, 2ft wide:
        available_stock=[example(AvailablePanel)])
    wanted = 3 * WantedPanel(label="panel",
                             length=1u"ft",
                             width=20u"inch",
                             material="plywood",
                             thickness=0.5u"inch")
    searcher = Searcher(supplier, wanted)
    search(searcher)
    @test length(wanted) == length(searcher.cheapest.finished)
    bought = Set(map(progenitor, searcher.cheapest.finished))
    make_test_graphs(searcher.cheapest, "fits-in-one")
    @info("bought = $bought")
    @test length(bought) == 1
    @test isempty(unuesd_bought_panels(searcher.cheapest))
end

@testset "Search: buy more" begin
    # Make sure we buy another AvailablePanel when none of our scraps
    # are big enough.
    supplier = Supplier(
        name="test",
        cost_per_cut=1.50,
        kerf=(1/8)u"inch",
        available_stock=[example(AvailablePanel)])
    wanted = 3 * WantedPanel(label="panel",
                             length=1.5u"ft",
                             width=20u"inch",
                             material="plywood",
                             thickness = 0.5u"inch")
    searcher = Searcher(supplier, wanted)
    search(searcher)
    @test length(wanted) == length(searcher.cheapest.finished)
    bought = Set(map(progenitor, searcher.cheapest.finished))
    @test length(bought) == 2
    @test isempty(unuesd_bought_panels(searcher.cheapest))
end


# Each element of searcher.cheapest.bought should be the progenitor of
# at leat one searcher.cheapest.finished panel.
function unused_bought_panels(state::SearchState)
    symdiff(Set(state.bought),
            Set(map(progenitor, state.finished)))
end

@testset "Search: too many buys" begin
    box_length = 12.5u"inch"
    box_width = 2u"inch"
    box_height = 1.875u"inch"
    stock_thickness = 0.125u"inch"
    rabbet_depth = 0.0625u"inch"
    compartment_count = 4
    wanted_panels = [
        WantedPanel(
	    label="bottom",
	    length=box_length,
	    width=box_width,
            material="plywood",
            thickness = stock_thickness),
        (2 * WantedPanel(
	    label="side",
	    length=box_length,
	    width=box_height - stock_thickness + rabbet_depth,
            material="plywood",
            thickness = stock_thickness))...,
        ((compartment_count + 1) *
	    WantedPanel(label="divider",
		        width=(box_height - stock_thickness + rabbet_depth),
		        length=(box_width - 2 * stock_thickness + 2 * rabbet_depth),
                        material="plywood",
                        thickness = stock_thickness)...)
    ]
    supplier = Supplier(
	name = "www.midwestproducts.com",
	kerf = 0.036u"inch",    # the measured set of my Japanese pull saw
	cost_per_cut=0.10,
	available_stock = [
	    AvailablePanel(
		label="basswood 24 × 4 × 1/8",
		length=24u"inch",
		width=4u"inch",
                thickness = stock_thickness,
                material="plywood",
		cost=4)
	])
    searcher = Searcher(supplier, wanted_panels)
    search(searcher)
    @test searcher.cheapest isa SearchState
    @test isempty(unused_bought_panels(searcher.cheapest))
    make_test_graphs(searcher.cheapest, "too-many-buys")
    bought = Set(map(progenitor, searcher.cheapest.finished))
    @test length(bought) == 2
end

@testset "FlippedPanel" begin
    w = WantedPanel(width=1u"inch", length=2u"inch", label="foo", thickness= 0.5u"inch")
    f = flipped(w)
    @test w.length == f.width
    @test w.width == f.length
    @test setdiff(Set(propertynames(f)), Set(propertynames(w))) == Set((:was,))
    @test wantsmatch(w, w)
    @test wantsmatch(f, f)
    @test wantsmatch(w, f)
    @test wantsmatch(f, w)
    @test flipped(WantedPanel(width=10u"inch",
			      length=10u"inch",
                              thickness= 0.5u"inch",
			      label="square")
                  ) isa WantedPanel
end

@testset "OrFlipped" begin
    wanted = example(WantedPanel)
    both = orFlipped(wanted)
    @test both[2].was === wanted
    @test both[1].width == both[2].length
    @test both[1].length == both[2].width
    @test both[2].label == "flipped $(wanted.label)"
end

@testset "multiply WantedPanel" begin
    wanted = 2 * example(WantedPanel)
    @test length(wanted) == 2
    @test wanted[1].length == wanted[2].length
    @test wanted[1].width == wanted[2].width
    labels = map(wanted) do p; p.label; end
    index = 1
    while labels[1][index] == labels[2][index]
        index += 1
    end
    @test map(labels) do l; parse(Int, l[index:end]); end == 1:2
end

@testset "multiply orFlipped" begin
    wanted = reduce(vcat,
                    map(orFlipped,
                        2 * example(WantedPanel)))
    @test length(wanted) == 4
end


using PanelCutting: add_edge!, query

@testset "Graph" begin
    g = PanelCutting.PanelGraph{Union{Symbol, Number}}()
    add_edge!(g, :a => :b)
    add_edge!(g, :b => :c)
    add_edge!(g, :a => 1)
    add_edge!(g, 1 => 1.1)
    add_edge!(g, 1 => 1.2)
    @test query(g, :a, Symbol) == Set([:a => :b])
    @test query(g, Symbol, :c) == Set([:b => :c])
    @test length(query(g, Any, Number)) == 3
    @test length(query(g, :b, :c)) == 1
end

include("test_callerFile.jl")

# dot isn't available in the GitHub actions environment.
# include("test_readme_examples.jl")

include("test_box.jl")

