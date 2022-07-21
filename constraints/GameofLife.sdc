create_clock -name clk_in -period 41.67 -waveform {0 20.835} [get_ports {clk_in}]
derive_pll_clocks -gen_basic_clock
