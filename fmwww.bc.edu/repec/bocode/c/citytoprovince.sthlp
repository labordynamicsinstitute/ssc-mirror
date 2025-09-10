{smcl}
{* *! version 1.0  07jan2025  Xiaokang Wu}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "destring" "help destring"}{...}
{vieweralsosee "encode" "help encode"}{...}
{vieweralsosee "merge" "help merge"}{...}
{viewerjumpto "Syntax" "citytoprovince##syntax"}{...}
{viewerjumpto "Description" "citytoprovince##description"}{...}
{viewerjumpto "Options" "citytoprovince##options"}{...}
{viewerjumpto "Remarks" "citytoprovince##remarks"}{...}
{viewerjumpto "Examples" "citytoprovince##examples"}{...}
{viewerjumpto "Stored results" "citytoprovince##results"}{...}
{viewerjumpto "Author" "citytoprovince##author"}{...}
{title:Title}

{phang}
{bf:citytoprovince} {hline 2} 根据城市字段生成对应的省份字段


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:citytoprovince} {varname} [{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt gen:erate(newvar)}}创建名为 {it:newvar} 的新省份变量{p_end}
{synopt:{opt replace}}替换已存在的 {bf:province} 变量{p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2}
注：必须指定 {opt generate()} 或 {opt replace} 选项之一。


{marker description}{...}
{title:Description}

{pstd}
{cmd:citytoprovince} 根据包含中国城市名称的变量生成对应的省份（省/自治区/直辖市/特别行政区）名称。
该程序能够识别城市的全称和简称，自动处理各种行政级别后缀。

{pstd}
程序内置了完整的中国地级及以上行政区划映射表，包括：

{p 8 12 2}• 4个直辖市（北京、天津、上海、重庆）{p_end}
{p 8 12 2}• 23个省{p_end}
{p 8 12 2}• 5个自治区{p_end}
{p 8 12 2}• 2个特别行政区（香港、澳门）{p_end}
{p 8 12 2}• 所有地级市、自治州、地区、盟{p_end}


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt generate(newvar)} 创建一个名为 {it:newvar} 的新字符串变量，包含对应的省份名称。
如果指定的变量名已存在，程序将报错。

{phang}
{opt replace} 创建或替换名为 {bf:province} 的变量。如果 {bf:province} 变量已存在，
将先删除该变量再重新创建。

{pstd}
注意：{opt generate()} 和 {opt replace} 选项不能同时使用。


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:citytoprovince} 能够处理多种格式的城市名称：

{p 8 12 2}1. 完整名称：如"南京市"、"临夏回族自治州"{p_end}
{p 8 12 2}2. 去掉后缀的名称：如"南京"、"临夏"{p_end}
{p 8 12 2}3. 常用简称：如"乌市"（乌鲁木齐）、"呼市"（呼和浩特）{p_end}

{pstd}
程序会自动去除以下后缀进行匹配：

{p 8 12 2}• 市、地区、盟{p_end}
{p 8 12 2}• 自治州及各种民族自治州全称{p_end}
{p 8 12 2}• 特别行政区{p_end}
{p 8 12 2}• 自治县{p_end}

{pstd}
对于无法匹配的城市名称，程序会保留空值并在结果中报告。


{marker examples}{...}
{title:Examples}

{pstd}基本使用：生成新的省份变量{p_end}
{phang2}{cmd:. citytoprovince city, generate(province_chn)}{p_end}

{pstd}替换已存在的province变量{p_end}
{phang2}{cmd:. citytoprovince city, replace}{p_end}

{pstd}完整示例：{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. input str20 city}{p_end}
{phang2}{cmd:  "南京市"}{p_end}
{phang2}{cmd:  "南京"}{p_end}
{phang2}{cmd:  "乌鲁木齐市"}{p_end}
{phang2}{cmd:  "乌市"}{p_end}
{phang2}{cmd:  "临夏回族自治州"}{p_end}
{phang2}{cmd:  "临夏"}{p_end}
{phang2}{cmd:  "香港特别行政区"}{p_end}
{phang2}{cmd:  "香港"}{p_end}
{phang2}{cmd:  end}{p_end}
{phang2}{cmd:. citytoprovince city, gen(province)}{p_end}
{phang2}{cmd:. list}{p_end}

{pstd}处理含有缺失值的数据：{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. gen city = "北京" if foreign == 0}{p_end}
{phang2}{cmd:. replace city = "上海" if foreign == 1}{p_end}
{phang2}{cmd:. citytoprovince city, gen(province)}{p_end}
{phang2}{cmd:. tab province foreign}{p_end}

{pstd}与其他命令结合使用：{p_end}
{phang2}{cmd:. use mydata, clear}{p_end}
{phang2}{cmd:. citytoprovince city_name, gen(prov)}{p_end}
{phang2}{cmd:. encode prov, gen(prov_code)}{p_end}
{phang2}{cmd:. bysort prov: gen prov_count = _N}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:citytoprovince} 在执行后显示匹配统计信息：

{p 8 12 2}• 成功匹配的记录数{p_end}
{p 8 12 2}• 未匹配的记录数{p_end}
{p 8 12 2}• 未匹配城市的列表（如果存在）{p_end}


{marker author}{...}
{title:Author}

{pstd}
Xiaokang Wu{break}
Nanjing University of Science and Technology{break}
Email: {browse "mailto:wuxk@njust.edu.cn"}{p_end}

{pstd}
citytoprovince.ado - 根据城市字段生成对应的省份字段{break}
Version 1.0.0{break}
2025年9月9日开发{p_end}


{marker alsosee}{...}
{title:Also see}

{psee}
帮助：{help encode}, {help decode}, {help merge}, {help replace}

{psee}
在线：{browse "https://www.stata.com":Stata官方网站}
{p_end}