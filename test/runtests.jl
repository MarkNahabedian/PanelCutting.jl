
using InteractiveUtils
using PanelCutting
using Unitful
using UnitfulUS
# using UnitfulCurrency
using Test

include("test_graph_rewrite.jl")


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

example_makers = Dict{Type, Function}()

"""
Make a new example of the spoecified type.
"""
function example(t::Type{<:AbstractPanel})
    example_makers[t]()
end

example_makers[WantedPanel] =
    () -> WantedPanel(;
                      label = "example WantedPanel",
                      width = 6u"inch",
                      length = 10u"inch")
example_makers[FlippedPanel] =
    () -> FlippedPanel(example(WantedPanel))
example_makers[AvailablePanel] =
    () -> AvailablePanel(;
                         length = 4u"ft",
                         width = 2u"ft",
                         label = "example AvailablePanel",
                         cost = money(10.00))
example_makers[BoughtPanel] =
    () -> BoughtPanel(example(AvailablePanel))
example_makers[Panel] =
    () -> let
        from = example(BoughtPanel)
        axis = LengthAxis()
        at = distance(from, axis) / 3
        Panel(;
              length = at,
              width = distance(from, other(axis)),
              cut_from = from,
              cut_at = at,
              cut_axis = axis,
              x = from.x,
              y = from.y,
              cost = from.cost)
    end
example_makers[ScrappedPanel] =
    () -> ScrappedPanel(; was=example(Panel))
example_makers[FinishedPanel] =
    () -> let
        have = example(Panel)
        FinishedPanel(have, WantedPanel(label = "want",
                                        width = have.width,
                                        length = have.length))
    end

@testset "PanelIdentity" begin
    for paneltype in filter(isconcretetype, allsubtypes(AbstractPanel))
        @test example(paneltype) != example(paneltype)
    end
end

@testset "PanelIntegrity" begin
    # Make sure we can't associate the wrong kinds or sizes of panels
    # with one another
end

@testset "trivial cut" begin
    panel1 = BoughtPanel(AvailablePanel("30 by 60", 30u"inch", 60u"inch", 20))
    panels = cut(panel1, LengthAxis(), panel1.length)
    @test length(panels) == 1
    panel2 = panels[1]
    @test panel2 isa Panel
    @test panel2.length == panel1.length
    @test panel2.width == panel1.width
    @test panel2.cost == panel1.cost
    @test panel2.x == panel1.x
    @test panel2.y == panel1.y
end

@testset "close shave" begin
    kerf= (1/8)u"inch"
    cut_cost = 1
    panel1 = BoughtPanel(AvailablePanel("30 by 60", 30u"inch", 60u"inch", 20))
    panels = cut(panel1, LengthAxis(),
                 panel1.length - kerf;
                 kerf=kerf, cost=cut_cost)
    @test length(panels) == 1
    panel2 = panels[1]
    @test panel2.cost == panel1.cost + cut_cost
end

@testset "Cut" begin
    kerf= (1/8)u"inch"
    cut_cost = 1
    panel1 = BoughtPanel(AvailablePanel("30 by 60", 30u"inch", 60u"inch", 20))
    panel2, panel3 = cut(panel1, LengthAxis(), 25u"inch";
                         kerf=kerf, cost=cut_cost)
    total_cost = panel1.cost + cut_cost
    @test panel2.length == 25u"inch"
    @test panel2.width == 30u"inch"
    @test panel3.length == panel1.length - panel2.length - kerf
    @test panel3.width == 30u"inch"
    @test panel2.x == panel1.x
    @test panel2.y == panel1.y
    @test panel3.x == panel1.x + panel2.length + kerf
    @test panel3.y == panel1.y
    @test panel2.cost == total_cost / 2
    @test panel3.cost == total_cost / 2
end

@testset "Buy more" begin
    # Make sure we buy another AvailablePanel when none of our scraps
    # are big enough.
    supplier = Supplier(
        name="test",
        cost_per_cut=1.50,
        kerf=(1/8)u"inch",
        available_stock=[example(AvailablePanel)])
    wanted = 3 * WantedPanel(label="panel",
                             length=1.5u"ft",
                             width=20u"inch")
    searcher = Searcher(supplier, wanted)
    search(searcher)
    @test length(wanted) == length(searcher.cheapest.finished)
    bought = Set(map(progenitor, searcher.cheapest.finished))
    @test length(bought) == 2
end

@testset "suboptimal - too many buys" begin
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
	    width=box_width),
        (2 * WantedPanel(
	    label="side",
	    length=box_length,
	    width=box_height - stock_thickness + rabbet_depth))...,
        ((compartment_count + 1) *
	    WantedPanel(label="divider",
		        width=(box_height - stock_thickness + rabbet_depth),
		        length=(box_width - 2 * stock_thickness + 2 * rabbet_depth))...)
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
		cost=4)
	])
    searcher = Searcher(supplier, wanted_panels)
    search(searcher)
    bought = Set(map(progenitor, searcher.cheapest.finished))
    # @test length(bought) == 2
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


@testset "Graph" begin
    g = PanelGraph()
    injest(g, :a => :b)
    injest(g, :b => :c)
    injest(g, :a => 1)
    injest(g, 1 => 1.1)
    injest(g, 1 => 1.2)
    @test query(g, :a, Symbol) == Set([:a => :b])
    @test query(g, Symbol, :c) == Set([:b => :c])
    @test length(query(g, Any, Number)) == 3
    @test length(query(g, :b, :c)) == 1
end

include("test_readme_examples.jl")
