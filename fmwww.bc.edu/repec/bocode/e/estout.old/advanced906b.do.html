capture which ineqrbd      // check whether -ineqrbd- is installed
if _rc ssc install ineqrbd // and get it if not
sysuse auto
ineqrbd price trunk weight length foreign, noregression
// Step 1: collect results from r(sf_Z#), r(mean_Z#), and r(cv_Z#)
local xvars "`r(xvars)'"
local nx : list sizeof xvars
foreach s in sf mean cv {
   tempname `s'
   matrix ``s'' = J(`nx'+2, 1, .z)
   matrix rownames ``s'' = residual `r(xvars)' Total
   forv i = 0/`nx' {
       matrix ``s''[`i'+1, 1] = `r(`s'_Z`i')'
   }
}
matrix `sf'[rowsof(`sf'), 1]     = 1
matrix `mean'[rowsof(`mean'), 1] = `r(mean_tot)'
matrix `cv'[rowsof(`sf'), 1]     = `r(cv_tot)'
// Step 2: build matrix that mirrors -ineqrbd-'s output
matrix ineqrbd = ///
   `sf' * 100 ,                    /// column 1: 100*s_f
   `sf' * `r(cv_tot)' ,            /// column 2: S_f
   `mean' / `r(mean_tot)' * 100,   /// column 3: 100*m_f/m
   `cv',                           /// column 4: CV_f
   `cv' / `r(cv_tot)'              //  column 5: CV_f/CV(total)
matrix colnames ineqrbd = 100*s_f S_f 100*m_f/m CV_f CV_f/CV(total)
// Step 3: post matrix columns in e()
ereturn post
tempname tmp
local i 0
foreach col in s_f100 S_f m_f100 CV_f CV_ftot {
   local ++i
   matrix `tmp' = ineqrbd[1...,`i']'
   quietly estadd matrix `col' = `tmp'
}
ereturn list
// Step 4: tabulate
esttab, cell("s_f100 S_f m_f100 CV_f CV_ftot") noobs
esttab, cell((S_f s_f100(fmt(1) par("" "%")))) noobs
