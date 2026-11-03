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

if [ -f "$generated_package_resolved" ]; then
    package_resolved="$generated_package_resolved"
elif [ -f "$workspace_package_resolved" ]; then
    package_resolved="$workspace_package_resolved"
elif [ -f "$tracked_package_resolved" ]; then
    package_resolved="$tracked_package_resolved"
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
fi

mkdir -p "$settings_bundle" "$result_cache_directory"

if [ -f "$result_cache" ]; then
    cp "$result_cache" "$settings_bundle/$result_file_name"
fi

(
    cd "$script_directory"
    "$license_plist" \
        --package-path "$package_resolved" \
        --output-path "$settings_bundle" \
        --suppress-opening-directory \
        --fail-if-missing-license \
        --silence-mode \
        --no-color
)

if [ -f "$settings_bundle/$result_file_name" ]; then
    mv "$settings_bundle/$result_file_name" "$result_cache"
fi

dependency_count=$(plutil -extract pins raw "$package_resolved")
license_count=$(find "$settings_bundle/com.mono0926.LicensePlist" -type f -name '*.plist' | wc -l | tr -d ' ')

if [ "$dependency_count" != "$license_count" ]; then
    echo "error: 의존성 ${dependency_count}개 중 라이선스 ${license_count}개만 생성되었습니다." >&2
    exit 1
fi

echo "LicensePlist $license_plist_version: 라이선스 ${license_count}개 생성 완료"
