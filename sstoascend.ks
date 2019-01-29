//Flight plan is as follows:
//Take off using 10 deg pitch, 90 deg hdg, 0 deg roll.
//Assist by steering landing gear to keep 90 deg hdg.
//Wait for positive rate of climb (or positive FPA)
//Gear up (manually?)
//Keep 5 deg AoA or zero deg FPA, whichever gives higher FPA
//Wait for 5000 MSL
//Keep FPA at 5 deg
//Wait for 1200 m/s
//FLCH from 1200 m/s, 1 deg per 10 m/s, keep FPA and nose above horizon
clearscreen.
SET Config:IPU to 2000.
print("SSTO launch program. Roundowl Industries. 2019-01-29.") at (0,1).
print("1) Taking off. Speed:" + round(ship:groundspeed,2)) at (0,2).
print("   Pitch is held at 10 deg. Do not raise landing gear.") at (0,3).
print("2) Will climb at 5 deg AoA to 5000 metres.") at (0,4).
//print("") at (0,5).
print("3) Will accelerate with 5 deg FPA to 1200 m/s.") at (0,6).
//print("") at (0,7).
print("4) Will keep 1200 m/s and climb to space.") at (0,8).
//print("") at (0,9).

lock acftpitch to 90 - vang(up:vector,ship:facing:forevector).
lock FPA to 90 - vang(up:vector,ship:velocity:surface).
lock AoA to acftpitch - FPA.

lock roll to 90 - vang(up:vector,ship:facing:starvector).

// Accelerometer
//declaring local variables 
LOCAL currVel TO SHIP:VELOCITY:ORBIT.   LOCAL currTime TO TIME:SECONDS.
LOCAL prevVel TO currVel.               LOCAL prevTime TO currTime.

//compute the gravitational acceleration of the celestial body at the current altitude.
LOCK gravitationalAcc TO SHIP:BODY:MU / (SHIP:BODY:RADIUS + SHIP:ALTITUDE)^2.

//the computed acceleration vector
GLOBAL acc TO V(0, 0, 0).
function accelerometer {
    //sample time and velocity
    SET currVel TO SHIP:VELOCITY:ORBIT. SET currTime TO TIME:SECONDS.
    
    //If zero time elapsed since the previous measurement, prevent division by zero.
    LOCAL timeDelta TO currTime - prevTime.
    IF timeDelta <> 0
    { 
        //derive the acceleration from the change of velocity over time,
        //add in the gravitational acceleration.
        SET acc TO (currVel - prevVel) * (1 / timeDelta) + UP:FOREVECTOR * gravitationalAcc.
    }
    
    //store the current time and velocity for the next calculations.
    SET prevVel TO currVel. SET prevTime TO currTime.
    return acc.
}

function pitchProtect {
    parameter
    tPitch,
    acftpitch,
    FPA.
    // G-load protection (requires acc sensor)
    set gload to vdot(ship:facing:topvector, accelerometer()) / 9.8.
    print("Protections in effect: " + abs(round(gload,3)) + " " + round((acftpitch - FPA),3)) at (0,10). //+LOAD ALPHA
    if (gload > 3.5) {
        set tPitch to FPA+(tPitch-FPA)*(4.5-gload).
        print("+LOAD") at (23,10).
    }
    if (gload < -3.0) {
        set tPitch to FPA-(FPA-tPitch)*(4.0-abs(gload)).
        print("-LOAD") at (23,10).
    }
    // Alpha protection (stall)
    if ((acftpitch - FPA) > 8) {
        set tPitch to min(tPitch, FPA + 8).
        print("ALPHA") at (29,10).
    }
    //Attitude protection
    set tPitch to max(-20,min(45,tPitch)).
    return tpitch.
}

//Take off using 10 deg pitch, 90 deg hdg, 0 deg roll.
//Assist by steering landing gear to keep 90 deg hdg.
//lock steering to ship:north + R(-90,90+10,90). //hdg pitch roll
lock steering to heading(90,10).
lock wheelsteering to 90.

//Wait for positive rate of climb (or positive FPA)
//Gear up (manually?)
until ship:verticalspeed > 10 {
    print("1) Taking off. Speed:" + round(ship:groundspeed,1)) at (0,2).
    wait 0.1.
}
print("1) Taking off. Positive rate achieved at:" + round(ship:groundspeed,1) + " m/s.") at (0,2).
unlock wheelsteering.
unlock steering.
print("   It is now safe to raise the landing gear. Retracting.") at (0,3).
GEAR OFF.

//Keep 5 deg AoA or zero deg FPA, whichever gives higher FPA
//Also do load and stall protections
function maximiseFPA {
    parameter
    acftpitch,
    FPA.

    set tPitch to max(0 + (acftpitch - FPA), FPA + 5).
    print("   Target: " + round(tPitch,1) + " FPA: " + round(FPA,1) + " Pitch: " + round(acftpitch,1)) at (0,5).
    set tPitch to pitchprotect(tpitch,acftpitch,FPA).
    return tPitch.
}

//lock steering to ship:north + R(-90,90+maximisefpa(acftpitch,FPA),90).
lock steering to heading(90,maximisefpa(acftpitch,FPA)).
//print("2) Climbing. Alt: " + round(ship:altitude,0) + " AoA: " + AoA) at (0,4).
//print("") at (0,5).

//Wait for 5000 MSL
until ship:altitude > 5000 {    
    print("2) Climbing to 5000 metres.") at (0,4).
    //print("   Pitch: " + round(acftpitch,1) + " FPA: " + round(FPA,1) + " Pitch: " + round(acftpitch,1)) at (0,5).
    wait 0.1.
}
print("2) Successfully climbed to 5000 metres.") at (0,4).
print("   Speed at 5000 metres was: " + round(ship:groundspeed,1) + "    ") at (0,5).
unlock steering.

function keepFPA {
    parameter
    targetFPA,
    actualFPA,
    acftpitch.

    set tPitch to max(targetFPA,min(targetFPA+acftpitch-actualfpa, targetFPA+10)).
    set tPitch to pitchprotect(tpitch,acftpitch,actualFPA).
    return tPitch.
}
//Keep FPA at 5 deg
//lock steering to ship:north + R(-90,90+keepFPA(5.0,FPA,acftpitch),90).
lock steering to heading(90,keepFPA(5.0,FPA,acftpitch)).

//Wait for 1200 m/s
until ship:groundspeed > 1000 {
    print("3) Accelerating with 5 deg FPA to 1200 m/s.") at (0,6).
    print("   Alt: " + round(ship:altitude,0) + " FPA: " + round(FPA,2) + " Speed: " + round(ship:groundspeed,1)) at (0,7).
    wait 0.1.
}
print("3) Successfully accelerated to 1000 m/s.   ") at (0,6).
print("   Altitude where 1200 m/s were achieved was " + round(ship:altitude,0) + " metres.") at (0,7).
unlock steering.

//FLCH from 1000 m/s, 1 deg per 10 m/s, keep FPA and nose above horizon
function FLCH {
    parameter
    targetSpeed,
    FPA,
    acftpitch.

    set tPitch to max(FPA, FPA + (ship:groundspeed - targetSpeed)/10).
    set tPitch to pitchprotect(tPitch,acftpitch,FPA).
    return tPitch.
}

//lock steering to ship:north + R(-90,90+FLCH(1200,FPA,acftpitch),90).
lock steering to heading(90,FLCH(1000,FPA,acftpitch)).

//Waiting for space.
until ship:apoapsis > 75000 {
    print("4) Keeping more than 1200 m/s to space. Attitude limit 30 deg.") at (0,8).
    print("   Alt: " + round(ship:altitude,0) + " FPA: " + round(FPA,2) + " Speed: " + round(ship:groundspeed,1)) at (0,9).
    wait 0.1.
}
unlock steering.
print("4) Successfully got apoapsis to 75000 metres. FPA was " + round(FPA,2) + " and speed was:" + round(ship:groundspeed,1)) at (0,8).
print("   Setting SAS to prograde mode to minimise drag.") at (0,9).
print("   Prepare for circularization. Thanks for flying with us.") at (0,10).
SAS on.
wait 0.
SET Config:IPU to 200.
set SASMODE to "PROGRADE".