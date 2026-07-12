# 安装教程

## 安装前

安装本主题前，请确保已经安装并至少运行过一次 Typora。项目源码仓库的 `resources` 文件夹包含主题示例；这些示例不再复制到各平台安装包中。

安装包的 `target` 目录结构如下：

```text
target/
├── latex.css
├── latex-dark.css
└── latex_fonts/
```

`latex_fonts` 是主题自己的字体资源目录，不会注册到操作系统。

公开发布包使用 `portable` 模式，包含目标平台 CSS 引用的完整字体集合；从源码运行 macOS 一键安装脚本时使用 `auto` 模式，会检测本机字体，因此 `latex_fonts` 可能只包含缺失字形，甚至为空。该目录只包含 TTF/OTF，相关许可证和授权说明放在安装包根目录的 `font-licenses`。

## 开始安装

以下两种安装方式任选其一。

### 自动安装

- macOS：打开终端，将 `install.sh` 拖入终端窗口并执行。
- Linux：在安装包目录执行 `sh ./install.sh`。
- Windows：右键点击 `install.ps1`，选择“使用 PowerShell 运行”。

安装脚本会将两个 CSS 文件和 `latex_fonts` 一并复制到 Typora 主题目录。

如果 Windows 提示执行策略限制，请仅在确认脚本来自本项目后，按照 PowerShell 提示允许本次执行。

### 手动安装

按照 [Typora 官方主题安装教程](https://theme.typora.io/doc/Install-Theme/) 打开主题文件夹，然后同时复制：

- `target/latex.css`
- `target/latex-dark.css`
- 整个 `target/latex_fonts` 文件夹

CSS 文件与 `latex_fonts` 必须保持同级，否则内置字体无法加载。

## 内置字体

安装包已经内置：

- Latin Modern：用于西文正文、标题和代码。
- Noto Sans/Serif SC：在系统缺少首选中文字体时提供回退。
- Family Song：用于中文正文及粗体、斜体。
- 方正公文楷体、仿宋：用于对应的中文标题和引用角色。
- macOS 的华文黑体或 Windows 的阿里巴巴普惠体：用于平台标题和界面回退。

主题通过 `@font-face` 的 `local(...)` 优先调用系统中已经存在的对应字体；只有找不到时，Typora 才会读取 `latex_fonts` 中的字体文件。因此用户不需要逐个安装字体，也不会修改 Windows、macOS 或 Linux 的系统字体目录。

三平台共用字体会优先保持正文、楷体和仿宋角色；遇到字体未覆盖的字符时，仍会回退到 Noto 或系统字体。

## 最后一步

完全退出并重新打开 Typora，然后在“主题”菜单中选择 `Latex` 或 `Latex Dark`。

如果您觉得这个主题有帮助，欢迎在 GitHub 上为项目点 Star。
