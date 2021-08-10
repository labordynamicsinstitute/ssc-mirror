*! 1.2 Oct 9th Jan Brogger
capture program drop _nice
program define _nice , rclass
	version 6.0

	*di "nice: 1-`1'"
	*di "nice: 2-`2'"

	local min=round(`1',0.1)
	if `min'==0 {local min=0.1}

	local max=round(`2',0.1)
	local range=round(`max'-`min',0.1)

	local max_n = 15
	local max_i = 100

	local inc=round(`range'/10,0.25)
	if `inc'==0 {local inc=0.5}

	local i=1
	if `min'~=`max' & `inc'~=0 {

		*di in red  "`min'(`inc')`max'"
		capture numlist "`min'(`inc')`max'"
		if _rc==0 {
			local lab "`r(numlist)'"
			local n : word count `lab'
			*di in red "n:`n'. i: `i'. max_n: `max_n'. max_i: `max_i'"
			while (`n'>`max_n') & (`i'<`max_i') {				
				local inc=round(`inc'+0.5,1)
				local i=`i'+1
				capture numlist "`min'(`inc')`max'"
				if _rc==0 {
					numlist "`min'(`inc')`max'"
					local lab "`r(numlist)'"
					local n : word count `lab'
				}
				else {
					local n=`max_n'+1
					local i=`max_i'+1
				}
			}

			if `n'<=`max_n' {
				local min=round(`min',0.1)
				local max=round(`max',0.1)
				local lab "`min',`lab',`max'"
			}
			else {
				local lab ""
			}
		}


	}

	if "`debug'"~="" {
		di in red "range: `range'"
		di in red "ymin2: `ymin2'"
		di in red "ymax2: `ymax2'"
		di in red "inc: `inc'"
		di in red "n: `n'"
		di in red "lab: `lab'"
	}

	return local lab `lab'

end




