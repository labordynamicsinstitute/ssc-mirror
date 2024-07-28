*! Version 6.3 27July2024
*! Jean-Benoit Hardouin, Myriam Blanchin
************************************************************************************************************
* Stata program : pcm
* Estimate the parameters of the Partial Credit Model
* Version 1 : December 17, 2007 [Jean-Benoit Hardouin]
* Version 2 : July 15, 2011 [Jean-Benoit Hardouin]
* Version 2.1 : October 18th, 2011 [Jean-Benoit Hardouin] : -fixedvar- option, new presentation
* Version 2.2 : October 23rd, 2013 [Jean-Benoit Hardouin] : correction of -fixedvar- option
* Version 2.3 : April 10th, 2014 [Jean-Benoit Hardouin] : correction of -fixedvar- option
* Version 2.3 : April 10th, 2014 [Jean-Benoit Hardouin] : correction of -fixedvar- option
* Version 3 : July 6th, 2019 [Jean-Benoit Hardouin] : New version using gsem
* Version 3.1 : July 9th, 2019 [Jean-Benoit Hardouin] : Small corrections
* Version 3.2 : July 17th, 2019 [Jean-Benoit Hardouin] : Small corrections
* Version 3.3 : July 25th, 2019 [Jean-Benoit Hardouin] : -pce- option
* Version 3.4 : August 23th, 2019 [Jean-Benoit Hardouin] : Correction of a bug
* Version 3.5 : August 29th, 2019 [Jean-Benoit Hardouin] : Correction of a bug with modamax``i''
* Version 4: September 13th, 2019 [Myriam Blanchin]: addition of longitudinal pcm
* Version 4.1: September 15th, 2019 [Jean-Benoit Hardouin]: correction of a small bug in the outputs
* Version 4.2: September 27th, 2019 [Jean-Benoit Hardouin] : EQUATING
* Version 4.3: November 8th, 2019 [Jean-Benoit Hardouin] : add a constant when difficulty parameters are fixed
* Version 5.0: August 2nd, 2022 [Jean-Benoit Hardouin] : New MAP graph, corrected estimation of the latent trait
* Version 5.1: July 8th, 2023 [Jean-Benoit Hardouin] : Correction of the MAP graph (histogram) and residuals graphs
* Version 5.2: July 16th, 2023 [Jean-Benoit Hardouin] : Add of new graphs for Equating
* Version 5.3: July 21th, 2023 [Jean-Benoit Hardouin] : Improvements for the docx option
* Version 5.4: July 28th, 2023 [Jean-Benoit Hardouin] : Improvements for graphs et corrections of bugs
* Version 5.5: October 25th, 2023 [Jean-Benoit Hardouin] : first attempt with DIF
* Version 6.0: July 7th, 2024 [Jean-Benoit Hardouin] : Stable version with DIF, but CCC and ICC graphs, and MAP have not been corrected
* Version 6.1: July 18th, 2024 [Jean-Benoit Hardouin] : Stable version with DIF, graphics OK, equating and editing have not been corrected
* Version 6.2: July 21th, 2024 [Jean-Benoit Hardouin] : Stable version with DIF, graphics OK, equating and editing OK, corrections of minor bugs - help file
* Version 6.3: July 27th, 2024 [Jean-Benoit Hardouin] : Stable version - help file - pcasim and pcacentile option - SSC
*
*
* Jean-benoit Hardouin, Myriam Blanchin - University of Nantes - France
* INSERM UMR 1246-SPHERE "Methods in Patient Centered Outcomes and Health Research", Nantes University, University of Tours
* jean-benoit.hardouin@univ-nantes.fr, myriam.blanchin@univ-nantes.fr
*
* News about this program : http://www.anaqol.org
*
* Copyright 2007, 2011, 2013, 2014, 2019, 2022-2024 Jean-Benoit Hardouin, Myriam Blanchin
*
* This program is free software; you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation; either version 2 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program; if not, write to the Free Software
* Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
************************************************************************************************************/


program define pcm, rclass 
syntax varlist(min=2 numeric) [iweight] [if] [in] [, CONTinuous(varlist) CATegorical(varlist) ITerate(int 100) TOLerance(real 0.01) model DIFFiculties(name) VARiance(real -1) PCA PCASim(int 0) PCACentile(int 95 ) rsm Graphs noGRAPHItems noCORRected filesave dirsave(string) docx(string) extension(string) alpha(real 0.01)  PCE WMLiterate(int 1) GENLT(string) GENINF(string) REPlace postpce visit(varname) id(varname) eqset1(varlist) eqset2(varlist) eqset1name(string) eqset2name(string) EQGraph eqaddset1(real 0) eqaddset2(real 0) eqmultset1(real 1) eqmultset2(real 1) eqwithci eqgenscore(string)  DIMname(string) minsize(int 30) DIFVar(varlist fv max=2) DIFItems(string) noRESiduals JITter(int 0) noOBS WCCC PARAN WObs(real 1)]

version 14
preserve

/************************************************************************************************************
QUELQUES TESTS
************************************************************************************************************/
marksample touse ,novarlist


local nbdifvar=0
if "`difvar'"!=""|"`difitems'"!="" {
	if "`difvar'"==""|"`difitems'"=="" {
		di in red "The -difvar- and -difitems- options must be used together."
		exit 198
	}
	tokenize `difvar'
	local nbdifvar : word count `difvar'
	if `nbdifvar'>2 {
		di in red "You can not used more than 2 variables in the -difvar- option"
		exit 198
	}
	local nbdif=1
	forvalues i=1/`nbdifvar' {
		local dif`i' ``i''
		qui levelsof `dif`i''
		local nbmoddif`i'=r(r)
		if `nbmoddif`i''<2 {
			di in red "There are only nbmoddifi'' levels for the DIF variable difi'' (a number between 2 and 4 is expected)."
			exit 198
		}
		local nbdif=`nbdif'*`nbmoddif`i''
		forvalues j=1/`nbmoddif`i'' {
		    local `dif`i''_`j' : word `j' of `r(levels)'
			*di "`dif`i''_`j' : ``dif`i''_`j''"
		}
	}
	if `nbdif'>4 {
		di in red "There are too many cases of DIF variables (more than 4)."
		exit 198
	}
	local nbrows=rowsof(`difitems')
	local nbcols=colsof(`difitems')
	if `nbcols'!=`nbdifvar' {
		di in red "The matrix specified in the -difitems- option must have as many columns as the number of variables defined in the -difvar- option."
		exit 198
	}
	else {
	    matrix colnames `difitems' = `difvar'
	}
}

if `pcacentile'<0|`pcacentile'>100 {
	di in red "The -pcacentile' option must contain an integer between 0 and 100."
	exit 198
}	
if `pcasim'<0|`pcasim'>1000 {
	di in red "The -pcasim' option must contain an integer between 0 and 1000."
	exit 198
}	
	
tokenize `varlist'
local nbitems : word count `varlist'
tempvar nbmissing
qui egen `nbmissing'=rowmiss(`varlist')
qui count if `nbmissing'==`nbitems'
local nbexcluded=r(N)
*di "il y a `r(N)' individus sans données"
qui replace `touse'=0 if  `nbmissing'==`nbitems'

if "`difitems'"=="" {
	tempname difitems
	matrix `difitems'=J(`nbitems',1,0)
	local nbrows=`nbitems'
	local nbcols=1
}
if `nbrows'!=`nbitems' {
	di in red "The matrix specified in the -difitems- option must have as many rows as there are items."
	exit 198
}
else {
	matrix rownames `difitems' = `varlist'
}



if `variance'!=-1&`variance'<=0 {
	di in red "The -variance- option cannot include a negative value."
	exit 198
}
if `variance'!=-1&"`visit'"!="" {
	di in red "The -variance- and -visit- options cannot be used together."*
	exit 198
}
if "`genlt'"!=""|"`geninf'"!="" {
    capture confirm new variable `genlt' `genlt'_se `geninf' `genlt'_corr `genlt'_ml `genlt'_opt_se 
	if _rc!=0&"`replace'"=="" {
	    di in red "The variables `genlt', `genlt'_se, `genlt'_corr, `genlt'_ml, `genlt'_ml_se and/or `geninf' already exist. Please modify the -genlt- and/or -geninf- option(s)."
		exit 198
	}
	if _rc!=0&"`replace'"!="" {
	    qui capture drop `genlt' 
		qui capture drop `genlt'_se 
		qui capture drop `genlt'_best 
		qui capture drop `geninf' 
		qui capture drop `genlt'_corr
		qui capture drop `genlt'_ml
		qui capture drop `genlt'_ml_se
	}
}
if ("`eqset1'"!=""&"`eqset2'"=="")|("`eqset1'"==""&"`eqset2'"!="") {
    di in red "The two options -eqset1- and -eqset2- must be used together."
	exit 198
}
if ("`eqset1'"!=""&"`graphs'"!="") {
    di in red "The two options -eqset1- and -graph- cannot be used together."
	exit 198
}
if ("`eqset1'"!=""&"`difvar'"!="") {
    di in red "The two options -eqset1- and -difvar- cannot be used together."
	exit 198
}
if "`corrected'"!="" {
	local xtitle "Latent trait"
}
else {
	local xtitle "Corrected latent trait"
}



/************************************************************************************************************
GESTION DES VARIABLES CONTINUES ET CATEGORIELLES
************************************************************************************************************/
if "`visit'"!=""{
	if "`id'"==""{
		di in red "The -visit- option must be used in conjunction with the -id- option. Please provide a value for the -id- option."
		exit 198
	}
	qui levelsof `visit'
	local levelsofv `r(levels)'
	local nbvisits=r(r)
	local timemin: word 1 of `levelsofv'
	local timemax: word `nbvisits' of `levelsofv'
	if `timemax'>5{
		di as error "You must use a discrete time variable (specified with the -visit- option) that has fewer than 5 measurement occasions."
		error 198
	}
	if `timemin'!=1{
		di as error "The -visit- variable must be coded with a value of 1 for the first visit."
		error 198
	}
	qui reshape wide `varlist', i(`id') j(`visit')
	local multivisit=1
}
else {
	local timemax=1
	local multivisit
}
qui count if `touse'
local nbobs=r(N)

local timelist
forvalues t=1/`timemax'{
	local timelist `timelist' T`t'
}

local modcont
local premodcont
local nbpar=0
local nbcont=0
local nbcat=0
if "`continuous'"!="" {
	tokenize `continuous'
	local nbcont : word count `continuous'
	local continuous
	forvalues i=1/`nbcont' {
		local cont`i' ``i''
		local continuous `continuous' ``i''
		local modcont `modcont' ``i''
	    local ++nbpar
	}
	local premodcont (`modcont'->T1)
	local modcont (`modcont'->`timelist')
}

local modcat
local premodcat
if "`categorical'"!="" {
	tokenize `categorical'
	local nbcat : word count `categorical'
	local categorical
	forvalues i=1/`nbcat' {
		local cat`i' ``i''
		local categorical `categorical' ``i''
		local modcat `modcat' i.``i''
		qui levelsof ``i''
		local levelsof``i'' `r(levels)'
		local nbpar=`nbpar'+`r(r)'-1
	}
	local premodcat (`modcat'->T1)
	local modcat (`modcat'->`timelist')
}


if "`dirsave'"=="" {
   local dirsave "`c(pwd)'"
}

/*************************************************************************************************************
GESTION DES ITEMS ET TESTS
*************************************************************************************************************/

tokenize `varlist'
local modamax=1
local modamin=0
local pbmin
local nbdiff=0
local scoremax=0
local listitemsdif
local listitemsdifcodes
local listitemsdifnumbers
local listitemsdiflevels1
local listitemsdiflevels2
tempname matelem groupdif matelem2
matrix `matelem'=J(4,`=`nbitems'*4',1)
matrix `matelem2'=J(4,`=`nbitems'*4',0)


qui gen `groupdif'=0 if `touse'
if `nbdifvar'==0 {
	local nbgroupdif=1
	local nbmoddif1=1
	qui replace `groupdif'=1 if `touse'
}
else if `nbdifvar'==1 {
	local nbgroupdif=`nbmoddif1'
	forvalues j=1/`nbmoddif1' {   
	    qui replace  `groupdif'=`j' if `dif1'==``dif1'_`j''&`touse'
	}
}
else if `nbdifvar'==2 {
	local nbgroupdif=`nbmoddif1'*`nbmoddif2'
	forvalues j=1/`nbmoddif1' {   
		forvalues k=1/`nbmoddif2' {   
			qui replace  `groupdif'=2*`j'+`k'-2 if `dif1'==``dif1'_`j''&`dif2'==``dif2'_`k''&`touse'
		}
	}
}
forvalues g=1/`nbgroupdif' {
	local scoremax`g'=0
}


local num=1
forvalues i=1/`nbitems' {
    local debut`i' `num'
    local name``i'': variable label ``i''
	if "`name``i'''"=="" {
		local name``i'' ``i''
	}
	local nbitem`i'=1
	local code`i'
	forvalues j=1/`nbdifvar' {
		if `difitems'[`i',`j']==1 {
			local nbitem`i'=`nbitem`i''*`nbmoddif`j''
			local code`i' `code`i''`j'
		}
	}
	if `nbitem`i''==1 {
		local listitemsdif `listitemsdif' ``i''
		local listitemsdifcodes `listitemsdifcodes' 0
		local listitemsdifnumbers `listitemsdifnumbers' `i'
		local listitemsdiflevels1 `listitemsdiflevels1' 0
		local listitemsdiflevels2 `listitemsdiflevels2' 0
		local labelelement`num' ``i''
		matrix `matelem2'[1,`num']=1
		local labelgr`num'
		local ++num
	}
	else {
		local listitemsdifcodes `listitemsdifcodes' `code`i''
		if `code`i''==1|`code`i''==2 {   
		    forvalues j=1/`nbmoddif`code`i''' {
				local listitemsdifnumbers `listitemsdifnumbers' `i'
				local tmp=`code`i''
				if `tmp'==1 {
					local listitemsdiflevels1 `listitemsdiflevels1' ``dif1'_`j''
					local listitemsdiflevels2 `listitemsdiflevels2' 0
				}
				else {
					local listitemsdiflevels2 `listitemsdiflevels2' ``dif2'_`j''
					local listitemsdiflevels1 `listitemsdiflevels1' 0
				}
				tempvar ``i''_`j'
				local listitemsdif `listitemsdif' ```i''_`j''
				qui gen ```i''_`j''=``i'' if `dif`tmp''==``dif`tmp''_`j'' 
				local labelelementbis`num' `dif`tmp''==``dif`tmp''_`j''
				local labelelement`num' ``i'' - `dif`tmp''==``dif`tmp''_`j''
				if `code`i''==1&`j'==1&`nbdifvar'==2 {
					matrix `matelem'[3,`num']=0
					matrix `matelem'[4,`num']=0
					matrix `matelem2'[1,`num']=1
					local labelgr`num' "`dif1'=``dif1'_1'"
				}
				if `code`i''==1&`j'==2&`nbdifvar'==2 {
					matrix `matelem'[1,`num']=0
					matrix `matelem'[2,`num']=0
					matrix `matelem2'[3,`num']=1
					local labelgr`num' "`dif1'=``dif1'_2'"
				}
				if `code`i''==2&`j'==1&`nbdifvar'==2 {
					matrix `matelem'[2,`num']=0
					matrix `matelem'[4,`num']=0
					matrix `matelem2'[1,`num']=1
					local labelgr`num' "`dif2'=``dif1'_1'"
				}
				if `code`i''==2&`j'==2&`nbdifvar'==2 {
					matrix `matelem'[1,`num']=0
					matrix `matelem'[3,`num']=0
					matrix `matelem2'[2,`num']=1
					local labelgr`num' "`dif2'=``dif1'_2'"
				}
				if `j'==1&`nbdifvar'==1 {
					matrix `matelem'[1,`num']=1
					matrix `matelem'[2,`num']=0
					matrix `matelem'[3,`num']=0
					matrix `matelem'[4,`num']=0
					matrix `matelem2'[1,`num']=1
					local labelgr`num' "`dif1'=``dif1'_1'"
				}
				if `j'==2&`nbdifvar'==1 {
					matrix `matelem'[1,`num']=0
					matrix `matelem'[2,`num']=1
					matrix `matelem'[3,`num']=0
					matrix `matelem'[4,`num']=0
					matrix `matelem2'[2,`num']=1
					local labelgr`num' "`dif1'=``dif1'_2'"
				}
				if `j'==3&`nbdifvar'==1 {
					matrix `matelem'[1,`num']=0
					matrix `matelem'[2,`num']=0
					matrix `matelem'[3,`num']=1
					matrix `matelem'[4,`num']=0
					matrix `matelem2'[3,`num']=1
					local labelgr`num' "`dif1'=``dif1'_3'"
				}
				if `j'==4&`nbdifvar'==1 {
					matrix `matelem'[1,`num']=0
					matrix `matelem'[2,`num']=0
					matrix `matelem'[3,`num']=0
					matrix `matelem'[4,`num']=1
					matrix `matelem2'[4,`num']=1
					local labelgr`num' "`dif1'=``dif1'_4'"
				}
				local ++num
			}
			
		}
		else if `code`i''==12 {
		    forvalues j=1/`nbmoddif1' {
				forvalues k=1/`nbmoddif2' {
					local listitemsdifnumbers `listitemsdifnumbers' `i'
					local listitemsdiflevels1 `listitemsdiflevels1' ``dif1'_`j''
					local listitemsdiflevels2 `listitemsdiflevels2' ``dif2'_`k''
					tempvar ``i''_`j'_`k'
					local listitemsdif `listitemsdif' ```i''_`j'_`k''
					qui gen ```i''_`j'_`k''=``i'' if `dif1'==``dif1'_`j''&`dif2'==``dif2'_`k''
					local labelelementbis`num' `dif1'==``dif1'_`j''&`dif2'==``dif2'_`k''
				    local labelelement`num' ``i'' - `dif1'==``dif1'_`j''&`dif2'==``dif2'_`k''
					if `j'==1&`k'==1 {
						matrix `matelem'[2,`num']=0
						matrix `matelem'[3,`num']=0
						matrix `matelem'[4,`num']=0
						matrix `matelem2'[1,`num']=1
						local labelgr`num' "`dif1'=``dif1'_1'&`dif2'=``dif1'_1'"
					}
					if `j'==1&`k'==2 {
						matrix `matelem'[1,`num']=0
						matrix `matelem'[3,`num']=0
						matrix `matelem'[4,`num']=0
						matrix `matelem2'[2,`num']=1
						local labelgr`num' "`dif1'=``dif1'_1'&`dif2'=``dif1'_2'"
					}
					if `j'==2&`k'==1 {
						matrix `matelem'[1,`num']=0
						matrix `matelem'[2,`num']=0
						matrix `matelem'[4,`num']=0
						matrix `matelem2'[3,`num']=1
						local labelgr`num' "`dif1'=``dif1'_2'&`dif2'=``dif1'_1'"
					}
					if `j'==2&`k'==2 {
						matrix `matelem'[1,`num']=0
						matrix `matelem'[2,`num']=0
						matrix `matelem'[3,`num']=0
						matrix `matelem2'[4,`num']=1
						local labelgr`num' "`dif1'=``dif1'_2'&`dif2'=``dif1'_2'"
					}
					local ++num
				}
			}
		}
		else if "`code`i''"=="" {
			local code`i'=0
		}
	}
}
matrix `matelem'=`matelem'[1..`nbgroupdif',1..`=`num'-1']
matrix `matelem2'=`matelem2'[1..`nbgroupdif',1..`=`num'-1']

forvalues i=1/`nbitems' {
	qui su ``i''
	local modamaxitem`i'=r(max)
}

local nblistitemsdif: word count  `listitemsdif'
forvalues i=1/`nblistitemsdif' {
	local element`i': word `i' of `listitemsdif'
	local modamax`i'=1
	if `timemax'>1 {
		forvalues t=1/`timemax'{
			 qui su ``i''`t' if `touse'
			 if `r(min)'!=`modamin' {
				 local modamin=r(min)
				 local pbmin `pbmin' ``i'`t''
			 }
			 if `r(max)'>`modamax' {
				 local modamax=r(max)
			 }
			 if `r(max)'>`modamax`i'' {
				local modamax`i'=r(max)
			}
		}
	}
	else {
		qui su `element`i'' if `touse'
		if "`r(max)'"=="" {
		    di as error "The variable `element`i'' is empty. Please correct this issue."
			error 198
		}
		if `r(min)'!=0 {
		   di as error "The minimum response category for each item must be coded as 0. This is not the case for the following item: `labelelement`i'' (min=`r(min)'). "
		   error 198
		}

		if `r(min)'!=`modamin' {
		    local modamin=r(min)
			local pbmin `pbmin' ``i''
		}
		if `r(max)'>`modamax' {
			local modamax=r(max)
		}
		if `r(max)'>`modamax`i'' {
			local modamax`i'=r(max)
		}
		qui tab `element`i'' if `touse'
		if `r(r)'!=`modamax`i''+1 {
			qui levels `element`i'' if `touse'
		    di as error "All response categories from 0 to `modamax`i'' must be present in the sample. This is not the case for the following items: `labelelement`i'' (at least one response category is missing: `r(levels)')."
		    error 198
		}
	}
	forvalues g=1/`nbgroupdif' {
		if `matelem'[`g',`i']==1 {
		    local scoremax`g'=`scoremax`g''+`modamax`i''
			if `scoremax`g''>`scoremax' {
				local scoremax=`scoremax`g''
			}
		}
	}
	if "`rsm'"=="" {
		local nbdiff=`nbdiff'+`modamax`i''
	}
}


qui count if `touse'
local nbind=r(N)
local codek
local precodek
if `timemax'>1 {
	forvalues k=1/`modamax' {
	   forvalues t=1/`timemax'{
			local codek`k'
		    forvalues i=1/`nbitems' {
			    if `k'<=`modamax`i'' {
				    local codek`k' `codek`k'' `k'.``i''`t'
			    }
		    }
		    local codek`k' (`codek`k''<-T`t'@`k')
		    if `t'==1{
				local precodek `precodek' `codek`k''
		    }
		    local codek `codek' `codek`k''
		}
	}
}
else {
	forvalues k=1/`modamax' {
		local codek`k'
		forvalues i=1/`nblistitemsdif' {
			if `k'<=`modamax`i'' {
				local codek`k' `codek`k'' `k'.`element`i''
			}
		}
		local codek`k' (`codek`k''<-T1@`k')
		local precodek `precodek' `codek`k''
		local codek `codek' `codek`k''
	}
}

local c=1
forvalues j=1/`nbmoddif1' {
	if `nbdifvar'==0 {
		local conddif1 1
	}
	if `nbdifvar'==1 {
		local conddif`c' "`dif1'==``dif1'_`j''"
		local d1=abbrev("`dif1'",10)
		local cond2dif`c' "`d1'=``dif1'_`j''"
		local ++c
	}
	if `nbdifvar'==2 {
		forvalues k=1/`nbmoddif2' {
			local conddif`c' "`dif1'==``dif1'_`j''&`dif2'==``dif2'_`k''"
			local d1=abbrev("`dif1'",15)
			local d2=abbrev("`dif2'",15)
			local cond2dif`c' "`d1'=``dif1'_`j''&`d2'=``dif2'_`k''"
			local ++c
		}
	}	
}


/*************************************************************************************************************
OPTION PCE
*************************************************************************************************************/

if "`pce'"!=""&"`difficulties'"==""&"`visit'"=="" {
    tempname sedelta b loulou
	qui raschpce `varlist' if `touse'
	local ll=r(ll)
	matrix `sedelta'=r(sedelta)
	matrix `sedelta'=`sedelta''
	matrix `b'=r(b)
	local difficulties `b'
	matrix `loulou'=`b'
	return matrix diff_parm=`b'
	`qui' pcm `varlist' if `touse', diff(`loulou')  geninf(TInf_0) genlt(lt_0) /*postpce*/
}


/*************************************************************************************************************
RECUPERATION DES PARAMETRES DE DIFFICULTES ET DEFINITION DES CONTRAINTES
*************************************************************************************************************/
if "`difficulties'"!=""&"`rsm'"!="" {
   di as error "You cannot define both the -difficulties- and -rsm- options simultaneously."
   error 198
}
local t=1
local constraints
local codemean
local codevar
local codecov
forvalues j=2/`timemax'{
	forvalues i=1/`nbitems' {
		forvalues k=1/`modamax`i'' {
			qui constraint `t' [`k'.``i''`j']_cons=[`k'.``i''`multivisit']_cons
			local constraints `constraints' `t'
			local ++t
			
		}
	}	
	if "`continuous'"=="" &  "`categorical'"==""{
		local codemean `codemean' T`j'@m`j'
		local codevar `codevar' T`j'@v`j'
		forvalues l=1/`=`j'-1'{
			local codecov `codecov' T`l'*T`j'@cov`l'`j'
		}
	}
	else{
		local codevar `codevar' e.T`j'@v`j'
		forvalues l=1/`=`j'-1'{
			local codecov `codecov' e.T`l'*e.T`j'@cov`l'`j'
		}	
	}
}
if `timemax'>1{
	if "`continuous'"=="" &  "`categorical'"==""{	
		local codelg means(T1@0 `codemean') var(T1@v1 `codevar') cov(`codecov')
	}
	else{
		local codelg var(e.T1@v1 `codevar') cov(`codecov')
	}
}
else {
    local constrvar
    if `variance'>0 {
		if "`continuous'"=="" &  "`categorical'"==""{	
			local constrvar var(T1@`variance') 
		}
	}
}

local fixedmean
if "`difficulties'"!="" {
    tempname beta
	matrix `beta'=J(`nbitems',`modamax',.)
	forvalues i=1/`nbitems' {
		forvalues k=1/`modamax`i'' {
			if `difficulties'[`i',`k']==. {
				 di as error "The kth difficulty parameter of the item ``i'' is not correctly specified in the -difficultie-s matrix"
				 error 198
			}
			else {
				if `k'==1 {
					matrix `beta'[`i',1]=-`difficulties'[`i',1]
  			    }
				else {
				    matrix `beta'[`i',`k']=`beta'[`i',`=`k'-1']-`difficulties'[`i',`k']
				}
				qui constraint `t' [`k'.``i''`multivisit']_cons=`beta'[`i',`k']
				local constraints `constraints' `t'
				local ++t
			}
		}
	}
	if "`continuous'"=="" &  "`categorical'"=="" {	
		local fixedmean mean(T1) 
	}
	else{
		local fixedmean 
	}
}



/*************************************************************************************************************
DEFINITION DES CONTRAINTES POUR UN RSM
*************************************************************************************************************/
if "`rsm'"!="" {
   local constraints
   if `timemax'>1 {
	   forvalues k=2/`modamax' {
		   forvalues i=2/`nblistitemsdif' {
			   qui constraint `t'   [`=`k'-1'.``i''`multivisit']_cons-[`k'.``i''`multivisit']_cons+[1.``i''`multivisit']_cons=[`=`k'-1'.`1'1]_cons-[`k'.`1'1]_cons+[1.`1'1]_cons
			   local constraints `constraints' `t'
			   local ++t
		   }
	   }
   }
   else {
	   forvalues k=2/`modamax' {
		   forvalues i=2/`nblistitemsdif' {
			    qui constraint `t'   [`=`k'-1'.`element`i'']_cons-[`k'.`element`i'']_cons+[1.`element`i'']_cons=[`=`k'-1'.`element1']_cons-[`k'.`element1']_cons+[1.`element1']_cons
			    local constraints `constraints' `t'
			    local ++t
				local nbdiff=`nblistitemsdif'+`modamax'-1
		   }
	   }
   }
}

/*************************************************************************************************************
MODELE
*************************************************************************************************************/


discard
if "`model'"!="" {
    local qui
}
else {
	local qui qui
}

if `timemax'==1{
   `qui' gsem `codek' `modcont' `modcat' if `touse' ,iterate(`iterate') tol(`tolerance') constraint(`constraints') latent(`timelist') `constrvar' `fixedmean'
}
else{
    `qui' gsem `precodek' `premodcont' `premodcat' if `touse',iterate(`iterate') tol(`tolerance') constraint(`constraints') 
     matrix esti_B = e(b)
    `qui' gsem `codek' `modcont' `modcat' if `touse',iterate(`iterate') tol(`tolerance') constraint(`constraints') latent(`timelist') `codelg' from(esti_B,skip)
}
local ll=e(ll)

tempvar latent score group selatent latent2 miss
tempname groups
qui predict `latent'* if `touse',latent se(`selatent'*)

if "`genlt'"!="" {
	if `timemax'==1 {
		qui gen `genlt'=`latent'1 if `touse'
		qui gen `genlt'_se=`selatent'1 if `touse'
	}
	forvalues t=2/`timemax' {
		qui gen `genlt'`t'=`latent'`t' if `touse'
		qui gen `genlt'`t'_se=`selatent'`t' if `touse'
	}
}

set seed 123456
if `timemax'>1 {
	forvalues t=1/`timemax'{
		qui gen `latent2'`t'=`latent'`t'+invnorm(uniform())*`selatent'`t' if `touse'
		local listit 
		forvalues i=1/`nbitems' {
			local listit `listit' ``i''`t'
		}
		qui genscore `listit' if `touse',score(`score'`t')
		qui gengroup `latent'`t' if `touse',newvariable(`group'`t') continuous minsize(`minsize')
	}
}
else {
	qui gen `latent2'=`latent'1+invnorm(uniform())*`selatent'1 if `touse'
	local listit 
	forvalues i=1/`nbitems' {
		local listit `listit' ``i''
	}
	qui genscore `listit' if `touse',score(`score')
	if "`graphs'"!="" {
		if `minsize'<`=`nbobs'*`nbgroupdif'/100' {
			local minsize=max(`minsize',`=ceil(`nbobs'*`nbgroupdif'/80)')
			di as text "The -minsize- option has been updated to `minsize'."
		}
	}
	qui gengroup `latent'1 if `touse',newvariable(`group') continuous minsize(`minsize')
}
forvalues s=0/`scoremax' {
    qui count if `score'==`s'&`touse'
	local effscore`s'=r(N)
}

/*time 1 only*/
qui levelsof `group'`multivisit' if `touse'
local nbgroups=r(r)
forvalues c=1/`nbgroupdif' {
	tempname groupsdif`c'
	matrix `groupsdif`c''=J(`nbgroups',`=`nblistitemsdif'+10',.)
	forvalues g=1/`nbgroups' {
		matrix `groupsdif`c''[`g',`=`nblistitemsdif'+3']=0
		qui count if `group'`multivisit'==`g'&`touse'&`conddif`c''
		local effgroup`g'=r(N)
		qui su `score' if `group'`multivisit'==`g'&`touse'&`conddif`c''
		if `r(N)'>0 {
			matrix `groupsdif`c''[`g',`=`nblistitemsdif'+3']=`r(mean)'
		}
		forvalues i=1/`nblistitemsdif' {
			qui count if `element`i''`multivisit'!=.&`group'`multivisit'==`g'&`touse'&`conddif`c''
			local n=r(N)
			if `n'>0 {
				qui su `element`i''`multivisit' if `group'`multivisit'==`g'&`touse'&`conddif`c''
				matrix `groupsdif`c''[`g',`i']=r(mean)

			}
			else {
				matrix `groupsdif`c''[`g',`i']=.
			}		
		}
		qui su `latent'1 if `group'`multivisit'==`g'&`touse'&`conddif`c''
		matrix `groupsdif`c''[`g',`=`nblistitemsdif'+1']=r(mean)
		matrix `groupsdif`c''[`g',`=`nblistitemsdif'+7']=r(min)
		matrix `groupsdif`c''[`g',`=`nblistitemsdif'+8']=r(max)
		qui count if `group'`multivisit'==`g'&`touse'
		matrix `groupsdif`c''[`g',`=`nblistitemsdif'+2']=r(N)
		qui su `score' if `group'`multivisit'==`g'&`score'!=.&`touse'&`conddif`c''
		matrix `groupsdif`c''[`g',`=`nblistitemsdif'+4']=r(min)
		matrix `groupsdif`c''[`g',`=`nblistitemsdif'+5']=r(max)	
	}
}
/*number of non-missing on all time points*/
qui egen `miss'=rowmiss(`score'*) if `touse'
qui count if `miss'==0&`touse'
local nbobsssmd=r(N)
qui drop `miss'	

di
if `nbexcluded'>0 {
	di as text "Number of excluded individuals:" %6.0f as result `nbexcluded' " (individuals with no responses to any of the items)"
}
di as text "Number of analysed individuals:" %6.0f as result `nbobs'
di as text "Number of individuals with a complete response pattern:" %6.0f as result `nbobsssmd'
di as text "Number of items:" %6.0f as result `nbitems'

di as text "Marginal log-likelihood:" %12.4f as result `ll'
di 
return scalar ll=`ll'



*set trace on
/*************************************************************************************************************
RECUPERATION DES ESTIMATIONS DES PARAMETRES DE DIFFICULTE
*************************************************************************************************************/
if "`difvar'"=="" {
    forvalues i=1/`nbitems' {
	    local element`i' ``i''
	}
	local nblistitemsdif=`nbitems'
}
tempname diff diffmat vardiff diffmat2 diftest
*set trace on
qui matrix `diffmat'=J(`nblistitemsdif',`modamax',.)
qui matrix `diffmat2'=J(`nblistitemsdif',`modamax',.)
qui matrix `diff'=J(`nbdiff',6,.)
if `nbdifvar'==1 {
	qui matrix `diftest'=J(`nbitems',6,.)
	matrix colnames `diftest'=chi2 df p chi2_`dif1' df_`dif1' p_`dif1' 
}
else if `nbdifvar'==2 {
	qui matrix `diftest'=J(`nbitems',9,.)
	matrix colnames `diftest'=chi2 df p chi2_`dif1' df_`dif1' p_`dif1' chi2_`dif2' df_`dif2' p_`dif2' 
}
local rn
local rn2



/*Test de DIF*/
forvalue i=1/`nbitems' {
	if "`code`i''"!="0"&"`code`i''"!="" {
		local accum
		forvalues j=`=`debut`i''+1'/`=`debut`i''+`nbitem`i''-1' {
			qui test -_b[1.`element`j'':_cons]=-_b[1.`element`debut`i''':_cons],`accum'
			local accum accum
			forvalues k=2/`modamaxitem`i'' {
				qui test _b[`=`k'-1'.`element`j'':_cons]-_b[`k'.`element`j'':_cons]=_b[`=`k'-1'.`element`debut`i''':_cons]-_b[`k'.`element`debut`i''':_cons],`accum'
			}
			matrix `diftest'[`i',1]=r(chi2)
			matrix `diftest'[`i',2]=r(df)
			matrix `diftest'[`i',3]=r(p)
		}
		if `code`i''==1 {
			matrix `diftest'[`i',4]=`diftest'[`i',1]
			matrix `diftest'[`i',5]=`diftest'[`i',2]
			matrix `diftest'[`i',6]=`diftest'[`i',3]
		}
		else if `code`i''==2{
			matrix `diftest'[`i',7]=`diftest'[`i',1]
			matrix `diftest'[`i',8]=`diftest'[`i',2]
			matrix `diftest'[`i',9]=`diftest'[`i',3]
		}
		if `code`i''==12 {
			local it1=`debut`i''
			local it2=`debut`i''+1
			local it3=`debut`i''+2
			local it4=`debut`i''+3
			qui test -_b[1.`element`it3'':_cons]=-_b[1.`element`it1'':_cons]
			qui test -_b[1.`element`it4'':_cons]=-_b[1.`element`it2'':_cons], accum
			forvalues k=2/`modamaxitem`i'' {
				qui test _b[`=`k'-1'.`element`it3'':_cons]-_b[`k'.`element`it3'':_cons] =_b[`=`k'-1'.`element`it1'':_cons]-_b[`k'.`element`it1'':_cons],accum
				qui test _b[`=`k'-1'.`element`it4'':_cons]-_b[`k'.`element`it4'':_cons] =_b[`=`k'-1'.`element`it2'':_cons]-_b[`k'.`element`it2'':_cons],accum
			}
			matrix `diftest'[`i',4]=r(chi2)
			matrix `diftest'[`i',5]=r(df)
			matrix `diftest'[`i',6]=r(p)
			qui test -_b[1.`element`it2'':_cons]=-_b[1.`element`it1'':_cons]
			qui test -_b[1.`element`it4'':_cons]=-_b[1.`element`it3'':_cons], accum
			forvalues k=2/`modamaxitem`i'' {
				qui test _b[`=`k'-1'.`element`it2'':_cons]-_b[`k'.`element`it2'':_cons] =_b[`=`k'-1'.`element`it1'':_cons]-_b[`k'.`element`it1'':_cons],accum
				qui test _b[`=`k'-1'.`element`it4'':_cons]-_b[`k'.`element`it4'':_cons] =_b[`=`k'-1'.`element`it3'':_cons]-_b[`k'.`element`it3'':_cons],accum
			}
			matrix `diftest'[`i',7]=r(chi2)
			matrix `diftest'[`i',8]=r(df)
			matrix `diftest'[`i',9]=r(p)
		}
	}
}


local t=1
forvalues i=1/`nblistitemsdif' {
    qui matrix `diffmat'[`i',1]=-_b[1.`element`i''`multivisit':_cons]
    qui matrix `diffmat2'[`i',1]=-_b[1.`element`i''`multivisit':_cons]
	qui lincom -_b[1.`element`i''`multivisit':_cons]
    qui matrix `diff'[`t',1]=`r(estimate)'
    qui matrix `diff'[`t',2]=`r(se)'
    qui matrix `diff'[`t',3]=`r(z)'
    qui matrix `diff'[`t',4]=`r(p)'
    qui matrix `diff'[`t',5]=`r(lb)'
    qui matrix `diff'[`t',6]=`r(ub)'
	local it:word `i' of `listitemsdifnumbers'
	local nom
	if `difitems'[`it',1]==1 {
		local d1:word `i' of `listitemsdiflevels1'
		local nom `nom'_`d1'
	}
	if `difitems'[`it',2]==1 {
		local d2:word `i' of `listitemsdiflevels2'
		local nom `nom'_`d2'
	}
	local rn `rn' 1.``it''`multivisit'`nom'
	local rn2 `rn2' ``it''`nom'
	local ++t
	local sum _b[1.`element`i''`multivisit':_cons]
	if "`rsm'"=="" {
	    forvalues k=2/`modamax`i'' {
			local sum "_b[`k'.`element`i''`multivisit':_cons]-(`sum')"
			local sum2 "_b[`=`k'-1'.`element`i''`multivisit':_cons]-_b[`k'.`element`i''`multivisit':_cons]"
			qui lincom (`sum2')
			qui matrix `diffmat'[`i',`k']=`r(estimate)'
			qui matrix `diffmat2'[`i',`k']=`diffmat2'[`i',`=`k'-1']+`diffmat'[`i',`k']
			qui matrix `diff'[`t',1]=`r(estimate)'
			qui matrix `diff'[`t',2]=`r(se)'
			qui matrix `diff'[`t',3]=`r(z)'
			qui matrix `diff'[`t',4]=`r(p)'
			qui matrix `diff'[`t',5]=`r(lb)'
			qui matrix `diff'[`t',6]=`r(ub)'
			local rn `rn' `k'.``it''`multivisit'`nom'
			local ++t
		}
    }
}

if "`rsm'"!="" {
    forvalues k=2/`modamax' {
		qui lincom _b[`=`k'-1'.`element1'`multivisit':_cons]-_b[`k'.`element1'`multivisit':_cons]+_b[1.`element1'`multivisit':_cons] 
		qui matrix `diff'[`t',1]=`r(estimate)'
		qui matrix `diff'[`t',2]=`r(se)'
		qui matrix `diff'[`t',3]=`r(z)'
		qui matrix `diff'[`t',4]=`r(p)'
		qui matrix `diff'[`t',5]=`r(lb)'
		qui matrix `diff'[`t',6]=`r(ub)'
		forvalues i=1/`nblistitemsdif' {
		    qui matrix `diffmat'[`i',`k']=`diff'[`t',1]+`diffmat'[`i',1]
		    qui matrix `diffmat2'[`i',`k']=`diffmat'[`i',`k']+`diffmat2'[`i',`=`k'-1']
		}
		local rn `rn' tau`k'
		local ++t
	}
}
local cn Estimate S.e. z p "Lower bound" "Upper Bound"
matrix colnames `diff'=`cn'
matrix rownames `diff'=`rn'

/*************************************************************************************************************
RECUPERATION DES ESTIMATIONS DES PARAMETRES POUR LES COVARIABLES, MOYENNES ET VARIANCES
*************************************************************************************************************/
tempname covariates
local nbcov=0
forvalues j=2/`timemax'{
	local nbcov=`nbcov'+`j'-1
}
qui matrix `covariates'=J(`=`nbpar'+`timemax'+2*`nbcov'',6,.)

local t=1


forvalues j=1/`=`timemax'-1'{
	forvalues k=`=`j'+1'/`timemax'{
		if "`categorical'"=="" & "`continuous'"=="" {
			if `j'==1{
				qui lincom [/]mean(T`k')
			}
			else{
				qui lincom [/]mean(T`k')-[/]mean(T`j')
			}
			qui matrix `covariates'[`t',1]=`r(estimate)'
			qui matrix `covariates'[`t',2]=`r(se)'
			qui matrix `covariates'[`t',3]=`r(z)'
			qui matrix `covariates'[`t',4]=`r(p)'
			qui matrix `covariates'[`t',5]=`r(lb)'
			qui matrix `covariates'[`t',6]=`r(ub)'
			local ++t
		}
		else{
			if "`categorical'"!=""{
				local first=0 
				foreach l in `levelsof`cat1'' {
					if `first'==0 {
						local ++first
					}
					else{
						if `first'==1 {
							qui lincom [T`k']`l'.`cat1'-[T`j']`l'.`cat1'
							qui matrix `covariates'[`t',1]=`r(estimate)'
							qui matrix `covariates'[`t',2]=`r(se)'
							qui matrix `covariates'[`t',3]=`r(z)'
							qui matrix `covariates'[`t',4]=`r(p)'
							qui matrix `covariates'[`t',5]=`r(lb)'
							qui matrix `covariates'[`t',6]=`r(ub)'
							local ++t
							local ++first
						}
					}
				}
			}
			else{
				qui lincom [T`k']`cont1'-[T`j']`cont1'
				qui matrix `covariates'[`t',1]=`r(estimate)'
				qui matrix `covariates'[`t',2]=`r(se)'
				qui matrix `covariates'[`t',3]=`r(z)'
				qui matrix `covariates'[`t',4]=`r(p)'
				qui matrix `covariates'[`t',5]=`r(lb)'
				qui matrix `covariates'[`t',6]=`r(ub)'
				local ++t
			}		
		}
	}
}	
		
forvalues j=1/`timemax'{
	if "`continuous'"!=""|"`categorical'"!="" {
		qui lincom _b[/var(e.T`j')]
	}
	else {
		qui lincom _b[/var(T`j')]
	}
	qui matrix `covariates'[`t',1]=`r(estimate)'
	qui matrix `covariates'[`t',2]=`r(se)'
	qui matrix `covariates'[`t',3]=`r(z)'
	qui matrix `covariates'[`t',4]=`r(p)'
	qui matrix `covariates'[`t',5]=`r(lb)'
	qui matrix `covariates'[`t',6]=`r(ub)'
	local ++t
}
forvalues j=1/`=`timemax'-1'{
	if "`continuous'"!=""|"`categorical'"!="" {
		forvalues k=`=`j'+1'/`timemax'{
			qui lincom _b[/cov(e.T`j',e.T`k')]
			qui matrix `covariates'[`t',1]=`r(estimate)'
			qui matrix `covariates'[`t',2]=`r(se)'
			qui matrix `covariates'[`t',3]=`r(z)'
			qui matrix `covariates'[`t',4]=`r(p)'
			qui matrix `covariates'[`t',5]=`r(lb)'
			qui matrix `covariates'[`t',6]=`r(ub)'
			local ++t
		}
	}
	else{
		forvalues k=`=`j'+1'/`timemax'{
			qui lincom _b[/cov(T`j',T`k')]
			qui matrix `covariates'[`t',1]=`r(estimate)'
			qui matrix `covariates'[`t',2]=`r(se)'
			qui matrix `covariates'[`t',3]=`r(z)'
			qui matrix `covariates'[`t',4]=`r(p)'
			qui matrix `covariates'[`t',5]=`r(lb)'
			qui matrix `covariates'[`t',6]=`r(ub)'
			local ++t
		}
	}
}
forvalues i=1/ `nbcont' {
   qui lincom `cont`i''
   qui matrix `covariates'[`t',1]=`r(estimate)'
   qui matrix `covariates'[`t',2]=`r(se)'
   qui matrix `covariates'[`t',3]=`r(z)'
   qui matrix `covariates'[`t',4]=`r(p)'
   qui matrix `covariates'[`t',5]=`r(lb)'
   qui matrix `covariates'[`t',6]=`r(ub)'
   local ++t
}
forvalues i=1/ `nbcat' {
   local first=0
   foreach j in `levelsof`cat`i''' {
	   if `first'==0 {
	      local ++first
	   }
	   else {
		   qui	lincom `j'.`cat`i''
		   qui matrix `covariates'[`t',1]=`r(estimate)'
		   qui matrix `covariates'[`t',2]=`r(se)'
		   qui matrix `covariates'[`t',3]=`r(z)'
		   qui matrix `covariates'[`t',4]=`r(p)'
		   qui matrix `covariates'[`t',5]=`r(lb)'
		   qui matrix `covariates'[`t',6]=`r(ub)'
		   local ++t
	   }
   }
}


/*************************************************************************************************************
OUTPUTS
*************************************************************************************************************/

if "`postpce'"=="" {
	local t=1
	local diffname
	di "{hline 117}"
	di  as text _col(104) "<--95% IC -->"
	di  as text _col(27) "<---- DIF variables --->"  _col(104) "Lower" _col(112) "Upper"
	di "Items"  _col(27) abbrev("`dif1'",10) _col(39) abbrev("`dif2'",10) _col(56) "Threshold" _col(69) "Estimate" _col(81) "s.e." _col(93) "z" _col(100) "p" _col(103) " Bound" _col(112) "Bound"
	di "{hline 117}"
	forvalues i=1/`nblistitemsdif' {
	   local num: word `i' of `listitemsdifnumbers'
	   forvalues j=1/`modamax`i'' {
		  if "`rsm'"==""|`j'==1 {
			  if `j'==1 {
				 di as text abbrev("`name``num'''",25) _c
				 local it: word `i' of `listitemsdifnumbers'
				 if "`difitems'"!="" {
					local level1: word `i' of `listitemsdiflevels1'
					local level2: word `i' of `listitemsdiflevels2'
					if `nbdifvar'==2&`difitems'[`it',1]==1&`difitems'[`it',2]==1 {
						di as text _col(30) "`level1'" _col(42) "`level2'" _c
					}
					else if `nbdifvar'==2&`difitems'[`it',1]==1&`difitems'[`it',2]==0 {
						di as text _col(30) "`level1'"  _c
					}
					else if `nbdifvar'==2&`difitems'[`it',1]==0&`difitems'[`it',2]==1 {
						di as text _col(42) "`level2'"  _c
					}
					else if `nbdifvar'==1&`difitems'[`it',1]==1 {
						di as text _col(30) "`level1'"  _c
					}
				}
			  }
			  di as text _col(64) %5.2f "`j'" as result _col(72) %5.2f `diff'[`t',1]  _col(80) %5.2f `diff'[`t',2] _col(88) %6.2f `diff'[`t',3] _col(96) %5.3f `diff'[`t',4] _col(104) %5.2f `diff'[`t',5] _col(112) %5.2f `diff'[`t',6] 
			  local ++t
			  local diffname `diffname' `j'.`element`i''
		  }
	   }
	   di
	}
	if "`rsm'"!="" {
		forvalues k=2/`modamax' {
			di as text "tau`k'"  as result _col(72) %5.2f `diff'[`t',1]  _col(80) %5.2f `diff'[`t',2] _col(88) %6.2f `diff'[`t',3] _col(96) %5.3f `diff'[`t',4] _col(104) %5.2f `diff'[`t',5] _col(112) %5.2f `diff'[`t',6] 
			local diffname `diffname' tau`k'
			local ++t
		}
	}
	di as text "{hline 117}"
	local t=1
	local listmoy
	local listvar
	local listcov
	forvalues j=1/`timemax'{
		local listvar `listvar' Variance_T`j'
		forvalues k=`=`j'+1'/`timemax'{
			local listcov `listcov' Cov_T`j'_T`k'
		}
		forvalues k=`=`j'+1'/`timemax'{
			local listmoy `listmoy' Mean_diff_T`j'_T`k'
		}
	}
	local n: word count `listmoy' `listvar' `listcov' 
	forvalues i=1/`n' {
		local v: word `i' of `listmoy' `listvar' `listcov' 
		di as text _col(1) %5.2f "`v'"  as result _col(72) %5.2f `covariates'[`t',1]  _col(80) %5.2f `covariates'[`t',2] _col(88) %6.2f `covariates'[`t',3] _col(96) %5.3f `covariates'[`t',4] _col(104) %5.2f `covariates'[`t',5] _col(112) %5.2f `covariates'[`t',6] 
		local ++t
	}
	local n: word count `continuous' 
	forvalues i=1/`n' {
		local v: word `i' of  `continuous' 
		local v2 :  variable label `v'
		if "`v2'"=="" {
		   local v2 `v'
		}
		di as text _col(1) %5.2f  abbrev("`v2'",20)  as result _col(72) %5.2f `covariates'[`t',1]  _col(80) %5.2f `covariates'[`t',2] _col(88) %6.2f `covariates'[`t',3] _col(96) %5.3f `covariates'[`t',4] _col(104) %5.2f `covariates'[`t',5] _col(112) %5.2f `covariates'[`t',6] 
		local ++t
	}

	local rn Variance `continuous'

	local n: word count  `categorical' 
	local catname
	forvalues i=1/`n' {
		local v: word `i' of `categorical'
		local v2 : variable label `v'
		if "`v2'"=="" {
		   local v2 `v'
		}
		local first=1
		local saute=1
		foreach j in `levelsof`cat`i''' {
			if `saute'==0 {
				if `first'==1 {
					di as text _col(1) abbrev("`v2'",20) _c
				}
				di  as text _col(64) %5.2f "`j'" as result _col(72) %5.2f `covariates'[`t',1]  _col(80) %5.2f `covariates'[`t',2] _col(88) %6.2f `covariates'[`t',3] _col(96) %5.3f `covariates'[`t',4] _col(104) %5.2f `covariates'[`t',5] _col(112) %5.2f `covariates'[`t',6] 
				local ++first
				local rn `rn' `j'.`n'
				local ++t
				local catname `catname' `j'.`v'
			}
			else {
			   local saute=0
			}
		}
	}
	di as text "{hline 117}"
	
	if "`difvar'"!="" {
		if `nbdifvar'==1 {
		    local hlinen=76
		}
		if `nbdifvar'==2 {
		    local hlinen=104
		}
		di as text "{hline `hlinen'}"
		di as text _col(32) "DIF tests" _col(55) "DIF tests: " abbrev("`dif1'",15)
		if `nbdifvar'==2 {
			di as text _col(83) "DIF tests: " abbrev("`dif2'",15) 
		}
		di as text _col(1) "Items" _col(28) "Chi2" _col(36) "df" _col(40) "p-values" _col(56) "Chi2" _col(64) "df" _col(68) "p-values" _c
		if `nbdifvar'==2 {
			di as text _col(84) "Chi2" _col(92) "df" _col(96) "p-values" _c
		}
		di
		di as text "{hline `hlinen'}"
		forvalues i=1/`nbitems' {
			di as text _col(1)  abbrev("``i''",20) _c			
			if `difitems'[`i',1]==1|`difitems'[`i',2]==1{
				di as result _col(25) %7.2f `diftest'[`i',1] _col(35) %3.0f `diftest'[`i',2] _col(43) %5.3f `diftest'[`i',3] _c
			}
			if `difitems'[`i',1]==1{
				di as result _col(53) %7.2f `diftest'[`i',4] _col(63) %3.0f `diftest'[`i',5] _col(71) %5.3f `diftest'[`i',6] _c 
			}
			if `difitems'[`i',2]==1{
				di as result _col(81) %7.2f `diftest'[`i',7] _col(91) %3.0f `diftest'[`i',8] _col(99) %5.3f `diftest'[`i',9]  _c
			}
			di
		}
		di as text "{hline `hlinen'}"
	}
	
	if "`visit'"==""{
		di
		qui su `latent'1 if `touse'
        tempvar se2latent
		qui gen `se2latent'=(`selatent'1)^2 if `touse'
		qui su `se2latent' if `touse'
		local resvar=r(mean)
		di as text "Mean squared std error of the latent variable: " as result %4.2f `resvar'
		di as text "Global variance of the latent variable: " as result %4.2f `=((`covariates'[1,1])+(`resvar'))'
		local PSI=(`covariates'[1,1])/((`covariates'[1,1])+(`resvar'))
		di as text "PSI: " as result %4.2f `PSI' _c
		if "`continuous'"!=""|"`categorical'"!="" {
		    di as text " (without adjustment on covariates)"
	    }
		else {
		    di
		}
		di
		return scalar PSI=`PSI'

	}



	matrix colnames `covariates'=`cn'
	matrix rownames `covariates'=`rn'
}


/*************************************************************************************************************
ESTIMATION OF THE CORRECTED VALUES OF THE LT ESTIMATORS (values of lt that explained the best the score)
**************************************************************************************************************/

tempfile savefile
qui save `savefile'

qui drop _all
		
qui set obs 2000
qui gen u=(_n-1000)/200*`=2*sqrt(`covariates'[1,1])'
qui gen Tcum=0
qui gen TInf=0
forvalues g=1/`nbgroupdif' {
	gen Tcum`g'=0
	forvalues i=1/`nblistitemsdif ' {
		if `matelem'[`g',`i']==1 {
			local d`g'=1
			qui gen cum`g'_`element`i''=0
			local it:word `i' of `listitemsdifnumbers' 
			if "`rsm'"=="" {
				local mm=`modamaxitem`it''
			}
			else {
				local mm `modamax'
			}	
			forvalues k=1/`mm' {
				local d`g' `d`g''+exp(`k'*u-`diffmat2'[`i',`k'])
			}
			qui gen c0_`g'_`element`i''=1/(`d`g'')
			forvalues k=1/`mm' {
				qui gen c`k'_`g'_`element`i''=exp(`k'*u-`diffmat2'[`i',`k'])/(`d`g'')
				qui replace cum`g'_`element`i''=cum`g'_`element`i''+c`k'_`g'_`element`i''*`k'
			}
			qui replace Tcum`g'=Tcum`g'+cum`g'_`element`i''
		}
	}
	local listlt`g'
	forvalues l=0/`scoremax`g'' {
		qui gen ecart`g'_`l'=.
		if `l'==0 {  
		   local j=0.25
		}
		else if `l'==`scoremax`g'' {
		   local j=`scoremax`g''-0.25
		}
		else {
		   local j=`l'
		}
		qui replace ecart`g'_`l'=abs(Tcum`g'-`j')
		qui su ecart`g'_`l'
		local tmp`g'=r(min)
		qui su u if round(ecart`g'_`l', 0.01)==round(`tmp`g'',0.01)
		local estlt`g'_`l'=`r(mean)'
		local listlt`g' `listlt`g'' `estlt`g'_`l''
		qui drop ecart`g'_`l'
	}
}
qui use `savefile', clear



/*************************************************************************************************************
FIT TESTS
*************************************************************************************************************/

/*Quelques explications
latent : estimation EAP du trait latent
latent2 : estimation Plausible Value à partir de l'estimation EAP
corrlatent : estimation corrigée cherchant la meilleur valeur du trait latent qui explique le score, interpolation à partir de l'EAP pour les individus avec des données manquantes
*/

if "`visit'"==""{
    local listres
	tempvar corrlatent corrlatenttmp 
	qui gen `corrlatenttmp'=.
	forvalues s=0/`scoremax' {
		forvalues g=1/`nbgroupdif' {
			qui replace `corrlatenttmp'=`estlt`g'_`s'' if `score'==`s'&`groupdif'==`g'
		}
	}
	qui ipolate `corrlatenttmp' `latent'1 , generate(`corrlatent') epolate
	qui replace `corrlatent'=`corrlatenttmp' if `corrlatenttmp'!=.
	qui replace `corrlatent'=`latent'1 if `corrlatenttmp'==.
	tempname fit
	qui matrix `fit'=J(`nblistitemsdif',6,.)
	matrix colnames `fit'=OUTFIT INFIT "Standardized OUTFIT" "Standardized INFIT" "corrOUTFIT" "corrINFIT"
	matrix rownames `fit'=`varlist'

	
	forvalues c=1/`nbgroupdif' {
		tempvar Tcum`c' TInf`c' /*cum`c'*/
		qui gen `Tcum`c''=0 if `touse'
		qui gen `TInf`c''=0 if `touse'
		forvalues g=1/`nbgroups' {
			qui su `corrlatent' if `group'==`g'&`touse'&`conddif`c''
			if r(N)!=0 {
				qui matrix `groupsdif`c''[`g',`=`nblistitemsdif'+6']=`r(mean)'
				qui matrix `groupsdif`c''[`g',`=`nblistitemsdif'+9']=`r(min)'
				qui matrix `groupsdif`c''[`g',`=`nblistitemsdif'+10']=`r(max)'
			}
		}
	}
	if "`postpce'"=="" {
		di as text "{hline 110}"
		di as text _col(27) "<---- DIF variables ---->" _col(86) "<---  Standardized  --->"
		di as text "Items" _col(27) abbrev("`dif1'",10) _col(40) abbrev("`dif2'",10) _col(59) "OUTFIT" _col(75) "INFIT" _col(89) "OUTFIT" _col(105) "INFIT"
		di as text "{hline 110}"
		di as text "Reference values*" _col(55) "[" %4.2f `=1-6/sqrt(`nbobs')' ";" %4.2f `=1+6/sqrt(`nbobs')' "]" _col(70) "[" %4.2f `=1-2/sqrt(`nbobs')' ";" %4.2f `=1+2/sqrt(`nbobs')' "]" _col(86) "[-2.6;2.6]" _col(101) "[-2.6;2.6]"
		di as text "Reference values**" _col(55) "[0.75;1.30]" _col(70) "[0.75;1.30]" _col(86) "[-2.6;2.6]" _col(101) "[-2.6;2.6]"
		di as text "{hline 110}"
	}
	local chi2=0
	local chi2_old=0
	forvalues g=1/`nbgroups' {
	   local chi2_g`g'=0
	   local chi2_old_g`g'=0
	}
	tempname outfit numinfit denominfit infit noutfit 
	qui gen `outfit'=0
	qui gen `numinfit'=0
	qui gen `denominfit'=0
	qui gen `infit'=0
	qui gen `noutfit'=0
	forvalues i=1/`nblistitemsdif' {
		if "`rsm'"=="" {
			local mm=`modamax`i''
		}
		else {
			local mm `modamax'
		}	
		tempvar cum_old`element`i'' c_old0_`element`i'' Inf_old`element`i'' y_old`element`i'' y2_old`element`i''  	
		tempvar cum`element`i'' c0_`element`i'' Inf`element`i'' C`element`i'' C2`element`i'' C3`element`i'' y`element`i'' y2`element`i'' z`element`i'' z2`element`i'' i`element`i'' 
		tempvar corrcum`element`i'' corrc0_`element`i'' corrInf`element`i'' corry`element`i'' corrz`element`i'' corrz2`element`i'' corri`element`i'' 

		local d=1
		local corrd=1
		local d_old=1
		qui gen `corrcum`element`i'''=0 if `touse'
		qui gen `cum`element`i'''=0 if `touse'
		qui gen `cum_old`element`i'''=0 if `touse'
		forvalues k=1/`mm' {
			local corrd `corrd'+exp(`k'*`corrlatent'-`diffmat2'[`i',`k'])
			local d `d'+exp(`k'*`latent2'-`diffmat2'[`i',`k'])
			local d_old `d_old'+exp(`k'*`latent'1-`diffmat2'[`i',`k'])
		}
		qui gen `corrc0_`element`i'''=1/(`corrd') if `touse' 
		qui gen `c0_`element`i'''=1/(`d') if `touse' 
		qui gen `c_old0_`element`i'''=1/(`d_old') if `touse'
		forvalues k=1/`mm' {
			tempvar corrc`k'_`element`i'' c`k'_`element`i'' c_old`k'_`element`i'' ci`k'_`element`i''
			qui gen `corrc`k'_`element`i'''=exp(`k'*`corrlatent'-`diffmat2'[`i',`k'])/(`corrd') if `touse'
			qui gen `c`k'_`element`i'''=exp(`k'*`latent2'-`diffmat2'[`i',`k'])/(`d') if `touse'
			qui gen `c_old`k'_`element`i'''=exp(`k'*`latent'1-`diffmat2'[`i',`k'])/(`d') if `touse'
			qui replace `corrcum`element`i'''=`corrcum`element`i'''+`corrc`k'_`element`i'''*`k' if `touse'
			qui replace `cum`element`i'''=`cum`element`i'''+`c`k'_`element`i'''*`k' if `touse'
			qui replace `cum_old`element`i'''=`cum_old`element`i'''+`c_old`k'_`element`i'''*`k' if `touse'
		}
		qui gen `corrInf`element`i'''=0 if `touse'
		qui gen `Inf`element`i'''=0 if `touse'
		qui gen `Inf_old`element`i'''=0 if `touse'
		qui gen `C`element`i'''=0 if `touse'
		forvalues k=0/`mm' {
			qui replace `corrInf`element`i'''=`corrInf`element`i'''+(`k'-`corrcum`element`i''')^2*`corrc`k'_`element`i''' if `touse'
			qui replace `Inf`element`i'''=`Inf`element`i'''+(`k'-`cum`element`i''')^2*`c`k'_`element`i''' if `touse'
			qui replace `Inf_old`element`i'''=`Inf_old`element`i'''+(`k'-`cum_old`element`i''')^2*`c_old`k'_`element`i''' if `touse'
			qui replace `C`element`i'''=`C`element`i'''+(`k'-`cum`element`i''')^4*`c`k'_`element`i''' if `touse'
		}
		qui count if `element`i''!=.&`touse'
		local n`element`i''=r(N)
		
		qui gen `C2`element`i'''=`C`element`i'''/((`Inf`element`i''')^2) if `touse'
		qui su `C2`element`i''' if `touse'
		local q2o`element`i''=(`r(mean)'-1)/((`n`element`i'''))

		qui gen `C3`element`i'''=`C`element`i'''-(`Inf`element`i''')^2 if `touse'
		qui su `C3`element`i'''
		local n=r(sum)
		qui su `Inf`element`i''' if `touse'
		local d=r(sum)
		local q2i`element`i''=`n'/((`d')^2)
		
		forvalues c=1/`nbgroupdif' {
			if `matelem'[`c',`i']==1 {
				qui replace `Tcum`c''=`Tcum`c''+`cum`element`i''' if `touse'
				qui replace `TInf`c''=`TInf`c''+`Inf`element`i''' if `touse'
			}
		}
		qui gen `corry`element`i'''=`element`i''-`corrcum`element`i''' if `touse'
		qui gen `y`element`i'''=`element`i''-`cum`element`i''' if `touse'
		qui gen `y_old`element`i'''=`element`i''-`cum_old`element`i''' if `touse'
		qui gen `y2`element`i'''=(`y`element`i''')^2 if `touse'
		qui gen `y2_old`element`i'''=(`y_old`element`i''')^2 if `touse'
		qui gen `corrz`element`i'''=(`corry`element`i'''/sqrt(`corrInf`element`i''')) if `touse'
		qui gen `z`element`i'''=(`y`element`i'''/sqrt(`Inf`element`i''')) if `touse'
		
		label variable `z`element`i''' "``i''"
		local listres `listres' `z`element`i'''
		local chi2_`element`i''=0
		local chi2_old_`element`i''=0
		forvalues g=1/`nbgroups' {
			
			qui su `y2`element`i''' if `group'==`g'&`touse'
			local n=r(sum)
			qui su `element`i'' if `group'==`g'&`touse'
			local n1=r(sum)
			qui su `cum`element`i''' if `group'==`g'&`touse'
			local n2=r(sum)
			qui su `Inf`element`i''' if `group'==`g'&`touse'
			local d=r(sum)
			local chi2=`chi2'+/*`eff'**/(`n1'-`n2')^2/(`d')
			local chi2_`element`i''=`chi2_`element`i'''+/*`eff'**/(`n1'-`n2')^2/(`d')
			local chi2_g`g'=`chi2_g`g''+/*`eff'**/(`n1'-`n2')^2/(`d')
			qui su `y2_old`element`i''' if `group'==`g'&`touse'
			local n_old=r(sum)
			qui su `element`i'' if `group'==`g'&`touse'
			local n1_old=r(sum)
			qui su `cum_old`element`i''' if `group'==`g'&`touse'
			local n2_old=r(sum)
			qui su `Inf_old`element`i''' if `group'==`g'&`touse'
			local d_old=r(sum)
			local chi2_old=`chi2_old'+(`n1_old'-`n2_old')^2/(`d_old')
			local chi2_old_`element`i''=`chi2_old_`element`i'''+(`n_old')/(`d_old')
			local chi2_old_g`g'=`chi2_old_g`g''+(`n_old')/(`d_old')
		}
		label variable `corrz`element`i''' "Standardized residuals "
		label variable `z`element`i''' "EAP standardized residuals "
		label variable `latent'1 "EAP latent trait"
		label variable `latent2' "EAP/PV latent trait"
		label variable `corrlatent' "Latent trait"
		tempname groupscoreelement`i'
		qui gen `groupscoreelement`i''=.
		local it: word `i' of `listitemsdifnumbers'
		forvalues m=0/`modamaxitem`it'' {
		    local minscoremoda`m'=.
		    local maxscoremoda`m'=.
		    forvalues s=0/`scoremax' {
			    qui count if `score'==`s'&`element`i''==`m'
				*tab `score' `element`i''
				qui replace `groupscoreelement`i''=`r(N)' if `score'==`s'&`element`i''==`m'
				if `r(N)'>0&`minscoremoda`m''==. {
					local minscoremoda`m'=`s'
				}
				if `r(N)'>0 {
					local maxscoremoda`m'=`s'
				}					
			}
		}
		if  "`graphs'"!=""&"`graphitems'"=="" {
			if "`filesave'"!="" {
				local fs saving("`dirsave'//residuals_`element`i''",replace)
			}
			local thr=abs(invnorm(`alpha'/2))
			tempvar id`element`i''
			local hline
			forvalues l=1/`modamax`i'' {
				local hline `hline' `=`diffmat'[`i',`l']'
			}
			if "`residuals'"=="" {
				if "`difvar'"!="" {
					local desc`i'
					local ext`i'
				    local it: word `i' of `listitemsdifnumbers'
				    local it1: word `i' of `listitemsdiflevels1'
				    local it2: word `i' of `listitemsdiflevels2'
					if `difitems'[`it',1]==1 {
						local desc`i' "`desc`i'' - `dif1'=`it1'"
						local ext`i' "`ext`i''_`dif1'`it1'"
					}
					if `difitems'[`it',2]==1 {
						local desc`i' "`desc`i'' - `dif2'=`it2'"
						local ext`i' "`ext`i''_`dif2'`it2'"
					}
				}
				qui count if `z`element`i'''!=.
				local nit=r(N)
				local desc`i' "`desc`i'' - n=`nit'"
				qui su `corrlatent' if `touse'
				local minlt=r(min)
				local maxlt=r(max)
				local minlt=floor(min(`minlt',-1))
				local maxlt=ceil(max(`maxlt',1))
				local corr
				if "`corrected'"=="" {
					local corr corr
				}
					/*qui gen `id`element`i'''=`groupscoreelement`i'' if abs(`z`element`i''')>`thr'
					qui tostring `id`element`i''',replace
					qui replace `id`element`i'''="" if `id`element`i'''=="."&`touse'
					qui count  if abs(`z`element`i''')>`thr'&`z`element`i'''!=.
					local abbvalues`i'=r(N)
					local pour=round(`abbvalues`i''/`nit'*1000,1)/10
					local abbpour`i' "n=`abbvalues`i'' (`pour'%)"
					qui su `z`element`i''' if `touse'
					local min=r(min)
					local max=r(max)
					local min=floor(min(`min',-3))
					local max=ceil(max(`max',3))
					qui graph twoway scatter `z`element`i''' `latent2'  if `touse', jitter(`jitter') xlabel(`minlt'(1)`maxlt') xline(`hline',lwidth(vthin)  lcolor(gray))  colordiscrete colorvar(``it'') colorlist(blue green orange purple gray red cyan ) ylabel(`min'(1)`max') yline(-`thr' `thr', lcolor(black) lpattern(dash)) yline(0,lcolor(black) lpattern(solid))  mlabel(`id`element`i''') name(res_``it''`ext`i'',replace) title("EAP/PV based standardized residuals") subtitle(`name``it''' `desc`i'' ) t2title(Abberant observations: `abbpour`i'' - Expected `=`alpha'*100'%) `fs' 
				}
				else {
					*/
					qui gen `id`element`i'''=""
					forvalues m=0/`modamaxitem`it'' {
						qui count if (``corr'z`element`i''')>`thr'&`element`i''==`m'
						local high`m'=`r(N)'
						qui count if (``corr'z`element`i''')<-`thr'&`element`i''==`m'
						local low`m'=`r(N)'
						if `low`m''!=0|`high`m''!=0 {
							qui replace `id`element`i'''="n=`high`m''" if `score'==`minscoremoda`m''&`score'!=.&`element`i''==`m'&`high`m''!=0
							qui replace `id`element`i'''="n=`low`m''" if `score'==`maxscoremoda`m''&`score'!=.&`element`i''==`m'&`low`m''!=0
						}
					}
					*qui tostring `id`element`i''',replace
					*qui replace `id`element`i'''="" if `id`element`i'''=="."&`touse'
					qui count  if abs(``corr'z`element`i''')>`thr'&``corr'z`element`i'''!=.
					local abbvalues`i'=r(N)
					local pour=round(`abbvalues`i''/`nit'*1000,1)/10
					local abbpour`i' "n=`abbvalues`i'' (`pour'%)"
					qui su ``corr'z`element`i''' if `touse'
					local min=r(min)
					local max=r(max)
					local min=floor(min(`min',-3))
					local max=ceil(max(`max',3))
					qui graph twoway scatter ``corr'z`element`i''' ``corr'latent'  if `touse', jitter(`jitter') xlabel(`minlt'(1)`maxlt') xline(`hline',lwidth(vthin)  lcolor(gray))  colordiscrete colorvar(``it'') colorlist(blue green orange purple gray red cyan ) ylabel(`min'(1)`max') yline(-`thr' `thr', lcolor(black) lpattern(dash)) yline(0,lcolor(black) lpattern(solid))  mlabel(`id`element`i''') name(res_``it''`ext`i'',replace) title("Standardized residuals") subtitle(`name``it''' `desc`i'' ) t2title(Outliers: `abbpour`i'' - Expected `=`alpha'*100'%) `fs' 
						
					/*
					qui gen `id`element`i'''=`groupscoreelement`i'' if abs(``corr'z`element`i''')>`thr'
					qui tostring `id`element`i''',replace
					qui replace `id`element`i'''="" if `id`element`i'''=="."&`touse'
					qui count  if abs(``corr'z`element`i''')>`thr'&``corr'z`element`i'''!=.
					local abbvalues`i'=r(N)
					local pour=round(`abbvalues`i''/`nit'*1000,1)/10
					local abbpour`i' "n=`abbvalues`i'' (`pour'%)"
					qui su ``corr'z`element`i''' if `touse'
					local min=r(min)
					local max=r(max)
					local min=floor(min(`min',-3))
					local max=ceil(max(`max',3))
					qui graph twoway scatter ``corr'z`element`i''' ``corr'latent'  if `touse', jitter(`jitter') xlabel(`minlt'(1)`maxlt') xline(`hline',lwidth(vthin)  lcolor(gray))  colordiscrete colorvar(``it'') colorlist(blue green orange purple gray red cyan ) ylabel(`min'(1)`max') yline(-`thr' `thr', lcolor(black) lpattern(dash)) yline(0,lcolor(black) lpattern(solid))  mlabel(`id`element`i''') name(res_``it''`ext`i'',replace) title("Standardized residuals") subtitle(`name``it''' `desc`i'' ) t2title(Abberant observations: `abbpour`i'' - Expected `=`alpha'*100'%) `fs' 
					*/
				*}
			}
		}
		qui gen `z2`element`i'''=(`z`element`i''')^2 if `touse'
		qui su `z2`element`i''' if `touse'
				local OUTFIT`element`i''=`r(mean)'
		qui matrix `fit'[`i',1]=`OUTFIT`element`i'''
		local OUTFITs`element`i''=((`r(mean)')^(1/3)-1)*(3/sqrt(`q2o`element`i'''))+sqrt(`q2o`element`i''')/3
		qui matrix `fit'[`i',3]=`OUTFITs`element`i'''
		qui su `Inf`element`i''' if `element`i''!=.&`touse'
		local sumw`element`i''=r(sum)
		qui gen `i`element`i'''=`Inf`element`i'''*`z2`element`i''' if `touse' 
		qui su `i`element`i''' if `element`i''!=.&`touse'
		local INFIT`element`i'' = `=`r(sum)'/`sumw`element`i''''
		qui matrix `fit'[`i',2]=`INFIT`element`i'''
		local INFITs`element`i''=(`=`r(sum)'/`sumw`element`i''''^(1/3)-1)*(3/sqrt(`q2i`element`i'''))+sqrt(`q2i`element`i''')/3
		qui matrix `fit'[`i',4]=`INFITs`element`i'''
		
		
		/*OUTFIT ET INFIT INDIVIDUEL*/

		qui replace `outfit'=`outfit'+`z2`element`i''' if `z2`element`i'''!=.
		qui replace `noutfit'=`noutfit'+1 if `z2`element`i'''!=. 
		qui replace `numinfit'=`numinfit'+`i`element`i''' if `z2`element`i'''!=.
		qui replace `denominfit'=`denominfit'+`sumw`element`i''' if `z2`element`i'''!=.
		
		/*corrected*/
		qui gen `corrz2`element`i'''=(`corrz`element`i''')^2 if `touse'
		qui su `corrz2`element`i''' if `touse'
		local corrOUTFIT`element`i''=`r(mean)'
		qui matrix `fit'[`i',5]=`corrOUTFIT`element`i'''
		qui su `corrInf`element`i''' if `element`i''!=.&`touse'
		local corrsumw`element`i''=r(sum)
		qui gen `corri`element`i'''=`corrInf`element`i'''*`corrz2`element`i''' if `touse' 
		qui su `corri`element`i''' if `element`i''!=.&`touse'
		local corrINFIT`element`i'' = `=`r(sum)'/`corrsumw`element`i''''
		qui matrix `fit'[`i',6]=`corrINFIT`element`i'''


		if "`postpce'"=="" {
			 local it: word `i' of `listitemsdifnumbers'
			 di as text abbrev("`name``it'''",25) _c
			 if "`difitems'"!="" {
				local level1: word `i' of `listitemsdiflevels1'
				local level2: word `i' of `listitemsdiflevels2'
				if `nbdifvar'==2&`difitems'[`it',1]==1&`difitems'[`it',2]==1 {
					di as text _col(27) "`level1'" _col(40) "`level2'" _c
				}
				else if `nbdifvar'==2&`difitems'[`it',1]==1&`difitems'[`it',2]==0 {
					di as text _col(27) "`level1'"  _c
				}
				else if `nbdifvar'==2&`difitems'[`it',1]==0&`difitems'[`it',2]==1 {
					di as text _col(40) "`level2'"  _c
				}
				else if `nbdifvar'==1&`difitems'[`it',1]==1 {
					di as text _col(27) "`level1'"  _c
				}
			}
			di as result _col(60) %5.3f `OUTFIT`element`i''' _col(75) %5.3f `INFIT`element`i''' _col(89) %6.3f `OUTFITs`element`i''' _col(104) %6.3f `INFITs`element`i''' 
		}
	}
	/*OUTFIT ET INFIT INDIVIDUEL*/
	qui replace `outfit'=`outfit'/`noutfit'
	qui replace `infit'=`numinfit'/`denominfit'
	/*Remettre les deux lignes suivantes si on veut les outfit/infit par individus*/
	*graph twoway scatter `outfit' `latent2',title(Outfit) name(outfit)
	*graph twoway scatter `infit' `latent2',title(Infit) name(infit)
	*/
	
	if "`postpce'"=="" {
		di as text "{hline 110}"
		di as text "*: As suggested by Wright (Smith, 1998)"
		di as text "**: As suggested by Bond and Fox (2007)"
	}
	if "`geninf'"!="" {
	    qui gen `geninf'=. if `touse'
		forvalues c=1/`nbgroupdif' {
			qui replace `geninf'=`TInf`c'' if `touse'&`TInf`c''!=.
		}
	}
	local listres2
	forvalues i=1/`nbitems' {
		tempvar res`i'
		qui gen `res`i''=.
		forvalues j=`debut`i''/`=`debut`i''+`nbitem`i''-1' {
			qui replace `res`i''=`z`element`j''' if `res`i''==.
		}
		local listres2 `listres2' `res`i''
		label variable `res`i'' ``i''
	}	
	di
	if "`pca'"!="" {
		di "{hline 100}"
		di "Principal Components Analysis on residuals"
		di "{hline 100}"
		tempname correlation
		*su `listres2' if `touse'
		qui pwcorr `listres2' if `touse'
		matrix `correlation'=r(C)
		matrix colnames `correlation'=`varlist'
		matrix rownames `correlation'=`varlist'
		di "Correlation coefficients between residuals"
		matrix list `correlation', noheader  format(%5.3f)
		di "{hline 100}"
		local comp=min(`nbitems',5)
		*pca `listres2',blanks(0.4) components(`comp')
		if `pcasim'>0 {
			tempfile jbhpca
			tempname pcam
			qui save `jbhpca', replace
			matrix `pcam'=J(`pcasim',1,.)
			qui count if `touse'
			local ntouse=r(N)
			forvalues r=1/`pcasim' {
				qui drop _all
				qui set obs `ntouse'
				forvalues i=1/`nblistitemsdif' {
					 qui gen item`i'=invnorm(uniform())
				}
				qui pca item*
				matrix `pcam'[`r',1]= e(Ev)[1,1]
			}
			qui drop _all
			qui svmat `pcam'
			qui centile `pcam'1, centile(`pcacentile')
			local ev= `r(ub_1)'
			di
			di "Parallel analysis:"
			di "`pcacentile'th percentile of first eigenvalues obtained with `pcasim' simulations:" %6.3f `ev'
			qui use `jbhpca', clear
			*set trace off
		}
		di
		pcamat `correlation' , n(`nbobs') names(`varlist') blanks(0.3) components(`comp')
		if "`paran'"!="" {
			paran `listres2'  if `touse',  centile(95) iteration(100) graph seed(6327456) all
		}
		*set trace on
	}
	
}

/*************************************************************************************************************
ESTIMATION OF THE WEIGHTED ML ESTIMATORS
**************************************************************************************************************/

if "`postpce'"!="" {
    local conv=10
	local it=`wmliterate'
	di "Iteration : `it'"
	while(`conv'>=1) {
		di "Iteration `it' : conv=`conv'"
		tempvar   sinf
		qui gen `sinf'=sqrt(TInf_`=`it'-1') if `touse'
		`qui' pcm `varlist' [iweight=`sinf'] if `touse',diff(loulou) wmliterate(`it') geninf(TInf_`it') genlt(lt_`it') 
		tempvar  ecart_`it' 
		qui gen `ecart_`it''=abs(lt_`it'-lt_`=`it'-1') if `touse'
		qui su `ecart_`it'' if `touse'
		local conv =r(mean)
		local ++it
	}
    exit	
}

/*************************************************************************************************************
RESULTS BY GROUP (IN PRESENCE OF DIF OR NOT)
*************************************************************************************************************/

if "`visit'"=="" {
    tempname matscorelt matgroupscorelt matgroupscoremdltdif
	qui matrix `matscorelt'=J(`=`nbitems'*`modamax'+1',`=4*`nbgroupdif'',.)
	tempname /*matscoreltdif*/ matgroupscoreltdif
	qui matrix `matgroupscoreltdif'=J(`nbgroups',`=`nbgroupdif'*3+4',.)
	qui matrix `matgroupscoremdltdif'=J(`nbgroups',`=`nbgroupdif'*3+4',.)
	
	local row=1
	local gap=43
	di
	local hline=`nbgroupdif'*`gap'+16
	di as text "{hline `hline'}"
	local col=20
	forvalues c=1/`nbgroupdif' {
		if `nbgroupdif'>1 {
			di _col(`col') "<--- `cond2dif`c''" _col(`=`col'+36')  "--->   " _c
		}
		local col=`col'+`gap'
	}
	if `nbgroupdif'>1 {
		di
	}
	local col=20
	forvalues c=1/`nbgroupdif' {
		di _col(`=`col'+8') "Latent Trait" _col(`=`col'+22') "Expected" _col(`=`col'+31') "Corrected" _c
		local col=`col'+`gap'
	}
	local col=20
	di
	di "Group" _col(10) "Score" _c
	forvalues c=1/`nbgroupdif' {
	    di _col(`=`col'') "Freq" _col(`=`col'+8') "Mean" _col(`=`col'+16') "s.e." _col(`=`col'+25') "Score" _col(`=`col'+32') "Estimate"  _c
		local col=`col'+`gap'
	}
	di
	di as text "{hline `hline'}"
	forvalues g=1/`nbgroups' {
		qui su `score'`multivisit' if `group'`multivisit'==`g'&`touse'
		if `r(N)'>0 {
			local scoremin`g'=`r(min)'
			local scoremax`g'=`r(max)'
			qui count if `group'==`g'&`touse'
			local eff`g'=r(N)
			qui count if `group'==`g'&`score'!=.&`touse'
			local effcompleted`g'=r(N)
			di as text "`g' (n=" as result `eff`g'' as text ")" _c
			if `effcompleted`g''>0 {
				forvalues s=`scoremin`g''/`scoremax`g'' {
					local col=20
					di as text _col(12) %3.0f `s' _c
					forvalues c=1/`nbgroupdif' {
						qui count if `group'==`g'&`score'==`s'&`touse'&`conddif`c''
						local effscore`s'c`c'=r(N)
						if `effscore`s'c`c''!=0 {
							qui su `latent'1 if `group'==`g'&`score'==`s'&`touse'&`conddif`c''
							local mean=r(mean)
							*matrix `groupsdif`c''[`g',`=`nblistitemsdif'+6']=`estlt`c'_`s''
							local ltscore`s'c`c'=`=ceil(`r(mean)'*1000)/1000'
							qui su `selatent'1 if `group'==`g'&`score'==`s'&`touse'&`conddif`c''
							local selatent`s'c`c'=r(mean)
							qui su `Tcum`c'' if `score'==`s'&`touse'&`conddif`c''
							local exp=r(mean)
							di as result _col(`col')  %4.0f `effscore`s'c`c'' _col(`=`col'+6') %6.3f `ltscore`s'c`c'' _col(`=`col'+14') %6.3f `selatent`s'c`c'' _col(`=`col'+24')   %6.2f  `exp' _col(`=`col'+34') %6.3f `estlt`c'_`s'' _c
							qui matrix `matscorelt'[`=`s'+1',`=`c'*4-3']=`effscore`s'c`c''
							qui matrix `matscorelt'[`=`s'+1',`=`c'*4-2']=`ltscore`s'c`c''
							qui matrix `matscorelt'[`=`s'+1',`=`c'*4-1']=`selatent`s'c`c''
							if "`estlt`c'_`s''"!="" {
								qui matrix `matscorelt'[`=`s'+1',`=`c'*4-0']=`estlt`c'_`s''
							}
							local ++row
						}
						local col=`col'+`gap' 
					}
					local ++row
					di			
				}
			}
		}
		qui count if `group'==`g'&`score'==.&`touse'
		local eff_md_`g'=r(N)
		qui matrix `matgroupscoremdltdif'[`g',1]=`g'
		qui matrix `matgroupscoremdltdif'[`g',4]=`eff_md_`g''
		if `eff_md_`g''>0 {
			local col=20
			di as text _col(14)  "." _c
			forvalues c=1/`nbgroupdif' {
				qui count if `group'==`g'&`score'==.&`touse'&`conddif`c''
				local effscoremd`g'c`c'=r(N)
				if `effscoremd`g'c`c''!=0 {
					qui su `latent'1 if `group'==`g'&`score'==.&`touse'&`conddif`c''
					local mean=r(mean)
					local ltscoremd`g'c`c'=`=ceil(`r(mean)'*1000)/1000'
					qui su `selatent'1 if `group'==`g'&`score'==.&`touse'&`conddif`c''
					local selatentmdc`c'=r(mean)
					qui su `Tcum`c'' if `group'`multivisit'==`g'&`score'==.&`touse'&`conddif`c''
					local exp=r(mean)
					qui su `corrlatent' if `group'==`g'&`score'==.&`touse'&`conddif`c''
					local meancorr=r(mean)
				
					di as result _col(`col')  %4.0f `effscoremd`g'c`c'' _col(`=`col'+6') %6.3f `ltscoremd`g'c`c'' _col(`=`col'+14') %6.3f `selatentmdc`c'' _col(`=`col'+24')   %6.2f `exp' _col(`=`col'+34') %6.3f  `meancorr' _c
					local ++row
					qui matrix `matgroupscoremdltdif'[`g',`=4+(`c'-1)*3+1']=`effscoremd`g'c`c''
					qui matrix `matgroupscoremdltdif'[`g',`=4+(`c'-1)*3+2']=`ltscoremd`g'c`c''
					qui matrix `matgroupscoremdltdif'[`g',`=4+(`c'-1)*3+3']=`selatentmdc`c''
				}
				else {
					qui matrix `matgroupscoremdltdif'[`g',`=4+(`c'-1)*3+1']=0
				}
				local col=`col'+`gap' 
			}
			local ++row
			di			
		}
		local col=20
		di as text _col(10) "{dup `=`gap'*`nbgroupdif'+7':-}"
		di as text _col(10) "`scoremin`g''/`scoremax`g''" _c
		qui matrix `matgroupscoreltdif'[`g',1]=`g'
		if "`scoremin`g''"!="" {
			qui matrix `matgroupscoreltdif'[`g',2]=`scoremin`g''
		}
		if "`scoremax`g''"!="" {
			qui matrix `matgroupscoreltdif'[`g',3]=`scoremax`g''
		}
		if "`eff`g''"!="" {
			qui matrix `matgroupscoreltdif'[`g',4]=`eff`g''
		}
		forvalues c=1/`nbgroupdif' {
			qui su `latent'1 if `group'`multivisit'==`g'&`touse'&`conddif`c''
			if `r(N)'>0 {
				local eff`g'_c`c'=r(N)
				local lt`g'_c`c'=r(mean)
				qui su `selatent'1 if `group'`multivisit'==`g'&`touse'&`conddif`c''
				local selt`g'_c`c'=r(mean)
				qui su `Tcum`c'' if `group'`multivisit'==`g'&`touse'&`conddif`c''
				local exp=r(mean)
				if "`scoremin`g''"=="" {
					local scoremin`g' "."
				}
				if "`scoremax`g''"=="" {
					local scoremax`g' "."
				}
				qui su `corrlatent' if `group'==`g'&`touse'&`conddif`c''
				local meancorr=r(mean)
				di as result _col(`col')  %4.0f `eff`g'_c`c'' _col(`=`col'+6') %6.3f `lt`g'_c`c'' _col(`=`col'+14') %6.3f `selt`g'_c`c'' _col(`=`col'+24') %6.2f `exp' _col(`=`col'+34') %6.3f  `meancorr' _c
			}
			local col=`col'+`gap'
			if "`eff`g'_c`c''"!="" {
				qui matrix `matgroupscoreltdif'[`g',`=4+(`c'-1)*3+1']=`eff`g'_c`c''
				qui matrix `matgroupscoreltdif'[`g',`=4+(`c'-1)*3+2']=`lt`g'_c`c''
				qui matrix `matgroupscoreltdif'[`g',`=4+(`c'-1)*3+3']=`selt`g'_c`c''
			}			
			else {
				qui matrix `matgroupscoreltdif'[`g',`=4+(`c'-1)*3+1']=0
			}
		}
		di
		di as text "{hline `hline'}"
		local ++row
	}
}	


/*************************************************************************************************************
Categories/Items/Test Characteristics Curves and Information graphs
*************************************************************************************************************/
if "`visit'"==""{
	local listofcolors stc1 stc2 stc3 stc4 stc5 stc6 stc7 stc8
	local listofpatterns solid dash longdash shortdash
	local xtitle "Latent trait" 
	forvalues j=1/`nbitems' {
		local mini`j'=`nblistitemsdif'
		local maxi`j'=0
		local xline`j' 
	}
	forvalues i=1/`nblistitemsdif' {
		local it: word `i' of `listitemsdifnumbers'
		local mini`it'=min(`i',`mini`it'')
		local maxi`it'=max(`i',`mini`it'')
	}
	local gstot
	local gsctot
	forvalues c=1/`nbgroupdif' {
		forvalues g=1/`nbgroups' {
			local colortxt: word `c' of `listofcolors'
			qui su `latent2' if `group'==`g'&`touse'&`conddif`c''
			local eff`c'=r(N)
			local xtot`c'=r(mean)
			local xmintot`c'=r(min)
			local xmaxtot`c'=r(max)
			qui su `corrlatent' if `group'==`g'&`touse'&`conddif`c''
			local xctot`c'=r(mean)
			local xcmintot`c'=r(min)
			local xcmaxtot`c'=r(max)
			qui su `score' if `group'==`g'&`touse'&`conddif`c''
			local ytot`c'=r(mean)
			local seuil=`minsize'/`nbgroupdif'
			local s vtiny
			*set trace on
			foreach lab in  /*tiny*/ vsmall small medsmall medium medlarge  large   vlarge  huge vhuge /*ehuge*/ {
				if `eff`c''>`seuil' {
					local s `lab'
				}
				local seuil=`seuil'+`minsize'/((`nbgroupdif'*`nbgroups'*2))
			}
			if `eff`c''==0 {
				local sef=1
			}
			else {
				local sef=2*`wobs'*`nbgroupdif'*(ln(`eff`c''/`minsize')+1)
			}
			*set trace off
			local gstot `gstot' || (scatteri `ytot`c'' `xtot`c'' , mcolor(`colortxt') /*msize(`s')*/ msize(*`sef') /*legend(off)*/ msymbol(circle_hollow)) || (pci `ytot`c'' `xmintot`c''  `ytot`c'' `xmaxtot`c'' ,lcolor(`colortxt'))
			local gsctot `gsctot' ||  (scatteri `ytot`c'' `xctot`c'' , mcolor(`colortxt') /*msize(`s')*/ msize(*`sef') /*legend(off)*/ msymbol(circle_hollow))|| (pci `ytot`c'' `xcmintot`c''  `ytot`c'' `xcmaxtot`c'' ,lcolor(`colortxt'))
		}
	}

	tempfile savefile
	qui save `savefile'

	qui drop _all
	local pas=1000*round(`=sqrt(`covariates'[1,1])',0.001)
	local pas=round(`pas')
	qui set obs `pas'
	qui gen u=round((_n-`pas'/2)/(`pas'/10)*`=sqrt(`covariates'[1,1])',0.01)
	qui su u
	local maxaxis=ceil(max(abs(`r(min)'),abs(`r(max)')))
	if "`graphitems'"=="" {
		if "`filesave'"!="" {
			local fsc saving("`dirsave'//CCC_``i''",replace)
			local fsi saving("`dirsave'//ICC_``i''",replace)
		}
	}
	gen density2=normalden(u)*`=sqrt(`covariates'[1,1])'

	forvalues c=1/`nbgroupdif' {
		qui gen Tcum`c'=0
		qui gen TInf`c'=0
		qui gen ecartcum`c'=.
		qui gen ecartcumw`c'=.

		forvalues i=1/`nbitems' {
			qui gen Tcum`c'_``i''=0
			qui gen TInf`c'_``i''=0
			local ccc`c'_``i''
			local ccci`c'_``i''
			local icc`c'_``i''
			local color=0
			local lp=0

			forvalues j=`mini`i''/`maxi`i'' {
				local ++color
				local ++lp
				local scatteri`j' scatteri . .
				local scatteric`j' scatteri . .
				local colortxt: word `color' of `listofcolors'
				*matrix list `groupsdif`c''
				forvalues g=1/`nbgroups' {
					local x=`groupsdif`c''[`g',`=`nblistitemsdif'+1']
					local xc=`groupsdif`c''[`g',`=`nblistitemsdif'+6']
					local xmin=`groupsdif`c''[`g',`=`nblistitemsdif'+7']
					local xmax=`groupsdif`c''[`g',`=`nblistitemsdif'+8']
					local xcmin=`groupsdif`c''[`g',`=`nblistitemsdif'+9']
					local xcmax=`groupsdif`c''[`g',`=`nblistitemsdif'+10']
					local y=`groupsdif`c''[`g',`j']
					local s1=`groupsdif`c''[`g',`=`nblistitemsdif'+2']
				
					local seuil=`minsize'/`nbgroupdif'
					local s vtiny
					foreach lab in  /*tiny*/ vsmall small medsmall medium medlarge  large   vlarge  huge vhuge /*ehuge*/ {
						if `s1'>`seuil' {
							local s `lab'
						}
						local seuil=`seuil'+`minsize'/(`nbgroups'*2)
					}
					local sef=2*`wobs'*`nbgroupdif'*(ln(`s1'/`minsize')+1)
					local scatteri`j' `scatteri`j'' || scatteri `y' `x' , mcolor(`colortxt') /*msize(`s')*/ msize(*`sef') legend(off) msymbol(circle_hollow) || pci `y' `xmin'  `y' `xmax' ,lcolor(`colortxt')
					local scatteric`j' `scatteric`j''  || scatteri `y' `xc' , mcolor(`colortxt') /*msize(`s')*/ msize(*`sef') legend(off) msymbol(circle_hollow)|| pci `y' `xcmin'  `y' `xcmax' ,lcolor(`colortxt')
				}
				local Gscatteri``i'' "`Gscatteri``i''' || `scatteri`j''"
				local Gscatteric``i'' "`Gscatteric``i''' || `scatteric`j''"
				local d`c'=1
				qui gen cum`c'_`element`j''=0
				qui gen cumi`c'_`element`j''=0
				if "`rsm'"=="" {
					local mm=`modamaxitem`i''
				}
				else {
					local mm `modamax'
				}
				if `matelem'[`c',`j']==1 {
					forvalues k=1/`mm' {
						local d`c' `d`c''+exp(`k'*u-`diffmat2'[`j',`k'])
					}
				
					qui gen c0_`c'_`element`j''=1/(`d`c'')
					if "`labelgr`j''"=="" {
						local tiret
					}
					else {
						local tiret -
					}
					label variable c0_`c'_`element`j'' "Pr(X=0) `tiret' `labelgr`j''"
					local yline
					forvalues k=1/`mm' {
						qui gen c`k'_`c'_`element`j''=exp(`k'*u-`diffmat2'[`j',`k'])/(`d`c'')
						qui replace cum`c'_`element`j''=cum`c'_`element`j''+c`k'_`c'_`element`j''*`k'
						label variable c`k'_`c'_`element`j'' "Pr(X=`k') `tiret' `labelgr`j''"
						local yline `yline' `=`k'-0.5'
						local colo: word `=`k'+1' of `listofcolors'
						if `matelem2'[`c',`j']==1 {
							local xline`i' `xline`i'' xline(`=`diffmat'[`j',`k']',lcolor(`colo') lwidth(vthin) )
						}
					}
					qui gen Inf`c'_`element`j''=0
					label variable Inf`c'_`element`j'' "`name`element`j'''"
					forvalues k=0/`mm' {
						local colo: word `=`k'+1' of `listofcolors'
						qui replace Inf`c'_`element`j''=Inf`c'_`element`j''+(`k'-cum`c'_`element`j'')^2*c`k'_`c'_`element`j''
						qui gen ci`k'_`c'_`element`j''=c`k'_`c'_`element`j''*sqrt(Inf`c'_`element`j'')
						*qui gen ci`k'_`c'_`element`j''=c`k'_`c'_`element`j''*(density2)
						label variable ci`k'_`c'_`element`j'' "Pr(X=`k') `tiret'  `labelgr`j''"
						local patt: word `lp' of `listofpatterns'
						if `matelem2'[`c',`j']==1 {
							local ccc`c'_``i'' "`ccc`c'_``i''' (line c`k'_`c'_`element`j'' u, lcolor(`colo') lpattern(`patt'))"
							*di "ccc`c'_``i'' : `ccc`c'_``i'''"
							local ccci`c'_``i'' "`ccci`c'_``i''' (line ci`k'_`c'_`element`j'' u, lcolor(`colo') lpattern(`patt'))"
						}
					}
					if `nbitem`i''==1 {
					    local tmp off
					}
					else {
					    local tmp on
					}
					
					if `matelem2'[`c',`j']==1 {
						local icc`c'_``i'' "`icc`c'_``i''' (line cum`c'_`element`j'' u, legend(`tmp'))"
					}
					label variable cum`c'_`element`j'' "`element`j'' - `labelgr`j''"
					*gen cumw`c'_`element`j''=cum`c'_`element`j''*sqrt(Inf`c'_`element`j'')
					gen cumw`c'_`element`j''=cum`c'_`element`j''*density2
					forvalues k=0/`mm' {
						if `k'==0 {
						   local l=0.25
						}
						else if `k'==`mm' {
						   local l=`k'-0.25
						}
						else {
						   local l=`k'
						}
						qui replace ecartcum`c'=abs(cum`c'_`element`j''-`l')
						qui su ecartcum`c'
						qui su u if round(ecartcum`c',0.01)==round(`r(min)',0.01)
						local bestest`j'_`k'=r(mean)
						qui su ci`k'_`c'_`element`j''
						qui su u if round(ci`k'_`c'_`element`j'',0.01)==round(`r(max)',0.01)
						local bestestw`j'_`k'=r(mean)
					}
					qui replace Tcum`c'_``i''=Tcum`c'_``i''+cum`c'_`element`j''
					qui replace TInf`c'_``i''=TInf`c'_``i''+Inf`c'_`element`j''	
					label variable Tcum`c'_``i'' "``i'' - `labelgr`j''"
					label variable TInf`c'_``i'' "``i'' - `labelgr`j''"
					qui replace Tcum`c'=Tcum`c'+Tcum`c'_``i''
					qui replace TInf`c'=TInf`c'+TInf`c'_``i''	
				}
			label variable Tcum`c' "`labelgr`j''"
			label variable TInf`c' "`labelgr`j''"
			}
		}
		qui gen TInfp`c'_`1'=TInf`c'_`1'/TInf`c'*100	
		forvalues i=2/`nbitems' {
			local tmp=`i'-1
			qui gen TInfp`c'_``i''=TInfp`c'_``tmp''+TInf`c'_``i''/TInf`c'*100	
			label variable TInfp`c'_``i'' "``i'' - `labelgr`j''"
		}
	}
	local xlinetot
	*local gstot
	local unit=max(ceil(`maxaxis'/7),1)	
			
	local xlabel xlabel(-`maxaxis'(`unit')`maxaxis') 
	*di "xlabel : `xlabel'"
	forvalues i=1/`nbitems' {
		local xlinetot `xlinetot' `xline`i''
		forvalues c=1/`nbgroupdif' {
			local ccc``i'' `ccc``i''' `ccc`c'_``i'''
			local ccci``i'' `ccci``i''' `ccci`c'_``i'''
			local icc``i'' `icc``i''' `icc`c'_``i'''
		}
		if "`corrected'"!="" {
			local gs `Gscatteri``i'''
			local gstotf `gstot'
		}
		else {
			local gs `Gscatteric``i'''
			local gstotf `gsctot'
		}
		if "`obs'"!="" {
			local gs
			local gstotf
		}
		else {
			local gs || `gs'
			local gstotf `gstotf'
		}
		if "`graphitems'"=="" {
			if "`graphs'"!="" {
				qui graph twoway `ccc``i''' , name(CCC``i'', replace) title(Categories Characteristic Curve (CCC)) subtitle(`name``i''') ytitle("Probability") xtitle("`xtitle'") `fsc' `xline`i'' `xlabel'
				if "`wccc'"!="" {
					qui graph twoway `ccc``i''' `ccci``i''' , name(CCCi``i'', replace) title(Weighted Categories Characteristic Curve (CCC)) subtitle(`name``i''') ytitle("Probability") xtitle("`xtitle'") `fsc' `xline`i'' `xlabel'
				}
				*di "qui graph twoway `icc``i''', name(ICC``i'',replace) title(Item Characteristic Curve (ICC)) subtitle(`name``i''') ytitle(Expected score to the item) xtitle(`xtitle')  `gs' `fsi' `xline`i'' ylabel(0(.5)`modamaxitem`i'') `xlabel'"
				qui graph twoway `icc``i''', name(ICC``i'',replace) title("Item Characteristic Curve (ICC)") subtitle(`name``i''') ytitle("Expected score to the item") xtitle("`xtitle'")  `gs' `fsi' `xline`i'' ylabel(0(.5)`modamaxitem`i'') `xlabel'
			}
		}
	}
	if "`filesave'"!="" {
		local fstcc saving("`dirsave'//TCC",replace)
		*local fsteo saving("`dirsave'//TCCeo",replace)
		forvalues c=1/`nbgroupdif' {
			local fsiic`c' saving("`dirsave'//IIC`c'",replace)
			local fstic`c' saving("`dirsave'//TIC`c'",replace)
			local fsiir`c' saving("`dirsave'//IIR`c'",replace)
		}
		local fstic saving("`dirsave'//TIC",replace)
		*local fstii saving("`dirsave'//TICi",replace)
		local fsm saving("`dirsave'//map",replace)
	}
	if "`graphs'"!="" {
		local grTInf
		local grTcum
		if `nbgroupdif'==1 {
			local legend legend(off)
		}
		else {
			local legend legend(on order(
		}
		forvalues c=1/`nbgroupdif' {
			local id=1
			gen cumInf`c'_0=0
			gen cumInfp`c'_0=0
			local grInf`c'
			local grcumInf`c'
			local grcumInfp`c'
			label variable TInf`c' "`cond2dif`c''"
			if "`cond2dif`c''" =="" {
				label variable Tcum`c' "Expected score"
			}
			else {
				label variable Tcum`c' "`cond2dif`c''"
				local legend `legend' `c' 
			}
			local grTInf `grTInf' TInf`c'
			local grTcum `grTcum' Tcum`c'
			forvalues i=1/`nblistitemsdif' {
				local it:word `i' of `listitemsdifnumbers'
				if `matelem'[`c',`i']==1 {
					gen cumInf`c'_`id'=cumInf`c'_`=`id'-1'+Inf`c'_`element`i''
					if "`labelgr`i''"=="" {
						label variable Inf`c'_`element`i'' "``it''"
						label variable cumInf`c'_`id' "``it''"
						label variable TInfp`c'_``it'' "``it''"
					}
					else {
						label variable Inf`c'_`element`i'' "``it'' - `labelgr`i''"
						label variable cumInf`c'_`id' "``it'' - `labelgr`i''"
						label variable TInfp`c'_``it'' "``it'' - `labelgr`i''"
					}
					local grInf`c' `grInf`c'' Inf`c'_`element`i''
					local grcumInf`c'  cumInf`c'_`id' `grcumInf`c''
					local grcumInfp`c'   TInfp`c'_``it'' `grcumInfp`c''
					local ++id
				}
			}
			qui graph twoway line `grInf`c'' u, name(IIC`c',replace) title("Item Information Curves") t1title("`cond2dif`c''") ytitle("Information") xtitle("`xtitle'")  `fsiic`c'' subtitle(`dimname') `xlabel'
			qui graph twoway (area `grcumInf`c''  u, lwidth(thin)) /*(line TInf`c' u, lwidth(thick))*/, name(TIC`c',replace) title("Test/Item Information Curves") ytitle("Information") xtitle("`xtitle'")  `fstic' subtitle(`dimname') t1title("`cond2dif`c''") `xlabel'
			qui graph twoway (area `grcumInfp`c''  u, lwidth(thin)) /*(line TInf`c' u, lwidth(thick))*/, name(IIR`c',replace) title("Item Information Ratios") ytitle("Information ratio (%)") xtitle("`xtitle'")  `fsiir' subtitle(`dimname') t1title("`cond2dif`c''") `xlabel' ylabel(0(20)100)
		}
		if `nbgroupdif'>1 {
			local legend `legend'))
		}
		*set trace on
		qui graph twoway line `grTcum' u `gstotf',`legend'  name(TCC,replace) title("Test Characteristic Curve (TCC)") ytitle("Expected Score") xtitle("`xtitle'")  `fstcc' subtitle(`dimname') ylabel(0(1)`scoremax',labsize(vsmall)) `xlinetot' /*xline(`listlt',lwidth(vthin) lcolor(gray)) */ `xlabel'
		*set trace off
		qui graph twoway line `grTInf' u, name(TIC,replace) title("Test Information Curve") ytitle("Information") xtitle("`xtitle'")  `fstic' subtitle(`dimname') `xlabel'

	}
	
	
/*************************************************************************************************************
MAP
*************************************************************************************************************/
*set trace on
	if "`graphs'"!=""|"`eqset1'"!="" {
		gen eff=0
		gen eff_md=0
		local effmax=0
		qui gen uceil=ceil(u*100)/100
		local eff
		forvalues c=1/`nbgroupdif' {
			gen eff`c'=0
			local eff `eff' eff`c'
			forvalues s=0/`scoremax' {
				if "`effscore`s'c`c''"=="" {
				   local effscore`s'c`c'=0
				}
				if `effscore`s'c`c''>`effmax' {
				   local effmax=`effscore`s'c`c''
				}
				qui replace eff`c'=`effscore`s'c`c'' if round(u,0.01)==round(`ltscore`s'c`c'',0.01)
				qui replace eff=`effscore`s'c`c'' if round(u,0.01)==round(`ltscore`s'c`c'',0.01)
			}
		}
		forvalues g=1/`nbgroups' {
			if `eff_md_`g''>`effmax' {
			   local effmax=`eff_md_`g''
			}
			forvalues c=1/`nbgroupdif' {
				if "`effscoremd`g'c`c''"!=""&"`effscoremd`g'c`c''"!="0" {
					qui replace eff_md=`effscoremd`g'c`c'' if round(u,0.01)==round(`ltscoremd`g'c`c'',0.01)
				}
			}
		}

		gen density=normalden(u)*sqrt(`covariates'[1,1])
		label variable eff "Complete"
		label variable eff_md "Incomplete"
		label variable u "Latent trait"
		label variable density "Density function of the latent trait"
		local scatteri
		local scatterj
		local color 
		qui su u if eff!=0|eff_md!=0
		local floor=floor(`r(min)')
		local ceil=ceil(`r(max)')
		local sep
		local ylbl
		local low=round(`effmax'/(`=`nbitems''),1)
		local unit=round(`effmax'/(`=`nbitems''),1)
		local ysuiv=-`unit'
		local y=`ysuiv'
		forvalues i=1/`nblistitemsdif' {
			local it:word `i' of `listitemsdifnumbers'
			if `i'>1 {
			     local itprec:word `=`i'-1' of `listitemsdifnumbers'
			}
			else {
				local itprec=0
				local low=`unit'
			}
			local color`i':word `i' of `listofcolors'
			if `it'!=`itprec' {
				local y=`ysuiv'
			}
			else {
		   		local y=`ysuiv'
			}
			local ysuiv=`y'-`unit'/(`nbitem`it'')
			local yprec=`y'
			local staritem
			local isdys
			local legend `"`=4+`nbgroupdif'' "cat 1""'
			forvalues l=1/`modamax' {
				if `l'>=2 {
					local legend `" `legend' `=2+`nbgroupdif'+2*`l'' "cat `l'" "'
				}			   
				local x=`diffmat'[`i',`l']
				local scatteri `scatteri' || scatteri `y' `x' "`l'" ,mcolor(black) mlabcolor(black)
				if `l'==1 {
					local xant=`x'
				}
				else {
					local xant=`diffmat'[`i',`=`l'-1']
				}
				if `xant'>`x' {
					local star *
					local staritem *
					local isdys="* : dysfunctioning items -"
				}
				else {
					local star
				}
				local scatterj `" `scatterj' `sep' scatteri `y' `x'   , pstyle(p`l') || pci `y' `xant' `y' `x', pstyle(p1) color(black)"'
				local sep ||
				if `x'<`floor' {
					local floor=floor(`x')
				}
				if `x'>`ceil'&`x'!=. {
					local ceil=ceil(`x')
				}
			}
			local it: word `i' of `listitemsdifnumbers'
			local nomcourt``i''=abbrev("``it''",20)
			if `it'!=`itprec' {
				local ylbl `ylbl' `y' "`nomcourt``i'''`staritem'"
			}
			local scatteri `scatteri' || scatteri `y' `=`floor'-2' "``i''",mcolor(black) mlabcolor(black) msize(vtiny)
		}
		qui su eff
		local maxe=ceil(`=(floor(`r(max)'/10)+1)*10')
		qui su eff_md
		local maxe_md=ceil(`=(floor(`r(max)'/10)+1)*10')
		local maxe=max(`maxe',`maxe_md')
		local maxi=0
		local Tinf
		forvalues c=1/`nbgroupdif' {
			qui su TInf`c'
			local maxi=max(`maxi',1.2*ceil(`r(max)'))
			local Tinf `Tinf' TInf`c'
		}
		qui su density
		local maxd=round(`r(max)', 0.01)+0.01
		qui drop if u<`floor'|u>`ceil'
		if "`eqset1'"==""&"`graphs'"!="" {
			local nbcolslegende=max(2,`modamax')
			if `modamax'==1 {
			   local holes "holes(2)"
			}
			tempvar line1 line2 line3 line4 line5
			qui gen `line1'=.
			label variable `line1' "Density"
			local line
			local num
			forvalues c=1/`nbgroupdif' {
			    local c2=`c'+1
				qui gen `line`c2''=.
				if "`cond2dif`c''"=="" {
					label variable `line`c2'' "Information"
				}
				else {
				    label variable `line`c2'' "Inf (`cond2dif`c'')"
					local lblinf "Inf: Information -"
				}
				local line `line' `line`c2'' 
				local num `num' `c2' 
			}
			local size small
			if `nbitems'>8 {
				local size vsmall
			}
			if `nbitems'>15 {
				local size tiny
			}
			qui graph twoway (line `line1' u ,lwidth(medthick) lcolo(stc5)) (line `line' u ,lwidth(medthick medthick medthick medthick) lcolo(stc1 stc2 stc3 stc4)) (line density u,yaxis(3) lwidth(medthick) lcolo(stc5) ) (bar eff u,  barwidth(.1) yaxis(1) xlabel(`floor'(1)`ceil') color(erose) )  (bar eff_md u,  barwidth(.05) yaxis(1) xlabel(`floor'(1)`ceil') color(stred) )  (line `Tinf' u,yaxis(2) lwidth(medthick medthick medthick medthick) lcolo(stc1 stc2 stc3 stc4) ) `scatterj'   , xline(0, lcolor(black)) legend(on position(3)     /*symysize(*.6) symxsize(*.6) textwidth(*.6)*/ /*cols(`nbcolslegende')*/ cols(1)  `holes' order(`"- "Functions" 1 `num' - "" - "Patterns" `=`nbgroupdif'+2' `=`nbgroupdif'+3' - "" - "Thresholds" `legend'  "') /*subtitle(Threshold parameters,size(*.7)) */size(small)) name(map,replace) ytitle("                           Frequencies")  ylabel(0(`=`maxi'/5')`maxi' `maxi'(`maxi')`=`maxi'*2' ,axis(2)) yscale(axis(2) off) yscale(axis(3) off)  ylabel(-`maxd'(`=`maxd'/5')`maxd' ,axis(3)) yline(0,lwidth(medium) lpattern(solid) lcolor(black))  ylabel(`ylbl',/*noticks*/ labsize(`size') grid angle(0) axis(1)) ylabel(`ylbl' 0(`=`maxe'/5')`maxe', grid angle(0) axis(1)) title("Individuals/items representations (Map)") xsize(12) ysize(9) note("`isdys' `lblinf' cat=answer categories") xtitle("`xtitle'") `fsm' subtitle(`dimname')
		}
		else if "`eqset1'"!="" {
			qui su eff
	        local ceil=ceil(ceil(`r(max)'/10)*10)

            qui tempfile equating
			qui save `equating', replace
		}
	}
	qui use `savefile', clear
}
		 


/*************************************************************************************************************
Most likely estimates for each response category
*************************************************************************************************************/

tempname bestest bestesti
matrix `bestest'=J(`nblistitemsdif',`=`modamax'+1',.)
matrix `bestesti'=J(`nblistitemsdif',`=`modamax'+1',.)
di
local long=`modamax'*16+72
di
di "Most likely estimates for each response category" 
di "{hline `long'}"
di _col(27) "<---- DIF Variables ---->" _col(56) "Unweighted" _col(`=68+`modamax'*8') "Weighted" 
di "Item" _col(27) abbrev("`dif1'",10) _col(42) abbrev("`dif2'",10)   _c
forvalues j=0/`modamax' {
     local col=56+`j'*8 
	 di _col(`col') "Cat `j'"     _c
}
forvalues j=0/`modamax' {
     local col=68+`modamax'*8+`j'*8 
	 di _col(`col') "Cat `j'"     _c
}
di
di "{hline `long'}"
forvalues i=1/`nblistitemsdif' {
	local it: word `i' of `listitemsdifnumbers'
	di as text abbrev("`name``it'''",25) _c
	if "`difitems'"!="" {
		local level1: word `i' of `listitemsdiflevels1'
		local level2: word `i' of `listitemsdiflevels2'
		if `nbdifvar'==2&`difitems'[`it',1]==1&`difitems'[`it',2]==1 {
			di as text _col(27) "`level1'" _col(40) "`level2'" _c
		}
		else if `nbdifvar'==2&`difitems'[`it',1]==1&`difitems'[`it',2]==0 {
			di as text _col(27) "`level1'"  _c
		}
		else if `nbdifvar'==2&`difitems'[`it',1]==0&`difitems'[`it',2]==1 {
			di as text _col(40) "`level2'"  _c
		}
		else if `nbdifvar'==1&`difitems'[`it',1]==1 {
			di as text _col(27) "`level1'"  _c
		}
	}
	forvalues j=0/`modamax`i'' {
		matrix `bestest'[`i',`=`j'+1']=`bestest`i'_`j''
	    di as result _col(`=55+`j'*8') %6.3f round(`bestest'[`i',`=`j'+1'], 0.001) _c
	}
	forvalues j=0/`modamax`i'' {
		matrix `bestesti'[`i',`=`j'+1']=`bestestw`i'_`j''
	    di as result _col(`=67+`modamax'*8+`j'*8') %6.3f round(`bestesti'[`i',`=`j'+1'], 0.001) _c
	}
	di
}
di as text "{hline `long'}"
		


/*************************************************************************************************************
EQUATING
*************************************************************************************************************/

if "`eqset1'"!="" {
    if "`eqgenscore'"!="" {
	   local tmp1 `=ustrlen("`eqgenscore'`eqset1name'")'
	   local tmp2 `=ustrlen("`eqgenscore'`eqset2name'")'
	   local mlength=max(`tmp1',`tmp2')
	   if `mlength'>27 {
			di as error "The number of characters containing in the strings eqgenscore+eqset1name or eqgenscore+eqset2name must be lesser than 27"
			di as error "eqgenscore+eqset1name : `tmp1' characters"
			di as error "eqgenscore+eqset2name : `tmp2' characters"
			error 130
		}
	}
	if "`eqset1name'"=="" {
	   local eqset1name="Set_1"
	}
	else if `c(version)'>17 {
		local eqset1name `=regexreplaceall("`eqset1name'"," ","_",.)'
	}
	if "`eqset2name'"=="" {
	   local eqset2name="Set_2"
	}
	else if `c(version)'>17 {
		local eqset2name `=regexreplaceall("`eqset2name'"," ","_",.)'
	}

    tokenize `eqset1'
	local nbset1: word count `eqset1'
	forvalues i=1/`nbset1' {
	   local eq1_`i':word `i' of `eqset1'
	}
    tokenize `eqset2'
	local nbset2: word count  `eqset2'
	forvalues i=1/`nbset2' {
	   local eq2_`i':word `i' of `eqset2'
	}	



	tempfile fileeq
	qui save `fileeq',replace
	forvalues t=1/2{
		local scoremaxset`t'=0
		forvalues i=1/`nbset`t'' {
			qui su `eq`t'_`i''
			local modamaxitem`eq`t'_`i''=r(max)
			local scoremaxset`t'=`scoremaxset`t''+`modamaxitem`eq`t'_`i'''
		}
	}
	drop _all
	qui set obs `=(`scoremaxset1'+`scoremaxset2'+2)*3'
	forvalues t=1/2 {
		qui gen scoreset`t'=.
		qui gen scoreset`t'm=.
		qui gen scoreset`t'p=.	
	}
	forvalues i=0/`scoremaxset1' {
	    qui replace scoreset1=`i' in `=`i'+1'
	    qui replace scoreset1m=`i' in `=`i'+1+(`scoremaxset1'+`scoremaxset2'+2)'
	    qui replace scoreset1p=`i' in `=`i'+1+(`scoremaxset1'+`scoremaxset2'+2)*2'
	}
	forvalues i=`=`scoremaxset1'+2'/`=`scoremaxset1'+`scoremaxset2'+2' {
	    qui replace scoreset2=`i'-`scoremaxset1'-2 in `i'
	    qui replace scoreset2m=`i'-`scoremaxset1'-2 in `=`i'+(`scoremaxset1'+`scoremaxset2'+2)'
	    qui replace scoreset2p=`i'-`scoremaxset1'-2 in `=`i'+(`scoremaxset1'+`scoremaxset2'+2)*2'
	}
	local s=0
	local eqset1b
	foreach i in `eqset1' {
		qui gen s1_`i'=0
		forvalues m=1/`modamaxitem`i'' {
		   qui gen s1_`i'_`m'=0 in 1/`=`scoremaxset1'+1'
		   qui replace s1_`i'_`m'=1 if scoreset1>`s' in 1/`=`scoremaxset1'+1'
		   qui replace s1_`i'=s1_`i'+s1_`i'_`m'
		   local ++s
		}
	    local eqset1b `eqset1b' s1_`i'
	}
	local s=0
	local eqset2b
	foreach i in `eqset2' {
		qui gen s2_`i'=0
		forvalues m=1/`modamaxitem`i'' {
		   qui gen s2_`i'_`m'=0 in `=`scoremaxset1'+2'/`=`scoremaxset1'+`scoremaxset2'+2'
		   qui replace s2_`i'_`m'=1 if scoreset2>`s' in `=`scoremaxset1'+2'/`=`scoremaxset1'+`scoremaxset2'+2'
		   qui replace s2_`i'=s2_`i'+s2_`i'_`m'
		   local ++s
		}
		local eqset2b `eqset2b' s2_`i'
	}
	tokenize `varlist'
	tempname diffset1 diffset2
	forvalues t=1/2 {
		qui matrix `diffset`t''=J(`nbset`t'',`modamax',.)
		local n=1
		local listset`t'
		foreach j in `eqset`t'' {
			forvalues i=1/`nbitems' {
				if "`j'"=="``i''" {
					local listset`t' `listset`t'' `i'
					forvalues m=1/`modamax' {
						qui matrix `diffset`t''[`n',`m']=`diffmat'[`i',`m']
					}
					local ++n						
				}
			}
		}
	}
	local var=`covariates'[1,1]
	qui gen lt=.
	forvalues t=1/2 {
		tempname matscorelt`t'
		qui pcm `eqset`t'b', diff(`diffset`t'') var(`var') minsize(1)
		qui matrix `matscorelt`t''=r(matscorelt)
		forvalues i=0/`scoremaxset`t'' {
			qui replace lt=`matscorelt`t''[`=`i'+1',2] if scoreset`t'==`i'
			qui replace lt=`matscorelt`t''[`=`i'+1',2]+1.96*`matscorelt`t''[`=`i'+1',3] if scoreset`t'p==`i'
			qui replace lt=`matscorelt`t''[`=`i'+1',2]-1.96*`matscorelt`t''[`=`i'+1',3] if scoreset`t'm==`i'
		}
		qui ipolate scoreset`t' lt, gen(score`t') epolate
	}
	qui ipolate scoreset1 lt, gen(score1bis) epolate


	forvalues t=1/2 {
		qui replace score`t'=scoreset`t'm if scoreset`t'm!=.
		qui replace score`t'=scoreset`t'p if scoreset`t'p!=.
		qui replace score1=score1bis if score1==.
		qui replace score`t'=0 if score`t'<0
		qui replace score`t'=`scoremaxset`t'' if score`t'>`scoremaxset`t''
	}
	local pciset1
	local pciset2
	local minimini=0
	local maximaxi=0
	forvalues t=1/2 {
        qui gen adjscore`t'=(score`t'+`eqaddset`t'')*`eqmultset`t''
	    qui gen adjscore`=3-`t''=(score`=3-`t''+`eqaddset`=3-`t''')*`eqmultset`=3-`t'''
		tempname matscore`t'
		qui matrix `matscore`t''=J(`=`scoremaxset`t''+1',7,.)
		forvalues s=0/`scoremaxset`t'' {
		    qui matrix `matscore`t''[`=`s'+1',1]=`s'
			qui su lt if scoreset`t'==`s'
		    qui matrix `matscore`t''[`=`s'+1',2]=r(mean)
			if `ceil'==0 {
				local ceil=1
			}
			if "`eqwithci'"=="" {
				local pciset`t'  `pciset`t'' scatteri `=-`ceil'/5*`t'' `r(mean)' (12) "`=round((`s'+`eqaddset`t'')*`eqmultset`t'',1)'"  , mlabsize(tiny) mcolor(black) mlabcolor(black)||
			}
			local mean=r(mean)
			qui su lt if scoreset`t'm==`s'
		    qui matrix `matscore`t''[`=`s'+1',3]=r(mean)
			local moins=r(mean)
			if `moins'<`minimini' {
				local minimini=floor(`moins')
			}
			qui su lt if scoreset`t'p==`s'
		    qui matrix `matscore`t''[`=`s'+1',4]=r(mean)
			local plus=r(mean)
			if `plus'>`maximaxi' {
				local maximaxi=ceil(`plus')
			}

			if "`eqwithci'"!="" {
				local y=-`ceil'/5*((2.5*`t'-2)+2*(`s'/`scoremaxset`t''))
				local pciset`t'  `pciset`t'' scatteri `y' `mean'  , mlabsize(tiny) mcolor(black) mlabcolor(black)|| scatteri `y' `moins' (9) "`=round((`s'+`eqaddset`t'')*`eqmultset`t'',1)'"  , msize(0) mlabsize(tiny) mcolor(black) mlabcolor(black)|| pci `y' `moins' `y' `plus',pstyle(p1) color(black)||
			}
			qui su score`=3-`t'' if scoreset`t'==`s'
		    qui matrix `matscore`t''[`=`s'+1',5]=r(mean)
			qui su score`=3-`t'' if scoreset`t'm==`s'
		    qui matrix `matscore`t''[`=`s'+1',6]=r(mean)
			qui su score`=3-`t'' if scoreset`t'p==`s'
		    qui matrix `matscore`t''[`=`s'+1',7]=r(mean)
		}
		matrix colnames `matscore`t'' =score`t' lt lt- lt+ score`=3-`t'' score`=3-`t''- score`=3-`t''+
		di as text
		di as text "{hline 78}"
		di as text "EQUATING `eqset`t'name' TO `eqset`=3-`t''name'"
		di as text "{hline 78}"
		di "`eqset`t'name' : `eqset`t''"
		di "`eqset`=3-`t''name' : `eqset`=3-`t'''"
		local eqset`t'namea=abbrev("`eqset`t'name'",18)
		local eqset`=3-`t''namea=abbrev("`eqset`=3-`t''name'",12)
		di "{hline 78}"
		di "Score"           _col(20) "<----- Latent trait ----->" _col(52) "<- Score `eqset`=3-`t''namea'" _col(77) "->"
		di "`eqset`t'namea'" _col(20) "Estimated" _col(39) "[95%IC]" _col(52) "Estimated" _col(72) "[95%IC]"
		di "{hline 78}"
		forvalues s=0/`scoremaxset`t'' {
		    local min=min(`=(`matscore`t''[`=`s'+1',6]+`eqaddset`=3-`t''')*`eqmultset`=3-`t'''',`=(`matscore`t''[`=`s'+1',7]+`eqaddset`=3-`t''')*`eqmultset`=3-`t'''')
		    local max=max(`=(`matscore`t''[`=`s'+1',6]+`eqaddset`=3-`t''')*`eqmultset`=3-`t'''',`=(`matscore`t''[`=`s'+1',7]+`eqaddset`=3-`t''')*`eqmultset`=3-`t'''')
			
			di %4.0f `=(`matscore`t''[`=`s'+1',1]+`eqaddset`t'')*`eqmultset`t''' _col(24) %5.2f `matscore`t''[`=`s'+1',2] _col(33) "[" %5.2f `matscore`t''[`=`s'+1',3] ";" %5.2f `matscore`t''[`=`s'+1',4] "]" _col(56) %5.2f `=(`matscore`t''[`=`s'+1',5]+`eqaddset`=3-`t''')*`eqmultset`=3-`t'''' _col(66) "[" %5.2f `min' ";" %5.2f `max' "]"			
		}
		di "{hline 78}"
		if "`eqgraph'"!="" {
			if `eqmultset`=3-`t'''>0 {
				local xlabel 	"`=`eqaddset`=3-`t'''*`eqmultset`=3-`t''''(`=ceil((`scoremaxset`=3-`t'''*`eqmultset`=3-`t''')/20)')`=(`scoremaxset`=3-`t'''+`eqaddset`=3-`t''')*`eqmultset`=3-`t''''"
			}
			else {
				local xlabel 	"`=(`scoremaxset`=3-`t'''+`eqaddset`=3-`t''')*`eqmultset`=3-`t''''(`=ceil((-`scoremaxset`=3-`t'''*`eqmultset`=3-`t''')/20)')`=`eqaddset`=3-`t'''*`eqmultset`=3-`t''''"
			}
			if `eqmultset`t''>0 {
				local ylabel 	"`=`eqaddset`t''*`eqmultset`t'''(`=ceil((`scoremaxset`t''*`eqmultset`t'')/20)')`=(`scoremaxset`t''+`eqaddset`t'')*`eqmultset`t'''"
			}
			else {
				local ylabel 	"`=(`scoremaxset`t''+`eqaddset`t'')*`eqmultset`t'''(`=ceil((-`scoremaxset`t''*`eqmultset`t'')/20)')`=`eqaddset`t''*`eqmultset`t'''"
			}
			twoway (line adjscore`t' adjscore`=3-`t'' if scoreset`=3-`t''!=.,lcolor(black) lpattern(solid) lwidth(thick)) (line adjscore`t' adjscore`=3-`t'' if scoreset`=3-`t''m!=.,lcolor(black) lpattern(dash) lwidth(thin)) (line adjscore`t' adjscore`=3-`t'' if scoreset`=3-`t''p!=.,lcolor(black) lpattern(dash) lwidth(thin)), title("Equating score of `eqset`=3-`t''name' to `eqset`t'name' ") ytitle("Score `eqset`t'name'") xtitle("Score `eqset`=3-`t''name'") ylabel(`ylabel') xlabel(`xlabel') name(eq`t'to`=3-`t'') legend(order(1 2) label(1 "Estimated") label(2 "95%IC") position(6)) subtitle("`dimname'") 
		}
		qui drop adjscore`t' adjscore`=3-`t''
	}
	
	if "`eqgraph'"!="" {
		qui use "`equating'",clear
	    qui su u
	    local flooru=floor(`r(min)')
	    local ceilu=ceil(`r(max)')
		qui su eff
	    local ceil=ceil(ceil(`r(max)'/10)*10)
		if `ceil'==0 {
		   local ceil=1
		}

		local title "Equating"
		if "`eqset1name'"!=""&"`eqset2name'"!=""{
		   local title "Equating between `eqset1name' and `eqset2name'"
		}
		if "`eqwithci'"=="" {
		   local ylabel1=-`ceil'/5
		   local ylabel2=-2*`ceil'/5
		   local gapu=ceil((`ceilu'-`flooru')/15)
		}
		else {
		    local ylabel1=-0.5*`ceil'/5
		    local ylabel2=-3*`ceil'/5
		   	local flooru=min(`flooru',`minimini')
			local ceilu=max(`ceilu',`maximaxi')
			local gapu=ceil((`ceilu'-`flooru')/15)
		}
	    qui graph twoway (bar eff u, barwidth(.2) yaxis(1) xlabel(`flooru'(`gapu')`ceilu') color(erose)) || `pciset1' `pciset2'  , yline(0, lcolor(black)) legend(off) name(equating,replace) ytitle("                           Frequencies")    /*ylabel(`ylbl', grid angle(0) axis(1))*/ ylabel(`ylabel1' "`eqset1name'" `ylabel2' "`eqset2name'" 0(`=`ceil'/5')`ceil', grid angle(0) axis(1)) title("`title'") subtitle("`dimname'") xsize(12) ysize(9)  xtitle("Latent trait") 
	}
	qui use `fileeq',clear
	tempname scoreset1 scoreset2
	forvalues t=1/2 {
		qui genscore `eqset`t'' if `touse',score(`scoreset`t'')
	 	qui su `scoreset`t'' if `touse'
		local maxscoreset=r(max)
		if "`eqgenscore'"!="" {
			local eqgenscore `=regexreplaceall("`eqgenscore'"," ","_")'
			foreach k in mean min max random {
				capture confirm  variable `eqgenscore'_`k'_`eqset`=3-`t''name'
				if _rc==0&"`replace'"!="" {
					qui replace `eqgenscore'_`k'_`eqset`=3-`t''name'=. if `touse'
				}
				else if _rc==0&"`replace'"!="" {
					di as error "The variable `eqgenscore'_`k'_`eqset`=3-`t''name' already exists"
					error 198
				}
				else {
					qui gen `eqgenscore'_`k'_`eqset`=3-`t''name'=. if `touse'
				}
			}
			forvalues s=0/`maxscoreset' {
				local min=min(`=(`matscore`t''[`=`s'+1',6]+`eqaddset`=3-`t''')*`eqmultset`=3-`t'''',`=(`matscore`t''[`=`s'+1',7]+`eqaddset`=3-`t''')*`eqmultset`=3-`t'''')
				local max=max(`=(`matscore`t''[`=`s'+1',6]+`eqaddset`=3-`t''')*`eqmultset`=3-`t'''',`=(`matscore`t''[`=`s'+1',7]+`eqaddset`=3-`t''')*`eqmultset`=3-`t'''')
				qui replace `eqgenscore'_mean_`eqset`=3-`t''name'=round(`=(`matscore`t''[`=`s'+1',5]+`eqaddset`=3-`t''')*`eqmultset`=3-`t'''',1) if round(`scoreset`t'',1)==`s'&`touse'
				qui replace `eqgenscore'_min_`eqset`=3-`t''name'=round(`min',1) if round(`scoreset`t'',1)==`s'&`touse'
				qui replace `eqgenscore'_max_`eqset`=3-`t''name'=round(`max',1) if round(`scoreset`t'',1)==`s'&`touse'
				qui replace `eqgenscore'_random_`eqset`=3-`t''name'=round(uniform()*(`max'-`min')+`min',1) if round(`scoreset`t'',1)==`s'&`touse'
			}
		}
		return matrix score`t'_to_`=3-`t''=`matscore`t''
	}
	
}


/*************************************************************************************************************
RETOUR AU FICHIER INITIAL ET SAUVEGARDE DES NOUVELLES VARIABLES
*************************************************************************************************************/

if "`visit'"!="" {
	tempfile sauv
	qui keep `latent'* `selatent'* `id' `visit' 
    qui reshape wide , i(`id') j(`visit')
	qui sort `id'	
	qui save `sauv', replace
	restore,preserve
	if "`replace'"!=""&("`genlt'"!=""|"`geninf'"!="") {
    	capture drop `genlt' 
    	capture drop `genlt'_se 
    	capture drop `geninf' 
    	capture drop `genlt'_corr
    	capture drop `genlt'_ml
    }
	tempname idorder
	qui gen `idorder'=_n 
	qui sort `id'
	qui merge 1:1 `id' using `sauv'
	
	qui sort `idorder'
    qui drop `idorder'	
}
else {
    if "`genlt'"!="" {
		qui gen `genlt'_corr=`corrlatent' if `touse'
		tempvar tmpitem mean nbnonmiss
		forvalues i=1/`nbitems' {
			qui gen `tmpitem'_`i'=. if `touse'
			forvalues k=0/`modamax' {
				qui replace `tmpitem'_`i'=`bestest'[`i',`=`k'+1'] if ``i''==`k'&`touse'
			}
		}
		qui egen `genlt'_ml=rowmean(`tmpitem'_*) if `touse'
		qui egen `nbnonmiss'=rownonmiss(`tmpitem'_*) if `touse'
 	}
	restore,not
}

/*************************************************************************************************************
PREPARATION DES MATRICES A RECUPERER POUR LE RETURN
*************************************************************************************************************/
matrix colnames `diff'="Estimate" "Std err" "z" "p" "lb" "ul"
matrix colnames `covariates'=Estimate s.e. z p lb ul
matrix rownames `covariates'=Variance `continuous' `catname'
if "`difvar'"!="" {
	local nom
	forvalues c=1/`nbgroupdif' {
		 local nom `nom' dif`c'_eff dif`c'_EAP_Est dif`c'_EAP_se dif`c'_Corr_Est
	}
}
else  {
	local nom `nom' eff EAP_Est EAP_se Corr_Est
}

matrix colnames `matscorelt'=`nom'
local nom
forvalues s=0/`scoremax' {
	local nom `nom' score`s'
}     
matrix rownames `matscorelt'=`nom'
matrix rownames `bestest'=`rn2'
matrix rownames `bestesti'=`rn2'

local nom
forvalues i=1/`nbitems' {
   local nom `nom' ``i''
}
if "`difvar'"!="" {
	matrix rownames `diftest'=`nom'
}

local nom
local nomw
forvalues m=0/`modamax' {
	local nom `nom' cat_`m'
	local nomw `nomw' catw_`m'
}
tempname mostlikely
matrix colnames `bestest'=`nom'
matrix colnames `bestesti'=`nomw'
matrix coljoinbyname `mostlikely' = `bestest' `bestesti'

local rg
forvalues g=1/`nbgroups' {
	local rg `rg' groupe`g'
}
matrix rownames `matgroupscoreltdif'=`rg'
matrix rownames `matgroupscoremdltdif'=`rg'
local cg number eff min max
forvalues c=1/`nbgroupdif' {
	local cg `cg' eff_c`c' EAP_c`c' se_c`c'
}
matrix colnames `matgroupscoreltdif'=`cg'
matrix colnames `matgroupscoremdltdif'=`cg'

matrix `fit'=`fit'[....,1..4]
matrix rownames `fit'=`rn2'

/*************************************************************************************************************
CREATION DU DOCX
*************************************************************************************************************/
*set trace on
if "`docx'"!="" {
    putdocx clear
    putdocx begin, footer(fall_report)
	putdocx table hdr = (1, 3), border(all, nil) tofooter(fall_report)
	if "`rsm'"=="" {
		putdocx table hdr(1, 1) = ("Partial Credit Model")
	}
	else {
		putdocx table hdr(1, 1) = ("Rating Scale Model")
	}
	putdocx table hdr(1, 2) = ("`dimname'"), halign(center)
	putdocx table hdr(1, 3) = ("Page "), pagenumber
	putdocx table hdr(1, 3) = ("/"), totalpages append
	putdocx table hdr(1, 3), halign(right)
	putdocx paragraph ,style(Title)
	if "`dimname'" =="" {
	    local dimname2 "Rasch analysis"
	}
	else {
	    local dimname2 "Rasch analysis of the `dimname' dimension"
	}
	putdocx text ("`dimname2'") ,
	putdocx paragraph ,style(Subtitle)
	putdocx text ("General informations") , bold underline font(,14) smallcaps
	putdocx paragraph
    putdocx text ("Date: $S_DATE, $S_TIME")
	putdocx paragraph
	putdocx text ("Number of individuals: `nbobs'")
	putdocx paragraph
	putdocx text ("Number of complete individuals: `nbobsssmd'")
	putdocx paragraph
    putdocx text ("Number of items: `nbitems'")
	putdocx paragraph
    putdocx text ("List of items: `varlist'")
	putdocx paragraph
    forvalues v=1/`nbdifvar' {
	    local list`v'
		forvalues i=1/`nbitems' {
			if `difitems'[`i',`v']==1 {
				
				local list`v' `list`v'' ``i''
			}
		}
		putdocx text ("List of items affected by DIF on variable `dif`v'': `list`v''")
		putdocx paragraph
	}
	local model Partial Credit Model (PCM)
	if "`rsm'"!="" {
	   local model Rating Scale Model (RSM)
	}
	putdocx text ("Model: `model'")
	putdocx paragraph
	putdocx text ("Marginal log-likelihood: `ll'")

	putdocx paragraph, style(Subtitle)
	putdocx text ("Estimation of the parameters") , bold underline font(,14) smallcaps
    putdocx table table1 = matrix(`diff') , nformat(%9.3f) rownames colnames  border(start, nil) border(insideH, nil) border(insideV, nil) border(end, nil) headerrow(1)  halign(center)
    putdocx table table1(.,1), halign(left) 
    putdocx table table1(.,2/7), halign(right) 
    putdocx table table1(1,.), halign(right) border(top) border(bottom)
	
	
	qui putdocx table table2 = matrix(`covariates') , nformat(%9.3f) rownames colnames border(start, nil) border(insideH, nil) border(insideV, nil) border(end, nil)  headerrow(1)
    putdocx table table2(.,1), halign(left) 
    putdocx table table2(.,2/7), halign(right) 
    putdocx table table2(1,.), halign(right) border(top) border(bottom)

	if "`difvar'"!="" {
		putdocx paragraph,style(Subtitle)
		putdocx text ("DIF tests") , bold underline font(,14) smallcaps
		qui putdocx table table3 = matrix(`diftest') , nformat(%9.3f) rownames colnames border(start, nil) border(insideH, nil) border(insideV, nil) border(end, nil)    headerrow(1)
		putdocx table table3(.,1), halign(left) 
		putdocx table table3(.,2/5), halign(right) 
		putdocx table table3(1,.), halign(right) border(top) border(bottom)
	}
	
	putdocx paragraph,style(Subtitle)
	putdocx text ("Fit indexes for items") , bold underline font(,14) smallcaps
	qui putdocx table table4 = matrix(`fit') , nformat(%9.3f) rownames colnames border(start, nil) border(insideH, nil) border(insideV, nil) border(end, nil)    headerrow(1)
    putdocx table table4(.,1), halign(left) 
    putdocx table table4(.,2/5), halign(right) 
    putdocx table table4(1,.), halign(right) border(top) border(bottom)

	putdocx paragraph,style(Subtitle)
	putdocx text ("Estimation per score") , bold underline font(,14) smallcaps
	qui putdocx table table5 = matrix(`matscorelt') , nformat(%9.3f) rownames colnames border(start, nil) border(insideH, nil) border(insideV, nil) border(end, nil)    headerrow(1) width(8)
    putdocx table table5(.,1), halign(left) 
    putdocx table table5(.,2/5), halign(right) 
    putdocx table table5(1,.), halign(right) border(top) border(bottom)

	*putdocx paragraph,style(Subtitle)
	*putdocx text ("Help for publication") , bold underline font(,14) smallcaps
	*putdocx text ("The parameters of the model were estimated using Marginal Maximum Likelihood (MML). ")
	
	
	
	local extension png
}

/*************************************************************************************************************
SAUVEGARDE DES GRAPHIQUES
*************************************************************************************************************/

if "`filesave'"!="" {
    if "`graphs'"!="" {
		if "`docx'"!="" {
		    *putdocx pagebreak
			putdocx paragraph, style(Subtitle)
			putdocx text ("General Graphs")
		}
		foreach i in TCC  TIC map {
			if "`extension'"!="" {
			    qui graph export "`dirsave'//`i'.`extension'", replace name(`i')     
            }
			if "`docx'"!="" {
			    putdocx paragraph
			    putdocx image "`dirsave'//`i'.png", height(10cm)
			}
		}
		foreach i in IIC TIC IIR {
			forvalues c=1/`nbgroupdif' {
				if "`extension'"!="" {
					qui graph export "`dirsave'//`i'`c'.`extension'", replace name(`i'`c')     
				}
				if "`docx'"!="" {
					putdocx paragraph
					putdocx image "`dirsave'//`i'`c'.png", height(10cm)
				}
			}
		}
		if "`graphitems'"=="" {
			putdocx paragraph, style(Subtitle)
			putdocx text ("Graphs per item")
			forvalues i=1/`nbitems' {
				if "`docx'"!="" {
					putdocx paragraph, style(Heading1)
				    putdocx text ("Graphs for ``i''") 
				}
				foreach j in CCC ICC  {
	 			    if "`extension'"!="" {
					    qui graph export "`dirsave'//`j'_``i''.`extension'", replace name(`j'``i'') 
					}
					if "`docx'"!="" {
						putdocx paragraph
						putdocx image "`dirsave'//`j'_``i''.png" , height(10cm)
					}
				}
			}
			if "`residuals'"=="" {
				forvalues i=1/`nblistitemsdif' {
					*set trace on
					*di "ext`i'=`ext`i''"
					local it: word `i' of `listitemsdifnumbers'
					if "`extension'"!="" {
						qui graph export "`dirsave'//residuals_``it''`ext`i''.`extension'", replace name(res_``it''`ext`i'') 
					}
					if "`docx'"!="" {
						putdocx paragraph
						putdocx image "`dirsave'//residuals_``it''`ext`i''.png" , height(10cm)
					}
				}
			}	
		}
	}
}
if "`docx'"!="" {
    putdocx save "`dirsave'//`docx'.docx", replace
}




return matrix difficulties=`diff'
return matrix covariates=`covariates'
return matrix matscorelt=`matscorelt'
return matrix matgroupscorelt=`matgroupscoreltdif'
return matrix matgroupscoremdlt=`matgroupscoremdltdif'
return matrix mostlikely=`mostlikely'
return matrix fit=`fit'
if "`difvar'"!="" {
	return matrix diftest=`diftest'
}

capture restore, not
end