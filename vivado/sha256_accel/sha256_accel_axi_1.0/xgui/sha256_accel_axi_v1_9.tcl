# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
	set Page0 [ipgui::add_page $IPINST -name "Page 0" -layout vertical]
	set Component_Name [ipgui::add_param $IPINST -parent $Page0 -name Component_Name]
	set C_SHA256_ACCEL_AXI_BASEADDR [ipgui::add_param $IPINST -parent $Page0 -name C_SHA256_ACCEL_AXI_BASEADDR]
	set C_SHA256_ACCEL_AXI_HIGHADDR [ipgui::add_param $IPINST -parent $Page0 -name C_SHA256_ACCEL_AXI_HIGHADDR]
}

proc update_PARAM_VALUE.C_SHA256_ACCEL_AXI_BASEADDR { PARAM_VALUE.C_SHA256_ACCEL_AXI_BASEADDR } {
	# Procedure called to update C_SHA256_ACCEL_AXI_BASEADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_SHA256_ACCEL_AXI_BASEADDR { PARAM_VALUE.C_SHA256_ACCEL_AXI_BASEADDR } {
	# Procedure called to validate C_SHA256_ACCEL_AXI_BASEADDR
	return true
}

proc update_PARAM_VALUE.C_SHA256_ACCEL_AXI_HIGHADDR { PARAM_VALUE.C_SHA256_ACCEL_AXI_HIGHADDR } {
	# Procedure called to update C_SHA256_ACCEL_AXI_HIGHADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_SHA256_ACCEL_AXI_HIGHADDR { PARAM_VALUE.C_SHA256_ACCEL_AXI_HIGHADDR } {
	# Procedure called to validate C_SHA256_ACCEL_AXI_HIGHADDR
	return true
}


