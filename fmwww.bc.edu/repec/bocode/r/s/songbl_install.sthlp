{smcl}
{* *! version 1.0.0  14jun2019}{...}
{p2colset 1 23 22 2}{...}
{p2col:{bf:[R] songbl install} {hline 2}}安装外部命令{p_end}
{p2col:}({browse "https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com/ado/s/songbl.pdf":View complete PDF manual entry}){p_end}
{p2colreset}{...}
{pstd}


{marker syntax}{...}
{title:Syntax}


{p 4 14 2}
{cmd:songbl install}
{bind:[{it:keywords},}
{cmdab:replace}
{cmdab:all}]

{p 8 16 2}

{synoptset 13}{...}
{synopthdr:Options}
{synoptline}

{synopt:{cmdab:replace}}
指定计算机上已经存在的程序文件将被已下载的文件替换。
{p_end}

{synopt:{cmdab:all}}
指定除了正在安装的程序和帮助文件外，把相关的辅助文件下载到当前工作目录。
{p_end}

{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:songbl install} 可以安装 SSC 平台上的外部命令，类似于 {cmd:ssc install}，但是安装速度要快很多。


{marker Examples}{...}
{title:Examples}

{pstd}安装 {cmd:reghdfe} 命令 {p_end}

{phang2}. {stata "songbl install reghdfe"}{p_end} 
{phang2}. {stata "songbl install reghdfe,replace"}{p_end} 
{phang2}. {stata "songbl install reghdfe,replace all"}{p_end} 

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

