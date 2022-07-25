{smcl}
{* 15nov2016}{...}
{cmd:help hkstock}{right: }
{hline}

{title:Title}


{phang}
{bf:hkstock} {hline 2} Downloads stock names and stock codes for  Hong Kong's listed companies from Hong Kong Stock Exchange(https://www.so.studiodahu.com/wiki/%E9%A6%99%E6%B8%AF%E4%BA%A4%E6%98%93%E6%89%80%E4%B8%8A%E5%B8%82%E5%85%AC%E5%8F%B8%E5%88%97%E8%A1%A8).


{title:Syntax}

{p 8 18 2}
{cmdab:hkstock} {it: exchange}{cmd:,}
[{it:options}]

{synoptset 36 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt path(foldername)}}Specify a folder where output .dta files will be saved in{p_end}


{synoptline}
{p2colreset}{...}


{pstd}{it:exchange}  For each valid exchange, they represent different meanings of security markerts.Examples of Exchange and the names of the Exchange are as following: {p_end}
{pstd} {hi:GEM}:Hong Kong, Growth Enterprise Stocks  {p_end}
{pstd} {hi:MAIN}:Hong Kong, Main Board Stocks  {p_end}
{pstd} {hi:ALL}:Hong Kong:all stocks {p_end}


{pstd}You can download stock names and stock codes for all the listed firms if choosing {it: command all} markets {p_end}


{pstd}{it:path} specifies the folder where the output .dta files are to be saved. {p_end}
{pstd} The folders can be either existed or not. {p_end}
{pstd} If the folder specified does not exist, {cmd:cnstock} will create it automatically. {p_end}


{title:Examples}

{phang}
{stata `"hkstock GEM"'}
{p_end}

{pstd}
It will extract a list of all the stock codes and stock names for all the  Growth Enterprise Stocks in Hong Kong Stock Exchange.


{phang}
{stata `"hkstock ALL"'}
{p_end}

{pstd}
It will extract a list of all the stock codes and stock names for all the firms listed in Hong Kong Stock Exchange.

{phang}
{stata `"hkstock MAIN, path(D:/temp/)"'}
{p_end}

{pstd}
It will extract a list of all the stock codes and stock names for Main Board Stocks in Hong Kong Stock Exchange, with output files saving to folder D:/temp/.


{title:Authors}

{pstd}Chuntao LI{p_end}
{pstd}China Stata Club(爬虫俱乐部){p_end}
{pstd}Wuhan, China{p_end}
{pstd}chtl@zuel.edu.cn{p_end}

{pstd}Jiaqi LI{p_end}
{pstd}China Stata Club(爬虫俱乐部){p_end}
{pstd}Wuhan, China{p_end}
{pstd}1725455820@qq.com{p_end}






