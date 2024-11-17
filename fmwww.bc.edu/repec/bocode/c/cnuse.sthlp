
{smcl}
{cmd:help cnuse {stata "help cnuse_cn": 中文版本}}
{hline}

{title:Title}

{p2colset 5 16 16 2}{...}
{p2col:{hi:cnuse}} Download datasets from the Quantitative Economics WeChat Public Account, the Econometric Service Center WeChat Public Account, and other network data sources. {p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 14 2}{cmd:cnuse} [{it:filename}] [{cmd:,} {cmdab:clear} {cmdab:nod} {cmdab:save} {cmdab:overwrite} {cmdab:url(}{it:"custom_url"}{cmd:)}]

{synoptset 10}{...}
{synopthdr}
{synoptline}
{synopt:{cmdab:clear}} Clear Stata's memory before loading the new dataset. {p_end}
{synopt:{cmdab:nod}} Do not describe the dataset after loading. By default, the {cmd:describe} command is automatically issued after loading. {p_end}
{synopt:{cmdab:save}} Save the dataset in your current working directory (use {stata "pwd"} to check the current directory). {p_end}
{synopt:{cmdab:overwrite}} Overwrite the existing dataset file in your directory if the file already exists. {p_end}
{synopt:{cmdab:url(}{it:"custom_url"}{cmd:)}} Specify a custom URL to download the dataset from. {p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}{cmd:cnuse} is used to access datasets provided in blog posts from the Econometric Service Center or datasets mentioned in quantitative economics resources. The command can import various file formats including .dta, .xls, .xlsx, .txt, .csv, .shp, and .zip. This includes spatial data (.shp files), which makes {cmd:cnuse} unique compared to other importing commands. {p_end}

{pstd}If the dataset is declared as a time series or panel, the {stata "tsset"}  or {stata "xtset"}  command will be automatically issued to display those characteristics. {p_end}

{pstd}Datasets downloaded in .zip format will be automatically extracted and read into Stata. {p_end}

{marker notes}{...}
{title:Notes}

{pstd}(1) {cmd:cnuse} supports the latest spatial data formats, such as .shp files. When importing .shp files, ensure that both .shp and .dbf files with the same name are available. Use {stata "help sp"} or {stata "help spshape2dta"} for more details on handling spatial data. {p_end}

{pstd}(2) If an error occurs, verify whether the dataset exists on the specified source or URL. {p_end}

{marker examples}{...}
{title:Examples}

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
{cmd:Wang Qiang} ,  Xi’an Jiaotong University,China.{break}
E-mail: {browse "740130359@qq.com":740130359@qq.com}. {break}
{p_end}


{marker alsosee}{...}
{title:Also see}

{psee}Online: {help use}, {help webuse}, {help sysuse}, {help net get}, {help bcuse} (if installed).{p_end}


