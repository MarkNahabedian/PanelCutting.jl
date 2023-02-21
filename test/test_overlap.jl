
@testset "Panel Overlap" begin
    let
        xs1 = XSpan(0, 25)
        xs2 = XSpan(25.125, 30)
        @test !overlap(xs1, xs2)
    end
    let
        s = XSpan(0, 10)
        @test within(0, s)
        @test within(10, s)
        @test within(5, s)
        @test !within(12, s)
    end
    let
        s1 = XSpan(0, 10)
        s2 = XSpan(3, 7)
        s3 = XSpan(5, 15)
        s4 = XSpan(12, 20)
        @test overlap(s1, s2)
        @test overlap(s2, s1)
        @test overlap(s1, s3)
        @test overlap(s3, s1)
        @test !overlap(s1, s4)
        @test !overlap(s4, s1)
    end
end

