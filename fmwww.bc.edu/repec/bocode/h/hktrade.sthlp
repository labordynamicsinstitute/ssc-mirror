{smcl}
{* 12Nov2022}{...}
{cmd:help hktrade}{right: }
{hline}

{title:Title}


{phang}
{bf:hktrade} {hline 2} Downloads historical stock or index transaction records for Hong Kong listed companies from Tencent.com.


{title:Syntax}

{p 8 18 2}
{cmdab:hktrade} {it: codelist}{cmd:,}
[{it:options}]

{synoptset 36 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt path(foldername)}}Specify a folder where output .dta files will be saved in{p_end}


{synoptline}
{p2colreset}{...}

{title:Description}

{pstd}{cmd: hktrade} is used to download historical transaction records for a list of Hong Kong public firms from Hong Kong Stock Exchange. 

{pstd}{it:code} In Hong Kong, stocks are coded in five digits, not tickers as in the United States. Examples of codes and the names are as follows: {p_end}

{pstd} {hi:Stock Codes and Stock Names:} {p_end}
{pstd} {hi:00001} CK Hutchison Holdings Ltd. {p_end}
{pstd} {hi:00002} CLP Holdings Ltd. {p_end}
{pstd} {hi:00395} Smartac International Holdings Limited {p_end}


{pstd}Note: The leading zeros in each code can be omitted. {p_end}

{pstd} {hi:Index Codes and Index Names:} {p_end}
{pstd} {hi:hkHSI} Hang Seng Index {p_end}
{pstd} {hi:hkHSCCI} Red Chip Index {p_end}
{pstd} {hi:hkHSCEI} State Enterprise Index {p_end}
{pstd} {hi:hkHSTECH} Hang Seng Technology Index {p_end}

{pstd}{it:path} specifies the folder where the output .dta files are to be saved. The folder can be either existed or a new folder. If the folder specified does not exist, {cmd: hktrade} will create it automatically.{p_end}



{title:Examples}

{phang}
{stata `"hktrade 1"'}
{p_end}

{pstd}
The Hong Kong stock code has a length of 5. If you enter an insufficient length, it will be recognized as the leftmost digit of the stock code(eg input 1 equals 00001), and then hkar will extract a list of all the transaction records for code you entered.

{phang}
{stata `"hktrade 00001"'}
{p_end}

{pstd}
It will extract a list of all the transaction records for code you entered.

{phang}
{stata `"hktrade 1 99"'}
{p_end}

{pstd}
It will extract various lists of all the transaction records for code you entered.

{phang}
{stata `"hktrade hkHSI"'}
{p_end}

{pstd}
It will obtain the historical transaction information of the Hang Seng Index.

{phang}
{stata `"hktrade 00395, path(D:/temp/)"'}
{p_end}

{pstd}
It will extract a list of all the transaction details for codes you entered, with output files saving to folder D:/temp/.



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



