

tcf1() = tcf2()

tcf2() = tcf3()   # Line 5

tcf3() = PanelCutting.callerFile()

@testset "callerFile" begin
    file, line = tcf1()
    @test file == @__FILE__()
    @test line == 5
end

