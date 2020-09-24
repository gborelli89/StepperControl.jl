# Convert coordinates to steps
# --------------------------------------------------------------------------------------
# s: system position and motor IDs (structure returned from configStepper())
# coords: array with the next coordinates
# relat: boolean, if true relative coordinates is taken into account,
#        if false, global (absolute) coordinates
# --------------------------------------------------------------------------------------
# returns an array with the number of steps for each motor
# --------------------------------------------------------------------------------------
function coords2steps(s, coords::Array{Float64,1}, order::Array{Int64,1}; relat=true)

    if relat
        steps = round.(Int, coords ./ s.ratio[order])
    else
        Δcoords = coords .- s.pos[order]
        steps = round.(Int, Δcoords ./ s.ratio[order])
    end

    return steps
end


# Convert steps to coordinates
# ---------------------------------------------------------------------
# s: system position and motor IDs (structure returned from configStepper())
# steps: array of itegers with the number of steps for each motor
# ---------------------------------------------------------------------
function steps2coords!(s, steps::Array{Int64,1}, order::Array{Int64,1})

    s.pos[order] .= s.pos[order] .+ steps .* s.ratio[order]

end


# Makes position an origin
# ---------------------------------------------------------------------
# s: system position and motor IDs (structure returned from configStepper())
# ---------------------------------------------------------------------
zeroStepper!(s) = s.pos .= s.pos .* 0


# Wait for complete movement
# ---------------------------------------------------------------------
# dev: connection
# ---------------------------------------------------------------------
function waitMove(dev)

    status = 0
    while status == 0
        status = bytesavailable(dev)
    end

    sleep(0.2)
end

# Move function
# ---------------------------------------------------------------------
# dev: device connection returned from stepperOpen()
#      if "nothing", no connection is provided (for testing purposes)
# s: system position and motor IDs (structure returned from configStepper())
# new_coords: array with the new coordinates
# relat: boolean, if true relative coordinates is taken into account,
#        if false, global (absolute) coordinates
# motorID: stepper motor ID (to comunicate with Arduino, for example)
# order: sequence of movements (just for manhattan motion type)
# method: type of motion applied (Arduino code must be done accordingly)
#         two types are supported: "manhattan" (one stepper at time) and "all"
# ---------------------------------------------------------------------
# returns the final position
# ---------------------------------------------------------------------
function moveStepper!(dev, s, new_coords::Array{Float64,1}; relat=true,
                    order::Union{Array{Int64,1},Nothing}=nothing, method="manhattan")


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
                waitMove(dev)
            end
        end

    elseif method == "all"
        msg = prod(stid.*";".*string.(steps).*";")
        if !isnothing(dev)
            write(dev, msg)
            waitMove(dev)
        end
    end

    steps2coords!(s, steps, order)
    return msg
end
