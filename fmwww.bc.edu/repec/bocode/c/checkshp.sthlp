{smcl}
{* 2025-01-10}{...}
{cmd:help checkshp} 

{title:Title}

{phang}
{bf:checkshp} {hline 2} Geometric validation and cleaning of Shapefiles

{title:Syntax}

{p 8 17 2}
{cmd:checkshp} {it:shpfile} [{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt :{opt d:etail}}Detailed output mode, containing detailed information for each invalid feature{p_end}
{synopt :{opt s:ummary}}Summary output mode, showing only statistical information (default){p_end}
{synopt :{opt c:lean}}Remove invalid geometric features and save to a new file{p_end}
{synoptline}

{p 4 6 2}
Note: Options {cmd:detail} and {cmd:summary} are mutually exclusive.


{title:Description}

{pstd}
{cmd:checkshp} validates the geometric validity of shapefiles and detects invalid geometric features. It can generate detailed or summary reports, and optionally clean invalid features by removing them and saving the cleaned shapefile to a new file.

{pstd}
The command checks for common geometric errors such as self-intersections, duplicate vertices, invalid rings, and other topology issues that may cause problems in spatial analysis or visualization.


{title:Examples}

{phang}
Check shapefile with summary output (default):

{p 12 16 2}
{cmd:. checkshp "fuzhou.shp"}{break}

{phang}
Check and clean invalid features:

{p 12 16 2}
{cmd:. checkshp "fuzhou.shp", detail clean}{break}


{title:Requirements}

{pstd}
{bf:Runtime environment requirements:}{p_end}
{phang2}• Java 17 or higher (automatically detected from Stata's Java configuration or system PATH){p_end}
{phang2}• checkshp-0.1.0.jar file (JAR package needs to be built first; automatically searched in current directory, build/libs, or Stata's ado directory){p_end}
{phang2}• All auxiliary files of the Shapefile (.shx, .dbf, .prj) must be in the same directory as the main file{p_end}


{title:Technical Details}

{pstd}
The command uses JTS (Java Topology Suite) and GeoTools libraries to validate geometry. It performs comprehensive checks on all features in the shapefile and reports any topology errors found. When {cmd:clean} is specified, invalid features are automatically removed using geometry fixing algorithms.


{title:Author}

{pstd}
Chunxia Chen{p_end}
{pstd}
School of Management, Xiamen University{p_end}
{pstd}
Email: triciachen6754@126.com{p_end}


{title:Also see}

{psee}
Online:  {help intershp}, {help reprojshp}, {help areashp}
{p_end}
