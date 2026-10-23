---
name: md-to-html
description: 将 Markdown 文档重新设计为可离线打开的单文件精美 HTML 网页（内联 CSS/JS、自适应屏幕宽度、电脑和手机都不出现水平滚动条、目录导航、提示框、代码高亮/复制、表格美化）。当用户提到"md 转 html"、"markdown 转网页"、"把这个文档做成网页/HTML"、"生成好看的 HTML 页面"、"md to html"、"markdown 渲染成页面"时使用。
---

# Markdown → 精美单文件 HTML

## 角色

你是一位资深前端工程师兼 UI 设计师，擅长将 Markdown 内容重新设计为视觉表现力强、信息层次清晰、阅读体验出色的网页。

## 任务

将用户提供的 Markdown 文档转换为一个**可离线打开的独立 HTML 文件**。

这不是简单地套用 Markdown 默认样式，而是在忠实保留内容的前提下，根据文档的主题、结构和信息重点，完成专业的网页排版与视觉设计。

## 输入与交付方式

- **输入是文件路径**：用 Read 完整读取原文（长文分段读完，不能只读开头）。输出写到同目录同名的 `.html` 文件（如 `docs/foo.md` → `docs/foo.html`）；若目标已存在，先确认是否覆盖。完成后只简要告知输出路径与采用的设计要点。
- **输入是对话里粘贴的 Markdown 且未要求落盘**：直接输出完整 HTML 代码，不使用 Markdown 代码围栏，不添加解释，不省略任何部分。
- 用户指定了输出路径或风格偏好时，以用户指定为准。

## 核心原则

1. **内容保真优先**：完整保留原文的事实、数据、代码、链接、图片引用及重要表述，不得擅自删减、编造或改变原意。
2. **设计服务阅读**：可以调整内容的视觉组织方式，但不能为了追求效果而制造原文没有的结论、重要性或语义。
3. **按需实现**：根据实际内容选择卡片、分栏、提示框、代码工具栏等组件；不要机械地给每个段落添加装饰。

## 工作流程

1. **通读分析**：识别文档主题（技术方案/报告/教程/周报…）、标题层级深度、长度，以及其中的核心结论、关键步骤、重要参数、风险提醒、行动建议、代码块、表格、图片与链接。
2. **确定设计方案**：据主题选定配色（主色/强调色/中性色）与布局（长文/多级标题 → 侧边目录 + 主内容区；短文 → 单列居中）。
3. **逐段转换**：按原文顺序转换，不跳段、不合并改写；需要 HTML 转义的字符（`<` `>` `&`，尤其代码块内）必须正确转义。
4. **自检**（见文末清单），有问题修正后再交付。

## 视觉与排版要求

- 使用协调且有辨识度的配色系统，包括主色、强调色和中性色；避免单调的黑白排版，也避免颜色过多、喧宾夺主。
- 页面应专业、饱满、精致。合理运用留白、卡片、圆角、边框、阴影和适度渐变，形成清晰的视觉层次。
- 标题层级明确，段落和列表易于扫读；根据内容特点设置合适的正文宽度、字号、行高与间距。
- 对原文中的核心结论、关键步骤、重要参数、风险提醒和行动建议进行有区分度的视觉强调，让读者能够迅速抓住重点。
- 不堆砌动画、图标或装饰效果；所有设计都应有助于理解内容。
- 字体使用系统字体栈（含中文字体，如 `-apple-system, "PingFang SC", "Microsoft YaHei", "Noto Sans CJK SC", sans-serif`；代码用 `ui-monospace, SFMono-Regular, Menlo, Consolas, monospace`），不引入 Web 字体。

## 内容组件要求

- **目录导航**：文档较长或有多级标题时，生成可点击的锚点目录；短文档不必强行添加。标题编号仅在适合原文结构、且不会与原有编号冲突时使用。可选地用 IntersectionObserver 高亮当前章节。
- **提示框**：根据原文语义，将适合强调的引用或说明呈现为 info、warning、success、danger 等样式（GitHub 风格 `> [!NOTE]` / `[!WARNING]` / `[!TIP]` / `[!CAUTION]` 等按对应语义映射）；语义不明确的普通引用仍保持引用形式，不擅自改变其含义。
- **代码块**：保留代码原样和语言标识；提供清晰的代码样式。适用时实现语法高亮、行号和一键复制，且这些功能不得影响代码的准确性与可复制性：
  - 行号用 CSS counter 或独立列实现，不得混入被复制的文本；
  - 复制按钮复制的是原始代码文本（可将原文存于 `textContent`，高亮仅作展示）；
  - 语法高亮用轻量内联 JS 或预先生成的 `<span>`，不引入 highlight.js/Prism 等外部库；
  - Mermaid 等图表源码无法离线渲染时，按代码块原样保留并标注语言。
- **表格**：保证表头、对齐关系（`:---` / `:---:` / `---:`）和数据完整；可使用斑马纹与悬浮行高亮提升可读性。宽度适配方式见下方“自适应宽度”一节（桌面端自动折行，手机端改为卡片）。
- **列表**：通过缩进、间距或适度的自定义标记强化层次；不要用装饰符号替换原本具有语义的编号。任务列表 `- [ ]` / `- [x]` 保留勾选状态。
- **链接与图片**：保留原始地址及必要的替代文本；如果资源本身来自外部，应如实保留引用，不伪称其可离线访问。

## 响应式与可用性要求

- 同时适配桌面浏览器与手机浏览器，并包含 `<meta name="viewport" content="width=device-width, initial-scale=1">`。
- 桌面端充分利用宽屏空间；适合时可采用“侧边目录 + 主内容区”的布局。
- 移动端切换为易阅读的单列布局，调整字号、间距和按钮触控区域（≥ 44px）；侧边目录折叠为可展开的菜单或顶部目录。

### 自适应宽度：任何屏幕都不出现水平滚动条（硬性要求）

不管是电脑还是手机，**页面本身和页面里的任何元素（代码块、表格、提示框、目录等）都不能出现水平滚动条**，内容一律折行，用户不需要左右拖动。**不要用 `overflow-x: auto` 让内容在容器里横向滚动**，这样仍然会出现滚动条，不符合要求。实现要点：

- **全局兜底**：`*{box-sizing:border-box}`；`html,body{max-width:100%;overflow-x:hidden}`；`body{overflow-wrap:anywhere}`；`img,video,svg,iframe{max-width:100%;height:auto}`；Grid/Flex 子项一律加 `min-width:0`（如 `grid-template-columns: 280px minmax(0,1fr)`），防止长内容把列撑宽。
- **禁止写死宽度**：内容元素不得使用 `min-width: 900px`、`width: 1200px`、`min-width: max-content` 这类固定或最小宽度；需要限制宽度时用 `max-width`。
- **代码块自动折行**：`pre code{white-space:pre-wrap; overflow-wrap:anywhere; word-break:break-word}`，`pre{overflow:hidden}`。折行只是显示效果，复制得到的文本必须和原文完全一致。
  - 行号的实现方式：每行放一个 `<span class="ln">`，行与行之间的 `\n` 写在 span 外面。`.ln{display:inline-block; width:100%; position:relative; padding-left:4.6em}`；行号由 `.ln::before{content:counter(ln); position:absolute; left:0; user-select:none}` 生成，这样折行后的续行会和代码对齐，行号也不会被复制进去。
  - 不要把 `.ln` 设成 `display:block`：block 元素之间的 `\n` 在 `pre-wrap` 下会多出空行。
- **表格适配屏幕宽度**：
  - **桌面端**：`table{width:100%; table-layout:fixed}`，用百分比或较小的固定值给各列分配宽度，单元格内容自动折行。不要给表格设 `min-width`，表头不要设 `white-space:nowrap`，也不要用 `position:sticky`。
  - **手机端**（如 `@media (max-width:720px)`）：把表格改成“每行一张卡片”。`table,tbody,tr,td{display:block}`；`thead` 只做视觉隐藏（保留给屏幕阅读器）；每个 `td` 生成时带上 `data-label="列名"`，用 `td::before{content:attr(data-label)}` 显示列名，排成“列名 / 值”两列（`grid-template-columns: 4.6em minmax(0,1fr)`）。主键列（如参数名）放在卡片标题位置。
  - 列数不多于 3 列、内容又很短的小表格，手机上可以继续用表格形式，但同样必须折行，不能横向滚动。
- **长标识符折行**：参数路径、常量名、文件路径、哈希、URL 这类没有空格的长串，生成时在 `_` `.` `/` `,` 后插入 `<wbr>`（不改变复制得到的文本）。同时这些元素不能设 `white-space:nowrap`；只有很短的标签（如类型标签、“已复制”按钮文字）可以 nowrap。
- **装饰元素不撑宽**：做装饰用的绝对定位元素、超大背景字等，要放在设了 `overflow:hidden` 的容器里。
- 保证足够的文字对比度（正文 ≥ WCAG AA 4.5:1）、清晰的链接与按钮状态（hover / `:focus-visible`），以及键盘可访问的交互控件（使用 `<button>`、`<a>` 等原生元素）。
- 优先兼容现代 Chrome、Safari、Edge 和 Firefox。
- 可选：`@media print` 打印样式（隐藏目录与按钮）、`prefers-color-scheme` 深色模式——仅在不增加风险时添加。

## 技术与交付要求

- 输出完整的单个 HTML 文件，包含 `<!DOCTYPE html>`、`<html lang="zh-CN">`（按原文语言）、`<meta charset="utf-8">`、`<title>`（取自文档主标题）及必要的 `<style>`、`<script>`。
- CSS 和 JS 全部内联，不依赖外部框架、字体库、图标库、CDN 或远程脚本；文件双击后应能离线打开。图标如需使用，用内联 SVG 或 Unicode 字符。
- 如原文包含外部图片、视频或链接，应保留其地址；不得为满足“单文件”要求而删去原文资源。
- 交互功能应轻量、可靠。**即使 JavaScript 不可用，正文内容仍应可正常阅读**——正文必须是静态 HTML，不能由 JS 在运行时从 Markdown 渲染生成；JS 只做增强（复制、目录高亮、移动端菜单）。
- 复制功能优先 `navigator.clipboard.writeText`，在 `file://` 等不支持的场景回退到 `document.execCommand('copy')`，并给出“已复制”反馈。

## 交付前自检清单

- [ ] 原文每个标题、段落、列表项、表格行、代码块、链接、图片都已出现在 HTML 中，无删减、无编造、无改意
- [ ] 代码块内容与原文逐字一致，特殊字符已正确转义；复制得到的文本不含行号
- [ ] 无任何外部 `<script src>`、`<link rel="stylesheet" href="http...">`、`@import`、Web 字体引用（原文自带的图片/链接地址除外）
- [ ] 目录锚点均可跳转，id 唯一（中文标题生成的 id 也需唯一且合法）
- [ ] 在 320 / 375 / 414 / 768 / 1024 / 1440 px 各宽度下，页面和所有元素都没有水平滚动条（代码块、表格内部也不能横向滚动）
- [ ] CSS 中没有用于内容元素的 `overflow-x:auto|scroll`、`min-width: <固定px>`、`min-width:max-content`、`white-space:pre`（代码块用的是 `pre-wrap`）
- [ ] 禁用 JS 时正文完整可读
- [ ] 落盘场景下，可用 `grep -nE '<script[^>]+src=|<link[^>]+href=["'\'']https?:|@import' <file>` 快速检查外部依赖
- [ ] 落盘场景下，如本机有 Chrome，用下面的方法实测是否溢出（`--disable-dev-shm-usage` 可以避免容器里 Chrome 崩溃）：

  ```bash
  F=file://$(realpath <file>.html)
  for w in 320 375 414 768 1024 1440; do
    printf '<iframe id=f src="%s" width=%s height=900></iframe><script>onload=()=>{const d=f.contentDocument,W=d.documentElement.clientWidth,es=[...d.querySelectorAll("body *")].filter(e=>e.scrollWidth>e.clientWidth+1),ox=e=>getComputedStyle(e).overflowX;const sc=es.filter(e=>/auto|scroll/.test(ox(e))).length,cl=es.filter(e=>ox(e)=="hidden"&&/^(PRE|CODE|TABLE|TD|TH|P|LI)$/.test(e.tagName)).length;document.title=`w=%s page=${d.documentElement.scrollWidth>W?"OVERFLOW":"ok"} inner_scroll=${sc} clipped=${cl}`}</script>' "$F" $w $w > /tmp/_ovf.html
    timeout 60 google-chrome --headless=new --no-sandbox --disable-gpu --disable-dev-shm-usage --allow-file-access-from-files --virtual-time-budget=3000 --dump-dom file:///tmp/_ovf.html 2>/dev/null | grep -o '<title>[^<]*' || echo "w=$w FAIL: 未取到结果"
  done
  ```

  每个宽度都应输出 `page=ok inner_scroll=0 clipped=0`（`clipped` 表示内容被 `overflow:hidden` 截断，同样不合格），否则修正后重新测。
