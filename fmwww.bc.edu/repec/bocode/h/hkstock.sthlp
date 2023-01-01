{smcl}
{* 12Nov2022}{...}
{cmd:help hkstock}{right: }
{hline}

{title:Title}


{phang}
{bf:hkstock} {hline 2} Downloads Security names and codes for Hong Kong listed companies from eastmoney.com.


{title:Syntax}

{p 8 18 2}
{cmdab:hkstock} {it: Family}{cmd:,}
[{it:options}]

{synoptset 36 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt path(foldername)}}Specify a folder where output .dta files will be saved in{p_end}
{synopt:{opt filename(name)}}Name the file according to the name entered{p_end}


{synoptline}
{p2colreset}{...}


{pstd}{it:Family} Family is Hong Kong's Securities Market category. For each valid Family, they represent different meanings of security markerts.You can enter in all uppercase or lowercase, or just capitalize the first letter.Examples of Family and the names of the Family are as following: {p_end}
{pstd} {hi:Stock}:all Hong Kong's Securities  {p_end}
{pstd} {hi:Main}:Hong Kong Main Board Stocks {p_end}
{pstd} {hi:Growth}:Hong Kong's Growth Enterprise Market Securities {p_end}
{pstd} {hi:ETF}:Hong Kong Stock Connect ETF Fund {p_end}
{pstd} {hi:H}:Stocks listed in Mainland and Hong Kong at the same time {p_end}
{pstd} {hi:Option}:Hong Kong Warrants {p_end}
{pstd} {hi:Index'}:Hong Kong Index {p_end}



{pstd}You can download stock names and stock codes for all the listed firms if choosing {it: hkstock All} markets {p_end}


{pstd}{it:path} specifies the folder where the output .dta files are to be saved. {p_end}
{pstd} The folders can be either existed or not. {p_end}
{pstd} If the folder specified does not exist, {cmd:hkstock} will create it automatically. {p_end}

{pstd}{it:filename} generates the filename according to the name entered {p_end}


{title:Examples}

{phang}
{stata `"hkstock stock"'}
{p_end}

{pstd}
It will extract a list of all the codes and names for the securities listed in Hong Kong.

{phang}
{stata `"hkstock Growth"'}
{p_end}

{pstd}
It will extract a list of all the stock codes and stock names for all the firms listed in Hong Kong's Growth Enterprise Market.

{phang}
{stata `"hkstock OPTION"'}
{p_end}

{pstd}
It will extract a list of all the stock codes and stock names for all the Hong Kong's Warrants.

{phang}
{stata `"hkstock Option etf"'}
{p_end}

{pstd}
It will extract a list of all the stock codes and stock names for all the Hong Kong's Warrants and ETF.

{phang}
{stata `"hkstock STOCK, path(D:/temp/) filename("stock")"'}
{p_end}

{pstd}
It will extract a list of all the codes and names for the securities listed in Hong Kong, with output files saving to folder D:/temp//stock.dta.



{title:Authors}

{pstd}Chuntao LI{p_end}
{pstd}China Stata Club(爬虫俱乐部){p_end}
{pstd}Wuhan, China{p_end}
{pstd}chtl@zuel.edu.cn{p_end}

{pstd}Xiuping Mao{p_end}
{pstd}China Stata Club(爬虫俱乐部){p_end}
{pstd}Wuhan, China{p_end}
{pstd}xiuping_mao@126.com{p_end}

{pstd}Tianyao Luo{p_end}
{pstd}China Stata Club(爬虫俱乐部){p_end}
{pstd}Business School, Xinjiang University, China{p_end}
{pstd}cnl1426@163.com{p_end}



