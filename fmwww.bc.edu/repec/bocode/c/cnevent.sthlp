{smcl}
{* 20Dec2018}{...}
{hi:help cnevent}
{hline}

{title:Title}

 {phang}
{bf:cnevent} {hline 2} Module to carry out an eventstudy with Chinese publicly listed firms.

{title:Syntax}

{p 8 18 2}
{cmdab:cnevent} {it:varlist(max=2 min=2)} {cmd:,} {it:[option]}

{marker Option}{...}
{title:Option}

{phang}
{opt estw(numlist)}   Set the estimatimation window.The default is (-200,-10), which stands for an estimation window starts from the 200th tradding days before the event date and ends at the 10th tradding day before the event date.
{p_end}

{phang}
{opt eventw(numlist)}   Define the event window.The default choice is (-3,5), which stands for an event window from the 3rd trading day before the event date to the 5th trading day aftern the event date.
{p_end}

{phang}
{opt ar(string)}  Set an output variable name which stands for the Abnormal Return.The default is AR.
{p_end}

{phang}
{opt car(string)}  Set an output variable name which stands for the Cumulative Abnormal Return.The default is CAR.
{p_end}

{phang}
{opt index(string)}  Set index which stands for the market's daily return.The default is 300. users may have many choices to use different indeces. 
{p_end}
    {pstd}Index Codes: following are some commonly used indeces{p_end}
    {pstd}000001 The Shanghai Composite Index.{p_end}
	{pstd}000002 The Shanghai A-Share Composite Index.{p_end}
	{pstd}000003 The Shanghai B-Share Composite Index.{p_end}
    {pstd}000300 CSI 300 Index.{p_end}
    {pstd}399001 Shenzhen Component Index.{p_end}
	{pstd}399003 Shenzhen B-Share Component Index.{p_end}
	{pstd}399005 Shenzhen small and mediam sized 100-firm Index.{p_end}	
	{pstd}399006 Shenzhen Growth Enterprise Market Index. {p_end}
	{pstd}399008 Shenzhen small and mediam sized 300-firm Index.{p_end}
	


{phang}
{opt estsmpn(int)}  Set the minimum number which stands for the sample size within the estimate window.The default is 50. If there are less than 50 trading days in the estimation window, the event study for the underlying event will not be carried out due to insufficient samples
{p_end}

{phang}
{opt filename(string)} Set a results file where Abnormal Return and Cumulative Abnormal Return will be saved in. The default is CAR,replace.
{p_end}

{marker description}{...}
{title:Description}
   
{pstd}{it:cnevent} can carry out a standard market model event study. It calculates the abnormal returns and Cumulative abnormal returns for each event.
To run this command, you only need to load your event list into memory containing necessary variables. The event list contains a variable of event date that record the date when the event happens and a variable of event firm id which identifies the subject of each sample. For instance: 
{p_end}
	
{pstd}stkcd	  edate{p_end}
{pstd}000002  2014-04-14{p_end}
{pstd}600900  2015-04-14{p_end}
{pstd}000028  2016-04-14{p_end}
{pstd}600000  2016-03-14{p_end}
{pstd}601898  2018-05-21{p_end}
{pstd}601988  2013-02-05{p_end}
{pstd}601666  2019-09-17{p_end}


{pstd}After reading the event data, you have to specify the relative parameters to the event date to set the event window and estimate window. For example, you may choose (-200,-10) as the estimate window and (-3,5) as the event window, and then you may set parameters like this: ...estw(-200 -10) eventw(-3 5).
    In this command, we use the market model to calculate the abnormal return. A output file will be stored in CAR.dta or the file name you specified with the {it:cnevent} option. which contains variables of your event list, abnormal returns and and the Cumulative Abnormal Return. {p_end}

{title:Examples1}

{phang}
{stata `"clear all"'}
{p_end}
{phang}
{stata `"cap mkdir d:/eventstudy"'}
{p_end}
{phang}
{stata `"cd d:/eventstudy"'}
{p_end}
{phang}
{stata `"input stkcd str10 edate"'}
{p_end}
{phang}
{stata `"2 "2014-04-14""'}
{p_end}
{phang}
{stata `"600900 "2015-04-14""'}
{p_end}
{phang}
{stata `"600000 "2016-03-14""'}
{p_end}
{phang}
{stata `"601898 "2018-05-21""'}
{p_end}
{phang}
{stata `"601988 "2013-02-05""'}
{p_end}
{phang}
{stata `"300999 "2021-1-17"""'}
{p_end}
{phang}
{stata `"end"'}
{p_end}
{phang}
{stata `"cnevent stkcd edate"'}
{p_end}
{phang}
{stata `"cnevent stkcd edate,estsmpn(100)"'}
{p_end}
{phang}
{stata `"cnevent stkcd edate,index(1) estsmpn(100)"'}
{p_end}


{title:Examples2}

{phang}
{stata `"clear all"'}
{p_end}
{phang}
{stata `"cap mkdir d:/eventstudy"'}
{p_end}
{phang}
{stata `"cd d:/eventstudy"'}
{p_end}
{phang}
{stata `"cnstock all"'}
{p_end}
{phang}
{stata `"sample 5,count"'}
{p_end}
{phang}
{stata `"gen ed = "2021-11-11""'}
{p_end}
{phang}
{stata `"keep stkcd ed"'}
{p_end}
{phang}
{stata `"cnevent stkcd ed,estw(-190 -10) eventw(-3 3) ar(AR_k) car(CAR_k) index(1) estsmpn(150)  filename(myeventstudy,replace)"'}
{p_end}




{title:Authors}

{pstd}Chuntao Li{p_end}
{pstd}China Stata Club(爬虫俱乐部){p_end}
{pstd}Wuhan, China{p_end}
{pstd}chtl@henu.edu.cn{p_end}

{pstd}Yizhuo Fang{p_end}
{pstd}China Stata Club(爬虫俱乐部){p_end}
{pstd}Kaifeng, China{p_end}
{pstd}13608671126@163.com{p_end}
