# StepperControl

A basic stepper motor control implementation. It can be used with an Arduino board to control many stepper motors. The home functionally was not implemented yet.

## Installation

The `StepperControl.jl` is a non official Julia package. It can be installed using the following command inside the Julia REPL:

```julia
julia> using Pkg
julia> Pkg.add("https://github.com/gborelli89/StepperControl.jl")
```


## Initializing and configuring

The connection can be made with the function `stepper_open`. The arguments are

* `dof`: number of degrees of freedom (integer value).
* `port`: if *nothing* (default), then the first port in the list is used. The USB port was used during the development (Arduino).
* `baud`: baudrate (default = 9600).
* `testnocon`: used for testing purposes, if `true` then no actual connection is created.

The output is an object of `StepperSystem` type with the number of degrees of freedom desired. The attributes are:

* `con`: serial connection (missing if testnocon = true).
* `pos`: current position. 
* `id`: strings with stepper motors IDs. 
* `step2coord`: array of functions (one for each DOF) to convert the number of steps to coordinates.
* `coord2step`: array of functions (one for each DOF) to convert the coordinates to the number of steps.
* `depend`: array with the dependencies. When used allows more complex systems. As default the first coordinate depends only on the first stepper motor, the second on the second stepper motor and so on so forth. This attribute allows that a given coordinate will depend on multiple stepper motors.

Apart from the connection, all the other attributes must be modified accordingly. It is important to notice that `step2coord` and `coord2step` accept any function which transforms motor steps into coordinate and vice versa.

Examples:

```julia
julia> dev = stepper_open(3, testnocon=true); # for 3 DOF and no connection (testing)

julia> dev.pos # returns the position (origin as defaul)
3-element StaticArrays.MArray{Tuple{3},Float64,1,3} with indices SOneTo(3):
 0.0
 0.0
 0.0

julia> dev.id # returns the stepper IDs (should be changed accordingly)
3-element StaticArrays.MArray{Tuple{3},String,1,3} with indices SOneTo(3):
 "m1"
 "m2"
 "m3"
```

The configuration can be done with the function `stepper_config!`. The arguments for the function are

* `dev`: object of `StepperSystem` type.
* `motorID`: an array of strings with the stepper motors IDs.
* `step2coord`: array of functions (one for each DOF) to convert the number of steps to coordinates.
* `coord2step`: array of functions (one for each DOF) to convert the coordinates to the number of steps.

This function provides a way to change the `StepperSystem` attributes.

Example:

```julia
# Change stepper motors IDs  
julia> stepper_config!(dev, motorID=["x","y","z"]);
julia> dev.id
3-element StaticArrays.MArray{Tuple{3},String,1,3} with indices SOneTo(3):
 "x"
 "y"
 "z"
```

## Conversion between coordinates and steps

### Linear functions

Auxiliary linear functions are implemented. In many simple systems each stepper is responsible for displacements in one specific direction without influencing the others (the movements are decoupled!). Also, in many cases the relation between the displacement and the number of steps is (or can be considered) linear.

In order to transform the coordinates into steps the function `linear_coord2step` can be applied. On the other hand, if the number of steps should be converted into displagement in a given coordinate system, the function `linear_step2coord` can be used. In both cases two arguments can be given: the number of steps needed for one full rotation of the stepper motor and the bell crank radius. In the raius is equal to one (default), then the result is the angular displacement in radians.

Examples:

```julia
# Let's consider no. steps per revolution = 2048 (stepper datasheet), bell crank radius = 1.0    

julia> x = linear_step2coord(spr=2048, r=1.0);
julia> x(512)*180/π
90.0

julia> sx = linear_coord2step(spr=2048, r=1.0);
julia> sx(π/2)
512
```

### Functions depending on more steppers or non linear relations

The `step2coord` and the `coord2step` attributes of the `StepperSystem` object can accept any function for coordinate/step conversion. If desired, a system calibration can be performed and non-linearities can be incorporated to the model. Also, some systems can be coupled. Some of these situations can be treated with the `depend` attribute. An example is show in [https://github.com/gborelli89/flowControl_GA](https://github.com/gborelli89/flowControl_GA). 


## Zero function

One can define a position as zero with the function `zero_stepper!`. There is only one parameter: the `StepperSystem` object. The `pos` attriute is modified and all the entries are changed to *0.0*. To return the current position one can type `dev.pos` or `getpos(dev)`, *dev* being the `StepperSytem` object.

## Move function

The function `move_stepper!` can be used to move the stepper motors of the system and update the `pos` entries. The parameters are

* `dev`: object of StepperSystem type
* `new_coords`: array of the new coordinates
* `relat`: if true the relative movement is performed
* `order`: trigger order
* `method`: there are three methods available. For "manhattan_msg" steps are written one at a time. For "oneline_msg" everything is passed right through. The "test_msg" method don't need any connections (dev.con = missing).

Example:

```julia
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

# Example of an Arduino code

**Julia** 

```julia
using StepperControl
dev = stepper_open(2)

# Steps to coordinates function
s2c(step) = step*0.001 # 0.001 is the conversion ratio

# Coordinates to steps function (inverse of s2c)
c2s(coord) = coord/0.001

# Configure system
stepper_config(dev, motorID=["x","y"], step2coord=[s2c,s2c], coord2step=[c2s,c2s]);

# Move using move_stepper!
```

**Arduino**

```cpp
#include <Stepper.h> 
 
const int stepsPerRevolution = 500;
String v1;
String v2; 

//Pins
Stepper myStepperX(stepsPerRevolution, 22,24,23,25); 
Stepper myStepperY(stepsPerRevolution, 30,32,31,33); 

void setup() 
{   
    Serial.begin(9600);
    //Initial speed 
    myStepperX.setSpeed(60);
    myStepperY.setSpeed(60);
} 
  
void loop() 
{ 
    String motorID = "0";

    if(Serial.available()){
        
        String v1 = Serial.readStringUntil(';'); 
        String v2 = Serial.readStringUntil(';');
        
        motorID = v1;
        int motorSteps = v2.toInt();

        if(motorID=="x"){
          myStepperX.step(motorSteps);
        }
        if(motorID=="y"){
          myStepperY.step(motorSteps);
        }
       
     }

     Serial.println(motorID);
     delay(500);
}
```