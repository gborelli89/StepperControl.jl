module StepperControl

using SerialPorts
using StaticArrays

include("serialConnection.jl")

include("moveStepper.jl")

export
    stepper_open,
    stepper_config,
    coords2steps,
    steps2coords!,
    zero_stepper!,
    move_stepper!

end
