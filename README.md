# About FyrLysAR

Why isn't the light in the lighthouse on during the day? Well, with FyrLysAR,
it is. This app shows the lights from lighthouses as they look from where you
are. Position, color and blinking pattern all match the real thing. Even in
broad daylight.

FyrLysAR augments the image from the camera with blinking lights representing
lighthouses. Put a light at the center of the screen to show more information
about that lighthouse at the bottom of the screen.

## Where are the lighthouses?

The position, height, color and character (blinking pattern) of the
lighthouses in Norway are read from the
[Norwegian List of Lights](https://nfs.kystverket.no/fyrlister/Fyrliste_HeleLandet.pdf)
published by the [Norwegian Costal Administration](https://kystverket.no).
There are about 7600 lighted marine aids for navigation along the
coast of Norway.

## What colors are the lights?

The colors used in lighted marine navigagational aids are white, red, green,
blue, and yellow. We have used [color reccomendations](https://www.iala-aism.org/product/r0201/)
from the [International Association of Marine Aids to Navigation and Lighthouse Authorities](https://www.iala-aism.org)
The colors are converted from xy to rgb using [ColorMine](https://colormine.org/convert/rgb-to-yxy)

## What is the blinking like?

The character - blinking pattern - used in the app is according to the
reccomandations in
[Rythmic Characters of Lights on aids to Navigation](https://www.iala-aism.org/product/r0110/)
This might not match the actual blinking perfectly, but is should show a
blinking which is easily recognisable and matching the description in the
List of Lights.

## Where is my camera pointing?

The phone has accelerometers essentially showing which direction is down. There
is also a compass showing which way is North. Together with the GPS showing
where the phone is and the location of the lighthouses, we calculate which
lighthouse the phone is pointing its camera at.

## What about the islands blocking my view?

If there is an island blocking your view of a lighthouse, the app will not show
that light. How does the app know about the island? The height above sea
level of all of Norway is available from the
[Norwegian Mapping Authority](https://hoydedata.no/LaserInnsyn2/). Combined
with your position and that of the lighthouse, the app can calcualte if there
is an island in the way.
