*! ddml v1.2
*! last edited: 21 jan 2023
*! authors: aa/ms

program define _ddml_extract, rclass
    version 16.0

	syntax [name] , [				///
				mname(name)			/// ignored if ename(.) provided
				ename(name)			///
				vname(varname)		///
				show(name)			/// pystacked, mse or n allowed
				detail				///
				keys				///
				key1(string)		///
				key2(string)		///
				key3(string)		///
				subkey1(string)		///
				subkey2(string)		///
				stata				///
				]
	
	*** syntax checks
	if "`mname'`ename'"=="" {
		di as err "error - must provide either mname(.) or ename(.)"
		exit 198
	}
	if "`mname'"~="" & "`ename'"~="" {
		// ignore mname if ename provide
		local mname
	}
	// show macro can be lower or upper case; upper required below
	local show = upper("`show'")
	// syntax check
	local showlist PYSTACKED MSE N SHORTSTACK
	if "`show'"~="" {
		local showok : list posof "`show'" in showlist
		if `showok'==0 {
			di as err "error - show(" lower("`show'") ") not supported"
			exit 198
		}
	}
	
	local keysflag		= ("`keys'"~="")
	local detailflag	= ("`detail'"~="")
	
	// "return clear" clears return(.) but not r(.); use this instead
	mata : st_rclear()
	
	tempname obj mtemp etemp

	if "`mname'"=="" {
		mata: `mtemp' = init_mStruct()
		mata: `obj' = m_ddml_extract("",`mtemp',"`ename'",`ename',`keysflag',"`show'",`detailflag',"`vname'","`key1'","`key2'","`key3'","`subkey1'","`subkey2'")
	}
	else if "`ename'"=="" {
		mata: `etemp' = init_eStruct()
		mata: `obj' = m_ddml_extract("`mname'",`mname',"",`etemp',`keysflag',"`show'",`detailflag',"`vname'","`key1'","`key2'","`key3'","`subkey1'","`subkey2'")
	}
	
	if "`namelist'"=="" {
		mata: `obj'
		mata: mata drop `obj'
	}
	else if "`namelist'"=="`mname'" {
		// stop silly mistake of overwriting the model struct
		di as err "error - cannot save Mata object `mname'; `mname' contains the ddml model"
		exit 198
	}
	else if "`stata'"=="" {
		cap mata: mata drop `namelist'
		mata: mata rename `obj' `namelist'
	}
	else {
		mata: st_local("eltype",eltype(`obj'))
		mata: st_local("orgtype",orgtype(`obj'))
		if "`eltype'"=="string" {
			mata: st_global("r(`namelist')",`obj')
		}
		else if "`orgtype'"=="scalar" {
			mata: st_numscalar("r(`namelist')",`obj')
		}
		else if ("`orgtype'"=="matrix") | ("`orgtype'"=="rowvector") | ("`orgtype'"=="colvector") {
			mata: st_matrix("r(`namelist')",`obj')
		}
		else {
			di as err "unsupported eltype `eltype' / orgtype `orgtype'"
			exit 198
		}
	}
	return add
	cap mata: mata drop `mtemp'
	cap mata: mata drop `etemp'
	
end

********************************************************************************
*** Mata section															 ***
********************************************************************************

mata:

transmorphic m_ddml_extract(		string scalar mname,		///
									struct mStruct d,			///
									string scalar ename,		///
									struct eStruct e,			///
									real scalar keysflag,		///
									string scalar show,			///
									real scalar detailflag,		///
									string scalar vname,		///
									string scalar key1,			///
									string scalar key2,			///
									string scalar key3,			///
									string scalar subkey1,		///
									string scalar subkey2		///
									)
{
	struct eStruct scalar eqn
	class AssociativeArray scalar AA

	if (show=="PYSTACKED") {
		rmatlist = J(1,0,"")
		vnames =(d.eqnAA).keys()
		vnames = sort(vnames,(1::cols(vnames))')
		for (i=1;i<=rows(vnames);i++) {
			eqn = (d.eqnAA).get(vnames[i])
			rmatlist = (rmatlist, pystacked_extract(d,eqn,vnames[i],"weights",detailflag))
			rmatlist = (rmatlist, pystacked_extract(d,eqn,vnames[i],"MSEs",detailflag))
		}
		// rmatlist can be empty if pystacked called with a single learner
		if (cols(rmatlist)>0) {
			st_global("r(matlist)",invtokens(sort(rmatlist,1)))
		}
	}
	else if (show=="SHORTSTACK") {
		vnames =(d.eqnAA).keys()
		vnames = sort(vnames,(1::cols(vnames))')
		nreps = d.nreps
		rmatlist = J(1,0,"")
		for (i=1;i<=rows(vnames);i++) {
			eqn = (d.eqnAA).get(vnames[i])
			vtlist = eqn.vtlist
			if ((eqn.ateflag==0) & (eqn.lieflag==0)) {
				// base case - plm, plm IV, ATE D, LATE Z, LIE Y
				// initialize
				cstripe = "mean_weight"
				rmat = J(0,eqn.nlearners,.)
				vnkey = vnames[i] + "_ssw"
				for (m=1;m<=nreps;m++) {
					AA = (d.estAA).get(("ss",strofreal(m)))
					rrep = AA.get((vnkey,"matrix"))
					rmat = (rmat \ rrep)
					cstripe = (cstripe \ ("rep_"+strofreal(m)))
				}
				// add mean across reps
				rmat = (mean(rmat) \ rmat)
				// in output, rows are learners, columns are resamples
				rmat = rmat'
				cstripe = (J(rows(cstripe),1,""), cstripe)
				rstripe = (vtlist)'
				rstripe = (J(rows(rstripe),1,""), rstripe)
				st_matrix("r("+vnkey+")",rmat)
				st_matrixcolstripe("r("+vnkey+")",cstripe)
				st_matrixrowstripe("r("+vnkey+")",rstripe)
				rmatlist = (rmatlist, vnkey)
				printf("\n{res}short-stacked weights across resamples for %s\n",vnames[i])
				stata("mat list " + "r("+vnkey+"), noheader noblank")
			}
			else {
				// LIE means D and Dhat so we need a column to indicate h=0/1
				// ATE/LATE means we need a column for D or Z = 0/1
				// initialize
				if (eqn.lieflag==1) {
					cstripe = ("h=0/1" \ "mean_weight")
				}
				else if (d.model=="interactive") {
					cstripe = ("D=0/1" \ "mean_weight")
				}
				else {
					cstripe = ("Z=0/1" \ "mean_weight")
				}
				rmat0 = J(0,eqn.nlearners,.)
				rmat1 = J(0,eqn.nlearners,.)
				vnkey = vnames[i] + "_ssw"
				vnkey_h = vnames[i] + "_h_ssw"
				vnkey0 = vnames[i] + "_ssw0"
				vnkey1 = vnames[i] + "_ssw1"
				for (m=1;m<=nreps;m++) {
					AA = (d.estAA).get(("ss",strofreal(m)))
					if (eqn.lieflag==1) {
						// D
						rrep0 = AA.get((vnkey,"matrix"))
						// Dhat
						rrep1 = AA.get((vnkey_h,"matrix"))
					}
					else {
						// D/Z=0
						rrep0 = AA.get((vnkey0,"matrix"))
						// D/Z=1
						rrep1 = AA.get((vnkey1,"matrix"))
					}
					rmat0 = (rmat0 \ rrep0 )
					rmat1 = (rmat1 \ rrep1 )
					cstripe = (cstripe \ ("rep_"+strofreal(m)))
				}
				// add mean across reps
				rmat0 = (mean(rmat0) \ rmat0)
				rmat1 = (mean(rmat1) \ rmat1)
				// in output, rows are learners, columns are resamples
				rmat0 = rmat0'
				rmat1 = rmat1'
				// add h column
				rmat0 = (J(rows(rmat0),1,0) , rmat0)
				rmat1 = (J(rows(rmat1),1,1) , rmat1)
				// combine
				rmat = (rmat0 \ rmat1)
				// add sort column to rmat
				lnum = runningsum(J(eqn.nlearners,1,1))
				lnum = (lnum \ lnum)
				rmat = (lnum, rmat)
				// sort rmat
				if (eqn.lieflag==1) {
					// with LIE, group vnames (with/without h) together)
					rmat = sort(rmat, (1,2))
				}
				else {
					// group by 0/1
					rmat = sort(rmat, (2,1))
				}
				// remove sort column
				rmat = rmat[.,2..cols(rmat)]
				cstripe = (J(rows(cstripe),1,""), cstripe)
				rstripe = J(0,1,"")
				if (eqn.lieflag==1) {
					for (vn=1;vn<=cols(vtlist);vn++) {
						rstripe = (rstripe \ vtlist[vn] \ (vtlist[vn]+"_h"))
					}
				}
				else {
					rstripe = (vtlist' \ vtlist')
				}
				rstripe = (J(rows(rstripe),1,""), rstripe)
				st_matrix("r("+vnkey+")",rmat)
				st_matrixcolstripe("r("+vnkey+")",cstripe)
				st_matrixrowstripe("r("+vnkey+")",rstripe)
				rmatlist = (rmatlist, vnkey)
				printf("\n{res}short-stacked weights across resamples for %s\n",vnames[i])
				stata("mat list " + "r("+vnkey+"), noheader noblank")
			}
		}
		st_global("r(matlist)",invtokens(sort(rmatlist,1)))
	}
	else if ((show=="MSE") | (show=="N")) {
		rmatlist = J(1,0,"")
		vnames =(d.eqnAA).keys()
		vnames = sort(vnames,(1::cols(vnames))')
		for (i=1;i<=rows(vnames);i++) {
			eqn = (d.eqnAA).get(vnames[i])
			rmatmse = J(0,1,.)
			rmatmse_folds = J(0,d.kfolds,.)
			reqn = J(0,1,"")
			rvtilde = J(0,1,"")
			rsmp = J(0,1,.)
			DZeq01 = J(0,1,.)
			vkeys = (eqn.resAA).keys()
			// sort keys by vtilde, rep, and lastly "MSE" or "MSE_folds"
			// means that when looping through, when j=MSE then j+1=MSE_folds for same vtilde and rep
			vkeys = sort(vkeys,(1,3,2))
			for (j=1;j<=rows(vkeys);j++) {
				if ((strpos(vkeys[j,2],show)==1) & (strpos(vkeys[j,2],"folds")==0)) {
					rmatmse = (rmatmse \ (eqn.resAA).get(vkeys[j,.]))
					reqn = (reqn \ vnames[i])
					if (strpos(vkeys[j,2],"0")) {
						DZeq01 = (DZeq01 \ 0)
					}
					else if (strpos(vkeys[j,2],"1")) {
						DZeq01 = (DZeq01 \ 1)
					}
					vt = vkeys[j,1]
					if ((vkeys[j,2]=="MSE_h") | (vkeys[j,2]=="N_h")) {
						vt = vt + "_h"
					}
					rvtilde = (rvtilde \ vt)
					rsmp = (rsmp \ strtoreal(vkeys[j,3]))
				}
				if ((strpos(vkeys[j,2],show)==1) & (strpos(vkeys[j,2],"folds")>0)) {
					rmatmse_folds =(rmatmse_folds \ (eqn.resAA).get(vkeys[j,.]))
				}
			}
			// store as r(.) macro
			// if interactive or LATE, include column for D/Z=0 or D/Z=1
			if (rows(DZeq01)>0) {
				rmat = (DZeq01, rsmp, rmatmse, rmatmse_folds)
				if (d.model=="interactive") {
					cstripe = ("D=0/1" \ "rep" \ "full_sample")
				}
				else {	// LATE
					cstripe = ("Z=0/1" \ "rep" \ "full_sample")
				}
			}
			else {
				rmat = (rsmp, rmatmse, rmatmse_folds)
				cstripe = ("rep" \ "full_sample")
			}
			rname = vnames[i]+"_mse"
			st_matrix("r("+rname+")",rmat)
			rstripe = (J(rows(rmat),1,""), rvtilde)
			st_matrixrowstripe("r("+rname+")",rstripe)
			// add fold numbers to column stripe
			for (k=1;k<=d.kfolds;k++) {
				cstripe = (cstripe \ "fold"+strofreal(k))
			}
			cstripe = (J(rows(cstripe),1,""), cstripe)
			st_matrixcolstripe("r("+rname+")",cstripe)
			rmatlist = (rmatlist, rname)
			st_global("r(matlist)",invtokens(sort(rmatlist,1)))
			display_mse(d, show, reqn, rvtilde, DZeq01, rsmp, rmatmse, rmatmse_folds)
		}
	}
	else if (ename~="") {
		// eStruct provided
		if (keysflag) {
			printf("{txt}AA keys for eqn %s.lrnAA:\n",ename)
			keymat = (e.lrnAA).keys()
			sort(keymat,(1::cols(keymat))')
			printf("{txt}AA keys for eqn %s.resAA:\n",ename)
			keymat = (e.resAA).keys()
			sort(keymat,(1::cols(keymat))')
		}
		else if (key3=="") {
			// only 2 keys, it's lrnAA
			return((e.lrnAA).get((key1,key2)))
		}
		else {
			// 3 keys, it's resAA		
			return((e.resAA).get((key1,key2,key3)))
		}
	}
	else if (mname~="") {
		// mStruct provided
		if ((keysflag) & (vname=="")) {
			if (vname=="") {
				// no vname means show the keys for the model struct AAs
				printf("{txt}AA keys for %s.eqnAA:\n",mname)
				keymat =(d.eqnAA).keys()
				keymat = sort(keymat,(1::cols(keymat))')
				keymat
				printf("{txt}AA keys for %s.estAA:\n",mname)
				keymat = (d.estAA).keys()
				keymat = sort(keymat,(1::cols(keymat))')
				keymat
				for (i=1;i<=rows(keymat);i++) {
					if (classname((d.estAA).get((keymat[i,.])))=="AssociativeArray") {
						k1 = keymat[i,1]
						k2 = keymat[i,2]
						printf("{txt}AA keys for %s.estAA, key 1=%s and key 2=%s:\n",mname,k1,k2)
						AA = (d.estAA).get((keymat[i,.]))
						keymat2 = AA.keys()
						sort(keymat2,(1::cols(keymat2))')
					}
				}
			}
		}
		else if (keysflag) {
			if (vname~="") {
				vlist = J(1,1,vname)
			}
			else {
				vlist = (d.nameY, d.nameD, d.nameZ)
			}
			for (v=1;v<=cols(vlist);v++) {
				eqn = (d.eqnAA).get(vlist[v])
				printf("{txt}AA keys for eqn %s.lrnAA:\n",vlist[v])
				keymat = (eqn.lrnAA).keys()
				sort(keymat,(1::cols(keymat))')
				printf("{txt}AA keys for eqn %s.resAA:\n",vlist[v])
				keymat = (eqn.resAA).keys()
				sort(keymat,(1::cols(keymat))')
			}
		}
		else if (vname=="") {

			// no vname means extract from the model struct estAA. 2 keys.
			if (classname((d.estAA).get((key1,key2)))=="AssociativeArray")  {
				// AA with estimation results, 2 subkeys or return the AA
				AA = (d.estAA).get((key1,key2))
				if ((subkey1+subkey2)=="") {
					return(AA)
				}
				else {
					return(AA.get((subkey1,subkey2)))
				}
			}
			else {
				// not an AA, or AA but no subkeys
				return((d.estAA).get((key1,key2)))
			}
		}
		else {
			// vname is in either nameY, nameD or nameZ
			eqn = (d.eqnAA).get(vname)
			if ((key1+key2)=="") {
				// no keys, return eqn
				return(eqn)
			}
			else if (key3=="") {
				// only 2 keys, it's lrnAA
				return((eqn.lrnAA).get((key1,key2)))
			}
			else {
				// 3 keys, it's resAA	
				return((eqn.resAA).get((key1,key2,key3)))
			}
		}
		
	}
	
}

function pystacked_extract(									///
								struct mStruct d,			///
								struct eStruct eqn,			///
								string scalar vname,		///
								string scalar kstrings,		/// either "weights" or "MSEs"
								real scalar detailflag		///
								)
{
	
	// kstrings = key string, "weights" or "MSEs"
	// kabbrev = "_w" or "_m"
	// kstring = key string minus s at the end
	kabbrev = "_" + strlower(substr(kstrings,1,1))
	kstring = substr(kstrings,1,strlen(kstrings)-1)
	
	rmatlist = J(1,0,"")
	vkeys = (eqn.resAA).keys()
	// to do sort, need to transform rep number string into a sortable string
	// e.g. if nrep<1000, 1=>001, 50=050, 100=>100 etc.
	// extract rep number as string
	repstring = vkeys[.,cols(vkeys)]
	// prefix of many zeros
	zstring = "00000000000000000000"
	// add to start of rep number and then keep the final characters in the string
	for (j=1;j<=rows(repstring);j++) {
		repstring[j] = substr(zstring+repstring[j],strlen(repstring[j]))
	}
	// append to last column of vkeys, sort and then drop
	vkeys = (vkeys, repstring)
	vkeys = sort(vkeys,(1,2,4))
	vkeys = vkeys[.,(1::3)]
	
	for (j=1;j<=cols(eqn.vtlist);j++) {

		// initialize
		vkeys_i = select(vkeys,vkeys[.,1]:==(eqn.vtlist)[j])
		swflag = 0
		// rmat will have all weights/MSEs for all learners for vt name j
		// if ATE/LATE, an additional column is needed, and similarly for LIE
		if ((eqn.ateflag==0) & (eqn.lieflag==0)) {
			rmat_all = J(0,2+d.kfolds,0)
		}
		else {
			rmat_all = J(0,3+d.kfolds,0)
		}
		rstripe = J(0,1,"")
		
		for (k=1;k<=rows(vkeys_i);k++) {
			if (strpos(vkeys_i[k,2],"stack_"+kstrings)) {
				swflag = 1		// stack weights/MSEs encountered
				rname=vkeys_i[k,1]
				if (vkeys_i[k,2]==("stack_"+kstrings)) {
					DZeq01 = ""
					treat = .
					hflag = 0
				}
				else if (vkeys_i[k,2]==("stack_"+kstrings+"_h")) {
					DZeq01 = ""
					treat = .
					hflag = 1
				}
				else if (vkeys_i[k,2]==("stack_"+kstrings+"0")) {
					DZeq01 = "0"
					treat = 0
					hflag = .
				}
				else if (vkeys_i[k,2]==("stack_"+kstrings+"1")) {
					DZeq01 = "1"
					treat = 1
					hflag = .
				}
				rmat = (eqn.resAA).get(vkeys_i[k,.])
				if ((hflag==0) | (hflag==.)) {
					base_est = tokens((eqn.lrnAA).get((vkeys_i[k,1],"stack_base_est")))'
					rstripe = rstripe \ base_est
				}
				else {
					base_est_h = tokens((eqn.lrnAA).get((vkeys_i[k,1],"stack_base_est_h")))'
					rstripe = rstripe \ base_est_h
				}
				if (rmat~=J(0,0,.)) {
					// col 1 is learner number, col 2 is treatment/hflag (if needed), col 3 is rep number (in AA as string)
					if ((eqn.ateflag==0) & (eqn.lieflag==0)) {
						rmat_k = ( (1::rows(rmat)) , J(rows(rmat),1,strtoreal(vkeys_i[k,3])) , rmat)
					}
					else if (eqn.ateflag==1) {
						rmat_k = ( (1::rows(rmat)) , J(rows(rmat),1,treat), J(rows(rmat),1,strtoreal(vkeys_i[k,3])) , rmat)
					}
					else {
						rmat_k = ( (1::rows(rmat)) , J(rows(rmat),1,hflag), J(rows(rmat),1,strtoreal(vkeys_i[k,3])) , rmat)
					}
					rmat_all = rmat_all \ rmat_k
				}
			}
		}
			
		// process if any stacking weights encountered
		if (rows(rmat_all) > 0) {
			// rmat_all has full set of weights for all learners
			if ((eqn.ateflag==0) & (eqn.lieflag==0)) {
				cstripe = ("learner" \ "resample")
			}
			else if (eqn.lieflag==1) {
				cstripe = ("learner" \ "h" \ "resample")
			}
			else if (d.model=="interactive") {
				cstripe = ("learner" \ "D=0/1" \ "resample")
			}
			else {
				cstripe = ("learner" \ "Z=0/1" \ "resample")
			}
			for (ff=1;ff<=d.kfolds;ff++) {
				cstripe = cstripe \ ("fold_"+strofreal(ff))
			}
			cstripe = (J(rows(cstripe),1,""), cstripe)
			rstripe = (J(rows(rstripe),1,""), rstripe)
			rn = rname + kabbrev
			st_matrix("r("+rn+")",rmat_all)
			st_matrixcolstripe("r("+rn+")",cstripe)
			st_matrixrowstripe("r("+rn+")",rstripe)
			rmatlist = (rmatlist, rn)
			if (detailflag) {
				printf("\n{res}pystacked "+kstrings+" for %s (%s)\n",rname,vname)
				stata("mat list " + "r("+rn+"), noheader noblank")
			}

			// learner means across resamples
			if ((eqn.ateflag==0) & (eqn.lieflag==0)) {

				// one mean per learner
				rmean_all = J(rows(base_est),2,.)
				for (ll=1;ll<=rows(base_est);ll++) {
					rmean_all[ll,1] = ll
					rlearner = select(rmat_all,rmat_all[.,1]:==ll)
					rmean_all[ll,2] = mean(mean(rlearner[.,(3,cols(rlearner))]')')
				}
				cstripe = (("" , "learner") \ ("" , ("mean_"+kstring)))
				rstripe = (J(rows(base_est),1,""), base_est)
				rn = rname+kabbrev+"_mn"
				st_matrix("r("+rn+")",rmean_all)
				st_matrixcolstripe("r("+rn+")",cstripe)
				st_matrixrowstripe("r("+rn+")",rstripe)
				printf("\n{res}mean pystacked "+kstrings+" across folds/resamples for %s (%s)\n",rname,vname)
				stata("mat list " + "r("+rn+"), noheader noblank")
			}
			else {
				// two means per learner (ATE, LATE, LIE)
				rmean_all = J(2*rows(base_est),3,.)
				rstripe = J(0,2,"")
				for (ll=1;ll<=rows(base_est);ll++) {
					rmean_all[2*ll-1,1]		= ll
					rmean_all[2*ll,1]		= ll
					rmean_all[2*ll-1,2]		= 0
					rmean_all[2*ll,2]		= 1
					rlearner = select(rmat_all,rmat_all[.,1]:==ll)
					rlearner_0 = select(rlearner,rlearner[.,2]:==0)
					rlearner_1 = select(rlearner,rlearner[.,2]:==1)
					rmean_all[2*ll-1,3]		= mean(mean(rlearner_0[.,(4,cols(rlearner_0))]')')
					rmean_all[2*ll,3]		= mean(mean(rlearner_1[.,(4,cols(rlearner_1))]')')
					rstripe = rstripe \ ("",base_est[ll]) \ ("",base_est[ll])
				}
				if (eqn.lieflag==1) {
					cstripe = (("" , "learner") \ ("" , "h=0/1") \ ("" , ("mean_"+kstring)))
				}
				else if (d.model=="interactive") {
					cstripe = (("" , "learner") \ ("" , "D=0/1") \ ("" , ("mean_"+kstring)))
				}
				else {
					cstripe = (("" , "learner") \ ("" , "H=0/1") \ ("" , ("mean_"+kstring)))
				}
				rn = rname+kabbrev+"_mn"
				st_matrix("r("+rn+")",rmean_all)
				st_matrixcolstripe("r("+rn+")",cstripe)
				st_matrixrowstripe("r("+rn+")",rstripe)
				printf("\n{res}mean pystacked " + kstrings + " across folds/resamples for %s (%s)\n",rname,vname)
				stata("mat list " + "r("+rn+"), noheader noblank")
			}
			
			// learner list
			cstripe = ("" , "learner")
			rstripe = (J(rows(base_est),1,""), base_est)
			rn = rname+"_learners"
			st_matrix("r("+rn+")",(1::rows(base_est)))
			st_matrixcolstripe("r("+rn+")",cstripe)
			st_matrixrowstripe("r("+rn+")",rstripe)
			rmatlist = (rmatlist, rn)
			// rmat_ll will have weights separately for each learner
			for (ll=1;ll<=rows(base_est);ll++) {
				
				svec = rmat_all[.,1] :== ll
				rmat_ll = select(rmat_all,svec)
				rmat_ll = rmat_ll[.,(2::cols(rmat_ll))]
				if ((eqn.ateflag==0) & (eqn.lieflag==0)) {
					cstripe = ("resample")
				}
				else if (eqn.lieflag==1) {
					cstripe = ("h=0/1" \ "resample")
				}
				else if (d.model=="interactive") {
					cstripe = ("D=0/1" \ "resample")
				}
				else {
					cstripe = ("Z=0/1" \ "resample")
				}
				for (ff=1;ff<=d.kfolds;ff++) {
					cstripe = cstripe \ ("fold_"+strofreal(ff))
					}
				cstripe = (J(rows(cstripe),1,""), cstripe)
				rn = rname+"_L"+strofreal(ll)+kabbrev
				st_matrix("r("+rn+")",rmat_ll)
				st_matrixcolstripe("r("+rn+")",cstripe)
				rmatlist = (rmatlist, rn)
			}
		}
	}
	return(rmatlist)
}

void display_mse(												///
									struct mStruct d,			///
									string scalar show,			///
									string matrix reqn,			///
									string matrix rvtilde,		///
									real matrix DZeq01,			///
									real matrix rsmp,			///
									real matrix rmatmse,		///
									real matrix rmatmse_folds	///
									)
{
	
	if ((rows(DZeq01)>0) & (d.model=="interactive")) {
		// interactive
		DZeq01text = "D="
	}		
	else if (rows(DZeq01)>0) {
		// LATE
		DZeq01text = "Z="
	}
	else {
		// all others
		DZeq01text = ""
	}
	
	if (show=="MSE") {
		fmt = "{res}%10.3f  "
		printf("\n{txt}MSEs for %s:\n",reqn[1])
	}
	else {
		fmt = "{res}%10.0f  "
		printf("\n{txt}Sample sizes for %s:\n",reqn[1])
	}


	printf("{txt}{space 16}")
	if (DZeq01text~="") {
		printf("{txt}%2s ", DZeq01text)
	}
	printf("{txt}%4s ","rep")
	printf("{txt}%10s ","full smp")
	for (j=1; j<=cols(rmatmse_folds);j++) {
		printf("{txt} %10s ", "fold "+strofreal(j))
	}
	printf("\n")
	for (i=1;i<=rows(rvtilde);i++) {
		printf("{txt}%16s", rvtilde[i])
		if (DZeq01text~="") {
			printf("{res}%2.0f ", DZeq01[i])
		}
		printf("{res}%4.0f ", rsmp[i])
		printf(fmt, rmatmse[i])
		for (j=1; j<=cols(rmatmse_folds);j++) {
			printf(fmt, rmatmse_folds[i,j])
		}
		printf("\n")
	}
}

void display_pystacked_weights(									///
									struct mStruct d,			///
									string scalar vname,		///
									string scalar rname,		///
									real matrix rmat,			///
									string matrix base_est,		///
									string scalar DZeq01		///
									)
{

	struct eStruct scalar eqn
	class AssociativeArray scalar AA
	
	// assemble message
	if (d.model=="interactive") {
		if (d.nameY==vname) {
			condit = "X,D="+DZeq01
		}
		else {
			condit = "X"
		}
	}
	else if (d.model=="late") {
		if ((d.nameY==vname) | (d.nameZ==vname)) {
			condit = "X"
		}
		else {
			condit = "X,Z="+DZeq01
		}
	}
	else if (d.model=="fiv") {
		condit = "X,Z"
	}
	else {
		condit = "X"
	}
	
	printf("\n{txt}pystacked weights for E[%s|%s] = %s, resample %s:\n",	///
		vname,																///
		condit,																///
		substr(rname,1,strrpos(rname,"_")-1),								///
		substr(rname,strrpos(rname,"_")+1))
	printf("{txt}%12s","fold:")
	for (j=1;j<=cols(rmat);j++) {
		printf("{txt}    %-4.0f",j)
	}
	printf("\n")
	for (i=1;i<=rows(rmat);i++) {
		printf("{txt}%12s",base_est[i])
		for (j=1;j<=cols(rmat);j++) {
			printf("{res}%7.3f ",rmat[i,j])
		}
		printf("\n")
	}
	
}

end
