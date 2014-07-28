# Top Level Design Parameters

# Clocks

create_clock -name {GPStoSPIPacker|FPGA_clock} -period 40.000000 -waveform {0.000000 5.000000} FPGA_clock
create_clock -name {GPStoSPIPacker|MAX_clockout} -period 125.000000 -waveform {0.000000 5.000000} MAX_clockout
create_clock -name {GPStoSPIPacker|SPI1_SCK} -period 20.000000 -waveform {0.000000 5.000000} SPI1_SCK

# False Paths Between Clocks


# False Path Constraints


# Maximum Delay Constraints


# Multicycle Constraints


# Virtual Clocks
# Output Load Constraints
# Driving Cell Constraints
# Wire Loads
# set_wire_load_mode top

# Other Constraints
