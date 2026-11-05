#!/bin/sh

set -eu

license_plist_version="3.28.3"
license_plist_archive_sha256="dd3ca6c08981a1e0c4980d5bc857bbd40f17b8b4c7ca89ab8923396fd910a040"

script_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repository_root=$(CDPATH= cd -- "$script_directory/.." && pwd)
settings_bundle="$repository_root/Project/App/App/Resources/Settings.bundle"
generated_package_resolved="$repository_root/Project/App/App.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
workspace_package_resolved="$repository_root/CCRecorder.xcworkspace/xcshareddata/swiftpm/Package.resolved"
tracked_package_resolved="$repository_root/.package.resolved"
tool_directory="$repository_root/Derived/Tools/LicensePlist/$license_plist_version"
license_plist="$tool_directory/license-plist"
result_cache_directory="$repository_root/Derived/LicensePlist"
result_file_name="com.mono0926.LicensePlist.latest_result.txt"
result_cache="$result_cache_directory/$result_file_name"

if [ -f "$tracked_package_resolved" ]; then
    package_resolved="$tracked_package_resolved"
elif [ -f "$generated_package_resolved" ]; then
    package_resolved="$generated_package_resolved"
elif [ -f "$workspace_package_resolved" ]; then
    package_resolved="$workspace_package_resolved"
else
    echo "error: Package.resolved를 찾을 수 없습니다. 먼저 tuist generate를 실행하세요." >&2
    exit 1
fi

if [ ! -x "$license_plist" ]; then
    license_plist_download_directory=$(mktemp -d "${TMPDIR:-/tmp}/ccrecorder-license-plist.XXXXXX")
    trap 'rm -rf -- "$license_plist_download_directory"' EXIT

    archive="$license_plist_download_directory/portable_licenseplist.zip"
    curl \
        --fail \
        --location \
        --retry 3 \
        --silent \
        --show-error \
        "https://github.com/mono0926/LicensePlist/releases/download/$license_plist_version/portable_licenseplist.zip" \
        --output "$archive"

    actual_sha256=$(shasum -a 256 "$archive" | awk '{ print $1 }')
    if [ "$actual_sha256" != "$license_plist_archive_sha256" ]; then
        echo "error: LicensePlist 아카이브 체크섬이 일치하지 않습니다." >&2
        exit 1
    fi

    mkdir -p "$tool_directory"
    unzip -q "$archive" license-plist -d "$tool_directory"
    chmod +x "$license_plist"
    rm -rf -- "$license_plist_download_directory"
    trap - EXIT
fi

mkdir -p "$settings_bundle" "$result_cache_directory"

generated_licenses_directory=$(mktemp -d "${TMPDIR:-/tmp}/ccrecorder-generated-licenses.XXXXXX")
trap 'rm -rf -- "$generated_licenses_directory"' EXIT

license_plist_package_resolved="$package_resolved"
if [ "$package_resolved" = "$tracked_package_resolved" ]; then
    license_plist_package_resolved="$generated_licenses_directory/Package.resolved"
    cp "$package_resolved" "$license_plist_package_resolved"
fi

if [ -f "$result_cache" ]; then
    cp "$result_cache" "$generated_licenses_directory/$result_file_name"
fi

generate_license_plists() {
    (
        cd "$script_directory"
        "$license_plist" \
            --package-path "$license_plist_package_resolved" \
            --output-path "$generated_licenses_directory" \
            --suppress-opening-directory \
            --fail-if-missing-license \
            --silence-mode \
            --no-color \
            "$@"
    )
}

generate_license_plists

dependency_count=$(plutil -extract pins raw "$package_resolved")
license_count=0
if [ -d "$generated_licenses_directory/com.mono0926.LicensePlist" ]; then
    license_count=$(find "$generated_licenses_directory/com.mono0926.LicensePlist" -type f -name '*.plist' | wc -l | tr -d ' ')
fi

if [ "$license_count" = "0" ]; then
    existing_license_count=0
    if [ -d "$settings_bundle/com.mono0926.LicensePlist" ]; then
        existing_license_count=$(find "$settings_bundle/com.mono0926.LicensePlist" -type f -name '*.plist' | wc -l | tr -d ' ')
    fi
    if [ "$dependency_count" = "$existing_license_count" ] && [ -f "$settings_bundle/com.mono0926.LicensePlist.plist" ]; then
        if [ -f "$generated_licenses_directory/$result_file_name" ]; then
            mv "$generated_licenses_directory/$result_file_name" "$result_cache"
        fi
        echo "LicensePlist $license_plist_version: 라이선스 ${existing_license_count}개가 최신 상태입니다"
        exit 0
    fi

    generate_license_plists --force
    license_count=$(find "$generated_licenses_directory/com.mono0926.LicensePlist" -type f -name '*.plist' | wc -l | tr -d ' ')
fi

if [ -f "$generated_licenses_directory/$result_file_name" ]; then
    mv "$generated_licenses_directory/$result_file_name" "$result_cache"
fi

if [ "$dependency_count" != "$license_count" ]; then
    echo "error: 의존성 ${dependency_count}개와 생성된 라이선스 ${license_count}개의 수가 일치하지 않습니다." >&2
    exit 1
fi

rm -rf -- "$settings_bundle/com.mono0926.LicensePlist"
rm -f -- "$settings_bundle/com.mono0926.LicensePlist.plist"
mv "$generated_licenses_directory/com.mono0926.LicensePlist" "$settings_bundle/"
mv "$generated_licenses_directory/com.mono0926.LicensePlist.plist" "$settings_bundle/"

echo "LicensePlist $license_plist_version: 라이선스 ${license_count}개 생성 완료"
