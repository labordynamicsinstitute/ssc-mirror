*! varorder 2.0.0 31aug2026
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
    local audit_lists_returned = r(audit_lists_returned)
    local audit_family_types `"`r(audit_family_types)'"'
    local audit_family_evidence `"`r(audit_family_evidence)'"'
    local audit_family_reasons `"`r(audit_family_reasons)'"'
    local audit_variable_keys `"`r(audit_variable_keys)'"'
    local audit_variable_evidence `"`r(audit_variable_evidence)'"'
    local audit_variable_reasons `"`r(audit_variable_reasons)'"'

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
        return scalar audit_lists_returned = `audit_lists_returned'
        foreach a in audit_family_types audit_family_evidence audit_family_reasons audit_variable_keys audit_variable_evidence audit_variable_reasons {
            return local `a' `"``a''"'
        }
        exit
    }

    global VARORDER_CONFIRM_RESPONSE ""
    di as txt ""
    display as txt "Press Enter to apply the proposed ordering."
    display _request(VARORDER_CONFIRM_RESPONSE)
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
        return scalar audit_lists_returned = `audit_lists_returned'
        foreach a in audit_family_types audit_family_evidence audit_family_reasons audit_variable_keys audit_variable_evidence audit_variable_reasons {
            return local `a' `"``a''"'
        }
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
    return scalar audit_lists_returned = `audit_lists_returned'
    foreach a in audit_family_types audit_family_evidence audit_family_reasons audit_variable_keys audit_variable_evidence audit_variable_reasons {
        return local `a' `"``a''"'
    }
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
    local __vo_macrolen = c(macrolen)
    mata: _varorder_make_plan_v2()

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
    return scalar audit_lists_returned = real("`__vo_audit_ok'")
    return local audit_family_ids `"`__vo_audit_family_ids'"'
    return local audit_family_names `"`__vo_audit_family_names'"'
    return local audit_family_states `"`__vo_audit_family_states'"'
    return local audit_family_types `"`__vo_audit_family_types'"'
    return local audit_family_evidence `"`__vo_audit_family_evidence'"'
    return local audit_family_reasons `"`__vo_audit_family_reasons'"'
    return local audit_variables `"`__vo_audit_variables'"'
    return local audit_variable_family_ids `"`__vo_audit_variable_family_ids'"'
    return local audit_variable_keys `"`__vo_audit_variable_keys'"'
    return local audit_variable_evidence `"`__vo_audit_variable_evidence'"'
    return local audit_variable_reasons `"`__vo_audit_variable_reasons'"'
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
    quietly _datasignature `canonical', fast
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
        p.ambiguous=1; p.system="unknown_hierarchy"; p.key=ustrregexs(1)+":"+ustrregexs(2); p.kval=(strtoreal(ustrregexs(1)),strtoreal(ustrregexs(2))); p.reason="hierarchy_ambiguous"
    }
    if (!p.temporal & ustrregexm(" "+s+" ", " (phase|measurement occasion|time point) ")) p.unresolved=1
    fam=_vo_clean_family(s, (p.system=="stage" | substr(p.system,1,9)=="relative_" | p.unresolved))
    if (fam=="" & ustrregexm(s,"^([[:alpha:]]+) [0-9]+$")) fam=ustrregexs(1)
    if (!p.temporal & !p.ambiguous & ustrregexm(s,"^(.+) q 0*([1-4])$")) { p.kval=strtoreal(ustrregexs(2)); p.key=strofreal(p.kval); p.system="quarter_candidate"; }
    else if (!p.temporal & !p.ambiguous & ustrregexm(s,"^(.+) ([0-9]+)$")) {
        m=ustrregexra(ustrregexs(2),"^0+",""); if(m=="") m="0"
        p.key=m; p.system="bare_numeric"
    }
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

struct vo_v2date {
    real scalar found, valid, ambiguous
    real rowvector ymd
    string scalar rule
}

struct vo_v2parse {
    string scalar family, schema, key, skey, reason, reference, hierarchy, node, evidence
    real scalar temporal, negative, invalid, unresolved
    real rowvector kval
    string rowvector relfrom, relto
}

struct vo_v2graph {
    string scalar status
    real rowvector order
}

string scalar _v2_phrase(string scalar raw)
{
    string scalar s
    s=ustrlower(ustrtrim(raw))
    s=ustrregexra(s,"_+"," ")
    s=ustrregexra(s,"[ ]+"," ")
    return(s)
}

string scalar _v2_endpoint(string scalar raw)
{
    string scalar s
    s=_v2_phrase(raw)
    s=ustrregexra(s,"^[^[:alnum:]+-]+|[^[:alnum:]+-]+$","")
    return(ustrtrim(ustrregexra(s,"[ ]+"," ")))
}

string rowvector _v2_split(string scalar raw, string scalar delimiter)
{
    string rowvector out
    string scalar s
    real scalar at,n
    out=J(1,0,""); s=raw; n=strlen(delimiter)
    while((at=strpos(s,delimiter))>0) {
        out=out,substr(s,1,at-1)
        s=substr(s,at+n,.)
    }
    return(out,s)
}

real scalar _v2_month(string scalar raw)
{
    string scalar s
    s=usubstr(ustrlower(raw),1,3)
    if(s=="jan") return(1)
    if(s=="feb") return(2)
    if(s=="mar") return(3)
    if(s=="apr") return(4)
    if(s=="may") return(5)
    if(s=="jun") return(6)
    if(s=="jul") return(7)
    if(s=="aug") return(8)
    if(s=="sep") return(9)
    if(s=="oct") return(10)
    if(s=="nov") return(11)
    if(s=="dec") return(12)
    return(.)
}

struct vo_v2date scalar _v2_date(string scalar raw)
{
    struct vo_v2date scalar d
    string scalar s,n,conv
    real scalar a,b,y,m,day
    d.found=0; d.valid=0; d.ambiguous=0; d.ymd=J(1,0,.); d.rule=""
    s=ustrlower(ustrtrim(raw)); n=_vo_norm(raw); conv=""
    if(ustrregexm(" "+n+" "," (date convention )?dmy ") | strpos(" "+n+" "," day month year ")) conv="dmy"
    if(ustrregexm(" "+n+" "," (date convention )?mdy ") | strpos(" "+n+" "," month day year ")) {
        if(conv!="" & conv!="mdy") { d.found=1; d.ambiguous=1; d.rule="conflicting_date_convention"; return(d); }
        conv="mdy"
    }
    if(ustrregexm(" "+s+" ","(^|[^0-9])([12][0-9][0-9][0-9])[-/]([0-9][0-9]?)[-/]([0-9][0-9]?)($|[^0-9])")) {
        y=strtoreal(ustrregexs(2)); m=strtoreal(ustrregexs(3)); day=strtoreal(ustrregexs(4))
        d.found=1; d.ymd=(y,m,day); d.valid=_vo_valid_calendar_date(y,m,day); d.rule="date_iso"; return(d)
    }
    if(ustrregexm(" "+s+" ","(^|[^[:alpha:]])(january|jan|february|feb|march|mar|april|apr|may|june|jun|july|jul|august|aug|september|sept|sep|october|oct|november|nov|december|dec)[ ]+([0-9][0-9]?)[,]?[ ]+([12][0-9][0-9][0-9])($|[^0-9])")) {
        m=_v2_month(ustrregexs(2)); day=strtoreal(ustrregexs(3)); y=strtoreal(ustrregexs(4))
        d.found=1; d.ymd=(y,m,day); d.valid=_vo_valid_calendar_date(y,m,day); d.rule="date_month_name_mdy"; return(d)
    }
    if(ustrregexm(" "+s+" ","(^|[^0-9])([0-9][0-9]?)[ ]+(january|jan|february|feb|march|mar|april|apr|may|june|jun|july|jul|august|aug|september|sept|sep|october|oct|november|nov|december|dec)[ ]+([12][0-9][0-9][0-9])($|[^0-9])")) {
        day=strtoreal(ustrregexs(2)); m=_v2_month(ustrregexs(3)); y=strtoreal(ustrregexs(4))
        d.found=1; d.ymd=(y,m,day); d.valid=_vo_valid_calendar_date(y,m,day); d.rule="date_month_name_dmy"; return(d)
    }
    if(ustrregexm(" "+s+" ","(^|[^0-9])([0-9][0-9]?)[-/]([0-9][0-9]?)[-/]([12][0-9][0-9][0-9])($|[^0-9])")) {
        a=strtoreal(ustrregexs(2)); b=strtoreal(ustrregexs(3)); y=strtoreal(ustrregexs(4)); d.found=1
        if(conv=="dmy") { day=a; m=b; d.rule="date_declared_dmy"; }
        else if(conv=="mdy") { m=a; day=b; d.rule="date_declared_mdy"; }
        else if(a>=13 & a<=31 & b>=1 & b<=12) { day=a; m=b; d.rule="date_range_dmy"; }
        else if(b>=13 & b<=31 & a>=1 & a<=12) { m=a; day=b; d.rule="date_range_mdy"; }
        else { d.ambiguous=1; d.rule="date_ambiguous_numeric"; return(d); }
        d.ymd=(y,m,day); d.valid=_vo_valid_calendar_date(y,m,day); return(d)
    }
    if(ustrregexm(" "+s+" ","(^|[^[:alpha:]])(date|ymd)[_ ]*([12][0-9][0-9][0-9])([0-9][0-9])([0-9][0-9])($|[^0-9])")) {
        y=strtoreal(ustrregexs(3)); m=strtoreal(ustrregexs(4)); day=strtoreal(ustrregexs(5))
        d.found=1; d.ymd=(y,m,day); d.valid=_vo_valid_calendar_date(y,m,day); d.rule="date_guarded_compact_ymd"; return(d)
    }
    if(ustrregexm(" "+s+" ","(^|[^[:alpha:]])(date|ymd)[_ ]+([12][0-9][0-9][0-9])[_ ]+([0-9][0-9]?)[_ ]+([0-9][0-9]?)($|[^0-9])")) {
        y=strtoreal(ustrregexs(3)); m=strtoreal(ustrregexs(4)); day=strtoreal(ustrregexs(5))
        d.found=1; d.ymd=(y,m,day); d.valid=_vo_valid_calendar_date(y,m,day); d.rule="date_guarded_fields_ymd"; return(d)
    }
    if(ustrregexm(s,"(^|[^0-9])([12][0-9][0-9][0-9])_([0-9][0-9]?)_([0-9][0-9]?)($|[^0-9])")) {
        d.found=1; d.ambiguous=1; d.rule="date_unguarded_fields"; return(d)
    }
    if(ustrregexm(" "+s+" ","(^|[^0-9])([0-9][0-9]?)[-/]([0-9][0-9]?)[-/]([0-9][0-9])($|[^0-9])")) {
        d.found=1; d.ambiguous=1; d.rule="date_two_digit_year"; return(d)
    }
    return(d)
}

string scalar _v2_construct(string scalar raw, struct vo_v2parse scalar p, string scalar source)
{
    string scalar s,prefix
    string rowvector t,keep,drop
    real scalar i
    s=_vo_norm(raw)
    if(s=="") return("")
    if(ustrregexm(" "+s+" "," randomized ([[:alpha:]]+ )*arm ")) return("")
    if(ustrregexm(s,"^(.+?) construct( |$)")) {
        prefix=ustrtrim(ustrregexs(1))
        prefix=ustrregexra(prefix," (response|responses|status|domain|measure|measurement|score)$","")
        return(prefix)
    }
    if(ustrregexm(s,"^(.+?) (temporal hierarchy|time order|temporal order|occasion order|measurement order|stage order|phase order|assessment sequence|measurement sequence|stage sequence|phase sequence)( |$)")) {
        prefix=ustrtrim(ustrregexs(1)); prefix=ustrregexra(prefix," construct$",""); return(prefix)
    }
    if(source!="name" & p.schema=="time" & ustrregexm(" "+s+" "," score time ") & ustrregexm(s,"^(.+ time) 0*[1-9][0-9]*$")) {
        prefix=" "+ustrtrim(ustrregexs(1))+" "
        prefix=ustrregexra(prefix," (score|scores|measure|measures|measurement|measurements|assessment|assessments|outcome|outcomes) "," ")
        return(ustrtrim(ustrregexra(prefix,"[ ]+"," ")))
    }
    if(substr(p.schema,1,9)=="relative_") {
        if(ustrregexm(s,"^(.+?) (hour|hours|day|days|week|weeks) [+-]?[0-9]+ relative to ")) return(ustrtrim(ustrregexs(1)))
    }
    if(source=="name" & !(p.temporal | p.negative | p.unresolved | p.invalid | p.schema=="date" | p.schema=="bare_numeric" | p.schema=="quarter_candidate")) return("")
    t=tokens(s); keep=J(1,0,"")
    drop=("a","id","score","scores","measure","measures","measurement","measurements","repeated","assessment","assessments","outcome","outcomes","calendar","year","quarter","month","date","convention","dmy","mdy","ymd","day","days","hour","hours","week","weeks","relative","to","at","then","related","fiscal","fy","grade","academic","term","semester","developmental","within","period","cycle","visit","time","wave","t","q","m","g","pre","mid","post","pretest","posttest","baseline","screening","discharge","followup","follow","up","before","during","after","treatment","current","stage","phase","occasion","unknown","unspecified","construct","hierarchy","order","sequence","questionnaire","item","form","batch","identifier","not","temporal","january","jan","february","feb","march","mar","april","apr","may","june","jun","july","jul","august","aug","september","sept","sep","october","oct","november","nov","december","dec","fall","spring","morning","afternoon","evening")
    for(i=1;i<=cols(t);i++) {
        if(anyof(drop,t[i])) continue
        if(ustrregexm(t[i],"^[+-]?[0-9]+$")) continue
        keep=keep,t[i]
    }
    if(cols(keep)==0) return("")
    if(cols(keep)==1 & ustrlen(keep[1])==1) return("")
    return(invtokens(keep))
}

struct vo_v2parse scalar _v2_parse(string scalar raw, string scalar source)
{
    struct vo_v2parse scalar p
    struct vo_parse scalar b
    struct vo_v2date scalar d
    string scalar s,clause,cur,one,left,right,unit
    string rowvector pieces,chain
    real scalar i,n
    p.family=""; p.schema=""; p.key="."; p.skey=""; p.reason=""; p.reference=""; p.hierarchy=""; p.node=""; p.evidence=""; p.temporal=0; p.negative=0; p.invalid=0; p.unresolved=0; p.kval=J(1,0,.); p.relfrom=p.relto=J(1,0,"")
    if(ustrtrim(raw)=="") return(p)
    b=_vo_parse_source(raw)
    p.schema=(anyof(("t","time","wave","visit","index"),b.system) | substr(b.system,1,9)=="relative_" ? b.system : _vo_schema(b.system)); p.key=b.key; p.reason=b.reason; p.temporal=b.temporal; p.negative=b.negative; p.unresolved=b.unresolved; p.invalid=(b.reason=="invalid_temporal_value"); p.kval=b.kval
    if(b.ambiguous & !p.invalid) { p.schema="unresolved_"+(b.system!="" ? _vo_schema(b.system) : "hierarchy"); p.unresolved=1; p.reason=(b.reason!="" ? b.reason : "incomplete_temporal_structure"); }
    if(cols(p.kval)) p.skey=_vo_sort_key(p.kval)
    s=_v2_phrase(raw)
    d=_v2_date(raw)
    if(d.found) {
        p.schema="date"; p.temporal=d.valid; p.invalid=(d.found & !d.valid & !d.ambiguous); p.unresolved=d.ambiguous; p.reason=(p.invalid ? "invalid_temporal_value" : (p.unresolved ? "temporal_unverified" : "")); p.kval=d.ymd
        if(d.valid) { p.key=strofreal(d.ymd[1])+":"+strofreal(d.ymd[2])+":"+strofreal(d.ymd[3]); p.skey=_vo_sort_key(d.ymd); }
        else if(p.invalid & cols(d.ymd)==3) { p.key=strofreal(d.ymd[1])+":"+strofreal(d.ymd[2])+":"+strofreal(d.ymd[3]); p.skey=""; }
        else { p.key="."; p.skey=""; }
    }
    if(ustrregexm(" "+s+" "," (hour|hours|day|days|week|weeks)[ ]*([+-]?[0-9]+)[ ]+relative[ ]+to[ ]+([^.;]+)")) {
        unit=ustrregexs(1); n=strtoreal(ustrregexs(2)); clause=ustrtrim(ustrregexs(3)); p.reference=_v2_endpoint(clause)
        if(substr(unit,1,4)=="hour") unit="hour"
        else if(substr(unit,1,3)=="day") unit="day"
        else unit="week"
        p.schema="relative_"+unit; p.invalid=0; p.kval=n
        if(ustrregexm(" "+clause+" "," (or|and/or|unknown|unspecified) ") | strpos(clause,"/")) {
            p.reference=""; p.temporal=0; p.unresolved=1; p.reason="ambiguous_reference_event"; p.key="."; p.skey=""
        }
        else {
            p.temporal=1; p.unresolved=(p.reference==""); p.key=strofreal(n); p.skey=_vo_sort_key(n)
            if(p.unresolved) p.reason="ambiguous_reference_event"
        }
    }
    if(ustrregexm(s,"temporal hierarchy[ ]*:[ ]*([^.]+)")) {
        clause=ustrregexs(1); chain=_v2_split(clause,">"); p.hierarchy=""; p.kval=J(1,0,.); p.schema="hierarchy"; p.temporal=1; p.unresolved=0
        for(i=1;i<=cols(chain);i++) {
            cur=_v2_endpoint(chain[i])
            if(cur=="" | anyof(_v2_split(p.hierarchy,">"),cur)) { p.unresolved=1; p.temporal=0; continue; }
            p.hierarchy=(p.hierarchy=="" ? cur : p.hierarchy+">"+cur)
            if(ustrregexm(" "+s+" "," "+cur+"[ ]*=[ ]*([+-]?[0-9]+)")) p.kval=p.kval,strtoreal(ustrregexs(1))
            else { p.unresolved=1; p.temporal=0; }
        }
        if(cols(chain)<2) { p.unresolved=1; p.temporal=0; }
        if(p.temporal) { p.key=invtokens(strofreal(p.kval),":"); p.skey=_vo_sort_key(p.kval); }
        else { p.key="."; p.reason="incomplete_temporal_structure"; }
    }
    if(ustrregexm(s,"(time order|temporal order|occasion order|measurement order|stage order|phase order|assessment sequence|measurement sequence|stage sequence|phase sequence|occasion sequence|sequence)[ ]*:[ ]*([^.]+)")) {
        clause=ustrregexs(2); p.relfrom=p.relto=J(1,0,"")
        if(strpos(clause,"<")) {
            chain=_v2_split(clause,"<")
            for(i=1;i<cols(chain);i++) { left=_v2_endpoint(chain[i]); right=_v2_endpoint(chain[i+1]); if(left!="" & right!="" & left!=right) { p.relfrom=p.relfrom,left; p.relto=p.relto,right; }; }
        }
        else {
            pieces=_v2_split(clause,";")
            for(i=1;i<=cols(pieces);i++) {
                one=_v2_endpoint(pieces[i]); left=right=""
                if(ustrregexm(one,"^(.+) before (.+)$")) { left=ustrregexs(1); right=ustrregexs(2); left=_v2_endpoint(left); right=_v2_endpoint(right); }
                else if(ustrregexm(one,"^(.+) precedes (.+)$")) { left=ustrregexs(1); right=ustrregexs(2); left=_v2_endpoint(left); right=_v2_endpoint(right); }
                else if(ustrregexm(one,"^(.+) after (.+)$")) { right=ustrregexs(1); left=ustrregexs(2); left=_v2_endpoint(left); right=_v2_endpoint(right); }
                else if(ustrregexm(one,"^(.+) follows (.+)$")) { right=ustrregexs(1); left=ustrregexs(2); left=_v2_endpoint(left); right=_v2_endpoint(right); }
                if(left!="" & right!="" & left!=right) { p.relfrom=p.relfrom,left; p.relto=p.relto,right; }
            }
        }
        if(ustrregexm(s,"current[ ]+(stage|occasion|phase)[ ]*:[ ]*([^.;]+)")) p.node=_v2_endpoint(ustrregexs(2))
        p.schema="relation"; p.temporal=(p.node!="" & cols(p.relfrom)>0); p.unresolved=!p.temporal; p.key=(p.node=="" ? "." : p.node); p.skey=""
    }
    p.family=_v2_construct(raw,p,source)
    if(source=="name" & p.family=="" & ustrlen(b.family)>=2 & (p.temporal | p.negative | p.unresolved | p.invalid | (p.schema=="related" & p.key!="."))) p.family=b.family
    p.evidence=source
    return(p)
}

string scalar _v2_cluster(string scalar schema)
{
    if(substr(schema,1,9)=="relative_") return("relative")
    if(schema=="t" | schema=="time" | schema=="wave" | schema=="visit" | schema=="index") return("index")
    if(schema=="stage") return("stage")
    if(schema=="hierarchy") return("hierarchy")
    if(schema=="relation") return("relation")
    if(schema=="date") return("date")
    if(schema=="" | schema=="related") return("related")
    return(schema)
}

string scalar _v2_family_cluster(string scalar schema)
{
    if(anyof(("t","time","wave","visit","index"),schema)) return(schema)
    return(_v2_cluster(schema))
}

string scalar _v2_group_cluster(string scalar schema, string scalar family,
    string rowvector allschema, string rowvector allfamily)
{
    string scalar base
    string rowvector systems,robust
    real scalar i,j,n
    base=_v2_cluster(schema)
    if(base!="index") return(base)
    systems=J(1,0,"")
    for(i=1;i<=cols(allschema);i++) if(allfamily[i]==family & _v2_cluster(allschema[i])=="index") systems=systems,allschema[i]
    if(cols(systems)==0) return(base)
    systems=uniqrows(sort(systems',1))'; robust=J(1,0,"")
    for(i=1;i<=cols(systems);i++) {
        n=0
        for(j=1;j<=cols(allschema);j++) if(allfamily[j]==family & allschema[j]==systems[i]) n++
        if(n>=2) robust=robust,systems[i]
    }
    if(cols(robust)>=2 & anyof(robust,schema)) return(schema)
    return(base)
}

struct vo_v2graph scalar _v2_graph(real matrix A)
{
    struct vo_v2graph scalar g
    real scalar n,i,j,step,nz,nonunique,seen
    real rowvector indeg,done,z,stack,vis
    n=rows(A); g.order=J(1,0,.); g.status="unique"; done=J(1,n,0); nonunique=0
    indeg=colsum(A)
    for(step=1;step<=n;step++) {
        z=select(1..n,(done:==0) :& (indeg:==0)); nz=cols(z)
        if(nz==0) { g.status="cyclic_precedence"; return(g); }
        if(nz>1) nonunique=1
        i=min(z); g.order=g.order,i; done[i]=1
        for(j=1;j<=n;j++) if(A[i,j]) indeg[j]=indeg[j]-1
    }
    if(n>1) {
        vis=J(1,n,0); stack=1; vis[1]=1
        while(cols(stack)) {
            i=stack[cols(stack)]
            if(cols(stack)==1) stack=J(1,0,.)
            else stack=stack[|1\cols(stack)-1|]
            for(j=1;j<=n;j++) if((A[i,j] | A[j,i]) & !vis[j]) { vis[j]=1; stack=stack,j; }
        }
        if(sum(vis)<n) { g.status="disconnected_temporal_graph"; return(g); }
    }
    if(nonunique) g.status="nonunique_topological_order"
    return(g)
}

string scalar _v2_join(string matrix raw)
{
    if(length(raw)==0) return("")
    if(length(raw)==1) return(raw[1])
    return(invtokens(rowshape(raw,1)))
}

string scalar _v2_pipe(string matrix raw)
{
    if(length(raw)==0) return("")
    if(length(raw)==1) return(raw[1])
    return(invtokens(rowshape(raw,1)," | "))
}

string scalar _v2_reason_message(string scalar code, string scalar evidence)
{
    if(code=="gap") return("an indexed position is missing, but the observed temporal order is unambiguous; ordering allowed")
    if(code=="temporal_unverified") {
        if(strpos(evidence,"value_label")) return("attached value-label metadata identifies a related response domain but does not establish the variable's measurement occasion; no action")
        return("available metadata do not establish a defensible temporal position; no action")
    }
    if(code=="explicit_non_temporal") return("metadata explicitly identify the variable as non-temporal; no action")
    if(code=="construct_conflict") return("metadata sources disagree about construct or family identity; no action")
    if(code=="position_conflict") return("metadata sources disagree about temporal position; no action")
    if(code=="temporal_conflict") return("metadata sources disagree about temporal versus non-temporal meaning; no action")
    if(code=="hierarchy_ambiguous") return("the temporal hierarchy or its precedence is ambiguous; no action")
    if(code=="hierarchy_conflict") return("metadata sources specify conflicting temporal hierarchies; no action")
    if(code=="reference_conflict") return("metadata sources specify conflicting relative-time reference events; no action")
    if(code=="ambiguous_reference_event") return("the relative-time reference event is ambiguous; no action")
    if(code=="overlapping_family_membership") return("the variable can belong to more than one temporal family; no action")
    if(code=="normalized_key_collision") return("multiple variables map to the same normalized temporal position; no action")
    if(code=="incomplete_temporal_structure") return("the temporal components or precedence information are incomplete; no action")
    if(code=="invalid_temporal_value") return("the stated temporal value is invalid; no action")
    if(code=="cyclic_precedence") return("the temporal precedence constraints form a cycle; no action")
    if(code=="nonunique_topological_order") return("the temporal constraints permit more than one valid order; no action")
    if(code=="disconnected_temporal_graph") return("the temporal precedence graph is disconnected; no action")
    if(code=="incomparable_temporal_system") return("the temporal components use incomparable ordering systems; no action")
    return(subinstr(code,"_"," ",.)+"; no action")
}

string scalar _v2_evidence_message(string scalar evidence)
{
    string rowvector out
    out=J(1,0,"")
    if(strpos("+"+evidence+"+","+name+")) out=out,"variable name"
    if(strpos("+"+evidence+"+","+label+")) out=out,"variable label"
    if(strpos("+"+evidence+"+","+notes+")) out=out,"variable notes"
    if(strpos("+"+evidence+"+","+value_label+")) out=out,"attached value-label metadata"
    return(cols(out) ? invtokens(out," + ") : "no informative metadata source")
}

string scalar _v2_type_message(string scalar type)
{
    if(type=="indexed") return("indexed temporal sequence")
    if(type=="stage") return("semantic stage sequence")
    if(type=="calendar_date") return("calendar-date sequence")
    if(type=="explicit_relation") return("explicit precedence sequence")
    if(type=="explicit_hierarchy") return("explicit temporal hierarchy")
    if(type=="relative_mixed") return("mixed-unit relative-time sequence")
    if(substr(type,1,9)=="relative_") return(subinstr(substr(type,10,.),"_"," ",.)+" relative-time sequence")
    if(type=="unresolved") return("unresolved temporal structure")
    return(subinstr(type,"_"," ",.)+" temporal structure")
}

real rowvector _v2_which(real matrix mask)
{
    real rowvector out
    real scalar i
    out=J(1,0,.)
    for(i=1;i<=length(mask);i++) if(mask[i]) out=out,i
    return(out)
}

string rowvector _v2_pick(string matrix raw, real matrix ix)
{
    string rowvector out
    real scalar i
    out=J(1,0,"")
    for(i=1;i<=length(ix);i++) out=out,raw[ix[i]]
    return(out)
}

string scalar _v2_short_family(string scalar raw)
{
    return(subinstr(ustrtrim(raw)," ","_",.))
}

void _varorder_make_plan_v2()
{
    real scalar k,i,j,g,pos,newpos,nmove,maxd,nfchanged,conf,nvalid,nunresolved,collision,gap,hasrel,allnegative,alltemporal,refconf,hierconf,schemaconf,overlap,linkok,cyc,nf,ii,jj,found,changed,limit,maxaudit
    string scalar canon,chosen,cluster,primary,typesig,ev,common,metatext,afidsout,afnamesout,afstatesout,aftypesout,afevidenceout,afreasonsout,avarsout,avaridsout,avarkeysout,avarevidenceout,avarreasonsout
    string rowvector vn,fam,ofam,ufam,fmap,grp,state,key,skey,reason,schema,reference,hierarchy,node,evidence,allf,fs,fr,ft,fe,fid,neworder,cfam,labfam,notefam,namefam,vfamily,vdom,vi,eps,from,to,auditids,auditkeys,auditev,schemaset,leftparts,rightparts,familymessages,variablemessages,familytypemessages,familyevidencemessages,variablekeymessages,variableevidencemessages
    real rowvector anchors,members,emitted,rank,ord,idx,changedmask,kval1,vinfo,tinfo,tempmembers,obsmap,auditvars,issuefamilies,noactionvars
    real matrix A,E,R
    struct vo_v2parse scalar pn,pl,pt,px
    struct vo_v2graph scalar gr
    k=st_nvar(); vn=fam=grp=state=skey=reason=schema=reference=hierarchy=node=evidence=namefam=labfam=notefam=vfamily=vdom=J(1,k,""); key=J(1,k,"."); kval1=J(1,k,.); vinfo=tinfo=J(1,k,0); rank=J(1,k,.)
    for(i=1;i<=k;i++) {
        vn[i]=st_varname(i)
        pn=_v2_parse(vn[i],"name")
        pl=_v2_parse(st_local("__vo_lab"+strofreal(i)),"label")
        pt=_v2_parse(st_local("__vo_note"+strofreal(i)),"notes")
        vi=_vo_value_info(st_local("__vo_vlname"+strofreal(i)))
        vfamily[i]=vi[1]; vdom[i]=vi[2]; vinfo[i]=strtoreal(vi[3])
        namefam[i]=pn.family; labfam[i]=pl.family; notefam[i]=pt.family
        if(ustrregexm(_vo_norm(vn[i]),"^(v|var|x|item|q|u|p|r|k|n|c|d|h|b|w) [0-9]+$")) { namefam[i]=""; pn.schema=""; pn.key="."; pn.skey=""; pn.kval=J(1,0,.); pn.temporal=0; pn.negative=0; pn.unresolved=0; pn.invalid=0; }
        if(pn.schema=="year" & ustrregexm(vn[i],"[[:alpha:]][12][0-9][0-9][0-9]")) { pn.temporal=0; pn.schema="related"; pn.key="."; pn.skey=""; pn.kval=J(1,0,.); pn.unresolved=0; }
        if(pn.schema=="grade_term" & !(_vo_has(_vo_norm(st_local("__vo_lab"+strofreal(i)))," (grade|developmental|academic term) ") | _vo_has(_vo_norm(st_local("__vo_note"+strofreal(i)))," (grade|developmental|academic term) "))) {
            pn.temporal=0; pn.unresolved=1; pn.schema="related"; pn.key="."; pn.skey=""; pn.kval=J(1,0,.)
        }
        if(pn.schema=="day_period" & !(strpos(_vo_norm(st_local("__vo_lab"+strofreal(i))),"within day") | strpos(_vo_norm(st_local("__vo_note"+strofreal(i))),"within day"))) {
            pn.temporal=0; pn.unresolved=1; pn.schema="related"; pn.key="."; pn.skey=""; pn.kval=J(1,0,.)
        }
        if(pn.schema=="related" & (pl.temporal | pt.temporal | pl.unresolved | pt.unresolved | pl.invalid | pt.invalid) & !((labfam[i]!="" & namefam[i]==labfam[i]) | (notefam[i]!="" & namefam[i]==notefam[i]))) namefam[i]=""
        if(!pn.temporal & !pl.temporal & !pt.temporal & strpos(_vo_norm(st_local("__vo_lab"+strofreal(i))),"repeated measure") & ustrregexm(_vo_norm(vn[i]),"^(.+) ([[:alpha:]]+)$")) {
            namefam[i]=ustrregexs(1); pn.schema="related"; pn.key=ustrregexs(2); pn.skey=pn.key
        }
        tinfo[i]=(pn.temporal | pl.temporal | pt.temporal)
        conf=0
        if(namefam[i]!="" & labfam[i]!="" & !_vo_compatible(namefam[i],labfam[i])) { conf=1; reason[i]="construct_conflict"; }
        if(namefam[i]!="" & notefam[i]!="" & !_vo_compatible(namefam[i],notefam[i])) { conf=1; reason[i]="construct_conflict"; }
        if(labfam[i]!="" & notefam[i]!="" & !_vo_compatible(labfam[i],notefam[i])) { conf=1; reason[i]="construct_conflict"; }
        chosen=""
        if(namefam[i]!="") chosen=namefam[i]
        if(labfam[i]!="" & (chosen=="" | (_vo_compatible(chosen,labfam[i]) & ustrlen(labfam[i])<ustrlen(chosen)))) chosen=labfam[i]
        if(notefam[i]!="" & (chosen=="" | (_vo_compatible(chosen,notefam[i]) & ustrlen(notefam[i])<ustrlen(chosen)))) chosen=notefam[i]
        if(chosen=="" & vinfo[i]) chosen=vfamily[i]
        fam[i]=chosen
        if(pn.temporal) px=pn
        else if(pl.temporal) px=pl
        else px=pt
        if(pn.temporal & pl.temporal & (_v2_cluster(pn.schema)!=_v2_cluster(pl.schema) | pn.key!=pl.key)) { conf=1; reason[i]="position_conflict"; }
        if(pn.temporal & pt.temporal & (_v2_cluster(pn.schema)!=_v2_cluster(pt.schema) | pn.key!=pt.key)) { conf=1; reason[i]="position_conflict"; }
        if(pl.temporal & pt.temporal & (_v2_cluster(pl.schema)!=_v2_cluster(pt.schema) | pl.key!=pt.key)) { conf=1; reason[i]="position_conflict"; }
        if((pn.negative | pl.negative | pt.negative) & (pn.temporal | pl.temporal | pt.temporal)) { conf=1; reason[i]="temporal_conflict"; }
        if(px.temporal) { schema[i]=px.schema; key[i]=px.key; skey[i]=px.skey; reference[i]=px.reference; hierarchy[i]=px.hierarchy; node[i]=px.node; if(cols(px.kval)) kval1[i]=px.kval[1]; }
        else {
            if(pn.invalid | pl.invalid | pt.invalid) {
                px=(pn.invalid ? pn : (pl.invalid ? pl : pt)); reason[i]="invalid_temporal_value"; schema[i]=px.schema
                if(px.key!=".") { key[i]=px.key; skey[i]=px.skey; if(cols(px.kval)) kval1[i]=px.kval[1]; }
            }
            else if(pn.unresolved | pl.unresolved | pt.unresolved) {
                px=(pn.unresolved ? pn : (pl.unresolved ? pl : pt)); schema[i]=px.schema
                if(px.key!=".") { key[i]=px.key; skey[i]=px.skey; if(cols(px.kval)) kval1[i]=px.kval[1]; }
                if(reason[i]=="") reason[i]=(px.reason!="" ? px.reason : (substr(px.schema,1,11)=="unresolved_" ? "incomplete_temporal_structure" : "temporal_unverified"))
            }
            else if(pn.negative | pl.negative | pt.negative) {
                reason[i]="explicit_non_temporal"
                if(pn.key!=".") { schema[i]=pn.schema; key[i]=pn.key; skey[i]=pn.skey; if(cols(pn.kval)) kval1[i]=pn.kval[1]; }
            }
            else if(pn.schema=="related" & pn.key!=".") { schema[i]="related"; key[i]=pn.key; skey[i]=pn.skey; reason[i]="temporal_unverified"; }
            else {
                px=(pn.schema!="" & pn.key!="." ? pn : (pl.schema!="" & pl.key!="." ? pl : pt))
                if(px.schema!="" & px.key!=".") { schema[i]=px.schema; key[i]=px.key; skey[i]=px.skey; if(cols(px.kval)) kval1[i]=px.kval[1]; reason[i]="temporal_unverified"; }
            }
        }
        if(!px.temporal & (pl.temporal | pt.temporal)) { px=(pl.temporal ? pl : pt); schema[i]=px.schema; key[i]=px.key; skey[i]=px.skey; reference[i]=px.reference; hierarchy[i]=px.hierarchy; node[i]=px.node; if(cols(px.kval)) kval1[i]=px.kval[1]; }
        evidence[i]=""
        if(namefam[i]!="" | pn.temporal | pn.negative | pn.unresolved | pn.invalid) evidence[i]="name"
        if(labfam[i]!="" | pl.temporal | pl.negative | pl.unresolved | pl.invalid) evidence[i]=(evidence[i]=="" ? "label" : evidence[i]+"+label")
        if(notefam[i]!="" | pt.temporal | pt.negative | pt.unresolved | pt.invalid) evidence[i]=(evidence[i]=="" ? "notes" : evidence[i]+"+notes")
        if(vinfo[i]) evidence[i]=(evidence[i]=="" ? "value_label" : evidence[i]+"+value_label")
        metatext=_vo_norm(vn[i]+" "+st_local("__vo_lab"+strofreal(i))+" "+st_local("__vo_note"+strofreal(i)))
        if(!tinfo[i] & (anyof(("context","location","setting"),fam[i]) | ustrregexm(" "+metatext+" "," (treatment|randomized) arm "))) {
            fam[i]=""; namefam[i]=""; labfam[i]=""; notefam[i]=""; schema[i]=""; key[i]="."; skey[i]=""; reason[i]=""; evidence[i]=""; kval1[i]=.
        }
    }
    /* A repeated substantive label prefix can establish a related construct,
       but never supplies temporal order by itself. */
    tempmembers=_v2_which((schema:=="") :& (labfam:!="") :& (reason:!="explicit_non_temporal"))
    for(ii=1;ii<cols(tempmembers);ii++) for(jj=ii+1;jj<=cols(tempmembers);jj++) {
        i=tempmembers[ii]; j=tempmembers[jj]; leftparts=tokens(labfam[i]); rightparts=tokens(labfam[j]); common=""
        if(leftparts[1]==rightparts[1]) common=leftparts[1]
        if(common!="" & ustrlen(common)>=3 &
            !anyof(("randomized","active","placebo","control","treatment","allocation","arm","group","category","class","site","context","location","male","female","sex","gender","race","ethnicity"),common)) {
            fam[i]=fam[j]=common
        }
    }
    /* Resolve compatible construct aliases only when the complete candidate
       neighborhood is pairwise compatible; otherwise membership overlaps. */
    ofam=fam
    tempmembers=_v2_which((ofam:!="") :& (schema:!="") :& (schema:!="related") :& (substr(schema,1,11):!="unresolved_"))
    ufam=(cols(tempmembers) ? uniqrows(sort(ofam[tempmembers]',1))' : J(1,0,""))
    idx=_v2_which(ofam:!=""); cfam=(cols(idx) ? uniqrows(sort(ofam[idx]',1))' : J(1,0,"")); fmap=cfam
    for(i=1;i<=cols(cfam);i++) {
        canon=cfam[i]
        schemaset=J(1,0,"")
        for(j=1;j<=cols(ufam);j++) if(_vo_compatible(canon,ufam[j])) schemaset=schemaset,ufam[j]
        if(cols(schemaset)) schemaset=uniqrows(sort(schemaset',1))'
        linkok=1
        for(ii=1;ii<cols(schemaset);ii++) for(jj=ii+1;jj<=cols(schemaset);jj++) if(!_vo_compatible(schemaset[ii],schemaset[jj])) linkok=0
        if(linkok & cols(schemaset)) {
            chosen=schemaset[1]
            for(j=2;j<=cols(schemaset);j++) if(ustrlen(schemaset[j])<ustrlen(chosen) | (ustrlen(schemaset[j])==ustrlen(chosen) & schemaset[j]<chosen)) chosen=schemaset[j]
            fmap[i]=chosen
        }
        else if(!linkok) fmap[i]=""
    }
    for(i=1;i<=k;i++) if(ofam[i]!="") {
        idx=_v2_which(cfam:==ofam[i]); canon=fmap[idx[1]]
        if(reason[i]=="explicit_non_temporal") fam[i]=ofam[i]
        else if(schema[i]=="" | schema[i]=="related" | substr(schema[i],1,11)=="unresolved_") {
            if(canon!="") fam[i]=canon
            else if(reason[i]=="") reason[i]="overlapping_family_membership"
        }
        else if(canon=="" & reason[i]=="") reason[i]="overlapping_family_membership"
    }
    /* A variable already carrying a material source conflict is never rescued
       by compatible family aliases. */
    for(i=1;i<=k;i++) if(anyof(("construct_conflict","position_conflict","temporal_conflict","hierarchy_conflict","reference_conflict"),reason[i])) fam[i]=ofam[i]
    /* Unresolved members attach only when their construct has one temporal schema. */
    idx=_v2_which(fam:!=""); ufam=(cols(idx) ? uniqrows(sort(fam[idx]',1))' : J(1,0,""))
    for(ii=1;ii<=cols(ufam);ii++) {
        canon=ufam[ii]
        cfam=J(1,0,"")
        for(j=1;j<=k;j++) if(fam[j]==canon & tinfo[j] & schema[j]!="" & schema[j]!="related" & substr(schema[j],1,11)!="unresolved_") cfam=cfam,_v2_group_cluster(schema[j],canon,schema,fam)
        if(cols(cfam)) cfam=uniqrows(sort(cfam',1))'
        tempmembers=_v2_which((fam:==canon) :& (tinfo:==0))
        for(jj=1;jj<=cols(tempmembers);jj++) {
            i=tempmembers[jj]
            if(cols(cfam)==1) {
                if(reason[i]=="temporal_unverified" & schema[i]!="" & schema[i]!="related" & substr(schema[i],1,11)!="unresolved_" & key[i]!="." & skey[i]!="" & _v2_group_cluster(schema[i],canon,schema,fam)==cfam[1]) {
                    tinfo[i]=1; reason[i]=""
                }
                else if(reason[i]!="explicit_non_temporal") {
                    if(substr(schema[i],1,11)!="unresolved_" | _v2_group_cluster(substr(schema[i],12,.),canon,schema,fam)==cfam[1]) schema[i]="unresolved_"+cfam[1]
                }
            }
            else if(cols(cfam)>1 & reason[i]!="explicit_non_temporal") reason[i]="overlapping_family_membership"
        }
    }
    for(i=1;i<=k;i++) if(fam[i]!="") {
        cluster=_v2_group_cluster(schema[i],fam[i],schema,fam)
        if(substr(schema[i],1,11)=="unresolved_") cluster=_v2_group_cluster(substr(schema[i],12,.),fam[i],schema,fam)
        if(reason[i]=="explicit_non_temporal" & schema[i]=="") cluster="related"
        grp[i]=fam[i]+"@"+cluster
    }
    allf=uniqrows(sort(grp',1))'
    if(cols(allf)) if(allf[1]=="") {
        if(cols(allf)==1) allf=J(1,0,"")
        else allf=allf[|1,2\1,cols(allf)|]
    }
    nf=cols(allf); fs=fr=ft=fe=fid=J(1,nf,""); anchors=J(1,nf,.); changedmask=J(1,nf,0)
    for(g=1;g<=nf;g++) {
        members=_v2_which(grp:==allf[g]); anchors[g]=min(members); canon=fam[members[1]]; cluster=substr(allf[g],strpos(allf[g],"@")+1,.)
        if(anyof(("t","time","wave","visit","index"),cluster)) ft[g]="indexed"
        else if(cluster=="date") ft[g]="calendar_date"
        else if(cluster=="relation") ft[g]="explicit_relation"
        else if(cluster=="hierarchy") ft[g]="explicit_hierarchy"
        else if(cluster=="relative") {
            schemaset=uniqrows(sort(schema[members]',1))'
            ft[g]=(cols(schemaset)==1 ? schemaset[1] : "relative_mixed")
        }
        else if(cluster=="related") ft[g]="unresolved"
        else ft[g]=cluster
        if(cols(members)<2) { fs[g]="unrelated"; continue; }
        primary=""; collision=0; gap=0; hasrel=0; refconf=0; hierconf=0; schemaconf=0; overlap=0
        if(anyof(reason[members],"invalid_temporal_value")) primary="invalid_temporal_value"
        else if(anyof(reason[members],"construct_conflict")) primary="construct_conflict"
        else if(anyof(reason[members],"position_conflict")) primary="position_conflict"
        else if(anyof(reason[members],"temporal_conflict")) primary="temporal_conflict"
        else if(anyof(reason[members],"hierarchy_ambiguous")) primary="hierarchy_ambiguous"
        for(i=1;i<cols(members);i++) for(j=i+1;j<=cols(members);j++) {
            ii=members[i]; jj=members[j]
            if(hierarchy[ii]!="" & hierarchy[jj]!="" & hierarchy[ii]!=hierarchy[jj]) hierconf=1
            if(reference[ii]!="" & reference[jj]!="" & reference[ii]!=reference[jj]) refconf=1
            if(key[ii]!="." & key[ii]==key[jj] & (schema[ii]==schema[jj] | (_v2_cluster(schema[ii])=="index" & _v2_cluster(schema[jj])=="index"))) collision=1
        }
        if(primary=="" & hierconf) primary="hierarchy_conflict"
        if(primary=="" & refconf) primary="reference_conflict"
        if(primary=="" & anyof(reason[members],"ambiguous_reference_event")) primary="ambiguous_reference_event"
        for(j=1;j<=k;j++) if(reason[j]=="overlapping_family_membership" & _vo_compatible(fam[j],canon)) overlap=1
        if(primary=="" & overlap) primary="overlapping_family_membership"
        if(primary=="" & collision) primary="normalized_key_collision"
        if(primary=="" & anyof(reason[members],"incomplete_temporal_structure")) primary="incomplete_temporal_structure"
        nvalid=sum((key[members]:!=".") :& (schema[members]:!="")); nunresolved=sum((key[members]:==".") :| (substr(schema[members],1,11):=="unresolved_"))
        allnegative=all(reason[members]:=="explicit_non_temporal")
        if(primary=="" & allnegative) { fs[g]="related"; primary="explicit_non_temporal"; }
        else if(primary=="" & cluster=="related") { fs[g]="related"; primary="temporal_unverified"; }
        else if(primary=="" & !any(tinfo[members])) { fs[g]="related"; primary="temporal_unverified"; }
        else if(primary=="" & nvalid==0) { fs[g]="related"; primary="temporal_unverified"; }
        else if(primary=="" & nunresolved>0) { fs[g]="ambiguous"; primary="incomplete_temporal_structure"; }
        if(primary!="" & fs[g]=="") fs[g]="ambiguous"
        if(fs[g]=="") {
            A=J(cols(members),cols(members),0); hasrel=any(schema[members]:=="relation")
            if(hasrel) {
                eps=J(1,0,""); from=to=J(1,0,"")
                for(i=1;i<=cols(members);i++) {
                    pt=_v2_parse(st_local("__vo_note"+strofreal(members[i])),"notes")
                    if(pt.node!="") eps=eps,pt.node
                    if(cols(pt.relfrom)) { from=from,pt.relfrom; to=to,pt.relto; eps=eps,pt.relfrom,pt.relto; }
                }
                if(cols(eps)) eps=uniqrows(sort(eps',1))'
                E=J(cols(eps),cols(eps),0)
                for(i=1;i<=cols(from);i++) { ii=_v2_which(eps:==from[i]); jj=_v2_which(eps:==to[i]); if(cols(ii)&cols(jj)) E[ii[1],jj[1]]=1; }
                gr=_v2_graph(E)
                if(gr.status=="cyclic_precedence") primary="cyclic_precedence"
                else {
                    R=E
                    for(pos=1;pos<=rows(R);pos++) for(i=1;i<=rows(R);i++) for(j=1;j<=rows(R);j++) if(R[i,pos] & R[pos,j]) R[i,j]=1
                    obsmap=J(1,cols(members),.)
                    for(i=1;i<=cols(members);i++) { ii=_v2_which(eps:==node[members[i]]); if(cols(ii)) obsmap[i]=ii[1]; }
                    if(any(obsmap:==.)) primary="incomplete_temporal_structure"
                    else for(i=1;i<=cols(members);i++) for(j=1;j<=cols(members);j++) if(i!=j & R[obsmap[i],obsmap[j]]) A[i,j]=1
                    if(cols(eps)>cols(members)) gap=1
                }
            }
            else {
                for(i=1;i<cols(members);i++) for(j=i+1;j<=cols(members);j++) {
                    ii=members[i]; jj=members[j]
                    if(!(schema[ii]==schema[jj] | (_v2_cluster(schema[ii])=="index" & _v2_cluster(schema[jj])=="index")) | reference[ii]!=reference[jj] | hierarchy[ii]!=hierarchy[jj]) schemaconf=1
                    else if(skey[ii]<skey[jj]) A[i,j]=1
                    else if(skey[jj]<skey[ii]) A[j,i]=1
                }
                if(schemaconf) primary="incomparable_temporal_system"
            }
            if(primary=="") {
                gr=_v2_graph(A); primary=(gr.status=="unique" ? "" : gr.status)
                if(primary=="") { fs[g]="confirmed"; for(i=1;i<=cols(gr.order);i++) rank[members[gr.order[i]]]=i; }
                else fs[g]="ambiguous"
            }
            else fs[g]="ambiguous"
        }
        if(fs[g]=="confirmed" & anyof(("t","time","wave","visit","index"),cluster)) {
            if(max(kval1[members])-min(kval1[members])+1>rows(uniqrows(sort(kval1[members]',1)))) gap=1
        }
        fr[g]=(primary=="" ? (gap ? "gap" : ".") : primary)
        ev=""; for(i=1;i<=cols(members);i++) if(evidence[members[i]]!="" & !strpos("+"+ev+"+","+"+evidence[members[i]]+"+")) ev=(ev=="" ? evidence[members[i]] : ev+"+"+evidence[members[i]])
        fe[g]=ev; fid[g]="F"+sprintf("%03.0f",g)
        for(i=1;i<=cols(members);i++) { state[members[i]]=fs[g]; if(fr[g]!=".") reason[members[i]]=fr[g]; }
    }
    for(i=1;i<=k;i++) if(reason[i]=="overlapping_family_membership") state[i]="ambiguous"
    emitted=J(1,k,0); neworder=J(1,0,"")
    for(pos=1;pos<=k;pos++) {
        idx=_v2_which(anchors:==pos)
        if(cols(idx)) {
            if(fs[idx[1]]=="confirmed") {
                members=_v2_which(grp:==allf[idx[1]]); ord=order(rank[members]',1)'
                for(j=1;j<=cols(ord);j++) { neworder=neworder,vn[members[ord[j]]]; emitted[members[ord[j]]]=1; }
            }
        }
        if(!emitted[pos]) { neworder=neworder,vn[pos]; emitted[pos]=1; }
    }
    nmove=0; maxd=0
    for(i=1;i<=k;i++) { idx=_v2_which(neworder:==vn[i]); newpos=idx[1]; if(newpos!=i) { nmove++; maxd=max((maxd,abs(newpos-i))); }; }
    nfchanged=0
    for(g=1;g<=nf;g++) if(fs[g]=="confirmed") {
        members=_v2_which(grp:==allf[g]); changed=0
        for(i=1;i<=cols(members);i++) { idx=_v2_which(neworder:==vn[members[i]]); if(idx[1]!=members[i]) changed=1; }
        if(changed) { nfchanged++; changedmask[g]=1; }
    }
    idx=_v2_which(fs:!="unrelated")
    st_local("__vo_new",invtokens(neworder)); st_local("__vo_nfdet",strofreal(cols(idx))); st_local("__vo_nfcon",strofreal(sum(fs:=="confirmed"))); st_local("__vo_nfrel",strofreal(sum(fs:=="related"))); st_local("__vo_nfamb",strofreal(sum(fs:=="ambiguous"))); st_local("__vo_nfchanged",strofreal(nfchanged)); st_local("__vo_nmove",strofreal(nmove)); st_local("__vo_maxdisp",strofreal(maxd))
    for(i=1;i<=k;i++) { if(reason[i]=="") reason[i]="."; if(key[i]=="") key[i]="."; fam[i]=_v2_short_family(fam[i]); }
    auditvars=_v2_which(state:!=""); st_local("__vo_classvars",_v2_join(_v2_pick(vn,auditvars))); st_local("__vo_classfams",_v2_join(_v2_pick(fam,auditvars))); st_local("__vo_classstates",_v2_join(_v2_pick(state,auditvars))); st_local("__vo_classkeys",_v2_join(_v2_pick(key,auditvars))); st_local("__vo_classreasons",_v2_join(_v2_pick(reason,auditvars)))
    cfam=J(1,nf,""); for(g=1;g<=nf;g++) cfam[g]=_v2_short_family(substr(allf[g],1,strpos(allf[g],"@")-1))
    st_local("__vo_families",_v2_join(_v2_pick(cfam,idx))); st_local("__vo_fstates",_v2_join(_v2_pick(fs,idx))); st_local("__vo_freasons",_v2_join(_v2_pick(fr,idx)))
    st_local("__vo_families_detected",_v2_join(_v2_pick(cfam,idx))); st_local("__vo_families_confirmed",_v2_join(_v2_pick(cfam,_v2_which(fs:=="confirmed")))); st_local("__vo_families_related",_v2_join(_v2_pick(cfam,_v2_which(fs:=="related")))); st_local("__vo_families_ambiguous",_v2_join(_v2_pick(cfam,_v2_which(fs:=="ambiguous")))); st_local("__vo_families_changed",_v2_join(_v2_pick(cfam,_v2_which(changedmask:==1)))); st_local("__vo_families_suppressed",_v2_join(_v2_pick(cfam,_v2_which((fs:=="related") :| (fs:=="ambiguous")))))
    afidsout=_v2_join(_v2_pick(fid,idx)); afnamesout=_v2_join(_v2_pick(cfam,idx)); afstatesout=_v2_join(_v2_pick(fs,idx))
    familytypemessages=familyevidencemessages=J(1,cols(idx),"")
    for(i=1;i<=cols(idx);i++) {
        g=idx[i]
        familytypemessages[i]=cfam[g]+": "+_v2_type_message(ft[g])
        familyevidencemessages[i]=cfam[g]+": "+_v2_evidence_message(fe[g])
    }
    aftypesout=_v2_pipe(familytypemessages); afevidenceout=_v2_pipe(familyevidencemessages)
    issuefamilies=_v2_which((fr:!=".") :& (fs:!="unrelated")); familymessages=J(1,cols(issuefamilies),"")
    for(i=1;i<=cols(issuefamilies);i++) { g=issuefamilies[i]; familymessages[i]=cfam[g]+": "+_v2_reason_message(fr[g],fe[g]); }
    afreasonsout=_v2_pipe(familymessages)
    auditids=auditkeys=auditev=J(1,cols(auditvars),"")
    for(i=1;i<=cols(auditvars);i++) {
        ii=auditvars[i]; idx=_v2_which(allf:==grp[ii]); auditids[i]=fid[idx[1]]
        auditkeys[i]=(key[ii]=="." ? "none" : _v2_short_family(key[ii])); auditev[i]=(evidence[ii]=="" ? "none" : evidence[ii])
    }
    avarsout=_v2_join(_v2_pick(vn,auditvars)); avaridsout=_v2_join(auditids)
    variablekeymessages=variableevidencemessages=J(1,cols(auditvars),"")
    for(i=1;i<=cols(auditvars);i++) {
        ii=auditvars[i]
        variablekeymessages[i]=vn[ii]+" ("+_v2_short_family(fam[ii])+"): temporal key "+auditkeys[i]
        variableevidencemessages[i]=vn[ii]+" ("+_v2_short_family(fam[ii])+"): "+_v2_evidence_message(auditev[i])
    }
    avarkeysout=_v2_pipe(variablekeymessages); avarevidenceout=_v2_pipe(variableevidencemessages)
    noactionvars=_v2_which((state:=="related") :| (state:=="ambiguous")); variablemessages=J(1,cols(noactionvars),"")
    for(i=1;i<=cols(noactionvars);i++) {
        ii=noactionvars[i]; variablemessages[i]=vn[ii]+" ("+_v2_short_family(fam[ii])+"): "+_v2_reason_message(reason[ii],evidence[ii])
    }
    avarreasonsout=_v2_pipe(variablemessages)
    limit=strtoreal(st_local("__vo_macrolen"))-1024; maxaudit=max((strlen(afidsout),strlen(afnamesout),strlen(afstatesout),strlen(aftypesout),strlen(afevidenceout),strlen(afreasonsout),strlen(avarsout),strlen(avaridsout),strlen(avarkeysout),strlen(avarevidenceout),strlen(avarreasonsout)))
    if(maxaudit<=limit) {
        st_local("__vo_audit_ok","1"); st_local("__vo_audit_family_ids",afidsout); st_local("__vo_audit_family_names",afnamesout); st_local("__vo_audit_family_states",afstatesout); st_local("__vo_audit_family_types",aftypesout); st_local("__vo_audit_family_evidence",afevidenceout); st_local("__vo_audit_family_reasons",afreasonsout); st_local("__vo_audit_variables",avarsout); st_local("__vo_audit_variable_family_ids",avaridsout); st_local("__vo_audit_variable_keys",avarkeysout); st_local("__vo_audit_variable_evidence",avarevidenceout); st_local("__vo_audit_variable_reasons",avarreasonsout)
    }
    else {
        st_local("__vo_audit_ok","0"); st_local("__vo_audit_family_ids",""); st_local("__vo_audit_family_names",""); st_local("__vo_audit_family_states",""); st_local("__vo_audit_family_types",""); st_local("__vo_audit_family_evidence",""); st_local("__vo_audit_family_reasons",""); st_local("__vo_audit_variables",""); st_local("__vo_audit_variable_family_ids",""); st_local("__vo_audit_variable_keys",""); st_local("__vo_audit_variable_evidence",""); st_local("__vo_audit_variable_reasons","")
    }
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
