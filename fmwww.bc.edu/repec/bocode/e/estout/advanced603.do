capt prog drop myttests
*! version 1.0.0  14aug2007  Ben Jann
program myttests, eclass
    version 8
    syntax varlist [if] [in], by(varname) [ * ]
    marksample touse
    markout `touse' `by'
    tempname mu_1 mu_2 d d_se d_t d_p
    foreach var of local varlist {
        qui ttest `var' if `touse', by(`by') `options'
        mat `mu_1' = nullmat(`mu_1'), r(mu_1)
        mat `mu_2' = nullmat(`mu_2'), r(mu_2)
        mat `d'    = nullmat(`d'   ), r(mu_1)-r(mu_2)
        mat `d_se' = nullmat(`d_se'), r(se)
        mat `d_t'  = nullmat(`d_t' ), r(t)
        mat `d_p'  = nullmat(`d_p' ), r(p)
    }
    foreach mat in mu_1 mu_2 d d_se d_t d_p {
        mat coln ``mat'' = `varlist'
    }
    tempname b V
    mat `b' = `mu_1'*0
    mat `V' = `b''*`b'
    eret post `b' `V'
    eret local cmd "myttests"
    foreach mat in mu_1 mu_2 d d_se d_t d_p {
        eret mat `mat' = ``mat''
    }
end
sysuse auto
myttests price weight mpg, by(foreign)
ereturn list
esttab, nomtitle nonumbers noobs ///
    cells("mu_1(fmt(a3)) mu_2 d(star pvalue(d_p))" ". . d_se(par)")
