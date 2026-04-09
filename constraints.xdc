# ============================================================
# Timing Constraints - EMG Gesture Recognition System
# Author: Student Project - Edge AI Hackathon
# Target Board: Arty A7-35T (xc7a35ticsg324-1L)
# Clock: 50 MHz (20ns period) for timing closure
# ============================================================

# System Clock - 50 MHz
# Note: We use 50 MHz instead of 100 MHz to ensure timing closure
# 50 MHz is more than enough for real-time EMG processing (we only need ~100 Hz output)
create_clock -period 20.000 -name sys_clk_pin -waveform {0.000 10.000} -add [get_ports clk]

# Input delay for ADC data signals
set_input_delay -clock [get_clocks sys_clk_pin] -min 0.5 [get_ports {adc_ch* adc_data_valid}]
set_input_delay -clock [get_clocks sys_clk_pin] -max 4.0 [get_ports {adc_ch* adc_data_valid}]

# Output delay for gesture class output
set_output_delay -clock [get_clocks sys_clk_pin] -min 0.5 [get_ports {gesture_class* gesture_valid}]
set_output_delay -clock [get_clocks sys_clk_pin] -max 4.0 [get_ports {gesture_class* gesture_valid}]

# Status outputs - not timing critical
set_output_delay -clock [get_clocks sys_clk_pin] -max 5.0 [get_ports {preprocessing_active inference_active}]

# Reset is asynchronous - false path
set_false_path -from [get_ports rst_n]

# Debug outputs are not timing critical
set_false_path -to [get_ports {latency_cycles*}]
set_false_path -to [get_ports {system_state*}]

# Clock uncertainty
set_clock_uncertainty -setup 0.200 [get_clocks sys_clk_pin]
set_clock_uncertainty -hold  0.100 [get_clocks sys_clk_pin]
