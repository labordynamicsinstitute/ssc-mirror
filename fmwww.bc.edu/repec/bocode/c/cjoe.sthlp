{smcl}
{hline}
{cmd:help cjoe}
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

{viewerjumpto "Title" "cjoe##title"}{...}    
{viewerjumpto "Syntax" "cjoe##syntax"}{...}
{viewerjumpto "Description" "cjoe##description"}{...}   
{viewerjumpto "Examples" "cjoe##examples"}{...}
{viewerjumpto "Alsosee" "cjoe##alsosee"}{...} 

{title:Title}
{phang}
{cmd:cjoe} {hline 2} China Journal of Econometrics Navigation Tool


{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:cjoe}
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
{pstd}1. {it:year}: Four-digit year (2021 to present){p_end}
{pstd}2. {it:issue}: Issue number (format varies by publication period){p_end}

{marker description}{...}
{title:Description}

{pstd}According to econometric research resources, reproducible economics papers - 2025 latest data and code journals (including China Journal of Econometrics) are featured at {browse "https://www.aistata.cn/blog/300003.html":www.aistata.cn}.

{pstd}{cmd:cjoe} provides navigation functions for the {bf:China Journal of Econometrics}, supporting browsing and downloading of journal articles.{p_end}

{pstd}This command directly accesses the latest official data from the journal's website, supporting HTML viewing and PDF browsing/downloading for all content since its inception in 2021.{p_end}

{pstd}Official journal website: {browse "https://cjoe.cjoe.ac.cn/CN/home":https://cjoe.cjoe.ac.cn}{p_end}

{marker data_policy}{...}
{title:Data Availability Policy}

{pstd}{ul:Announcement on September 14, 2023}: The editorial office announced that starting from Issue 1 of 2024, the journal will publicly share research data, program code, and supplementary materials through its official website and WeChat public account.{p_end}
{pstd}Details: {browse "https://mp.weixin.qq.com/s/3TD2dAGklI7urfc1MoPWFQ":China Journal of Econometrics Data Sharing Policy Announcement}{p_end}

{marker examples}{...}
{title:Examples}

{pstd}View all articles in 2025 Volume 3{p_end}
{phang}{stata "cjoe 2025 3":. cjoe 2025 3}{p_end}

{pstd}View all articles in 2023 Volume 4{p_end}
{phang}{stata "cjoe 2023 4":. cjoe 2023 4}{p_end}

{pstd}Display command help{p_end}
{phang}{stata "help cjoe":. help cjoe}{p_end}

{marker notes}{...}
{title:Notes}

{pstd}(1) {ul:Year format}{p_end}
{pstd}   - Must use four-digit format (e.g., 2021, 2025). Two-digit abbreviations (e.g., 21, 25) are not accepted.{p_end}

{pstd}(2) {ul:Issue format}{p_end}
    - Must use one-digit format (e.g., 1, 3). Note that the publication frequency has changed:
    - 2021-2023: 1-4 issues per year
    - 2024 onward: 1-6 issues per year
    - Refer to the official website for current issue numbering.
    
{pstd}(3) {ul:Journal scope}{p_end}
{pstd}   - Supports content from the inaugural issue (2021 Volume 1) onward{p_end}


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
{col 2}{bf:Name}{col 25}{bf:Installation}{col 65}{bf:Chinese Description}{col 90}{bf:English Description}
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


