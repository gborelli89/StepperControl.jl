# --------------------------------------------------------------------------------------
# Serial connection and stepper motor initialization
# --------------------------------------------------------------------------------------


"""
    stepper_open(;port=nothing, baud=9600)

## Description
Function to open the device.
## Arguments
- port: port path. If nothing it'll get the first port of list_serialports()
- baud: baud rate
returns the connection
"""
function stepper_open(;port=nothing, baud=9600)

    if isnothing(port)
        port = list_serialports()[1]
    end
    dev = SerialPort(port, baud)

    return dev
end

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
function stepper_config(motorID::AbstractArray, ratio::AbstractArray)
    
    motorID = string.(motorID)
    ratio = float(ratio)

    n = length(motorID)
    if length(ratio) != n
        throw(DimensionMismatch("The number of ratios provided must match the number of stepper motors!"))
    end

    pos = @MVector zeros(n)

    init = (pos=pos, motorID=Tuple(motorID), ratio=Tuple(ratio))

    return init
end
