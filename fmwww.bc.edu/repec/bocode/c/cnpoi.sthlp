{smcl}
{* 25Feb2023}{...}
{cmd:help cnpoi}{right: }
{hline}

{title:Title}

{phang}
{bf:cnpoi} {hline 2} This Stata module helps to extract the specified information by keywords or types in a certain city.


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:cnpoi}{cmd:,} gaodekey(string) city(string) {keywords(string) types(string) path(string)} [{it:options}]

	
{marker description}{...}
{title:Description}

{pstd}
POI(Point of Interest) is the general name of one or some kind of things we are interested in,such as schools, hospitals, restaurants, high-speed railway stations, etc. 
Each POI usually contains name, address, category, coordinates and other informations.
These data and information are often of great significance in our research. Gaode Map API is widely used in China. 
{cmd:cnpoi} is used to get information about keywords which you are interested in in the city from Gaode Map API.  
The content of keywords or the types are specified by users.  
Before using this command, a Gaodekey secret key from Gaode Map API is needed.  
A typical Gaode secret key is an alphanumeric string ,and the option gaodekey(string) is necessary. If you have a Gaode key, which is, say 67ad42777daa5410afb96024, the gaodekey option must be specified as gaodekey(67ad42777daa5410afb96024).  
You can get a secret key from Gaode Map open platform (https://lbs.amap.com/). 
There are some information can be extracted when users using cnmapsearch.  
(1) The name of the place in the searching range.  
(2) The address and Latitude & Longitude of the place.
(3) The type of the place.
{p_end}

{pstd}
{cmd:cnpoi} require Stata version 17 or higher.
{p_end}


{marker options}{...}
{title:Options}

{phang}
{opt gaodekey(string)} is a required option before you using this command.
You can get a secret key from Gaodemap open platform(https://lbs.amap.com/). 
{p_end}

{phang}
{opt city(string)} is a required option when users using this command. 
This option determines the area you are searching, it can be a Prefecture-level city or a District or a county-level city. 
For example 武汉市 or 洪山区 or 随州市  You'd better use county-level cities and districts to search because it will be more accurate than Prefecture-level city.
{p_end}

{phang}
{opt keywords(string)} {opt types(string)} are two options determine the POI(the things that you are interested in ).
You must choose at least one  of them. For example, if you want to search the "美食", you can import keywords(美食). And you can also import types(餐饮服务),you must choose the types according the Gaode Map Classification Of POI. 
keywords and types support multiple searchs, and multiple keywords or types are separated by "|". 
For example, keywords(高铁站|机场|火车站) types(生活服务|汽车服务|餐饮服务) The types will be more accurate than keywords,so it is strongly recommended that you use the types according the Gaode Map Classification of POI. 
{p_end}
	
{phang}
{opt path(string)} specify a folder where output .dta files will be saved in, the folder can be either existed or a new folder. 
If the folder specified does not exist, hkar will create it automatically. 
If you don not add the option of path(string),the .dta is saved in your current working path by default.
  
  
{marker example}{...}
{title:Examples}

{phang}
{stata `"cnpoi,gaodekey(67ad42777daa5410afb96024) city(武汉市) keywords(肯德基|麦当劳|必胜客)"'}
{p_end}

{pstd} 
It will search by your keywords.

{phang}
{stata `"cnpoi,gaodekey(67ad42777daa5410afb96024) city(武汉市) types(快餐厅)"'}
{p_end}

{pstd} 
It will search by your types. And you must choose the types according the Gaode Map Of POI(https://developer.amap.com/api/webservice/guide/api/search).
   
{phang}
{stata `"cnpoi,gaodekey(67ad42777daa5410afb96024) city(武汉市) keywords(肯德基|麦当劳|必胜客) types(快餐厅)"'}
{p_end}

{pstd}
It will search by keywords and types. This method may be more accurate.
 
{phang}
{stata `"cnpoi,gaodekey(67ad42777daa5410afb96024) city(武汉市) keywords(肯德基|麦当劳|必胜客) types(快餐厅) path(D:\test)"'}
{p_end}

{pstd}
Specify a folder where output .dta files will be saved in. 
If you don not add the option of path(string),the .dta is saved in your current working path by default.

   
   
{title:Authors}

{pstd}Chuntao LI{p_end}
{pstd}China Stata Club(爬虫俱乐部){p_end}
{pstd}School of Finance, Zhongnan University of Economics and Law{p_end}
{pstd}Wuhan, China{p_end}
{pstd}chtl@zuel.edu.cn{p_end}

{pstd}Zeyuan Guo{p_end}
{pstd}China Stata Club(爬虫俱乐部){p_end}
{pstd}School of Finance, Zhongnan University of Economics and Law{p_end}
{pstd}Wuhan, China{p_end}
{pstd}guozeyuan4513@163.com{p_end}
	
{pstd}Kong Meng{p_end}
{pstd}China Stata Club(爬虫俱乐部){p_end}
{pstd}School of Finance, Zhongnan University of Economics and Law{p_end}
{pstd}Wuhan, China{p_end}
{pstd}mengkong147@163.com{p_end}



