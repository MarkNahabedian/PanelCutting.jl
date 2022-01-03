
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

@testset "PanelCutting.jl" begin
    # Write your tests here.
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
