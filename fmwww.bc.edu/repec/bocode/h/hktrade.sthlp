{smcl}
{* 12Nov2022}{...}
{* Updated on Apr 20th, 2023}{...}
{cmd:help hktrade}{right: }
{hline}

{title:Title}


{phang}
{bf:hktrade} {hline 2} Downloads historical stock transaction and warrants records for Hong Kong listed companies from Eastmoney.com. You can specify the frequency of transaction data through option fqt().

{title:Syntax}

{p 8 18 2}
{cmdab:hktrade} {it: codelist}{cmd:,}
[{it:options}]

{synoptset 36 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt fqt(frequency)}}Specify transaction frequency. d or D stands for day, w or W stands for week, m or M stands for month{p_end}
{synopt:{opt path(foldername)}}Specify a folder where output .dta files will be saved in{p_end}
{synoptline}
{p2colreset}{...}

{title:Description}

{pstd}{cmd: hktrade} is used to download historical transaction and warrants records records for a list of Hong Kong public firms from Hong Kong Stock Exchange. The generated transaction data includes 10 trading indicators such as opening price, closing price, rise and fall, trading volume, etc.


{pstd}{it:code} In Hong Kong, stocks and warrants are coded in five digits, not tickers as in the United States. Examples of codes and the names are as follows: {p_end}

{pstd} {hi:Stock Codes and Stock Names:} {p_end}
{pstd} {hi:00001} CK Hutchison Holdings Ltd. {p_end}
{pstd} {hi:00002} CLP Holdings Ltd. {p_end}
{pstd} {hi:80737} Shenzhen Investment Holdings Bay Area Development Company Limited. {p_end}
{pstd} {hi:25737} The warrant code(Changhe Societe Generale Siyi Purchase A) associated with CK Hutchison Holdings Ltd. {p_end}

{pstd}Note: The leading zeros in each code can be omitted. {p_end}
{pstd}{it:path} specifies the folder where the output .dta files are to be saved. The folder can be either existed or a new folder. If the folder specified does not exist, {cmd: hktrade} will create it automatically.{p_end}
{pstd}{it:fqt} specifies transaction frequency, default is d. d or D stands for day, w or W stands for week, m or M stands for month.{p_end}


{title:Examples}

{phang}
{stata `"hktrade 1,fqt(M)"'}
{p_end}

{pstd}
The Hong Kong stock code has a length of 5. If you enter an insufficient length, it will be recognized as the leftmost digit of the stock code(eg input 1 equals 00001), and then hkar will extract a list of all the transaction records for code you entered.

{phang}
{stata `"hktrade 00001,fqt(d)"'}
{p_end}

{pstd}
It will extract a list of all the transaction records for code you entered.

{phang}
{stata `"hktrade 1 99"'}
{p_end}  

{pstd}
It will extract various lists of all the transaction records for code you entered.

{phang}
{stata `"hktrade 80737,fqt(W) path(D:/temp)"'}
{p_end}

{pstd}
It will extract a list of all the transaction details for codes you entered, with output files saving to folder D:/temp/.

{phang}
{stata `"hktrade 25737,fqt(d)"'}
{p_end}  

{pstd}
It will obtain the daily-level transaction information of a warrant you entered.


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



