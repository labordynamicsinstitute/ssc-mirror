{smcl}
{* *! version 1.0.0  14jun2019}{...}
{p2colset 1 19 21 2}{...}
{p2col:{bf:[D] songbl dir} {hline 2}}检索松柏林收藏的命令代码{p_end}
{p2col:}({browse "https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com/ado/s/songbl.pdf":View complete PDF manual entry}){p_end}
{p2colreset}{...}
{pstd}


{marker syntax}{...}
{title:Syntax}


{p 4 14 2}
{cmd:songbl dir}
{bind:[{it:keywords},}
{cmdab:g:ap}
{cmdab:c:ls}
{cmdab:L:ine}
{cmdab:nocat}
{cmdab:fy}
{cmdab:max:deep(numlist)}
{cmdab:d:rop(string)}]


{p 8 16 2}

{synoptset 17}{...}
{synopthdr:Options}
{synoptline}
{synopt:{cmdab:c:ls}}
清屏后显示结果
{p_end}

{synopt:{cmdab:g:ap}}
在输出的推文结果之间进行空格一行
{p_end}

{synopt:{cmdab:l:ine}}
打印显示的另一种输出风格
{p_end}

{synopt:{cmdab:nocat}}
不输出文件夹信息
{p_end}

{synopt:{cmdab:fy}}
生成把工作路径下的 pdf 文档转为网页格式的链接
{p_end}

{synopt:{cmdab:d:rop(string)}}
删除检索的关键词
{p_end}

{synopt:{cmdab:max:deep(numlist)}}
限定搜索文件夹最高层次
{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
当前目录路径下电脑文件资源的递归搜索与超链接显示。
支持* 、？等通配符，与strmatch（）函数的使用规则一致.
利用 {cmd:songbl dir} 命令可以快捷管理与打开文件。


{marker Examples}{...}
{title:Examples}

{pstd}搜索电脑D盘目录下mp4格式的视频

{phang2}. {stata "cd D:\"}{p_end}
{phang2}. {stata "songbl dir *.mp4"}{p_end}

{pstd}打印所有外部命令{p_end}

{phang2}. {stata "cd `c(sysdir_plus)'"}{p_end}
{phang2}. {stata "songbl dir"}{p_end}

{pstd}打印外部命令所在的文件夹{p_end}

{phang2}. {stata "qui songbl dir"}{p_end}

{pstd}打印所有外部命令,但是不呈现文件夹{p_end}

{phang2}. {stata "songbl dir,nocat"}{p_end}

{pstd}打印所有外部命令的 [.ado] 文件{p_end}

{phang2}. {stata "songbl dir *.ado "}{p_end}

{pstd}搜索 [songbl.ado] 文件{p_end}

{phang2}. {stata "songbl dir songbl.ado"}{p_end}

{pstd}搜索 s 开头的文件{p_end}

{phang2}. {stata "songbl dir s*"}{p_end}

{pstd}搜索至少含有两个 s 的 ado 文件{p_end}

{phang2}. {stata "songbl dir *s*s*.ado"}{p_end}

{pstd}搜索 s 开头，并且是6个字符的ado文件{p_end}

{phang2}. {stata "songbl dir s?????.ado"}{p_end}

{pstd}打印所有外部命令,打印显示另一种输出风格{p_end}

{phang2}. {stata "songbl dir,l"}{p_end}

{pstd}打印所有外部命令的 [.ado] 与 [.sthlp] 文件(并集){p_end}

{phang2}. {stata "songbl dir *.ado *.sthlp"}{p_end}

{pstd}打印所有外部命令文件,但不包括[.ado] 与 [.sthlp] 文件{p_end}

{phang2}. {stata "songbl dir ,drop(*.ado *.sthlp)"}{p_end}

{pstd}限定搜索文件夹最高一层，即当前工作路径下的文件{p_end}

{phang2}. {stata "songbl dir ,max(1)"}{p_end}


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

