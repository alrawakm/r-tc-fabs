create_clock -name clk -period 12.500 [get_ports {clk}]
derive_clock_uncertainty
set_false_path -from [get_ports {reset_n}]
