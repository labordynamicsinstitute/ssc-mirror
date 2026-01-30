{smcl}
{* 2025-01-10}{...}
{cmd:help reprojshp} 

{title:Title}

{phang}
{bf:reprojshp} {hline 2} Reproject Shapefiles to specified coordinate systems

{title:Syntax}

{p 8 17 2}
{cmd:reprojshp} {it:shpfile} [{cmd:,} {it:options}]


{title:Description}

{pstd}
{cmd:reprojshp} reprojects shapefiles to a specified coordinate reference system (CRS). The target CRS can be specified using an EPSG code, by referencing a GeoTIFF file, or by referencing a Shapefile that contains the desired CRS information.

{pstd}
The reprojected shapefile is saved as a new file ({it:shpfile}_reproj.shp), preserving the original file.


{title:Options}

{phang}
{opt crs(crs_or_file)} is required and specifies the target coordinate system. The shapefile can be reprojected to:{p_end}
{phang2}• {bf:EPSG code}: For example, {cmd:crs(EPSG:4326)} or {cmd:crs(4326)} (EPSG: prefix is automatically added).{p_end}
{phang2}• {bf:GeoTIFF file path}: For example, {cmd:crs("C:/data/raster.tif")}, automatically reads the coordinate system from .tif/.tiff files.{p_end}
{phang2}• {bf:Shapefile path}: For example, {cmd:crs("C:/data/reference.shp")}, automatically reads the coordinate system from the .prj file of the specified shapefile.{p_end}


{title:Examples}

{phang}
Reproject shapefile to WGS84 (EPSG:4326):

{p 12 16 2}
{cmd:. reprojshp "fuzhou.shp", crs(EPSG:4326)}{break}

{phang}
Reproject shapefile using GeoTIFF file as reference:

{p 12 16 2}
{cmd:. reprojshp "fuzhou.shp", crs("DMSP-like2020.tif")}{break}


{title:Requirements}

{pstd}
{bf:Runtime environment requirements:}{p_end}
{phang2}• Java 17 or higher (automatically detected from Stata's Java configuration or system PATH){p_end}
{phang2}• checkshp-0.1.0.jar file (JAR package needs to be built first; automatically searched in current directory, build/libs, or Stata's ado directory){p_end}
{phang2}• All auxiliary files of the Shapefile (.shx, .dbf, .prj, etc.) must be in the same directory as the main file{p_end}


{title:Technical Details}

{pstd}
The command uses GeoTools library for coordinate reference system transformations. It automatically handles datum transformations and coordinate system conversions. When reprojecting geographic coordinate systems to projected coordinate systems, appropriate UTM zones or other suitable projections are selected automatically for accurate area calculations.


{title:Author}

{pstd}
Chunxia Chen{p_end}
{pstd}
School of Management, Xiamen University{p_end}
{pstd}
Email: triciachen6754@126.com{p_end}


{title:Also see}

{psee}
Online:  {help checkshp}, {help intershp}, {help areashp}
{p_end}