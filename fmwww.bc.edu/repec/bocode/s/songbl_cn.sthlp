{smcl}
{* *! version 1.0.0  14jun2019}{...}
{p2colset 1 15 19 2}{...}
{p2col:{bf:[D] songbl} {hline 2}}检索松柏林数据库中的推文{p_end}
{p2col:}({browse "https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com/ado/s/songbl.pdf":View complete PDF manual entry}){p_end}
{p2colreset}{...}
{pstd}


{marker syntax}{...}
{title:Syntax}


{p 4 14 2}
{cmd:songbl}
{bind:[{it:keywords},}
{cmdab:g:ap}
{cmdab:c:ls}
{cmdab:m:link}
{cmdab:mt:ext}
{cmdab:mu:rl}
{cmdab:w:link}
{cmdab:wt:ext}
{cmdab:wu:rl}
{cmdab:l:ine}
{cmdab:t:able}
{cmdab:noc:at}
{cmdab:n:avigation}
{cmdab:save(str)}
{cmdab:drop(str)}
{cmdab:auth:or(str)}
{cmdab:replace}
{cmdab:n:um(int)}
{cmdab:clip}]

{p 8 16 2}

{synoptset 13}{...}
{synopthdr:Options}
{synoptline}
{synopt:{cmdab:c:ls}}
清屏后显示结果
{p_end}

{synopt:{cmdab:noc:at}}
不输出推文来源信息
{p_end}

{synopt:{cmdab:drop(str)}}
去除指定的检索关键词
{p_end}

{synopt:{cmdab:t:able}}
以表格的形式呈现检索结果
{p_end}

{synopt:{cmdab:g:ap}}
在输出的推文结果之间空格一行
{p_end}

{synopt:{cmdab:l:ine}}
以表格的形式呈现检索结果时，在表格内部划线。
{p_end}

{synopt:{cmdab:m:link}}
输出第1种 Markdown 形式的推文信息
{p_end}

{synopt:{cmdab:mt:ext}}
输出第2种 Markdown 形式的推文信息
{p_end}

{synopt:{cmdab:mu:rl}}
输出第3种 Markdown 形式的推文信息
{p_end}

{synopt:{cmdab:w:link}}
输出第1种 Weixin 分享形式推文信息
{p_end}

{synopt:{cmdab:wt:ext}}
输出第2种 Weixin 分享形式推文信息
{p_end}

{synopt:{cmdab:wu:rl}}
输出第3种 Weixin 分享形式推文信息
{p_end}

{synopt:{cmdab:clip}}
点击超链接可以剪切分享推文，与 Wlink 搭配使用
{p_end}

{synopt:{cmdab:n:um(#)}}
指定要列出的最新推文的数量；N(10)是默认值。
与 songbl new 搭配使用
{p_end}

{synopt:{cmdab:n:avigation}}
用于打开导航目录的选择项， 更多导航目录能详看：songbl all
{p_end}

{synopt:{cmdab:save(str)}}
save 选项将利用 txt/md/docx等格式的文档来打开分享的内容。
{p_end}

{synopt:{cmdab:replace}}
作用同 save 选项，replace 选项将生成分享内容的 STATA 数据集。
{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:songbl} 命令可以让用户在 Stata 命令窗口中轻松检索并打开几千篇来自微信公众号、爬虫俱乐部、连享会网站、经管之家等的Stata推文。资源仍在不断增加中.....


{marker Examples}{...}
{title:Examples}

{pstd}分类查看所有推文{p_end}

{phang2}. {stata "songbl"}{p_end} 

{pstd}按照资源更新时间来查看推文，默认设置为前10条{p_end}

{phang2}. {stata "songbl new "}{p_end} 

{pstd}同上，且以表格的形式呈现结果

{phang2}. {stata "songbl new,t"}{p_end} 

{pstd}同上，且在结果表格内部增加横线

{phang2}. {stata "songbl new,t l"}{p_end} 

{pstd}同上，但是空格一行打印

{phang2}. {stata "songbl new,g "}{p_end}

{pstd}输出标题中包含 [IV-GMM] 关键词的推文超链接{p_end}

{phang2}. {stata "songbl IV-GMM"}{p_end}

{pstd}输出来自连享会的推文超链接{p_end}

{phang2}. {stata "songbl PSM,auth(连享会)"}{p_end}

{pstd}输出来自爬虫俱乐部的推文超链接{p_end}

{phang2}. {stata "songbl 变量,auth(爬虫俱乐部)"}{p_end}

{pstd}不输出推文分类信息{p_end}

{phang2}. {stata "songbl DID,noc"}{p_end}

{pstd}清屏后输出结果{p_end}

{phang2}. {stata "songbl Stata绘图,c"}{p_end}

{pstd}支持大小写关键词的推文超链接检索{p_end}

{phang2}. {stata "songbl DiD"}{p_end}

{pstd}输出含有 [空间] 或者 [面板]  的推文超链接 (并集){p_end}

{phang2}. {stata "songbl 空间 + 面板 "}{p_end}

{pstd}输出含有关键词 [空间] [面板] (交集),且不包括 [数据] [stata] 的推文超链接 {p_end}

{phang2}. {stata "songbl 空间 面板,drop(数据 stata)"}{p_end}
 
{pstd}输含有关键词 [空间] ,且不包括 [面板] [数据] [stata] 的推文超链接{p_end}

{phang2}. {stata "songbl 空间 - 面板 -数据 - stata"}{p_end}
 
{pstd}结果同上{p_end}

{phang2}. {stata "songbl 空间,drop(面板 数据 stata)"}{p_end}

{pstd}以推文标题：URL的形式输出结果{p_end}

{phang2}. {stata "songbl did psm,w"}{p_end}

{pstd}点击超链接可以剪切分享推文，与 Wlink 搭配使用

{phang2}. {stata "songbl did psm,wlink clip "}{p_end}

{pstd}同 Wlink ，但输出的效果略有不同{p_end}

{phang2}. {stata "songbl did psm,wt"}{p_end}

{pstd}同上，但输出的效果略有不同{p_end}

{phang2}. {stata "songbl did psm,wu"}{p_end}

{pstd}三种输出方式进行比较{p_end}

{phang2}. {stata "songbl did psm,w wt wu cls"}{p_end}

{pstd}以 Markdown 格式输出推文链接{p_end}

{phang2}. {stata "songbl did psm, m"}{p_end}

{pstd}同上，但输出的效果略有不同{p_end}

{phang2}. {stata "songbl did psm, mt"}{p_end}

{pstd}同上，但输出的效果略有不同{p_end}

{phang2}. {stata "songbl did psm, mu"}{p_end}

{pstd}三种输出方式进行比较{p_end}

{phang2}. {stata "songbl did psm,m mt mu cls"}{p_end}

{pstd}不输出推文期刊来源信息{p_end}

{phang2}. {stata "songbl did psm, w  m noc"}{p_end}

{pstd}利用 txt 等文档打开分享的内容{p_end}

{phang2}. {stata "songbl did psm,w save(txt) "}{p_end}
{phang2}. {stata "songbl did psm,m save(md) "}{p_end}
{phang2}. {stata "songbl did psm,m save(docx) "}{p_end}
{phang2}. {stata "songbl did psm,m save(xls) "}{p_end}
{phang2}. {stata "songbl did psm,m save(do) "}{p_end}

{pstd}生成分享内容的 STATA 数据集{p_end}

{phang2}. {stata "songbl did psm,w replace"}{p_end}
{phang2}. {stata "songbl did psm,m replace"}{p_end}


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

{title:Acknowledgement}

{p}命令的编写思想来自 {help lianxh} 命令，在此表示感谢。
{p_end}


{title:Also see}

{synoptset 30 }{...}
{synopt:{help lianxh}} 
{p2colreset}{...}

{synoptset 30 }{...}
{synopt:{help songbl}} 
{p2colreset}{...} 


