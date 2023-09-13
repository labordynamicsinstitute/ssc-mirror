{smcl}
{* *! version 1.0.0  14jun2019}{...}
{p2colset 1 19 21 2}{...}
{p2col:{bf:[D] songbl ssc} {hline 2}}对 SSC 中的外部命令进行中文检索{p_end}
{p2col:}({browse "https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com/ado/s/songbl.pdf":View complete PDF manual entry}){p_end}
{p2colreset}{...}
{pstd}


{marker syntax}{...}
{title:Syntax}


{p 4 14 2}
{cmd:songbl ssc}
{bind:[{it:keywords},}
{cmdab:g:ap}
{cmdab:c:ls}
{cmdab:l:ine}
{cmdab:n:umlist(#)}
{cmdab:d:rop(string)}]

{p 8 16 2}

{synoptset 13}{...}
{synopthdr:Options}
{synoptline}

{synopt:{cmdab:c:ls}}
清屏后显示结果
{p_end}

{synopt:{cmdab:l:ine}}
生成的结果表格中间划线
{p_end}

{synopt:{cmdab:drop(string)}}
删除检索的关键词
{p_end}

{synopt:{cmdab:g:ap}}
在输出的论文结果之间进行空格一行
{p_end}

{synopt:{cmdab:n:um(#)}}
指定要列出的最新推文的数量；N(10)是默认值。与 songbl ssc new 搭配使用
{p_end}

{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:songbl dir} 命令可以实现对松柏林数据库中的外部命令进行中文关键词检索。


{marker Examples}{...}
{title:Examples}

{pstd}检索 [排序] 相关的外部命令{p_end}

{phang2}. {stata "songbl ssc 排序"}{p_end} 

{pstd}同上，空格一行输出{p_end}

{phang2}. {stata "songbl ssc 排序,gap"}{p_end} 

{pstd}同上，输出的表格内部增加横线{p_end}

{phang2}. {stata "songbl ssc 排序,line"}{p_end} 

{pstd}检索 [排序] 关键词相关的外部命令，但不包括关键词 [变量]{p_end}

{phang2}. {stata "songbl ssc 排序,drop(变量) "}{p_end}

{pstd}同上，检索的结果一致{p_end}
{phang2}. {stata "songbl ssc 排序 - 变量 "}{p_end}

{pstd}输出最新的10个外部命令{p_end}

{phang2}. {stata "songbl ssc new"}{p_end}

{pstd}输出最新的20个外部命令{p_end}

{phang2}. {stata "songbl ssc new,n(20)"}{p_end}

{pstd}清屏后输出检索结果{p_end}

{phang2}. {stata "songbl ssc new,c"}{p_end}


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

