pro def nca_centiles, rclass
syntax varlist (max=1) [if] [in], centiles(numlist)
marksample touse
tempname out 
local centiles: subinstr local centiles  " " "\",all

mata:  st_matrix("`out'", _quantilesR("`varlist'", .01*(`centiles') ))

return matrix centiles=`out'
end
