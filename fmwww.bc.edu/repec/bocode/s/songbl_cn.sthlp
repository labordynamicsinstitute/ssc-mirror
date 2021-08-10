{smcl}
{* *! version 4.0 *! Update: 2021/3/15 12:32}{...}
{cmd:help songbl}
{hline}

{title:Title}

{p2colset 5 16 16 2}{...}
{p2col:{hi: songbl} {hline 2}}在 Stata 命令窗口中对微信公众号、爬虫俱乐部、连享会网站等推文的关键词检索与结果输出。 
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}


{p 8 14 2}
{cmd:songbl}
{bind:[{it:keywords},}
{cmdab:m:link}
{cmdab:mt:ext}
{cmdab:mu:rl}
{cmdab:w:link}
{cmdab:wt:ext}
{cmdab:wu:rl}
{cmdab:noc:at}
{cmdab:p:aper}
{cmdab:g:ap}
{cmdab:t:ype(string) }
{cmdab:c:ls}
{cmdab:f:ile(string)}
{cmdab:n:avigation }
{cmdab:ti:me}
{cmdab:save}
{cmdab:replace}
{cmdab:s:ou}]]

{p 8 14 2}

{synoptset 14}{...}
{synopthdr:Options}
{synoptline}
{synopt:{cmdab:c:ls}}
清屏后显示结果
{p_end}
{synopt:{cmdab:noc:at}}
不输出推文分类信息
{p_end}
{synopt:{cmdab:g:ap}}
在输出的推文结果之间进行空格一行
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
{synopt:{cmdab:ti:me}}
输出检索结果后面带有返回推文分类目录或者论文分类目录的快捷方式
{p_end}
{synopt:{cmdab:p:aper}}
用于检索论文，输出论文超链接，用户可以输入 ：{stata "songbl paper "}浏览已有论文分类
{p_end}
{synopt:{cmdab:n:avigation}}
用于导航功能。例如打开《中国工业经济目录》 ：{stata "songbl cie,n "}.更多导航功能详看：{stata "songbl all"}
{p_end}
{synopt:{cmdab:t:ype(string)}}
按照推文来源进行检索，t(lxh)表示仅检索来自连享会的推文。 t(sc) 表示仅检索来自爬虫俱乐部的推文
{p_end}
{synopt:{cmdab:f:ile(string)}}
括号内为文档类型，包括 do/txt/docx/pdf 等。例如 file(do) 表示在 stata 打开以 .do 结尾的 do 文档推文
{p_end}
{synopt:{cmdab:save(string)}}
save 选项将利用文档来打开分享的内容，包括 txt/md/docx/doc/xls/xlsx/sas 等。建议使用 save(txt) 格式输出。
{p_end}
{synopt:{cmdab:replace}}
作用同 save 选项，replace 选项将生成分享内容的 STATA 数据集。使用 replace 选项将会导致已导进 STATA 的数据被清空替换成分享内容的 STATA 数据集
{p_end}
{synopt:{cmdab:s:ou}}
网页搜索功能，搜索来源包括计量圈、百度、微信公众号、经管之家、知乎。
{p_end}
{synoptline}
{marker description}{...}
{title:Description}

{pstd}
{opt songbl} 可以让用户在 Stata 命令窗口中轻松检索并打开几千篇来自微信公众号、爬虫俱乐部、连享会网站、经管之家等的Stata推文。
用户也可以分类浏览并下载几百篇来自 {browse "http://ciejournal.ajcass.org/":《中国工业经济》}   的论文与代码，以及几千篇来自《社会》、《金融研究》、《世界经济》、《劳动经济研究》
等期刊论文。资源仍在不断增加中.....


{marker Examples}{...}
{title:Examples}

{ul:新功能}

{pstd}利用 TXT 文档打开分享的内容{p_end}

{phang2}. {stata "songbl sj-9,w save(txt) paper"}{p_end}
{phang2}. {stata "songbl sj-9,m save(txt) paper"}{p_end}

{pstd}生成分享内容的 STATA 数据集。注意：使用 replace 选项将会导致已导进 STATA 的数据被清空替换成分享的内容 STATA 数据集{p_end}

{phang2}. {stata "songbl sj-9,w replace paper"}{p_end}
{phang2}. {stata "songbl sj-9,m replace paper"}{p_end}

{pstd}输出检索结果后面带有返回推文分类目录或者论文分类目录的快捷方式{p_end}

{phang2}. {stata "songbl PSM,time"}{p_end}

{ul:网页搜索功能}

{pstd} 网页搜索关于 DID 的资源 {p_end}

{phang2}. {stata "songbl DID,s"}{p_end}

{pstd} 网页搜索关于 PSM 的资源 {p_end}

{phang2}. {stata "songbl PSM,s"}{p_end}


{pstd} 搜索"计量圈"关于 DID 的资源：键入 "计量圈" 的任意字符{p_end}

{phang2}. {stata "songbl DID,s(计)"}{p_end}
{phang2}. {stata "songbl DID,s(量圈)"}{p_end}
{phang2}. {stata "songbl DID,s(计量圈)"}{p_end}

{pstd} 搜索"经管之家"关于 PSM 的资源：键入 "经管之家" 的任意字符{p_end}

{phang2}. {stata "songbl PSM,s(经)"}{p_end}
{phang2}. {stata "songbl PSM,s(管)"}{p_end}
{phang2}. {stata "songbl PSM,s(经管之家)"}{p_end}

{pstd} 同时搜索"计量圈、百度、微信公众号、经管之家、知乎"关于 "songbl" 的内容{p_end}

{phang2}. {stata "songbl songbl,s(all)"}{p_end}

{ul:导航功能}

{pstd} The Stata Journals {p_end}

{phang2}. {stata "songbl sj,n"}{p_end}

{pstd} 中国工业经济 {p_end}

{phang2}. {stata "songbl cie,n"}{p_end}

{pstd}songbl导航大全{p_end}

{phang2}. {stata "songbl all"}{p_end}

{pstd}推文主题分类导航{p_end}

{phang2}. {stata "songbl"}{p_end}

{pstd}浏览最近更新的推文

{phang2}. {stata "songbl new "}{p_end}

{pstd}知网经济学期刊分类导航{p_end}

{phang2}. {stata "songbl zw"}{p_end}

{pstd}常用STATA与学术网站导航{p_end}

{phang2}. {stata "songbl stata"}{p_end}

{pstd}常用社会科学数据库网站导航{p_end}

{phang2}. {stata "songbl data"}{p_end}

{pstd}可直接打开论文链接的期刊分类导航{p_end}

{phang2}. {stata "songbl paper"}{p_end}

{pstd}Stata科研之余，消遣放松网站导航{p_end}

{phang2}. {stata "songbl music"}{p_end}

{ul:基本功能}

{pstd}输出标题中包含 [IV-GMM] 关键词的推文超链接{p_end}

{phang2}. {stata "songbl IV-GMM"}{p_end}

{pstd}输出来自连享会的推文超链接{p_end}

{phang2}. {stata "songbl PSM,t(lxh)"}{p_end}

{pstd}输出来自爬虫俱乐部的推文超链接{p_end}

{phang2}. {stata "songbl 变量,t(sc)"}{p_end}

{pstd}输出 《金融研究》的论文超链接{p_end}

{phang2}. {stata "songbl 金融研究,p"}{p_end}

{pstd}输出标题中包含 [连享会历史文章] 关键词的推文超链接,并在stata打开以.do结尾的推文do文档{p_end}

{phang2}. {stata "songbl  连享会历史文章,f(do)"}{p_end}

{pstd}输出的推文结果之间空格一行{p_end}

{phang2}. {stata "songbl 日期,gap"}{p_end}

{pstd}不输出推文分类信息{p_end}

{phang2}. {stata "songbl DID,noc"}{p_end}

{pstd}清屏后输出结果{p_end}

{phang2}. {stata "songbl Stata绘图,c"}{p_end}

{pstd}支持大小写关键词的推文超链接检索{p_end}

{phang2}. {stata "songbl DiD"}{p_end}

{pstd}输出含有 [DID] 和 [倍分法] 的推文超链接 (交集){p_end}

{phang2}. {stata "songbl did 倍分法"}{p_end}

{pstd}输出含有 [空间] 、[面板] 和 [数据] 的推文超链接 (交集){p_end}

{phang2}. {stata "songbl 空间 面板 数据"}{p_end}

{pstd}输出含有 [空间] 或者 [面板]  的推文超链接 (并集){p_end}

{phang2}. {stata "songbl 空间 + 面板 "}{p_end}

{pstd}输出同时含有关键词 [空间计量] [stata] (交集),且不包括关键词 [面板] 的推文超链接 {p_end}

{phang2}. {stata "songbl 空间计量 stata - 面板 "}{p_end}
 

{ul:分享功能}

{pstd}以推文标题：URL的形式输出结果{p_end}

{phang2}. {stata "songbl Stata教程,w"}{p_end}

{pstd}同上，但输出的效果略有不同{p_end}

{phang2}. {stata "songbl Stata教程,wt"}{p_end}

{pstd}同上，但输出的效果略有不同{p_end}

{phang2}. {stata "songbl Stata教程,wu"}{p_end}

{pstd}三种输出方式进行比较{p_end}

{phang2}. {stata "songbl 倍分法DID pdf,w wt wu cls"}{p_end}

{pstd}以 Markdown 格式输出推文链接{p_end}

{phang2}. {stata "songbl DID pdf, m"}{p_end}

{pstd}同上，但输出的效果略有不同{p_end}

{phang2}. {stata "songbl DID 倍分法 pdf, mt"}{p_end}

{pstd}同上，但输出的效果略有不同{p_end}

{phang2}. {stata "songbl DID 倍分法 pdf, mu"}{p_end}

{pstd}三种输出方式进行比较{p_end}

{phang2}. {stata "songbl 倍分法 DID pdf,m mt mu cls"}{p_end}

{pstd}不输出推文分类信息{p_end}

{phang2}. {stata "songbl DID 倍分法, w  m noc"}{p_end}


{title:Author}

{phang}
{cmd:Bolin, Song (松柏林)} Shenzhen University, China. wechat：{cmd:songbl_stata}{break}
{p_end}


{title:Also see}

{synoptset 30 }{...}
{synopt:{help lianxh} (if installed)} {stata ssc install lianxh} (to install){p_end}
{p2colreset}{...}

