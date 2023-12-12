{smcl}
{* 16Oct2022}{...}
{hi:help cnborder}
{hline}

{title:Title}

{phang}
{bf:cnborder} {hline 2} Baidu Map API is widely used in China. By using the address, this STATA module aids in determining whether a point is on the boundary. To use this command, users need to install cngcode and cnaddress from SSC.

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:cnborder}{cmd:,} baidukey(string) address(string) [{it:options}]

{marker description}{...}
{title:Description}

{pstd}
{cmd:cnborder} uses the Baidu Map API address, and based on the provided address this command identifies the latitude, longitude, province, city, and county. Moreover, this command also finds eight different locations surrounding the provided address (i.e., east, west, north, south, northeast, northwest, southeast, and southwest). 
Finally, based on the said data, this command determines that the aforementioned eight places share the same province, city, or county as the center point (address), and this also indicates that the center point is not on the boundary.{p_end}

{pstd}
{cmd:cnborder} require Stata version 14 or higher. {p_end}

{pstd}
Detailed equations on how to calculate the eight points:{p_end}
{pstd}
east_latitude = center_latitude, eastlongitude=center_longitude + radius/(111*cos(center_latitude*_pi/180)).{p_end}
{pstd}
west_latitude = center_latitude, west_longitude=center_longitude - radius/(111*cos(center_latitude*_pi/180)).{p_end}
{pstd}
north_latitude = center_latitude + radius/111, north_longitude = center_longitude.{p_end}
{pstd}
south_latitude = center_latitude - radius/111, south_longitude = center_longitude.{p_end}
{pstd}
northeast_latitude = center_latitude + radius/2^0.5/111, northeast_longitude = center_longitude + radius/2^0.5/(111*cos((center_latitude + radius/2^0.5/111)*_pi/180)).{p_end}
{pstd}
northwest_latitude = center_latitude + radius/2^0.5/111, northwest_longitude = center_longitude - radius/2^0.5/(111*cos((center_latitude + radius/2^0.5/111)*_pi/180)).{p_end}
{pstd}
southeast_latitude = center_latitude - radius/2^0.5/111, southeast_longitude = center_longitude + radius/2^0.5/(111*cos((center_latitude + radius/2^0.5/111)*_pi/180)).{p_end}
{pstd}
southwest_latitude = center_latitude - radius/2^0.5/111, southwest_longitude = center_longitude - radius/2^0.5/(111*cos((center_latitude + radius/2^0.5/111)*_pi/180)).{p_end}



{marker options}{...}
{title:Options for cnborder}

{dlgtab:Credentials(required)}
{phang}
{opt baidukey(string)} is required before using this command. 
You can get a secret key from Baidumap open platform(http://lbsyun.baidu.com). 
The process normally will take 3-5 days after you submit your application online. {p_end}

{dlgtab:Address(required)}
{phang}
{opt address(string)}is the precise address of the center location. This STATA command extract the latitude, longitude, province, city, county, and eight different locations from the provided address.{p_end}

{dlgtab:Search options}
{phang}
{opt radius(int)}  is an optional factor, and the user can determine the radius around the center point. However, the default radius is 20 km. {p_end}

{dlgtab:Response switches}

{phang}
{opt province_border(newvar)} is string variable and user can specify the name of the outcome of province_borde. Default choice is province_border. {p_end}

{phang}
{opt city_border(newvar)} is string variable and user can specify the name of the outcome of city_border. Default choice is city_border. {p_end}

{phang}
{opt county_border(newvar)} is string variable and user can specify the name of the outcome of county_border. Default choice is county_border. {p_end}

{marker example}{...}
{title:Example}

{pstd}
Example 1, check whether those firms are located at regional border (within 20km, the default radius)


{phang}
{stata `"clear all"'}
{p_end}
{phang}
{stata `"input str80 company_address"'}
{p_end}
{phang}
{stata `""广东省深圳市盐田区大梅沙环梅路33号万科中心""'}
{p_end}
{phang}
{stata `""广东省广州市荔湾区沙面北街45号""'}
{p_end}
{phang}
{stata `""河南省漯河市双汇路1号双汇大厦""'}
{p_end}
{phang}
{stata `""山东省济南市历城区经十路2503号""'}
{p_end}
{phang}
{stata `""贵州省仁怀市茅台镇""'}
{p_end}
{phang}
{stata `""四川省宜宾市翠屏区岷江西路150号""'}
{p_end}
{phang}
{stata `"end"'}
{p_end}
{phang}
{stata `"local bdk your-secret-key"'}
{p_end}
{phang}
{stata `"cnborder,baidukey(`bdk') address(company_address)"'}
{p_end}


{pstd}
Example 2, check whether those firms are located at regional border within 5km, with radius(5) option


{phang}
{stata `"clear all"'}
{p_end}
{phang}
{stata `"input str80 company_address"'}
{p_end}
{phang}
{stata `""广东省深圳市盐田区大梅沙环梅路33号万科中心""'}
{p_end}
{phang}
{stata `""广东省广州市荔湾区沙面北街45号""'}
{p_end}
{phang}
{stata `""河南省漯河市双汇路1号双汇大厦""'}
{p_end}
{phang}
{stata `""山东省济南市历城区经十路2503号""'}
{p_end}
{phang}
{stata `""贵州省仁怀市茅台镇""'}
{p_end}
{phang}
{stata `""四川省宜宾市翠屏区岷江西路150号""'}
{p_end}
{phang}
{stata `"end"'}
{p_end}
{phang}
{stata `"local bdk your-secret-key"'}
{p_end}
{phang}
{stata `"cnborder,baidukey(`bdk') address(company_address) radius(5)"'}
{p_end}


{pstd}
Example 3, check whether those firms are located at regional border (within 20km, the default radius) but set variable names for the three outputs.


{phang}
{stata `"clear all"'}
{p_end}
{phang}
{stata `"input str80 company_address"'}
{p_end}
{phang}
{stata `""广东省深圳市盐田区大梅沙环梅路33号万科中心""'}
{p_end}
{phang}
{stata `""广东省广州市荔湾区沙面北街45号""'}
{p_end}
{phang}
{stata `""河南省漯河市双汇路1号双汇大厦""'}
{p_end}
{phang}
{stata `""山东省济南市历城区经十路2503号""'}
{p_end}
{phang}
{stata `""贵州省仁怀市茅台镇""'}
{p_end}
{phang}
{stata `""四川省宜宾市翠屏区岷江西路150号""'}
{p_end}
{phang}
{stata `"end"'}
{p_end}
{phang}
{stata `"local bdk your-secret-key"'}
{p_end}
{phang}
{stata `"cnborder,baidukey(`bdk') address(company_address) province_border(border1) city_border(border2) county_border(border3)"'}
{p_end}


{marker outcomes}{...}
{title:Outcomes}
{pstd}
There will be three binary (1/0) outcome of this Stata module (i.e., prov_border, city_border, and county_border). The value of 1 represents province/city/county is on the border of central point and 0 otherwise. {p_end}  

{title:Author}
{pstd}Chuntao LI{p_end}
{pstd}China Stata Club(爬虫俱乐部){p_end}
{pstd}Wuhan, China{p_end}
{pstd}chtl@zuel.edu.cn{p_end}

{pstd}Guangzhong Liu{p_end}
{pstd}China Stata Club(爬虫俱乐部){p_end}
{pstd}Kaifeng, China{p_end}
{pstd}liugz_henu@163.com{p_end}

{pstd}Muhammad Usman{p_end}
{pstd}Division of Management and Administrative Sciences, UE Business School, University of Education{p_end}
{pstd}Lahore, Pakistan{p_end}
{pstd}m.usman@ue.edu.pk{p_end}
