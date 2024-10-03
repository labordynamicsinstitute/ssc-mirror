*! Date        : 05juillet2016
*! Version     : 1.0.0
*! Author      : Charlie Joyez, Paris-Dauphine University
*! Email	   : charlie.joyez@dauphine.fr

*REQUIRES THE NWCOMMANDS PACKAGE BY T.GRUND (https://nwcommands.wordpress.com/)
* Calculates strength centralization
* See A. Barrat, M. Barthélemy, R. Pastor-Satorras, and A. Vespignani, “The architecture of complex weighted networks”. PNAS 101 (11): 3747–3752 (2004).

capture program drop nwStrengthcent
program nwStrengthcent, rclass
	version 9
	syntax [anything(name=netname)] [,DIRection(string)]		
	_nwsyntax `netname', max(9999)
	_nwsetobs
	
foreach v in _degree _strength _in_degree _out_degree _in_strength _out_strength _min_s _diff_s _tot_diff_s _max_s{
	capture confirm variable `v'
if !_rc {
                      
					   rename `v' alr_`v'
               }
}
	
	if `networks' > 1 {
		local k = 1
	}
	_nwsetobs `netname'
	
	set more off
 quietly foreach netname_temp in `netname' {
 nwtomata `netname_temp', mat(mymat)

_nwsyntax `netname_temp' 
quietly nwdegree `netname_temp',valued
quietly	mata : A=mymat

 			if "`directed'" == "true" {
				if "`direction'"!="inward"{
				 rename _out_strength _strength
				}
				if "`direction'"=="inward"{
				 rename _in_strength _strength
				}
			}

quietly	mata : W=sum(A)/2
			*noi di "W"
			*noi mata W
quietly	mata : N=rows(A)
			*noi di "N"
			*noi mata N
quietly	capture drop _max_s 
quietly	egen _max_s = max(_strength)
			*noi di "S*"
			*noi di _max_s
quietly	egen _min_s = min(_strength) if _strength!=0
			*noi di "Smin"
			*noi di _min_s
		su _min_s
		local mins `r(mean)'
		mata mins=(`mins')
			*noi mata mins
		mata : den=(W-mins)*(N-1)
			*noi di "denomin"
			*noi mata den
		capture drop _diff_s
		gen _diff_s=_max_s-_strength
		capture drop _tot_diff_s
		egen _tot_diff_s=total(_diff_s)
		su _tot_diff_s
		local num `r(mean)'
			*noi di `num'
		mata num=(`num')
			*noi mata num
			*noi mata den
		quietly mata: st_numscalar("r(s_central)", num/den)
			
			*noi mata A
		noi di "{txt} Freeman Strength centralization:: {res}`r(s_central)'"

	
local k = `k' + 1
		
		 
	
}
foreach v in _degree _strength _in_degree _out_degree _in_strength _out_strength _min_s _diff_s _tot_diff_s _max_s {
	capture confirm variable alr_`v'
if !_rc {
          capture drop  `v'           
					  rename alr_`v' `v'

               }

			   else {

					capture drop `v'
			  
			   }
}
return scalar s_central = `r(s_central)'
	end
