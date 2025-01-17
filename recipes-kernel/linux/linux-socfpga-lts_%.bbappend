# Append GSRD SoCFPGA device tree source include files
# As this is custom to Intel SoCFPGA GSRD, hence it is not suitable to be upstreamed to meta-intel-fpga

FILESEXTRAPATHS:prepend := "${THISDIR}/linux-socfpga-lts:"

DEPENDS = "u-boot-mkimage-native dtc-native"

SRC_URI:append:agilex_fm61 = " file://fit_kernel_agilex_fm61.its"
SRC_URI:append:agilex_fm87 = " file://fit_kernel_agilex_fm87.its"
SRC_URI:append:agilex_fm86 = " file://fit_kernel_agilex_fm86.its"
SRC_URI:append:agilex5 = " file://fit_kernel_agilex5.its"
SRC_URI:append:stratix10 = " file://fit_kernel_stratix10.its"

SRC_URI:append:arria10 = " \
			${@bb.utils.contains("IMAGE_TYPE", "gsrd", "file://0001-socfpga_arria10_socdk-include-reference-design-dtsi.patch", "", d)} \
			${@bb.utils.contains("IMAGE_TYPE", "pr", "file://0001-dts-arm-enable-FPGA-PR-DTBs-for-Arria10.patch", "", d)} \
			${@bb.utils.contains("IMAGE_TYPE", "nand", "file://0001-socfpga_arria10_socdk-include-reference-design-dtsi.patch", "", d)} \
			${@bb.utils.contains("IMAGE_TYPE", "qspi", "file://0001-socfpga_arria10_socdk-include-reference-design-dtsi.patch", "", d)} \
			${@bb.utils.contains("IMAGE_TYPE", "pcie", "file://0001-socfpga_arria10_socdk-pcie-include-reference-design-.patch", "", d)} \
			${@bb.utils.contains("IMAGE_TYPE", "sgmii", "file://0001-socfpga_arria10_socdk-sgmii-include-reference-design.patch", "", d)} \
			${@bb.utils.contains("IMAGE_TYPE", "tse", "file://0001-socfpga_arria10_socdk-tse-include-reference-design-d.patch", "", d)} \
			"

SRC_URI:append:cyclone5 = " file://0001-socfpga_cyclone5_socdk-include-reference-design-dtsi.patch"

# Append GSRD specific kernel config fragments
SRC_URI:append = " file://ubifs.scc"
SRC_URI:append:agilex_fm61 = " file://sgmii.scc"
SRC_URI:append:agilex5 = " file://initrd.scc"
SRC_URI:append:stratix10 = " file://sgmii.scc"
SRC_URI:append:arria10 = " file://tse.scc"
SRC_URI:append:cyclone5 = " file://tse.scc"

inherit deploy

LINUXDEPLOYDIR = "${WORKDIR}/deploy-${PN}"
DTBDEPLOYDIR = "${DEPLOY_DIR_IMAGE}/devicetree"

do_deploy:append() {
	# Stage required binaries for kernel.itb
	# Supported device family:
	# 				-	Agilex FM61, FM87, FM86
	# 				-	Agilex5
	# 				-	Stratix10

	if [[ "${MACHINE}" == *"agilex_"* ]]; then
		# linux.dtb
		cp ${DTBDEPLOYDIR}/socfpga_agilex_socdk.dtb ${B}
		cp ${DTBDEPLOYDIR}/socfpga_agilex_vanilla.dtb ${B}
		if [[ "${MACHINE}" == "agilex_fm61" ]]; then
			cp ${DTBDEPLOYDIR}/socfpga_agilex_socdk_nand.dtb ${B}
			cp ${DTBDEPLOYDIR}/socfpga_agilex_socdk_pr.dtb ${B}
		fi
		# core.rbf
		cp ${DEPLOY_DIR_IMAGE}/${MACHINE}_${IMAGE_TYPE}_ghrd/ghrd.core.rbf ${B}
		if [[ "${MACHINE}" == "agilex_fm61" ]]; then
			cp ${DEPLOY_DIR_IMAGE}/${MACHINE}_${IMAGE_TYPE}_ghrd/nand.core.rbf ${B}
			cp ${DEPLOY_DIR_IMAGE}/${MACHINE}_${IMAGE_TYPE}_ghrd/ghrd_pr.core.rbf ${B}
		fi
	elif [[ "${MACHINE}" == "agilex5" ]]; then
		# linux.dtb
		cp ${LINUXDEPLOYDIR}/socfpga_${MACHINE}_socdk.dtb ${B}/socfpga_${MACHINE}_socdk.dtb
	elif [[ "${MACHINE}" == "stratix10" ]]; then
		# linux.dtb
		cp ${DTBDEPLOYDIR}/socfpga_stratix10_socdk.dtb ${B}
		cp ${DTBDEPLOYDIR}/socfpga_stratix10_vanilla.dtb ${B}
		cp ${DTBDEPLOYDIR}/socfpga_stratix10_socdk_nand.dtb ${B}
		# core.rbf
		cp ${DEPLOY_DIR_IMAGE}/${MACHINE}_${IMAGE_TYPE}_ghrd/ghrd.core.rbf ${B}
		cp ${DEPLOY_DIR_IMAGE}/${MACHINE}_${IMAGE_TYPE}_ghrd/nand.core.rbf ${B}
	fi

	# Generate and deploy kernel.itb
	if [[ "${MACHINE}" == *"agilex"* || "${MACHINE}" == "stratix10" ]]; then
		# kernel.its
		cp ${WORKDIR}/fit_kernel_${MACHINE}.its ${B}
		# Image
		cp ${LINUXDEPLOYDIR}/Image ${B}
		# Compress Image to lzma format
		xz --format=lzma ${B}/Image
		# Generate kernel.itb
		mkimage -f ${B}/fit_kernel_${MACHINE}.its ${B}/kernel.itb
		# Deploy kernel.its, kernel.itb and Image.lzma
		install -m 744 ${B}/fit_kernel_${MACHINE}.its ${DEPLOYDIR}
		install -m 744 ${B}/kernel.itb ${DEPLOYDIR}
		install -m 744 ${B}/Image.lzma ${DEPLOYDIR}
	fi
}

do_install:append() {
	if ${@bb.utils.contains("IMAGE_TYPE", "pr", "true", "false", d)} ; then
		install -D -m 0644 ${D}/boot/fpga_static_region.dtb ${D}/boot/fpga_static_region.dtbo
		install -D -m 0644 ${D}/boot/persona1.dtb ${D}/boot/persona1.dtbo
		install -D -m 0644 ${D}/boot/persona0.dtb ${D}/boot/persona0.dtbo
	fi
}
