{smcl}
{* 01Apr2026}{...}
{hi:help vcontrol}{...}
{right:{browse "https://github.com/asjadnaqvi/stata-vcontrol":vcontrol v1.0 (GitHub)}}

{hline}

{title:vcontrol}: Version control command for Stata packages (beta)

{marker description}{title:Description}

{p 4 4 2}
{cmd:vcontrol} compares version dates of a Stata package available on SSC and GitHub (or a custom URL). 
It displays the distribution dates for both sources and identifies which version is newer.{p_end}

{p 4 4 2}
If the {opt update} option is specified, the latest version is automatically installed 
from the source with the more recent distribution date.{p_end}

{marker syntax}{title:Syntax}

{p 8 15 2}
{cmd:vcontrol} {it:package} [{cmd:,} {opt url(string)} {opt update} {opt replace}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{p2coldent:{opt package}}Name of the package to check (required).{p_end}

{syntab:Options}
{synopt:{opt url(string)}}Custom GitHub installation URL used to check and install the package. Default: {it:https://raw.githubusercontent.com/asjadnaqvi/stata-<package>/refs/heads/main/installation}.{p_end}
{synopt:{opt update}}Install the latest version after checking dates.{p_end}
{synopt:{opt replace}}Pass {cmd:replace} to {cmd:ssc install} or {cmd:net install} during update.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* {opt package} is required.{p_end}



{marker examples}{title:Examples}

{p 4 4 2}Check version of tidytuesday package:{p_end}
{p 8 8 2}{stata "vcontrol tidytuesday"}{p_end}

{p 4 4 2}Check and update if a newer version is available:{p_end}
{p 8 8 2}{stata "vcontrol tidytuesday, update"}{p_end}

{p 4 4 2}Update and force reinstallation when needed:{p_end}
{p 8 8 2}{stata "vcontrol tidytuesday, update replace"}{p_end}

{p 4 4 2}Check with custom GitHub installation URL:{p_end}
{p 8 8 2}{vcontrol mypackage, url(<some url>)}{p_end}

{title:Feedback}

Please submit bugs, errors, and feature requests on {browse "https://github.com/asjadnaqvi/stata-vcontrol/issues":GitHub} by opening a new issue.

{title:Citation guidelines}

Please cite the version you use (SSC or GitHub). The GitHub version may have updates not yet released on SSC.
Visit the {browse "https://github.com/asjadnaqvi/stata-vcontrol":GitHub repository} for the most up-to-date version.

{title:Package details}

Version      : {bf:vcontrol} v1.0
This release : 01 Apr 2026
First release: 16 Feb 2026
Repository   : {browse "https://github.com/asjadnaqvi/stata-vcontrol":GitHub}
Keywords     : Stata, version control, package management
License      : {browse "https://opensource.org/licenses/MIT":MIT}

Author       : {browse "https://github.com/asjadnaqvi":Asjad Naqvi}
E-mail       : asjadnaqvi@gmail.com
Twitter/X    : {browse "https://twitter.com/AsjadNaqvi":@AsjadNaqvi}
BlueSky      : {browse "https://bsky.app/profile/asjadnaqvi.bsky.social":@asjadnaqvi.bsky.social}


{title:Other visualization packages}
{psee}
    {helpb arcplot}, {helpb alluvial}, {helpb bimap}, {helpb bumparea}, {helpb bumpline}, {helpb circlebar}, {helpb circlepack}, {helpb clipgeo}, {helpb delaunay}, {helpb graphfunctions}, {helpb geoboundary}, {helpb geoflow}, {helpb joyplot}, 
	{helpb marimekko}, {helpb polarspike}, {helpb sankey}, {helpb schemepack}, {helpb spider}, {helpb splinefit}, {helpb streamplot}, {helpb sunburst}, {helpb ternary}, {helpb treecluster}, {helpb treemap},
    {helpb trimap}, {helpb vcontrol}, {helpb waffle}

Visit {browse "https://github.com/asjadnaqvi":GitHub} for further information.