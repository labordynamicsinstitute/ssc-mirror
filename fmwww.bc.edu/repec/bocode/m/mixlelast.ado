*! mixlelast version 1.0 (27/05/2024)
*! Lars Zeigermannn
* mixlelast builds on mixlpred written by Arne Risa Hole

capture program drop mixlelast
program define mixlelast, rclass
		version 14.1

		syntax [if] [in],													///
			ALTernatives(varname) [											///
			FOR(varname)													///
			ABSOLUTEchange(real 0)											///
			PERCENTchange(real 0)											///
			DUMMY															///
			MARGinaleffects													///
			Weighted														///
			NREP(integer 50)												///
			BURN(integer 15)												///
			NOSD															///
			QUIetly															///
			HETtype(string)													///
			KRobb(numlist max=1 integer >1)									///
			KRUSERdraws														///
			KRBURN(integer 15)												///
			KRLEVEL(cilevel) 												///
			KRSE															///
			]
		
		** Check that last estimation was mixlogit **
		if ("`e(cmd)'" != "mixlogit") error 301
		
		** Mark the prediction sample **
 		marksample touse, novarlist
        markout `touse' `e(indepvars)' `e(group)' `e(id)'
		
        ** Drop data not in prediction sample **
        preserve
        qui keep if `touse'
		
		** Generate variable used to sort data **
		tempvar sorder
        sort `e(id)' `e(group)' `alternatives'
        gen `sorder' = _n
		
		** Generate total number of observations **
        local totobs = _N
		
		** Generate number of distinct alternatives **
        qui duplicates report `alternatives'
        local numalt = r(unique_value)
				
		** Generate number of choice occasions **
		qui duplicates report `e(group)'
        local numco = r(unique_value)
				
		** Check that alternatives variable is numeric **
		capture confirm numeric var `alternatives'
		if _rc != 0 {
                di in r "The alternatives variable must be numeric"
                exit 498
		}
		
		** Check that alternatives variable is unique per choice occasion **
		capture bysort `e(group)': assert `alternatives'[_n] != `alternatives'[_n+1]
		if _rc != 0 {
				di in r "The alternatives variable is not unique per choice set"
				exit 498
		}
		
		** mixl_id: vector of alternative identifiers set to 1 ... # of alternatives, if variable is non-consecutive **
		sort `sorder'
		tempvar alternatives2
		egen `alternatives2'=group(`alternatives')

		
		** Set and check for variable **
		if ("`for'" != ""){
			local n : word count `e(indepvars)' 
			forvalues i = 1/`n'{
			cap assert "`for'" == "`:word `i' of `e(indepvars)''"
					if _rc == 0 {
					local elastcoeff = `i'
					continue, break
				}
			}
			if _rc != 0{
				di in r "`for' is not specified as an independent variable in mixlogit"
				exit 498
			}
		}
		else {
			local elastcoeff = `e(kfix)'+1
			local for `: word `elastcoeff' of `e(indepvars)''
		}
		
		** Generate local indicating if margin is specified
		if ("`marginaleffects'" == "") local marginal = 0
		else local marginal = 1
		
		** Generate local weighted **
		if ("`weighted'" != "") local weighted = 1
		else local weighted = 0
		
		** Generate local nosd ** 
		
		if ("`nosd'" !="") local nosd = 1
		else{
			local nosd = 0
			if ("`krobb'" != "") local nosd = 1
		}
				
		** Generate local dummy **
		if ("`dummy'" != "") local dummy = 1
		else local dummy = 0
		
		** Check that absolute, percent and dummy options cannot be specified at the same time **
		if (`absolutechange' != 0){
			if (`percentchange' != 0 & `dummy' != 0) {
				di in r "The absolutechange, percentchange and dummy options cannot be specified together."
				exit 498
			}
			if (`dummy' != 0) {
				di in r "The absolutechange and dummy options cannot be specified together."
				exit 498
			}
			if (`percentchange' !=  0) {
				di in r "Absolutechange and percentchange cannot be specified together."
				exit 498
			}
		}
		else {
			if (`percentchange' != 0 & `dummy' != 0) {
				di in r "The percentchange and dummy options cannot be specified together."
				exit 498
			}
		}
		
		** Check if variable is discrete or a dummy **
		capture assert `for' == 0 | `for' == 1
		if (_rc == 0) {
			if (`dummy' == 0) di "`for' is a dummy variable: Consider using the dummy option."
		}
		else {
			if (`dummy' == 1){
				di in r "`for' is not a dummy variable: dummy option allowed."
				exit 498
			}
			if (`percentchange' == 0 & `absolutechange' == 0) {
				capture assert int(`for') == `for'
				if (_rc == 0) di "`for' is an integer variable: Consider using the absolutechange or percentagechange option."
			}
		}
		
		** Generate local type for type of change **
		if (`absolutechange' != 0) {
			local change = `absolutechange'
			local type = 1
			local changeby absolute value
		}
		else if (`percentchange' != 0){
			local change = `percentchange'
			local type = 2
			local changeby percentage
		}
		else if (`dummy' != 0){
			local change = 0
			local type = 3
			local changeby dummy change
		}
		else {
			local change = 0
			local type = 4
			local changeby marginal
		}
		
		** Check if choice sets are heterogeneous and if hettype option is correctly specified **
		capture assert `totobs'/`numalt' == `numco'
		if (_rc == 0){
			local het = 0
			cap assert "`hettype'" == ""
			if (_rc != 0) {
				di in r "Choice sets are homogeneous: hettype option not allowed."
				exit 498
			}
			local hettype 0
			local hettype2 = 0
		}
		else {
			local het = 1
			if ("`hettype'" == "") local hettype I
						
			cap assert "`hettype'" == "I" | "`hettype'" == "IIa" | "`hettype'" == "IIb"
			if (_rc != 0) {
				di in r "`hettype' is not a valid type of aggregation: Choose I, IIa or IIb."
				exit 498
			}
			
			if ("`hettype'" == "I") local hettype2 = 1
			else if ("`hettype'" == "IIa") local hettype2 = 2
			else local hettype2 = 3
		}
		

		** Check if KR options are used consistently **
		if ("`krse'" != "") {
			capture assert `krobb' != 1
			if _rc != 0 {
					di in r "Option krse can only be specified togehter with the krobb option."
					exit 498
			}
			local krse = 1
		}
		else local krse = 0
			
		if ("`kruserdraws'" != "") {
			capture assert `krobb' != 1
			if _rc != 0 {
					di in r "Option kruserdaws can only be specified togehter with the krobb option."
					exit 498
			}
			local kruser = 1    
        }
		else local kruser = 0
		
		if ("`krobb'" == "") local krobb = 1	
		
        ** Generate individual id **
        if ("`e(id)'" != "") {
		
			qui duplicates report `e(id)'
			local np = r(unique_value)	
			tempvar nchoice pid
			sort `e(group)'
			bysort `e(group)': gen `nchoice' = cond(_n==_N,1,0)
			sort `e(id)'
			bysort  `e(id)': egen `pid' = sum(`nchoice')
			local id = 1
        }
        else {
			qui duplicates report `e(group)'
			local np = r(unique_value)
			local id = 0
        }

		** Generate choice occacion id **
        tempvar csid
		
        ** csid: number of observations per choice occasion
        bysort `e(group)': egen `csid' = sum(1)
		
        ** Set Mata matrices to be used in prediction routine **
        local rhs `e(indepvars)'

        tempname b
        matrix `b' = e(b)
		
		tempname V
		matrix `V' = e(V)
		
		** Compute elasticities/marginal effects in Mata
        mata: mixl_elast("`b'", "`V'")
		
		return add
		
	

		** Display output **
		if ("`quietly'" == "") {
			mixlelast_output `alternatives' `for' `weighted' `nosd' `marginal' `type' `absolutechange' `percentchange' `hettype' `krobb' `krse' `krlevel'
			return add
		}
		
		** Returned results **	
		if ("`hettype'" != "0") return local hettype `hettype'
		return local change `changeby'
		if (`type' == 4) return local method = "point"
		else return local method = "arc"
		return local for `for'
		return local alternatives `alternatives'
		return local id `e(id)'
		return local group `e(group)'
		return local cmd "mixlelast"
		if (`krobb' != 1) {
			return scalar kruser = `kruser'
			return scalar krburn = `krburn'
			return scalar krse = `krse'
			if (`krse' == 0) return scalar krlevel = `krlevel'
			return scalar krobb = `krobb'
		}
		return scalar nrep = `nrep'
		return scalar burn = `burn'
		return scalar nosd = `nosd'
		if (`absolutechange' != 0) return scalar absolutechange = `absolutechange'
		if (`percentchange' != 0) return scalar percentchange = `percentchange'
		return scalar weighted = `weighted'
		return scalar marginal = `marginal'
		return scalar het = `het'
		return scalar N_alt = `numalt'
		return scalar N_id = `np'
		return scalar N_group = `numco'
		return scalar N = `totobs'
		
		** Restore data **
        restore
end

capture program drop mixlelast_output
program mixlelast_output, rclass
		version 14.1
		
		args alternatives for weighted nosd marginal type absolutechange percentchange hettype krobb krse krlevel
			
		** Generate row and column labels for output table **
		
		qui local labelname: value label `alternatives'
		qui levelsof `alternatives', local(levels)
		
		if (`krobb' == 1) local rowcat Mean SD
		else if (`krse' == 1) local rowcat Mean SE
		else local rowcat Mean CI_lower CI_upper
		foreach l of local levels{
		
			if ("`labelname'" != "") {
				local collabel `"`collabel'`"`: label `labelname' `l''"'"'
			}
			else {
				local collabel `"`collabel'`"`l'"'"'
			}

			if (`nosd' == 0 | `krobb' != 1){
				foreach r of local rowcat{
					if ("`labelname'" != "") {
						local rowlabel `"`rowlabel'`"`: label `labelname' `l'':`r'"'"'
					}
					else {
						local rowlabel `"`rowlabel'`"`l':`r'"'"'
					}
				}
			}			
		}
		
		** Generate title and subtitle(s) for output table **
		if (`weighted' == 0) local title "Mixed logit sample"
		else local title "Mixed logit probability weighted sample"
					
		if (`marginal' == 0) local title `title' elasticities
		else if (`type' == 4) local title `title'  marginal effects
		else local title `title' incremental effects
			
		if ("`hettype'" != "0") local title `title' (type `hettype')
			
		if (`type' == 1) local subtitle "Calculated for an absolute change of `absolutechange' in `for'"
		else if (`type' == 2) local subtitle "Calculated for a change of `percentchange' per cent in `for'"
		else if (`type' == 3) local subtitle "Calculated for a dummy change in `for'"
		else local subtitle "Calculated for a marginal change in `for'"
			
		if (`krobb' != 1) {
			if (`krse' != 0) local krtype = "standard errors"
			else local krtype = "`krlevel'% confidence intervals"
				
			local subtitle2 "Means and `krtype' by Krinsky-Robb parametric bootstrap with `krobb' repetitions"
		}
			
		** Label output table **
		matrix colnames output = `collabel'	
		if (`nosd' == 0 | `krobb' != 1) matrix rownames output = `rowlabel'
		else matrix rownames output = `collabel'
			
		** Display output table **
		matlist output,title(`title') showcoleq(c)
			
		disp _newline "`subtitle'"
		disp "`subtitle2'"
			
		** Store title and subtitle(s) to r() **
		return local subtitle2 = "`subtitle2'"
		return local subtitle = "`subtitle'"
		return local title "`title'"
end


capture mata mata drop mixl_elast()
version 14.1
mata:
void mixl_elast(string scalar B_s, string scalar V_s)
{
		// Scalars
		kfix = st_numscalar("e(kfix)")
        krnd = st_numscalar("e(krnd)")
        krln = st_numscalar("e(krln)")
		nrep = strtoreal(st_local("nrep"))
	    burn = strtoreal(st_local("burn"))
        corr = st_numscalar("e(corr)")
		krburn = strtoreal(st_local("krburn"))
		coeff = strtoreal(st_local("elastcoeff"))
		type = strtoreal(st_local("type"))
		changeby = strtoreal(st_local("change"))
		marginal = strtoreal(st_local("marginal"))
		np = strtoreal(st_local("np"))
		numalt = strtoreal(st_local("numalt"))
		numco = strtoreal(st_local("numco"))
		het = strtoreal(st_local("het"))
		noSD = strtoreal(st_local("nosd"))
		weighted = strtoreal(st_local("weighted"))
		hettype = strtoreal(st_local("hettype2"))
		kr = strtoreal(st_local("krobb"))
		krlevel = strtoreal(st_local("krlevel"))
		krse = strtoreal(st_local("krse"))
		kruser = strtoreal(st_local("kruser"))
		id = strtoreal(st_local("id"))
		ncho = st_numscalar("e(k_aux)")
		
		// Vectors and matrices
		mixl_X = st_data(., tokens(st_local("rhs")))
		mixl_ID = st_data(., st_local("alternatives2"))
		mixl_CSID = st_data(., st_local("csid"))
		if (id == 1) mixl_T = st_data(., st_local("pid"))
		else mixl_T = J(st_nobs(),1,1)
		if (kruser == 1) external mixl_KRUSERDRAWS
		
		// Get coefficients and (co)variance matrix
        B_ORIGINAL = st_matrix(B_s)'
		V = st_matrix(V_s)
		
		if (kr == 1) {
			B = B_ORIGINAL
		}
		else {
			noSD = 1
			if (kruser == 1) {
				KRERR = invnormal(mixl_KRUSERDRAWS)
			}	
			else if (rows(B_ORIGINAL) <= 10) {
				KRERR = invnormal(halton(kr,rows(B_ORIGINAL),(1+krburn+kr))')
			}
			else {
				KRERR = invnormal(runiform(kr,rows(B_ORIGINAL))')
			}	

			KR = J(kr,numalt^2,.)
		}

		// Loop through kr repititiions
		for (q=1; q<=kr; q++) {
			
			if (kr != 1) B = B_ORIGINAL :+ cholesky(V) * KRERR[.,q]

			kall = kfix + krnd

			if (kfix > 0) {
				MFIX = B[|1,1\kfix,1|]
				MFIX = MFIX :* J(kfix,nrep,1)
			}
			
			MRND = B[|(kfix+1),1\kall,1|]
			
			if (corr == 1) {
				SRND = invvech(B[|(kall+1),1\(kall+ncho),1|]) :* lowertriangle(J(krnd,krnd,1))
			}
			else {
				SRND = diag(B[|(kall+1),1\(kfix+2*krnd),1|])
			}
			
			if (noSD == 1) EFFECTS = J(numalt,numalt,0)
			else EFFECTS = J(numco,numalt^2,0)
			
			P = J(numalt*numco,1,.)

			i = 1
			j = 1
			k = 1

			if (type == 1) mixl_X2 = mixl_X[.,coeff]:+changeby
			if (type == 2) mixl_X2 = mixl_X[.,coeff]:*(1+changeby:/100)			
			if (type == 3) mixl_X2 = abs(mixl_X[.,coeff]:-1)		
			
			DIV = J(numalt,numalt,0)
			
			// Loop through np decision makers
			for (n=1; n<=np; n++) {
				
				if (user == 1) ERR = invnormal(mixl_USERDRAWS[.,(1+nrep*(n-1))..(nrep*n)])
				else ERR = invnormal(halton(nrep,krnd,(1+burn+nrep*(n-1)))')

				if (kfix > 0) BETA = MFIX \ (MRND :+ (SRND*ERR))
				else BETA = MRND :+ (SRND*ERR)
					
				if (krln > 0) {
					if ((kall-krln) > 0) {
						BETA = BETA[|1,1\(kall-krln),nrep|]\exp(BETA[|(kall-krln+1),1\kall,nrep|])
					}
					else {
						BETA = exp(BETA)
					}
				}

				ALPHA = BETA[|coeff,1\coeff,nrep|]
				// folgendes OK
				t = 1
				nc = mixl_T[i,1]
				
				// Loop through nc choice occasions for decision maker n
				for (t=1; t<=nc; t++) {

					XMAT = mixl_X[|i,1\(i+mixl_CSID[i,1]-1),cols(mixl_X)|]
					EV = exp(XMAT*BETA)
					R = EV :/ colsum(EV)
					PROB = mean(R')'
					
					// Point effects
					if (type == 4){
						ALPHA_R = ALPHA:*R
						INDVEFFECTS = (-ALPHA_R*R')
						INDVEFFECTS_cross = (1:-R):*ALPHA_R
						INDVEFFECTS_cross = (rowsum(INDVEFFECTS_cross,1))
						_diag(INDVEFFECTS,INDVEFFECTS_cross)
						if (marginal == 0) INDVEFFECTS = (INDVEFFECTS:*XMAT[.,coeff]'):/PROB
					}
					// Arc effects
					else {
						XMAT2 = mixl_X2[|i\(i+mixl_CSID[i,1]-1)|]
						DIF = XMAT[.,coeff]:-XMAT2
						nr = mixl_CSID[i,1]
						PROB_changed = J(nr,nr,0)
						INDVEFFECTS = J(nr,nr,0)
						MEANP = J(nr,nr,0)
							
						for (r=1; r<=nr; r++){
							XMAT_changed = XMAT
							XMAT_changed[r,coeff] = XMAT2[r,1]
							EV_changed = exp(XMAT_changed*BETA)
							R_changed = EV_changed :/ colsum(EV_changed)
							PROB_changed[.,r] = mean(R_changed',1)'
							INDVEFFECTS[.,r] = (PROB:-PROB_changed[.,r]):/(DIF[r,1])
							
							if (marginal == 0){
								MEANP[.,r] = (PROB_changed[.,r]:+PROB):/2
							}
						}
						
						if (marginal == 0){
							MEANX = (XMAT[.,coeff]:+XMAT2):/2
							INDVEFFECTS = (INDVEFFECTS:*MEANX'):/MEANP
						}
					}

					// For heterogeneous choice sets
					if (het == 1){

						INDVEFFECTS2 = J(numalt,numalt,0)
						pos = mixl_ID[|i,1\i+mixl_CSID[i]-1,1|]
						INDVEFFECTS2[pos,pos] = INDVEFFECTS
						INDVEFFECTS = INDVEFFECTS2
						
						if (noSD == 1 & hettype == 3){
							if (weighted == 1) DIV[pos,pos] = DIV[pos,pos] :+ PROB
							else DIV[pos,pos] = DIV[pos,pos] :+ 1
						}
						
						PROB2 = J(numalt,1,0)
						PROB2[pos] = PROB
						PROB = PROB2
					}

					P[|j,1\j+numalt-1,1|] = PROB

					// Store individual effects
					if (noSD == 1){
						if (weighted == 0) EFFECTS = EFFECTS :+ INDVEFFECTS
						else EFFECTS = EFFECTS :+ PROB:*INDVEFFECTS	
						
					}
					else {
						EFFECTS[k,.] = vec(INDVEFFECTS')'						
					}
					
					i = i+mixl_CSID[i,1]
					j = j+numalt
					++k
				}
			}

			// Generate output table
			if (type == 4) EFFECTS = EFFECTS:/nrep

			P = colshape(P,numalt)
			if (noSD == 1){
				if (weighted == 1){
					if (hettype != 3) DIV = colsum(P)'
				}
				else {
					if (hettype == 0 | hettype == 1) DIV = numco
					else if (hettype == 2) DIV = colsum(P :!= 0)'
				}
				
				OUTPUT = EFFECTS:/DIV
				
				if (kr == 1) MEAN = OUTPUT
				else KR[q,.] = vec(OUTPUT')'
				
			}
			else {
			
				if (weighted == 1){
					weight = P
					if (hettype == 3) _editvalue(EFFECTS,0,.)
				}
				else {
					if (hettype == 0 | hettype == 1) weight = J(numco,numalt,1)
					else if (hettype == 2) weight = (P :!= 0)
					if (hettype == 3){
						_editvalue(EFFECTS,0,.)
						weight = (P :!= 0)
					}
				}
				MEAN=J(numalt,numalt,.)
				SD=J(numalt,numalt,.)
				i = 1
				for (a=1; a<=numalt; a++) {
					w = weight[.,a]
					for (b=1; b<=numalt; b++){
						MEAN[a,b] = mean(EFFECTS[.,i],w)
						sd = (EFFECTS[.,i]:-MEAN[a,b])
						sd = sum(sd:*sd:*w):/sum(w)
						SD[a,b] = sqrt(sd)
						i++
					}
				}
			OUTPUT=colshape((MEAN,SD),numalt)
			}
			
			// Krinsky-Robb output
			if (kr > 1 & q == kr){
				KRSE = J(1,numalt^2,.)
				for (a=1; a<=numalt^2; a++){
					KR[.,a] = sort(KR[.,a],1)
					KRSE[.,a] = sqrt(variance(KR[.,a],1))
				}
			
			sig = ((100-krlevel)/2)/100
						kr_low = max((floor((kr)*sig),1))
						kr_high = min((ceil((kr+1)*(1-sig)),kr))
						KR_low = KR[kr_low,.]
						KR_high = KR[kr_high,.]
						st_matrix("r(ci_lower)",colshape(KR_low,numalt))
						st_matrix("r(ci_upper)",colshape(KR_high,numalt))
						st_matrix("r(krse)",colshape(KRSE,numalt))
						
						if (krse == 1){
							OUTPUT = colshape(mean(KR),numalt),colshape(KRSE,numalt)
						}
						else {
							OUTPUT = colshape(mean(KR),numalt),colshape(KR_low,numalt),colshape(KR_high,numalt)					
						}
			
				OUTPUT = colshape(OUTPUT,numalt)	
				MEAN = colshape(mean(KR),numalt)
				
			}
			else {
				
				st_matrix("r(sd)",colshape(SD,numalt))
		
			}
			
			st_matrix("r(mean)",MEAN)
			st_matrix("output",OUTPUT)
		
		}

}
end
