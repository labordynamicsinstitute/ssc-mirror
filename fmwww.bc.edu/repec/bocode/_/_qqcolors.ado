*! _qqcolors 1.0.0 16may2026
*! Generate MATLAB-style colormap cuts & colors for twoway contour
*! Available maps: jet, parula, viridis, hot, cool, redblue, redwhiteblue
*! Author: Merwan Roudane

program _qqcolors, rclass
    version 14
    syntax , MAP(string) ZMIN(string) ZMAX(string) [ Levels(integer 30) ]

    local zmin = real("`zmin'")
    local zmax = real("`zmax'")
    if `zmin' == .  local zmin = -1
    if `zmax' == .  local zmax =  1

    local map = lower("`map'")
    if !inlist("`map'","jet","parula","viridis","hot","cool","redblue","rwb","plasma") ///
        & !inlist("`map'","redgreen","rdgrn","rdylgn","redwhitegreen","rwg","rdwhgn") {
        di as err "unknown colormap `map'"
        exit 198
    }

    local n = `levels'
    if `n' < 4 local n = 4

    * Generate `n' colors evenly spaced along the chosen colormap
    tempname COL CUTS
    mata: lqqr_qqcolors_gen("`map'", `n', `zmin', `zmax', "`COL'", "`CUTS'")

    * Convert numeric color matrix to list of quoted "r g b" strings.
    * Use compound quotes so each entry retains its surrounding "..." even
    * on the first iteration (Stata strips outer quotes when RHS starts with ").
    local colors `""'
    forval i = 1/`n' {
        local r = round(`COL'[`i',1])
        local g = round(`COL'[`i',2])
        local b = round(`COL'[`i',3])
        local colors `"`colors' "`r' `g' `b'""'
    }

    * Convert cuts matrix to space-separated numlist
    local cuts ""
    local nc = colsof(`CUTS')
    forval j = 1/`nc' {
        local v = `CUTS'[1,`j']
        local cuts `cuts' `v'
    }

    return local colors `"`colors'"'
    return local cuts   `"`cuts'"'
    return local map    `"`map'"'
end
