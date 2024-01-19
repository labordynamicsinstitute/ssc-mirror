{smcl}
{* 20Dec2018}{...}
{hi:help cnkchart}
{hline}

{title:Title}

 {phang}
{bf:cnkchart} {hline 2} Draw a Candlestick Chart with the Chinese-listed stock code or index.

{title:Syntax}

{p 8 18 2}
{cmdab:cnkchart} {it:code(max=1 min=1)} {cmd:,} {it:[option]}

{marker description}{...}
{title:Description}

{pstd}{it:code} is a stock code or index code to be draw. For the code, there will be a Candlestick Chart as an output containing the trading information for that stock.{p_end}

{marker Option}{...}
{title:Option}


{phang}
{opt traday(string)} set a range of trading data.The default is (c(current_date),90), which stands for drawing a Candlestick Chart from [c(current_date)-90,c(current_date)].
{p_end}

{phang}
{opt filename(string)} set a file where the Candlestick Chart will be saved in. The default is (stkcd, gph), which stands for the results filename is stkcd, and the output format is gph. Users may have many choices for the output format.
{p_end}
    {pstd}Output format: following are some commonly used format{p_end}
    {pstd}ps PostScript.{p_end}
	{pstd}eps The EPS (Encapsulated PostScript).{p_end}
	{pstd}svg SVG (Scalable Vector Graphics).{p_end}
    {pstd}pdf PDF (Portable Document Format).{p_end}
    {pstd}png PNG (Portable Network Graphics).{p_end}
	{pstd}other {p_end}
	
{phang}
{opt week/month(string)} specify that the moving average is a weekly/monthly moving average, the default is a daily moving average. Note: unable to set both of options traday and week/month simultaneously.
{p_end}

{phang}
{opt index(string)} specify that the code is index code,the default is stock code. Users may have many choices to use a different index, for example：
{p_end}
    {pstd}000001 The Shanghai Composite Index.{p_end}
	{pstd}000002 The Shanghai A-Share Composite Index.{p_end}
	{pstd}000003 The Shanghai B-Share Composite Index.{p_end}
    {pstd}000300 CSI 300 Index.{p_end}
    {pstd}399001 Shenzhen Component Index.{p_end}
	{pstd}399003 Shenzhen B-Share Component Index.{p_end}
	{pstd}399005 Shenzhen small and mediam sized 100-firm Index.{p_end}	
	{pstd}399006 Shenzhen Growth Enterprise Market Index.{p_end}
	{pstd}399008 Shenzhen small and mediam sized 300-firm Index.{p_end}



{title:Example}

{phang}
{stata `"clear all"'}
{p_end}
{phang}
{stata `"cap mkdir e:/kchart"'}
{p_end}
{phang}
{stata `"cd e:/kchart"'}
{p_end}
{phang}
{stata `"cnkchart 1"'}
{p_end}
{phang}
{stata `"cnkchart 1,week"'}
{p_end}
{phang}
{stata `"cnkchart 1,month"'}
{p_end}
{phang}
{stata `"cnkchart 1,week index"'}
{p_end}
{phang}
{stata `"cnkchart 1, traday(2021-1-1,50)"'}
{p_end}
{phang}
{stata `"cnkchart 1, traday(2021-1-1,50) filename(1p)"'}
{p_end}
{phang}
{stata `"cnkchart 1, traday(2021-1-1,50) filename(1p,png)"'}
{p_end}


{title:Authors}

{pstd}Chuntao Li{p_end}
{pstd}China Stata Club(爬虫俱乐部){p_end}
{pstd}Wuhan, China{p_end}
{pstd}chtl@henu.edu.cn{p_end}

{pstd}Yizhuo Fang{p_end}
{pstd}China Stata Club(爬虫俱乐部){p_end}
{pstd}Kaifeng, China{p_end}
{pstd}yzhfang1@163.com{p_end}

{pstd}Dr. Muhammad Usman{p_end}
{pstd}UE Business School, Division of Management and Administrative Sciences, University of Education{p_end}
{pstd}Lahore, Pakistan{p_end}
{pstd}m.usman@ue.edu.pk{p_end}




