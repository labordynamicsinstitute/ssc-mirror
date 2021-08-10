{smcl}
{* *! version 3.2 25mar2021}{...}
{cmd:help georoute}
{hline}


{title:Title}

{p 4 18 2}
{hi:georoute} {hline 2} Calculate travel distance and travel time
between two addresses or two points identified by their 
geographical coordinates.
{p_end}


{title:Syntax}

{phang}
Full command

{p 8 32 2}
{cmd:georoute} 
{ifin} 
{cmd:,} 
{opt herekey(API KEY)}
{c -(}{opth startad:dress(varlist)} {c |} {opt startxy(xvar yvar)}{c )-} 
{c -(}{opth endad:dress(varlist)} {c |} {opt endxy(xvar yvar)}{c )-} 
[ {it:options} ]


{phang}
Command with immediate arguments:{p_end}

{p 8 32 2}
{cmd:georoutei}
{cmd:,} 
{opt herekey(API KEY)}
{c -(}{opt startad:dress(string)} {c |} {cmd: startxy(}{it:#x}, {it:#y}{cmd:)}{c )-}
{c -(}{opt endad:dress(string)} {c |} {cmd: endxy(}{it:#x}, {it:#y}{cmd:)}{c )-} 
[ {it:options} ]


{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Compulsory arguments}
{syntab:{ul:HERE credentials}}
{p2coldent :+ {opt herekey(API KEY)}}API KEY of the HERE application to be used{p_end}
{syntab:{ul:Start points}}
{p2coldent :* {opth startad:dress(varlist)}}address of departure{p_end}
{p2coldent :or}{p_end}
{p2coldent :* {opt startxy(xvar yvar)}}coordinates of departure{p_end}
{syntab:{ul:End points}}
{p2coldent :* {opth endad:dress(varlist)}}address of destination{p_end}
{p2coldent :or}{p_end}
{p2coldent :* {opt endxy(xvar yvar)}}coordinates of destination{p_end}

{syntab:Routing options}
{p2coldent :* {opt tm:ode(string|varname)}}transport mode{p_end}
{p2coldent :* {opt rt:ype(string|varname)}}routing type{p_end}
{p2coldent :* {opt traf:fic(string|varname)}}traffic mode{p_end}
{p2coldent :* {opt dt:ime(string,mask|varname|"now")}}date and time of departure{p_end}
{synopt :{opt av:oid(string)}}avoid specific routing features{p_end}
{synopt :{opt soft:exclude(string)}}softly exclude specific routing features{p_end}
{synopt :{opt strict:exclude(string)}}strictly exclude specific routing features{p_end}

{syntab:New variables}
{p2coldent :° {opth di:stance(newvar)}}new variable to record travel distance{p_end}
{p2coldent :° {opth ti:me(newvar)}}new variable to record travel time{p_end}
{p2coldent :° {opth diag:nostic(newvar)}}new variable to record diagnostic code{p_end}
{p2coldent :° {opt co:ordinates(stub1 stub2)}}prefixes of new variables to record coordinates and match code{p_end}
{p2coldent :° {opt replace}}overwrite existing variables{p_end}

{syntab:Reporting}
{synopt :{opt km}}return travel distance in kilometers rather than in miles{p_end}
{p2coldent :° {opt timer}}print a timer to indicate evolution of geocoding{p_end}
{p2coldent :° {opt pause}}pause for 30 seconds after every 100th observation is geocoded{p_end}
{p2coldent :° {opt obs:ervations}}print a detailed observation account{p_end}
{synopt :{opt noset:tings}}suppress settings report{p_end}
{synoptline}
{pstd}
* These options only accept string arguments (no variables) when used with the immediate command {cmd:georoutei}.{break}
° These options are not available (irrelevant) with the immediate command {cmd:georoutei}.{break}
+ In HERE applications created before December 2019, credentials consisted of an APP ID and an APP CODE.
In earlier versions of {cmd:georoute}, the application credentials were therefore provided using 
{opt hereid(APP ID)} and {opt herecode(APP CODE)}. 
These options are still available but are not documented anymore as they might become obsolete in the future.
The same applies to {opt herepaid}.
See Weber & Péclat (2017) for more information.{p_end}


{title:Description}

{pstd}
{cmd:georoute} calculates the georouting distance between two addresses or two points identified by their geographical coordinates. It uses the HERE API ({browse "https://developer.here.com"}) to retrieve distances in two steps. 
In the first step, addresses are geocoded and their geographical coordinates (latitude and longitude) are obtained. 
In the second step, the georouting distance between the two points is calculated. 
The user can also provide directly geographical coordinates, which will bypass the first step. 
Most features offered by the HERE API are available as options. {break}

{pstd}
{cmd:georoutei} is an immediate version of {cmd: georoute}, i.e., a command in which all arguments must be typed in rather than included in variables (see {help immed}). 
{cmd:georoutei} is useful for quick interactive requests and preliminary checks.


{title:Requirements}

{pstd} Before using {cmd:georoute}, the user must register for a HERE account at {browse "https://developer.here.com"} and create an application that can be used with HERE APIs. The API KEY of the application must be provided via {cmd:herekey()}. 

{pstd} {cmd:georoute} requires a connection to the internet.

{pstd} {cmd:georoute} uses the user-written commands 
{cmd:insheetjson} and {cmd:libjson}. Type {stata ssc install insheetjson} 
and {stata ssc install libjson} to load the necessary packages. 


{title:Options}

{dlgtab:Main (compulsory)}

{phang}{opt herekey(API KEY)} is compulsory. 
It provides the credentials of the HERE application to be used.
See {browse "https://developer.here.com"} 
to create an application and obtain its API KEY.

{phang}{opth startaddress(varlist)} and {opth endaddress(varlist)}
specify the addresses of departure and destination. Addresses can be
inserted as a single variable or as a variable list. 
Alternatively, {opt startxy()} and {opt endxy()} can be used. 
Either {opt startaddress()} or {opt startxy()} is required. 
Either {opt endaddress()} or {opt endxy()} is required.

{phang2}Note: special characters (e.g., French accents) in addresses may cause the geocoding process to fail. 
Such characters should be transformed before running {cmd:georoute}, e.g., using {help subinstr()}.

{phang}{opt startxy(xvar yvar)} and {opt endxy(xvar yvar)} 
specify the geographical coordinates (in decimal degrees) 
of the departure and destination points. 
They can be used as an alternative to {opt startaddress()} and {opt endaddress()}. 
Two numeric variables containing latitude (x) and longitude (y) coordinates of the starting and 
ending points must be provided in {opt startxy()} and in {opt endxy()}.

{phang2}Note: latitude (x) must be between -90 and 90, 
and longitude (y) must be between -180 and 180. 
Examples of coordinates: {break}
- United States Capitol: 38.8897, -77.0089 {break} 
- Eiffel Tower: 48.8584, 2.2923 {break} 
- Cape Horn: -55.9859, -67.2743 {break} 
- Pearl Tower: 31.2378, 121.5225 


{dlgtab:Routing options}

{phang}{opt tmode(string|varname)} specifies the transport mode. 
The default is {opt tmode("car")}.{break}
Transport modes available (see 
{browse "https://developer.here.com/documentation/routing/topics/resource-param-type-routing-mode.html#type-transport-mode" :HERE documentation}): {break}
- {it:car}{break}
- {it:carHOV}{break}
- {it:pedestrian}{break}
- {it:publicTransport}{break}
- {it:publicTransportTimeTable}{break}
- {it:truck}{break}
- {it:bicycle}{break}

{phang2}Transport modes can be specified either via a string 
(for instance {opt tmode("car")}) or via a variable 
(for instance {opt tmode(vehicle)}). When a string is used, the same 
transport mode will be used for all observations. Using a variable makes 
it possible to specify transport mode at the observation level, in which case 
the variable must be a string variable composed of the transport modes typed 
exactly as above (mind the capitalized letters). Any missing values will 
be assigned the default transport mode ("car").

{phang}{opt rtype(string|varname)} specifies the routing type.
The default is {opt rtype("balanced")}.{break}
Routing types available are (see 
{browse "https://developer.here.com/documentation/routing/topics/resource-param-type-routing-mode.html#type-routing-type" :HERE documentation}):{break}
- {it:fastest}{break}
- {it:shortest}{break}
- {it:balanced}{break}

{phang2}Routing types can be abbreviated to a minimum of 1 letter: 'f' for {it:fastest}, 's' for {it:shortest}, 'b' for {it:balanced}. 

{phang2}Routing types can be specified either via a string 
(for instance {opt rtype("fastest")}) or via a variable 
(for instance {opt rtype(routing)}). 
When a string is used, the same routing type will be used for all observations. 
Using a variable makes it possible to specify routing type at the observation level, 
in which case the variable must be a string variable composed of the routing types 
indicated above (possibly abbreviated).
Any missing values will be assigned the default routing type ("{it:balanced}").

{phang}{opt traffic(string|varname)} specifies whether to optimize a route for traffic. 
The default is {opt traffic("default")}.{break}
Traffic modes available are
(see 
{browse "https://developer.here.com/documentation/routing/topics/resource-param-type-routing-mode.html#type-traffic-mode" :HERE documentation}):{break}
- {it:enabled}{break}
- {it:disabled}{break}
- {it:default}{break}

{phang2}Traffic modes can be abbreviated to a minimum of 2 letters: 'en' for {it:enabled}, 'di' for {it:disabled}, 'de' for {it:default}.

{phang2}Traffic modes can be specified either via a string 
(for instance {opt traffic("enabled")}) or via a variable 
(for instance {opt traffic(traf)}). 
When a string is used, the same traffic mode will be used for all observations. 
Using a variable makes it possible to specify traffic mode at the observation level,
in which case the variable must be a string variable composed of the traffic modes 
indicated above (possibly abbreviated).
Any missing values will be assigned the default traffic mode ("{it:default}").

{phang2}Note that traffic mode has no impact for 
transport modes "{it:pedestrian}" and "{it:bicycle}".

{phang}{opt dtime(string,mask|varname|"now")} specifies the 
date and time when travel is expected to start 
(see {browse "https://developer.here.com/documentation/routing/dev_guide/topics/example-time-aware-route.html" :HERE documentation}).
The default is {opt dtime("now")}, i.e., 
the current time as of running the calculation.

{phang2}Departure time can be specified either via a string and a mask 
(for instance {cmd:dtime}("01Jul2020 08:00:00", "DMYhms"); see {help clock}) or via a variable 
(for instance {opt dtime(t)}). 
When a string is used, the same departure time will be used for all observations. 
Using a variable makes it possible to specify departure time at the observation level, 
in which case the format of the variable must be %tc or %tC.
Any missing values will be assigned the default departure time ("{it:now}").

{phang2}Note that departure time has no impact for 
transport modes "{it:pedestrian}" and "{it:bicycle}".
The extent to which it is possible to calculate travel times in the past depends on other 
parameters, in particular the transport mode specified in {opt tmode()}.
It moreover seems that historical traffic data is not available from HERE API before 
January 2020, resulting in a travel time that is independent of departure time before then.

{phang}{opt avoid(string)}, {opt softexclude(string)} and 
{opt strictexclude(string)} specify routing features to be 
avoided / softly excluded / strictly excluded. 
Routing features available are (see 
{browse "https://developer.here.com/documentation/routing/dev_guide/topics/resource-param-type-routing-mode.html#type-route-feature" :HERE documentation}):{break}
- {it:tollroad}{break}
- {it:motorway}{break}
- {it:boatFerry}{break}
- {it:railFerry}{break}
- {it:tunnel}{break}
- {it:dirtRoad}{break}
- {it:park}{break}

{phang2}Routing features can be abbreviated to a minimum of 2 letters: 
'to' for {it:tollroad}, 'mo' for {it:motorway}, 'bo' for {it:boatFerry}, 
'ra' for {it:railFerry}, 'tu' for {it:tunnel}, 'di' for {it:dirtRoad}, 
'pa' for {it:park}.

{phang2}Note that putting restriction of feature "{it:park}" 
has no impact for transport modes other than "{it:pedestrian}" and "{it:bicycle}".


{dlgtab:New variables}

{phang}{opth distance(newvar)} creates the new variable {newvar} containing 
the travel distance between departure and destination points. 
If {opt distance()} is not specified, 
travel distance will be stored in a variable named {it:travel_distance}.

{phang}{opth time(newvar)} creates the new variable {newvar} containing 
the travel time between departure and destination points. 
If {opt time()} is not specified, travel time will be stored in a variable named {it:travel_time}.

{phang}{opth diagnostic(newvar)} creates the new variable {newvar} containing 
a diagnostic code for the geocoding and georouting outcome of each observation 
in the database: 
0 = OK, 
1 = No route found, 
2 = Start and/or end not geocoded, 
3 = Start and/or end coordinates missing, 
4 = No route searched.
If {opt diagnostic()} is not specified, the codes will be stored in a variable named {it:georoute_diagnostic}.

{phang}{cmd:coordinates(}{it:str1 str2}{cmd:)} creates new 
variables containing the coordinates and the match code of the 
starting ({it:str1_x},{it:str1_y},{it:str1_match}) 
and ending ({it:str2_x},{it:str2_y},{it:str2_match}) addresses. 
This option is irrelevant if geographical coordinates (rather than addresses) are 
provided for departure and destination points. 
The match code indicates how well the result matches the request 
in a 4-point scale: 
1 = exact, 
2 = ambiguous, 
3 = upHierarchy, 
4 = ambiguousUpHierarchy. 
If {opt coordinates()} is not specified, coordinates and match code will not be saved.

{phang}{opt replace} indicates that the variables in {cmd:distance()}, {cmd:time()},
{cmd:coordinates()}, and {cmd:diagnostic()} may be replaced if they already exist in the database. 
It should be used cautiously because it might definitively drop some data.


{dlgtab:Reporting}

{phang}{opt km} specifies that distances should be returned in kilometers. 
The default is to return distances in miles.

{phang}{opt timer} requests that a timer is printed while geocoding. If specified,
a dot is printed for every centile of the dataset that has been geocoded and 
a number is printed every 10%.

{phang}{opt pause} can be used to slow the geocoding process by asking Stata to 
sleep for 30 seconds every 100th observation. This could be useful for large databases,
which might overload the HERE API and result in missing values for batches of 
observations.

{phang}{opt observations} can be used to print a detailed observation account,
showing how many observations were discarded and why.

{phang}{opt nosettings} suppresses display of the settings report.


{title:Saved results}

{pstd}{cmd:georoute} saves results in different variables (see section "New variables" above).

{pstd}{cmd:georoutei} saves the following results in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(dist)}}Travel distance{p_end}
{synopt:{cmd:r(time)}}Travel time{p_end}
{synopt:{cmd:r(startx)}}x-coordinate (latitude) of departure point{p_end}
{synopt:{cmd:r(starty)}}y-coordinate (longitude) of departure point{p_end}
{synopt:{cmd:r(endx)}}x-coordinate (latitude) of destination point{p_end}
{synopt:{cmd:r(endy)}}y-coordinate (longitude) of destination point{p_end}


{title:Examples}

{pstd}Input some data{p_end}
{phang2}{cmd:. input str60 address1 str60 address2 str20 vehicle}{p_end}
{phang2}{cmd:. "Rue de la Tambourine 17, 1227 Carouge, Switzerland" "Rue Abram-Louis Breguet 2, 2000 Neuchatel, Switzerland" "car"}{p_end}
{phang2}{cmd:. "Rue de la Tambourine 17, 1227 Carouge, Switzerland" "Rue Abram-Louis Breguet 2, 2000 Neuchatel, Switzerland" "publicTransport"}{p_end}
{phang2}{cmd:. "Rue de la Tambourine 17, 1227 Carouge, Switzerland" "Rue Abram-Louis Breguet 2, 2000 Neuchatel, Switzerland" "bicycle"}{p_end}
{phang2}{cmd:. "1003 Lausanne, Switzerland" "74500 Evian, France" "car"}{p_end}
{phang2}{cmd:. "Paris, France" "New York, USA" "car"}{p_end}
{phang2}{cmd:. "1003 Lausanne, Switzerland" "1203 Geneva, Switzerland" "car"}{p_end}
{phang2}{cmd:. end}{p_end}

{pstd}Compute travel distances and travel times (use your own API KEY to run this example){p_end}
{phang2}{cmd:. global apikey 0wxsecZz7uLgpLTMuO5ae19dPx0RwparL1U91yxQOVE}{p_end}
{phang2}{cmd:. georoute, herekey("$apikey") startad(address1) endad(address2) km di(dist) ti(time) co(p1 p2)}{p_end}
{phang2}{cmd:. georoute, herekey("$apikey") startad(address1) endad(address2) km tmode(vehicle) traffic(enabled) observations}{p_end}

{pstd}Usage of the immediate command{p_end}
{phang2}{cmd:. georoutei, herekey("$apikey") startad("Rue de la Tambourine 17, 1227 Carouge, Switzerland") endad("Rue Abram-Louis Breguet 2, 2000 Neuchatel, Switzerland") km}{p_end}
{phang2}{cmd:. georoutei, herekey("$apikey") startxy(46.1761413, 6.1393099) endxy(46.99382, 6.94049) km}{p_end}


{title:Reference}

{pstd}Weber S & Péclat M (2017): "A simple command to calculate travel distance and travel time", {it:Stata Journal}, {bf:17}(4): 962-971 
({browse "http://www.stata-journal.com/article.html?article=dm0092"}).


{title:Authors}

{pstd}
Sylvain Weber{break}
University of Neuchâtel{break}
Institute of Economic Research{break}
Neuchâtel, Switzerland{break}
{browse "mailto:sylvain.weber@unine.ch?subject=Question/remark about -georoute-&cc=martin.peclat@unine.ch;august.warren@dc.gov":sylvain.weber@unine.ch}

{pstd}
Martin Péclat{break}
University of Neuchâtel{break}
Institute of Economic Research{break}
Neuchâtel, Switzerland{break}
{browse "mailto:martin.peclat@unine.ch?subject=Question/remark about -georoute-&cc=august.warren@dc.gov;sylvain.weber@unine.ch":martin.peclat@unine.ch}

{pstd}
August Warren{break}
Office of the State Superintendent of Education{break}
Washington, DC 20002, USA{break}
{browse "mailto:august.warren@dc.gov?subject=Question/remark about -georoute-&cc=martin.peclat@unine.ch;sylvain.weber@unine.ch":august.warren@dc.gov}
