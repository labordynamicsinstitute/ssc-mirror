{smcl}
{* *! version 1.0.0  14jun2019}{...}
{p2colset 1 19 21 2}{...}
{p2col:{bf:[D] songbl cie} {hline 2}}检索松柏林收藏的命令代码{p_end}
{p2col:}({browse "https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com/ado/s/songbl.pdf":View complete PDF manual entry}){p_end}
{p2colreset}{...}
{pstd}


{marker syntax}{...}
{title:Syntax}


{p 4 14 2}
{cmd:songbl cie}
{bind:[{it:keywords},}
{cmdab:g:ap}
{cmdab:c:ls}]

{p 8 14 2}

{synoptset 14}{...}
{synopthdr:Options}
{synoptline}
{synopt:{cmdab:c:ls}}
清屏后显示结果
{p_end}

{synopt:{cmdab:g:ap}}
在输出的推文结果之间进行空格一行
{p_end}

{synopt:{cmdab:no:replace}}
如果已修改过论文代码dofile,则是检索后打开生成的dofile,而不会下载替换
{p_end}
{synoptline}


{marker Examples}{...}
{title:Examples}

{pstd}打开《中国工业经济》期刊目录

{phang2}. {stata "songbl cie "}{p_end}

{pstd}能实现同上的效果,但是速度较慢

{phang2}. {stata "qui songbl paper ,j(中国工业经济)"}{p_end}

{pstd}检索 {cmd:xthreg} 命令的代码

{phang2}. {stata "songbl cie xthreg"}{p_end}

{pstd}检索 {cmd:reghdfe} 命令的代码

{phang2}. {stata "songbl cie reghdfe"}{p_end}

{pstd}如果已有论文代码dofile,打开检索后生成的 dofile 则不会被替换

{phang2}. {stata "songbl cie reghdfe,noreplace"}{p_end}

{marker description}{...}
{title:Description}

{pstd}
通过输入关键词命令，检索来自{cmd:songbl} 论文代码数据库的 dofile。
论文代码数据库主要来自《中国工业经济》，后期会加入更多期刊。
例如《数量经济与技术经济研究》很快也会公布论文复制的代码与数据。


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

