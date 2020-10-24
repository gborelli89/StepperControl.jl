# StepperControl

A basic stepper motor control implementation. It can be used with an Arduino board to control many stepper motors. The home functionally was not implemented yet.

## Initializing and configuring

The connection can be made with the function `stepper_open`. The arguments are

* `port`: if *nothing* (default), then the first port in the list is used. The USB port was used during the development (Arduino).
* `baud`: baudrate (default = 9600)

Examples:

```julia
con = serial_open() # for port=nothing and baud=9600
con = serial_open(port="dev/ttyACM0)
```

The configuration can be done with the function `stepper_config`. The arguments for the function are

* `motorID`: an array of strings with the stepper motors ID.
* `ratio`: the displacement/#steps ratio for each stepper motor

Notice this provides a generic implementation. Many steppers can be used at the same time. Also, the `ratio` can consider linear or angular displacements, depending on the application.

Example:

```julia
robo = stepper_config(["x","y","z","w"], [0.05,0.05.0.05,0.01])
```

The function retuns a *NamedTuple* with the initial position `robo.pos` (always considered at the origin), the motor IDs `robo.motorID` and the ratios `robo.ratio`. The position is the only variable which can be modified. The other arguments (motor ID and ratios) are given in tuples, therefore are fixed values.

## Conversion between coordinates and steps

Two auxiliary functions for stepper motor moving were created: `coords2steps` and `steps2coords!`. The first one converts an array with new coordinates to steps, that can be passed to the Arduino board via USB cable to control the steppe motors of the system. The second one does the other way round, converts the steps into coordinates, which is important to update the `robo.pos`.

Parameters for the functions (in order):

* the *NamedTuple* returned from `stepper_config`
* array with the  coordinates (`coords2steps`) or the number of steps (`steps2coords!`)
* indexes with the motor order
* `relat`: boolean indicating if the movement is absolute or relative (default - `relat=true`)

Examples:

```julia
steps_a = coords2steps(robo, [1.0,2.0,3.0,2.5], collect(1:4)) 
steps2coords!(robo, steps_a, collect(1:4))

steps_b = coords2steps(robo, [3.0,2.6], [2,1], relat=false) # absolute movement for "y" and "x" 
steps2coords!(robo, steps_b, [2,1])
```

## Zero function

One can define a position as zero with the function `zero_stepper!`. There is only one parameter: the *NamedTuple* defined above (returned from `stepper_config`). The `robo.pos` is modified and all the entries are changed to *0.0*.

## Move single or multiple steppers

The function `move_stepper!` can be used to move one or many stepper motors of the system and update the pos entries. The parameters are

* connection (returned from `stepper_open`)
* *NamedTuple* with the position and configuration info (returned from `stepper_config`)
* an array with the new coordinates

There are also some optional parameters:

* `relat`: boolean indicating if the movement is absolute or relative (default - `relat=true`)
* `order`: indexes indicating the sequence of motors. If *nothing* (default) ascending order is considered
* `method`: if *"manhattan"* (default) then one line for each motor is sent. If *"all"* then everything is sent in one line string. This will depend on the Arduino code.

Example:

```julia
 move_stepper!(con, robo, [1.0,2.0,3.4,7.1])  
 ```

# Example of an Arduino code

**Julia** 

```julia
using StepperControl
dev = stepper_open()
robot = stepper_config(["x","y"], [0.1,0.1])
# move using move_stepper!
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