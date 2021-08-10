***Script for illustrating Central Limit Theorem***

***
//AUTHOR: Marshall A. Taylor
//DATE: February 7, 2017
//NOTE: The goal is to show that the standard error estimated
	//from a single random variable is nearly equivalent to
	//the standard deviation of an empirically-derived sampling
	//distribution, regardless of how the random variable is
	//distributed. Good tutorial for illustrating how the 
	//denominator in the s.e. equation--sqrt(n)--work in
	//practice.
***

capture program drop sdist
program define sdist
preserve
clear
version 13.1
set graphics off

syntax , [samples(real 200) obs(real 500) type(string) par1(real 0) ///
	par2(real 1) round(real 0.001) dots]

qui {

capture which savesome
if `=_rc'!=0 {
	ssc install savesome
	}

if "`dots'"!="" {
nois _dots 0, title(Preparing for simulation) reps(`samples')
forvalues k = 1/`samples' { //Generate empty variables. Increasing this will
	gen var`k'=.          //result in a more normal sampling distribution.
	nois _dots `k' 0	//Just be sure to adjust var* text in loops below.
	}
}

if "`dots'"=="" {
forvalues k = 1/`samples' {
	gen var`k'=.
	}
}	
	
if "`type'"=="" local type "`par1'+(`par2'-`par1')*runiform()" //default
if "`type'"=="uniform" local type "`par1'+(`par2'-`par1')*runiform()"
if "`type'"=="normal" local type "rnormal(`par1',`par2')"
if "`type'"=="poisson" local type "rpoisson(`par2')"

if "`dots'"!="" {
nois _dots 0, title(Creating `samples' random samples with `obs' observations) ///
	reps(`samples')
foreach i of varlist var1-var`samples' { //Use K (above) to generate K random variables
	set obs `obs'                        //from a uniform distribution w/ n each.
	gen `i'_r = `type'
	sum `i'_r
	gen `i'_mean=r(mean)
	nois _dots `i' 0
	}
}

if "`dots'"=="" {
foreach i of varlist var1-var`samples' { 
	set obs `obs'                        
	gen `i'_r = `type'
	sum `i'_r
	gen `i'_mean=r(mean)
	}
}

if "`dots'"!="" {
nois _dots 0, title(Creating dataset of random samples) reps(`samples')
foreach m of varlist var1-var`samples' { //Drop empty variables used to set random
    nois _dots `m' 0                    //random variables.
	drop `m'
	} 
}

if "`dots'"=="" {
foreach m of varlist var1-var`samples' {
	drop `m'
	}
}

savesome *_r using random_vars.dta, replace

rename var1_r x //Save one set of sample estimates for later comparison to the
drop *_r       //empirically-derived sampling distribution.
xpose, clear varname

local a=`samples'+1

sum v1 in 2/`a' //Getting empirically-derived mean and standard deviation of
local sa_mean=round(r(mean),`round') //the sampling distribution.
local sa_sd=round(r(sd),`round')

hist v1 in 2/`a', freq normal fcolor("gs6") lcolor("black") normopts(lcolor("black" lwidth(1.5))) ///
	xtitle("Empirical Sampling Distribution of `samples' X-bars" ///
	"{&mu}{sub:x-bar} = `sa_mean'; {&sigma}{sub:X-bar} = `sa_sd'") ///
	graphregion(fcolor(white)) saving(sampling.gph,replace)

savesome v1 in 2/`a' using sample_means.dta, replace
xpose, clear varname

ci x //Getting standard error estimate from a single sample.
local x_se=round(r(se),`round')
sum x
local x_mean=round(r(mean),`round')
local x_sd=round(r(sd),`round')

local diff = round(abs(`sa_sd'-`x_se'),`round')

#delimit ;
hist x, freq normal fcolor("gs6") lcolor("black") normopts(lcolor("black" lwidth(1.5))) 
	xtitle("Distribution of a Single X"
	"X-bar = `x_mean'; {it:s} = `x_sd'; se{sub:X-bar} = `x_se'") 
	graphregion(fcolor(white)) saving(sampling2.gph,replace) ;
#delimit cr

noisily: disp "                            "
noisily: disp "          ------------------"
noisily: disp "                      sd/se    "
noisily: disp "          ------------------"
noisily: disp "          sig_Xb       `sa_sd'"
noisily: disp "          se_Xb        `x_se'"
noisily: disp "          abs(diff)    `diff'"
noisily: disp "          ------------------"
noisily: disp "                  "
noisily: disp "The difference between sig_Xb and se_Xb is `diff'. The larger"
noisily: disp "this difference, the poorer the single X variable standard error approximates"
noisily: disp "the standard deviation of the sampling distribution. This may be due to one"
noisily: disp "of two things: a small number of samples and/or a small sample size."

set graphics on
gr combine sampling.gph sampling2.gph, ///
	col(1) imargin(0 0 0 0) graphregion(margin(l=22 r=22) fcolor(white)) ///
	saving(sampling_combined.gph,replace)

clear
restore
}
end
