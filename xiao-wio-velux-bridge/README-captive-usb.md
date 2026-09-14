# Captive short-USB variant

This is a separate variant of the XIAO ESP32-S3 + Wio-SX1262 Velux bridge
enclosure. It is intended for a very short USB cable whose external connector
plugs into a charger while the cable's device-side plug and overmould remain
protected inside the enclosure.

The ordinary exposed-USB model remains available as a separate matched pair.

## Cable assumptions

The defaults reserve this internal plug envelope:

- 12.5 mm wide;
- 6.5 mm high;
- 13 mm long;
- cable no larger than 4.5 × 4.5 mm at the case entry.

Measure the chosen short cable before printing the full base. Adjust
`captive_plug_body_w`, `captive_plug_body_h`, `captive_plug_body_l`, and the
two `captive_cable_slot_*` parameters in the shared SCAD source if needed.

## Mechanical arrangement

- The XIAO/Wio stack sits at the closed rear end.
- The USB-C plug and its moulded body sit in the front bay.
- A vertical installation slot allows a complete cable to be laid into the
  base; a long lid tongue closes it to a 4.5 × 4.5 mm cable aperture.
- Two internal shoulders sit 0.8 mm ahead of the nominal overmould. An outward
  pull therefore reaches the enclosure shoulder before appreciably loading the
  XIAO connector.
- Antenna cable exits face forward. Their leads travel through the two open side
  channels to their connectors on the rear-mounted electronics.

## Assembly order

1. Confirm the short USB cable fits the plug envelope and entry slot without
   compression.
2. Adhere the Wi-Fi antenna to the left wall and LoRa antenna to the right wall,
   with both antenna cable exits toward the USB-cable end.
3. Route the antenna leads along the low side guides.
4. Plug the short USB-C cable into the XIAO while the board is still above the
   enclosure.
5. Connect both I-PEX antenna plugs.
6. Lay the USB cable into the open vertical entry slot, keeping its overmould
   behind the two strain shoulders.
7. Lower all fourteen header pins into the deeper printed sockets until the
   board reaches both end shelves. There are no separate PCB clips to engage.
8. Check that no cable crosses the rim. Fit the lid so its long front tongue
   closes the installation slot, then engage all four internal lid clips.

Print the base on its floor and the lid exactly as exported, with the broad,
smooth exterior face against the build plate. Four 7 mm-wide, 1.5 mm-thick
flex clips span the centring lip's complete depth and continue 7.5 mm below the
lid. There is no 0.7 mm-thick section left in the flexible rectangle. Each has
a 10 mm sideways-flared tapered root. The complete tongues remain inside the
cavity; only their self-supporting diamond hooks enter slightly oversized
matching diamond wall pockets. Roughly 0.15 mm vertical profile clearance avoids
perceptible up/down lid travel while retaining printable tolerance. This
revision's relocated, thicker clips
require its matching newly exported base.

To remove the lid, put a thin flat screwdriver or similar metal tool into either
5 × 3 mm square slot in the long edge of the lid plate. Each slot reaches across
and 1 mm behind the base wall so the tool can twist at the lid/base seam. Both
variants have one lid slot per side; neither has release gaps in the base.

## Build

```sh
make captive_usb
```

Outputs are written to `export-captive-usb/`; the rendered assembly preview is
`previews/captive_usb_assembly.png`.
