{smcl}
{* *! version 1.0.0  14jun2019}{...}
{p2colset 1 21 21 2}{...}
{p2col:{bf:[D] songbl excel} {hline 2}}把当前工作路径下的 excel 数据转为 stata 格式{p_end}
{p2col:}({browse "https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com/ado/s/songbl.pdf":View complete PDF manual entry}){p_end}
{p2colreset}{...}
{pstd}


{marker syntax}{...}
{title:Syntax}


{p 4 14 2}
{cmd:songbl excel}
{bind:[{it:keywords},}
{cmdab:f:rowfirst}
{cmdab:replace}]

{p 8 16 2}

{synoptset 13}{...}
{synopthdr:Options}
{synoptline}

{synopt:{cmdab:f:irstrow}}
将 excel 首行数据视为变量名
{p_end}

{synopt:{cmdab:replace}}
替换已经存在的数据
{p_end}

{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:songbl excel} 命令可以快捷将当前工作路径下 批量 excel 数据转为 stata .dta 数据。


{marker Examples}{...}
{title:Examples}

{pstd}将当前工作路径下批量 excel 数据转为 .dta 数据{p_end}

{phang2}. {stata "songbl excel "}{p_end} 

{pstd}同上，并将 excel 首行数据视为变量名{p_end}

{phang2}. {stata "songbl excel,firstrow "}{p_end} 

{pstd}同上，并替换已存在的数据{p_end}

{phang2}. {stata "songbl excel,firstrow replace "}{p_end} 

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

