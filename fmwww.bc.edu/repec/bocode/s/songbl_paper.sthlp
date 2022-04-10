{smcl}
{* *! version 1.0.0  14jun2019}{...}
{p2colset 1 21 21 2}{...}
{p2col:{bf:[D] songbl paper} {hline 2}}检索松柏林数据库中的论文{p_end}
{p2col:}({browse "https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com/ado/s/songbl.pdf":View complete PDF manual entry}){p_end}
{p2colreset}{...}
{pstd}


{marker syntax}{...}
{title:Syntax}


{p 4 14 2}
{cmd:songbl paper}
{bind:[{it:keywords},}
{cmdab:j:ournal(string)}
{cmdab:g:ap}
{cmdab:c:ls}
{cmdab:m:link}
{cmdab:mt:ext}
{cmdab:mu:rl}
{cmdab:w:link}
{cmdab:wt:ext}
{cmdab:wu:rl}
{cmdab:noc:at}
{cmdab:save}
{cmdab:replace}
{cmdab:clip}]

{p 8 16 2}

{synoptset 13}{...}
{synopthdr:Options}
{synoptline}
{synopt:{cmdab:c:ls}}
清屏后显示结果
{p_end}

{synopt:{cmdab:noc:at}}
不输出论文期刊来源信息
{p_end}

{synopt:{cmdab:j:ournal(str)}}
指定检索的期刊来源如 aer qje
{p_end}

{synopt:{cmdab:drop(str)}}
去除检索的关键词
{p_end}

{synopt:{cmdab:g:ap}}
在输出的论文结果之间进行空格一行
{p_end}

{synopt:{cmdab:m:link}}
输出第1种 Markdown 形式的论文信息
{p_end}

{synopt:{cmdab:mt:ext}}
输出第2种 Markdown 形式的论文信息
{p_end}

{synopt:{cmdab:mu:rl}}
输出第3种 Markdown 形式的论文信息
{p_end}

{synopt:{cmdab:w:link}}
输出第1种 Weixin 分享形式论文信息
{p_end}

{synopt:{cmdab:wt:ext}}
输出第2种 Weixin 分享形式论文信息
{p_end}

{synopt:{cmdab:wu:rl}}
输出第3种 Weixin 分享形式论文信息
{p_end}

{synopt:{cmdab:clip}}
点击超链接可以剪切分享论文，与 Wlink 搭配使用
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
{cmd:songbl dir} 命令可以实现对松柏林数据库中的论文进行关键词检索，会继续更新一些重点期刊的最新论文。


{marker Examples}{...}
{title:Examples}

{pstd}分类查看所有论文{p_end}

{phang2}. {stata "songbl paper "}{p_end} 

{pstd}输出 2015 年 aer 的论文超链接{p_end}

{phang2}. {stata "songbl paper 2015,j(aer)"}{p_end} 

{pstd}输出 《金融研究》的论文超链接{p_end}

{phang2}. {stata "songbl paper ,j(金融研究)"}{p_end} 

{pstd}输出 《金融研究》的期次超链接{p_end}

{phang2}. {stata "qui songbl paper ,j(金融研究)"}{p_end} 

{pstd}输出 《中国工业经济》企业出口的论文超链接{p_end}

{phang2}. {stata "songbl paper 企业出口,j(中国工业经济)"}{p_end} 

{pstd}输出 《中国工业经济》2021年第6期论文超链接{p_end}

{phang2}. {stata "songbl paper 2021 6,j(中国工业经济)"}{p_end} 

{pstd}同上，但是空格一行打印

{phang2}. {stata "songbl paper 2021 6,j(中国工业经济) g "}{p_end}

{pstd}不输出论文期刊来源{p_end}

{phang2}. {stata "songbl paper 经济,j(中国工业经济) noc "}{p_end}

{pstd}清屏后输出论文结果{p_end}

{phang2}. {stata "songbl paper 经济,j(金融研究) c"}{p_end}

{pstd}输出含有 [空间] 或者 [面板]  的论文超链接 (并集){p_end}

{phang2}. {stata "songbl paper 空间 + 面板,j(中国工业经济) "}{p_end}

{pstd}输出含有关键词 [空间计量] [stata] (交集),且不包括 [.pdf] 的论文超链接 {p_end}

{phang2}. {stata "songbl paper 空间 + 面板,drop(pdf) j(中国工业经济)"}{p_end}
 
{pstd}输出含有关键词 [中国工业经济] ,且不包括 [2021] [2020] [2019] 的论文超链接{p_end}

{phang2}. {stata "songbl paper 中国工业经济- 2021 - 2020 -2019,j(中国工业经济)"}{p_end}
 
{pstd}以论文标题：URL的形式输出结果{p_end}

{phang2}. {stata "songbl paper 2022,j(中国工业经济) w"}{p_end}

{pstd}点击超链接可以剪切分享论文，与 Wlink 搭配使用

{phang2}. {stata "songbl paper 2022,j(中国工业经济) wlink clip "}{p_end}

{pstd}同 Wlink ，但输出的效果略有不同{p_end}

{phang2}. {stata "songbl paper 2022,j(中国工业经济) wt"}{p_end}

{pstd}同上，但输出的效果略有不同{p_end}

{phang2}. {stata "songbl paper 022,j(中国工业经济) wu"}{p_end}

{pstd}三种输出方式进行比较{p_end}

{phang2}. {stata "songbl paper 2022,j(中国工业经济) w wt wu cls"}{p_end}

{pstd}以 Markdown 格式输出论文链接{p_end}

{phang2}. {stata "songbl paper 2022,j(中国工业经济) m"}{p_end}

{pstd}同上，但输出的效果略有不同{p_end}

{phang2}. {stata "songbl paper 2022,j(中国工业经济) mt"}{p_end}

{pstd}同上，但输出的效果略有不同{p_end}

{phang2}. {stata "songbl paper 2022,j(中国工业经济) mu"}{p_end}

{pstd}三种输出方式进行比较{p_end}

{phang2}. {stata "songbl paper 2022,j(中国工业经济)m mt mu cls"}{p_end}

{pstd}不输出论文期刊来源信息{p_end}

{phang2}. {stata "songbl paper 2022,j(中国工业经济) w  m noc"}{p_end}

{pstd}利用 txt 文档打开分享的内容{p_end}

{phang2}. {stata "songbl paper 2022,j(中国工业经济) w save(txt) "}{p_end}
{phang2}. {stata "songbl paper 2022,j(中国工业经济) m save(txt) "}{p_end}

{pstd}生成分享内容的 STATA 数据集{p_end}

{phang2}. {stata "songbl paper 2022,j(中国工业经济) w replace"}{p_end}
{phang2}. {stata "songbl paper 2022,j(中国工业经济) m replace"}{p_end}


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

