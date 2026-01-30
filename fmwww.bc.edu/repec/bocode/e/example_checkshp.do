cd "D:\checkshp\checkshp"

local shp `"fujian.shp"'
local shp2 `"fuzhou_building.shp"' 
local tif_file `"DMSP-like2020.tif"'

checkshp "`shp'", detail clean

reprojshp "`shp'", crs(EPSG:3857)

reprojshp "`shp'", crs("`tif_file'")

areashp "`shp'",crs(EPSG:4534) save(temp.csv)

intershp "`shp'" with("`shp2'"), crs(EPSG:4534) group(Floor) 