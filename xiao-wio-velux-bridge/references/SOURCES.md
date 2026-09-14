# Mechanical sources

All measurements are in millimetres.

## Seeed Studio XIAO ESP32-S3

- Product documentation and resources:
  <https://wiki.seeedstudio.com/xiao_esp32s3_getting_started/>
- Official 3D model archive:
  <https://files.seeedstudio.com/wiki/SeeedStudio-XIAO-ESP32S3/res/seeed-studio-xiao-esp32s3-3d_model.zip>
- STEP bounding box measured locally: **22.48198 × 4.46000 × 17.78000**. Axes
  were reordered in the enclosure parameters as length × width × height.
- The longer dimension includes the USB-C connector overhang.
- Official Seeed KiCad footprint:
  <https://github.com/Seeed-Studio/OPL_Kicad_Library/blob/master/Seeed%20Studio%20XIAO%20Series%20Library/XIAO-ESP32-S3-DIP.kicad_mod>
  - two rows of seven through-hole pins;
  - **2.54 mm** pin pitch;
  - **15.24 mm** row spacing (row centres at ±7.62 mm);
  - official PCB drill **0.889 mm**. The printed sockets intentionally default
    larger at 1.15 mm to account for FDM hole contraction and 0.64 mm square pins.
- Seeed's XIAO PCB-design guide independently specifies 2.54 mm terminal pitch
  and a nominal 1.1 mm through-hole:
  <https://github.com/Seeed-Studio/OSHW-XIAO-Series/blob/main/document/PCB_Design_XIAO.md>

## Wio-SX1262 for XIAO

- Kit documentation:
  <https://wiki.seeedstudio.com/wio_sx1262_with_xiao_esp32s3_kit/>
- Official carrier-board 3D model archive:
  <https://files.seeedstudio.com/products/SenseCAP/Wio_SX1262/Wio-SX1262_for_XIAO_3D_file.rar>
- STEP bounding box measured locally: **17.78010 × 21.43981 × 7.30000**.

## Antennas

- Official Wi-Fi antenna datasheet:
  <https://files.seeedstudio.com/wiki/XIAO_WiFi/antenna/FPC_Antenna_2.4GHz_1.16dbi_for_XIAO_ESP32S3/res/Datasheet_2.4GHz_FPC_Antenna_1.16dbi_for_XIAO_ESP32S3.pdf>
  - body **37.4 ± 0.2 × 17.5 ± 0.2 mm**;
  - cable **65 ± 2 mm**, diameter **1.13 ± 0.1 mm**;
  - assembled thickness **≤1.80 mm**, including release paper.
- Seeed's kit antenna comparison image:
  <https://files.seeedstudio.com/wiki/XIAO_ESP32S3_for_Meshtastic_LoRa/37.png>
  - supplied LoRa FPC body **40 × 7 × 1 mm**;
  - I-PEX cable **50 mm**;
  - stated maximum gain **0.04 dBi**;
  - Seeed describes it as an included test/short-range antenna.

## Existing Seeed enclosure

- Official case page:
  <https://wiki.seeedstudio.com/wio_sx1262_and_xiao_esp32s3_kit_with_3dprinted_enclosure_introduction_and_assembly_guide/>
- Published complete size: **22 × 23 × 57 mm**.
- That enclosure is for the external 195 mm SMA whip arrangement, so it was used
  only as a sanity check—not as the basis for this dual-FPC layout.
