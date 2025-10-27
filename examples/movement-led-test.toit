// Copyright (C) 2025 Toit Contributors
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.
import gpio
import rcwl0516 show *

/**
Simple example of having a movement event call a Lambda/Callback.

See README.md for wiring diagram.  Essentially the 'OUT' pin goes to a GPIO on
the ESP32.  A GPIO pin is also used for the LED.  It flashes 3 times before the
start of the function to show the wiring is correct.
*/

main:
  // Adjust these to pin numbers in your setup.
  led-pin    := gpio.Pin 27 --output
  detect-pin := gpio.Pin 26 --input --pull-down

  // Flash the LED pin to see that the LED is set up correctly.
  print "Testing LED setup..."
  led-pin.set 0
  3.repeat:
    led-pin.set 1
    sleep --ms=500
    led-pin.set 0
    sleep --ms=500

  // Start up the motion detection
  print "Starting Motion Detection..."
  rcwl0516-driver := Rwcl0516 detect-pin

  // Have the motion detection events turn the LED on or off
  rcwl0516-driver.set-callback --movement=:: led-pin.set 1
  rcwl0516-driver.set-callback --clear=:: led-pin.set 0

  // Run a loop and print something if the board shows a movement event.
  // Note that in this case it latches, and clears after the function is called.
  while true:
    if rcwl0516-driver.motion-detected:
      print "$((Duration --us=(Time.monotonic-us)).in-s)s: Motion Detected..."
    sleep --ms=250
