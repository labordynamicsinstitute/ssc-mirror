*! version 1.20 Sept 16, 2020
*! version 1.00 Jan 30, 2019
*! Ben A. Dwamena: bdwamena@umich.edu

cap program drop midas_mle
program midas_mle, eclass byable(recall) sortpreserve
    version 16.1

    if _by() {
        local BY `"by `_byvars'`_byrc0':"'
    }

    if  !replay()  {

        #delimit ;
        syntax varlist(min=4  max=4)
        [if] [in] [, 
            ID(varlist) 
            INTegration(string) 
            NIP(integer 20) 
            SORTby(varlist min=1)
            LEVEL(integer 95)
            noCOEFficients
            noSUMmary
            noHEADer
            noFITstats 
            HETstats
            HSROC 
            REVman  *];
        #delimit cr

        qui {
            preserve
            marksample touse
            if _by()  {
                qui replace `touse' = 0  if  `_byindex' != _byindex()
            }
            global touse= `touse'
            nois di ""
            nois di in white "........................................................................."
            nois di ""
            nois di in white "........................................................................." 
            nois di ""
            nois di in white "........................................................................."
            nois di ""

            qui {
                global alph = (100-`level')/200
                if "`id'" != "" {
                    egen __midas_studylabel = concat(`id'), p(" ")
                }
                else {
                    tempvar id
                    gen `id'=string(_n)
                    egen __midas_studylabel = concat(`id'), p(" ")
                }
                // Link functions
                // logit is the default link if none has been specified.
                if wordcount("`link'") > 1 {
                    opts_exclusive  "logit probit cloglog"
                }

                local model "Bivariate Generalized Linear Mixed Modeling"
               
                local link "logit"
                

                if wordcount("`integration'")   > 1 {
                    opts_exclusive "pcaghermite mcaghermite mvaghermite"
                }

                if `level' < 10 | `level' > 99 {
                    di as error "level() must be between 10 and 99"
                    exit 198
                }

                if ~missing("`sortby'") {
                    gsort  `sortby'
                    local sortby "`sortby'"
                }

                if "`integration'"=="" {
                    local integration mvaghermite
                }

                tokenize `varlist'
                local tp `1'
                local fp `2'
                local fn  `3'
                local tn `4'

                tempname varlist
                sort __midas_studylabel
                mkmat `1' `2' `3' `4', mat(`varlist')  rownames(__midas_studylabel)
                count if `touse'
                global midas_nobs = r(N)
                ereturn scalar nstudies = $midas_nobs
            }

            tempvar sum sumtp sumfn sumtn sumfp prev
            egen `sumtp' = total(`tp')  if `touse'
            egen `sumfn' = total(`fn')  if `touse'
            egen `sumtn' = total(`tn')  if `touse'
            egen `sumfp' = total(`fp')   if `touse'
            local sumtpfn = `sumtp' + `sumfn'
            local sumtnfp = `sumtn' + `sumfp' 
            gen `prev'=(`tp' + `fn')/(`tp' + `tn' + `fn' + `fp')   if `touse'
            sum `prev'
            local prev=r(mean)
            local prevmin= r(min)
            local prevmax=r(max)

            /*  MODEL SPECIFICATION AND ESTIMATION   */
            tempvar parameter _num invnum dtruth _mu _study last disgroup obsprob
            tempvar studdy obsprob invn eta varpro pred
            tempname avgnum modest clogits X groups XT Z ZZ A fish varp varb
            tempname VV V G B Sigma invV weight linpred pred

            gen long __midas_dep1 = int(`tp')      if `touse'               
            gen long __midas_dep2 = int(`tn')    if `touse'                 
            gen long __midas_denom1 =  int(`tp'+`fn')    if `touse'                       
            gen long __midas_denom2 =  int(`tn'+`fp')    if `touse'
            gen __midas_studyid=_n    if `touse'
            gen `invnum'1 = 1/__midas_denom1 
            sum `invnum'1, meanonly
            nois global  avnum1 = r(mean)
            gen `invnum'2 = 1/__midas_denom2 
            sum `invnum'2, meanonly
            nois global avnum2 = r(mean)       
            sort __midas_studyid     
            qui reshape long __midas_denom __midas_dep, i(__midas_studyid) j(__midas_dtruth)
            qui tabulate __midas_dtruth, generate(__midas_mu)
            gen `obsprob' = __midas_dep/__midas_denom

            * ---- Portable CSV: use tempfile + global instead of hard-coded path ----
            tempfile midas_input
            outsheet * using `midas_input', replace comma
            global midas_input "`midas_input'"

            bysort __midas_studyid:  gen `last' = _n==_N

            meglm (__midas_dep __midas_mu1 __midas_mu2, noconstant) ///
                (__midas_studyid: __midas_mu1 __midas_mu2, noconstant ///
                cov(unstructured)), ///
                family(binomial __midas_denom) link(`link') ///
                intmethod(`integration') intpoints(`nip') nogroup nolrt

            estimates store  __midas_modest
            mat `VV' = e(V)
            local covlogits = `VV'[1,2]
            local ll = e(ll)
            local k = e(k)
            local k_f= e(k_f)
            local k_r= e(k_r)
            local npoints=e(n_quad)
            local N = e(N)
            local dev = -2 * `ll'
            local AIC =  -2 * `ll' + 2*`k'
            local BIC= -2 * `ll' + `k'  * log(`N')

            tempname  Vsum bsum Vhsroc bhsroc  VVV groups
            tempname Vblogit VIsquared bIsquared Vhess  bbb
            tempname ebpred residuals reffects  scores studywgts

            //scores
            tempvar g last
            predict `g'*, scores
            bysort __midas_studyid:  gen `last' = _n ==_N
            mkmat __midas_studyid `g'*  if `last' != 1, mat(`scores')  rownames(__midas_studylabel)
            mat colnames `scores' = studdy g1 g2 g3 g4 g5 g6

            // post-estimation predictions
            mle_pred
            mat `ebpred' = r(ebpred)

            // random effects
            mle_reffects
            mat `reffects' = r(reffects)

            // residuals
            mle_residuals
            mat `residuals' = r(residuals)

            mle_groups
            mat `groups'= r(groups)

            //generate matrices
            mle_mats
            mat `VVV' = r(VVV)
            mat `bbb' = r(bbb)

            mat `Vsum' = r(Vsum)
            mat `bsum' = r(bsum)

            mat `Vhsroc' = r(Vhsroc)
            mat `bhsroc' = r(bhsroc)

            mat `VIsquared' = r(VIsquared)
            mat `bIsquared' = r(bIsquared)

            mat `Vhess' = r(Vhess)

            mat  `Vblogit' =  r(Vblogit)

            local corrlogits = r(corrlogits)
            local covlogits  = r(covlogits)

            //generating matrix of studyweights
            estimates restore  __midas_modest
            mle_weights
            mat `studywgts' = r(studywgts)

            restore
            tempvar tousecopy
            gen `tousecopy'=$touse

            ereturn post `bbb' `VVV'
            ereturn repost,  esample(`tousecopy')

            foreach i in  varlist groups Vsum bsum Vhsroc bhsroc Vblogit VIsquared bIsquared Vhess ///
                ebpred residuals scores reffects studywgts {
                ereturn matrix `i'= ``i'', copy
            }

            ereturn scalar N        = $midas_nobs
            ereturn scalar Ndis     =`sumtpfn'
            ereturn scalar Nnodis   =`sumtnfp'
            ereturn scalar ll       =`ll'
            ereturn  scalar dev     = `dev'
            ereturn  scalar AIC     =`AIC'
            ereturn scalar BIC      =`BIC'
            ereturn scalar k        = 5
            ereturn scalar kf       = 2
            ereturn scalar kr       = 3
            ereturn scalar prev     = `prev'
            ereturn scalar prevmin  = `prevmin'
            ereturn scalar prevmax  = `prevmax'
            ereturn scalar corrlogits = `corrlogits'
            ereturn scalar covlogits  = `covlogits'

            if ~missing("`sortby'") {
                eret local sortby `sortby'
            }

            if "`integration'"=="" |"`integration'" == "mvaghermite" {
                ereturn local estmethod  "Mean-Variance Adaptive Gauss–Hermite Quadrature"
            }
            else if "`integration'" == "pcaghermite" {
                ereturn local estmethod  "Pinheiro–Chao Mode-Curvature Adaptive Gauss–Hermite Quadrature"
            }
            else if "`integration'" == "mcaghermite" {
                ereturn local estmethod  "Mode-Curvature Adaptive Gauss–Hermite Quadrature"
            }

            ereturn local title "Bivariate Meta-analysis of Binary Diagnostic Test Accuracy Data"
            eret local  n_quad "`nip'"
            ereturn local fam "Binomial"
            ereturn local link `link'

            ereturn local cmdline "midas mle `0'"
            ereturn local cmd "midas_mle"
            ereturn local package "midas"
            cap estimates store _midas_estimates
        }
    }
    else { // replay
        if  "`e(cmd)'" != "midas_mle" error 301  // last estimates not found
        if _by() error 190
        #delimit;
        syntax [if] [in] [, Level(cilevel)   
            noCOEFficients
            noSUMmary
            noHEADer
            noFITstats 
            HETstats
            HSROC 
            REVman
            DIAGplot
            EBayes(string)
            *];
        #delimit cr
    }

    if missing("`header'") {
        nois di ""
        nois di ""
        nois di in smcl as text "{hline 76}"
        nois di ""
        nois di as txt _n e(title) _n
        nois di as txt _n "Using "   e(estmethod) _n
        nois di in smcl as text "{hline 76}"
        nois di ""
        nois di ""
        nois di as txt "Number of studies" _col(60) "= " _col(64) as res %5.0f e(N)
        nois di ""
        nois di as txt "Reference-positive Units" _col(60) "= " _col(64) as result %5.0f e(Ndis)
        nois di ""
        nois di as txt "Reference-negative Units" _col(60) "= " _col(64) as result %5.0f e(Nnodis)
        nois di ""
        nois di as txt "Pretest Prob of Disease" _col(60) "= " _col(64) as result %5.2f e(prev)
    }
    nois di ""
    nois di ""
    if missing("`fitstats'") {
        nois di as txt "Integration points" _col(60) "= " _col(64) as res %5.0g e(n_quad)
        nois di ""
        nois  di as txt "Deviance" _col(60) "= " _col(64) as res %5.3f  e(dev)
        nois  di " "
        nois  di as txt "Akaike Information Criterion" _col(60) "= " _col(64) as res  %5.3f  e(AIC)
        nois  di " "
        nois  di as txt "Bayesian Information Criterion" _col(60) "= " _col(64) as res  %5.3f    e(BIC)
        nois  di " "
        nois  di as txt "Log-likelihood " _col(60) "= " _col(64) as res  %5.3f   e(ll)
        nois di ""
    }
    nois di ""
    nois di ""
    if  missing("`coefficients'") {
        nois di  in smcl in gr  _newline(1)  "{hilite: Fixed and Random Effects Estimates:}"
        tempname b V bsum Vsum
        mat `b' = e(b)
        mat `V' = e(V)
        nois _coef_table , bmatrix(`b')  vmatrix(`V') cformat(%5.4f) pformat(%5.4f) sformat(%8.4f)
    }
    nois di ""
    nois di ""
    nois di ""
    if  missing("`summary'") {
        nois di in smcl in gr  _newline(1)   "{hilite: Summary Test Performance Estimates:}"
        mat `bsum' = e(bsum)
        mat `Vsum' = e(Vsum)
        nois _coef_table , bmatrix(`bsum')  vmatrix(`Vsum') cformat(%5.4f) pformat(%5.4f) sformat(%8.4f)
        nois di ""
    }
    if !missing("`hetstats'") {
        nois di in smcl in gr  _newline(1) "{hilite: Heterogeneity/Inconsistency Statistics:}"
        tempname bIsquared VIsquared
        mat `bIsquared' = e(bIsquared)
        mat `VIsquared' = e(VIsquared)
        nois _coef_table , bmatrix(`bIsquared')  vmatrix(`VIsquared') cformat(%5.4f) pformat(%5.4f) sformat(%8.4f)
        nois di ""
    }

    if !missing("`hsroc'") {
        nois di in smcl in gr  _newline(1) "{hilite: Derived HSROC Model Estimates:}"
        tempname bhsroc Vhsroc
        mat `bhsroc' = e(bhsroc)
        mat `Vhsroc' = e(Vhsroc)
        nois _coef_table , bmatrix(`bhsroc')  vmatrix(`Vhsroc') cformat(%5.4f) pformat(%5.4f) sformat(%8.4f)
        nois di ""
    }

    if !missing("`revman'") {
        tempname brev Vrev crev
        mat `brev' = e(b)
        mat `Vrev' = e(V)
        local cov01 = `Vrev'[1,2]
        qui _coef_table , bmatrix(`brev')  vmatrix(`Vrev')
        mat `crev' = r(table)'
        local  sp = `crev'[2,1]
        local  spse = `crev'[2,2]
        local  sn = `crev'[1,1]
        local  snse = `crev'[1,2]
        local reffs1= `crev'[3,1]
        local reffs2= `crev'[4,1]

        nois di in smcl as text "{hline 76}"
        nois di  in smcl in gr  _newline(1)  "{hilite: Parameters Estimates for Export into RevMan}"
        nois di ""
        nois di ""
        nois di  in smcl in blue  "{title: Parameters for SROC Curve}"
        nois di ""
        nois di as text "{hilite:E(logitse)}" as text ": Expected mean logit sensitivity" _col(66) " =   " _col(70) as res %5.4f `sn'
        nois di ""
        nois di as text "{hilite:E(logitsp)}" as text ": Expected mean logit specificity" _col(66) " =   " _col(70) as res %5.4f `sp'
        nois di ""
        nois di as text  "{hilite:Var(logitse)}" as text ": Between-study variance of logit sensitivity" _col(66) " =   " _col(70) as res %5.4f `reffs1'
        nois di ""
        nois di as text  "{hilite:Var(logitsp)}" as text ": Between-study variance of logit specificity" _col(66) " =   " _col(70) as res %5.4f `reffs2'
        nois di ""
        nois di as text  "{hilite:Cov(logits)}" as text ": Between-study Covariance" _col(66) " =   " _col(70) as res %5.4f e(covlogits)
        nois di ""
        nois di as text  "{hilite:Corr(logits)}" as text": Between-study Correlation" _col(66) " =  " _col(70) as res %5.4f e(corrlogits)
        nois di ""
        nois di ""
        nois di ""
        nois di  in smcl in blue "{title: Parameters for Confidence and Prediction Regions:}"
        nois di ""
        nois di as text "{hilite:SE(E(logitse))}" as text ": Standard error of expected mean logit sensitivity" _col(66) " =   " _col(70) as res %5.4f `snse'
        nois di ""
        nois di as text  "{hilite:SE(E(logitsp))}" as text ": Standard error of expected mean logit specificity" _col(66) " =   " _col(70) as res %5.4f `spse'
        nois di ""
        nois di  as text "{hilite:Cov(Es)}" as text ": Covariance between mean logit sensitivity and specificity" _col(66) " =  " _col(70) as res %5.4f `cov01'
        nois di ""
        nois di as text  "{hilite:Studies}" as text ": Number of Studies included in meta-analysis" _col(66) " =   " _col(70) as res %2.0f e(N)
        nois di ""
    }

    nois di ""
    nois di ""

    preserve

    if "`ebayes'" != "" {
        qui {
            mat ebforest=e(varlist)
            local id: rowfullnames ebforest
            local x: word  count("`id'")
            tempvar Studddy ebs iddd
            tempname befor Vefor eforest
            qui gen `Studddy' = ""
            forvalues i =1/`x' {
                local bb: word `i' of `id'
                qui replace `Studddy' = "`bb'" in `i'
            }

            gen `iddd'=_n
            gsort  `iddd'
            gen `ebs' = strlen(`Studddy')
            sum `ebs', meanonly
            local ebs4 = int(r(max) + 40)
            format `Studddy' %-`ebs4's
            mat `befor' = e(bsum)
            mat `Vefor' = e(Vsum)
            _coef_table, bmatrix(`befor') vmatrix(`Vefor')
            mat `eforest' = r(table)'
            local mvar1 = `eforest'[1,1]   
            local mvar2 = `eforest'[2,1]

            /* STUDY-SPECIFIC Sensitivity (True Positive Rate)*/
            tempvar sens senslo senshi sensse spec speclo spechi specse FPR         
            version 9: gen `sens' = tp/(tp+fn) 
            version 9: gen `senslo' = invbinomial(tp+fn,tp,$alph)   
            version 9: gen `senshi' = invbinomial(tp+fn,tp,1-$alph)
            version 9: gen `sensse' = (`senshi'-`senslo')/(2*invnormal(1-$alph))

            /* STUDY-SPECIFIC Specificity (True Negative Rate) */
            version 9: gen `spec' = tn/(tn+fp)       
            version 9: gen `speclo' = invbinomial(tn+fp,tn,$alph) 
            version 9: gen `spechi' = invbinomial(tn+fp,tn,1-$alph)
            version 9: gen `specse' =(`spechi'-`speclo')/(2*invnormal(1-$alph))

            tempvar ebsens ebsenslo ebsenshi ebsensse ebspec ebspeclo ebspechi ebspecse
            tempvar randeffs1 randeffs2 serandeffs1 serandeffs2
            tempname reffects coeffs1 coeffs2 
            mat `reffects' = e(reffects)
            local eid: rownames `reffects'
            local x: word  count("`eid'")
            gen `randeffs1' = .
            gen `randeffs2' = .
            gen `serandeffs1' = .
            gen `serandeffs2' = .
            forvalues i =1/`x' {
                replace `randeffs1' = `reffects'[`i',1] in `i'
                replace `randeffs2' = `reffects'[`i',2] in `i'
                replace `serandeffs1' = `reffects'[`i',3] in `i'
                replace `serandeffs2' = `reffects'[`i',4] in `i'
            }
            mat bvars = e(Vblogit)
            mat coeffs = e(b)
            scalar `coeffs1' = coeffs[1,1]
            scalar `coeffs2' = coeffs[1,2]
            gen `ebsens' = invlogit(`randeffs1' + `coeffs1')
            gen `ebsenslo' = invlogit(`randeffs1'  + `coeffs1' - 1.96*`serandeffs1')
            gen `ebsenshi' = invlogit(`randeffs1'  + `coeffs1' + 1.96*`serandeffs1')
            gen `ebsensse' = (`ebsenshi'-`ebsens')/invnormal(0.975)
            gen `ebspec' = invlogit(`randeffs2' + `coeffs2')
            gen `ebspechi' = invlogit(`randeffs2'  + `coeffs2' + 1.96*`serandeffs2')
            gen `ebspeclo' = invlogit(`randeffs2'  + `coeffs2' - 1.96*`serandeffs2')
            gen `ebspecse'=(`ebspechi'-`ebspec')/invnormal(0.975)
            format `ebsens' `ebsenslo' `ebsenshi' `ebspec' `ebspeclo' `ebspechi' %9.2f
            format `sens' `senslo' `senshi' `spec' `speclo' `spechi' %9.2f

            tempvar obs obs1 wgt1 wgt2
            gen `obs' = _n
            gen `obs1' = _n + 0.30
            count
            local max1 = r(N)
            local maxx = `max' + 2
            label value `obs' obs
            label value `obs1' obs1

            forval i = 1/`max1'{
                local value = `"`value' `i'"'
                local value1 = `"`value' `i'"'
                label define obs `i' "`=`Studddy'[`i']'", modify
            }

            local ylabopt "labsize(*`textscale') tl(*0) labgap(*0)  labc(bg) tlc(none) "
            local xlab1 "xlab(0(.5)1.0, format(%2.1f) labsize(*`textscale') labc(bg) tlc(none))"

            if "`ebayes'"=="for" {

                gen `wgt1' = 1/(`ebsensse' * `ebsensse')
                #delimit ;
                twoway (rspike `ebsenslo' `ebsenshi' `obs', ylabel(`"`value'"', valuelabel labsize(*.75) tl(*0) angle(360))
                    hor s(i) lpat(blank)  `xlab1')(scatter `obs1' `sens', ms(i) msize(`mscale2') mcolor(gs10))
                    (scatter `obs' `ebsens', ms(i) msize(`mscale2') mcolor(gs10))
                    (rspike `senslo' `senshi' `obs1', ylabel(`"`value'"', valuelabel labsize(*.75) tl(*0) angle(360))
                    hor s(i) lpat(blank)  `xlab1'), legend(off) xtitle("", size(*.5)) yscale(noline) xscale(off fill)
                    plotregion(style(none)) nodraw ytitle("", size(*.5)) ysca(rev) title("", size(*.5) pos(1) justification(right)) fxsize(10) name(mplot, replace);
                #delimit cr

                #delimit ;
                twoway (rspike `ebsenslo' `ebsenshi' `obs', ylabel(`"`value'"', nolabel
                    `ylabopt' angle(360)) hor s(i) blpattern(solid) blwidth(thin) blcolor(black) `xlab1')
                    (rspike `senslo' `senshi' `obs1', ylabel(`"`value1'"', nolabel
                    `ylabopt' angle(360)) hor s(i) blpattern(dash) blwidth(thin) blcolor(black) `xlab1')
                    (scatter `obs' `ebsens', ms(o) mcolor(black))
                    (scatter `obs1' `sens', ms(oh) mcolor(black)), ytitle("", size(*.5))
                    legend(off) xtitle("Sensitivity", size(*.75)) title("", size(*.5)
                    justification(left)) ysca(rev) nodraw name(mplot1, replace) xline(`mvar1') ;
                #delimit cr

                gen `wgt2' = 1/(`ebspecse'*`ebspecse')

                #delimit ;
                twoway (rspike `ebspeclo' `ebspechi' `obs', ylabel(`"`value'"', nolabel
                    `ylabopt' angle(360)) hor s(i) blpattern(solid) blwidth(thin) blcolor(black) `xlab1')
                    (rspike `speclo' `spechi' `obs1', ylabel(`"`value1'"', nolabel
                    `ylabopt' angle(360)) hor s(i) blpattern(dash) blwidth(thin) blcolor(black) `xlab1')
                    (scatter `obs' `ebspec', ms(o) mcolor(black))
                    (scatter `obs1' `spec', ms(oh) mcolor(black)), legend(off)
                    xtitle("Specificity", size(*.75)) ytitle("", size(*.5))  title("", size(*.5)
                    justification(left)) ysca(rev) nodraw  name(mplot2, replace) xline(`mvar2');
                #delimit cr
                #delimit ;
                nois graph combine mplot mplot1 mplot2,  row(1) ysize(6) xsize(4)
                    note("MLE of mean sensitivity and specificity (solid vertical lines)"
                    "Predicted data (solid horizontal lines and solid markers)"
                    "Observed data (dashed horizontal lines and open markers)",
                    position(12) justification(center) size(*.75)) `options';                           
                #delimit cr
            }
            else if "`ebayes'"=="roc" {
                #delimit;
                nois twoway (pci 0 1 1 0, clpat(solid) clc(black))
                    (pcspike `sens' `spec' `ebsens' `ebspec', lwidth(vvthin) lpatt(solid) lcol(black*5))
                    (scatter `sens' `spec', mlab(`studddy') mlabsize(*.5)
                    mlabpos(0) mcolor(gray) mlabc(black*2) msym(O) sort)
                    (scatter `ebsens' `ebspec', mlabel(`studddy') mlabpos(0) mlabsize(*.5)
                    mlabc(black*2) mcolor(black) msym(Sh) sort)
                    , legend(order(3 "Observed Data" 4 "EBayes" 1 "Null Line") size(*.75)
                    symxsize(2) pos(5) ring(0) col(1))
                    xsc(range(0(0.2)1)) ysc(range(0 1))  xla(0(.2)1, nogrid format(%7.1f))
                    yla(0(.2)1, nogrid angle(horizontal) format(%7.1f)) 
                    plotregion(margin(zero)) xsc(rev) xti(Specificity)
                    yti(Sensitivity);                           
                #delimit cr
            }
        }
    }

    if "`diagplot'"  != "" {
        qui {
            tempname reffects scores residuals H invH scorei ci
            tempvar cooksd

            mat `reffects' = e(reffects)
            mat `scores'= e(scores)
            mat `residuals'= e(residuals)
            matrix `H' = e(V)

            tempname groups_m bvars_m
            mat `groups_m' = e(groups)
            mat `bvars_m' = e(Vblogit)

            local k = colsof(`H')

            * Save current data and build diagnostic dataset
            tempfile _origdata
            capture save `_origdata', replace
            
            local nr = rowsof(`reffects')
            local ns = rowsof(`scores')
            local nd = rowsof(`residuals')
            local ng = rowsof(`groups_m')
            local nmax = max(`nr', `ns', `nd', `ng')
            drop _all
            set obs `nmax'

            svmat `reffects', names(col)
            svmat `scores', names(col)
            svmat `residuals', names(col)

            capture confirm variable studdy
            if _rc {
                gen studdy = _n
            }

            local N = `nr'

            gen `cooksd' = .
            local i = 1
            while `i'<=`N'{
                mkmat g1-g`k' if _n==`i', matrix(`scorei')
                matrix `ci' = 2*`scorei'*`H'*`scorei''
                replace `cooksd' = `ci'[1,1] in `i'
                local i = `i' + 1
            }
            format `cooksd' %5.2f
            count if `cooksd' !=.
            local xmax=r(N)
            local n = 4*e(k)/r(N)

            tw (spike `cooksd' studdy)(scatter `cooksd' studdy if `cooksd' !=. & `cooksd' > `n' & studdy !=., ///
                mlw(medthin) mfc(yellow) mlc(black) msize(*1.5) ms(O)) ///
                (scatter `cooksd' studdy if `cooksd' !=. & `cooksd' > `n' & studdy !=., ///
                ms(i) mlabp(0) mlabel(studdy) mlabs(*.5) mlabc(black)) , ///
                legend(off) yline(`n', lpat(dash) lw(thin)) ylab(, angle(hor) nogrid) xlab(, nogrid) ///
                name(cooksd, replace) ytitle("Cook's Distance", size(*.75)) ///
                xtitle("Study", size(*.75)) nodraw title("Influence Analysis", size(*.75))

            ******Residual-based Goodness-of-fit Assessment**********
            * e(residuals) is interleaved: odd rows=dresid1, even rows=dresid2
            * Pair them: for each row with dresid1 non-missing, grab dresid2 from next row
            gen _dr1 = dresid1 if dresid1 < .
            gen _dr2 = dresid2[_n+1] if dresid1 < .
            gen _dresid = sign(_dr1) * sqrt(_dr1^2 + _dr2^2) if _dr1 < . & _dr2 < .
            * Count non-missing paired residuals
            count if _dresid < .
            local ndresid = r(N)
            * Compute mean and sd
            sum _dresid if _dresid < .
            local dmean = r(mean)
            local dsd = r(sd)
            * Rank the residuals for P-P plot (without sorting the dataset)
            egen _rank = rank(_dresid) if _dresid < .
            gen _pexp = (_rank - 0.5) / `ndresid' if _dresid < .
            gen _pobs = normal((_dresid - `dmean') / `dsd') if _dresid < .
            tw (function y=x, range(0 1) lc(gs12) lp(dash) lw(thin)) ///
                (scatter _pobs _pexp if _dresid < ., ms(O) msize(*1.5) mc(navy) mlw(medthin)), ///
                legend(off) name(pdresid, replace) ///
                title("Goodness-Of-Fit", size(*.75)) ///
                xtitle("Expected Normal", size(*.75)) ///
                ytitle("Observed", size(*.75)) ///
                ylab(0(0.2)1, angle(hor) format(%7.2f)) ///
                xlab(0(0.2)1) nodraw
            drop _dr1 _dr2 _dresid _rank _pexp _pobs

            ******Bivariate Normality using Mahalanobis Squared Distances**********
            mkmat randeff* if randeff1 < ., matrix(xvar)
            matrix accum cov = randeff* if randeff1 < ., noc dev
            matrix cov = cov/(r(N)-1)
            matrix mahascorex= (xvar) * (inv(cov)) * (xvar')
            matrix mahascore= (vecdiag(mahascorex))'
            svmat mahascore, names(mahascore)
            sort mahascore1
            gen _chiexp = invchi2(2, (_n - 0.5) / `nr') if mahascore1 < .
            gen _chiobs = mahascore1 if mahascore1 < .
            tw (scatter _chiobs _chiexp if mahascore1 < ., ms(O) msize(*0.8) mc(navy)) ///
                (function y=x, range(_chiexp) n(2) lc(gs8) lp(dash)), ///
                legend(off) nodraw name(bivar, replace) ///
                ylab(, angle(hor)) title("Bivariate Normality", size(*.75)) ///
                xtitle("Chi-squared Quantile", size(*.75)) ///
                ytitle("Mahalanobis Score", size(*.75))

            *****Outlier Detection using standardized residuals**********
            tempvar stdres1 stdres2
            local bvars1 = `bvars_m'[1,1]
            local bvars2 = `bvars_m'[2,2]
            svmat `groups_m', names(col)
            gen `stdres1' = (1-disgroup1)*randeff1/ sqrt(`bvars1' - serandeff1^2)
            gen `stdres2' = disgroup2*randeff2/ sqrt(`bvars2' - serandeff2^2)
            tw (scatter `stdres2' `stdres1', mlw(medthin) mlc(black) mfc(gs15) msize(*1.5) ms(O)) ///
                (scatter `stdres2' `stdres1' if (`stdres2' < -2 | `stdres2' > 2)|(`stdres1' < -2 | `stdres1' > 2), mlw(medthin) mlc(black) mfc(yellow) msize(*1.5) ms(O)) ///
                (scatter `stdres2' `stdres1', ms(i) mlabp(0) mlabel(studdy) mlabs(*.5) mlabc(black)), ylab(-3(1)3, angle(hor) format(%7.1f) nogrid) ///
                xlab(-3(1)3, format(%7.1f) nogrid) xline(-2 0 2, lw(thin) lpat(dash)) yline(-2 0 2, lpat(dash) lw(thin) ) legend(off) ///
                name(outlier, replace) ytitle("Standardized_Residual_2", size(*.75)) xtitle("Standardized_Residual_1", size(*.75)) ///
                title("Outlier Detection", size(*.75)) nodraw

            nois graph combine pdresid outlier cooksd  bivar, rows(2)  `title'  `options'
        }
        * Restore original data
        capture use `_origdata', clear
    }


end


cap program drop mle_weights
program define mle_weights, rclass
    cap preserve
    cap estimates restore __midas_modest
    import delimited "$midas_input", clear

    tempvar parameter _num invnum dtruth _mu _study last disgroup
    tempvar studdy obsprob invn eta varpro pred
    tempname avgnum modest clogits X groups XT Z ZZ A fish varp varb
    tempname VV V G B Sigma invV weight linpred pred

    generate `disgroup' = __midas_dtruth
    gen `disgroup'1 = __midas_mu1
    gen `disgroup'2 = __midas_mu2
    gen `obsprob' = __midas_dep/__midas_denom
    gen `studdy' = __midas_studyid
    bysort `studdy':  gen `last' = _n==_N
    mkmat `disgroup'1 `disgroup'2, mat(`X')
    gen `invn'=1/__midas_denom
    mat `XT' = `X''

    //create the random effects design matrix - N studies, 2 random parameters
    mat `Z' = I(_N)
    mat `ZZ' = I(0.5*_N)

    //Create A (diagonal matrix) using variable, n (number of diseased for sensitivity and number of non-diseased for specificity) in dataset
    mkmat `invn', mat(`A')

    //create a diagonal matrix with the matrix, colA, above
    mat `A' = diag(`A')

    predict `eta', eta

    //create variance of Bernoulli distribution
    gen `varpro' = ((invlogit(`eta'))*(1-(invlogit(`eta'))))

    //Create B (diagonal matrix) based on the predicted probability,
    mkmat `varpro', mat(`B')
    mat `B' = diag(`B')

    //Creating the G matrix containing the variances of the random effects
    mat `Sigma' = (_b[/var(__midas_mu1[__midas_studyid])],_b[/cov(__midas_mu1[__midas_studyid],__midas_mu2[__midas_studyid])]  ///
        \ _b[/cov(__midas_mu1[__midas_studyid],__midas_mu2[__midas_studyid])] , _b[/var(__midas_mu2[__midas_studyid])])

    mat `G'=`ZZ'#`Sigma'

    //create variance matrix for the observations
    mat `V' = (`Z'*`G'*`Z'') + (`A'*syminv(`B'))

    //invert the variance matrix, V
    mat `invV' = invsym(`V')

    //derive Fisher's Information matrix
    mat `fish' = `XT'*`invV'*`X'

    //invert Fisher's Information matrix
    mat `varb' = invsym(`fish')

    //Loop over studies to obtain the study specific percentage weights
    forvalues i = 1/$midas_nobs {
        mat `V'`i' = `V'

        //Replace study i so that it has zero information
        mat `V'`i'[(`i'*2)-1,(`i'*2)-1] = 1000000000
        mat `V'`i'[(`i'*2)-1,`i'*2] = 0
        mat `V'`i'[`i'*2,(`i'*2)-1] = 0
        mat `V'`i'[`i'*2,`i'*2] = 1000000000

        //recalculate matrices when study i removed
        mat `invV'`i' = invsym(`V'`i')
        mat `fish'`i' = `XT'*`invV'`i'*`X'
        mat `fish'`i'_`i' = `fish' - `fish'`i'
        mat `weight'`i' = `varb'*`fish'`i'_`i'*`varb'

        //derive percentage weight for study i for sensitivity
        mat pctwgt`i'sens = 100*(`weight'`i'[1,1]/`varb'[1,1])

        //derive percentage weight for study i for specificity
        mat pctwgt`i'spec = 100*(`weight'`i'[2,2]/`varb'[2,2])
        scalar pctwgt`i'=100*(trace(`weight'`i')/trace(`varb'))
    }

    tempvar senwgt spewgt studywgt
    tempname studywgts
    keep if `last' ==1
    gen `senwgt' =.
    gen `spewgt' =.
    gen `studywgt' =.
    forvalues i = 1/$midas_nobs {
        replace `senwgt' = pctwgt`i'sens[1,1]    in `i'
        replace `spewgt' = pctwgt`i'spec[1,1]   in `i'
        replace `studywgt' = pctwgt`i'   in `i'
    }
    mkmat  `senwgt' `spewgt' `studywgt' if `last' ==1, mat(`studywgts') rownames(__midas_studylabel)
    matrix colnames `studywgts'= senwgt spewgt bivwgt
    return matrix  studywgts = `studywgts', copy
    cap estimates restore __midas_modest
    cap restore
end

cap program drop mle_groups
program define mle_groups, rclass
    capture preserve
    cap estimates restore __midas_modest
    import delimited "$midas_input", clear
    tempvar last disgroup
    tempname groups
    gen `disgroup'1 = __midas_mu1
    gen `disgroup'2 = __midas_mu2
    mkmat `disgroup'1 `disgroup'2, mat(`groups') rown(__midas_studylabel)
    matrix colnames `groups' = disgroup2 disgroup1
    ret mat groups = `groups', copy
    cap estimates restore __midas_modest
    cap restore
end

cap program drop mle_mats
program define mle_mats, rclass
    capture preserve
    cap estimates restore __midas_modest
    tempname Vblogit Vwlogit sigmasqspe sigmasqsen Isqspe Isqsen Isqbiv
    tempname bIsquared  VIsquared Sens Spec LRP LRN DOR
    tempname bsum Vsum bhsroc bbb VVV Vhsroc Alpha Theta beta s2alpha s2theta

    mat `Vblogit' =(_b[/var(__midas_mu2[__midas_studyid])] , _b[/cov(__midas_mu1[__midas_studyid],__midas_mu2[__midas_studyid])] ///
        \ _b[/cov(__midas_mu1[__midas_studyid],__midas_mu2[__midas_studyid])] , ///
        _b[/var(__midas_mu1[__midas_studyid])])
    return mat  Vblogit = `Vblogit', copy

    nlcom (`sigmasqsen': $avnum1*(exp(((_b[/var(__midas_mu1[__midas_studyid])])/2)+_b[__midas_mu1])+ ///
        exp(((_b[/var(__midas_mu1[__midas_studyid])])/2)-_b[__midas_mu1])+2)) ///
        (`sigmasqspe': $avnum2*(exp(((_b[/var(__midas_mu2[__midas_studyid])])/2)+_b[__midas_mu2])+ ///
        exp(((_b[/var(__midas_mu2[__midas_studyid])])/2)-_b[__midas_mu2])+2)),  ///
        post noheader cformat(%5.4f) pformat(%5.4f) sformat(%8.4f)

    mat `Vwlogit' = (_b[`sigmasqsen'],0 \ 0, _b[`sigmasqspe'])
    return mat  Vblogit = `Vblogit', copy
    estimates restore __midas_modest

    nlcom (`Isqsen': _b[/var(__midas_mu1[__midas_studyid])]/(_b[/var(__midas_mu1[__midas_studyid])] +  ///
        ($avnum1*(exp(((_b[/var(__midas_mu1[__midas_studyid])])/2)+_b[__midas_mu1])+ ///
        exp(((_b[/var(__midas_mu1[__midas_studyid])])/2)-_b[__midas_mu1])+2)))) ///
        (`Isqspe': _b[/var(__midas_mu2[__midas_studyid])]/(_b[/var(__midas_mu2[__midas_studyid])] + ///
        ($avnum2*(exp(((_b[/var(__midas_mu2[__midas_studyid])])/2)+  ///
        _b[__midas_mu2])+exp(((_b[/var(__midas_mu2[__midas_studyid])])/2)-_b[__midas_mu2])+2)))) ///
        (`Isqbiv' : sqrt(exp(log(det(`Vblogit'))))/(sqrt(exp(log(det(`Vblogit')))) + ///
        sqrt(($avnum1*(exp(((_b[/var(__midas_mu1[__midas_studyid])])/2)+_b[__midas_mu1])+ ///
        exp(((_b[/var(__midas_mu1[__midas_studyid])])/2)-_b[__midas_mu1])+2))* ///
        ($avnum2*(exp(((_b[/var(__midas_mu2[__midas_studyid])])/2)+_b[__midas_mu2])+ ///
        exp(((_b[/var(__midas_mu2[__midas_studyid])])/2)-_b[__midas_mu2])+2))))),  ///
        noheader cformat(%5.4f) pformat(%5.4f) sformat(%8.4f)

    mat `bIsquared' = r(b)
    mat `VIsquared' = r(V)
    local hetsnames: di "Isqsen Isqspe Isqbiv"
    mat colnames `bIsquared' = `hetsnames'
    mat colnames `VIsquared' = `hetsnames'
    mat rownames `VIsquared' = `hetsnames'
    return matrix bIsquared=`bIsquared', copy
    return matrix VIsquared=`VIsquared', copy

    nlcom (`Sens': invlogit(_b[__midas_mu1]))(`Spec': invlogit(_b[__midas_mu2])) ///
        (`DOR': _b[__midas_mu1]+_b[__midas_mu2])(`LRP': invlogit(_b[__midas_mu1])/(1-invlogit(_b[__midas_mu2]))) ///
        (`LRN': (1-invlogit(_b[__midas_mu1]))/invlogit(_b[__midas_mu2])),  ///
        noheader cformat(%5.4f) pformat(%5.4f) sformat(%8.4f)

    mat `bsum' = r(b)
    mat `Vsum' = r(V)
    local sumnames: di "Sens Spec DOR LRP LRN"
    mat colnames `bsum' = `sumnames'
    mat colnames `Vsum' = `sumnames'
    mat rownames `Vsum' = `sumnames'   
    return matrix bsum=`bsum', copy
    return matrix Vsum=`Vsum', copy

    nlcom ///
        (`Alpha': (_b[/var(__midas_mu2[__midas_studyid])] / _b[/var(__midas_mu1[__midas_studyid])])^(.25) * _b[__midas_mu1] ///
        + (_b[/var(__midas_mu1[__midas_studyid])] / _b[/var(__midas_mu2[__midas_studyid])])^(.25) * _b[__midas_mu2]) ///
        (`Theta': .5*((_b[/var(__midas_mu2[__midas_studyid])] / _b[/var(__midas_mu1[__midas_studyid])])^(.25) * _b[__midas_mu1] ///
        - (_b[/var(__midas_mu1[__midas_studyid])] / _b[/var(__midas_mu2[__midas_studyid])])^(.25) * _b[__midas_mu2])) ///
        (`beta': .5*log(_b[/var(__midas_mu2[__midas_studyid])] / _b[/var(__midas_mu1[__midas_studyid])])) ///
        (`s2alpha': 2*( sqrt(_b[/var(__midas_mu1[__midas_studyid])] * _b[/var(__midas_mu2[__midas_studyid])])+ ///
        _b[/cov(__midas_mu1[__midas_studyid],__midas_mu2[__midas_studyid])])) ///
        (`s2theta': .5*( sqrt(_b[/var(__midas_mu1[__midas_studyid])] * ///
        _b[/var(__midas_mu2[__midas_studyid])]) - _b[/cov(__midas_mu1[__midas_studyid],__midas_mu2[__midas_studyid])])) ///
        , noheader cformat(%5.4f) pformat(%5.4f) sformat(%8.4f)

    matrix `bhsroc' = r(b)
    matrix `Vhsroc' = r(V)
    local hsrocnames: di "Alpha Theta beta s2alpha s2theta"
    mat colnames `bhsroc' = `hsrocnames'
    mat colnames `Vhsroc' = `hsrocnames'
    mat rownames `Vhsroc' = `hsrocnames'
    return matrix bhsroc=`bhsroc', copy
    return matrix Vhsroc=`Vhsroc', copy
    estimates restore  __midas_modest

    tempname logitspe logitsen varlogitspe varlogitsen covlogits Vhess
    nlcom (`logitsen': _b[__midas_mu1])(`logitspe': _b[__midas_mu2]) ///
        (`varlogitsen': _b[/var(__midas_mu1[__midas_studyid])]) (`varlogitspe': _b[/var(__midas_mu2[__midas_studyid])]) ///
        (`covlogits': _b[/cov(__midas_mu1[__midas_studyid],__midas_mu2[__midas_studyid])]), ///
        cformat(%5.4f) pformat(%5.4f) sformat(%8.4f)
    nois di ""
    nois di ""
    mat `Vhess' = r(V)
    local hessnames: di "logitsen logitspe  varlogitsen varlogitspe covlogits"
    mat colnames `Vhess' = `hessnames'
    mat rownames `Vhess' = `hessnames'
    return matrix Vhess=`Vhess', copy

    tempname  logitsen logitspe varlogitsen varlogitspe covlogits corrlogits bbb VVV
    nlcom (`logitsen': _b[__midas_mu1])(`logitspe': _b[__midas_mu2]) ///
        (`varlogitsen': _b[/var(__midas_mu1[__midas_studyid])]) (`varlogitspe': _b[/var(__midas_mu2[__midas_studyid])]) ///
        (`covlogits': _b[/cov(__midas_mu1[__midas_studyid],__midas_mu2[__midas_studyid])]) ///
        (`corrlogits': _b[/cov(__midas_mu1[__midas_studyid],__midas_mu2[__midas_studyid])] / ///
        sqrt(_b[/var(__midas_mu1[__midas_studyid])] * _b[/var(__midas_mu2[__midas_studyid])])),  ///
        post noheader cformat(%5.4f) pformat(%5.4f) sformat(%8.4f)
    nois di ""
    nois di ""
    mat `bbb' = r(b)
    mat `VVV' = r(V)
    local coefnames: di "logitsen logitspe varlogitsen varlogitspe covlogits corrlogits"
    local corrlogits = `bbb'[1,6]
    local covlogits = `bbb'[1,5]
    mat colnames `bbb' = `coefnames'
    mat colnames `VVV' = `coefnames'
    mat rownames `VVV' = `coefnames'
    return matrix bbb = `bbb', copy
    return matrix VVV = `VVV', copy
    return scalar corrlogits = `corrlogits'
    return scalar covlogits = `covlogits'
    cap estimates restore __midas_modest
    cap restore
end

cap program drop mle_reffects
program define mle_reffects, rclass
    capture preserve
    cap estimates restore __midas_modest
    import delimited "$midas_input", clear
    tempvar randeff1 randeff2  serandeff1 serandeff2 last
    tempname reffects
    bysort __midas_studyid:  gen `last' = _n ==_N
    predict `randeff1' `randeff2' , reffects reses(`serandeff1'  `serandeff2')
    mkmat  `randeff1' `randeff2' `serandeff1' `serandeff2' if  `last' == 1, ///
        mat(`reffects')  rownames(__midas_studylabel)
    mat colnames `reffects' = randeff1 randeff2  serandeff1 serandeff2
    ret mat reffects = `reffects', copy
    cap estimates restore __midas_modest
    cap restore
end

cap program drop mle_residuals
program define mle_residuals, rclass
    capture preserve
    cap estimates restore __midas_modest
    tempvar residuals dresid idd
    tempname residuals
    predict `dresid', deviance
    keep __midas_dtruth __midas_studylabel `dresid'
    gen `idd' = _n
    reshape wide `dresid', i(`idd') j(__midas_dtruth)
    mkmat `dresid'1 `dresid'2, mat(`residuals') ///
        rownames(__midas_studylabel)
    mat colnames `residuals' = dresid1 dresid2
    ret mat residuals = `residuals', copy
    cap estimates restore __midas_modest
    cap restore
end

cap program drop mle_pred
program define mle_pred, rclass
    capture preserve
    cap estimates restore __midas_modest
    import delimited "$midas_input", clear
    tempvar pred residuals dresid last
    tempvar randeff1 randeff2  serandeff1 serandeff2
    tempname ebpred reffects residuals
    bysort __midas_studyid: gen `last' =_n==_N
    predict `dresid', deviance
    predict `pred'
    predict `randeff1' `randeff2' , reffects reses(`serandeff1'  `serandeff2')
    mkmat  `randeff1' `randeff2' `serandeff1' `serandeff2' if `last' == 1, ///
        mat(`reffects')  rownames(__midas_studylabel)
    mat colnames `reffects' = randeff1 randeff2  serandeff1 serandeff2
    mkmat  `dresid' if `last' == 1, ///
        mat(`residuals')  rownames(__midas_studylabel)
    mat colnames `residuals' = dresid
    replace `pred' = `pred'/__midas_denom
    keep `pred'  __midas_studyid __midas_dtruth __midas_studylabel
    reshape wide `pred' , i(__midas_studyid) j(__midas_dtruth)
    mkmat `pred'*, mat(`ebpred') rownames(__midas_studylabel)
    mat colnames `ebpred' = pred1 pred2
    ret mat reffects = `reffects', copy
    ret mat residuals = `residuals', copy
    ret mat ebpred = `ebpred', copy
    cap estimates restore __midas_modest
    cap restore
end
