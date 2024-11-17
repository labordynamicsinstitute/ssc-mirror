

{smcl}
{cmd:help cnuse_cn {stata "help cnuse": 英文版本}}

{hline}

{title:标题}

{p2colset 5 16 16 2}{...}
{p2col:{hi:cnuse_cn}} 从“数量经济学”微信公众号、“计量经济学服务中心”微信公众号及其他网络数据源下载数据集。{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:语法}

{p 8 14 2}{cmd:cnuse_cn} [{it:文件名}] [{cmd:,} {cmdab:clear} {cmdab:nod} {cmdab:save} {cmdab:overwrite} {cmdab:url(}{it:"自定义链接"}{cmd:)}]

{synoptset 10}{...}
{synopthdr}
{synoptline}
{synopt:{cmdab:clear}} 加载新数据集前清空 Stata 的内存。{p_end}
{synopt:{cmdab:nod}} 加载数据集后不显示描述信息（默认会显示）。{p_end}
{synopt:{cmdab:save}} 将数据集保存到当前工作目录（可使用 {stata "pwd"} 查看当前目录）。{p_end}
{synopt:{cmdab:overwrite}} 如果文件已存在，允许覆盖。{p_end}
{synopt:{cmdab:url(}{it:"自定义链接"}{cmd:)}} 指定自定义下载链接。{p_end}
{synoptline}

{marker description}{...}
{title:描述}

{pstd}{cmd:cnuse_cn} 用于从“计量经济学服务中心”或“数量经济学”等资源中下载数据集。支持导入多种文件格式，包括 .dta、.xls、.xlsx、.txt、.csv、.shp 和 .zip。这些功能使 {stata "cnuse"} 比其他数据导入命令更为多样化。{p_end}

{pstd}如果数据集被声明为时间序列或面板数据，将自动运行 {stata "tsset"} 或 {stata "xtset"} 命令以显示这些特性。{p_end}

{pstd}对于 .zip 格式文件，{stata "cnuse"} 会自动解压并读取。{p_end}

{marker notes}{...}
{title:注意事项}

{pstd}(1) {cmd:cnuse_cn} 支持最新的空间数据格式，例如 .shp 文件。在导入 .shp 文件时，请确保同名的 .shp 和 .dbf 文件同时存在。可以参考 {stata "help sp"} 或 {stata "help spshape2dta"} 了解更多空间数据处理细节。{p_end}

{pstd}(2) 如果发生错误，请检查所提供的数据集链接或网址是否存在。{p_end}

{marker examples}{...}
{title:示例}

{phang}{stata "cnuse smoking.dta, clear"}{p_end}
{phang}{stata "cnuse auto.dta, clear"}{p_end}
{phang}{stata "cnuse auto.xls, clear"}{p_end}
{phang}{stata "cnuse auto.xlsx, clear"}{p_end}
{phang}{stata "cnuse auto.csv, clear"}{p_end}
{phang}{stata "cnuse nlsw88.zip, clear"}{p_end}
{phang}{stata "cnuse columbus.shp, clear"}{p_end}
{phang}{stata "cnuse smoking.dta, clear nodes"}{p_end}
{phang}{stata "cnuse   mroz.dta, url(https://gitee.com/econometric/data/blob/master/data01/)"}{p_end}
{phang}{stata "cnuse  apple.dta, url(https://www.stata-press.com/data/r18/)"}{p_end}
{phang}{stata "cnuse crime1.dta, url(http://fmwww.bc.edu/ec-p/data/wooldridge/)"}{p_end}



{title:Author}
{phang}
{cmd:Wang Qiang} ,   Xi’an Jiaotong University, China.{break}
E-mail: {browse "740130359@qq.com":740130359@qq.com}. {break}
{p_end}

{marker alsosee}{...}
{title:另见}

{psee}在线帮助：{help use}, {help webuse}, {help sysuse}, {help net get}, {help bcuse}（如果已安装）。{p_end}
