# Constraints

## ASIC

* **Process:** IHP CMOS5L 130 nm via Tiny Tapeout
* **Tile allocation:** `6 × 4` tiles = **24 tiles**
* **Tile size:** ~`200 × 150 µm`
* **Nominal area:** ~`0.7 mm²`
* **Rough budget:** ~`1k logic cells/tile` → ~`24k cells`
* **Submission:** CMOS5L Verilog template → RTL → GDS
* **Timing:** Must meet timing after place-and-route
* **Routing:** Must leave area for clock-tree buffers and routing
* **Memory:** SRAM is recommended for instruction memory where practical

## Functionality

* General-purpose, **reprogrammable protocol emulator**
* Implement protocols primarily in **firmware**, not dedicated protocol blocks
* Must support precise:

  * GPIO reads
  * GPIO writes
  * Cycle counting / delays
  * Program control flow
* Initial target protocols:

  * UART
  * SPI
  * I2C
* Potential stretch goals:

  * USB (low speed)
  * 10 Mbit Ethernet
  * JTAG
  * SWD
  * PS/2
  * CAN

## Submission

* **Open source**
* **Deadline:** January 18, 2027
