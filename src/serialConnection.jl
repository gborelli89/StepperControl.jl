# --------------------------------------------------------------------------------------
# Serial connection and stepper motor initialization
# --------------------------------------------------------------------------------------

mutable struct StepperSystem{N} 
    con
    pos::MVector{N,Float64}
    id::MVector{N,String}
    coordconv::MVector{N,Any}
    stepconv::MVector{N,Any}
end


"""
    stepper_open(dof; port=nothing, baud=9600)

## Description 
Function to open a generic connection and returns a StepperSystem type to control a system of stepper motors
## Arguments
- dof: degrees of freedom
- port: port path. If nothing it'll get the first port of SerialPort.list_serialports
- baud: baud rate (default = 9600)
## Observations
The output is a StepperSystem type including the following elements with fixed size (dof):
- con: port connection
- pos: position 
- id: stepper motors IDs
- coordconv: array of functions to convert steps into coordinates
- stepconv: array of functions to convert coordinates into steps
- testnocon: true for testing purposes. Makes dev.con equals missing
Except from con, all the other elements must be configured (see StepperControl.stepper_config)
"""
function stepper_open(dof; port=nothing, baud=9600, testnocon=false)

    if testnocon
        con = missing
    else
        if isnothing(port)
            port = list_serialports()[1]
        end
        con = SerialPort(port, baud)
    end

    pos = repeat([0.0], dof)
    id = "m" .* string.(1:dof)
    f(x) = float(x) 
    g(x) = Int(round(x))

    dev = StepperSystem{dof}(con, pos, id, repeat([f], dof), repeat([g], dof))

    return dev
end

"""
    linear_step2coord(; spr::Int, r=1.0)

## Description
Linear function to find coordinates from a number of steps
## Arguments
- spr: steps per revolution
- r: bell crank radius. The unit can be used to express angle displacements in radians.
## Example
```jldoctest
julia> x = linear_step2coord(spr=2048);

julia> x(512)
1.5707963267948966

julia> x(512)*180/π
90.0
```
"""
function linear_step2coord(;spr::Int, r=1.0)
    
    function f(steps::Real) 
        steps = Int(round(steps))
        r*2π*steps/spr
    end
    
    return f
end

"""
    linear_coord2step(; spr::Int, r=1.0)

## Description
Linear function to find steps from a displacement
## Arguments
- spr: steps per revolution
- r: bell crank radius. The unit can be used to express angle displacements in radians.
## Example
```jldoctest
julia> x = linear_coord2step(spr=2048);

julia> x(π/2)
512
```
"""
function linear_coord2step(;spr::Int, r=1.0) 
    g(coord::Real) = Int(round(coord*spr/(r*2π)))
    return g
end


"""
    stepper_config!(dev::StepperSystem; motorID::AbstractVector=dev.id, coordconv_fun::AbstractVector=dev.coordconv, stepconv_fun::AbstractVector=dev.stepconv)

## Description
Configure stepper system.
## Arguments
- dev: element of StepperSystem type
- motorID: array with motor IDs
- coordconv_fun: functions to convert steps into coordinates
- stepconv_fun: functions to convert coordinates into steps 
## Examples
```jldoctest
julia> r = stepper_open(2);

julia> r.id 
2-element MArray{Tuple{2},String,1,2} with indices SOneTo(2):
 "m1"
 "m2"

julia> r.coordconv[1](10)
10
julia> r.stepconv[1](10)
10

julia> f = linear_step2coord(spr=2048, r=2);

julia> g = linear_coord2step(spr=2048, r=2);

julia> stepper_config!(r, motorID=["x","y"], coordconv_fun=[f], stepconv_fun=[g]);

julia> r.id
2-element MArray{Tuple{2},String,1,2} with indices SOneTo(2):
 "x"
 "y"

 julia> r.coordconv[1](10)
 0.06135923151542565
 julia> r.coordconv[1](2048)/(2π)
 2.0

 julia> r.stepconv[1](10)
 1630
 julia> r.stepconv[1](4π)
 2048
```
"""
function stepper_config!(dev::StepperSystem; motorID::AbstractVector = dev.id, 
                        coordconv_fun::AbstractVector = dev.coordconv, 
                        stepconv_fun::AbstractVector = dev.stepconv)

    n = length(dev.id)
    dev.id = motorID

    if length(coordconv_fun) == 1 
        coordconv_fun = repeat(coordconv_fun, n)
    end
    dev.coordconv = coordconv_fun

    if length(stepconv_fun) ==1
        stepconv_fun = repeat(stepconv_fun, n)
    end
    dev.stepconv = stepconv_fun

end

    


"""
    stepper_open(;port=nothing, baud=9600)

## Description
Function to open the device.
## Arguments
- motorID: array of strings with the IDs of the stepper motors used
- port: port path. If nothing it'll get the first port of list_serialports()
- baud: baud rate
- testnocon: modify to true for testing with no serial connection
returns the connection
"""
#function stepper_open(motorID::AbstractString ;port=nothing, baud=9600, testnocon=false)
#
#    n = length(motorID)
#
#    if testnocon
#        con = nothing
#    else
#        if isnothing(port)
#            port = list_serialports()[1]
#        end
#        con = SerialPort(port, baud)
#    end
#
#    pos = repeat([0.0], n)
#
#    dev = (con=con, motorID=motorID, pos=pos)
#    return dev
#end

"""
    stepper_config(motorID::AbstractArray, ratio::AbstractArray)

## Description    
Initial configuration of the system.
## Arguments
- motorID: array of strings with the IDs of the stepper motors used
- ratio: array with the relation displacement/#steps for each stepper motor must have the same length as motorID
returns the initial position (at origin), stepper IDs and ratios
## Example
```jldoctest
julia> using StepperControl

julia> r = stepper_config(["x","y","z"], [1.0,1.0,1.0])
(pos = [0.0, 0.0, 0.0], motorID = ("x", "y", "z"), ratio = (1.0, 1.0, 1.0))
```
"""
#function stepper_config(motorID::AbstractArray, conversion::AbstractArray)
#    
#    motorID = string.(motorID)
#    #ratio = float(ratio)
#
#    n = length(motorID)
#    if length(conversion) != n
#        throw(DimensionMismatch("The number of ratios provided must match the number of stepper motors!"))
#    end
#
#    pos = @MVector zeros(n)
#
#    init = (pos=pos, motorID=Tuple(motorID), conversion=Tuple(conversion))
#
#    return init
#end
