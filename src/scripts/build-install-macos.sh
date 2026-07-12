#!/bin/sh

# Build the macOS theme from SCSS, then install it into Typora.

set -u

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
src_dir=$(dirname "$script_dir")

show_sass_help() {
    cat <<'EOF'
未能安装 Sass，请手动安装后重新运行本脚本。

Sass 官方安装说明：
https://sass-lang.com/install/

Homebrew 的 Dart Sass 页面：
https://formulae.brew.sh/formula/dart-sass

推荐安装命令：
brew install dart-sass
EOF
}

usable_sass() {
    [ -n "$1" ] && "$1" --version >/dev/null 2>&1
}

find_sass() {
    if command -v dart-sass >/dev/null 2>&1; then
        candidate=$(command -v dart-sass)
        if usable_sass "$candidate"; then
            echo "$candidate"
            return 0
        fi
    fi

    if command -v sass >/dev/null 2>&1; then
        candidate=$(command -v sass)
        if usable_sass "$candidate"; then
            echo "$candidate"
            return 0
        fi
    fi

    return 1
}

if [ "$(uname -s)" != "Darwin" ]; then
    echo "错误：此脚本仅支持 macOS。" >&2
    exit 1
fi

if ! command -v make >/dev/null 2>&1; then
    echo "错误：未找到 make。请先运行 xcode-select --install 安装命令行工具。" >&2
    exit 1
fi

sass_bin=$(find_sass || true)

if [ -z "$sass_bin" ]; then
    echo "未检测到 Sass。"

    if ! command -v brew >/dev/null 2>&1; then
        echo "同时未检测到 Homebrew，无法自动安装 Sass。" >&2
        show_sass_help >&2
        exit 1
    fi

    if [ -t 0 ]; then
        printf "是否现在使用 Homebrew 安装 Dart Sass？[Y/n] "
        read -r answer
        case "$answer" in
            n|N|no|NO|No)
                show_sass_help
                exit 1
                ;;
        esac
    else
        echo "当前不是交互式终端，跳过自动安装。" >&2
        show_sass_help >&2
        exit 1
    fi

    echo "正在通过 Homebrew 安装预编译的 Dart Sass……"
    echo "提示：Homebrew 可能会先自动更新，期间输出较多内容属于正常现象。"
    if ! brew install dart-sass; then
        echo "Homebrew 安装 Dart Sass 失败；常见原因包括网络、代理或 Homebrew 配置问题。" >&2
        show_sass_help >&2
        exit 1
    fi

    # Refresh the shell command cache before looking for the newly installed binary.
    hash -r 2>/dev/null || true
    sass_bin=$(find_sass || true)
    if [ -z "$sass_bin" ]; then
        echo "安装命令已结束，但仍然无法找到 Sass。" >&2
        show_sass_help >&2
        exit 1
    fi
fi

echo "使用 Sass：$sass_bin"
echo "正在编译 macOS 主题……"
echo "将检测本机已安装字体，仅把缺失字形放入 target/latex_fonts。"

font_manifest="$src_dir/../resources/fonts/manifest.json"
if [ ! -f "$font_manifest" ]; then
    echo "错误：未找到字体子模块清单。请先在项目根目录执行：" >&2
    echo "git submodule update --init --recursive --depth 1" >&2
    exit 1
fi

if ! make -C "$src_dir" SASS="$sass_bin" FONT_MODE=auto macos; then
    echo "主题编译失败，请检查上方错误信息。" >&2
    exit 1
fi

installer="$src_dir/latex-theme/macos-typora/install.sh"
if [ ! -f "$installer" ]; then
    echo "编译完成，但未找到安装脚本：$installer" >&2
    exit 1
fi

echo "编译成功，正在安装到 Typora……"
if ! sh "$installer"; then
    echo "主题安装失败，请检查 Typora 是否已正确安装。" >&2
    exit 1
fi

echo "全部完成。请完全退出并重新打开 Typora，然后选择 Latex 或 Latex Dark 主题。"
