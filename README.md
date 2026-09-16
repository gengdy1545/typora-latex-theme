# Typora LaTeX Theme 自用版

这是基于 [Keldos-Li/typora-latex-theme](https://github.com/Keldos-Li/typora-latex-theme) 修改的自用版本。原项目的主题介绍、排版效果与使用场景请直接查看上游仓库；本 README 只说明当前版本的改动和安装方式。

## 本版本的改进

- 优化 Typora 的屏幕阅读体验，并保持打印、导出时的论文排版尺寸。
- 重做代码块与语法高亮，完善浅色、深色主题下的可读性。
- 完善 Mermaid 图表样式，覆盖流程图、时序图、类图、状态图、ER 图、饼图、甘特图、Git 图、思维导图、时间线、Sankey 等常见类型。
- 支持 Typora/GitHub 风格的 `NOTE`、`TIP`、`IMPORTANT`、`WARNING`、`CAUTION` 提示块。
- 发布包按 Windows、macOS、Linux 分平台构建，内置主题所需字体，并在发布前自动校验字体完整性。
- 安装脚本会同时部署主题 CSS 和字体资源，无需再逐个下载、安装系统字体。
- 提供 [Obsidian CSS Snippet](obsidian/README.md)，将相同的学术排版风格用于 Obsidian Markdown 内容，并支持 `#pic_left`、`#pic_center`、`#pic_right` 图片对齐语法。

## 下载与安装

### 1. 下载对应平台的发布包

请先安装并至少运行一次 [Typora](https://typora.io/)，然后前往[本项目 Releases](https://github.com/gengdy1545/typora-latex-theme/releases)下载最新版本：

| 操作系统 | 发布包 |
| --- | --- |
| Windows | `latex-theme-windows.zip` |
| macOS | `latex-theme-macos.zip` |
| Linux | `latex-theme-linux.zip` |

解压发布包后，可以选择自动安装或手动安装。

### 2. 自动安装

- **Windows**：右键单击 `install.ps1`，选择“使用 PowerShell 运行”。如果系统拦截脚本，请先确认文件来自本项目，再允许本次执行。
- **macOS**：打开“终端”，将 `install.sh` 拖入终端窗口，然后按回车执行。
- **Linux**：在解压后的目录中执行 `sh ./install.sh`。

脚本会把 `latex.css`、`latex-dark.css` 和 `latex_fonts` 一并复制到 Typora 主题目录。完成后请完全退出并重新打开 Typora，在“主题”菜单中选择 `Latex` 或 `Latex Dark`。

### 3. 手动安装

按照 [Typora 官方主题安装说明](https://theme.typora.io/doc/Install-Theme/)打开主题文件夹，将以下内容全部复制进去：

```text
target/
├── latex.css
├── latex-dark.css
└── latex_fonts/
```

`latex_fonts` 必须与两个 CSS 文件保持同级，否则主题无法加载内置字体。复制完成后重启 Typora，并选择 `Latex` 或 `Latex Dark`。

## 字体如何处理

用户下载发布包时，目标平台所需的字体已经包含在压缩包中，因此安装期间不需要再联网下载字体，也不需要手动逐个安装字体文件。

主题会优先使用电脑中已经存在的对应字体；缺少时才读取 Typora 主题目录下的 `latex_fonts`。这些字体只供主题使用，不会注册到 Windows、macOS 或 Linux 的系统字体目录，也不会修改已有系统字体。

发布包包含 Latin Modern、Noto Sans/Serif SC、Family Song、方正公文楷体与仿宋，以及平台所需的标题或界面回退字体。字体许可证和授权说明位于发布包的 `font-licenses` 目录；如果要再次分发本仓库或安装包，请先阅读其中的说明。

## Obsidian 使用方法

本仓库同时提供 `obsidian/latex.css`。将它复制到 Obsidian Vault 的 `.obsidian/snippets/latex.css`，然后在“设置 → 外观 → CSS 代码片段”中刷新并启用 `latex`。

该 Snippet 只调整 Markdown 内容，不覆盖 Obsidian 的界面字体，也不携带 Typora 的内置字体。图片默认居中，也可以在嵌入链接后追加 `#pic_left`、`#pic_center` 或 `#pic_right` 指定对齐方式，例如 `![[example.png#pic_center|500]]`。完整功能、阅读模式与 Live Preview 的差异及已知限制见 [Obsidian 安装说明](obsidian/README.md)。

## 从源码构建

字体资源通过 Git Submodule 管理，克隆时需要一并获取：

```bash
git clone --recurse-submodules https://github.com/gengdy1545/typora-latex-theme.git
cd typora-latex-theme
make -C src all
```

已有仓库可先执行：

```bash
git submodule update --init --recursive --depth 1
```

构建需要 `make`、Dart Sass、`unzip`、Perl 及其核心模块 `JSON::PP`。默认的 `portable` 模式会生成包含目标平台完整字体的可移植安装包。

macOS 用户也可以运行：

```bash
sh ./src/scripts/build-install-macos.sh
```

该脚本会检测 Dart Sass；缺少时可经用户确认后通过 Homebrew 安装。随后它会检测本机已有字体，只提取缺失字形，编译主题并安装到当前电脑的 Typora 主题目录。
