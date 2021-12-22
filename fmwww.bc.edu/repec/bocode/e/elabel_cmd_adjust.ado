*! version 1.0.0 07nov2021 daniel klein
program elabel_cmd_adjust
    version 11.2
    
    gettoken colon cmdline : 0 , parse(",:") quotes
    if (`"`colon'"' != ":") {
    	if (`"`colon'"' != ",") error 198
        gettoken opts cmdline : cmdline , parse(":") quotes
        local 0 , `opts'
        syntax [ , SEParator(string asis) FORCE ]
        gettoken colon cmdline : cmdline , parse(":") quotes
        if (`"`colon'"' != ":") error 198
    }
    
    gettoken cmd 0 : cmdline , quotes
    if (`"`cmd'"' == "mvencode") {
        syntax varlist [ if ] [ in ] , MV(passthru) [ Override ]
    }
    else if (`"`cmd'"' == "mvdecode") {
        syntax varlist [ if ] [ in ] , MV(passthru)
    }
    else if (`"`cmd'"' == "recode") {
        syntax anything(equalok) [ if ] [ in ] [ , COPYrest Test ]
        gettoken varlist rules : anything , parse("(") quotes
        gettoken leftpar       : rules    , parse("(") quotes
        if (`"`leftpar'"' != "(") gettoken varlist rules : anything
        unab varlist : `varlist'
    }
    else if (`"`cmd'"' == "replace") {
        syntax varname =exp [ if ] [ in ] [ , noPromote ]
    }
    else if (`"`cmd'"' == "") {
        display as err "'' found where command expected"
        exit 198
    }
    else {
        display as err `"command `cmd' is not supported"'
        exit 199
    }
    
    local current_language : char _dta[_lang_c]
    local other_languages  : char _dta[_lang_list]
    local other_languages  : list other_languages - current_language
    
    foreach var of local varlist {
        capture confirm numeric variable `var'
        if (_rc) continue
        
        local lblnames : value label `var'
        foreach lang of local other_languages {
            local lblnames `lblnames' `: char `var'[_lang_l_`lang']'
        }
        if ("`lblnames'" == "") continue
        
        local lblnames : list uniq lblnames
        local lblnamelist : list lblnamelist | lblnames
        
        local vars_with_value_labels : list vars_with_value_labels | var
    }
    
    if ("`lblnamelist'" == "") {
        `cmdline'
        exit
    }
    
    elabel _u_usedby more_vars : `lblnamelist'
    local more_vars : list more_vars - vars_with_value_labels
    if ("`more_vars'" != "") error_more_vars `more_vars' , `force'
    
    preserve
    
    mata : elabel_cmd_adjust(               ///
        st_local("cmdline"),                ///
        st_local("lblnamelist"),            ///
        st_local("vars_with_value_labels"), ///
        st_local("cmd"),                    ///
        st_local("rules"),                  ///
        st_local("if")+st_local("in"),      ///
        st_local("mv"),                     ///
        st_local("separator")               ///
        )
        
    restore , not
end

program error_more_vars
    syntax anything [ , FORCE ]
    gettoken varname : anything
    if ("`force'" == "force") local note as txt "note: "
    display as err `note' "variable `varname' " ///
    "has one of the adjusted value labels attached"
    exit 498*("`force'"=="")
end

version 11.2

mata :

mata set matastrict   on
mata set mataoptimize on

struct struct_elabel_adjust
{
    string rowvector lblnamelist
    
    real   colvector old_values
    real   colvector new_values
    
    real   rowvector varindex
    real   matrix    st_data
    
    string scalar    separator
}

void elabel_cmd_adjust(
    string scalar st_cmdline,
    string scalar st_lblnamelist,
    string scalar st_varlist,
    string scalar st_cmd,
    string scalar st_rules,
    string scalar st_ifin,
    string scalar st_mv,
    string scalar st_separator
    )
{
    struct struct_elabel_adjust scalar A
    real                        scalar rc
    
    A.separator = get_separator(tokens(st_separator))
    
    A.lblnamelist = tokens(st_lblnamelist)
    
    get_values_from_value_labels(A)
    
    if ((st_cmd == "replace") | (st_ifin != "")) {
        A.varindex = st_varindex(tokens(st_varlist))
        A.st_data = st_data(., A.varindex)
    }
    
    if ( (rc=_stata(st_cmdline)) ) exit(rc)
    
    if ((st_cmd == "replace") | (st_ifin != "")) 
        get_observed_values(A)
    else 
        change_all_values(A, st_cmd, st_rules, st_mv)
        
    adjust_value_labels(A)
}

string scalar get_separator(string rowvector separator)
{
    if (separator == J(1, 0, ""))  return(char(32))
    else if (cols(separator == 1)) return(separator)
    errprintf("option separator() invalid\n")
    exit(198)
}

void get_values_from_value_labels(struct struct_elabel_adjust scalar A)
{
    real   colvector values
    string colvector labels
    real   scalar    i
    
    pragma unset values
    pragma unset labels 
    
    for (i=1; i<=cols(A.lblnamelist); i++) {
        st_vlload(A.lblnamelist[i], values, labels)
        A.old_values = uniqrows((A.old_values\ values))
    }
}

void get_observed_values(struct struct_elabel_adjust scalar A)
{
    real matrix    old_to_new
    real scalar    i
    real colvector is_int
    
    old_to_new = J(0, 2, .)
    
    for (i=1; i<=cols(A.st_data); i++) {
        
        is_int = (A.st_data[, i]:==trunc(A.st_data[, i])) :&
                 (A.st_data[, i]:!=.) // integer or .a, .b, ..., .z
        if ( !any(is_int) ) continue
        
        old_to_new = 
            old_to_new\ 
            select((A.st_data[, i], st_data(., A.varindex[i])), is_int)
            
        old_to_new = distinctrowsof(old_to_new)
        
    }
    
    A.old_values = 
        select(A.old_values, !_aandb(A.old_values', old_to_new[, 1]')')
    
    if ( rows(A.old_values) ) 
        warning_not_observed(A.old_values)
    
    A.new_values = A.old_values\ old_to_new[, 2]
    A.old_values = A.old_values\ old_to_new[, 1]
}

void warning_not_observed(real colvector not_observed)
{
    real scalar nrows, i
    
    nrows = rows(not_observed)
    
    printf("{txt}\nWarning: value%s {res:%f}", "s"*(nrows>1), not_observed[1])
    if (nrows > 1) {
        for (i=2; i<nrows; i++) printf(", {res:%f}", not_observed[i])
        printf("%s and {res:%f}", ","*(nrows>2), not_observed[nrows])
    }
    printf(" %s label%s attached but %s not observed in the data.\n",
        (nrows>1 ? "have" : "has a"),
        "s"*(nrows>1),
        (nrows>1 ? "are" : "is")
        )
}

void change_all_values(
    struct struct_elabel_adjust scalar A,
    string                      scalar st_cmd,
    string                      scalar st_rules,
    string                      scalar st_mv
    )
{
    real   scalar n_obs, rc
    string scalar cmdline
    
    if ((n_obs=st_nobs()) < rows(A.old_values)) 
        st_addobs((rows(A.old_values) - n_obs))
    
    A.varindex = st_addvar(("double"), st_tempname())
    st_store((1::rows(A.old_values)), A.varindex, A.old_values)
    
    if (st_cmd == "mvencode") st_mv = st_mv + " override"
    
    cmdline = sprintf("%s %s %s , %s", 
        st_cmd,
        st_varname(A.varindex),
        st_rules,
        st_mv
        )
    
    if ( (rc=_stata(cmdline, 1)) ) exit(error(rc))
    
    A.new_values = st_data((1::rows(A.old_values)), A.varindex)
    
    if (n_obs < st_nobs() ) st_dropobsin((n_obs+1, st_nobs()))
}

void adjust_value_labels(struct struct_elabel_adjust scalar A)
{
    real         colvector values
    string       colvector labels
    real         scalar    i
    real         colvector select
    transmorphic scalar    vl
    
    pragma unset values
    pragma unset labels
    
    for (i=1; i<=cols(A.lblnamelist); i++) {
        
        st_vlload(A.lblnamelist[i], values, labels)
        
        select = _aandb(A.old_values', values', 0)'
        if ( !any(select) ) continue
        
        values = select(A.new_values, select)
        
        if ( any(values:!=trunc(values)) ) {
            values = select(values, (values:!=trunc(values)))[1]
            errprintf("%s: may not label %-9.0g\n", A.lblnamelist[i], values)
            exit(198)
        }
        
        if ( any(values:==.) ) {
            printf("%s: may not label .\n", A.lblnamelist[i])
            select = select:*(A.new_values:!=.)
            values = select(A.new_values, select)
        }
        
        labels = st_vlmap(A.lblnamelist[i], select(A.old_values, select))
        
        select = _distinctrowsof((strofreal(values), labels))
        values = select(values, select)
        labels = select(labels, select)
        
        vl = elabel_vlinit(A.lblnamelist[i], values, labels, A.separator)
        elabel_vldefine(vl, 1)
        
    }
    
}

end
exit
