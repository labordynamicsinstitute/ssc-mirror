*! version 1.1.0 8October2016

program edfreg, eclass
	version 13.1
	syntax anything [aw pw] [if] [in] [, cluster(string) robust select(string) absorb(string) noCONStant]
                               
if ("`robust'" == "" & "`cluster'" == "") {
	display as error "Error: Specify robust or cluster(clustervar)"
	exit
	}

	tempvar touse index indexa indexac order sd
	tempname X Q z z2 zsum zX z2X zXXz zXzzXz z2XXz2 zWz zXzWzXz zXW zW z2W pos c Y V VV B BB info infoa infoac Vid R W mean
	gettoken y xvars: anything
	unab y: `y'
	if ("`xvars'" ~= "") unab xvars: `xvars'
	if ("`select'" ~= "") unab select: `select'
	if ("`exp'" ~= "") gettoken a ww: exp, parse("=")

if (wordcount("`y'") ~= 1 ) {
	display as error "Error: Specify unique dependent variable"
	exit
	}

	local list0: list select | xvars
if (wordcount("`list0'") == 0) {
	display as error "Error: Must specify at least one independent variable"
	exit
	}
	if ("`absorb'" == "") reg `y' `list0' [`weight' `exp'] `if' `in', cluster(`cluster') `robust' `constant'
	if ("`absorb'" ~= "") areg `y' `list0' [`weight' `exp'] `if' `in', cluster(`cluster') `robust' `constant' absorb(`absorb')
	_ms_extract_varlist `list0', noomitted nofatal
	local list `r(varlist)'
	_ms_extract_varlist `select', noomitted nofatal	
	local lists `r(varlist)'

	local k = wordcount("`list'") 
	if ("`constant'" == "" & "`absorb'" == "") local k = `k' + 1
	if ("`select'" ~= "") local kk = wordcount("`lists'")
	if ("`select'" == "") local kk = `k'

	gen `order' = _n
	gen byte `touse' = e(sample)
	sort `touse' `cluster' `absorb' `order'
	if ("`cluster'" ~= "") quietly egen `index' = group(`cluster') if `touse' == 1
	if ("`absorb'" ~= "") {
		quietly egen `indexa' = group(`absorb') if `touse' == 1
		quietly sum `indexa'
		local fe = r(max)
		}
	if ("`absorb'" ~= "" & "`cluster'" ~= "") {
		quietly egen `indexac' = group(`cluster' `absorb') if `touse' == 1	
		quietly egen `sd' = sd(`index') if `touse' == 1, by(`indexa') 
		quietly sum `sd'
		if (r(max) > 0) {
			display as error "Error: Categories defined by absorb must be subsets of cluster variable"
			display as error "Consider recoding absorb as fixed effects dummy variables."
			exit
			}
		}
*Double checking that the X vars I extract produce the estimated coefficients
	mata `BB' = st_matrix("e(b)"); `V' = st_matrix("e(V)"); `pos' = abs(`BB')+abs(colsum(`V')):>0; `BB' = select(`BB',`pos')
	mata `X' = st_data(.,"`list'","`touse'"); `Y' = st_data(.,"`y'","`touse'"); `W' = J(rows(`X'),1,1)
	if ("`ww'" ~= "") mata `W' = st_data(.,"`ww'","`touse'")
	if ("`constant'" == "" & "`absorb'" == "") mata `X' = `X', J(rows(`X'),1,1)
	if ("`absorb'" ~= "") {
		mata `mean' = mean((`X',`Y'),`W'); `Vid' = st_data(.,"`indexa'","`touse'"); `infoa' = panelsetup(`Vid',1) 
		mata for (i=1;i<=rows(`infoa');i++) `X'[`infoa'[i,1]..`infoa'[i,2],1...] = `X'[`infoa'[i,1]..`infoa'[i,2],1...]:-mean(`X'[`infoa'[i,1]..`infoa'[i,2],1...],`W'[`infoa'[i,1]..`infoa'[i,2],1])
		mata for (i=1;i<=rows(`infoa');i++) `Y'[`infoa'[i,1]..`infoa'[i,2],1] = `Y'[`infoa'[i,1]..`infoa'[i,2],1]:-mean(`Y'[`infoa'[i,1]..`infoa'[i,2],1],`W'[`infoa'[i,1]..`infoa'[i,2],1])
		}
	mata `W' = sqrt(`W'); `X' = `X':*`W'; `Y' = `Y':*`W'; `B' = invsym(`X''*`X')*`X''*`Y'
	if ("`absorb'" ~= "") mata `B' = `B' \ `mean'[1,`k'+1] - `mean'[1,1..`k']*`B'
	mata `BB' = (`BB' - `B''); `BB' = `BB'*`BB''; st_matrix("`VV'",`BB')

if (`VV'[1,1] > 1e-08) {
	display as error "Fatal error: unable to reproduce regression"
	display as error "Please provide a.young@lse.ac.uk with data and regression code"
	exit
	}

*Mata `V' consists of two columns: bias of variance estimate, edf (rows = variables).
	mata `Q' = invsym(`X''*`X'); `V' = J(`kk',2,.)

	if ("`absorb'" ~= "") mata for (i=1;i<=rows(`infoa');i++) `W'[`infoa'[i,1]..`infoa'[i,2],1] = `W'[`infoa'[i,1]..`infoa'[i,2],1]/sqrt(`W'[`infoa'[i,1]..`infoa'[i,2],1]'*`W'[`infoa'[i,1]..`infoa'[i,2],1])

*Clustered
if ("`cluster'" ~= "") {
	mata `Vid' = st_data(.,"`index'","`touse'"); `info' = panelsetup(`Vid',1)
	if ("`absorb'" ~= "") {
		mata `infoac' = J(rows(`info'),2,.)
		forvalues i = 1/`e(N_clust)' {
			quietly sum `indexac' if `index' == `i'
			mata `infoac'[`i',1..2] = (`r(min)',`r(max)')
			}
		}
	mata `BB' = rows(`info') - `e(N_clust)'; st_matrix("`VV'",`BB')

if (`VV'[1,1] > 0) {
	display as error "Fatal error: inconsistency in number of clusters"
	display as error "Please provide a.young@lse.ac.uk with data and regression code"
	exit
	}

	forvalues i = 1/`kk' {
		mata `z' = J(1,`k',0); `z'[1,`i'] = 1; `z' = `z'*`Q'*`X''; `zsum' = rowsum(`z':*`z')
		mata `zX' = J(`e(N_clust)',`k',0); `z2' = J(`e(N_clust)',1,0); `zWz' = J(`e(N_clust)',1,0)
		forvalues a = 1/`e(N_clust)' {
			mata `zX'[`a',1...] = `z'[1,`info'[`a',1]..`info'[`a',2]]*`X'[`info'[`a',1]..`info'[`a',2],1...]
			mata `z2'[`a',1] = rowsum(`z'[1,`info'[`a',1]..`info'[`a',2]]:*`z'[1,`info'[`a',1]..`info'[`a',2]])
			if ("`absorb'" ~= "") mata for (i=`infoac'[`a',1];i<=`infoac'[`a',2];i++) `zWz'[`a',1] = `zWz'[`a',1] + (`z'[1,`infoa'[i,1]..`infoa'[i,2]]*`W'[`infoa'[i,1]..`infoa'[i,2],1])^2
			}
		mata `zXXz' = `zX''*`zX'; `zXzzXz' = (`zX':*`z2')'*`zX'; `zXzWzXz' = (`zX':*`zWz')'*`zX'
		mata `V'[`i',1..2] = `zsum' - trace(`Q'*`zXXz') - sum(`zWz'), sum(`z2':*`z2') - 2*trace(`Q'*`zXzzXz') + trace(`Q'*`zXXz'*`Q'*`zXXz') + sum(`zWz':*`zWz') - 2*sum(`z2':*`zWz') + 2*trace(`Q'*`zXzWzXz') 
		mata `V'[`i',1..2] = `V'[`i',1]/`zsum', `V'[`i',1]^2/`V'[`i',2]
		}
	if ("`absorb'" == "") mata `V'[1...,1] = `V'[1...,1]*(`e(N_clust)'*(`e(N)'-1)/((`e(N)'-`k')*(`e(N_clust)'-1)))
	if ("`absorb'" ~= "") mata `V'[1...,1] = `V'[1...,1]*(`e(N_clust)'*(`e(N)'-1)/((`e(N)'-`k' - `fe')*(`e(N_clust)'-1)))
	local df = `e(N_clust)' - 1
	}

*Robust
if ("`robust'" ~= "" & "`cluster'" == "") {
	forvalues i = 1/`kk' {
		mata `z' = J(1,`k',0); `z'[1,`i'] = 1; `z' = `z'*`Q'*`X''; `z2' = `z':*`z'; `zsum' = rowsum(`z':*`z')
		mata `zX' = `z'':*`X'; `zXXz' = `zX''*`zX'; `z2X' = `z2'':*`X'; `zXzzXz' = `z2X''*`z2X'; `zWz' = J(1,1,0); `zXW' = J(1,1,0); `z2W' = J(1,1,0)
		if ("`absorb'" ~= "") {
			mata `zW' = `z'':*`W'; `z2W' = `z2'':*`W'
			mata `zWz' = J(rows(`infoa'),1,0); `zXW' = J(rows(`infoa'),`k',0)
			mata for (i=1;i<=rows(`infoa');i++) `zWz'[i,1] = (`zW'[`infoa'[i,1]..`infoa'[i,2],1]'*`zW'[`infoa'[i,1]..`infoa'[i,2],1])
			mata for (i=1;i<=rows(`infoa');i++) `zXW'[i,1...] = `zW'[`infoa'[i,1]..`infoa'[i,2],1]'*`zX'[`infoa'[i,1]..`infoa'[i,2],1...]
			} 
		mata `zXzWzXz' = `zXW''*`zXW'
		mata `V'[`i',1..2] = `zsum' - trace(`Q'*`zXXz') - sum(`zWz'), sum(`z2':*`z2') - 2*trace(`Q'*`zXzzXz') + trace(`Q'*`zXXz'*`Q'*`zXXz') + sum(`zWz':*`zWz') - 2*sum(`z2W':*`z2W') + 2*trace(`Q'*`zXzWzXz')
		mata `V'[`i',1..2] = `V'[`i',1]/`zsum', `V'[`i',1]^2/`V'[`i',2]
		}
	if ("`absorb'" == "") {
		mata `V'[1...,1] = `V'[1...,1]*(`e(N)'/(`e(N)'-`k'))		
		local df = `e(N)' - `k' 
		}
	else {
		mata `V'[1...,1] = `V'[1...,1]*(`e(N)'/(`e(N)'-`k'-`fe'))
		local df = `e(N)' - `k' - `fe'
		}
	}
*Computing and organizing results for ereturn
	mata `c' = st_matrix("e(V)"); `c' = diagonal(`c'); `pos' = `c':>0; `c' = select(`c',`pos')
	mata `R' = `B'[1..`kk',1], sqrt(`c'[1..`kk',1]):/sqrt(`V'[1...,1]), `V'[1...,2]; `R' = `R', `R'[1...,1]:/`R'[1...,2]
	mata `R' = `R', 2*ttail(`R'[1...,3],abs(`R'[1...,4])), `R'[1...,1]+(`R'[1...,2]:*invttail(`V'[1...,2],.975)), `R'[1...,1]-(`R'[1...,2]:*invttail(`V'[1...,2],.975))
	mata st_matrix("`VV'",`R')
	if ("`select'" == "" & "`constant'" == "" & "`absorb'" == "") matrix rownames `VV' = `list' _cons
	if ("`select'" == "" & "`constant'" ~= "") matrix rownames `VV' = `list'
	if ("`select'" ~= "") matrix rownames `VV' = `lists'
	matrix colnames `VV' = "coef" "adj se" "edf" "t" "pvalue" "95% ci lower" "95% ci upper" 

*Displaying results
	display as text " " _newline
	display as text "Nominal degrees of freedom == `df'" _newline
	display as text _col(14) "{c |}" _col(34) "Bias"  _col(45) "Effective"
	display as text _col(14) "{c |}" _col(32) "Adjusted"  _col(46) "Degrees"
	display as text "    Variable {c |}" _col(21) "Coef." _col(32) "Std. Err." _col(44) "of Freedom" _col(61) "t" _col(68) "P>|t|" _col(79) "[95% Conf. Interval]" 
	display as text "{hline 13}{c +}{hline 85}"
	forvalues i = 1/`kk' {
		display as text %12s abbrev(word("`list' _cons",`i'),12) " {c |}" _col(17) %10.9g `VV'[`i',1] _col(30) %10.9g `VV'[`i',2] _col(43) %10.1f `VV'[`i',3] _col(50) %10.2f `VV'[`i',4] _col(60) %10.3f `VV'[`i',5] _col(77) %10.9g `VV'[`i',6] _col(90) %10.9g `VV'[`i',7]
		}
	ereturn matrix edf = `VV', copy

	foreach j in X Q z z2 zsum zX z2X zXXz zXzzXz z2XXz2 zWz zXzWzXz zXW zW z2W pos c Y V VV B BB info infoa infoac Vid R W mean {
		capture mata mata drop ``j''
		}

*Restoring original order of the data set
	sort `order'

end

