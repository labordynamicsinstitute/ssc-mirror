{smcl}
{* 21Feb2024}{...}
{cmd:help hkprlink}{right: }
{hline}

{title:Title}


{phang}
{bf:hkprlink} {hline 2} Obtain and download disclosure reports from 1999-04-01 to now on the official website of the Hong Kong Stock Exchange.


{title:Syntax}

{p 8 18 2}
{cmdab:hkprlink}{it: codelist}{cmd:,}
[{it:options}]

{synoptset 36 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt path(foldername)}}Specify a folder where output files will be saved in. Chinese characters are not allowed in the path.{p_end}
{synoptline}
{p2colreset}{...}

{title:Description}


{pstd}{it:codelist} is a list of stock codes. In Hong Kong, stocks are identified by a five digit numbers. Examples of codes and the names are as follows: {p_end}

{pstd} {hi:Stock Codes and Stock Names:} {p_end}
{pstd} {hi:00001} CK Hutchison Holdings Ltd. {p_end}
{pstd} {hi:00002} CLP Holdings Ltd. {p_end}
{pstd} {hi:00099} WONG'S INTERNATIONAL HOLDINGS LIMITED {p_end}

{pstd}Note: The leading zeros in each code can be omitted. {p_end}

{pstd}{it:path} Specify a folder where output files will be saved in. The folder can be either existed or a new folder. If the folder specified does not exist, {cmd: hkprlink} will create it automatically.{p_end}



{title:Examples}

{phang}
{stata `"hkprlink 1"'}
{p_end}

{pstd}
The length of the Hong Kong stock code is 5. If the entered length is insufficient, it will be filled with 0 (for example, entering 1 equals 00001).

{phang}
{stata `"hkprlink 00001"'}
{p_end}

{pstd}
It will extract the link and name of the report for stock code 00001, and download all reports.

{phang}
{stata `"hkprlink 00001 00002"'}
{p_end}

{pstd}
It will extract the link and name of the report for stock codes 00001 and 00002, and download all reports.

{phang}
{stata `"hkprlink 00099, path(D:/temp/)"'}
{p_end}

{pstd}
It will extract the link and name of the report for stock codes 00099, and download all reports to the folder D:/temp/.



{title:Authors}

{pstd}Chuntao LI{p_end}
{pstd}China Stata Club(爬虫俱乐部){p_end}
{pstd}Wuhan, China{p_end}
{pstd}chtl@zuel.edu.cn{p_end}

{pstd}Tianyao Luo{p_end}
{pstd}China Stata Club(爬虫俱乐部){p_end}
{pstd}Xinjiang University Business School, China{p_end}
{pstd}cnl1426@163.com{p_end}

{pstd}Dr. Muhammad Usman{p_end}
{pstd}UE Business School, Division of Management and Administrative Sciences{p_end}
{pstd}University of Education, Lahore, Pakistan{p_end}
{pstd}m.usman@ue.edu.pk{p_end}

{pstd}Haitao Si{p_end}
{pstd}Wuhan University, China{p_end}
{pstd}sihaitao0114@163.com{p_end}




