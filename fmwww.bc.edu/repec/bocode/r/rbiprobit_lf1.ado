*! version 1.1.0 , 18apr2022
*! Author: Mustafa Coban, Institute for Employment Research (Germany)
*! Website: mustafacoban.de
*! Support: mustafa.coban@iab.de


/****************************************************************/
/*    			 rbiprobit lf1 evaluator						*/
/****************************************************************/



program define rbiprobit_lf1

	version 11						
	args todo b lnfi g1 g2 g3 H		//	Siehe Beschreibung oben
	
	tempvar xb zg 
	tempname arho
		
	mleval `xb'  = `b', eq(1)
	mleval `zg'  = `b', eq(2)
	mleval `arho' = `b', eq(3) scalar	
	
	if `arho' < -14 {
		scalar `arho' = -14
	}
	if `arho' > 14{
		scalar `arho' = 14
	}
	
	
	tempname rho drdk d2rd2k
	scalar `rho' 	= (exp(2*`arho')-1) / (1+exp(2*`arho'))
	scalar `drdk' 	= (4 * exp(2*`arho')) / ( (1+exp(2*`arho'))*(1+exp(2*`arho')) )
	scalar `d2rd2k' = 8 * exp(2*`arho') * (1-exp(2*`arho')) ///
						/ ( (1+exp(2*`arho'))*(1+exp(2*`arho'))*(1+exp(2*`arho')) )
			
	
	tempname q1 q2
	
	quietly{
		gen byte `q1' = 2*$ML_y1 - 1
		gen byte `q2' = 2*$ML_y2 - 1
		replace `lnfi' = ln(binormal(`q1'*`xb',`q2'*`zg',`q1'*`q2'*`rho'))
	}
	
	if (`todo' == 0) exit
	
	
	*!	notational shortcuts		
	tempvar w1 w2 rhost etast v1 v2 s1 s2 Phi2 phi2
	
	quietly{ 

		gen double `w1' = `q1' * `xb'
		gen double `w2' = `q2' * `zg'
		gen double `rhost' = `q1' * `q2' * `rho'
		gen double `etast' = 1/(sqrt(1-`rhost'*`rhost'))
	
		gen double `v1' = (`w2'-`rhost'*`w1') * `etast'
		gen double `v2' = (`w1'-`rhost'*`w2') * `etast'
		gen double `s1' = normalden(`w1') * normal(`v1')
		gen double `s2' = normalden(`w2') * normal(`v2')
		
		gen double `Phi2' = binormal(`w1',`w2',`rhost')
		*gen double `phi2' = (1/(2*_pi))*`etast' * ///
		*					exp(-.5*`etast'^2*(`w1'^2 - 2*`rhost'*`w1'*`w2' + `w2'^2))
		*				//	stata's prefered calculation
						
		gen double `phi2' = `etast' * normalden(`w1') * normalden(`v1') // Greene's Equiv.
	}
		

	*!	scores	
	tempvar scr1 scr2 scr3
	
	quietly{
		gen double `scr1' = (`s1'/`Phi2') *`q1'
		gen double `scr2' = (`s2'/`Phi2') *`q2'
		gen double `scr3' = (`phi2'/`Phi2') *`q1'*`q2'*`drdk'
		
		replace `g1' = `scr1'
		replace `g2' = `scr2'
		replace `g3' = `scr3'
	}
	
	if (`todo' == 1) exit
	
end
