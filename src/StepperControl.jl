module StepperControl

using SerialPorts
using StaticArrays

include("serialConnection.jl")

include("moveStepper.jl")

export
    stepperOpen,
    stepperConfig,
    coords2steps,
    steps2coords!,
    zeroStepper!,
    moveStepper!

end
