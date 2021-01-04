"""
    waitmove(dev::StepperSystem)

## Description
Wait for stepper complete movement.
## Arguments
- dev: object of StepperSystem type with the serial connection (dev.con)
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
- dev: object of StepperSystem type  
"""
function stepper_zero!(dev::StepperSystem)
    dev.pos = dev.pos * 0.0
end

"""
    getpos(dev::StepperSystem)

## Description
Function to get the current position. Returns a vector of floats.
## Arguments
- dev: object of StepperSystem type
"""
getpos(dev::StepperSystem) = dev.pos[1:end]


"""
    manhattan_msg(dev::StepperSystem, id, steps)

## Description
Function to pass one instruction per line
## Arguments
- dev: object of StepperSystem type
- id: stepper motor id
- steps: number of steps
"""
function manhattan_msg(dev::StepperSystem, id, steps)
    
    n =length(id)

    msg = []
    for j in 1:n
        msg_temp = id[j]*";"*string(steps[j])*";"
        push!(msg, msg_temp)
        if isopen(dev.con)
            write(dev.con, msg_temp)
            waitmove(dev)
        else
            throw(AssertionError("Please open the connection!"))
        end
    end

    return msg
end


"""
    oneline_msg(dev::StepperSystem, id, steps)

## Description
Function to pass all instructions in one line
## Arguments
- dev: object of StepperSystem type
- id: stepper motor id
- steps: number of steps
"""
function oneline_msg(dev::StepperSystem, id, steps)

    msg = prod(id.*";".*string.(steps).*";")
    if isopen(dev.con)
        write(dev.con, msg)
        waitmove(dev)
    else
        throw(AssertionError("Please open the connection!"))
    end

    return msg
end


"""
    test_msg(dev::StepperSystem, id, steps)

## Description
Function test message for a stepper motor system
## Arguments
- dev: object of StepperSystem type
- id: stepper motor id
- steps: number of steps
"""
function test_msg(dev::StepperSystem, id, steps)
    msg = prod(id.*";".*string.(steps).*";")
end

"""
    stepper_move!(dev::StepperSystem, new_coords; relat=true, order=1:length(dev.id), method="manhattan")

## Description
Move system
## Arguments
- dev: object of StepperSystem type
- new_coords: array of the new coordinates
- relat: if true the relative movement is performed
- order: trigger order
- method: there are three methods available. For "manhattan_msg" steps are written one at a time. For "oneline_msg" everything is passed right through. The "test_msg" method don't need any connections (dev.con = missing).
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

 julia> stepper_move!(dev, [10.0, 20.0], order=[2,1], method=StepperControl.oneline_msg)
 "y;20;x;10;"

 julia> getpos(dev)
 2-element Array{Float64,1}:
 20.0
 40.0
```
"""
function stepper_move!(dev::StepperSystem, new_coords; relat=true, order=1:length(dev.id), method=manhattan_msg)

    n = length(new_coords)

    new_coords = float(new_coords)
    stepper_id = dev.id[order]

#    if !relat
#        new_coords = deltacoord(dev, new_coords)
#    end
    steps = [dev.coord2step[i](new_coords[dev.depend[i]]) for i in 1:n]
    coords = [dev.step2coord[k](steps[dev.depend[k]]) for k in 1:n]
    
    if !relat
        steps_init = [dev.coord2step[i](getpos(dev)[dev.depend[i]]) for i in 1:n]
        coords_init = [dev.step2coord[k](steps_init[dev.depend[k]]) for k in 1:n]
        steps = steps - steps_init
        coords = coords - coords_init
    end

    steps_msg = steps[order]

    msg = method(dev, stepper_id, steps_msg)

    #coords = [dev.step2coord[k](steps[dev.depend[k]]) for k in 1:n]
    dev.pos[order] += coords[order]

    return msg
end
