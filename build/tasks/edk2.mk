#
# Copyright (C) 2024 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

ifneq ($(TARGET_TEGRA_VERSION),)
TARGET_KERNEL_CLANG_PATH ?= $(BUILD_TOP)/prebuilts/clang/host/$(HOST_PREBUILT_TAG)/$(LLVM_PREBUILTS_VERSION)

BUILD_TOOLS_PATH   := $(BUILD_TOP)/prebuilts/build-tools/$(HOST_PREBUILT_TAG)
LINEAGE_TOOLS_PATH := $(BUILD_TOP)/prebuilts/tools-lineage/$(HOST_PREBUILT_TAG)
TOS_PATH       	   := $(BUILD_TOP)/device/nvidia/tegra-common/tos
SCRIPTS_PATH       := $(BUILD_TOP)/device/nvidia/tegra-common/flash_package

DTC_HOST           := $(HOST_OUT_EXECUTABLES)/dtc

BROTLI_PATH        := $(BUILD_TOP)/external/brotli
TIANOCORE_PATH     := $(BUILD_TOP)/bootable/tianocore

EDK2_PKCS7_INC     ?= $(BUILD_TOP)/bootable/tianocore/edk2/BaseTools/Source/Python/Pkcs7Sign/TestRoot.cer.gFmpDevicePkgTokenSpaceGuid.PcdFmpDevicePkcs7CertBufferXdr.inc

EDK2_BUILD_TYPE    := RELEASE
EDK2_TOOLCHAIN     := GCC5
EDK2_ARCH          := AARCH64
EDK2_TARGET        := JetsonAndroid

TOOLCHAIN_VARS := CLANG_HOST_BIN=$(abspath $(dir $(KERNEL_MAKE_CMD)))/ CC=$(TARGET_KERNEL_CLANG_PATH)/bin/clang CXX=$(TARGET_KERNEL_CLANG_PATH)/bin/clang++ AS=$(TARGET_KERNEL_CLANG_PATH)/bin/clang AR=$(TARGET_KERNEL_CLANG_PATH)/bin/llvm-ar LD=$(TARGET_KERNEL_CLANG_PATH)/bin/llvm-ld CLANG_BIN=$(TARGET_KERNEL_CLANG_PATH)/bin/ GCC_HOST_BIN=$(abspath $(dir $(KERNEL_MAKE_CMD)))/ GCC5_$(EDK2_ARCH)_PREFIX=$(KERNEL_TOOLCHAIN)/$(KERNEL_TOOLCHAIN_PREFIX) DTCPP_PREFIX=$(KERNEL_TOOLCHAIN)/$(KERNEL_TOOLCHAIN_PREFIX)

# 1: Intermediates dir
# 2: Target base filename
# 3: Optional build paramters
define edk2_rule
$(1): $(DTC_HOST)
	@mkdir -p $(dir $1)
	@cp -R $(TIANOCORE_PATH)/edk2 $(dir $1)/
	@cp -R $(TIANOCORE_PATH)/edk2-non-osi $(dir $1)/
	@cp -R $(TIANOCORE_PATH)/edk2-platforms $(dir $1)/
	@cp -R $(TIANOCORE_PATH)/edk2-nvidia $(dir $1)/
	@cp -R $(TIANOCORE_PATH)/edk2-nvidia-non-osi $(dir $1)/
	@cp -R $(TIANOCORE_PATH)/edk2-nvidia-lineage $(dir $1)/
	@cp -R $(BROTLI_PATH)/* $(dir $1)/edk2/BaseTools/Source/C/BrotliCompress/brotli/
	@cp -R $(BROTLI_PATH)/* $(dir $1)/edk2/MdeModulePkg/Library/BrotliCustomDecompressLib/brotli/
	@export PYTHON_COMMAND=$(BUILD_TOOLS_PATH)/python3 && \
		export WORKSPACE=$(abspath $(dir $1)) && \
		export PACKAGES_PATH=$(abspath $(dir $1))/edk2-nvidia:$(abspath $(dir $1))/edk2:$(abspath $(dir $1))/edk2-non-osi:$(abspath $(dir $1))/edk2-platforms:$(abspath $(dir $1))/edk2-nvidia-non-osi:$(abspath $(dir $1))/edk2-nvidia-lineage:$(abspath $(dir $1))/edk2-platforms/Features/Intel/OutOfBandManagement && \
		export IASL_PREFIX=$(LINEAGE_TOOLS_PATH)/bin/ && \
		export DTC_PREFIX=$(abspath $(dir $(DTC_HOST)))/ && \
		export $(TOOLCHAIN_VARS) && \
		source $(abspath $(dir $1))/edk2/edksetup.sh && \
		$(KERNEL_MAKE_CMD) -C $(abspath $(dir $1))/edk2/BaseTools && \
		PYTHONPATH=$$$$PYTHONPATH:$(abspath $(dir $1))/edk2-nvidia-lineage/Silicon/NVIDIA/scripts/Kconfiglib \
			KCONFIG_CONFIG=$(abspath $(dir $1))/edk2-nvidia-lineage/.config \
			$(abspath $(dir $1))/edk2-nvidia-lineage/Silicon/NVIDIA/scripts/Kconfiglib/defconfig.py \
			--kconfig $(abspath $(dir $1))/edk2-nvidia/Platform/NVIDIA/Kconfig \
			$(abspath $(dir $1))/edk2-nvidia-lineage/Platform/NVIDIA/$(EDK2_TARGET)/$(EDK2_TARGET).defconfig && \
		sed 's/"//g' $(abspath $(dir $1))/edk2-nvidia-lineage/.config > $(abspath $(dir $1))/edk2-nvidia-lineage/config.dsc.inc && \
		sed -E -i 's/^CONFIG_([^=]*)=$$$$/# CONFIG_\1 is not set/' $(abspath $(dir $1))/edk2-nvidia-lineage/config.dsc.inc && \
		$(abspath $(dir $1))/edk2/BaseTools/BinWrappers/PosixLike/build -q -a $(EDK2_ARCH) -t $(EDK2_TOOLCHAIN) \
			-p $(abspath $(dir $1))/edk2-nvidia-lineage/Platform/NVIDIA/$(EDK2_TARGET)/$(EDK2_TARGET).dsc -b $(EDK2_BUILD_TYPE) \
			$3 -DEDK2_PKCS7_INC=$(EDK2_PKCS7_INC) -DBUILD_PROJECT_TYPE=EDK2 -DBUILD_DATE_TIME="$(shell date '+%Y-%m-%dT%H:%M:%S+00:00')" \
			-DBUILDID_STRING="$(shell BUILD_TOP=$(abspath $(TIANOCORE_PATH)/../..) python $(SCRIPTS_PATH)/get_branch_name.py)-$(shell git -C $(TIANOCORE_PATH)/edk2-nvidia-lineage rev-parse --short HEAD)"
	@python $(dir $1)/edk2-nvidia/Silicon/NVIDIA/edk2nv/FormatUefiBinary.py $(dir $1)/Build/$(EDK2_TARGET)/$(EDK2_BUILD_TYPE)_$(EDK2_TOOLCHAIN)/FV/UEFI_NS.Fv $1

$(PRODUCT_OUT)/$(2).bin: $(1)
	$(hide) cp $(1) $(PRODUCT_OUT)/$(2).bin

.PHONY: $(2)
$(2): $(PRODUCT_OUT)/$(2).bin
endef

$(eval $(call edk2_rule,$(call intermediates-dir-for,EXECUTABLES,tianocore)/tianocore.bin,tianocore))

TIANOCORE_DTBO_TARGETS := \
    AndroidConfiguration.dtbo
INSTALLED_TIANOCORE_DTBO_TARGETS := $(TIANOCORE_DTBO_TARGETS:%=$(PRODUCT_OUT)/%)
$(INSTALLED_TIANOCORE_DTBO_TARGETS): $(PRODUCT_OUT)/tianocore.bin
	echo -e ${CL_GRN}"Copying individual tianocore DTBOs"${CL_RST}
	cp $(@F:%.dtbo=$(call intermediates-dir-for,EXECUTABLES,tianocore)/Build/$(EDK2_TARGET)/$(EDK2_BUILD_TYPE)_$(EDK2_TOOLCHAIN)/$(EDK2_ARCH)/Silicon/NVIDIA/Tegra/DeviceTree/DeviceTree/OUTPUT/%.dtb) $@
endif
