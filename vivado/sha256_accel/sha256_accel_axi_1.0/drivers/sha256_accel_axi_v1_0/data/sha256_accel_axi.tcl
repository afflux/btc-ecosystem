

proc generate {drv_handle} {
	xdefine_include_file $drv_handle "xparameters.h" "sha256_accel_axi" "NUM_INSTANCES" "DEVICE_ID"  "C_SHA256_ACCEL_AXI_BASEADDR" "C_SHA256_ACCEL_AXI_HIGHADDR"
}
