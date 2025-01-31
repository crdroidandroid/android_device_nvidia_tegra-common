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

LF_BCM_PATH := kernel/nvidia/linux-firmware/

PRODUCT_COPY_FILES += \
    $(LF_BCM_PATH)/rtl_bt/rtl8761bu_config.bin:$(TARGET_COPY_OUT_VENDOR)/firmware/rtl_bt/rtl8822cu_config.bin \
    $(LF_BCM_PATH)/rtl_bt/rtl8822cu_fw.bin:$(TARGET_COPY_OUT_VENDOR)/firmware/rtl_bt/rtl8822cu_fw.bin \
    $(LF_BCM_PATH)/rtw88/rtw8822c_fw.bin:$(TARGET_COPY_OUT_VENDOR)/firmware/rtw88/rtw8822c_fw.bin \
    $(LF_BCM_PATH)/rtw88/rtw8822c_wow_fw.bin:$(TARGET_COPY_OUT_VENDOR)/firmware/rtw88/rtw8822c_wow_fw.bin
