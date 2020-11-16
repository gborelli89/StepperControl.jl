"""
    waitmove(dev::StepperSystem)

## Description
Wait for stepper complete movement.
## Arguments
- dev: element of StepperSystem type with the serial connection (dev.con)
"""
function waitmove(dev::StepperSystem)

    status = 0
    while status == 0
        status = bytesavailable(dev.con)
    end

    sleep(0.2)
end

"""
    stepper_zero!(dev::StepperSystem)

## Description
Makes current position the origin.
## Arguments
- dev: element of StepperSystem type  
"""
function stepper_zero!(dev::StepperSystem)
    dev.pos = dev.pos * 0.0
end

"""
    getpos(dev::StepperSystem)

## Description
Function to get the current position. Returns a vector of floats.
## Arguments
- dev: element of StepperSystem type
"""
getpos(dev::StepperSystem) = dev.pos[1:end]

"""
    deltacoord(dev::StepperSystem, new_coords::AbstractVector)

## Description
Computes de difference between the new and actual coordinates
## Arguments
- dev: element of StepperSystem type
- new_coords: array of the new coordinates
"""
deltacoord(dev::StepperSystem, new_coords::AbstractVector) = new_coords - getpos(dev)


"""
    stepper_move!(dev::StepperSystem, new_coords::AbstractVector; relat=true, order=1:length(dev.id), method="manhattan")

## Description
Move system
## Arguments
- dev: element of StepperSystem type
- new_coords: arry of the new coordinates
- relat: if true the relative movement is performed
- order: trigger order
- method: there are three methods available. For "manhattan" steps are written one at a time. For "all" everything is passed right through. The "test" method don't need any connections (dev.con = missing).
## Examples
```jldoctest
julia> dev = stepper_open(2);

julia> stepper_config!(dev, motorID=["x","y"]);

julia> stepper_move!(dev, [10.0, 20.0])
2-element Array{Any,1}:
 "x;10;"
 "y;20;"

 julia> getpos(dev)
 2-element Array{Float64,1}:
 10.0
 20.0

 julia> stepper_move!(dev, [10.0, 20.0], order=[2,1], method="all")
 "y;20;x;10;"

 julia> getpos(dev)
 2-element Array{Float64,1}:
 20.0
 40.0
```
"""
function stepper_move!(dev::StepperSystem, new_coords::AbstractVector; relat=true, order=1:length(dev.id), method="manhattan")

    n = length(order)

    new_coords = float(new_coords)
    stepper_id = dev.id[order]

    if !relat
        new_coords = deltacoord(dev, new_coords)
    end
    steps = [dev.stepconv[i](new_coords[i]) for i in order]

    if method == "manhattan"
        msg = []
        for j in 1:n
            msg_temp = stepper_id[j]*";"*string(steps[j])*";"
            push!(msg, msg_temp)
            if !isopen(dev.con)
                write(dev.con, msg_temp)
                waitmove(dev)
            end
        end

    elseif method == "all"
        msg = prod(stepper_id.*";".*string.(steps).*";")
        if !isopen(dev.con)
            write(dev.con, msg)
            waitmove(dev)
        end

    elseif method == "test"
        msg = prod(stepper_id.*";".*string.(steps).*";")
    end

    coords = [dev.coordconv[order[k]](steps[k]) for k in 1:n]
    dev.pos[order] += coords 

    return msg
end


"""
    coords2steps(s, coords::Array{Float64,1}, order::Array{Int64,1}; relat=true)
 
## Description
Converts coordinates to steps.
## Arguments
- s: system position and motor IDs (structure returned from stepper_config)
- coords: array with the next coordinates
- relat: boolean, if true relative coordinates is taken into account, if false, global (absolute) coordinates
## Example
```jldoctest
julia> using StepperControl
    
julia> r = stepper_config(["x","y","z"], [1.0,1.0,1.0]);
julia> coords2steps(r, [100.0, 50.0], [1,3])
2-element Array{Int64,1}:
 100
  50
```
"""
#function coords2steps(s, coords::AbstractArray, order::Array{Int64,1}; relat=true)
#
#    coords = float(coords)
#    if relat
#        steps = round.(Int, coords ./ s.ratio[order])
#    else
#        Δcoords = coords .- s.pos[order]
#        steps = round.(Int, Δcoords ./ s.ratio[order])
#    end
#
#    return steps
#end

"""
    steps2coords!(s, steps::Array{Int64,1}, order::Array{Int64,1})

## Description
Converts steps to coordinates.
## Arguments
- s: system position and motor IDs (structure returned from stepper_config)
- steps: array of itegers with the number of steps for each motor
## Example
```jldoctest
julia> using StepperControl
    
julia> r = stepper_config(["x","y","z"], [2.0,2.0,2.0]);
julia> steps2coords!(r, [10, 20, 30], [1,2,3])
3-element view(::StaticArrays.MArray{Tuple{3},Float64,1,3}, [1, 2, 3]) with eltype Float64:
 20.0
 40.0
 60.0
```
"""
#function steps2coords!(s, steps::Array{Int64,1}, order::Array{Int64,1})
#
#    s.pos[order] .= s.pos[order] .+ steps .* s.ratio[order]
#
#end

"""
    zero_stepper!(s)

## Description
Zero position.
## Arguments
- s: system position and motor IDs (structure returned from configStepper())
"""
#zero_stepper!(s) = s.pos .= s.pos .* 0

"""
    waitmove(dev)

## Description
Wait for stepper complete movement.
## Arguments
- dev: connection
"""
#function waitmove(dev)

#    status = 0
#    while status == 0
#        status = bytesavailable(dev.con)
#    end

#    sleep(0.2)
#end

"""
    move_stepper!(dev, s, new_coords::AbstractArray; relat=true, order=nothing, method="manhattan")

## Description
Move function.
## Arguments
- dev: device connection returned from stepper_open(). If "nothing", no connection is provided (for testing purposes)
- s: system position and motor IDs (structure returned from stepper_config)
- new_coords: array with the new coordinates
- relat: boolean, if true relative coordinates is taken into account, if false, global (absolute) coordinates
- motorID: stepper motor ID (to comunicate with Arduino, for example)
- order: sequence of movements (just for manhattan motion type)
- method: type of motion applied (Arduino code must be done accordingly). Two types are supported: "manhattan" (one stepper at time) and "all"
returns the final position
## Examples
```jldoctest
julia> using StepperControl

julia> r = stepper_config(["x","y","z"], [1.0,1.0,1.0]);
julia> move_stepper!(nothing, r, [50.0,20.0,32.0])
3-element Array{Any,1}:
 "x;50;"
 "y;20;"
 "z;32;"

julia> move_stepper!(nothing, r, [50.0,20.0,32.0], relat=false)
3-element Array{Any,1}:
 "x;0;"
 "y;0;"
 "z;0;"

julia> move_stepper!(nothing, r, [50.0,20.0,32.0], relat=true, method="all")
"x;50;y;20;z;32;"

julia> r.pos
3-element StaticArrays.MArray{Tuple{3},Float64,1,3} with indices SOneTo(3):
 100.0
  40.0
  64.0
```
"""
#function move_stepper!(dev, s, new_coords::AbstractArray; relat=true, order=nothing, method="manhattan")
#
#    new_coords = float(new_coords)
#
#    if isnothing(order)
#        order = collect(1:length(s.motorID))
#    end
#        stid = s.motorID[order]
#
#    steps = coords2steps(s, new_coords, order, relat=relat)
#
#    if method == "manhattan"
#        msg = []
#        for i in 1:length(order)
#            msg_temp = stid[i]*";"*string(steps[i])*";"
#            push!(msg, msg_temp)
#            if !isnothing(dev)
#                write(dev, msg_temp)
#                waitmove(dev)
#            end
#        end
#
#    elseif method == "all"
#        msg = prod(stid.*";".*string.(steps).*";")
#        if !isnothing(dev)
#            write(dev, msg)
#            waitmove(dev)
#        end
#    end
#
#    steps2coords!(s, steps, order)
#    return msg
#end
