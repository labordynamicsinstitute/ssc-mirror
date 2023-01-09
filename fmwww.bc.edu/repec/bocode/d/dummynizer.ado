*! Part of package matrixtools v. 0.29
*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
* 2020-08-23 Added
* 2020-05-13 Created
program define dummynizer
    syntax, MATacode(string) [PREfix(string) Clear]
    
    `clear'
    capture mata __M = `matacode'
    mata: __pre = `"`prefix'"' == "" ? "v" : `"`prefix'"'
    mata: __nms = __pre :+ strofreal(1..cols(__M), "%04.0f")
    if !_rc  mata nhb_sae_addvars(__nms, __M) 
    else mata error(`"MATA code not proper!"')
    mata: mata drop __*
end