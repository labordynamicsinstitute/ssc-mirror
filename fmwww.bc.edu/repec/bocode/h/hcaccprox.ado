************************************************************************************************************
* hcaccprox: Hierachical Clusters Analysis/CCPROX
* Version 1: May 12, 2004
* Add-on: Partition version 2 (2004-04-10)
*
* Use the Detect Stata program (http://freeirt.free.fr)
*
* Historic :
* Version 1 [2004-01-18], Jean-Benoit Hardouin
*
* Jean-benoit Hardouin, Regional Health Observatory of Orléans - France
* jean-benoit.hardouin@neuf.fr
*
* News about this program : http://anaqol.free.fr
* FreeIRT Project : http://freeirt.free.fr
*
* Copyright 2004 Jean-Benoit Hardouin
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
*
************************************************************************************************************

program define hcaccprox , rclass
version 8.0
syntax varlist(min=2 numeric) [,PROX(string) METHod(string) PARTition(numlist) MEASures DETails DETect(integer 0)]

local nbpart:word count `partition'
tokenize `partition'
forvalues k=1/`nbpart' {
	local part`k'=``k''
}

local nbitems : word count `varlist'
tokenize `varlist'

tempname proximity whereitems 

matrix define `proximity'=J(`nbitems',`nbitems',0)
matrix define `whereitems'=J(`=`nbitems'-1',`nbitems',0)

if `detect'>`nbitems' {
	di _col(3) in green "The number of partitions analyzed by the DETECT criterion must be inferior to the number of possible partitions"
	di _col(3) in green "This number of possible partitions is `=`nbitems'-1', so your detect option is put to this number"
	local detect=`nbitems'-1
	di
}

if "`prox'"!="a"&"`prox'"!="ad"&"`prox'"!="cor"&"`prox'"!="ccov"&"`prox'"!="ccor"&"`prox'"!="mh" {
	if "`prox'"=="" {
		local prox="ccov"
	}
	else {
		di in red "You must define an existing measure of proximity (a, ad, cor, ccov, ccor, mh)."
		di in red "Please correct your prox option."
		exit
	}
}

if "`method'"!="UPGMA"&"`method'"!="single"&"`method'"!="complete" {
	if "`method'"=="" {
		local method="UPGMA"
	}
	else {
		di in red "Tou must define an existing method to define the proximity between two clusters of items:"
		di in red _col(10) "- UPGMA: Unweighted Pair-Group Method of Average"
		di in red _col(10) "- single: single linkage"
		di in red _col(10) "- complete: complete linkage "
		di in red "Please correct your method option"
		exit
	}
}

forvalues i=1/`nbitems' {
	matrix `whereitems'[1,`i']=`i'
	if "`details'"!="" {
		di in green _col(3) "The item " _col(13) in yellow "``i''"  in green " correspond to the node " in yellow "`i'" 
	}
}

tempvar score
egen `score'=rmean(`varlist')
qui replace `score'=`score'*`nbitems'
forvalues k=0/`nbitems' {
	qui count if `score'==`k'
	local nk`k'=r(N)
}

qui count
local N=r(N)

if "`prox'"=="ccov"|"`prox'"=="mh" {
	local proxmin=0
}

/*************************Measure of proximities*********************************/

forvalues i=1/`nbitems' {
	forvalues j=`=`i'+1'/`nbitems' {	
		/***********************************Proximity A**************************/
		if "`prox'"=="a" {
			qui count if ``i''==1&``j''==1
			local tmp11=r(N)
			qui count if ``i''==0&``j''==0
			local tmp00=r(N)

			matrix `proximity'[`i',`j']=sqrt(1-`tmp11'/(`N'-`tmp00'))
			matrix `proximity'[`j',`i']=`proximity'[`i',`j']
		}

		/***********************************Proximity AD*************************/
		if "`prox'"=="ad" {
			qui count if ``i''==1&``j''==1
			local tmp11=r(N)
			qui count if ``i''==0&``j''==0
			local tmp00=r(N)

			matrix `proximity'[`i',`j']=sqrt(1-(`tmp11'+`tmp00')/`N')
			matrix `proximity'[`j',`i']=`proximity'[`i',`j']
		}

		/**********************************Proximity COR*************************/
		if "`prox'"=="cor" {
			qui count if ``i''==1&``j''==1
			local tmp11=r(N)
			qui count if ``i''==0&``j''==0
			local tmp00=r(N)
			qui count if ``i''==1&``j''==0
			local tmp10=r(N)
			qui count if ``i''==0&``j''==1
			local tmp01=r(N)

			matrix `proximity'[`i',`j']=sqrt(2*(1-(`tmp11'*`tmp00'-`tmp10'*`tmp01')/(sqrt((`tmp11'+`tmp10')*(`tmp11'+`tmp01')*(`tmp00'+`tmp10')*(`tmp00'+`tmp01')))))
			matrix `proximity'[`j',`i']=`proximity'[`i',`j']
		}

		/***********************************Proximity CCOV**********************/
		if "`prox'"=="ccov" {
			local dij=0
			forvalues k=1/`=`nbitems'-1' {
				if `nk`k''!=0 {
					qui corr ``i'' ``j'',cov
					local covi`i'j`j'k`k'=r(cov_12)
					local dij=`dij'+`covi`i'j`j'k`k''*`nk`k''
				}
			}

			matrix `proximity'[`i',`j']=-`dij'/`N'
			matrix `proximity'[`j',`i']=`proximity'[`i',`j']
			if `proxmin'<`dij'/`N' {
				local proxmin=`dij'/`N'
			}
		}

		/***********************************Proximity CCOR**********************/

		if "`prox'"=="ccor" {
			local dij=0
			forvalues k=1/`=`nbitems'-1' {
				if `nk`k''!=0 {
					qui corr ``i'' ``j''
					local cori`i'j`j'k`k'=r(rho)
					local dij=`dij'+`cori`i'j`j'k`k''*`nk`k''
				}
			}

			matrix `proximity'[`i',`j']=sqrt(2*(1-`dij'/`N'))
			matrix `proximity'[`j',`i']=`proximity'[`i',`j']
		}
	
		
		/***********************************Proximity MH************************/

		if "`prox'"=="mh" {
			local numij=0
			local denom=0
			forvalues k=1/`=`nbitems'-1' {
				if `nk`k''!=0 {
					qui count if ``i''==1&``j''==1
					local A=r(N)
					qui count if ``i''==0&``j''==1
					local B=r(N)
					qui count if ``i''==1&``j''==0
					local C=r(N)
					qui count if ``i''==0&``j''==0
					local D=r(N)
				 
					if `B'!=0&`C'!=0 {
						local numij=`numij'+`A'*`D'/`nk`k''
						local denomij=`denomij'+`B'*`C'/`nk`k''
					}
				}
			}

			matrix `proximity'[`i',`j']=-log(`numij'/`denomij')
			matrix `proximity'[`j',`i']=`proximity'[`i',`j']
			if `proxmin'<log(`numij'/`denomij') {
				local proxmin=-`proximity'[`i',`j']
			}
		}
	}
}

if "`prox'"=="ccov"|"`prox'"=="mh" {
	forvalues i=1/`nbitems' {
		forvalues j=`=`i'+1'/`nbitems' {
			matrix `proximity'[`i',`j']=`proximity'[`i',`j']+`proxmin'
			matrix `proximity'[`j',`i']=`proximity'[`i',`j']
		}
	}
}

/**********************END OD THE COMPUTING OF THE PROXIMITIES**************************************/
if "`measures'"!="" {
	di
	matrix rowname `proximity'=`varlist'
	matrix colname `proximity'=`varlist'
	di in green _col(3) "Measures of proximity between the items"
	matrix list `proximity', noheader
	di
}

/**********************STEP 0**********************************************************************/

tempname currentprox nodes conclinesnodes mempart

matrix `currentprox'=`proximity'
matrix define `nodes'=J(`=`nbitems'+4',`=2*`nbitems'-1',0)
matrix define `conclinesnodes'=J(1,`nbitems',0)
matrix define `mempart'=J(`=`nbitems'+2',`=`nbitems'-1',0)
forvalues i=1/`nbitems' {
	matrix `nodes'[1,`i']=1
	matrix `nodes'[2,`i']=1
	matrix `nodes'[5,`i']=`i'
	matrix `conclinesnodes'[1,`i']=`i'
}


/*********************************CLUSTERING PROCEDURE*************************************/

forvalues k=1/`=`nbitems'-1' {
	local nbclusters=`nbitems'-`k'+1
	local distmin=`currentprox'[1,2]
	local cl1=1
	local cl2=2

	forvalues i=1/`nbclusters' {
		forvalues j=`=`i'+1'/`nbclusters' {
			if `distmin'>`currentprox'[`i',`j'] {
				local distmin=`currentprox'[`i',`j']
				local cl1=`i'
				local cl2=`j'
			}
		}
	}

	local linescl1=`conclinesnodes'[1,`cl1']
	local nbitemscl1=`nodes'[1,`linescl1']
	matrix `nodes'[2,`linescl1']=0
	local linescl2=`conclinesnodes'[1,`cl2']
	local nbitemscl2=`nodes'[1,`linescl2']
	matrix `nodes'[2,`linescl2']=0
	matrix `nodes'[1,`=`nbitems'+`k'']=`nbitemscl1'+`nbitemscl2'
	matrix `nodes'[2,`=`nbitems'+`k'']=1
	matrix `nodes'[3,`=`nbitems'+`k'']=`linescl1'
	matrix `nodes'[4,`=`nbitems'+`k'']=`linescl2'
	if "`details'"!="" {
		di in green _col(3) "The nodes" _col(13) in yellow "`linescl1'" _col(17) in green "and" _col(21) in yellow "`linescl2'" _col(25) in green "are been aggregated to form the node " in yellow "`=`nbitems'+`k''"
	}

	forvalues i=5/`=`nbitemscl1'+4' {
		local item=`nodes'[`i',`linescl1']
		matrix `nodes'[`i',`=`nbitems'+`k'']=`item'
		matrix `whereitems'[`k',`item']=`=`nbitems'+`k''
	}
	forvalues i=5/`=`nbitemscl2'+4' {
		local item=`nodes'[`i',`linescl2']
		matrix `nodes'[`=`i'+`nbitemscl1'',`=`nbitems'+`k'']=`item'
		matrix `whereitems'[`k',`item']=`=`nbitems'+`k''
	}

	local tmp=1
	forvalues i=1/`=`nbitems'+`k'' {
		if `nodes'[2,`i']==1 {
			matrix `mempart'[`tmp',`k']=`i'
			local tmp=`tmp'+1
		}
	}



	if `detect'>=`=`nbitems'-`k'' {
		local partdetect
		local compteur=1
		local scaledetect
		forvalues i=1/`=`nbitems'-`k'' {
			local scaledetect`i'
		}
		forvalues i=1/`=`nbitems'+`k'' {
			if `nodes'[2,`i']==1{
				local tmp=`nodes'[1,`i']
				local partdetect `partdetect' `tmp'
				local tmp2=4+`tmp'
				forvalues j=5/`tmp2' {
					local tmp3=`nodes'[`j',`i']
					local scaledetect`compteur' `scaledetect`compteur'' ``tmp3''
				}
			local scaledetect `scaledetect' `scaledetect`compteur''
			local compteur=`compteur'+1
			}
		}
	qui detect `scaledetect' , partition(`partdetect')
	local detect`=`nbclusters'-1'=r(DETECT)
	local R`=`nbclusters'-1'=r(R)
	local Iss`=`nbclusters'-1'=r(Iss)
	}


	matrix drop `currentprox'
	matrix define `currentprox'=J(`=`nbclusters'-1',`=`nbclusters'-1',0)
	matrix drop `conclinesnodes'
	matrix define `conclinesnodes'=J(1,`=`nbclusters'-1',0)

	local tmp=1
	forvalues i=1/`=`nbitems'+`k'' {
		if `nodes'[2,`i']==1 {
			matrix `conclinesnodes'[1,`tmp']=`i'
			local tmp=`tmp'+1
		}
	}
	forvalues i=1/`=`nbclusters'-1' {
		forvalues j=`=`i'+1'/`=`nbclusters'-1' {
			if "`method'"=="UPGMA" {
				local moy=0
				local linescl1=`conclinesnodes'[1,`i']
				local nbitemscl1=`nodes'[1,`linescl1']
				local linescl2=`conclinesnodes'[1,`j']
				local nbitemscl2=`nodes'[1,`linescl2']
				forvalues l=5/`=`nbitemscl1'+4' {
					forvalues m=5/`=`nbitemscl2'+4' {
						local item1=`nodes'[`l',`linescl1']
						local item2=`nodes'[`m',`linescl2']
						local tmp=`proximity'[`item1',`item2']
						local moy=`moy'+`tmp'
					}
				}
				matrix `currentprox'[`i',`j']=`moy'/(`nbitemscl1'*`nbitemscl2')
				matrix `currentprox'[`j',`i']=`moy'/(`nbitemscl1'*`nbitemscl2')
			}
			if "`method'"=="single" {
				local moy=0
				local linescl1=`conclinesnodes'[1,`i']
				local nbitemscl1=`nodes'[1,`linescl1']
				local linescl2=`conclinesnodes'[1,`j']
				local nbitemscl2=`nodes'[1,`linescl2']
				forvalues l=5/`=`nbitemscl1'+4' {
					forvalues m=5/`=`nbitemscl2'+4' {
						local item1=`nodes'[`l',`linescl1']
						local item2=`nodes'[`m',`linescl2']
						if `l'==5&`m'==5 {
							local distmin=`proximity'[`item1',`item2']
						}
						else {
							if `distmin'>`proximity'[`item1',`item2'] {
								local distmin=`proximity'[`item1',`item2']
							}
						}
					}
				}
				matrix `currentprox'[`i',`j']=`distmin'
				matrix `currentprox'[`j',`i']=`distmin'
			}
			if "`method'"=="complete" {
				local moy=0
				local linescl1=`conclinesnodes'[1,`i']
				local nbitemscl1=`nodes'[1,`linescl1']
				local linescl2=`conclinesnodes'[1,`j']
				local nbitemscl2=`nodes'[1,`linescl2']
				local distmax=0
				forvalues l=5/`=`nbitemscl1'+4' {
					forvalues m=5/`=`nbitemscl2'+4' {
						local item1=`nodes'[`l',`linescl1']
						local item2=`nodes'[`m',`linescl2']
						if `distmax'<`proximity'[`item1',`item2'] {
							local distmax=`proximity'[`item1',`item2']
						}
					}
				}
				matrix `currentprox'[`i',`j']=`distmax'
				matrix `currentprox'[`j',`i']=`distmax'
			}
		}
	}
}

if `detect'!=0 {
        tempname indexes
        matrix define `indexes'=J(`detect',4,0)
        matrix colnames `indexes'=Clusters DETECT Iss R
	di ""
	di in green _col(7) "Indexes to test the `detect' latest partitions of the items"
	di ""
	di in green _col(29) "DETECT" _col(43) "Iss" _col(56) "R"
	di _col(5) in green "Only one cluster:" _col(27) in yellow %8.5f `detect1' _col(38) %8.5f  `Iss1' _col(49) %8.5f  `R1'
	matrix `indexes'[1,1]=1
	matrix `indexes'[1,2]=`detect1'
	matrix `indexes'[1,3]=`Iss1'
	matrix `indexes'[1,4]=`R1'
        forvalues k=2/`detect' {
	        matrix  `indexes'[`k',1]=`k'
	        matrix  `indexes'[`k',2]=`detect`k''
	        matrix  `indexes'[`k',3]=`Iss`k''
	        matrix  `indexes'[`k',4]=`R`k''
		di  _col(5) in green "`k' clusters:" _col(27) in yellow %8.5f `detect`k'' _col(38) %8.5f  `Iss`k'' _col(49) %8.5f `R`k''
	}
        return matrix indexes=`indexes'
}


forvalues k=1/`nbpart' {
	di ""
	local rowmempart=`nbitems'-`part`k''
	di in green _col(8) "Number of clusters : `part`k''"
	tempname affect`part`k''
	matrix define `affect`part`k'''=J(1,`nbitems',0)
	forvalues i=1/`part`k'' {
		di
		di in green _col(12) "Cluster `i':"
		local rownodes=`mempart'[`i',`rowmempart']
		local itemsinthecluster=`nodes'[1,`rownodes']
		forvalues j=5/`=4+`itemsinthecluster'' {
			local tmp=`nodes'[`j',`rownodes']
			matrix `affect`part`k'''[1,`tmp']=`i'
			di in yellow _col(13)"``tmp''"
		}
	}
	matrix colnames `affect`part`k'''=`varlist'
        return matrix affect`part`k''=`affect`part`k'''
}

return matrix mempart `mempart'
return matrix nodes `nodes'
return local nbitems=`nbitems'
return local varlist `varlist'
end

/*********************************************************
*Partition
*Version 2 (May 10, 2004)
*
*Historic
*Version 1 (January 18, 2004)
***********************************************************/

program define partition
version 8.0
syntax anything(name=partition)
 
local nbitems=r(nbitems)
tempname mempart nodes
matrix `mempart'=r(mempart)
matrix `nodes'=r(nodes)
local varlist "`r(varlist)'"

local nbpart:word count `partition'
tokenize `partition'

forvalues k=1/`nbpart' {
	local part`k'=``k''
}
tokenize `varlist'

forvalues k=1/`nbpart' {
	di ""
	local rowmempart=`nbitems'-`part`k''
	di in green _col(8) "Number of clusters : `part`k''
	forvalues i=1/`part`k'' {
		di
		di in green _col(12) "Cluster `i':"
		local rownodes=`mempart'[`i',`rowmempart']
		local itemsinthecluster=`nodes'[1,`rownodes']
		forvalues j=5/`=4+`itemsinthecluster'' {
			local tmp=`nodes'[`j',`rownodes']
			di in yellow _col(13)"``tmp''"
		}
	}
}
end
