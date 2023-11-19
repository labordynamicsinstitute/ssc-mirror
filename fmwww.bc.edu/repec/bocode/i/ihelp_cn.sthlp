{smcl}
{* 17Nov2023}{...}
{cmd:help ihelp {stata "help ihelp": English version}}{right: }
{hline}

{title:标题}

{p2colset 5 16 18 2}{...}
{p2col:{hi:ihelp} {hline 2}} 在浏览器窗口显示帮助文档（HTML 简易版或 PDF 详细版），并提供帮助文档的网页链接 {p_end}
{p2colreset}{...}


{title:语法}

{p 8 16 2}
{cmd:ihelp} {cmd:}{it:command_name} [{cmd:,}
{opt w:eb}
{opt m:arkdown}
{opt txt}
{opt ms}
{opt tex:full}
{opt l:atex}
{opt f:ormat}{cmd:(}#{cmd:)}
{opt c:lipoff}]

{synoptset 17 tabbed}{...}
{synopthdr}
{synoptline}
{col 5}{bf:网页版帮助文档}：直接在浏览器中显示帮助文件
{col 5}{hline 14}
{synopt:{opt w:eb}}打开 HTML 简易版在线帮助文档 (默认打开 PDF 详细版){p_end}
{synopt:{opt f:ormat(#)}}以预设格式提供网页链接，包括三种预设格式{p_end}

{col 5}{bf:Markdown, Word 和 TeX 格式}：显示帮助文档的引用信息和链接，自动复制到剪切板
{col 5}{hline 26}
{synopt:{opt m:arkdown}}以 Markdown 格式提供网页链接{p_end}
{synopt:{opt txt}}以 纯文本 格式提供网页链接，可以复制到微信的对话框中{p_end}
{synopt:{opt ms}}以富文本格式提供网页链接，可以复制到 MicroSoft Word 中呈现为带链接的文本{p_end}
{synopt:{opt tex:full}}以 LaTeX原始 格式提供网页链接{p_end}
{synopt:{opt l:atex}}以 LaTeX 格式提供网页链接{p_end}

{col 5}{bf:其它}：
{col 5}{hline 4}
{synopt:{opt c:lipoff}}不把输出内容复制到剪切板{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}


{title:简介}

{pstd}
{cmd:ihelp} 用于打开 Stata 官方命令的在线帮助文件。官方命令 {help help} 可以打开内置的帮助文档，但只能在 Stata 窗口阅读；
若要查看 PDF 版本的帮助文件，则需要打开该命令所属的完整 PDF 文件 (通常有几百页)，不利于记录和分享。

{pstd}
{cmd:ihelp} 可以克服上述局限，快速搜索单个命令的 PDF 手册文档 (一个命令对应一个 PDF 文件)，或在 Web 浏览器中查看网页版帮助文件。
同时，{cmd:ihelp} 还可以提供帮助文件的引文信息，并采用 text, markdown, TeX 等多种格式输出，便于记录和分享。 

{pstd}
使用时，只需要在官方命令 {it:help} 前面添加一个字母 {it:i} 即可。所有使用 {it:help cmd} 命令可以直接打开的官方帮助文件，
都可以使用 {it:{bf:i}}{it:help cmd} 打开其 PDF 版本 (与 Stata 电子手册内容一致) 和 HTML 版本 (与普通的文字版帮助文件内容一致)。

{pstd}
为了方便引用，{cmd:ihelp} 命令还设置了一系列格式选项，包括 {it:markdown}、{it:txt}、{it:ms}、{it:latex}、{it:texfull} 和 {it:format(#)}。这些选项考虑了不同文本编辑器（比如 TeXLive、Markdown）的语法差异，
使得用户可以根据需要，获取特定格式的在线帮助文件链接，并自动复制到剪贴板。

{pstd}
此外，{cmd:ihelp} 还可以处理命令缩写问题，并在缩写无法唯一识别官方命令时，列出所有可能的相似命令。


{title:选项}

{phang}{ul:主要选项}

{phang2}{opt web} 快速打开 HTML 简易版在线帮助文档。(默认打开 PDF 详细版)

{phang}{ul:格式选项}：提供帮助文档的网页链接，并自动复制到剪切板，支持多种呈现格式。{p_end}

{phang2}{opt markdown} 以 Markdown 形式显示网页链接，比如 {ul:ihelp regress, markdown} 显示的文本格式如下：{p_end}

{pmore3} [**[R]** regress](https://www.stata.com/manuals/rregress.pdf) 
 {p_end}

{phang3}将其复制到 Markdown 中会显示为可点击的链接：{browse "https://www.stata.com/manuals/rregress.pdf":------ [R] regress --------}{p_end}

{phang2}{opt txt} 以文本（命令:URL）形式显示网页链接，比如 {ul:ihelp regress, txt} 显示的文本格式如下：{p_end}

{pmore3}[R] regress: https://www.stata.com/manuals/rregress.pdf {p_end}

{phang3}可以将其复制到微信的对话框中，效果为：[R] regress: {browse "https://www.stata.com/manuals/rregress.pdf":https://www.stata.com/manuals/rregress.pdf}{p_end}

{phang2}o {opt ms} 以富文本形式将链接复制到剪切板，该链接可以粘贴到 MicroSoft Word 中，呈现为带链接的文本。比如 {ul:ihelp regress, ms} 后，按 Ctrl+V 粘贴到 Word，将显示为：{browse `"https://www.stata.com/manuals/rregress.pdf"':[R] regress}{p_end}

{phang3}需要注意的是，该功能存在一些局限：（1）只能在 Windows 系统中使用；（2）只适用于 Stata 16 或更高版本；（3）需要安装 Python。若不满足上述条件，则会自动切换为 {opt txt} 选项，生成文本（命令:URL）形式的网页链接。{p_end}

{phang2}{opt texfull} 以完整的 TeX 文本形式显示网页链接，比如 {ul:ihelp regress, texfull} 显示的文本格式如下：{p_end}

{pmore3} \href{https://www.stata.com/manuals/rregress.pdf}{\bfseries{[\MakeUppercase{r}] regress}}  {p_end}

{phang3} 可以将其插入到 .tex 文档中，使用 TeX 编辑器编译后会显示为 PDF 文件中的可点击的链接：{browse `"https://www.stata.com/manuals/rregress.pdf"':[R] regress}{p_end}

{phang2}{opt latex} 以 Latex 形式显示网页链接，比如 {ul:ihelp regress, latex} 显示的文本格式如下：{p_end}

{pmore3}\stihelp[r]{regress} {p_end}

{phang3} 可以将其插入到 .tex 文档中，使用 TeX 编辑器编译后会显示为 PDF 文件中的可点击的链接：{browse `"https://www.stata.com/manuals/rregress.pdf"':[R] regress}{p_end}

{pmore3}注意：由于 {it:\stihelp} 是一个用户定义的新命令，需要在 .tex 文档的导言区中加入下述内容来定义该命令：{p_end}
{pmore3} \newcommand{\stihelp}[2][r]{  {p_end}
{pmore3}{space 4}	 \href{https://www.stata.com/manuals/#1#2.pdf}{\bfseries{[\MakeUppercase{#1}] #2}}  {p_end}
{pmore3} }  {p_end}

{phang2}{cmd:format(#)} 以预设格式提供网页链接，支持三种 Markdown 的预设格式：

{phang3}format(1) 在 Markdown 中呈现为 {browse `"https://www.stata.com/manuals/rregress.pdf"':[R] regress}，显示的文本格式如下：{p_end}

{pmore3}[**[R]** regress](https://www.stata.com/manuals/rregress.pdf)

{phang3}format(2) 在 Markdown 中呈现为 {browse `"https://www.stata.com/manuals/rregress.pdf"':regress}，显示的文本格式如下：{p_end}

{pmore3}[regress](https://www.stata.com/manuals/rregress.pdf)

{phang3}format(3) 在 Markdown 中呈现为 {browse `"https://www.stata.com/manuals/rregress.pdf"':help regress}，显示的文本格式如下：{p_end}

{pmore3}[help regress](https://www.stata.com/manuals/rregress.pdf)

{phang2}{cmd:clipoff} 取消复制到剪切板


{title:举例}

{phang}* {ul:基本功能}：打开帮助文档

{phang2}{inp:.} {stata "ihelp pwcorr":ihelp pwcorr}{p_end}
{phang2}{inp:.} {stata "ihelp clip(), web":ihelp clip(), web}{p_end}
{phang2}{inp:.} {stata "ihelp mata function":ihelp mata function}{p_end}
{phang2}{inp:.} {stata "ihelp twoway scatter, web":ihelp twoway scatter, web}{p_end}
{phang2}{inp:.} {stata "ihelp sum":ihelp sum}{p_end}

{phang}* {ul:辅助功能}：输出不同格式的引文信息

{phang2}{inp:.} {stata "ihelp twoway scatter, m":ihelp twoway scatter, markdown}{p_end}
{phang2}{inp:.} {stata "ihelp import excel, w web":ihelp import excel, w web}{p_end}
{phang2}{inp:.} {stata "ihelp xtreg, latex":ihelp xtreg, latex}{p_end}
{phang2}{inp:.} {stata "ihelp xtreg, tex":ihelp xtreg, tex}{p_end}
{phang2}{inp:.} {stata "ihelp xtreg, f(2)":ihelp xtreg, f(2)}{p_end}
{phang2}{inp:.} {stata "ihelp xtreg, f(3) clipoff":ihelp xtreg, f(3) clipoff}{p_end}


{title:存储结果}

{pstd}
可以通过{stata "return list": return list} 查看 {cmd:ihelp} 后的存储结果 (参见 {help return}):

{synoptset 15 tabbed}{...}
{synopt:{cmd:. r(link)}}PDF帮助文档的网页链接（URL）{p_end}
{synopt:{cmd:. r(link_web)}}网页版帮助文档的网页链接（URL）{p_end}
{synopt:{cmd:. r(link_m)}}Markdown格式的网页链接文本{p_end}
{synopt:{cmd:. r(link_txt)}}命令:URL 格式的网页链接文本{p_end}
{synopt:{cmd:. r(link_l1)}}LaTeX原始形式的网页链接代码{p_end}
{synopt:{cmd:. r(link_l2)}}LaTeX自定义形式的网页链接代码{p_end}
{synopt:{cmd:. r(link_f1)}}第一种预设格式的网页链接文本{p_end}
{synopt:{cmd:. r(link_f2)}}第二种预设格式的网页链接文本{p_end}
{synopt:{cmd:. r(link_f3)}}第三种预设格式的网页链接文本{p_end}


{title:作者}

{pstd} {cmd:Yujun,Lian* (连玉君)}{p_end}
{pstd} . Lingnan College, Sun Yat-Sen University, China. {p_end}
{pstd} . E-mail: {browse "mailto:arlionn@163.com":arlionn@163.com} {p_end}
{pstd} . Blog: {browse "lianxh.cn":https://www.lianxh.cn}.{p_end}

{pstd} Yongli,Chen (陈勇吏) {p_end}
{pstd} . Antai College of Economics and Management, Shanghai Jiao Tong University, China.{p_end}
{pstd} . E-mail: {browse "mailto:yongli_chan@163.com":yongli_chan@163.com}{p_end}


{title:引用}

{pstd} Chen Yongli, Yujun Lian. Browse and cite Stata manuals easily: the
wwwhelp command. {bf:The Stata Journal}, 2024, forthcoming, {browse "https://file-lianxh.oss-cn-shenzhen.aliyuncs.com/Refs/LianPub/Chen-Lian-2024-SJ-wwwhelp-ihelp.pdf":--PDF--}.


{title:Also see}

{pstd} Online: {helpb help}, {helpb wwwhelp} (same as {helpb ihelp}){p_end}

