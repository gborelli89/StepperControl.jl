using StepperControl
using Test

@testset "StepperControl.jl" begin
    p = stepperConfig(["x","y","z","w"], [0.1,0.1,0.1,0.1])
    @test_throws DimensionMismatch stepperConfig(["x","y","z"],[1.0,1.0])
    @test p.pos == [0.0,0.0,0.0,0.0]
    @test p.motorID == ("x","y","z","w")
    @test p.ratio == (0.1,0.1,0.1,0.1)
    @test coords2steps(p,[1.2,2.5,3.3,7.3],collect(1:4)) == [12,25,33,73]
    @test coords2steps(p, [2.6,3.2], [3,2]) == [26,32]
    @test coords2steps(p, [2.6,3.22], [3,2]) == [26,32]
    @test coords2steps(p, [2.6,3.27], [3,2]) == [26,33]
    @test_throws DimensionMismatch coords2steps(p, [2.6,3.2,2.1], [1,2])
    @test_throws MethodError coords2steps(p, [2,3], [1,2])

    st = [22,30,13,44]
    steps2coords!(p, st, collect(1:4))
    @test p.pos == [2.2,3.0,1.3,4.4]
    steps2coords!(p, st, collect(1:4))
    @test p.pos == [4.4,6.0,2.6,8.8]
    coords2steps(p,[4.4,6.0,1.3,4.4],collect(1:4),relat=false) == [0,0,0,0]
    zeroStepper!(p)
    @test p.pos == [0.0,0.0,0.0,0.0]
    @test_throws DimensionMismatch steps2coords!(p,st,[1,2])

    @test moveStepper!(nothing, p, [2.9,3.2,11.1,4.5]) == ["x;29;","y;32;","z;111;","w;45;"]
    @test p.pos ≈ [2.9,3.2,11.1,4.5]
    @test moveStepper!(nothing, p, [2.9,3.2,11.1,4.5], relat=false) == ["x;0;","y;0;","z;0;","w;0;"]
    @test p.pos ≈ [2.9,3.2,11.1,4.5]
    zeroStepper!(p)
    @test p.pos == [0.0,0.0,0.0,0.0]
    @test moveStepper!(nothing, p, [2.2,3.3], order=[3,2]) == ["z;22;","y;33;"]
    @test p.pos ≈ [0.0,3.3,2.2,0.0]
    @test_throws DimensionMismatch moveStepper!(nothing, p, [2.2,3.3])
    @test moveStepper!(nothing, p, [1.2,3.5,3.0,4.0], relat=false) ==["x;12;","y;2;","z;8;","w;40;"]
    @test p.pos ≈ [1.2,3.5,3.0,4.0]

end
