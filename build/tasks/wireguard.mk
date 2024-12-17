#
# Copyright (C) 2020-2024 The LineageOS Project
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
ifeq ($(TARGET_PREBUILT_KERNEL),)
WIREGUARD_PATH := $(BUILD_TOP)/kernel/nvidia/wireguard
KERNEL_OUT := $(TARGET_OUT_INTERMEDIATES)/KERNEL_OBJ
KERNEL_OUT_RELATIVE := ../../KERNEL_OBJ

_wireguard_ko := $(call intermediates-dir-for,ETC,wireguard)/wireguard.ko

$(_wireguard_ko): $(KERNEL_OUT)/arch/$(KERNEL_ARCH)/boot/$(BOARD_KERNEL_IMAGE_NAME) $(TARGET_OUT_VENDOR)/etc/init/wireguard.rc
	@mkdir -p $(dir $@)
	@cp -R $(WIREGUARD_PATH)/src/* $(_wireguard_intermediates)/
	$(hide) +$(KERNEL_MAKE_CMD) $(PATH_OVERRIDE) $(KERNEL_MAKE_FLAGS) -C $(_wireguard_intermediates) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) KERNELDIR=$(KERNEL_OUT_RELATIVE) module
	$(KERNEL_TOOLCHAIN_PATH)strip --strip-unneeded $@;

$(TARGET_OUT_VENDOR)/lib/modules/wireguard.ko: $(_wireguard_ko) $(TARGET_OUT_VENDOR)/etc/init/wireguard.rc
	$(hide) cp $< $@

.PHONY: wireguard
wireguard: $(TARGET_OUT_VENDOR)/lib/modules/wireguard.ko
endif
endif
