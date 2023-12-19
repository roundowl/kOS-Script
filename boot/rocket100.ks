// Generic rocket ascend script
// Takes orbit radius as a parameter
// Starts by going upwards, rotating to be pointing east with the bottom of a ship
// Starts gravity turn at 100 m/s
// Tries to achieve a target pitch which linearly goes from 90 to 0
// 90 at whichever altitude ship is at when 100 m/s triggered
// Lowers the target pitch to 0 at 70000 meters
// While doing that, keeps actual pitch of the ship within 5 deg of surface prograde
// Except above 70km, where simulated atmosphere ends and angle of attack does not matter
// Manages throttle to achieve a Thrust-to-Weight-Ratio (TWR) of 2.0 for the whole ascend
// When orbit apoapsis is 1000 meters below target, lower throttle gradually to 5%
// When apoapsis hits target, kill throttle, but account for drag while below 70km
// Then warp time to 30s before apoapsis, and circularize
// When orbit circularity is 0.1% or starts to get worse, kill throttle and end script

wait until ship:unpacked.
print("Executing ascent to 100km orbit, 90 deg inclination.").
wait 1.
print("Three").
wait 1.
print("Two").
wait 1.
print("One").
wait 1.
print("Liftoff!").

// Parameters
set orbit_radius to 100000.

// Constants
set g to kerbin:mu / kerbin:radius^2.
lock twr to ship:availablethrust / (ship:mass * g).
// lock acftpitch to 90 - vang(up:vector,ship:facing:forevector).
lock FPA to 90 - vang(up:vector,ship:velocity:surface).
// lock AoA to acftpitch - FPA.
// ship:orbit:eccentricity

// Initial setup
set ship:control:pilotmainthrottle to 1.
stage.
when ship:availablethrust = 0 then {
    set ship:control:pilotmainthrottle to 0.
    wait 0.
    stage.
    set ship:control:pilotmainthrottle to 1.
    if ship:deltav:current = 0 {
        return false.
    } else {
        return true.
    }
}

// Liftoff (hopefully)
wait until ship:altitude > 100.
print(46).
// Turn to 90 deg heading
lock steering to heading(90, 90).
lock desired_throttle to min(1.0, max(0.0, 2 / (twr+0.001))).

until ship:airspeed > 100 {
    set ship:control:pilotmainthrottle to desired_throttle.
    wait 0.
}

print(56).
set start_altitude to ship:altitude.
wait 0.
lock ideal_pitch to min(89, max(85 - 85 * ((ship:altitude-start_altitude) / 40000), 0)).
lock steering to heading(90, max(ideal_pitch, FPA - 10)).

print(61).
clearscreen.
until ship:apoapsis > orbit_radius - 1000 {
    set ship:control:pilotmainthrottle to desired_throttle.
    print(start_altitude) at (0,0).
    print(FPA) at (1,1).
    print(ideal_pitch) at (1,2).
    wait 0.
}
print(66).
set ship:control:pilotmainthrottle to 0.05.
lock steering to ship:prograde.

wait until ship:apoapsis >= orbit_radius.

lock desired_throttle to min(1.0, max(0.0, orbit_radius - ship:apoapsis)).

until ship:altitude > 70000 {
    set ship:control:pilotmainthrottle to desired_throttle.
    wait 0.
}

set ship:control:pilotmainthrottle to 0.

wait until ship:orbit:eta:apoapsis < 60.
kuniverse:timewarp:cancelwarp().

lock ideal_pitch to min(45, max(0, -ship:verticalspeed)).
lock steering to heading(90, ideal_pitch).

wait until ship:orbit:eta:apoapsis < 10.
kuniverse:timewarp:cancelwarp().
wait until kuniverse:timewarp:issettled().

lock desired_throttle to min(1.0, max(0.0, 2 / (twr+0.001))).
set ship:control:pilotmainthrottle to desired_throttle.
wait 1.
set curr_eccentricity to ship:orbit:eccentricity.
wait 0.

// until ship:periapsis > orbit_radius - 1000 {
//     set ship:control:pilotmainthrottle to desired_throttle.
//     set curr_eccentricity to ship:orbit:eccentricity.
//     wait 0.
// }

until ship:orbit:eccentricity > curr_eccentricity {
    set ship:control:pilotmainthrottle to desired_throttle.
    set curr_eccentricity to ship:orbit:eccentricity.
    print(curr_eccentricity) at (0,0).
    wait 0.
}

set ship:control:pilotmainthrottle to 0.
wait 0.

unlock steering.
