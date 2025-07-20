{smcl}
{hline}
help jcufe
{hline}

{pstd}{vieweralsosee "cnuse" "net describe http://fmwww.bc.edu/repec/bocode/c/cnuse"}{break}
{vieweralsosee "topsis" "net describe http://fmwww.bc.edu/repec/bocode/t/topsis"}{break}
{vieweralsosee "log2md" "net describe http://fmwww.bc.edu/repec/bocode/l/log2md"}{break}
{vieweralsosee "sj1" "help sj1"}{break}
{vieweralsosee "baiduweather" "help baiduweather"}{break}
{vieweralsosee "gaodeweather" "help gaodeweather"}{break}
{vieweralsosee "cie" "help cie"}{break}               
{vieweralsosee "jqte" "help jqte"}{break}              
{vieweralsosee "cjoe" "help cjoe"}{break}              
{vieweralsosee "jcufe" "help jcufe"}{break}           
{vieweralsosee "cjs" "help cjs"}{break}                
{vieweralsosee "jce" "help jce"}{break}               
{vieweralsosee "jwe" "help jwe"}{break}                
{vieweralsosee "jjgl" "help jjgl"}{break}              
{vieweralsosee "" "--"}
{p_end}

{viewerjumpto "Title" "jcufe##title"}{...}    
{viewerjumpto "Syntax" "jcufe##syntax"}{...}
{viewerjumpto "Description" "jcufe##description"}{...}   
{viewerjumpto "Examples" "jcufe##examples"}{...}
{viewerjumpto "Alsosee" "jcufe##alsosee"}{...} 

{marker title}{...}
{title:Title}

{p2colset 5 16 16 2}{...}
{p2col:{hi: jcufe} {hline 2}}Journal of Central University of Finance & Economics Navigation Tool{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:jcufe}
{it:year}
{it:issue}
[{cmd:,}
{opt help}
]

{synoptset 20 tabbed}{...}
{synopthdr:Options}
{synoptline}
{synopt:{opt help}}Display this help documentation{p_end}
{synoptline}

{pstd}Parameters:{p_end}
{pstd}1. {it:year}: Four-digit year (2015 to present){p_end}
{pstd}2. {it:issue}: Issue number (integer between 1-12){p_end}

{marker description}{...}
{title:Description}

{pstd}{cmd:jcufe} provides navigation functions for the Journal of Central University of Finance & Economics, supporting browsing of article directories and direct access to papers in HTML and PDF formats.{p_end}

{pstd}This command parses data from the journal's official website, supporting HTML viewing and PDF browsing/downloading for all content since 2015.{p_end}

{p 4 4 2}{ul:Core features}:{p_end}
{pstd}• Displays complete article lists for specified issues{p_end}
{pstd}• Provides HTML online reading links for each article{p_end}
{pstd}• Provides PDF browsing/download links{p_end}

{marker examples}{...}
{title:Examples}

{pstd}View all articles in 2024 Volume 3{p_end}
{phang}{stata "jcufe 2024 3":. jcufe 2024 3}{p_end}

{pstd}View contents of 2024 Volume 12{p_end}
{phang}{stata "jcufe 2024 12":. jcufe 2024 12}{p_end}

{pstd}Display command help{p_end}
{phang}{stata "help jcufe":. help jcufe}{p_end}

{marker notes}{...}
{title:Notes}

{pstd}{ul:Year format}{p_end}
{pstd}Must use four-digit format (e.g., 2015, 2023). Two-digit abbreviations (e.g., 15, 23) are not accepted.{p_end}

{pstd}{ul:Issue format}{p_end}
{pstd}Input integer numbers (1-12) without zero-padding:{p_end}
{pstd}   - Correct: {stata jcufe 2024 1}{p_end}
{pstd}   - Incorrect: {stata jcufe 2024 01} (01 format not supported){p_end}

{pstd}{ul:Journal scope}{p_end}
{pstd}Supports content from Volume 1 of 2015 onward. Earlier issues are not supported.{p_end}

{pstd}{ul:Solution for HTTP 500error prompts}{p_end}
{pstd}When you click on a PDF link in the output results, if you see an error prompt saying 'HTTP Error 500 Internal Server Error' for specific years, please check whether that PDF is currently being downloaded. At this point, you can view the HTML webpage and then click 'View Full PDF' on the official website to see if an error occurs. Please refer to the official website for specific information.{p_end}

{title:Author & Questions and Suggestions}

{p 4 4 2}
{cmd:Wang Qiang}, Xi'an Jiaotong University, China{p_end}

{p 4 4 2}
    If you encounter any issues or have suggestions while using the tool, we will address them promptly. 
	
    Email: {browse "mailto:740130359@qq.com":740130359@qq.com}	

	
{marker alsosee}{...}
{title:Also see}
{p 4 4 2}

{p 4 8 2}The following is a navigation table of Stata external commands for Quantitative Economics:

{col 2}{hline 160}
{col 2}{bf:Name}{col 25}{bf:Installation}{col 65}{bf:Chinese Description}{col 100}{bf:English Description}
{col 2}{hline 160}

{col 2}{stata "help cnuse": cnuse}{col 25}{stata "net install cnuse, from(http://fmwww.bc.edu/repec/bocode/c/) replace": net install cnuse, replace}{col 65}网络数据资源下载使用{col 100}Download datasets from WeChat Public Accounts
{col 2}{hline 160}

{col 2}{stata "help topsis": topsis}{col 25}{stata "net install topsis, from(http://fmwww.bc.edu/repec/bocode/t/) replace": net install topsis, replace}{col 65}熵权法{col 100}Calculate scores with entropy/TOPSIS method
{col 2}{hline 160}

{col 2}{stata "help log2md": log2md}{col 25}{stata "net install log2md, from(http://fmwww.bc.edu/repec/bocode/l/) replace": net install log2md, replace}{col 65}Markdown格式log工作日志{col 100}Create enhanced Markdown logs
{col 2}{hline 160}

{col 2}{stata "help sj1": sj1}{col 25}{stata "ssc install sj1, replace": ssc install sj1, replace}{col 65}{browse "https://www.stata-journal.com/":Stata期刊杂志}{col 100}Stata Journal
{col 2}{hline 160}

{col 2}{stata "help baiduweather": baiduweather}{col 25}{stata "ssc install baiduweather, replace": ssc install baiduweather, replace}{col 65}百度地图天气查询{col 100}Query weather with Baidu Maps API
{col 2}{hline 160}

{col 2}{stata "help gaodeweather": gaodeweather}{col 25}{stata "ssc install gaodeweather, replace": ssc install gaodeweather, replace}{col 65}高德地图天气查询{col 100}Query weather with Amap API
{col 2}{hline 160}

{col 2}{stata "help cie": cie}{col 25}{stata "ssc install cie, replace": ssc install cie, replace}{col 65}{browse "https://ciejournal.ajcass.com//":中国工业经济}{col 100}China Industrial Economics Journal
{col 2}{hline 160}

{col 2}{stata "help jqte": jqte}{col 25}{stata "ssc install jqte, replace": ssc install jqte}{col 65}{browse "http://www.jqte.net/sljjjsjjyj/ch/index.aspx":数量经济技术经济研究}{col 100}Journal of Quantitative & Technological Economics
{col 2}{hline 160}

{col 2}{stata "help cjoe": cjoe}{col 25}{stata "ssc install cjoe, replace": ssc install cjoe, replace}{col 65}{browse "https://cjoe.cjoe.ac.cn/CN/home":计量经济学报}{col 100}China Journal of Econometrics
{col 2}{hline 160}

{col 2}{stata "help jcufe": jcufe}{col 25}{stata "ssc install jcufe, replace": ssc install jcufe, replace}{col 65}{browse "https://xbbjb.cufe.edu.cn/":中央财经大学学报}{col 100}Journal of Central University of Finance & Economics
{col 2}{hline 160}

{col 2}{stata "help cjs": cjs}{col 25}{stata "ssc install cjs, replace": ssc install cjs, replace}{col 65}{browse "https://www.society.shu.edu.cn/CN/1004-8804/home.shtml":社会}{col 100}Chinese Journal of Sociology
{col 2}{hline 160}

{col 2}{stata "help jce": jce}{col 25}{stata "ssc install jce, replace": ssc install jce, replace}{col 65}{browse "https://www.jcejournal.com.cn/CN/home":中国经济学}{col 100}Journal of China Economics
{col 2}{hline 160}

{col 2}{stata "help jwe": jwe}{col 25}{stata "ssc install jwe, replace": ssc install jwe, replace}{col 65}{browse "https://manu30.magtech.com.cn/sjjj/CN/home":世界经济}{col 100}Journal of World Economy
{col 2}{hline 160}

{col 2}{stata "help jjgl": jjgl}{col 25}{stata "ssc install jjgl, replace": ssc install jjgl, replace}{col 65}{browse "https://jjgl.ajcass.com/":经济管理}{col 100}Business Management Journal
{col 2}{hline 160}


{p 4 4 2}
Related resources: {browse "https://www.aistata.cn/blog.html":www.aistata.cn}

{hline}


