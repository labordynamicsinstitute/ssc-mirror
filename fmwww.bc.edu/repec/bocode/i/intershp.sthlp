{smcl}
{* 2025-01-10}{...}
{cmd:help intershp} 

{title:Title}

{phang}
{bf:intershp} {hline 2} Calculate spatial intersection statistics between two Shapefiles

{title:Syntax}

{p 8 17 2}
{cmd:intershp} {it:shpfile1} {cmd:with(}{it:shpfile2}{cmd:)} [{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt :{opt crs(string)}}Coordinate reference system specification (required). Can be EPSG code (e.g., EPSG:3857 or 3857), TIF file path, or SHP file path{p_end}
{synopt :{opt merge}}Merge overlapping features of shp2 before intersection calculation (deduplication){p_end}
{synopt :{opt group(string)}}Group statistics by specified field of shp2{p_end}
{synoptline}

{p 4 6 2}
Note: {cmd:with()} is required and must be specified before the comma. {cmd:crs()} is required and must be specified.


{title:Description}

{pstd}
{cmd:intershp} calculates spatial intersection statistics between two shapefiles. It computes the intersection area statistics for features in the first shapefile that intersect with features in the second shapefile specified in {cmd:WITH()}.

{title:Examples}

{phang}
Calculate intersection statistics grouped by a field:

{p 12 16 2}
{cmd:. intershp "fuzhou.shp" with("fuzhou_building.shp"), crs(EPSG:3857) group("Floor")}{break}


{title:Requirements}

{pstd}
{bf:Runtime environment requirements:}{p_end}
{phang2}• Java 17 or higher (automatically detected from Stata's Java configuration or system PATH){p_end}
{phang2}• checkshp-0.1.0.jar file (JAR package needs to be built first; automatically searched in current directory, build/libs, or Stata's ado directory){p_end}
{phang2}• All auxiliary files of both Shapefiles (.shx, .dbf, .prj, etc.) must be in the same directory as the main file{p_end}


{title:Technical Details}

{pstd}
The command uses JTS (Java Topology Suite) and GeoTools libraries for spatial intersection calculations. The {cmd:crs()} option is required and specifies the coordinate reference system to use. The command projects both shapefiles to the specified coordinate system before performing intersection calculations.

{pstd}
The command uses STRtree spatial index to accelerate large-scale intersection calculations, making it efficient for processing large datasets with millions of features. Stream processing and batch merging strategies prevent memory overflow issues. The command automatically clips shp2 to shp1 bounds before intersection calculation, using spatial filtering to reduce the number of features processed, further optimizing memory usage for large shapefiles.


{title:Author}

{pstd}
Chunxia Chen{p_end}
{pstd}
School of Management, Xiamen University{p_end}
{pstd}
Email: triciachen6754@126.com{p_end}

{title:Also see}

{psee}
Online:  {help checkshp}, {help reprojshp}, {help areashp}
{p_end}
