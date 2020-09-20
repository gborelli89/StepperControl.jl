# --------------------------------------------------------------------------------------
# Serial connection and stepper motor initialization
# --------------------------------------------------------------------------------------

# Open device
# --------------------------------------------------------------------------------------
# port: port path. If nothing it'll get the first port of list_seriaports()
# baud: baud rate
# --------------------------------------------------------------------------------------
# returns the connection
# --------------------------------------------------------------------------------------
function stepperOpen(;port=nothing, baud=9600)

    if isnothing(port)
        port = list_serialports()[1]
    end
    dev = SerialPort(port, baud)

    return dev
end


# Initial configuration of the system
# --------------------------------------------------------------------------------------
# motorID: array of strings with the IDs of the stepper motors used
# ratio: array with the relation displacement/#steps for each stepper motor
#        must have the same length as motorID
# --------------------------------------------------------------------------------------
# returns initial position (at origin), stepper IDs and ratios
# --------------------------------------------------------------------------------------
function stepperConfig(motorID::Array{String,1}, ratio::Array{Float64,1})

    n = length(motorID)
    if length(ratio) != n
        throw(DimensionMismatch("The number of ratios provided must match the number of stepper motors!"))
    end

    pos = @MVector zeros(n)

    init = (pos=pos, motorID=Tuple(motorID), ratio=Tuple(ratio))

    return init
end
