#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2020 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2020 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=opkona
VENDOR=oneplus

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to not sanitizing the vendor folder before extraction
CLEAN_VENDOR=false

# Proprietary files list
DEVICE_NAME="Common"

KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -c | --cleanup )
                CLEAN_VENDOR=true
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        -d | --device )
                DEVICE_NAME="${2}"; shift
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in
        odm/bin/hw/vendor.oplus.hardware.biometrics.fingerprint@2.1-service)
            "${PATCHELF}" --add-needed libshims_fingerprint.oplus.so "${2}"
            ;;
        odm/etc/init/wlchgmonitor.rc)
            sed -i "/disabled/d;/seclabel/d" "${2}"
            ;;
        odm/etc/vintf/manifest/manifest_oplus_fingerprint.xml)
            sed -ni "/android.hardware.biometrics.fingerprint/{x;s/hal format/hal override=\"true\" format/;x};x;1!p;\${x;p}" "${2}"
            ;;
        odm/lib64/libpwirissoft.so)
            "${SIGSCAN}" -p "72 1F 00 94" -P "1F 20 03 D5" -f "${2}"
            ;;
        product/etc/sysconfig/com.android.hotwordenrollment.common.util.xml)
            sed -i "s/\/my_product/\/product/" "${2}"
            ;;
        system_ext/lib64/libwfdnative.so)
            sed -i "s/android.hidl.base@1.0.so/libhidlbase.so\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00/" "${2}"
            ;;
        vendor/lib64/hw/com.qti.chi.override.so)
            grep -q libcamera_metadata_shim.so "${2}" || "${PATCHELF}" --add-needed libcamera_metadata_shim_opkona.so "${2}"
            sed -i "s/com.oem.autotest/\x00om.oem.autotest/" "${2}"
            ;;
        vendor/lib64/vendor.qti.hardware.camera.postproc@1.0-service-impl.so)
            "${SIGSCAN}" -p "1F 0A 00 94" -P "1F 20 03 D5" -f "${2}"
            ;;
    esac
}

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

if [ "${DEVICE_NAME}" = "Common" ]; then
    extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"
elif [ "${DEVICE_NAME}" = "instantnoodle" ]; then
    extract "${MY_DIR}/proprietary-files-instantnoodle.txt" "${SRC}" "${KANG}" --section "${SECTION}"
elif [ "${DEVICE_NAME}" = "instantnoodlep" ]; then
    extract "${MY_DIR}/proprietary-files-instantnoodlep.txt" "${SRC}" "${KANG}" --section "${SECTION}"
fi

"${MY_DIR}/setup-makefiles.sh"
