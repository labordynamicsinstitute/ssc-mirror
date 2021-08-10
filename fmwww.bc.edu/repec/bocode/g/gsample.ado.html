*! version 1.0.8  25oct2020  Ben Jann

capt mata mata which mm_sample()
if _rc {
    di as error "mm_sample() from -moremata- is required; type {stata ssc install moremata}"
    error 499
}

program gsample
    version 9.2
    
    // syntax
    qui syntax [anything(name=n)] [if] [in] [iw aw] [, ///
      Generate(name)   /// store sample counts in newvar
      Percent          /// information in n is percentage
      wor              /// sample without replacement
      Strata(varlist)  /// stratified sampling
      Cluster(varlist) /// clutser sampling
      IDcluster(name)  /// add new id for resample clusters
      Keep             /// keep cases outside touse
      Replace          /// replace existing variables
      alt              /// use alternative (faster) algorithm for SRSWOR
      NOWARN           /// allow repetitions in UPSWOR
      RRound           /// random round; only relevant if strata() specified
      NOPReserve       /// do not preserve data
      ]
    if "`idcluster'"!="" & "`cluster'"=="" {
        di as err "idcluster() can only be specified with the cluster() option"
        exit 198
    }
    if "`replace'"=="" {
        if "`generate'"!=""  confirm new var `generate'
        if "`idcluster'"!="" confirm new var `idcluster'
    }
    if `"`n'"'=="" local n .
    if `"`n'"'!="." {
        capt confirm number `n'
        if _rc unab nvar: `n', max(1)
    }
    
    // sample and weights
    marksample touse, zeroweight
    markout `touse' `strata' `cluster', strok
    qui count if `touse'
    local N = r(N)
    local Nout = _N - `N'
    if `N'==0 error 2000
    capt assert `n'>=0 if `touse'
    if _rc {
        di as err "n must be 0 or larger"
        exit 198
    }
    if `"`exp'"'!="" {
        tempvar wgt
        qui generate double `wgt' `exp' if `touse'
        capt assert (`wgt'>=0) if `touse'
        if _rc error 402
        capt assert (`wgt'==0) if `touse'
        if _rc==0 {
            di as err "weights all zero"
            exit 499
        }
    }
    else local wgt
    
    // settings depending on type of sampling
    if `"`wgt'"'!="" | "`wor'"=="" local alt    // alt only relevant for SRSWOR
    if `"`wgt'"'=="" | "`wor'"=="" local nowarn // nowarn only relevant for USPWOR
    if "`strata'"==""   local rround            // rround only relevant with strata()
    if "`strata'`cluster'"=="" {
        if "`generate'"=="" {
            local stype "1"
        }
        else {
            local stype "1g"
            local local nopreserve nopreserve
        }
    }
    else {
        if "`generate'"=="" {
            local stype "2"
        }
        else {
            local stype "2g"
            local local nopreserve nopreserve
        }
    }
    
    // apply sampling
    if "`nopreserve'"=="" preserve
    capture noisily _gsample`stype' /*
        */ `n' "`nvar'" `N' `Nout' `touse' `"`wgt'"' "`generate'" /*
        */ "`wor'" "`percent'" "`keep'" "`alt'" /*
        */ "`nowarn'" "`rround'" "`strata'" "`cluster'" "`idcluster'"
    if _rc exit _rc
    if "`nopreserve'"=="" restore, not
end

program _gsample1 // no strata, no clusters, return sample
    args n nvar N Nout touse wgt generate wor percent keep alt nowarn
    if "`nvar'"!="" {
        su `nvar' if `touse', mean
        local n = r(mean)
    }
    tempvar sortindex index
    if `Nout' {
        gen long `sortindex' = _n
        sort `touse' `sortindex'
        gen long `index' = _n * (!`touse' & `"`keep'"'!="")
    }
    else {
        gen long `index' = 0
    }
    mata: _gsample1()
    keep if `index'
    sort `index'
end

program _gsample1g // no strata, no clusters, return count variable
    args n nvar N Nout touse wgt generate wor percent keep alt nowarn
    if "`nvar'"!="" {
        su `nvar' if `touse', mean
        local n = r(mean)
    }
    tempvar index
    qui gen long `index' = (!`touse') * (`"`keep'"'!="")
    mata: _gsample1g()
    nobreak {
        capt confirm new variable `generate'
        if _rc drop `generate'
        rename `index' `generate'
    }
    // if "`keep'"=="" & `Nout' keep if `touse'
end

program _gsample2 // stratified/clustered, return sample
    args n nvar N Nout touse wgt generate wor percent keep alt nowarn ///
        rround strata cluster idcluster
    tempvar sortindex index
    gen long `sortindex' = _n
    sort `touse' `strata' `cluster' `sortindex'
    if "`strata'"!="" {
        capt confirm str var `strata'
        if `: list sizeof strata'==1 & _rc local sid "`strata'"
        else {
            tempvar sid
            by `touse' `strata': gen byte `sid' = (_n == 1)
            qui replace `sid' = sum(`sid')
        }
    }
    if "`cluster'"!="" {
        capt confirm str var `cluster'
        if `: list sizeof cluster'==1 & _rc & "`idcluster'"=="" ///
            local cid "`cluster'"
        else {
            tempvar cid
            by `touse' `strata' `cluster': gen byte `cid' = (_n == 1)
            qui replace `cid' = sum(`cid')
        }
    }
    else local idcluster
    gen long `index' = 0
    if `Nout' & "`keep'"!="" qui replace `index' = _n if !`touse'
    mata: _gsample2()
    keep if `index'
    if "`idcluster'"!="" {
        tempvar newid
        bys `touse' `strata' `cluster' `sortindex' (`index'): ///
            gen long `newid' = _n
        qui bys `touse' `strata' `cluster' `newid' (`sortindex'): ///
             replace `newid' = (_n==1)
    }
    sort `index'
    if "`idcluster'"!="" {
        qui replace `newid' = sum(`newid')
        capt confirm new variable `idcluster'
        if _rc drop `idcluster'
        rename `newid' `idcluster'
    }
end

program _gsample2g, sort // stratified/clustered, return count variable
    args n nvar N Nout touse wgt generate wor percent keep alt nowarn ///
        rround strata cluster idcluster
    sort `touse' `strata' `cluster' `_sortindex' // => stable sort order
    if "`strata'"!="" {
        capt confirm str var `strata'
        if `: list sizeof strata'==1 & _rc local sid "`strata'"
        else {
            tempvar sid
            by `touse' `strata': gen byte `sid' = (_n == 1)
            qui replace `sid' = sum(`sid')
        }
    }
    if "`cluster'"!="" {
        capt confirm str var `cluster'
        if `: list sizeof cluster'==1 & _rc & "`idcluster'"=="" ///
            local cid "`cluster'"
        else {
            tempvar cid
            by `touse' `strata' `cluster': gen byte `cid' = (_n == 1)
            qui replace `cid' = sum(`cid')
        }
    }
    else local idcluster
    tempvar index
    qui gen long `index' = (!`touse') * ("`keep'"!="")
    mata: _gsample2g()
    // if "`keep'"=="" qui keep if `touse'
    if "`idcluster'"!="" {
        tempvar newid
        by `touse' `strata' `cluster': gen byte `newid' = (_n == 1)
        qui replace `newid' = sum(`newid')
    }
    nobreak {
        capt confirm new variable `generate'
        if _rc drop `generate'
        rename `index' `generate'
        if "`idcluster'"!="" {
            capt confirm new variable `idcluster'
            if _rc drop `idcluster'
            rename `newid' `idcluster'
        }
    }
end

version 9.1
mata:
void _gsample1()
{
    // variables
    touse  = st_varindex(st_local("touse"))
    index  = st_varindex(st_local("index"))
    w      = _st_varindex(st_local("wgt"))
    wor    = st_local("wor")!=""
    pct    = st_local("percent")!=""
    Nout   = strtoreal(st_local("Nout"))
    alt    = st_local("alt")!=""
    nowarn = st_local("nowarn")!=""
    // sample size / weights / population size
    n = strtoreal(st_local("n"))
    N = strtoreal(st_local("N"))
    if (w<.) st_view(w, ., w, touse)
    if (pct) n = round(N/100 :* n)
    else     n = round(n)
    // draw sample
    if (alt | nowarn) s = mm_sample(n, N, ., w, wor, 0, 1, alt, nowarn)
    else              s = mm_sample(n, N, ., w, wor, 0, 1) // old syntax
    s = Nout :+ s
    if (wor==0 | nowarn) _gsample_expand(s, index)
    if (rows(s)>0) st_store(s, index, touse, (Nout+1::Nout+rows(s)))
}

void _gsample1g()
{
    // variables
    touse  = st_varindex(st_local("touse"))
    index  = st_varindex(st_local("index"))
    w      = _st_varindex(st_local("wgt"))
    wor    = st_local("wor")!=""
    pct    = st_local("percent")!=""
    alt    = st_local("alt")!=""
    nowarn = st_local("nowarn")!=""
    // sample size / weights / population size
    n = strtoreal(st_local("n"))
    N = strtoreal(st_local("N"))
    if (w<.) st_view(w, ., w, touse)
    if (pct) n = round(N/100 :* n)
    else     n = round(n)
    // draw sample
    if (alt | nowarn) s = mm_sample(n, N, ., w, wor, 1, 1, alt, nowarn)
    else              s = mm_sample(n, N, ., w, wor, 1, 1) // old syntax
    st_store(., index, touse, s)
}

void _gsample2()
{
    real colvector strata, cluster
    // variables
    touse  = st_varindex(st_local("touse"))
    index  = st_varindex(st_local("index"))
    sid    = _st_varindex(st_local("sid"))
    cid    = _st_varindex(st_local("cid"))
    w      = _st_varindex(st_local("wgt"))
    nvar   = _st_varindex(st_local("nvar"))
    wor    = st_local("wor")!=""
    pct    = st_local("percent")!=""
    Nout   = strtoreal(st_local("Nout"))
    N      = strtoreal(st_local("N"))
    alt    = st_local("alt")!=""
    nowarn = st_local("nowarn")!=""
    rround = st_local("rround")!=""
    // strata/clusters
    if (sid<.) st_view(strata, ., sid, touse)
    if (cid<.) st_view(cluster, ., cid, touse)
    mm_panels(strata, S=J(1,2,N), cluster, C=.)
    // weights
    if (w<.) {
        if (cid<.) st_view(w, Nout :+ mm_colrunsum(C[.,1]), w, touse)
        else st_view(w, ., w, touse)
    }
    // sample size
    if (nvar<.) {
        if (sid<.) n = st_data(Nout :+ mm_colrunsum(S[.,1]), nvar)
        else n = _st_data(Nout+1, nvar)
    }
    else n = strtoreal(st_local("n"))
    if (pct)    n = S[.,2]/100 :* n
    if (rround) n = _gsample_rround(n)
    else        n = round(n)
    // draw sample
    if (alt | nowarn) s = mm_sample(n, S, C, w, wor, 0, 1, alt, nowarn)
    else              s = mm_sample(n, S, C, w, wor, 0, 1) // old syntax
    s = Nout :+ s
    if (wor==0 | nowarn) _gsample_expand(s, index)
    if (rows(s)>0) st_store(s, index, touse, (Nout+1::Nout+rows(s)))
}

void _gsample2g()
{
    real colvector strata, cluster
// variables
    touse  = st_varindex(st_local("touse"))
    index  = st_varindex(st_local("index"))
    sid    = _st_varindex(st_local("sid"))
    cid    = _st_varindex(st_local("cid"))
    w      = _st_varindex(st_local("wgt"))
    nvar   = _st_varindex(st_local("nvar"))
    wor    = st_local("wor")!=""
    pct    = st_local("percent")!=""
    Nout   = strtoreal(st_local("Nout"))
    N      = strtoreal(st_local("N"))
    alt    = st_local("alt")!=""
    nowarn = st_local("nowarn")!=""
    rround = st_local("rround")!=""
// strata/clusters
    if (sid<.) st_view(strata, ., sid, touse)
    if (cid<.) st_view(cluster, ., cid, touse)
    mm_panels(strata, S=J(1,2,N), cluster, C=.)
// weights
    if (w<.) {
        if (cid<.) st_view(w, Nout :+ mm_colrunsum(C[.,1]), w, touse)
        else st_view(w, ., w, touse)
    }
// sample size
    if (nvar<.) {
        if (sid<.) n = st_data(Nout :+ mm_colrunsum(S[.,1]), nvar)
        else n = _st_data(Nout+1, nvar)
    }
    else n = strtoreal(st_local("n"))
    if (pct)    n = S[.,2]/100 :* n
    if (rround) n = _gsample_rround(n)
    else        n = round(n)
// draw sample
    if (alt | nowarn) s = mm_sample(n, S, C, w, wor, 1, 1, alt, nowarn)
    else              s = mm_sample(n, S, C, w, wor, 1, 1) // old syntax
    st_store(., index, touse, s)
}

real colvector _gsample_rround(real colvector n)
{
    r = rows(n)
    if (r==1) return(round(n))
    n0 = trunc(n)
    N = round(sum(n)) - sum(n0)
    if (N==0) return(n0)
    return(n0 + mm_upswor(N, n-n0, 1))
}

void _gsample_expand(real colvector s, real scalar index)
{
    p = order(s,1)
    lastpos = 0
    j = st_nobs()
    for (i=1; i<=rows(p);i++) {
        pos = s[p[i]]
        if (pos == lastpos) {
            s[p[i]] = ++j // positions of duplicates after -expand-
            _st_store(pos, index, _st_data(pos, index) + 1)
        }
        else _st_store(pos, index, 1)
        lastpos = pos
    }
    stata("expand `" + "index" + "' if `" +
     "touse" + "' & `" + "index" + "'")
}
end
