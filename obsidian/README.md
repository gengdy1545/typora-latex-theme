# Obsidian LaTeX Content Snippet

## 功能说明

`latex.css` 将本仓库 Typora LaTeX 主题的学术排版语言迁移到 Obsidian Markdown 内容，包括中西文字体角色、标题层级与阅读模式编号、正文首行缩进、列表、引用、Callout、代码与语法高亮、三线表、脚注、图片、公式及 Mermaid，并同时适配浅色和深色模式。阅读模式正文默认缩进 `2em`；如需关闭，可将 CSS 内容区域局部变量 `--tlt-first-line-indent` 改为 `0`。

## 安装方法

将仓库中的 `obsidian/latex.css` 复制到 Obsidian Vault 的 `.obsidian/snippets/latex.css`。如果 `.obsidian/snippets/` 不存在，请先创建该目录。

## 启用方法

在 Obsidian 中依次进入“设置 → 外观 → CSS 代码片段”，刷新代码片段列表，然后启用 `latex`。

## 字体说明

本版本不包含字体文件，只通过 `local(...)` 和跨平台字体栈调用本机已经安装的字体。各排版角色及主要回退顺序如下：

- 西文正文：Latin Modern Roman → Times New Roman → Times → 通用衬线字体；
- 西文标题：Latin Modern Roman 粗体 → Times New Roman → Times → 通用衬线字体；
- 中文正文：Family Song / FmlSong → Songti SC / STSong / 华文宋体 → SimSun / 宋体 → Noto Serif CJK SC / Source Han Serif SC；
- H1–H3 与表头中文：STHeiti / 华文黑体 → PingFang SC → Microsoft YaHei / 微软雅黑 → Noto Sans CJK SC / Source Han Sans SC；
- H4 中文：FZDocKai → Kaiti SC / STKaiti → KaiTi / 楷体 → Noto Serif CJK SC / Source Han Serif SC；
- H5–H6 与引用中文：FZDocFangSong → STFangsong → FangSong / 仿宋 → Songti SC → Noto Serif CJK SC / Source Han Serif SC；
- 行内代码与代码块：Latin Modern Mono → Consolas → SFMono-Regular → Menlo → Liberation Mono → Courier New → 通用等宽字体；
- Callout 标题与 Mermaid 文字：系统 UI 无衬线字体，如 Segoe UI、PingFang SC、Microsoft YaHei 和 Noto Sans CJK SC。

正文、列表和表格正文使用西文正文字体与中文宋体组合；H1–H3 使用中文黑体，H4 使用楷体，H5–H6 及引用使用仿宋；Callout 正文沿用正文字体。系统缺少首选字体时会自然采用后续字体，不影响 snippet 加载，但字形、字重和版面度量可能有所不同。

若未来需要打包仓库内置字体，应另行设计字体复制与许可证处理流程，本次版本不包含字体文件或该处理流程。

## 阅读模式与 Live Preview 的差异

阅读模式使用稳定的 HTML 标题结构，默认提供 H2–H6 多级编号，H1 不编号并重置后续计数器。Live Preview 已适配 CodeMirror 6 的标题、正文、列表、引用、代码，以及已渲染的 Callout、表格、图片、公式和 Mermaid；由于编辑器虚拟化和 DOM 重绘会导致纯 CSS counter 跳号或重置，Live Preview 默认不启用标题编号，也不承诺与阅读模式编号等价。阅读模式正文使用两端对齐和首行缩进，列表、引用、Callout、脚注及表格单元格内的段落不缩进；Live Preview 保持编辑器自然对齐且不缩进，以保护光标定位和选择体验。

## 样式范围

样式仅限定于 `.markdown-preview-view` 和 `.markdown-source-view.mod-cm6` 内的 Markdown 内容，不设置工作区背景，不作用于 Canvas、Excalidraw 或其他非 Markdown 视图，也不修改 YAML Frontmatter。

## 验证方法

启用后分别打开同一 Markdown 文档的阅读模式和 Live Preview，检查标题、段落、列表、引用、Callout、代码、表格、脚注、图片、公式与 Mermaid 的排版及浅深色可读性。随后逐一查看侧边栏、标签页、菜单、状态栏、设置页、命令面板和弹窗，确认它们在启用与停用 snippet 前后没有样式变化；宽表格还应确认可以横向滚动。

## 已知限制

Live Preview 的 CodeMirror 6 虚拟化使 CSS counter 无法可靠复现阅读模式的连续标题编号，因此默认关闭该模式下的编号。最终字体外观取决于本机已安装字体，系统回退与仓库打包字体的字形、字重和度量可能不同。Obsidian DOM 或语法高亮 token 类名在未来版本中若发生变化，相关细节样式可能需要同步调整。
