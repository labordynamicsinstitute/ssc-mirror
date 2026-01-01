*! command: ComSupp; version: 7 02 October 2024
*! Enrico Cristofoletti
***************************	
*VERSION HISTORY
*gpsmdcomsup7 is the same as gpsmdcomsup6 but it is converted to a r-class command (before n-class but it was difficult to integrate with the other ado files)
***************************	
*gpsmdcomsup +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
***************************	
program define gpsmdcomsup, rclass
	version 14.2
	*
	#delimit ;
	syntax  varlist(min=2) , 
	exogenous(varlist)
	index(string) 
	cutpoints(numlist integer max=1)
	obs_notsup(string)
	[testing(numlist integer max=1)
	ln(varlist)
	]
	;
	#delimit cr	
	/*
	varlist: the treatment in the same order as the GPSMD command
	exogenous: exogenous var in the same order that in the GPSMD command
	index: the point where you want to calculate GPSMD (can be "mean" or "p50"
	cutpoints: the number of discrete intervals of the dimensions of the treatment
	obs_notsup: the name for the dummy variable 1->not balanced 0->balanced
	testing: if 1 also the various Gps calculated are generated as obs_notsup#
	ln(varlist): the treatment dimensions we want to take the log transform
	*/
	*copy start***
	*I copy all returns output of gpsmd so that I can return them at the end of the program (otherwise there is not compatibility with gpsmdbal)
		local listvarFS "`varlist'"
		if "`ln'"!="" {
			foreach i of local ln {
				local listvarFS= subinstr("`listvarFS'", "`i'", "LN_`i'",.)
			}
		}
		local cmdline `"`r(cmdline)'"'
		local cmd `"`r(cmd)'"'
		foreach gpsmddimen of local listvarFS{ 
			local cmdline`gpsmddimen' `"`r(cmdline`gpsmddimen')'"'
		}
		local Dimensions `"`r(Dimensions)'"'
		local DimensionsFS `"`r(DimensionsFS)'"'
		local LNVarCreated `"`r(LNVarCreated)'"'
		local ExogenousGPSMD `"`r(Exogenous)'"'
		local gpsmdvar `"`r(gpsmdvar)'"'
		local chosenpointGPSMD `"`r(chosenpoint)'"' 
		*the matrix var covar
		tempname VarCov_matgps
		matrix define `VarCov_matgps'= r(VarCov)
	*copy end***
	*Check start***
	capture: assert "`index'"=="mean" | "`index'"=="p50"
	if _rc!=0{
		display as error `"index can be "mean" or "p50""'
		error
	}
	capture: ds `obs_notsup'*
	if _rc==0{
		foreach i in `=r(varlist)' {
			confirm new variable `i'
		}
	}
	*Check end***
	*I generate the list of transformed variables and I import in mata the variables needed	
		tempname treatments exogen TempResults logTrans
		if "`ln'"==""{
			mat define `logTrans' = (0)
		}
		else if "`ln'"!="" {
			*checks start***
			capture: assert `: word count `ln''<= `: word count `varlist'' 
			if _rc!=0 {
				display as error "You are trying to transform a number of dimensions higher than the total number of dimensions "
				error
			}
			foreach i of local ln{
				capture: assert strmatch("`varlist'","*`i'*")==1
				if _rc!=0 {
					display as error "You are trying to transform a dimension which has not been previously stated"
					error
				}
			}
			*checks end***
			foreach i of local ln{
				if `: list posof "`i'" in ln'==1{
					mat define `logTrans'=( `: list posof "`i'" in varlist' )
				}
				else if `: list posof "`i'" in ln'!=1{
					mat define `logTrans'=( `logTrans', `: list posof "`i'" in varlist' )
				}
			}
		}
		mata: `treatments' = st_data(.,("`varlist'"))
		mata: `exogen' = st_data(.,("`exogenous'")) 
		mata: `logTrans' = st_matrix("`logTrans'")
	*I actually calculate the common support
	mata: `TempResults'=gpsmdcomsup(`treatments',  `exogen', `cutpoints', "`index'", `logTrans')
	if "`testing'"!="1" {
		mata: st_matrix("`obs_notsup'", `TempResults'[., cols(`TempResults')])
		svmat double `obs_notsup', names("`obs_notsup'")
		rename `obs_notsup'1 `obs_notsup'
		matrix drop `obs_notsup'
	}
	else if "`testing'"=="1"{
		mata: st_matrix("`obs_notsup'", `TempResults' )
		svmat double `obs_notsup', names("`obs_notsup'")
		matrix drop `obs_notsup'
	}
	display _newline "****************" _newline `"COMMON SUPPORT (variable: "`obs_notsup'")"' _newline "1 corresponds to observations outside the common support" _newline "0 corresponds to observations inside the common support" _newline "****************" _newline
	tab `obs_notsup' //The problem of leaving gpsmdcomsup n-class is this tab but I find it useful
	*I return all returns output of gpsmd (otherwise there is not compatibility with gpsmdbal) (In a sense gpsmdcomsup remains n-class)
		return clear
		*I generate those I want
		return local cmdline `"`cmdline'"'
		return local cmd `"`cmd'"'
		foreach gpsmddimen of local listvarFS { 
		return local cmdline`gpsmddimen' `"`cmdline`gpsmddimen''"'
		}
		*the dimension of the treatment and the exogenous vars
		return local Dimensions `"`Dimensions'"'
		return local DimensionsFS `"`DimensionsFS'"'
		return local LNVarCreated `"`LNVarCreated'"'
		return local Exogenous `"`ExogenousGPSMD'"'
		return local gpsmdvar `"`gpsmdvar'"'
		return local chosenpoint `"`chosenpointGPSMD'"'
		*the matrix var covar
		return matrix VarCov = `VarCov_matgps'	
end
*MATA PART----------------------------------------------------------------------
mata: 
//************
//LinReg(dep, indep)
	struct LinRegS
	{
	real matrix B, RES, PRE
	//B: coefficients; RES: residuals ; PRE: predictions. But actually it is simply  new object with three spaces that are matrixes
	}
	struct LinRegS scalar LinReg(real matrix depvar, real matrix indepvar)
		{
		struct LinRegS scalar LR
		real matrix indep
		real matrix dep
		//adapted from here https://blog.stata.com/2016/01/05/programming-an-estimation-command-in-stata-computing-ols-objects-in-mata/
		//see also https://www.stata-journal.com/sjpdf.html?articlenum=pr0035
			indep=(indepvar, J(rows(indepvar),1,1))
			dep=depvar
		//formula OLS: B= (X'X)^-1 (X'Y)
		LR.B=invsym(quadcross(indep, indep)) * quadcross(indep, dep)
		//formula residuals RES=Y- X*B
		LR.RES = dep - indep*LR.B
		//formula Prediction 
		LR.PRE = indep*LR.B
		return(LR)
		}
//************
//************
//gpsMDGivenPoint
	real matrix gpsMDGivenPoint(real matrix Dim, real matrix exogenous, real matrix Chosentreat, real matrix LogTranslist)  
		{
		struct LinRegS scalar LMFirstStage
		real matrix usedDIM
		real matrix usedChosentreat
		real matrix ResMat
		real matrix usedChosentreatMat
		real matrix ResfromChoTrMat
		real matrix VarMat
		real matrix gps
		usedDIM=Dim
		usedChosentreat=Chosentreat
		if (LogTranslist!=0){
			for (i=1; i<=cols(LogTranslist); i++){
				usedDIM[., LogTranslist[1, i]]=ln(usedDIM[.,LogTranslist[1, i]])
				usedChosentreat[., LogTranslist[1, i]] = ln(usedChosentreat[.,LogTranslist[1, i]])
			}	
		}
		//Dim: matrix with one col for every dimension of the treatment
		//exogenous: matrix with the exogenous variables and possibly the interactions
		//Chosentreat: is a rowvector with the chosen treatment in each dimension
		//LogTranslist: rowvector, each dimension includes the position in Dim of the treatment dimension we want to transform 
		//I generate the residuals for the regression and from the prediction and the chosen treatment:
			for (i=1;i<=cols(usedDIM);i++){
				LMFirstStage=LinReg( usedDIM[.,i] , exogenous )
				if (i==1){
					ResMat=LMFirstStage.RES
					usedChosentreatMat=J(rows(usedDIM), 1, usedChosentreat[1,i])
					ResfromChoTrMat = usedChosentreatMat - LMFirstStage.PRE
				}
				else if (i>1){
					ResMat=(ResMat, LMFirstStage.RES)
					usedChosentreatMat=J(rows(usedDIM), 1, usedChosentreat[1,i])
					ResfromChoTrMat = (ResfromChoTrMat, (usedChosentreatMat - LMFirstStage.PRE))
				}
			}
		//I calculate the variance covariance of the residuals
			VarMat = variance(ResMat)
		//I calculate the gps vector
			gps=(1/(((2* pi())^(cols(usedDIM)/2))*((det(VarMat))^(1/2)))) * exp((-1/2) * diagonal((ResfromChoTrMat) * (invsym( VarMat )) * ((ResfromChoTrMat)')))
		//if (LogTranslist!=0) I retransform
		if (LogTranslist!=0){
			for (i=1; i<=cols(LogTranslist); i++){
			gps = gps :/ Chosentreat[1, LogTranslist[1, i]]
			}	
		}	
			return(gps)
		}
//************
//gpsmdcomsup
	real matrix gpsmdcomsup(real matrix treatments, real matrix exogenous, real scalar cutpoints, string scalar index, real matrix LogTranslist)
		{
		//the output is a vector which is 1 if the obs must be dropped and 0 otherwise (Obs_unbal)
		//treatments: matrix with the column with the treatments
		//exogenous: matrix with the exogenous variables and possibly the interactions
		//cutpoints: the number of discrete intervals of the dimensions of the treatment
		//index if you want the chosenpoint evaluated at the mean or at the median "mean"|"p50"
		//LogTranslist: rowvector, each dimension includes the position in Dim of the treatment dimension we want to transform 
		real matrix Obs_unbal
		real scalar ntreatments
		real matrix dta
		real matrix tempPercetile
		real matrix groupsid
		real matrix Groupsindta
		real matrix chosenpoints
		real matrix tempchosenpointsCol
		real matrix tempmed
		real matrix tempgroupandgps
		real matrix tempgroup
		real matrix tempnogroup
			//I define the number of treatment
			ntreatments= cols(treatments)
			//I generate a new matrix with all together treatments plus as the first column a vector with the numbers 
			//from 1 to rows(treatments) in order to keep the order
				dta=( (1 .. rows(treatments))',  treatments)
			//I generate the percentile needed for the ith treatment
				for (i=2; i<=(ntreatments+1);i++){
					//I sort dta for the ith treatment
						dta= dta[order(dta[., i], 1),.]
					//I add a vector at the end for the quantiles 
						tempPercetile=trunc( (cutpoints :* ( (1.. rows(dta))':-1 )) :/ rows(dta) ) :+1  
					//I substitute with tempPercetile[_n-1, 1] if dta[_n, 1+1]==dta[_n-1, 1+1]
						for (j=2;j<=rows(dta);j++){
							if (dta[j, i]==dta[(j-1), i]){
								tempPercetile[j,1]=tempPercetile[(j-1),1]
							}
						}
					//I add the column with the percentiles
						dta=(dta, tempPercetile)
					}
			//I generate the groupsid
				//I generate a matrix with the unique rows of percentiles
					groupsid=uniqrows(dta[.,((ntreatments+2)..cols(dta))]) 
				//I add a column for the identifiers of the group
					groupsid=((1.. rows(groupsid))', groupsid)
				//I add the group as a the last column in dta
					Groupsindta=J(rows(dta), 1 ,0)
					for (i=1; i<=rows(groupsid); i++){
						for (j=1; j<=rows(dta); j++){
							if ( dta[j,((ntreatments+2)..cols(dta))]==groupsid[ i, (2..cols(groupsid))] ){
								Groupsindta[j,1] = i
							}
						}
					}
					//I remove the percentiles and I add Groupsindta to  dta
						dta= dta[.,(1..(ntreatments+1))]
						dta=(dta , Groupsindta)
				//dta is now (colvec id, matrix dimension, colvec grupsid)
			//I generate the matrix with the treatments it will have a column for each treatment and a row for each discrete group
				chosenpoints= J(rows(groupsid), ntreatments, 0)
				for (i=2; i<=(ntreatments+1); i++){
					tempchosenpointsCol= J(rows(groupsid),1,0)
					for (j=1; j<=rows(groupsid); j++){
						if (index=="mean"){
							tempchosenpointsCol[j,1]= mean(select(dta[., i], (dta[., cols(dta)] :== j )))
						}
						else if (index=="p50"){
							//see https://www.statalist.org/forums/forum/general-stata-discussion/mata/1335405-can-i-use-mata-to-calculate-a-median-of-the-outcome-in-the-exposed-and-unexposed-groups-following-matching-with-teffects-psmatch
							tempmed=select(dta[., i], (dta[., cols(dta)] :== j))
							tempmed=tempmed[order(tempmed,1), 1 ]
							if (ceil((rows(tempmed)*0.5))==(rows(tempmed)*0.5)){
								tempchosenpointsCol[j,1]= (tempmed[(rows(tempmed)*0.5),1] + tempmed[((rows(tempmed)*0.5) + 1 ),1])/2
							}
							else {
								tempchosenpointsCol[j,1]= 	tempmed[ceil(rows(tempmed)*0.5),1]							
							}
						}
					}
					chosenpoints[., (i-1)]= tempchosenpointsCol[., 1]
				}
			//I generate the propensity score at a given point for each chosenpoint and I update the vector Obs_unbal with the unbalanced obs
				//since exogenous is sorted as in the dataset, I sort dta as the dataset
					dta=dta[order(dta[.,1], 1), .]
				//I calculate the gps and I update Obs_unbal
					Obs_unbal= J(rows(dta), 1, 0)
					for (i=1; i<=rows(chosenpoints); i++){
						tempgroupandgps= (dta[., (cols(dta))] , gpsMDGivenPoint(dta[.,(2..(ntreatments+1))], exogenous, chosenpoints[i, .] , LogTranslist)) 
						tempgroup=select(tempgroupandgps[., (cols(tempgroupandgps))], (tempgroupandgps[.,1]:==i))
						tempnogroup=select(tempgroupandgps[., (cols(tempgroupandgps))], (tempgroupandgps[.,1]:!=i))
						assert(cols(tempgroupandgps)==2) //check
						assert(cols(tempgroup)==1) //check
						assert(cols(tempnogroup)==1) //check
						Obs_unbal[ selectindex( ( tempgroupandgps[., cols(tempgroupandgps)] :< max( ( min(tempgroup), min(tempnogroup) ) ) ) :| ( tempgroupandgps[., cols(tempgroupandgps)] :> min( ( max(tempgroup), max(tempnogroup ) ) ) ) :| (Obs_unbal:==1)) , 1] = ///
						J(rows(selectindex( ( tempgroupandgps[., cols(tempgroupandgps)] :< max( ( min(tempgroup), min(tempnogroup) ) ) ) :| ( tempgroupandgps[., cols(tempgroupandgps)] :> min( ( max(tempgroup), max(tempnogroup ) ) ) ) :| (Obs_unbal:==1))), 1, 1)		
						//I save the gps at a given point for cases when testing==1
						if (i==1){
							gpsPP= tempgroupandgps[., cols(tempgroupandgps)]
						}
						else{
							gpsPP=(gpsPP, tempgroupandgps[., cols(tempgroupandgps)])
						}
					}
					//tempgroup
					//tempnogroup
					//tempgroupandgps
					//chosenpoints
					//(dta, Obs_unbal)
					return((gpsPP, Obs_unbal))
		}
//************		
end 
