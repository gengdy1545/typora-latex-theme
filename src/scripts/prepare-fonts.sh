#!/bin/sh

# Prepare the font files referenced by the generated theme CSS.
#
# portable: include every face required by the target platform. This is the
#           deterministic mode used by CI and release builds.
# auto:     local build only; omit a face when the current operating system
#           reports one of its exact names as already registered.

set -eu

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    echo "用法：$0 <windows|macos|linux> <目标 latex_fonts 目录> [portable|auto]" >&2
    exit 2
fi

platform=$1
destination=$2
mode=${3:-portable}

case "$platform" in
    windows|macos|linux) ;;
    *)
        echo "错误：不支持的目标平台：$platform" >&2
        exit 2
        ;;
esac

case "$mode" in
    portable|auto) ;;
    safe)
        echo "提示：字体模式 safe 已更名为 portable。" >&2
        mode=portable
        ;;
    *)
        echo "错误：字体模式必须是 portable 或 auto：$mode" >&2
        exit 2
        ;;
esac

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
src_dir=$(dirname "$script_dir")
font_root="$src_dir/../resources/fonts"
manifest="$font_root/manifest.json"

if [ ! -f "$manifest" ]; then
    echo "错误：未找到字体清单：$manifest" >&2
    echo "请先在项目根目录执行：" >&2
    echo "git submodule update --init --recursive --depth 1" >&2
    exit 1
fi

if ! command -v unzip >/dev/null 2>&1; then
    echo "错误：构建内置字体需要 unzip，请先安装后重试。" >&2
    exit 1
fi

# JSON::PP has shipped with Perl for many years and is available in macOS,
# mainstream Linux distributions, and Git for Windows. Keeping JSON parsing
# here makes manifest.json the sole build inventory.
if ! command -v perl >/dev/null 2>&1 || ! perl -MJSON::PP -e 'exit 0' >/dev/null 2>&1; then
    echo "错误：读取字体清单需要 Perl 及其核心模块 JSON::PP。" >&2
    exit 1
fi

host_platform=unknown
case "$(uname -s)" in
    Darwin) host_platform=macos ;;
    Linux) host_platform=linux ;;
    MINGW*|MSYS*|CYGWIN*) host_platform=windows ;;
esac

font_catalog=""
if [ "$mode" = "auto" ]; then
    if [ "$host_platform" != "$platform" ]; then
        echo "错误：auto 模式只能构建当前系统（当前 $host_platform，目标 $platform）。" >&2
        echo "构建跨平台或可移植安装包请使用 FONT_MODE=portable。" >&2
        exit 1
    fi

    # Test hook: a newline-delimited catalog makes exact face-selection logic
    # deterministic without mocking an operating system font service.
    if [ -n "${FONT_CATALOG_FILE:-}" ]; then
        if [ ! -f "$FONT_CATALOG_FILE" ]; then
            echo "错误：FONT_CATALOG_FILE 不存在：$FONT_CATALOG_FILE" >&2
            exit 1
        fi
        font_catalog=$(sed 's/\r$//' "$FONT_CATALOG_FILE")
    else
        case "$platform" in
            macos)
                # atsutil reports registered PostScript face names and is much
                # faster than system_profiler. AppKit is the fallback.
                if command -v atsutil >/dev/null 2>&1; then
                    font_catalog=$(atsutil fonts -list 2>/dev/null | awk '
                        /^System Fonts:$/ { reading = 1; next }
                        /^System Families:$/ { exit }
                        reading {
                            sub(/^[[:space:]]*/, "")
                            sub(/[[:space:]]*$/, "")
                            if ($0 != "") print
                        }
                    ' || true)
                elif command -v osascript >/dev/null 2>&1; then
                    font_catalog=$(osascript -l JavaScript -e '
                        ObjC.import("AppKit");
                        var manager = $.NSFontManager.sharedFontManager;
                        var output = [];
                        var fonts = manager.availableFonts;
                        var families = manager.availableFontFamilies;
                        for (var i = 0; i < fonts.count; i++)
                            output.push(ObjC.unwrap(fonts.objectAtIndex(i)));
                        for (var j = 0; j < families.count; j++)
                            output.push(ObjC.unwrap(families.objectAtIndex(j)));
                        output.sort().join("\n");
                    ' 2>/dev/null | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || true)
                fi
                ;;
            linux)
                if command -v fc-list >/dev/null 2>&1; then
                    font_catalog=$(fc-list -f '%{postscriptname}\n%{family}\n%{file}\n' 2>/dev/null | awk '
                        {
                            sub(/\r$/, "")
                            if ($0 ~ /^\//) {
                                count = split($0, path, "/")
                                name = path[count]
                                sub(/\.[^.]*$/, "", name)
                                if (name != "") print name
                                next
                            }
                            count = split($0, names, ",")
                            for (i = 1; i <= count; i++) {
                                sub(/^[[:space:]]*/, "", names[i])
                                sub(/[[:space:]]*$/, "", names[i])
                                if (names[i] != "") print names[i]
                            }
                        }
                    ' || true)
                fi
                ;;
            windows)
                if command -v powershell.exe >/dev/null 2>&1; then
                    font_catalog=$(powershell.exe -NoProfile -Command '
                        $paths = @(
                            "$env:WINDIR\Fonts",
                            "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
                        )
                        Get-ChildItem $paths -File -ErrorAction SilentlyContinue |
                            ForEach-Object { $_.BaseName }
                        $registryPaths = @(
                            "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts",
                            "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
                        )
                        foreach ($path in $registryPaths) {
                            if (Test-Path $path) {
                                (Get-ItemProperty $path).PSObject.Properties |
                                    Where-Object { $_.Name -notmatch "^PS" } |
                                    ForEach-Object { $_.Name -replace "\s+\(.*\)$", "" }
                            }
                        }
                        Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue
                        $collection = New-Object System.Drawing.Text.InstalledFontCollection
                        $collection.Families | ForEach-Object { $_.Name }
                    ' 2>/dev/null | tr -d '\r' || true)
                fi
                ;;
        esac
    fi
fi

font_is_installed() {
    [ "$mode" = "auto" ] || return 1
    [ -n "$font_catalog" ] || return 1

    printf '%s\n' "$font_catalog" | LC_ALL=C awk -v aliases="$1" '
        BEGIN { count = split(aliases, expected, ";") }
        {
            sub(/\r$/, "")
            for (i = 1; i <= count; i++) {
                if ($0 == expected[i]) found = 1
            }
        }
        END { exit(found ? 0 : 1) }
    '
}

staging="${destination}.tmp.$$"
rows="${destination}.manifest.$$"
cleanup() {
    rm -rf "$staging"
    rm -f "$rows"
}
trap cleanup 0 1 2 3 15

rm -rf "$staging"
mkdir -p "$staging"
mkdir -p "$(dirname "$rows")"

# Emit one tab-delimited row per active face. Validation here prevents a
# malformed manifest from writing outside latex_fonts.
if ! perl -MJSON::PP -0777 -e '
    use strict;
    use warnings;
    binmode STDOUT, ":encoding(UTF-8)";

    my $platform = shift @ARGV;
    my $data = decode_json(do { local $/; <STDIN> });
    die "unsupported font manifest schema\n"
        unless ($data->{schemaVersion} // 0) == 3;

    my %outputs;
    for my $package (@{$data->{packages} // []}) {
        my %platforms = map { $_ => 1 } @{$package->{platforms} // []};
        next unless $platforms{$platform};

        for my $face (@{$package->{faces} // []}) {
            my @detect = @{$face->{detect} // []};
            die "missing detection aliases for $package->{id}\n" unless @detect;

            my @fields = (
                $package->{archive},
                $face->{member},
                $face->{output},
                join(";", @detect),
                $package->{id}
            );
            for my $field (@fields) {
                die "invalid control character in manifest\n"
                    if !defined($field) || $field =~ /[\t\r\n]/;
            }
            die "duplicate font output: $face->{output}\n"
                if $outputs{$face->{output}}++;
            print join("\t", @fields), "\n";
        }
    }
' "$platform" < "$manifest" > "$rows"; then
    echo "错误：无法解析字体清单。" >&2
    exit 1
fi

is_safe_relative_path() {
    case "$1" in
        ""|/*|../*|*/../*|*/..) return 1 ;;
        *) return 0 ;;
    esac
}

selected_count=0
included_count=0
skipped_count=0
tab=$(printf '\t')

while IFS="$tab" read -r archive_rel member output aliases package_id
do
    [ -n "$archive_rel" ] || continue
    selected_count=$((selected_count + 1))

    if ! is_safe_relative_path "$archive_rel" ||
       ! is_safe_relative_path "$member" ||
       ! is_safe_relative_path "$output"; then
        echo "错误：字体清单包含不安全路径：$package_id" >&2
        exit 1
    fi

    case "$archive_rel" in
        *.zip) ;;
        *)
            echo "错误：字体归档不是 ZIP：$archive_rel" >&2
            exit 1
            ;;
    esac
    case "$output" in
        *.ttf|*.TTF|*.otf|*.OTF) ;;
        *)
            echo "错误：latex_fonts 只允许 TTF/OTF：$output" >&2
            exit 1
            ;;
    esac

    archive="$font_root/$archive_rel"
    if [ ! -f "$archive" ]; then
        echo "错误：未找到字体包：$archive" >&2
        echo "请先在项目根目录执行：" >&2
        echo "git submodule update --init --recursive --depth 1" >&2
        exit 1
    fi

    if font_is_installed "$aliases"; then
        echo "使用系统字体，跳过：${aliases%%;*}"
        skipped_count=$((skipped_count + 1))
        continue
    fi

    target="$staging/$output"
    mkdir -p "$(dirname "$target")"
    if ! unzip -p "$archive" "$member" > "$target" || [ ! -s "$target" ]; then
        echo "错误：无法从 $(basename "$archive") 提取 $member" >&2
        exit 1
    fi
    echo "加入主题字体：${aliases%%;*}"
    included_count=$((included_count + 1))
done < "$rows"

if [ "$selected_count" -eq 0 ]; then
    echo "错误：字体清单没有适用于 $platform 的字形。" >&2
    exit 1
fi

mkdir -p "$(dirname "$destination")"
rm -rf "$destination"
mv "$staging" "$destination"
rm -f "$rows"
trap - 0 1 2 3 15

echo "已准备 ${platform} 主题字体（模式：${mode}，加入：${included_count}，系统已有：${skipped_count}）：${destination}"
