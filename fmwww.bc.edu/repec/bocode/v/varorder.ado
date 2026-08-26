*! varorder 1.1.0 23aug2026
program define varorder, rclass
    version 16.0
    syntax [, UNDO]

    if "`undo'" != "" {
        _varorder_undo
        return add
        exit
    }

    quietly _varorder_plan
    local old `r(oldorder)'
    local proposed `r(neworder)'
    local k = r(k)
    local nfdet = r(n_families_detected)
    local nfcon = r(n_families_confirmed)
    local nfrel = r(n_families_related)
    local nfamb = r(n_families_ambiguous)
    local nfchanged = r(n_families_changed)
    local nfsup = r(n_families_suppressed)
    local nmove = r(n_moved)
    local maxdisp = r(max_displacement)
    local fams `r(family_names)'
    local fstates `r(family_states)'
    local freasons `r(family_reasons)'
    local families_detected `"`r(families_detected)'"'
    local families_confirmed `"`r(families_confirmed)'"'
    local families_related `"`r(families_related)'"'
    local families_ambiguous `"`r(families_ambiguous)'"'
    local families_changed `"`r(families_changed)'"'
    local families_suppressed `"`r(families_suppressed)'"'

    local nf : word count `fams'
    local relnames ""
    local ambnames ""
    local gapnames ""
    forvalues i = 1/`nf' {
        local f : word `i' of `fams'
        local s : word `i' of `fstates'
        local q : word `i' of `freasons'
        if "`s'" == "confirmed" & "`q'" == "gap" {
            local fp : list posof "`f'" in gapnames
            if !`fp' local gapnames "`gapnames' `f'"
        }
        else if "`s'" == "related" {
            local fp : list posof "`f'" in relnames
            if !`fp' local relnames "`relnames' `f'"
        }
        else if "`s'" == "ambiguous" {
            local fp : list posof "`f'" in ambnames
            if !`fp' local ambnames "`ambnames' `f'"
        }
    }
    local gapnames : list retokenize gapnames
    local relnames : list retokenize relnames
    local ambnames : list retokenize ambnames
    local ngap : word count `gapnames'
    local nrelissues : word count `relnames'
    local nambissues : word count `ambnames'
    foreach issue in gap rel amb {
        local `issue'text ""
        local ntotal 0
        if "`issue'" == "gap" local ntotal = `ngap'
        else if "`issue'" == "rel" local ntotal = `nrelissues'
        else if "`issue'" == "amb" local ntotal = `nambissues'
        local nshow = min(`ntotal', 8)
        if `nshow' {
            forvalues j = 1/`nshow' {
                local f : word `j' of ``issue'names'
                if "``issue'text'" == "" local `issue'text "`f'"
                else local `issue'text "``issue'text', `f'"
            }
        }
        if `ntotal' > `nshow' local `issue'text "``issue'text', ..."
    }

    di as txt ""
    di as txt "varorder preview summary"
    di as txt ""
    di as txt "Examined: `k' variables"
    di as txt "Confirmed temporal structures: `nfcon'"
    di as txt "Variables to be reordered: `nmove'"
    di as txt "Maximum displacement: `maxdisp' columns"
    if `ngap' | `nrelissues' | `nambissues' {
        di as txt ""
        di as txt "Issues requiring review:"
        if `ngap' di as txt "  Gap warnings but ordering allowed (`ngap'): `gaptext'"
        if `nrelissues' di as txt "  Related/unverified — no action (`nrelissues'): `reltext'"
        if `nambissues' di as txt "  Ambiguous/conflicting — no action (`nambissues'): `ambtext'"
    }
    di as txt ""
    di as txt "All eligible structures will be included in the proposed ordering. Structures marked as no action will remain unchanged."

    if "`old'" == "`proposed'" {
        di as txt ""
        di as txt "No variable-order changes were required."
        _varorder_returns, oldorder(`old') neworder(`old') k(`k') changed(0) ///
            nfdet(`nfdet') nfcon(`nfcon') nfrel(`nfrel') nfamb(`nfamb') ///
            nfchanged(0) nfsup(`nfsup') nmove(0) maxdisp(0) ///
            fdet(`"`families_detected'"') fcon(`"`families_confirmed'"') ///
            frel(`"`families_related'"') famb(`"`families_ambiguous'"') ///
            fsup(`"`families_suppressed'"')
        return add
        exit
    }

    global VARORDER_CONFIRM_RESPONSE ""
    di as txt ""
    display as txt "Press Enter to apply the proposed ordering." _request(VARORDER_CONFIRM_RESPONSE)
    local __vo_answer "${VARORDER_CONFIRM_RESPONSE}"
    macro drop VARORDER_CONFIRM_RESPONSE
    local __vo_confirmed = ("`__vo_answer'" == "" & lower(c(mode)) != "batch")
    if !`__vo_confirmed' {
        di as txt "Confirmation declined; dataset unchanged."
        _varorder_returns, oldorder(`old') neworder(`old') k(`k') changed(0) ///
            nfdet(`nfdet') nfcon(`nfcon') nfrel(`nfrel') nfamb(`nfamb') ///
            nfchanged(0) nfsup(`nfsup') nmove(0) maxdisp(0) ///
            fdet(`"`families_detected'"') fcon(`"`families_confirmed'"') ///
            frel(`"`families_related'"') famb(`"`families_ambiguous'"') ///
            fsup(`"`families_suppressed'"')
        return add
        exit
    }

    _varorder_apply, neworder(`proposed') expectedold(`old')
    local changed = r(changed)
    if `changed' di as result "Variable order updated."
    _varorder_returns, oldorder(`old') neworder(`proposed') k(`k') changed(`changed') ///
        nfdet(`nfdet') nfcon(`nfcon') nfrel(`nfrel') nfamb(`nfamb') ///
        nfchanged(`nfchanged') nfsup(`nfsup') nmove(`nmove') maxdisp(`maxdisp') ///
        fdet(`"`families_detected'"') fcon(`"`families_confirmed'"') ///
        frel(`"`families_related'"') famb(`"`families_ambiguous'"') ///
        fchanged(`"`families_changed'"') fsup(`"`families_suppressed'"')
    return add
end

program define _varorder_plan, rclass
    version 16.0
    unab __vo_old : _all
    local __vo_k : word count `__vo_old'
    forvalues __vo_i = 1/`__vo_k' {
        local __vo_v : word `__vo_i' of `__vo_old'
        local __vo_lab`__vo_i' : variable label `__vo_v'
        local __vo_vlname`__vo_i' : value label `__vo_v'
        notes _count __vo_nn : `__vo_v'
        local __vo_note`__vo_i' ""
        if `__vo_nn' > 0 {
            forvalues __vo_j = 1/`__vo_nn' {
                notes _fetch __vo_one_note : `__vo_v' `__vo_j'
                local __vo_note`__vo_i' `"`__vo_note`__vo_i'' `__vo_one_note'"'
            }
        }
    }
    mata: _varorder_make_plan()

    return scalar k = `__vo_k'
    return scalar n_families_detected = real("`__vo_nfdet'")
    return scalar n_families_confirmed = real("`__vo_nfcon'")
    return scalar n_families_related = real("`__vo_nfrel'")
    return scalar n_families_ambiguous = real("`__vo_nfamb'")
    return scalar n_families_suppressed = real("`__vo_nfrel'") + real("`__vo_nfamb'")
    return scalar n_families_changed = real("`__vo_nfchanged'")
    return scalar n_moved = real("`__vo_nmove'")
    return scalar max_displacement = real("`__vo_maxdisp'")
    return scalar order_lists_returned = 1
    return local oldorder `"`__vo_old'"'
    return local neworder `"`__vo_new'"'
    return local class_variables `"`__vo_classvars'"'
    return local class_families `"`__vo_classfams'"'
    return local class_states `"`__vo_classstates'"'
    return local class_keys `"`__vo_classkeys'"'
    return local class_reasons `"`__vo_classreasons'"'
    return local family_names `"`__vo_families'"'
    return local family_states `"`__vo_fstates'"'
    return local family_reasons `"`__vo_freasons'"'
    return local families_detected `"`__vo_families_detected'"'
    return local families_confirmed `"`__vo_families_confirmed'"'
    return local families_related `"`__vo_families_related'"'
    return local families_ambiguous `"`__vo_families_ambiguous'"'
    return local families_changed `"`__vo_families_changed'"'
    return local families_suppressed `"`__vo_families_suppressed'"'
end

program define _varorder_apply, rclass
    version 16.0
    syntax , NEWORDER(varlist) [EXPECTEDOLD(varlist) INJECTFAIL]
    unab actualold : _all
    if `"`expectedold'"' != "" & `"`actualold'"' != `"`expectedold'"' {
        di as err "varorder: dataset order changed after planning"
        exit 459
    }
    _varorder_assert_permutation, old(`"`actualold'"') new(`"`neworder'"')
    if `"`actualold'"' == `"`neworder'"' {
        return scalar changed = 0
        exit
    }
    quietly _varorder_identity
    local identity `"`r(identity)'"'
    local fr = c(frame)
    capture noisily order `neworder'
    local applyrc = _rc
    if !`applyrc' & "`injectfail'" != "" local applyrc = 459
    if !`applyrc' {
        unab got : _all
        if `"`got'"' != `"`neworder'"' local applyrc = 459
    }
    if `applyrc' {
        capture noisily order `actualold'
        local rollbackrc = _rc
        if `rollbackrc' {
            di as err "varorder: application failed and rollback also failed"
            exit 498
        }
        di as err "varorder: application failed; original order restored"
        exit `applyrc'
    }
    quietly _varorder_identity
    local afteridentity `"`r(identity)'"'
    mata: _varorder_store_undo(st_local("actualold"), st_local("fr"), st_local("afteridentity"))
    return scalar changed = 1
end

program define _varorder_undo, rclass
    version 16.0
    mata: _varorder_fetch_undo()
    if "`__vo_undo_valid'" != "1" {
        di as err "varorder: no valid undo state is available"
        exit 459
    }
    if "`__vo_undo_frame'" != c(frame) {
        di as err "varorder: undo state belongs to another frame"
        exit 459
    }
    quietly _varorder_identity
    if `"`r(identity)'"' != `"`__vo_undo_identity'"' {
        di as err "varorder: current dataset is incompatible with the stored undo state"
        exit 459
    }
    unab current : _all
    _varorder_assert_permutation, old(`"`current'"') new(`"`__vo_undo_order'"')
    capture noisily order `__vo_undo_order'
    if _rc exit _rc
    mata: _varorder_consume_undo()
    local changed = (`"`current'"' != `"`__vo_undo_order'"')
    local k : word count `current'
    local nmove 0
    local maxdisp 0
    forvalues i=1/`k' {
        local v : word `i' of `current'
        local j : list posof "`v'" in __vo_undo_order
        if `i' != `j' {
            local ++nmove
            local d = abs(`i'-`j')
            if `d' > `maxdisp' local maxdisp `d'
        }
    }
    if `changed' di as result "Variable order restored."
    else di as result "Stored variable order was already in place."
    _varorder_returns, oldorder(`current') neworder(`__vo_undo_order') k(`k') changed(`changed') ///
        nfdet(0) nfcon(0) nfrel(0) nfamb(0) nfchanged(0) nfsup(0) ///
        nmove(`nmove') maxdisp(`maxdisp')
    return add
end

program define _varorder_assert_permutation
    version 16.0
    syntax , OLD(varlist) NEW(varlist)
    local no : word count `old'
    local nn : word count `new'
    if `no' != `nn' exit 459
    local so : list sort old
    local sn : list sort new
    if `"`so'"' != `"`sn'"' exit 459
    local un : list uniq new
    local nu : word count `un'
    if `nu' != `nn' exit 459
end

program define _varorder_identity, rclass
    version 16.0
    unab names : _all
    local canonical : list sort names
    quietly _datasignature `canonical'
    local sig `"`r(datasignature)'"'
    local meta `"`: data label'|`: sortedby'"'
    foreach v of local canonical {
        local vl : variable label `v'
        local vf : format `v'
        local vv : value label `v'
        local meta `"`meta'|`v'|`vl'|`vf'|`vv'"'
        notes _count nn : `v'
        forvalues j = 1/`nn' {
            notes _fetch one_note : `v' `j'
            local meta `"`meta'|`one_note'"'
        }
    }
    mata: st_local("__vo_metahash", strofreal(hash1(st_local("meta")), "%21x"))
    mata: _varorder_extra_identity(st_local("canonical"))
    return local identity `"`sig'|`__vo_metahash'|`__vo_extra_identity'"'
end

program define _varorder_returns, rclass
    version 16.0
    syntax , OLDORDER(varlist) NEWORDER(varlist) K(integer) CHANGED(integer) ///
        NFDET(integer) NFCON(integer) NFREL(integer) NFAMB(integer) ///
        NFCHANGED(integer) NFSUP(integer) NMOVE(integer) MAXDISP(integer) ///
        [FDET(string) FCON(string) FREL(string) FAMB(string) ///
        FCHANGED(string) FSUP(string)]
    return scalar changed = `changed'
    return scalar k = `k'
    return scalar n_families_detected = `nfdet'
    return scalar n_families_confirmed = `nfcon'
    return scalar n_families_related = `nfrel'
    return scalar n_families_ambiguous = `nfamb'
    return scalar n_families_changed = `nfchanged'
    return scalar n_families_suppressed = `nfsup'
    return scalar n_moved = `nmove'
    return scalar max_displacement = `maxdisp'
    return scalar order_lists_returned = 1
    return local oldorder `"`oldorder'"'
    return local neworder `"`neworder'"'
    return local families_detected `"`fdet'"'
    return local families_confirmed `"`fcon'"'
    return local families_related `"`frel'"'
    return local families_ambiguous `"`famb'"'
    return local families_changed `"`fchanged'"'
    return local families_suppressed `"`fsup'"'
end

mata:
struct vo_parse {
    string scalar family, system, key, reason
    real scalar temporal, negative, ambiguous, unresolved
    real rowvector kval
}

string scalar _vo_norm(string scalar raw)
{
    string scalar s
    s = ustrregexra(raw, "([a-z][a-z][a-z])([A-Z])", "$1 $2")
    s = ustrlower(ustrtrim(s))
    s = ustrregexra(s, "[^\p{L}\p{N}]+", " ")
    s = ustrregexra(s, "([[:alpha:]])([0-9])", "$1 $2")
    s = ustrregexra(s, "([0-9])([[:alpha:]])", "$1 $2")
    return(strtrim(ustrregexra(s, " +", " ")))
}

real scalar _vo_has(string scalar s, string scalar re)
{
    return(ustrregexm(" "+s+" ", re))
}

string scalar _vo_clean_family(string scalar s, real scalar temporalcontext)
{
    string rowvector t, keep
    real scalar i,stagecontext
    stagecontext = temporalcontext & ustrregexm(" "+s+" ", " (before|during|after|pre|mid|post) (treatment|intervention|therapy|program) ")
    t = tokens(s); keep = J(1,0,"")
    for (i=1; i<=cols(t); i++) {
        if (anyof(("a","id","score","scores","measure","measures","measurement","measurements","repeated","assessment","assessments","outcome","outcomes","calendar","year","quarter","month","fiscal","fy","grade","academic","term","semester","developmental","within","hour","hours","day","days","week","weeks","period","cycle","then","in","of","for","hierarchy","related","setting","context","location","home","school","community","work","commute","indoor","outdoor","time","wave","visit","t","q","m","g","questionnaire","item","form","batch","identifier","not","temporal"), t[i])) continue
        if (temporalcontext & anyof(("pre","mid","post","pretest","posttest","baseline","screening","discharge","followup","follow","up","before","during","after","at","position","unknown","unspecified","occasion","phase"),t[i])) continue
        if (stagecontext & anyof(("treatment","intervention","therapy","program"),t[i])) continue
        if (ustrregexm(t[i], "^[0-9]+$")) continue
        if (anyof(("fall","spring","morning","afternoon","evening"),t[i])) continue
        keep = keep,t[i]
    }
    if (cols(keep)==0) {
        if (_vo_has(s," score ")) return("score")
        return("")
    }
    if (cols(keep)==1 & ustrlen(keep[1])==1) return("")
    return(invtokens(keep))
}

real scalar _vo_is_leap_year(real scalar y)
{
    return(mod(y,400)==0 | (mod(y,4)==0 & mod(y,100)!=0))
}

real scalar _vo_valid_calendar_date(real scalar y, real scalar m, real scalar d)
{
    real rowvector mdays
    if (y<1000 | y>2999 | m<1 | m>12 | d<1) return(0)
    mdays=(31,28,31,30,31,30,31,31,30,31,30,31)
    if (_vo_is_leap_year(y)) mdays[2]=29
    return(d<=mdays[m])
}

real scalar _vo_month_matches_quarter(real scalar q, real scalar m)
{
    return(q>=1 & q<=4 & m>=1 & m<=12 & ceil(m/3)==q)
}

real scalar _vo_generic_value_token(string scalar s)
{
    return(anyof(("yes","no","yesno","true","false","binary","agree","agreed","disagree","disagreed","strongly","neither","nor","neutral","not","applicable","unknown","missing","refused","dont","know","never","rarely","sometimes","often","always","low","medium","high","very","poor","fair","good","excellent","satisfied","dissatisfied","other","none","pre","mid","post","before","during","after","baseline","followup","follow","up"),s))
}

string scalar _vo_clean_value_name(string scalar raw)
{
    string rowvector t, keep
    real scalar i
    string scalar compact
    t=tokens(_vo_norm(raw)); keep=J(1,0,"")
    for(i=1;i<=cols(t);i++) {
        if(anyof(("value","values","label","labels","lbl","vl","domain","code","codes","generic","answer","answers","response","responses","category","categories","phase"),t[i])) continue
        if(ustrregexm(t[i],"^[0-9]+$")) continue
        keep=keep,t[i]
    }
    if(cols(keep)==0) return("")
    if(cols(keep)==1 & ustrlen(keep[1])==1) return("")
    compact=subinstr(invtokens(keep)," ","",.)
    if(anyof(("yesno","binary","likert","status"),compact)) return("")
    return(invtokens(keep))
}

string rowvector _vo_value_info(string scalar labelname)
{
    string scalar fam, sig, one
    string rowvector dirs, nt, toks, distinctive
    string colvector txt
    real colvector val
    real scalar i,j
    fam=""; sig=""; distinctive=J(1,0,"")
    if(labelname=="") return((fam,sig,"0"))
    fam=_vo_clean_value_name(labelname)
    dirs=vec(st_vldir())'
    if(anyof(dirs,labelname)) {
        st_vlload(labelname,val,txt)
        nt=J(1,rows(txt),"")
        for(i=1;i<=rows(txt);i++) nt[i]=_vo_norm(txt[i])
        nt=uniqrows(sort(nt',1))'
        sig=invtokens(nt,"|")
        for(i=1;i<=cols(nt);i++) {
            toks=tokens(nt[i])
            for(j=1;j<=cols(toks);j++) {
                if(ustrregexm(toks[j],"^[0-9]+$") | _vo_generic_value_token(toks[j])) continue
                if(!anyof(distinctive,toks[j])) distinctive=distinctive,toks[j]
            }
        }
    }
    if(fam=="" & cols(distinctive)) fam=invtokens(sort(distinctive',1)')
    if(fam=="") return(("",sig,"0"))
    return((fam,sig,"1"))
}

struct vo_parse scalar _vo_parse_source(string scalar raw)
{
    struct vo_parse scalar p
    string scalar s, sr, fam, m, unit
    real scalar n, q, g, d, per, yr, mo, dy, cy, vi, tm
    p.family=""; p.system=""; p.key="."; p.reason=""; p.temporal=0; p.negative=0; p.ambiguous=0; p.unresolved=0; p.kval=J(1,0,.)
    s = _vo_norm(raw)
    if (s=="") return(p)
    sr=ustrregexra(raw, "([a-z][a-z][a-z])([A-Z])", "$1 $2")
    sr=ustrlower(ustrtrim(sr))
    sr=ustrregexra(sr, "_+", " ")
    p.negative = _vo_has(s, " (not time|not temporal|questionnaire item|assessment form|batch identifier|batch id) ")
    p.unresolved = ustrregexm(" "+s+" ", " (temporal position|time point|measurement occasion) (unknown|unspecified) ")

    /* Most-specific typed components are recognized before their parts. */
    if (ustrregexm(" "+sr+" ", "(^|[^0-9])([12][0-9][0-9][0-9])-([0-9][0-9])-([0-9][0-9])($|[^0-9])")) {
        yr=strtoreal(ustrregexs(2)); mo=strtoreal(ustrregexs(3)); dy=strtoreal(ustrregexs(4))
        p.system="calendar_date"; p.kval=(yr,mo,dy); p.key=strofreal(yr)+":"+strofreal(mo)+":"+strofreal(dy)
        if (_vo_valid_calendar_date(yr,mo,dy)) p.temporal=1
        else { p.ambiguous=1; p.reason="invalid_temporal_value"; }
    }
    else if (ustrregexm(" "+s+" ", " (fy|fiscal year) 0*([12][0-9][0-9][0-9]) (q|quarter) 0*([0-9]+) (m|month) 0*([0-9]+) ")) {
        yr=strtoreal(ustrregexs(2)); q=strtoreal(ustrregexs(4)); mo=strtoreal(ustrregexs(6))
        p.system="fiscal_hierarchy_unsupported"; p.kval=(yr,q,mo); p.key=strofreal(yr)+":"+strofreal(q)+":"+strofreal(mo); p.ambiguous=1; p.reason="hierarchy_ambiguous"
    }
    else if (ustrregexm(" "+s+" ", " ([12][0-9][0-9][0-9]) (q|quarter) 0*([0-9]+) (m|month) 0*([0-9]+) ")) {
        yr=strtoreal(ustrregexs(1)); q=strtoreal(ustrregexs(3)); mo=strtoreal(ustrregexs(5))
        p.system="year_quarter_month"; p.kval=(yr,q,mo); p.key=strofreal(yr)+":"+strofreal(q)+":"+strofreal(mo)
        if (_vo_month_matches_quarter(q,mo)) p.temporal=1
        else { p.ambiguous=1; p.reason="hierarchy_ambiguous"; }
    }
    else if (ustrregexm(" "+s+" ", " year ([12][0-9][0-9][0-9]) (q|quarter) 0*([0-9]+) (m|month) 0*([0-9]+) ")) {
        yr=strtoreal(ustrregexs(1)); q=strtoreal(ustrregexs(3)); mo=strtoreal(ustrregexs(5))
        p.system="year_quarter_month"; p.kval=(yr,q,mo); p.key=strofreal(yr)+":"+strofreal(q)+":"+strofreal(mo)
        if (_vo_month_matches_quarter(q,mo)) p.temporal=1
        else { p.ambiguous=1; p.reason="hierarchy_ambiguous"; }
    }
    else if (ustrregexm(" "+s+" ", " fy 0*([12][0-9][0-9][0-9]) (q|quarter) 0*([0-9]+) ")) {
        yr=strtoreal(ustrregexs(1)); q=strtoreal(ustrregexs(3)); p.system="fiscal_year_quarter"; p.kval=(yr,q); p.key=strofreal(yr)+":"+strofreal(q)
        if (q>=1 & q<=4) p.temporal=1
        else { p.ambiguous=1; p.reason="invalid_temporal_value"; }
    }
    else if (ustrregexm(" "+s+" ", " fiscal year 0*([12][0-9][0-9][0-9]) (q|quarter) 0*([0-9]+) ")) {
        yr=strtoreal(ustrregexs(1)); q=strtoreal(ustrregexs(3)); p.system="fiscal_year_quarter"; p.kval=(yr,q); p.key=strofreal(yr)+":"+strofreal(q)
        if (q>=1 & q<=4) p.temporal=1
        else { p.ambiguous=1; p.reason="invalid_temporal_value"; }
    }
    else if (ustrregexm(" "+s+" ", " academic year 0*([12][0-9][0-9][0-9]) (term|semester) 0*([1-9][0-9]*) ")) {
        yr=strtoreal(ustrregexs(1)); tm=strtoreal(ustrregexs(3)); p.temporal=1; p.system="academic_year_term"; p.kval=(yr,tm); p.key=strofreal(yr)+":"+strofreal(tm)
    }
    else if (ustrregexm(" "+s+" ", " academic year 0*([12][0-9][0-9][0-9]) (term|semester) 0*([0-9]+) ")) {
        yr=strtoreal(ustrregexs(1)); tm=strtoreal(ustrregexs(3)); p.system="academic_year_term"; p.kval=(yr,tm); p.key=strofreal(yr)+":"+strofreal(tm); p.ambiguous=1; p.reason="invalid_temporal_value"
    }
    else if (ustrregexm(" "+s+" ", " cycle 0*([1-9][0-9]*) visit 0*([1-9][0-9]*) ")) {
        cy=strtoreal(ustrregexs(1)); vi=strtoreal(ustrregexs(2)); p.temporal=1; p.system="cycle_visit"; p.kval=(cy,vi); p.key=strofreal(cy)+":"+strofreal(vi)
    }
    else if (ustrregexm(" "+s+" ", " cycle 0*([0-9]+) visit 0*([0-9]+) ")) {
        cy=strtoreal(ustrregexs(1)); vi=strtoreal(ustrregexs(2)); p.system="cycle_visit"; p.kval=(cy,vi); p.key=strofreal(cy)+":"+strofreal(vi); p.ambiguous=1; p.reason="invalid_temporal_value"
    }
    else if (ustrregexm(" "+s+" ", " (g|grade) 0*([1-9][0-9]*) (fall|spring) ")) {
        g=strtoreal(ustrregexs(2)); per=(ustrregexs(3)=="fall" ? 1 : 2); p.temporal=1; p.system="grade_term"; p.kval=(g,per); p.key=strofreal(g)+":"+strofreal(per)
    }
    else if (ustrregexm(" "+s+" ", " day 0*([1-9][0-9]*) (morning|afternoon|evening) ")) {
        d=strtoreal(ustrregexs(1)); per=1+(ustrregexs(2)=="afternoon")+2*(ustrregexs(2)=="evening"); p.temporal=1; p.system="day_period"; p.kval=(d,per); p.key=strofreal(d)+":"+strofreal(per)
    }
    else if (ustrregexm(" "+s+" ", " ([12][0-9][0-9][0-9]) m 0*([0-9]+) ")) {
        yr=strtoreal(ustrregexs(1)); mo=strtoreal(ustrregexs(2)); p.system="calendar_month"; p.kval=(yr,mo); p.key=strofreal(yr)+":"+strofreal(mo)
        if (mo>=1 & mo<=12) p.temporal=1
        else { p.ambiguous=1; p.reason="invalid_temporal_value"; }
    }
    else if (ustrregexm(" "+sr+" ", "(^|[^[:alpha:]])(hours?|days?|weeks?)[ ]*([+-]?[0-9]+)($|[^0-9])")) {
        unit=ustrregexs(2); n=strtoreal(ustrregexs(3))
        if (substr(unit,1,4)=="hour") unit="hour"
        else if (substr(unit,1,3)=="day") unit="day"
        else unit="week"
        p.temporal=1; p.system="relative_"+unit; p.kval=n; p.key=strofreal(n)
    }
    else if (ustrregexm(" "+s+" ", " (t|time|wave|visit) 0*([1-9][0-9]*) ")) {
        m=ustrregexs(1); n=strtoreal(ustrregexs(2)); p.temporal=1; p.system=m; p.kval=n; p.key=strofreal(n)
    }
    else if (_vo_has(s," screening ")) { p.temporal=1; p.system="stage"; p.kval=(0,0); p.key="0:0"; }
    else if (_vo_has(s," pretest ")) { p.temporal=1; p.system="stage"; p.kval=(1,0); p.key="1:0"; }
    else if (_vo_has(s," posttest ")) { p.temporal=1; p.system="stage"; p.kval=(3,0); p.key="3:0"; }
    else if (_vo_has(s," baseline ")) { p.temporal=1; p.system="stage"; p.kval=(1,0); p.key="1:0"; }
    else if (ustrregexm(" "+s+" ", " follow up 0*([1-9][0-9]*) ")) { n=strtoreal(ustrregexs(1)); p.temporal=1; p.system="stage"; p.kval=(3,n); p.key="3:"+strofreal(n); }
    else if (ustrregexm(" "+s+" ", " followup 0*([1-9][0-9]*) ")) { n=strtoreal(ustrregexs(1)); p.temporal=1; p.system="stage"; p.kval=(3,n); p.key="3:"+strofreal(n); }
    else if (_vo_has(s," follow up ") | _vo_has(s," followup ")) { p.temporal=1; p.system="stage"; p.kval=(3,1); p.key="3:1"; }
    else if (_vo_has(s," pre ")) { p.temporal=1; p.system="stage"; p.kval=(1,0); p.key="1:0"; }
    else if (_vo_has(s," mid ")) { p.temporal=1; p.system="stage"; p.kval=(2,0); p.key="2:0"; }
    else if (_vo_has(s," post ")) { p.temporal=1; p.system="stage"; p.kval=(3,0); p.key="3:0"; }
    else if (_vo_has(s," before ")) { p.temporal=1; p.system="stage"; p.kval=(1,0); p.key="1:0"; }
    else if (_vo_has(s," during ")) { p.temporal=1; p.system="stage"; p.kval=(2,0); p.key="2:0"; }
    else if (_vo_has(s," discharge ")) { p.temporal=1; p.system="stage"; p.kval=(3,0); p.key="3:0"; }
    else if (_vo_has(s," after ")) { p.temporal=1; p.system="stage"; p.kval=(3,0); p.key="3:0"; }

    else if (ustrregexm(" "+s+" ", " ([12][0-9][0-9][0-9]) q 0*([1-4]) ")) {
        yr=strtoreal(ustrregexs(1)); q=strtoreal(ustrregexs(2)); p.temporal=1; p.system="year_quarter"; p.kval=(yr,q); p.key=strofreal(yr)+":"+strofreal(q)
    }
    else if (ustrregexm(" "+s+" ", " year ([12][0-9][0-9][0-9]) quarter 0*([1-4]) ")) {
        yr=strtoreal(ustrregexs(1)); q=strtoreal(ustrregexs(2)); p.temporal=1; p.system="year_quarter"; p.kval=(yr,q); p.key=strofreal(yr)+":"+strofreal(q)
    }
    else if (ustrregexm(" "+s+" ", " ([12][0-9][0-9][0-9]) quarter 0*([1-4]) ")) {
        yr=strtoreal(ustrregexs(1)); q=strtoreal(ustrregexs(2)); p.temporal=1; p.system="year_quarter"; p.kval=(yr,q); p.key=strofreal(yr)+":"+strofreal(q)
    }
    else if (!p.temporal & !p.ambiguous & ustrregexm(" "+s+" ", " quarter 0*([1-4]) ")) {
        q=strtoreal(ustrregexs(1)); p.temporal=1; p.system="quarter"; p.kval=q; p.key=strofreal(q)
    }
    else if (!p.temporal & !p.ambiguous & ustrregexm(" "+s+" ", " ([12][0-9][0-9][0-9]) ")) {
        yr=strtoreal(ustrregexs(1)); p.temporal=1; p.system="year"; p.kval=yr; p.key=strofreal(yr)
    }
    if (!p.temporal & !p.ambiguous & ustrregexm(" "+s+" ", " ([0-9]+) ([0-9]+) ")) {
        p.ambiguous=1; p.system="unknown_hierarchy"; p.key=ustrregexs(1)+":"+ustrregexs(2); p.kval=(strtoreal(ustrregexs(1)),strtoreal(ustrregexs(2)))
    }
    if (!p.temporal & ustrregexm(" "+s+" ", " (phase|measurement occasion|time point) ")) p.unresolved=1
    fam=_vo_clean_family(s, (p.system=="stage" | substr(p.system,1,9)=="relative_" | p.unresolved))
    if (fam=="" & ustrregexm(s,"^([[:alpha:]]+) [0-9]+$")) fam=ustrregexs(1)
    if (!p.temporal & !p.ambiguous & ustrregexm(s,"^(.+) q 0*([1-4])$")) { p.key=strofreal(strtoreal(ustrregexs(2))); p.system="quarter_candidate"; }
    else if (!p.temporal & !p.ambiguous & ustrregexm(s,"^(.+) ([0-9]+)$")) { p.key=strofreal(strtoreal(ustrregexs(2))); p.system="bare_numeric"; }
    if(p.negative & p.system=="year") { p.temporal=0; p.key="."; p.system=""; p.kval=J(1,0,.); }
    p.family=fam
    return(p)
}

real scalar _vo_compatible(string scalar a, string scalar b)
{
    string rowvector ta,tb
    string scalar ia,ib
    real scalar i
    if (a=="" | b=="") return(1)
    if (a==b) return(1)
    if (subinstr(a," ","")==subinstr(b," ","")) return(1)
    if (min((ustrlen(a),ustrlen(b)))>=3 & (usubstr(a,1,ustrlen(b))==b | usubstr(b,1,ustrlen(a))==a)) return(1)
    ta=tokens(a); tb=tokens(b); ia=ib=""
    if(min((ustrlen(ta[1]),ustrlen(tb[1])))>=3 & (usubstr(ta[1],1,ustrlen(tb[1]))==tb[1] | usubstr(tb[1],1,ustrlen(ta[1]))==ta[1])) {
        oka=(cols(ta)==1); okb=(cols(tb)==1)
        if(cols(ta)>1) oka=all((ta[|2\cols(ta)|]:=="at") :| (ta[|2\cols(ta)|]:=="by"))
        if(cols(tb)>1) okb=all((tb[|2\cols(tb)|]:=="at") :| (tb[|2\cols(tb)|]:=="by"))
        if(oka & okb) return(1)
    }
    for(i=1;i<=cols(ta);i++) ia=ia+usubstr(ta[i],1,1)
    for(i=1;i<=cols(tb);i++) ib=ib+usubstr(tb[i],1,1)
    if ((ustrlen(a)>=2 & a==ib) | (ustrlen(b)>=2 & b==ia)) return(1)
    return(strpos(" "+a+" "," "+b+" ")>0 | strpos(" "+b+" "," "+a+" ")>0)
}

string scalar _vo_schema(string scalar s)
{
    if (anyof(("t","time","wave","visit"),s)) return("index")
    if (anyof(("stage","stage_unresolved"),s)) return("stage")
    if (substr(s,1,9)=="relative_") return("relative")
    if (s=="quarter_candidate") return("quarter")
    if (s=="bare_numeric" | s=="related_lexical" | s=="") return("related")
    return(s)
}

string scalar _vo_sort_key(real rowvector v)
{
    real scalar i,j
    string scalar digits, complement
    string rowvector out
    out=J(1,cols(v),"")
    for(i=1;i<=cols(v);i++) {
        digits=sprintf("%020.0f",abs(v[i]))
        if(v[i]<0) {
            complement=""
            for(j=1;j<=strlen(digits);j++) complement=complement+strofreal(9-strtoreal(substr(digits,j,1)))
            out[i]="0"+complement
        }
        else out[i]="1"+digits
    }
    return(invtokens(out,":"))
}

void _varorder_make_plan()
{
    real scalar k,i,j,g,nf,conf,neg,amb,unres,alltemp,collision,gap,pos,newpos,maxd,nmove,nfchanged,linkok
    string scalar canon
    string colvector choices
    string rowvector vn,fam,grp,state,key,reason,sys,skey,allf,fs,fr,neworder,vfamily,vdom,vi
    real rowvector kval, anchors, ord, members, emitted, classix, idx, gx,vinfo,matches,changedmask
    struct vo_parse scalar pn,pl,pt
    k=st_nvar(); vn=J(1,k,""); fam=state=key=reason=sys=skey=vfamily=vdom=J(1,k,""); kval=J(1,k,.); vinfo=J(1,k,0)
    for (i=1;i<=k;i++) {
        vn[i]=st_varname(i)
        pn=_vo_parse_source(vn[i]); pl=_vo_parse_source(st_local("__vo_lab"+strofreal(i))); pt=_vo_parse_source(st_local("__vo_note"+strofreal(i)))
        vi=_vo_value_info(st_local("__vo_vlname"+strofreal(i))); vfamily[i]=vi[1]; vdom[i]=vi[2]; vinfo[i]=strtoreal(vi[3])
        if(pn.system=="year" & ustrregexm(vn[i],"[[:alpha:]][12][0-9][0-9][0-9]")) { pn.temporal=0; pn.key="."; pn.system=""; pn.kval=J(1,0,.); }
        if (ustrregexm(_vo_norm(vn[i]),"^(v|var|x|item|q|u) [0-9]+$")) {
            pn.family=""
            if (pn.system=="bare_numeric" | pn.system=="quarter_candidate") { pn.key="."; pn.system=""; pn.kval=J(1,0,.); }
        }
        if (ustrlen(pn.family)<2) pn.family=""
        if (ustrlen(pl.family)<2) pl.family=""
        if (ustrlen(pt.family)<2) pt.family=""
        if (pn.system=="grade_term" & !(_vo_has(_vo_norm(st_local("__vo_lab"+strofreal(i)))," (grade|developmental|academic term) ") | _vo_has(_vo_norm(st_local("__vo_note"+strofreal(i)))," (grade|developmental|academic term) "))) { pn.temporal=0; pn.key="."; pn.kval=J(1,0,.); }
        if (pn.system=="day_period" & !(strpos(_vo_norm(st_local("__vo_lab"+strofreal(i))),"within day") | strpos(_vo_norm(st_local("__vo_note"+strofreal(i))),"within day"))) { pn.temporal=0; pn.key="."; pn.kval=J(1,0,.); }
        conf=0
        if (!_vo_compatible(pn.family,pl.family) | !_vo_compatible(pn.family,pt.family) | !_vo_compatible(pl.family,pt.family)) { conf=1; reason[i]="construct_conflict"; }
        if (pn.temporal & pl.temporal & (pn.key!=pl.key | _vo_schema(pn.system)!=_vo_schema(pl.system))) { conf=1; reason[i]="position_conflict"; }
        if (pn.temporal & pt.temporal & (pn.key!=pt.key | _vo_schema(pn.system)!=_vo_schema(pt.system))) { conf=1; reason[i]="position_conflict"; }
        if (pl.temporal & pt.temporal & (pl.key!=pt.key | _vo_schema(pl.system)!=_vo_schema(pt.system))) { conf=1; reason[i]="position_conflict"; }
        if ((pn.negative|pl.negative|pt.negative) & (pn.temporal|pl.temporal|pt.temporal)) { conf=1; reason[i]="temporal_conflict"; }
        if (!pn.temporal & pl.family!="" & _vo_compatible(pn.family,pl.family)) fam[i]=(pn.family=="" | ustrlen(pl.family)<=ustrlen(pn.family) ? pl.family : pn.family)
        else if (pn.family!="") fam[i]=pn.family
        else if (pl.family!="") fam[i]=pl.family
        else fam[i]=pt.family
        if (pl.family!="" & subinstr(fam[i]," ","")==subinstr(pl.family," ","") & ustrlen(pl.family)<ustrlen(fam[i])) fam[i]=pl.family
        if (pt.family!="" & subinstr(fam[i]," ","")==subinstr(pt.family," ","") & ustrlen(pt.family)<ustrlen(fam[i])) fam[i]=pt.family
        if (fam[i]=="" & vinfo[i]) fam[i]=vfamily[i]
        if (pn.temporal) { key[i]=pn.key; sys[i]=pn.system; kval[i]=pn.kval[1]; skey[i]=_vo_sort_key(pn.kval); }
        else if (pl.temporal) { key[i]=pl.key; sys[i]=pl.system; kval[i]=pl.kval[1]; skey[i]=_vo_sort_key(pl.kval); }
        else if (pt.temporal) { key[i]=pt.key; sys[i]=pt.system; kval[i]=pt.kval[1]; skey[i]=_vo_sort_key(pt.kval); }
        if (!pn.temporal & !pl.temporal & !pt.temporal) {
            if (pn.key!=".") { key[i]=pn.key; sys[i]=pn.system; skey[i]=(pn.system=="quarter_candidate" ? _vo_sort_key(strtoreal(pn.key)) : (cols(pn.kval) ? _vo_sort_key(pn.kval) : pn.key)); }
            else if (pl.key!=".") { key[i]=pl.key; sys[i]=pl.system; skey[i]=(cols(pl.kval) ? _vo_sort_key(pl.kval) : pl.key); }
            else if (pt.key!=".") { key[i]=pt.key; sys[i]=pt.system; skey[i]=(cols(pt.kval) ? _vo_sort_key(pt.kval) : pt.key); }
        }
        if ((pn.system=="bare_numeric" | pn.system=="quarter_candidate") & (pl.temporal | pt.temporal)) {
            if(pl.temporal) { key[i]=pl.key; sys[i]=pl.system; kval[i]=pl.kval[1]; skey[i]=_vo_sort_key(pl.kval); }
            else { key[i]=pt.key; sys[i]=pt.system; kval[i]=pt.kval[1]; skey[i]=_vo_sort_key(pt.kval); }
        }
        if (!pn.temporal & !pl.temporal & !pt.temporal & (pn.unresolved|pl.unresolved|pt.unresolved)) sys[i]="stage_unresolved"
        if(ustrregexm(_vo_norm(vn[i]),"^item [0-9]+$") & sys[i]=="time" & fam[i]!="") fam[i]=fam[i]+" time"
        if (!pn.temporal & !pl.temporal & !pt.temporal & strpos(_vo_norm(st_local("__vo_lab"+strofreal(i))),"repeated measure") & ustrregexm(_vo_norm(vn[i])," ([[:alpha:]]+)$")) { key[i]=ustrregexs(1); sys[i]="related_lexical"; skey[i]=key[i]; }
        if (!conf) {
            if (pn.reason!="") reason[i]=pn.reason
            else if (pl.reason!="") reason[i]=pl.reason
            else if (pt.reason!="") reason[i]=pt.reason
            else if (pn.ambiguous|pl.ambiguous|pt.ambiguous) reason[i]="hierarchy_ambiguous"
            else if (pn.unresolved|pl.unresolved|pt.unresolved) reason[i]="temporal_unresolved"
            else if (pn.negative|pl.negative|pt.negative) reason[i]="explicit_non_temporal"
        }
    }
    /* Relative units describe distinct, non-convertible temporal systems. */
    for(i=1;i<k;i++) for(j=i+1;j<=k;j++) {
        if(fam[i]!="" & fam[i]==fam[j] & substr(sys[i],1,9)=="relative_" & substr(sys[j],1,9)=="relative_" & sys[i]!=sys[j]) {
            reason[i]=reason[j]="incomparable_temporal_system"
        }
    }
    for(i=1;i<=k;i++) if(reason[i]=="temporal_unresolved" & fam[i]!="") {
        matches=J(1,0,.)
        for(j=1;j<=k;j++) if(fam[j]!="" & key[j]!="" & _vo_schema(sys[j])=="stage" & _vo_compatible(fam[i],fam[j])) matches=matches,j
        if(cols(matches)) {
            linkok=1
            for(g=1;g<cols(matches);g++) for(j=g+1;j<=cols(matches);j++) if(!_vo_compatible(fam[matches[g]],fam[matches[j]])) linkok=0
            if(linkok) {
                choices=uniqrows(sort(fam[matches]',1)); canon=choices[1]
                for(j=2;j<=rows(choices);j++) if(ustrlen(choices[j])<ustrlen(canon)) canon=choices[j]
                fam[i]=canon
            }
            else {
                reason[i]="construct_conflict"
                for(j=1;j<=cols(matches);j++) reason[matches[j]]="construct_conflict"
            }
        }
    }
    grp=fam
    for(i=1;i<=k;i++) if(grp[i]!="") {
        if(reason[i]=="explicit_non_temporal" & sys[i]=="year") grp[i]=grp[i]+"@related"
        else grp[i]=grp[i]+"@"+_vo_schema(sys[i])
    }
    allf=uniqrows(sort(grp',1))'
    if (cols(allf)>0) if (allf[1]=="") allf=select(allf,allf:!="")
    fs=fr=J(1,cols(allf),""); anchors=J(1,cols(allf),.)
    for (g=1;g<=cols(allf);g++) {
        members=select(1..k,grp:==allf[g]); anchors[g]=min(members)
        if (cols(members)<2) { fs[g]="unrelated"; continue; }
        conf=anyof(reason[members],"construct_conflict") | anyof(reason[members],"position_conflict") | anyof(reason[members],"temporal_conflict") | anyof(reason[members],"incomparable_temporal_system"); neg=anyof(reason[members],"explicit_non_temporal"); amb=anyof(reason[members],"hierarchy_ambiguous") | anyof(reason[members],"invalid_temporal_value"); unres=anyof(reason[members],"temporal_unresolved")
        alltemp=all(key[members]:!="") & all(sys[members]:!="bare_numeric") & all(sys[members]:!="related_lexical")
        if(anyof(sys[members],"quarter_candidate")) alltemp=all((sys[members]:=="quarter") :| (sys[members]:=="quarter_candidate")) & anyof(sys[members],"quarter")
        collision=0
        for(i=1;i<cols(members);i++) for(j=i+1;j<=cols(members);j++) if(key[members[i]]!="" & key[members[i]]==key[members[j]]) collision=1
        if(conf) {
            fs[g]="ambiguous"
            if(anyof(reason[members],"construct_conflict")) fr[g]="construct_conflict"
            else if(anyof(reason[members],"position_conflict")) fr[g]="position_conflict"
            else if(anyof(reason[members],"incomparable_temporal_system")) fr[g]="incomparable_temporal_system"
            else fr[g]="temporal_conflict"
        }
        else if(unres) { fs[g]="ambiguous"; fr[g]="incomplete_temporal_structure"; }
        else if(amb) { fs[g]="ambiguous"; fr[g]=(anyof(reason[members],"invalid_temporal_value") ? "invalid_temporal_value" : "hierarchy_ambiguous"); }
        else if(collision) { fs[g]="ambiguous"; fr[g]="normalized_key_collision"; }
        else if(neg | !alltemp) { fs[g]="related"; fr[g]=(neg ? "explicit_non_temporal" : "temporal_unverified"); }
        else { fs[g]="confirmed"; fr[g]="."; }
        if(fs[g]=="confirmed") {
            gap=0
            if (all((sys[members]:=="t") :| (sys[members]:=="time") :| (sys[members]:=="wave") :| (sys[members]:=="visit"))) {
                if(max(kval[members])-min(kval[members])+1>rows(uniqrows(sort(kval[members]',1)))) gap=1
            }
            if(gap) fr[g]="gap"
        }
        for(i=1;i<=cols(members);i++) { state[members[i]]=fs[g]; if(fr[g]!=".") reason[members[i]]=fr[g]; }
    }
    emitted=J(1,k,0); neworder=J(1,0,"")
    for(pos=1;pos<=k;pos++) {
        gx=select(1..cols(allf),anchors:==pos)
        if(cols(gx)) {
            if(fs[gx[1]]=="confirmed") {
                members=select(1..k,grp:==allf[gx[1]])
                ord=order(skey[members]',1)'
                for(j=1;j<=cols(ord);j++) { neworder=neworder,vn[members[ord[j]]]; emitted[members[ord[j]]]=1; }
            }
        }
        if(!emitted[pos]) { neworder=neworder,vn[pos]; emitted[pos]=1; }
    }
    nmove=0;maxd=0
    for(i=1;i<=k;i++) { newpos=select(1..k,neworder:==vn[i]); if(newpos!=i) { nmove++; maxd=max((maxd,abs(newpos-i))); }; }
    nfchanged=0; changedmask=J(1,cols(allf),0)
    for(g=1;g<=cols(allf);g++) if(fs[g]=="confirmed") { members=select(1..k,grp:==allf[g]); if(any(neworder[members]:!=vn[members])) { nfchanged++; changedmask[g]=1; } }
    classix=select(1..k,state:!="")
    st_local("__vo_new",invtokens(neworder)); st_local("__vo_nfdet",strofreal(sum(fs:!="unrelated")))
    st_local("__vo_nfcon",strofreal(sum(fs:=="confirmed"))); st_local("__vo_nfrel",strofreal(sum(fs:=="related"))); st_local("__vo_nfamb",strofreal(sum(fs:=="ambiguous")))
    st_local("__vo_nfchanged",strofreal(nfchanged)); st_local("__vo_nmove",strofreal(nmove)); st_local("__vo_maxdisp",strofreal(maxd))
    for(i=1;i<=k;i++) { if(reason[i]=="") reason[i]="."; if(key[i]=="") key[i]="."; fam[i]=subinstr(fam[i]," ","_",.); }
    for(i=1;i<=cols(fr);i++) if(fr[i]=="") fr[i]="."
    st_local("__vo_classvars",invtokens(vn[classix])); st_local("__vo_classfams",invtokens(fam[classix])); st_local("__vo_classstates",invtokens(state[classix])); st_local("__vo_classkeys",invtokens(key[classix])); st_local("__vo_classreasons",invtokens(reason[classix]))
    for(i=1;i<=cols(allf);i++) { if(strpos(allf[i],"@")) allf[i]=substr(allf[i],1,strpos(allf[i],"@")-1); allf[i]=subinstr(allf[i]," ","_",.); }
    idx=select(1..cols(allf),fs:!="unrelated"); st_local("__vo_families",invtokens(allf[idx])); st_local("__vo_fstates",invtokens(fs[idx])); st_local("__vo_freasons",invtokens(fr[idx]))
    idx=select(1..cols(allf),fs:!="unrelated"); canon=""; if(cols(idx)) canon=invtokens(allf[idx]); st_local("__vo_families_detected",canon); idx=select(1..cols(allf),fs:=="confirmed"); canon=""; if(cols(idx)) canon=invtokens(allf[idx]); st_local("__vo_families_confirmed",canon)
    idx=select(1..cols(allf),fs:=="related"); canon=""; if(cols(idx)) canon=invtokens(allf[idx]); st_local("__vo_families_related",canon); idx=select(1..cols(allf),fs:=="ambiguous"); canon=""; if(cols(idx)) canon=invtokens(allf[idx]); st_local("__vo_families_ambiguous",canon)
    idx=select(1..cols(allf),changedmask:==1); canon=""; if(cols(idx)) canon=invtokens(allf[idx]); st_local("__vo_families_changed",canon); idx=select(1..cols(allf),(fs:=="related") :| (fs:=="ambiguous")); canon=""; if(cols(idx)) canon=invtokens(allf[idx]); st_local("__vo_families_suppressed",canon)
}

void _varorder_store_undo(string scalar ord, string scalar fr, string scalar id)
{
    external string rowvector VARORDER_UNDO_STATE
    VARORDER_UNDO_STATE=(ord,fr,id)
}
void _varorder_fetch_undo()
{
    external string rowvector VARORDER_UNDO_STATE
    if (length(VARORDER_UNDO_STATE)==3) {
        st_local("__vo_undo_valid","1"); st_local("__vo_undo_order",VARORDER_UNDO_STATE[1]); st_local("__vo_undo_frame",VARORDER_UNDO_STATE[2]); st_local("__vo_undo_identity",VARORDER_UNDO_STATE[3])
    }
    else st_local("__vo_undo_valid","0")
}
void _varorder_consume_undo()
{
    external string rowvector VARORDER_UNDO_STATE
    VARORDER_UNDO_STATE=J(1,0,"")
}

void _varorder_extra_identity(string scalar canonical)
{
    string rowvector vars, parts, cn, vln
    string colvector txt
    real colvector val
    real scalar i,j
    vars=tokens(canonical); parts=J(1,0,"")
    for(i=1;i<=cols(vars);i++) {
        if (st_isstrvar(vars[i])) parts=parts,(vars[i]+"="+strofreal(hash1(st_sdata(.,vars[i])),"%21x"))
        else parts=parts,(vars[i]+"="+strofreal(hash1(st_data(.,vars[i])),"%21x"))
    }
    cn=st_dir("char","_dta","*")'
    for(i=1;i<=cols(cn);i++) parts=parts,("_dta["+cn[i]+"]="+st_global("_dta["+cn[i]+"]"))
    for(i=1;i<=cols(vars);i++) {
        cn=st_dir("char",vars[i],"*")'
        for(j=1;j<=cols(cn);j++) parts=parts,(vars[i]+"["+cn[j]+"]="+st_global(vars[i]+"["+cn[j]+"]"))
    }
    vln=vec(st_vldir())'
    vln=select(vln,vln:!="")
    if (cols(vln)) vln=sort(vln',1)'
    for(i=1;i<=cols(vln);i++) {
        st_vlload(vln[i],val,txt)
        parts=parts,("vl="+vln[i]+":"+strofreal(hash1(val),"%21x")+":"+strofreal(hash1(txt),"%21x"))
    }
    st_local("__vo_extra_identity",strofreal(hash1(parts'),"%21x"))
}
end
