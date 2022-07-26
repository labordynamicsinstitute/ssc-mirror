*------------------------------------------------------------------------------*
*																	
*	DEFINE THE FRAME FOR THE MAIN AND SUBCOMMANDS
*																	
*------------------------------------------------------------------------------*

*** THIS IS COPIED FROM BEN JANN'S grstyle_set

program _grstyle_graphsize_translate2  
* (add the "2" in case the original "_grstyle_graphsize_translate" were to change)
    version 9.2
    args s
    capt confirm number `s'
    if _rc==0 {
        c_local size `s'
        exit
    }
    local u = substr(`"`s'"',-2,.)
    if !inlist(`"`u'"',"pt","mm","in","cm") {
        local u = substr(`"`s'"',-4,.)
        if `"`u'"'!="inch" {
             local u = substr(`"`s'"',-3,.)
             if `"`u'"'!="inc" {
                 di as err `"`s' not allowed"'
                 exit 198
             }
        }
    }
    local v = substr(`"`s'"',1,strlen(`"`s'"')-strlen(`"`u'"'))
    capt confirm number `v'
    if _rc {
        di as err `"`s' not allowed"'
        exit 198
    }
    if      `"`u'"'=="pt"   local s = `v' / 72
    else if `"`u'"'=="mm"   local s = `v' / 25.4
    else if `"`u'"'=="cm"   local s = `v' / 2.54
    else if `"`u'"'=="in"   local s = `v'
    else if `"`u'"'=="inch" local s = `v'
    else if `"`u'"'=="inc"  local s = `v'
    c_local size `s'
end



*------------------------------------------------------------------------------*
*																	
*	DEFINE THE PROGRAM: 1 GRAPH RESIZE
*																	
*------------------------------------------------------------------------------*


capture program drop resize
program define resize
    version 12

	syntax [anything]  ,  xsize(string) ysize(string) [ * ]

	
* TRANSLATE SIZES (the internal software of pre-enlightenment Stata uses Inch):
_grstyle_graphsize_translate2 `xsize'
local xsize = `size'

_grstyle_graphsize_translate2 `ysize'
local ysize = `size'

*** THE CALCULATION OF THE SCALE DIFFERS, DEPENDING ON WHETHER THE SIZE OF 
* GRAPHS IS SPECIFIED IN grstyle.

* IF IT'S SPECIFIED IN grstyle, THE FOLLOWING MACRO IS DEFINED
* --> IDENTIFY WHETHER THIS MACRO IS DEFINED 
* --> `temp' it's -1 if not defined and a different value otherwise
local temp =  $GRSTYLE_RSIZE  -1

* if the size of graphs is specified in grstyle
if `temp' != -1 {
local scale = 1 / (min(`xsize',`ysize') / $GRSTYLE_RSIZE ) 
}
* if not --> assume the Stata default-size: 4 X 5.5 inch
if `temp' == -1 {
local scale = 1 / (min(`xsize',`ysize') / 4 ) 
}

graph display `anything' , xsize(`xsize') ysize(`ysize') scale(`scale') `options'
end



