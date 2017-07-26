# dds-synth
Direct digital synthesizer (DDS) with ATmega8515, Xilinx XC9572 CPLD and SDA5708-24B display

## The board
![The board](images/dds-board.jpg)

## ATmega8515
ATmega8515 polls two buttons to increase/decrease frequency status word, computes
resulting frequency and prints it on the display.

## XC9572 CPLD
The Xilinx CPLD implements a 16-bit phase accumulator using frequency status word
provided by the ATmega8515.
It also includes a state machine for proper timings accessing EPROM (27C210-15) and
latching samples for 16-bit DAC.

## 16-bit R-2R DAC
![16-bit R-2R DAC](/images/dds-board-dac.jpg)

## SDA5708-24B display
![SDA5708-24B display](/images/dds-board-display.jpg)
