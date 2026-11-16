project_open skip
create_timing_netlist
read_sdc skip75.sdc
update_timing_netlist
foreach_in_collection corner [get_available_operating_conditions] {
    set_operating_conditions $corner
    update_timing_netlist
    report_timing -setup -npaths 1 -detail summary -file "timing75_${corner}_setup.txt"
    report_timing -hold -npaths 1 -detail summary -file "timing75_${corner}_hold.txt"
}
delete_timing_netlist
project_close
