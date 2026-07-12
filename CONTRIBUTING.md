 

# 作出贡献

感谢您对 Typora LaTeX Theme 的关注！我们欢迎任何形式的贡献。  

与贡献相关的详细文档可在[贡献指南](https://github.com/Keldos-Li/typora-latex-theme/wiki/%E8%B4%A1%E7%8C%AE%E6%8C%87%E5%8D%97)中找到。这份指南不仅描述了本项目的贡献规范，而且介绍了构建方法和工具链，帮助您快速开始开发。您可能也对本项目的[技术细节](https://github.com/Keldos-Li/typora-latex-theme/wiki/%E6%8A%80%E6%9C%AF%E7%BB%86%E8%8A%82)感兴趣。  

## 本地构建

字体资源以 Git Submodule 管理。克隆时建议执行：

```bash
git clone --recurse-submodules <repository-url>
```

已有工作区可执行：

```bash
git submodule update --init --recursive --depth 1
```

构建需要 `make`、Dart Sass、`unzip`，以及带核心模块 `JSON::PP` 的 Perl。macOS、常见 Linux 发行版和 Git for Windows 通常已经包含 Perl。准备完成后运行：

```bash
make -C src all
```

生成目录中每个平台的 `target` 都包含 `latex.css`、`latex-dark.css` 和 `latex_fonts`。字体仅作为主题资源使用，不会安装到系统。

默认的 `FONT_MODE=portable` 用于 CI 和发布包：它不会读取构建机器的字体状态，会携带目标平台 CSS 引用的全部字体。若构建完成后只在当前电脑安装，可以启用本机检测：

```bash
make -C src macos FONT_MODE=auto
```

`auto` 只能构建当前操作系统。它会逐字形检查本机字体，已有字体不会重复放进 `target/latex_fonts`，缺失字体才从字体子模块的 ZIP 解压。无论使用哪种模式，`latex_fonts` 都只包含 TTF/OTF；许可证和字体授权说明位于安装包根目录的 `font-licenses`。

## 获取帮助

如果您遇到了无法解决的问题，您可以前往 GitHub Discussions [发起讨论](https://github.com/Keldos-Li/typora-latex-theme/discussions/new)，或前往 GitHub Issues [报告故障](https://github.com/Keldos-Li/typora-latex-theme/issues/new?labels=bug)、[请求新功能](https://github.com/Keldos-Li/typora-latex-theme/issues/new?labels=Feature+Request)。同时，您也可以使用电子邮件，联系 [Keldos-Li](mailto:i@keldos.me) 或 [RalXYZ](mailto:RalXYZ@pm.me)，或者[加入交流反馈QQ群](https://qm.qq.com/cgi-bin/qm/qr?k=8Vy0m_9-phExgORJKwVTZ2Hix19yScCn&jump_from=webapi)之后和大家一起讨论。
