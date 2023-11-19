{smcl}
{* *! version 1.4 11Sep2023}{...}
{cmd:help lxhget}
{hline}

{pstd}

{title:Title}

{p2colset 5 16 16 2}{...}
{p2col:{hi: lxhget} {hline 2}}Download datasets of {browse "https://www.lianxh.cn":lianxh.cn} blogs or network , 
see {stata "help lianxh":help lianxh}.{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:lxhget}
[
{it:filename}  
{cmd:,}
{cmdab:d:esc}
{cmd:install}
{cmd:replace}
{cmdab:u:rl(string)} 
]

{p 2 8 2}

{synoptset 10}{...}
{synopthdr:Options}
{synoptline}
{synopt:{cmdab:desc}}
describe a package.
{p_end}
{synopt:{cmdab:install}}
install ado-files and help files from a package.
{p_end}
{synopt:{cmdab:replace}}
overwrite the datasets with same filename as the dataset loaded. 
{p_end}
{synopt:{cmdab:url()}}
specifies that the dataset will be download from {opt url} you provied. 
{p_end}
{synoptline}
{pstd}Notes:{p_end}
{pstd}(1) {cmd:lxhget} with no argument is used to list the datasets available.
{p_end}
{pstd}(2) {it:filename} must contain a suffix, such as .dta, .xlsx, .do, .rar, .txt, .csv, .pkg, etc files.
{p_end}
{pstd}(3) {opt url()} provide an easy way to download dataset from various sources. 
For example, the following commands are equivalent:{p_end}
{phang}{stata "lxhget jtrain.dta, url(http://fmwww.bc.edu/ec-p/data/wooldridge)" : . lxhget jtrain.dta, url(http://fmwww.bc.edu/ec-p/data/wooldridge)}{p_end}


{marker description}{...}
{title:Description}

{pstd} {cmd:lxhget} provides a easy way to download datasets of 
{browse "https://www.lianxh.cn":lianxh.cn} blogs or network. 

{pstd} These datasets can have various suffixes, such as .dta, xlsx, .do, .rar, .txt, .csv, .pkg, etc files.

{pstd} To get the aoe_test.zip, give the command{stata "lxhget aoe_test.zip" : lxhget aoe_test.zip}.

{pstd} If you receive an error message, check the {browse "https://gitee.com/arlionn/data/blob/master/data_dty.md":web page} listing these datasets.

{pstd}The .dta or .zip of .dta can be directely used through {stata "help lxhuse":lxhuse} command.


{title:Examples} 

{phang}{stata "lxhget" : . lxhget} // list datasets {p_end}
{phang}{stata "lxhget auto_test.dta" : . lxhget auto_test.dta}{p_end}
{phang}{stata "lxhget auto_test.zip" : . lxhget auto_test.zip}{p_end}
{phang}{stata "lxhget auto_test.xlsx, replace" : . lxhget auto_test.xlsx, replace}{p_end}

{phang}{stata "lxhget aoeplacebo.pkg" : . lxhget aoeplacebo.pkg} {space 9}//install ancillary files from a package {p_end}
{phang}{stata "lxhget aoeplacebo.pkg, des" : . lxhget aoeplacebo.pkg, des} {space 4}// describe installed packages {p_end}
{phang}{stata "lxhget aoeplacebo.pkg, install" : . lxhget aoeplacebo.pkg, install} //install ado-files and help files from a package {p_end}


{title:Acknowledgements}

{p 4 8 2}
Codes from {help bcuse} by Prof. C.F. Baum have been incorporated.


{title:Author}

{phang}
{cmd:Yujun, Lian} Lingnan College, Sun Yat-Sen University, China.{break}
E-mail: {browse "mailto:arlionn@163.com":arlionn@163.com}. {break}
Blog: {browse "https://www.lianxh.cn":lianxh.cn} {break}
{p_end}


{title:Other Commands}

{pstd}

{synoptset 30 }{...}
{synopt:{help lianxh} (if installed)} {stata ssc install lianxh} (to install){p_end}
{synopt:{help bdiff} (if installed)} {stata ssc install bdiff} (to install){p_end}
{synopt:{help lxhuse} (if installed)} {stata ssc install lxhuse} (to install){p_end}
{synopt:{help songbl} (if installed)} {stata ssc install songbl} (to install){p_end}
{synopt:{help xtbalance} (if installed)} {stata ssc install xtbalance} (to install){p_end}
{synopt:{help ihelp} (if installed)} {stata ssc install ihelp} (to install){p_end}
{p2colreset}{...}


{title:Also see}

{psee} 
Online:  
{help use}, 
{help webuse},
{help net get}, 
{help bcuse} (if installed).

