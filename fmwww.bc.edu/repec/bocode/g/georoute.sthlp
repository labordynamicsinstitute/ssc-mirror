{smcl}
{* *! version 4.1 02aug2023}{...}
{cmd:help georoute}{right: ({browse "https://doi.org/10.1177/1536867X221083857":SJ22-1: dm0092_1})}
{hline}

{title:Title}

{p2colset 5 17 19 2}{...}
{p2col:{cmd:georoute} {hline 2}}Calculate travel distance and travel time
between two addresses or two points identified by their 
geographical coordinates{p_end}


{title:Syntax}

{p 8 16 2}
{cmd:georoute} 
{ifin}{cmd:,} 
{opt herekey(api_key)}
{c -(}{opth startad:dress(varlist)} | {opt startxy(xvar yvar)}{c )-} 
{c -(}{opth endad:dress(varlist)} | {opt endxy(xvar yvar)}{c )-} 
[{it:options}]


{phang}
Command with immediate arguments:{p_end}

{p 8 16 2}
{cmd:georoutei}{cmd:,} 
{opt herekey(api_key)}
{c -(}{opt startad:dress(string)} | {cmd:startxy(}{it:#x}{cmd:,} {it:#y}{cmd:)}{c )-}
{c -(}{opt endad:dress(string)} | {cmd:endxy(}{it:#x}{cmd:,} {it:#y}{cmd:)}{c )-} 
[{it:options}]


{synoptset 37 tabbed}{...}
{synopthdr}
{synoptline}
{syntab: Compulsory arguments}
{synopt: {opt herekey(api_key)}}API KEY of the HERE application to be used{p_end}
{p2coldent: * {opth startad:dress(varlist)}}address of departure{p_end}
{p2coldent: * {opt startxy(xvar yvar)}}coordinates of departure{p_end}
{p2coldent: * {opth endad:dress(varlist)}}address of destination{p_end}
{p2coldent: * {opt endxy(xvar yvar)}}coordinates of destination{p_end}

{syntab:Routing options}
{p2coldent: * {opt tm:ode(string|varname)}}transport mode{p_end}
{p2coldent: * {opt rt:ype(string|varname)}}routing type{p_end}
{p2coldent: * {cmdab:dt:ime(}{c -(}{it:string}{cmd:,}{it:mask}{c )-}|{it:varname}|{cmd:"now")}}date and time of departure{p_end}
{synopt: {opt av:oid(string)}}avoid specific routing features{p_end}

{syntab:New variables}
{p2coldent: ° {opth di:stance(newvar)}}new variable to record travel distance{p_end}
{p2coldent: ° {opth ti:me(newvar)}}new variable to record travel time{p_end}
{p2coldent: ° {opth diag:nostic(newvar)}}new variable to record diagnostic code{p_end}
{p2coldent: ° {opt co:ordinates(str1 str2)}}prefixes of new variables to record coordinates and query score{p_end}
{p2coldent: ° {opt replace}}overwrite existing variables{p_end}

{syntab:Reporting}
{synopt: {opt km}}return travel distance in kilometers rather than the default miles{p_end}
{p2coldent: ° {opt timer}}print a timer to indicate evolution of geocoding{p_end}
{p2coldent: ° {opt pause}}pause for 30 seconds after every 100th observation is geocoded{p_end}
{p2coldent: ° {opt obs:ervations}}print a detailed observation account{p_end}
{synopt: {opt noset:tings}}suppress settings report{p_end}
{synoptline}
{pstd}
* These options only accept string arguments (no variables) when used with the
immediate command {cmd:georoutei}.{break}
° These options are not available (irrelevant) with the immediate command
{cmd:georoutei}.{break}


{title:Description}

{pstd}
{cmd:georoute} calculates the georouting distance between two addresses or two
points identified by their geographical coordinates.  It uses the HERE API
({browse "https://developer.here.com"}) to retrieve distances in two steps.
In the first step, addresses are geocoded and their geographical coordinates
(latitude and longitude) are obtained.  In the second step, the georouting
distance between the two points is calculated.  The user can also directly
provide geographical coordinates, which will bypass the first step.  Most
features offered by the HERE API are available as options.

{pstd}
{cmd:georoutei} is an immediate version of {cmd: georoute}, that is, a command
in which all arguments must be typed in rather than included in variables (see
{help immed}).  {cmd:georoutei} is useful for quick interactive requests and
preliminary checks.


{title:Requirements}

{pstd}
Before using {cmd:georoute}, the user must register for a HERE account at
{browse "https://developer.here.com"} and create an application that can be
used with HERE APIs.  The API key of the application must be provided via
{cmd:herekey()}.

{pstd}
{cmd:georoute} requires a connection to the Internet.

{pstd}
{cmd:georoute} uses the community-contributed commands {cmd:insheetjson} and
{cmd:libjson}.  Type {bf:{stata ssc install insheetjson}} and
{bf:{stata ssc install libjson}} to load the necessary packages.


{title:Options}

{dlgtab:Main (compulsory)}

{phang}
{opt herekey(api_key)} provides the credentials of the HERE application to be
used.  {cmd:herekey()} is required.  See {browse "https://developer.here.com"}
to create an application and obtain its API key.

{phang}
{opth startaddress(varlist)} and {opth endaddress(varlist)} specify the
addresses of departure and destination, respectively.  Addresses can be
inserted as a single variable or a variable list.  Alternatively,
{cmd:startxy()} and {opt endxy()} can be used.  Either {opt startaddress()} or
{opt startxy()} is required; either {opt endaddress()} or {opt endxy()} is
required.

{pmore}
Note: Special characters (for example, French accents) in addresses may cause
the geocoding process to fail.  Such characters should be transformed before
running {cmd:georoute}, for example, by using {helpb subinstr()}.

{phang}
{opt startxy(xvar yvar)} and {opt endxy(xvar yvar)} specify the geographical
coordinates (in decimal degrees) of the departure and destination points,
respectively.  {it:xvar} and {it:yvar} must be numeric variables containing
latitude ({it:x}) and longitude ({it:y}) coordinates of the starting and
ending points.  Alternatively, {opt startaddress()} and {opt endaddress()} can
be used.  Either {opt startxy()} or {opt startaddress()} is required; either
{cmd:endxy()} or {opt endaddress()} is required.

{pmore}
Note: Latitude ({it:x}) must be between -90 and 90, and longitude ({it:y})
must be between -180 and 180.  Examples of coordinates:

{pmore}
- United States Capitol: 38.8897, -77.0089 {break} 
- Eiffel Tower: 48.8584, 2.2923 {break} 
- Cape Horn: -55.9859, -67.2743 {break} 
- Pearl Tower: 31.2378, 121.5225 

{dlgtab:Routing options}

{phang}
{opt tmode(string|varname)} specifies the transport mode.  The following
{it:string}s are available transport modes (see also 
{browse "https://developer.here.com/documentation/routing/topics/resource-param-type-routing-mode.html#type-transport-mode":HERE documentation}
for details): 

{pmore}
- {cmd:"car"} (default){break}
- {cmd:"publicTransit"}{break}
- {cmd:"pedestrian"}{break}
- {cmd:"bicycle"}{break}

{pmore}
The transport mode can be specified either via a string (for instance,
{cmd:tmode("car")}) or via a variable (for instance, {cmd:tmode(vehicle)}).
When a string is used, all observations will use the same transport mode.
When a variable is used,  it is possible to specify the transport mode at the
observation level, in which case the variable must be a string variable
composed of the transport modes exactly as above (including capitalization).
Any missing values will be assigned the default transport mode ({cmd:"car"}).

{phang}
{opt rtype(string|varname)} specifies the routing type.  The following
{it:string}s are available routing types (see also
{browse "https://developer.here.com/documentation/routing/topics/resource-param-type-routing-mode.html#type-routing-type":HERE documentation}
for details):

{pmore}
- {cmd:"}{cmdab:f:ast}{cmd:"} (default){break}
- {cmd:"}{cmdab:s:hort}{cmd:"}{break}

{pmore}
Routing types can be specified either via a string (for instance,
{cmd:rtype("fast")}) or via a variable (for instance, {cmd:rtype(routing)}).
When a string is used, all observations will use the same routing type.  When
a variable is used, it is possible to specify the routing type at the
observation level, in which case the variable must be a string variable
composed of the routing types exactly as above (possibly abbreviated).  Any
missing values will be assigned the default routing type ({cmd:"fast"}).

{phang}
{cmd:dtime(}{c -(}{it:string}{cmd:,}{it:mask}{c )-}|{it:varname}|{cmd:"now")}
specifies the date and time travel is expected to start (see also 
{browse "https://developer.here.com/documentation/routing/dev_guide/topics/example-time-aware-route.html":HERE documentation}
for details).  The default is {cmd:dtime("now")}, that is, the current time as
of running the calculation.

{pmore}
Departure time can be specified either via a string and a mask (for instance,
{cmd:dtime("01Nov2020 08:00:00", "DMYhms")}; see {help clock}) or via a
variable (for instance, {cmd:dtime(t)}).  When a string is used, all
observations will use the same departure time.  When a variable is used, it is
possible to specify the departure time at the observation level, in which case
the format of the variable must be {cmd:%tc} or {cmd:%tC}.  Any missing values
will be assigned the default departure time ({cmd:"now"}).

{pmore}
{cmd:dtime()} has no impact for transport modes {cmd:"pedestrian"} and
{cmd:"bicycle"}.  The extent to which it is possible to calculate travel times
in the past depends on other parameters, in particular, the transport mode
specified in {opt tmode()}.  Moreover, it seems that historical traffic data
are only available from the HERE API for a few months back, resulting in a
travel time independent of departure time for older time periods.

{phang}
{opt avoid(string)} can be used to specify routing features to be avoided.
The following {it:string}s are available routing features (see also
{browse "https://developer.here.com/documentation/routing/dev_guide/topics/resource-param-type-routing-mode.html#type-route-feature":HERE documentation}
for details):

{pmore}
- {cmd:"}{cmdab:to:llRoad}{cmd:"}{break}
- {cmd:"}{cmdab:fe:rry}{cmd:"}{break}
- {cmd:"}{cmdab:tu:nnel}{cmd:"}{break}
- {cmd:"}{cmdab:di:rtRoad}{cmd:"}

{dlgtab:New variables}

{phang}
{opth distance(newvar)} creates the new variable containing the travel
distance between the departure and destination points.  By default, travel
distance will be stored in a variable named {cmd:travel_distance}.

{phang}
{opth time(newvar)} creates the new variable containing the travel time
between the departure and destination points.  By default, travel time will be
stored in a variable named {cmd:travel_time}.

{phang}
{opth diagnostic(newvar)} creates the new variable containing a diagnostic
code for the geocoding and georouting outcome of each observation in the
database: {cmd:0} = {cmd:OK}, {cmd:1} = {cmd:No route found}, {cmd:2} =
{cmd:Start and/or end not geocoded}, {cmd:3} =
{cmd:Start and/or end coordinates missing}, and {cmd:4} =
{cmd:No route searched}.  By default, the codes will be stored in a variable
named {cmd:georoute_diagnostic}.

{phang}
{cmd:coordinates(}{it:str1 str2}{cmd:)} creates new variables
{it:str1}{cmd:_x}, {it:str1}{cmd:_y}, {it:str1}{cmd:_score},
{it:str2}{cmd:_x}, {it:str2}{cmd:_y}, and {it:str2}{cmd:_score}, which contain
the coordinates and the query score of the starting ({it:str1}{cmd:_x},
{it:str1}{cmd:_y}, {it:str1}{cmd:_score}) and ending ({it:str2}{cmd:_x},
{it:str2}{cmd:_y}, {it:str2}{cmd:_score}) addresses.  This option is
irrelevant if geographical coordinates (rather than addresses) are provided.
By default, coordinates and query score are not saved.  The query score is a value 
from 0 to 1 representing the percentage of the input that matched the returned address.

{phang}
{opt replace} specifies that the variables in {cmd:distance()}, {cmd:time()},
{cmd:diagnostic()}, and {cmd:coordinates()} be replaced if they already exist
in the database.  {cmd:replace} should be used cautiously because it might
definitively drop some data.

{dlgtab:Reporting}

{phang}
{opt km} specifies that distances be returned in kilometers.  The default is
to return distances in miles.

{phang}
{opt timer} requests that a timer be printed while geocoding.  If specified, a
dot is printed for every centile of the dataset that has been geocoded, and a
number is printed every 10%.

{phang}
{opt pause} slows the geocoding process by asking Stata to sleep for 30
seconds every 100th observation.  This could be useful for large databases,
which might overload the HERE API and result in missing values for batches of
observations.

{phang}
{opt observations} prints a detailed observation account, showing how many
observations were discarded and why.

{phang}
{opt nosettings} suppresses display of the settings report.



{title:Examples}

{pstd}Input some data{p_end}
{phang2}{cmd:. input str60 address1 str60 address2 str20 vehicle}{p_end}
{phang2}{cmd:. "Rue de la Tambourine 17, 1227 Carouge, Switzerland" "Rue Abram-Louis Breguet 2, 2000 Neuchatel, Switzerland" "car"}{p_end}
{phang2}{cmd:. "Rue de la Tambourine 17, 1227 Carouge, Switzerland" "Rue Abram-Louis Breguet 2, 2000 Neuchatel, Switzerland" "publicTransit"}{p_end}
{phang2}{cmd:. "Rue de la Tambourine 17, 1227 Carouge, Switzerland" "Rue Abram-Louis Breguet 2, 2000 Neuchatel, Switzerland" "bicycle"}{p_end}
{phang2}{cmd:. "1003 Lausanne, Switzerland" "74500 Evian, France" "car"}{p_end}
{phang2}{cmd:. "Paris, France" "New York, USA" "car"}{p_end}
{phang2}{cmd:. "1003 Lausanne, Switzerland" "1203 Geneva, Switzerland" "car"}{p_end}
{phang2}{cmd:. end}{p_end}

{pstd}Compute travel distances and travel times (use your own API key to run this example){p_end}
{phang2}{cmd:. global apikey 0wxsecZz7uLgpLTMuO5ae19dPx0RwparL1U91yxQOVE}{p_end}
{phang2}{cmd:. georoute, herekey("$apikey") startad(address1) endad(address2) km di(dist) ti(time) co(p1 p2)}{p_end}
{phang2}{cmd:. georoute, herekey("$apikey") startad(address1) endad(address2) km tmode(vehicle) observations}{p_end}

{pstd}Use the immediate command{p_end}
{phang2}{cmd:. georoutei, herekey("$apikey") startad("Rue de la Tambourine 17, 1227 Carouge, Switzerland") endad("Rue Abram-Louis Breguet 2, 2000 Neuchatel, Switzerland") km}{p_end}
{phang2}{cmd:. georoutei, herekey("$apikey") startxy(46.1761413, 6.1393099) endxy(46.99382, 6.94049) km}{p_end}


{title:Stored results}

{pstd}
{cmd:georoute} stores results in different variables (see section
{it:New variables} above).

{pstd}
{cmd:georoutei} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(dist)}}travel distance{p_end}
{synopt:{cmd:r(time)}}travel time{p_end}
{synopt:{cmd:r(startx)}}{it:x} coordinate (latitude) of departure point{p_end}
{synopt:{cmd:r(starty)}}{it:y} coordinate (longitude) of departure point{p_end}
{synopt:{cmd:r(endx)}}{it:x} coordinate (latitude) of destination point{p_end}
{synopt:{cmd:r(endy)}}{it:y} coordinate (longitude) of destination point{p_end}


{title:Authors}

{pstd}
Sylvain Weber{break}
University of Applied Sciences and Arts of Western Switzerland (HES-SO){break}
Geneva, Switzerland{break}
{browse "mailto:sylvain.weber@hesge.ch?subject=Question/remark about -georoute-&cc=martin.peclat@bluewin.ch;augustjwarren@gmail.com":sylvain.weber@hesge.ch}

{pstd}
Martin Péclat{break}
Romande Energie{break}
Morges, Switzerland{break}
{browse "mailto:martin.peclat@bluewin.ch?subject=Question/remark about -georoute-&cc=augustjwarren@gmail.com;sylvain.weber@unine.ch":martin.peclat@bluewin.ch}

{pstd}
August Warren{break}
Office of the State Superintendent of Education{break}
Washington, DC{break}
{browse "mailto:augustjwarren@gmail.com?subject=Question/remark about -georoute-&cc=martin.peclat@bluewin.ch;sylvain.weber@hesge.ch":augustjwarren@gmail.com}


{title:Also see}

{p 4 14 2}
Article:  {it:Stata Journal}, volume 22, number 1: {browse "https://doi.org/10.1177/1536867X221083857":dm0092_1},{break}
          {it:Stata Journal}, volume 17, number 4: {browse "https://doi.org/10.1177/1536867X1801700411":dm0092}{p_end}
