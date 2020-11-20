module StepperControl

using SerialPorts
using StaticArrays

include("serialConnection.jl")
include("moveStepper.jl")

export
    StepperSystem,
    stepper_open,
    stepper_config!,
    linear_step2coord,
    linear_coord2step,
    stepper_zero!,
    getpos,
    stepper_move!

end
