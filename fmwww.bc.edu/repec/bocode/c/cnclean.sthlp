{smcl}
{* *! version 1.0.0  2025}{...}
{viewerjumpto "语法" "cnclean##syntax"}{...}
{viewerjumpto "描述" "cnclean##description"}{...}
{viewerjumpto "选项" "cnclean##options"}{...}
{viewerjumpto "示例" "cnclean##examples"}{...}
{viewerjumpto "作者" "cnclean##author"}{...}

{title:Title}

{phang}
{bf:cnclean} {hline 2} 文本标准化处理程序


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:cnclean}
{varlist}
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:主要选项}
{synopt:{opt r:eplace}}替换原变量内容{p_end}
{synopt:{opt gen:erate(string)}}指定新变量名后缀（默认: _std）{p_end}

{syntab:文本处理选项}
{synopt:{opt trim}}去除首尾空格（默认执行）{p_end}
{synopt:{opt notrim}}不去除首尾空格{p_end}
{synopt:{opt spaces}}处理多余空格（默认执行）{p_end}
{synopt:{opt nospaces}}不处理多余空格{p_end}
{synopt:{opt fullwidth}}全角字符转半角（默认执行）{p_end}
{synopt:{opt nofullwidth}}不进行全角转半角{p_end}

{syntab:大小写转换}
{synopt:{opt lower}}转换为小写{p_end}
{synopt:{opt upper}}转换为大写{p_end}
{synopt:{opt proper}}首字母大写{p_end}

{syntab:高级选项}
{synopt:{opt punct}}标准化标点符号（中文标点转英文）{p_end}
{synopt:{opt tabs}}将制表符转换为空格{p_end}
{synopt:{opt newlines}}移除换行符{p_end}
{synopt:{opt special}}移除特殊字符{p_end}
{synopt:{opt digits}}统一数字格式（全角转半角）{p_end}
{synopt:{opt alpha}}统一字母格式（全角转半角）{p_end}
{synopt:{opt verbose}}显示详细处理信息{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:cnclean} 对字符串变量进行标准化处理，包括全角半角转换、空格处理、
大小写转换等多种文本清理功能。该程序特别适合处理中英文混合文本数据。

{pstd}
默认情况下，程序会执行以下操作：{p_end}
{p 8 12 2}• 全角字符转换为半角字符{p_end}
{p 8 12 2}• 多个连续空格替换为单个空格{p_end}
{p 8 12 2}• 去除字符串首尾的空格{p_end}

{pstd}
程序会自动跳过非字符串变量，并在处理时给出提示。


{marker options}{...}
{title:Options}

{dlgtab:主要选项}

{phang}
{opt replace} 直接替换原变量的内容。如果不指定此选项，程序会创建新变量。

{phang}
{opt generate(string)} 指定生成新变量的后缀。默认值为"_std"。
例如，如果原变量名为"text"，新变量将命名为"text_std"。

{dlgtab:文本处理选项}

{phang}
{opt trim}/{opt notrim} 控制是否去除字符串首尾的空格。默认执行trim。

{phang}
{opt spaces}/{opt nospaces} 控制是否处理多余空格。默认会将多个连续空格
替换为单个空格，并处理标点符号周围的不当空格。

{phang}
{opt fullwidth}/{opt nofullwidth} 控制是否将全角字符转换为半角字符。
这包括全角数字、字母和常用符号。默认执行转换。

{dlgtab:大小写转换}

{phang}
{opt lower} 将所有字母转换为小写。

{phang}
{opt upper} 将所有字母转换为大写。

{phang}
{opt proper} 将每个单词的首字母转换为大写（标题格式）。

{pstd}
注意：lower、upper和proper选项互斥，不能同时使用。

{dlgtab:高级选项}

{phang}
{opt punct} 标准化标点符号，将中文标点转换为对应的英文标点。
例如："。"转为"."，"，"转为","等。

{phang}
{opt tabs} 将制表符（\t）转换为空格。

{phang}
{opt newlines} 移除文本中的换行符（\n、\r、\r\n）。

{phang}
{opt special} 移除特殊字符，仅保留基本ASCII字符、中文字符和常用标点。

{phang}
{opt digits} 确保所有数字都是半角格式（包含在fullwidth选项中）。

{phang}
{opt alpha} 确保所有英文字母都是半角格式（包含在fullwidth选项中）。

{phang}
{opt verbose} 显示详细的处理过程信息，便于了解每步操作。


{marker examples}{...}
{title:Examples}

{pstd}基本用法：标准化单个变量{p_end}
{phang2}{cmd:. cnclean company_name}{p_end}

{pstd}替换原变量{p_end}
{phang2}{cmd:. cnclean address, replace}{p_end}

{pstd}处理多个变量并指定新变量后缀{p_end}
{phang2}{cmd:. cnclean name address phone, generate(_clean)}{p_end}

{pstd}转换为小写并处理标点{p_end}
{phang2}{cmd:. cnclean description, lower punct replace}{p_end}

{pstd}完整的文本清理{p_end}
{phang2}{cmd:. cnclean text_var, punct tabs newlines special verbose}{p_end}

{pstd}使用通配符处理所有文本变量{p_end}
{phang2}{cmd:. cnclean text*, replace upper}{p_end}

{pstd}仅进行全角转半角，不处理空格{p_end}
{phang2}{cmd:. cnclean chinese_text, nospaces notrim}{p_end}


{marker author}{...}
{title:Author}

{pstd}
Xiaokang Wu{break}
Nanjing University of Science and Technology{break}
Email: {browse "mailto:wuxk@njust.edu.cn"}{p_end}

{pstd}
cnclean.ado - 文本标准化处理程序{break}
Version 1.0.0{break}
2025年开发{p_end}

{marker also_see}{...}
{title:Also see}

{psee}
帮助：{help ustrregexra}, {help ustrtrim}, {help ustrlower}, 
{help ustrupper}, {help ustrtitle}

{psee}
相关：{help string functions}