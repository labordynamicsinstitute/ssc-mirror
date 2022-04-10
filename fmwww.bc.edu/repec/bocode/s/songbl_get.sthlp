{smcl}
{* *! version 1.0.0  14jun2019}{...}
{p2colset 1 19 21 1}{...}
{p2col:{bf:[D] songbl get} {hline 2}}下载和打开在网络上 dofile 文档{p_end}
{p2col:}({browse "https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com/ado/s/songbl.pdf":View complete PDF manual entry}){p_end}
{p2colreset}{...}
{pstd}


{marker syntax}{...}
{title:Syntax}


{p 4 14 2}
{cmd:songbl get}
[
{it:filename}  
{cmd:,}
{cmd:no}
{cmd:replace} 
]


{p 8 16 2}

{synoptset 10}{...}
{synopthdr:Options}
{synoptline}

{synopt:{cmdab:no:pen}}
仅下载，不打开 dofile.
{p_end}

{synopt:{cmdab:replace}}
用与加载的文件相同的文件名覆盖该文件
{p_end}

{synoptline}

{marker Examples}{...}
{title:Examples}

{phang}{stata "songbl get prof" : . songbl get prof}{p_end}

{phang}{stata "songbl get prof,no" : . songbl get prof,no}{p_end}

{phang}{stata "songbl get prof,replace" : . songbl get prof,replace}{p_end}

{phang}{stata "songbl get https://gitee.com/songbolin/stata_do/raw/master/iv.do" : . songbl get https://gitee.com/songbolin/stata_do/raw/master/iv.do}{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:songbl get} 命令可以下载并打开 {cmd:songbl}数据库中的 dofile 文档。
当用户使用 {stata "help songbl_cn":songbl} 命令搜索 dofile 文件时，
可以使用 {cmd:songbl get} 命令直接下载到外部命令文件夹并打开它。
此外，{cmd:songbl get} 还可以下载和打开在网络上 dofile 文档。
例如保存在 GitHub 或 Gitee 上的 dofile 文档。


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

