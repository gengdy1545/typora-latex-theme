# Obsidian LaTeX Content Snippet

## 功能说明

`latex.css` 为 Obsidian Markdown 内容提供学术排版，包括标题层级、正文首行缩进、列表、引用、Callout、三线表、脚注、图片与图片对齐语法、公式及 Mermaid，并同时适配浅色和深色模式。阅读模式与 Live Preview 不显示标题编号；导出 PDF 时为 H2–H6 生成连续编号，H1 不编号，并在每个 H1 处重新计数。阅读模式正文默认缩进 `2em`；如需关闭，可将 CSS 内容区域局部变量 `--tlt-first-line-indent` 改为 `0`。

本 Snippet 不覆盖行内代码、围栏代码块、语法高亮或行号样式，这些内容完全使用 Obsidian 当前主题或相关插件的默认效果。

## 安装方法

将仓库中的 `obsidian/latex.css` 复制到 Obsidian Vault 的 `.obsidian/snippets/latex.css`。如果 `.obsidian/snippets/` 不存在，请先创建该目录。

## 启用方法

在 Obsidian 中依次进入“设置 → 外观 → CSS 代码片段”，刷新代码片段列表，然后启用 `latex`。

## 字体说明

本 snippet 不包含 `@font-face`、字体文件或自定义字体栈，也不覆盖正文、界面及代码的 `font-family`。请在 Obsidian 的“设置 → 外观 → 字体”中分别配置界面字体、正文字体和代码字体；“字体大小”设置控制正文基础字号，snippet 中标题、脚注等相对字号会随之按比例变化。

## 图片对齐

图片默认居中。需要显式指定对齐方式时，在嵌入链接的文件名后追加 `#pic_left`、`#pic_center` 或 `#pic_right`：

```text
![[example.png#pic_center]]
![[example.png#pic_left|500]]
```

锚点可以和 Obsidian 原生的 `|500` 宽度参数同时使用；snippet 不设置图片宽度，尺寸仍由该参数或图片自身决定。该语法适用于 `![[...]]` 嵌入。

## 阅读模式与 Live Preview 的差异

阅读模式与 Live Preview 的标题都不带编号。阅读模式正文使用两端对齐和首行缩进，列表、引用、Callout、脚注及表格单元格内的段落不缩进；Live Preview 保持编辑器自然对齐且不缩进。

## 样式范围

样式仅限定于 `.markdown-preview-view` 和 `.markdown-source-view.mod-cm6` 内的 Markdown 内容，不设置工作区背景，不作用于 Canvas、Excalidraw 或其他非 Markdown 视图，也不修改 YAML Frontmatter。

## 验证方法

启用后分别打开同一 Markdown 文档的阅读模式和 Live Preview，检查标题不带编号，并检查段落、列表、引用、Callout、表格、脚注、图片、公式与 Mermaid 的排版及浅深色可读性。用 `#pic_left`、`#pic_center`、`#pic_right` 各嵌入一张图片确认对齐生效。导出 PDF 后，H2–H6 应有连续编号。代码应保持当前 Obsidian 主题的默认表现。随后逐一查看侧边栏、标签页、菜单、状态栏、设置页、命令面板和弹窗，确认它们在启用与停用 snippet 前后没有样式变化；宽表格还应确认可以横向滚动。

## 已知限制

标题编号只在打印和导出 PDF 时出现。编号按当次导出的完整文档计数；分成多篇笔记分别导出时，每篇各自从 1 开始。
