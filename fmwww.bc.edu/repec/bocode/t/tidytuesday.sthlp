{smcl}
{* 16February2025}{...}
{hi:help treecluster}{...}
{right:{browse "https://github.com/asjadnaqvi/stata-tidytuesday":tidytuesday v1.0 (GitHub)}}

{hline}

{title:tidytuesday}: A Stata package for fetching {browse "https://github.com/rfordatascience/tidytuesday":TidyTuesday}'s weekly challenge data.


{marker syntax}{title:Syntax}

{p 4 15 2}
{cmd:tidytuesday} [{cmd:get}], {cmd:[} {cmd:year({it:num})} {cmd:month({it:num})} {cmd:week({it:num})} {cmd:]}


The command has two possible uses. First:

{p 4 15 2}
{stata tidytuesday, year(2024)}

will generate a meta data table, with clickable links including the ability to directly load the data for a specific week.
This can be made more precise by also specifying the {opt month()} and {opt week()} options.

The second option is to directly fetch the data for a specific year and week combination:

{p 4 15 2}
{stata tidytuesday get, year(2025) week(3)}

Please note that weekly challenges might contain more than one file. The program will try to setup and 
clean the files and save them locally. There might be errors if unusual data structures are encountered.
In this case please check the repository and the raw data for details and for instructions on how to link multiple files.


{synoptline}
{p2colreset}{...}


{title:Examples}

See {browse "https://github.com/asjadnaqvi/stata-tidytuesday":GitHub} for examples.


{title:Feedback and issues}

Please submit bugs, errors, feature requests on {browse "https://github.com/asjadnaqvi/stata-tidytuesday/issues":GitHub} by creating a new issue.


{title:Package details}

Version      : {bf:tidytuesday} v1.0
This release : 16 Feb 2025
First release: 16 Feb 2025
Repository   : {browse "https://github.com/asjadnaqvi/stata-tidytuesday":GitHub}
Keywords     : Stata, data, tidytuesday
License      : {browse "https://opensource.org/licenses/MIT":MIT}

Author       : {browse "https://github.com/asjadnaqvi":Asjad Naqvi}
E-mail       : asjadnaqvi@gmail.com
Twitter/X    : {browse "https://twitter.com/AsjadNaqvi":@AsjadNaqvi}
BlueSky      : {browse "https://bsky.app/profile/asjadnaqvi.bsky.social":@asjadnaqvi.bsky.social}


{title:Other visualization packages}

{psee}
    {helpb alluvial}, {helpb arcplot}, {helpb bimap}, {helpb bumparea}, {helpb bumpline}, {helpb circlebar}, {helpb circlepack}, {helpb clipgeo}, {helpb delaunay}, 
	{helpb geoboundary}, {helpb geoflow}, {helpb graphfunctions}, {helpb marimekko}, {helpb polarspike}, {helpb ridgeline}, 
	{helpb sankey}, {helpb schemepack}, {helpb spider}, {helpb splinefit},
	{helpb streamplot}, {helpb sunburst}, {helpb ternary}, {helpb tidytuesday}, {helpb treecluster}, {helpb treemap}, {helpb trimap}, {helpb waffle}

or visit {browse "https://github.com/asjadnaqvi":GitHub}.

