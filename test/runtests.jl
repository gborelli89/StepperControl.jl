using StepperControl
using Test

@testset "StepperControl.jl" begin
    s = stepper_open(3, testnocon=true)
    stepper_config!(s, motorID=["x","y","z"])
    @test getpos(s) == [0,0,0]
    @test s.id == ["x", "y", "z"]
    @test stepper_move!(s, [10,20,30], method="test") == "x;10;y;20;z;30;"
    @test getpos(s) == [10,20,30]
    @test stepper_move!(s, [1,2,3], order=[2,3,1], method="test") == "y;2;z;3;x;1;"
    @test getpos(s) == [11,22,33]
    @test stepper_move!(s, [1,2,3], relat=false, method="test") == "x;-10;y;-20;z;-30;"
    @test getpos(s) == [1,2,3]
    stepper_zero!(s)
    @test getpos(s) == [0,0,0]
    @test stepper_move!(s, [1,2,3], order=[2], method="test") == "y;2;"
    @test getpos(s) == [0,2,0]

    f = linear_step2coord(spr=2048, r=10)
    @test f(2048)/(2π) == 10.0
    g = linear_coord2step(spr=2048, r=10)
    @test g(f(2048)) == 2048
    stepper_config!(s, step2coord=[f,f,f], coord2step=[g,g,g])
    @test s.step2coord[1](1024)/π == 10
    @test s.coord2step[1](s.step2coord[1](100)) == 100

#    p = stepper_config(["x","y","z","w"], [0.1,0.1,0.1,0.1])
#    @test_throws DimensionMismatch stepper_config(["x","y","z"],[1.0,1.0])
#    @test p.pos == [0.0,0.0,0.0,0.0]
#    @test p.motorID == ("x","y","z","w")
#    @test p.ratio == (0.1,0.1,0.1,0.1)
#    @test coords2steps(p,[1.2,2.5,3.3,7.3],collect(1:4)) == [12,25,33,73]
#    @test coords2steps(p, [2.6,3.2], [3,2]) == [26,32]
#    @test coords2steps(p, [2.6,3.22], [3,2]) == [26,32]
#    @test coords2steps(p, [2.6,3.27], [3,2]) == [26,33]
#    @test_throws DimensionMismatch coords2steps(p, [2.6,3.2,2.1], [1,2])

#    st = [22,30,13,44]
#    steps2coords!(p, st, collect(1:4))
#    @test p.pos == [2.2,3.0,1.3,4.4]
#    steps2coords!(p, st, collect(1:4))
#    @test p.pos == [4.4,6.0,2.6,8.8]
#    coords2steps(p,[4.4,6.0,1.3,4.4],collect(1:4),relat=false) == [0,0,0,0]
#    zero_stepper!(p)
#    @test p.pos == [0.0,0.0,0.0,0.0]
#    @test_throws DimensionMismatch steps2coords!(p,st,[1,2])

#    @test move_stepper!(nothing, p, [2.9,3.2,11.1,4.5]) == ["x;29;","y;32;","z;111;","w;45;"]
#    @test p.pos ≈ [2.9,3.2,11.1,4.5]
#    @test move_stepper!(nothing, p, [2.9,3.2,11.1,4.5], relat=false) == ["x;0;","y;0;","z;0;","w;0;"]
#    @test p.pos ≈ [2.9,3.2,11.1,4.5]
#    zero_stepper!(p)
#    @test p.pos == [0.0,0.0,0.0,0.0]
#    @test move_stepper!(nothing, p, [2.2,3.3], order=[3,2]) == ["z;22;","y;33;"]
#    @test p.pos ≈ [0.0,3.3,2.2,0.0]
#    @test_throws DimensionMismatch move_stepper!(nothing, p, [2.2,3.3])
#    @test move_stepper!(nothing, p, [1.2,3.5,3.0,4.0], relat=false) ==["x;12;","y;2;","z;8;","w;40;"]
#    @test p.pos ≈ [1.2,3.5,3.0,4.0]

end
