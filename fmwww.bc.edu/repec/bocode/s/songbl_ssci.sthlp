{smcl}
{* *! version 1.0.0  14jun2019}{...}
{p2colset 1 20 21 2}{...}
{p2col:{bf:[D] songbl ssci} {hline 2}}对 SSCI 期刊网址进行关键词检索{p_end}
{p2col:}({browse "https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com/ado/s/songbl.pdf":View complete PDF manual entry}){p_end}
{p2colreset}{...}
{pstd}


{marker syntax}{...}
{title:Syntax}

{p 4 14 2}
{cmd:songbl ssci}
{bind:[{it:keywords},}
{cmdab:g:ap}
{cmdab:c:ls}
{cmdab:d:rop(string)}]

{p 8 16 2}

{synoptset 13}{...}
{synopthdr:Options}
{synoptline}

{synopt:{cmdab:c:ls}}
清屏后显示结果
{p_end}

{synopt:{cmdab:drop(string)}}
删除检索的关键词
{p_end}

{synopt:{cmdab:g:ap}}
在输出的论文结果之间进行空格一行
{p_end}

{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:songbl ssci} 命令可以实现 SSCI 期刊网址进行关键词检索。


{marker Examples}{...}
{title:Examples}

{pstd}分类查看所有 SSCI 期刊{p_end}

{phang2}. {stata "songbl ssci "}{p_end} 

{pstd}检索 [china] 相关的 ssci 期刊{p_end}

{phang2}. {stata "songbl ssci china"}{p_end} 

{pstd}同上，空格一行输出{p_end}

{phang2}. {stata "songbl ssci china,gap"}{p_end} 

{pstd}检索 [china] 相关的 ssci 期刊，但不包括关键词 [变量]{p_end}

{phang2}. {stata "songbl ssci china,drop(Review) "}{p_end}

{pstd}同上，检索的结果一致{p_end}

{phang2}. {stata "songbl ssci china - Review"}{p_end}


{title:Author}

{phang}
{cmd:Bolin, Song (松柏林)} Shenzhen University, China. {break}
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

