{smcl}
{* 15Jan2021}{...}
{hi:help cntraveltime}
{hline}

{title:Title}

{phang}
{bf:cntraveltime} {hline 2} 
This Stata module helps to extract the travel distance and travel time between two locations from Baidu Map API(http://api.map.baidu.com).

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:cntraveltime}{cmd:,} baidukey(string) start_lat(varname) start_long(varname) end_lat(varname) end_long(varname) [{it:options}]


{marker description}{...}
{title:Description}

{pstd}
Baidu Map is widely used in China.
{cmd:cntraveltime} use Baidu Map API to extract the travel time and distance from one location to another.To be close to the real world,{cmd:cntraveltime} can calculate result with respect to different mode of transportation (car-driving, public transport and cycling) and perference of transportation (less walk, as quickly as possible ,etc). Forthermore, it can also extract the description of the traveling route.Before using this command, a Baidu key from Baidu Map API is needed.A typical Baidu key is an alphanumeric string.  You can get a secret key from Baidu Map's open platform (http://lbsyun.baidu.com).The process normally will take few minutes after you submit your application online.
{p_end}

{pstd}
{cmd:cntraveltime} requires Stata version 14 or higher.
{p_end}

{marker options}{...}
{title:options for cntraveltime}

{dlgtab:Credentials(required)}

{phang}
{opt baidukey(string)} is required before using this command. A typical Baidu Map API key is an alphanumeric string. Suppose the user already has a Baidu Map API key, which is, say, CH8eakl6UTlEb1OakeWYvofh;then, the baidukey() option must be specified as baidukey(CH8eakl6UTlEb1OakeWYvofh).
{p_end}

{phang}
{opt start_lat(varname)} & {opt start_long(varname)} specify the longitude and latitude of the origin location.  
{p_end}

{phang}
{opt end_lat(varname)} & {opt end_long(varname)} specify the longitude and latitude of the destination location.
{p_end}

{dlgtab:Search options}

{phang}
{opt detail}: If the user needs a detail information on the route chosen by {cmd:cntraveltime} , option {opt detail} helps. The default is not to show this information.
{p_end}

{phang}
{opt mode(string)} allows the user to choose different travel modes. It can be car, public or bike. The default choice is public transport. Baidu Map will calculate the travel distance and travel time between two specified locations upon your choice of transport mode, as the route for bicycle may be different from a car driving route. There will be an error message if users specify a transit mode other than car, public or bike, for example, subway
{p_end}

{phang}
{opt route_option(real)} can choose the detail preference when the given locations in the same cities. Please note that for different transport mode, the effective range and meaning of the route_option are also different. Enter the number in the option and the preferences represented by different numbers as follows. 
{p_end}
{pmore}
public 0: default, recommendation
{p_end}
{pmore}
public 1: less transit
{p_end}
{pmore}
public 2: less walk
{p_end}
{pmore}
public 3: no subway
{p_end}
{pmore}
public 4: as quickly as possible
{p_end}
{pmore}
public 5: subway
{p_end}
{pmore}
car 0: default
{p_end}
{pmore}
car 3: avoid high speed
{p_end}
{pmore}
car 4: high speed priority
{p_end}
{pmore}
car 5: avoid congested sections
{p_end}
{pmore}
car 6: avoiding toll stations
{p_end}
{pmore}
car 7: both 4 and 5
{p_end}
{pmore}
car 8: both 3 and 4
{p_end}
{pmore}
car 9: both 4 and 6
{p_end}
{pmore}
car 10: both 6 and 8 
{p_end}
{pmore}
car 11: both 3 and 6
{p_end}
{pmore}
bike 0: default, common
{p_end}
{pmore}
bike 1: electric bicycle
{p_end}

{phang}
{opt intercitytype(real)} can choose a more specific cross-city public transport. When the two locations are in different cities, the program will calculate the travel distance and travel time according to the selected transportation. If the two locations are in the same city, this option will not work. It should be noted that this option is only valid when the content of the mode () option is "public". This option accepts a number as a parameter, and the default is 0, the number specifies the mode of transportation where
{p_end}

{pmore}
0	: train
{p_end}
{pmore}
1	: plane
{p_end}
{pmore}
2	: bus
{p_end}



{phang}
{opt intercity_route_option(real)} represents the priority requirement for cross-city public transportation, the default is 0, the preferences represented by different numbers are as follows.
{p_end}

{pmore}
0	: as quickly as possible 
{p_end}
{pmore}
1	: start as early as possible
{p_end}
{pmore}
2	: as cheap as possible
{p_end}




{marker example}{...}
{title:Example}

{pstd}
Input the address

{phang}
{stata `"clear"'}
{p_end}
{phang}
{stata `"input double startlat double startlng double endlat double endlng"'}
{p_end}
{phang}
{stata `"28.18561 112.95033 39.99775 116.31616"'}
{p_end}
{phang}
{stata `"43.85427 125.30057 28.18561 112.95033"'}
{p_end}
{phang}
{stata `"31.85925 117.21600 33.01379 119.36848"'}
{p_end}
{phang}
{stata `"end"'} 
{p_end}

{pstd}
Extracts the detail information of drving between the two place.

{phang}
{stata `"cntraveltime, baidukey(your secret key) start_lat(startlat) start_long(startlng) end_lat(endlat) end_long(endlng) mode("car") detail route_option(4)"'}
{p_end}

{phang}
{stata `"list duration distance "'}
{p_end}


{pstd}
Extracts the detail information by bus between the two place.

{phang}
{stata `"cntraveltime, baidukey(your secret key) start_lat(startlat) start_long(startlng) end_lat(endlat) end_long(endlng) mode("public") detail route_option(4) intercitytype(1)  intercity_route_option(1)"'}
{p_end}

{phang}
{stata `"list duration distance "'}
{p_end}


{title:Author}

{pstd}Chuntao LI{p_end}
{pstd}China Stata Club(爬虫俱乐部){p_end}
{pstd}Wuhan, China{p_end}
{pstd}chtl@henu.edu.cn{p_end}

{pstd}Yuan Xue{p_end}
{pstd}China Stata Club(爬虫俱乐部){p_end}
{pstd}Wuhan, China{p_end}
{pstd}xueyuan19920310@163.com{p_end}

{pstd}Xueren Zhang{p_end}
{pstd}China Stata Club(爬虫俱乐部){p_end}
{pstd}Wuhan, China{p_end}
{pstd}snowmanzhang@whu.edu.cn{p_end}

