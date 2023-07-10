{smcl}
{cmd:help hkwarrant}{right: }
{hline}

{title:Title}


{phang}
{bf:hkwarrant} {hline 2} Download warrant or warrant's information associated with the codes you entered from Eastmoney.com. 

{title:Syntax}

{p 8 18 2}
{cmdab:hkwarrant} {it: codelist}{cmd:,}
[{it:options}]

{synoptset 36 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt path(foldername)}}Specify a folder where output .dta files will be saved in{p_end}
{synoptline}
{p2colreset}{...}

{title:Description}

{pstd}{cmd: hkwarrant} is used to download warrant or warrant's information associated with a list of Hong Kong public firms from Hong Kong Stock Exchange. The generated warrant information includes deadline, warrant name, strike price, exchange ratio, etc.


{pstd}{it:code} In Hong Kong, stocks are coded in five digits, not tickers as in the United States. Examples of codes and the names are as follows: {p_end}

{pstd} {hi:Stock Codes and Stock Names:} {p_end}
{pstd} {hi:00001} CK Hutchison Holdings Ltd. {p_end}
{pstd} {hi:00002} CLP Holdings Ltd. {p_end}
{pstd} {hi:80737} Shenzhen Investment Holdings Bay Area Development Company Limited {p_end}


{pstd}Note: The leading zeros in each code can be omitted. {p_end}
{pstd}{it:path} specifies the folder where the output .dta files are to be saved. The folder can be either existed or a new folder. If the folder specified does not exist, {cmd: hktrade} will create it automatically.{p_end}


{title:Examples}

{phang}
{stata `"hkwarrant 1"'}
{p_end}

{pstd}
The Hong Kong stock code has a length of 5. If you enter an insufficient length, it will be recognized as the left most digit of the stock code(eg input 1 equals 00001), and then hkwarrant will extract a list of warrant information associated with the codes you entered.

{phang}
{stata `"hkwarrant 1 , path(D:/temp)"'}
{p_end}

{pstd}
It will extract a list of warrant information associated with the codes you entered, with output files saving to folder D:/temp/.

{phang}
{stata `"hkwarrant 25737 "'}
{p_end}

{pstd}
Warrant information can also be obtained individually if the code is already known.

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



