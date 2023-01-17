
@testset "Box Face opposite" begin
    @test opposite(Top()) == Bottom()
    @test opposite(Bottom()) == Top()
    @test opposite(Left()) == Right()
    @test opposite(Right()) == Left()
    @test opposite(Front()) == Back()
    @test opposite(Back()) == Front()
end

@testset "Box Face neighbors" begin
    @test neighbors(Top(), Left())
    @test neighbors(Top(), Right())
    @test neighbors(Top(), Front())
    @test neighbors(Top(), Back())
    @test !neighbors(Top(), Top())
    @test !neighbors(Top(), Bottom())

    @test neighbors(Bottom(), Left())
    @test neighbors(Bottom(), Right())
    @test neighbors(Bottom(), Front())
    @test neighbors(Bottom(), Back())
    @test !neighbors(Bottom(), Bottom())
    @test !neighbors(Bottom(), Top())

    @test neighbors(Left(), Top())
    @test neighbors(Left(), Bottom())
    @test neighbors(Left(), Front())
    @test neighbors(Left(), Back())
    @test !neighbors(Left(), Left())
    @test !neighbors(Left(), Right())

    @test neighbors(Right(), Top())
    @test neighbors(Right(), Bottom())
    @test neighbors(Right(), Front())
    @test neighbors(Right(), Back())
    @test !neighbors(Right(), Right())
    @test !neighbors(Right(), Left())

    @test neighbors(Front(), Top())
    @test neighbors(Front(), Bottom())
    @test neighbors(Front(), Left())
    @test neighbors(Front(), Right())
    @test !neighbors(Front(), Front())
    @test !neighbors(Front(), Back())
    
    @test neighbors(Back(), Top())
    @test neighbors(Back(), Bottom())
    @test neighbors(Back(), Left())
    @test neighbors(Back(), Right())
    @test !neighbors(Back(), Back())
    @test !neighbors(Back(), Front())
end

@testset "Box Face neighbors are not opposites" begin
    for ft in subtypes(Face)
        f = ft()
        for n in neighbors(f)
            @test opposite(f) != n
        end
    end
end

@testset "Box Edge equality" begin
    @test Edge(Top(), Left()) == Edge(Left(), Top())
    @test hash(Edge(Top(), Left())) == hash(Edge(Left(), Top()))
    foo = Dict()
    foo[Edge(Top(), Left())] = 1
    @test get(foo, Edge(Left(), Top()), nothing) == 1
end

@testset "Box Face length_adjust" begin
    box = Box(; width = 3u"m",
              height = 1u"m",
              depth = 2u"m")
    for f in subtypes(Face)
        box.thickness[f()] = 5u"mm"
    end
    la = PanelCutting.length_adjust
    box.joint_types[Edge(Front(), Right())] = ButtJoint(Right())
    box.joint_types[Edge(Front(), Bottom())] = DadoJoint(Bottom(), 2u"mm")
    @test la(box, Back(), Left()) == 0u"mm"
    @test la(box, Front(), Right()) == 0u"mm"
    @test la(box, Right(), Front()) == -5u"mm"
    @test la(box, Front(), Bottom()) == 0u"mm"
    @test la(box, Bottom(), Front()) == -3u"mm"
end

@testset "Box" begin
    box = Box(; width = 3u"m",
              height = 1u"m",
              depth = 2u"m")
    box.open[Top()] = true
    box.grain_direction[Bottom()] = GDEither()
    for f in subtypes(Face)
        box.thickness[f()] = 5u"mm"
    end
    for f in neighbors(Bottom())
        box.joint_types[Edge(Bottom(), f)] = ButtJoint(f)
    end
    box.joint_types[Edge(Front(), Left())] =
        DadoJoint(Left(),
                  box.thickness[Front()] / 2)
    box.joint_types[Edge(Front(), Right())] =
        DadoJoint(Right(),
                  box.thickness[Front()] / 2)
    wanted = WantedPanels(box)
    @test length(wanted) == 6   # No top, bottom can be flipped.
    w(t, label) = filter(p -> p isa t && label == p.label,
                         wanted)
    @test w(WantedPanel, "Top") == []
    @info box.joint_types
    let
        @info "Back"
        back = w(WantedPanel, "Back")
        @test length(back) == 1
        back = back[1]
        @info back
        @test back.length > back.width
        @test back.length == box.width
        @test back.width == box.height - box.thickness[Bottom()]
    end
    let
        @info "Front"
        front = w(WantedPanel, "Front")
        @test length(front) == 1
        front = front[1]
        @info front
        @test front.length > front.width
        @test front.length == box.width
        @test front.width == box.height - box.thickness[Bottom()]
    end
    let
        @info "Left"
        left = w(WantedPanel, "Left")
        @test length(left) == 1
        left = left[1]
        @info left
        @test left.length > left.width
        dj = box.joint_types[Edge(Front(), Left())]
        @test float(left.length) == float(box.depth + dj.tongue_length - box.thickness[Front()])
        @test float(left.width) == float(box.height - box.thickness[Bottom()])
    end
    let
        @info "Right"
        right = w(WantedPanel, "Right")
        @test length(right) == 1
        right = right[1]
        @info right
        @test right.length > right.width
        dj = box.joint_types[Edge(Front(), Right())]
        @test float(right.length) == float(box.depth + dj.tongue_length - box.thickness[Front()])
        @test float(right.width) == float(box.height - box.thickness[Bottom()])
    end
    let
        @info "Bottom, WantedPanel"
        bottom = w(WantedPanel, "Bottom")
        @test length(bottom) == 1
        bottom = bottom[1]
        @info bottom
        @test bottom.length > bottom.width
        @test bottom.length == box.width
        @test bottom.width == box.depth
    end
    let
        @info "Bottom, FlippedPanel"
        bottom = w(FlippedPanel, "flipped Bottom")
        @test length(bottom) == 1
        bottom = bottom[1]
        @info bottom
        @test bottom.length < bottom.width
        @test bottom.length == box.depth
        @test bottom.width == box.width
    end
end
