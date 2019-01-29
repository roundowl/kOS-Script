declare r_hdg to 0.
declare r_spd to 0.

until (brakes) {
	set r_hdg to r_hdg - ship:control:pilotwheelsteer.
	if (r_hdg < 0) { set r_hdg to r_hdg + 360. }
	if (r_hdg > 360) { set r_hdg to r_hdg - 360. }
		
	set r_spd to r_spd + ship:control:pilotwheelthrottle.
		
	set my_hdg to
		arctan2(
			vdot(vcrs(ship:up:vector, ship:north:vector),ship:facing:forevector),
			vdot(ship:north:vector,ship:facing:forevector)
		).
	if (my_hdg < 0) {set my_hdg to my_hdg + 360.}.

	// 5 - 355 = -350 (should be 10) (biggest is 180 - 360 = -180)
	// 355 - 345 = 10 (as is)
	// 355 - 5 = 350 (should be -10) (biggest is 360 - 180 = 180)
	// 345 - 355 = -10 (as is)
	set diff_hdg to r_hdg - my_hdg.
	if (diff_hdg < -180) { set diff_hdg to diff_hdg + 360.}.
	if (diff_hdg > 180) { set diff_hdg to diff_hdg - 360.}.

	set ship:control:wheelsteer to -diff_hdg / 90.

	set ship:control:wheelthrottle to (r_spd - groundspeed). // / 10.
	
	clearscreen.
	print ("Driving to HDG " + round(r_hdg) + " at SPD " + round(r_spd,2)) at (0,0).
	//print ("My HDG is " + round(my_hdg) + " and SPD is " + round(groundspeed,2)) at (0,1).
	//print ("Diff HDG: " + round(diff_hdg,2)) at (0,2).
	//print ("Steer: " +
	//	round(ship:control:wheelsteer,2) +
	//	" Throttle: " +
	//	round(ship:control:wheelthrottle,2)
	//	) at (0,3).
	wait 0.
}.

SET SHIP:CONTROL:NEUTRALIZE to TRUE.