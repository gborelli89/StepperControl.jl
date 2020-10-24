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
function coords2steps(s, coords::AbstractArray, order::Array{Int64,1}; relat=true)

    coords = float(coords)
    if relat
        steps = round.(Int, coords ./ s.ratio[order])
    else
        Δcoords = coords .- s.pos[order]
        steps = round.(Int, Δcoords ./ s.ratio[order])
    end

    return steps
end

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
function steps2coords!(s, steps::Array{Int64,1}, order::Array{Int64,1})

    s.pos[order] .= s.pos[order] .+ steps .* s.ratio[order]

end

"""
    zero_stepper!(s)

## Description
Zero position.
## Arguments
- s: system position and motor IDs (structure returned from configStepper())
"""
zero_stepper!(s) = s.pos .= s.pos .* 0

"""
    waitmove(dev)

## Description
Wait for stepper complete movement.
## Arguments
- dev: connection
"""
function waitmove(dev)

    status = 0
    while status == 0
        status = bytesavailable(dev)
    end

    sleep(0.2)
end

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
function move_stepper!(dev, s, new_coords::AbstractArray; relat=true, order=nothing, method="manhattan")

    new_coords = float(new_coords)

    if isnothing(order)
        order = collect(1:length(s.motorID))
    end
        stid = s.motorID[order]

    steps = coords2steps(s, new_coords, order, relat=relat)

    if method == "manhattan"
        msg = []
        for i in 1:length(order)
            msg_temp = stid[i]*";"*string(steps[i])*";"
            push!(msg, msg_temp)
            if !isnothing(dev)
                write(dev, msg_temp)
                waitmove(dev)
            end
        end

    elseif method == "all"
        msg = prod(stid.*";".*string.(steps).*";")
        if !isnothing(dev)
            write(dev, msg)
            waitmove(dev)
        end
    end

    steps2coords!(s, steps, order)
    return msg
end
