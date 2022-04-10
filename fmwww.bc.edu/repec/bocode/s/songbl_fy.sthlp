{smcl}
{* *! version 1.0.0  14jun2019}{...}
{p2colset 1 19 21 2}{...}
{p2col:{bf:[D] songbl fy} {hline 2}}翻译单词、句子、stata 命令帮助文档与 PDF 英文文档{p_end}
{p2col:}({browse "https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com/ado/s/songbl.pdf":View complete PDF manual entry}){p_end}
{p2colreset}{...}
{pstd}


{marker syntax}{...}
{title:Syntax}


{p 4 14 2}
{cmd:songbl fy}
{bind:[{it:keywords},}
{cmdab:c:ommand}
{cmdab:pdf}]

{p 8 16 2}

{synoptset 17}{...}
{synopthdr:Options}
{synoptline}
{synopt:{cmdab:c:ommand}}
将 stata 命令帮助文档由 .sthlp 或 .hlp 格式，转为 .html 网页格式。
{p_end}

{synopt:{cmdab:pdf}}
将当前文件夹下 pdf 文档转为 .html 网页格式。网页格式文字可以使用 Google翻译转译
{p_end}
{synoptline}

{marker Examples}{...}
{title:Examples}

{pstd} 翻译单词 "中国"

{phang2}. {stata "songbl fy 中国"}{p_end}

{pstd} 翻译单词 "china"

{phang2}. {stata "songbl fy china"}{p_end}

{pstd} 翻译句子 "网页格式文字可以使用 Google翻译转译"

{phang2}. {stata "songbl fy 网页格式文字可以使用 Google翻译转译"}{p_end}

{pstd} 翻译句子 "Caution, you are requesting to edit an ado file provided by Stata."

{phang2}. {stata `"songbl fy "Caution, you are requesting to edit an ado file provided by Stata""'}{p_end}

{pstd} 将 merge 命令帮助文档由 .sthlp 转为 .html 网页格式

{phang2}. {stata "songbl fy merge,c"}{p_end}

{pstd} 将 当前工作路径下全部 pdf 文档转为 .html 网页格式

{phang2}. {stata "songbl fy ,pdf"}{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:songbl fy} 命令翻译单词与词语时，这是利用有道翻译与微软翻译进行转译，因此该功能需要有网络环境才能进行。

   主要以如下思路批量进行命令帮助文档与英文文献翻译，首先把.sthlp、pdf文档转为 .html 网页格式，然后使用 Google翻译转译。

   在转换过程中，我们使用了 {help wordconvert} 命令，这个命令通过调用 PowerShell 和 MS Word 实现文件相互转换。
   要使用这个命令，首先要保证电脑里面装有 Microsoft Word2007 或更高的版本。
   此外，还需要解决 PowerShell 禁止脚本运行的问题。配置 PowerShell，方法如下：{browse "https://mp.weixin.qq.com/s/cKPpVerQ--ztQA86qF68Sw"}



{title:Author}

{phang}
{cmd:Bolin, Song (松柏林)} Shenzhen University, China. wechat：{cmd:songbl_stata}{break}
{p_end}


{title:wechat}

{synoptset 30 }{...}
{cmd:     Stata 交流群微信：{browse "https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com/picture/wechat/wechat.jpg":songbl_stata}}
{p2colreset}{...}

{cmd:    上传Stata资源到知识星球：{browse "https://public.zsxq.com/groups/28855842182811.html":https://public.zsxq.com/groups/28855842182811.html}}

{p2colreset}{...}

{title:Also see}

{synoptset 30 }{...}
{synopt:{help songbl}}
{p2colreset}{...}

{title:Acknowledgement}

{p}部分代码改编来自命令 {bf:fanyi} ，在此表示感谢。{browse "https://github.com/r-stata/fanyi":https://github.com/r-stata/fanyi} 
{p_end}

