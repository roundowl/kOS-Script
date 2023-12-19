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

clearscreen.

// Parameters
parameter orbit_radius.

// Constants
set g to kerbin:mu / kerbin:radius^2.
lock twr to ship:availablethrust / (ship:mass * g).
lock acftpitch to 90 - vang(up:vector,ship:facing:forevector).
lock FPA to 90 - vang(up:vector,ship:velocity:surface).
lock AoA to acftpitch - FPA.
// ship:orbit:eccentricity

// Initial setup
set pitch to 90.
lock throttle to 1.
stage.

// Liftoff (hopefully)
wait until ship:altitude > 100.

// Turn to 90 deg heading
lock ship:control:pilotmainthrottle to min(1.0, max(0.0, 2 - twr)).
lock steering to heading(90, 90).

// Acceleration to 100 m/s
wait until ship:airspeed > 100.

set start_altitude to ship:altitude.
lock ideal_pitch to min(89, max(89 - 89 * (start_altitude / 70000), 0)).

lock steering to heading(90, FPA - 5).

wait until pitch <= ideal_pitch.

lock steering to heading(90, ideal_pitch).

wait until ship:apoapsis > orbit_radius - 1000.

lock ship:control:pilotmainthrottle to 0.05.
lock steering to ship:prograde.

wait until ship:apoapsis >= orbit_radius.

lock ship:control:pilotmainthrottle to min(1.0, max(0.0, orbit_radius - ship:apoapsis)).

wait until ship:altitude > 70000.

lock ship:control:pilotmainthrottle to 0.

wait until ship:orbit:eta:apoapsis < 30.
kuniverse:timewarp:cancelwarp()

lock ideal_pitch to min(10, max(-10, -ship:verticalspeed / 10)).
lock steering to heading(90, ideal_pitch).

wait until ship:orbit:eta:apoapsis < 10.

lock ship:control:pilotmainthrottle to min(1.0, max(0.0, 2 - twr)).

set curr_eccentricity to ship:orbit:eccentricity.
wait 0.

until ship:orbit:eccentricity < curr_eccentricity {
    set curr_eccentricity to ship:orbit:eccentricity.
    wait 0.
}

lock ship:control:pilotmainthrottle to 0.
wait 0.

unlock ship:control:pilotmainthrottle.
unlock steering.
