#!/bin/sh

# This file is copied into each macOS/Linux release directory.

set -u

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if [ "$(uname -s)" = "Linux" ]; then
    theme_dir="$HOME/.config/Typora/themes"
elif [ "$(uname -s)" = "Darwin" ]; then
    theme_dir="$HOME/Library/Application Support/abnerworks.Typora/themes"
else
    echo "暂不支持当前操作系统：$(uname -s)" >&2
    exit 1
fi

echo "正在寻找 Typora 主题文件夹：$theme_dir"
if [ ! -d "$theme_dir" ]; then
    echo "未找到该文件夹，请先安装并运行一次 Typora。" >&2
    exit 2
fi

if ! cp -f "$script_dir"/target/*.css "$theme_dir/"; then
    echo "主题 CSS 安装失败。" >&2
    exit 3
fi

font_source="$script_dir/target/latex_fonts"
font_destination="$theme_dir/latex_fonts"
if [ ! -d "$font_source" ]; then
    echo "安装包不完整：缺少 target/latex_fonts。" >&2
    exit 3
fi

# Only replace directories managed by the current theme. Very old releases
# used unrelated flat filenames; those are intentionally not encoded here as
# permanent compatibility cleanup.
if ! mkdir -p "$font_destination"; then
    echo "主题字体安装失败。" >&2
    exit 3
fi

for managed_dir in latin-modern noto-cjk-sc family-song fzdoc macos windows
do
    if ! rm -rf "$font_destination/$managed_dir"; then
        echo "主题字体安装失败。" >&2
        exit 3
    fi
done

if ! cp -R "$font_source"/. "$font_destination/"; then
    echo "主题字体安装失败。" >&2
    exit 3
fi

echo "安装成功。字体仅保存在 Typora 主题目录，不会安装到操作系统。"
