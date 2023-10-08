*! version 2.1.0  03oct2023
program usesome
    
    version 10.1
    
    syntax [ anything(everything) ] ///
    [ ,                             /// 
        CLEAR                       ///
        noLabel                     ///
        NOT                         ///
        /// has() not() insensitve  ///
        DS(passthru)                ///
        FINDNAME(passthru)          ///
        noReturn                    /// 
        READDTA  /// for certification; not documented
        *               /// old syntax; no longer documented
    ]
    
    if ( c(changed) & mi("`clear'") ) error 4
    
    if ( mi(`"`options'"') ) ds_findname , `ds' `findname'
    else old_syntax `anything' , `options' `ds' `findname'
    
    nobreak {
        
        tempname rr
        _return hold `rr'
        
        capture noisily break {
            
            mata : usesome(                        /// 
                    st_local("anything"),          ///
                    st_local("ifin"),              ///
                    st_local("using"),             ///
                    ("`not'"=="not"),              ///
                    st_local("label"),             ///
                    st_local("ds"),                ///
                    st_local("findname"),          ///
                    ("`return'"!="noreturn"),      ///
                    ("`readdta'"=="readdta"),      ///
                    ("`old_syntax'"=="old_syntax") ///
                    )
                    
        }
        
        local rc = _rc
        
        if ("`return'" == "noreturn") _return restore `rr'
        else                          _return drop    `rr'
        
    }
    
    exit `rc'
    
end


program ds_findname
    
    /*
        Parse the modern ds() and findname() options.
        
        We do not allow options that are be added
        to -ds- and/or -findname- after 13may2021.
        
        We also do not allow any reporting options.
        
        Modern options restrict <varspec>, 
        i. e., select the intersection of <varspec> and r(varlist).
    */
    
    syntax [ , DS(string asis) FINDNAME(string asis) ]
    
    local reporting_opts alpha detail varwidth skip indent
    
    ds_opts_not_allowed `reporting_opts' , `ds'
    findname_opts_not_allowed `reporting_opts' local columns , `findname'
    
    c_local ds       : copy local ds
    c_local findname : copy local findname 
    
end


program ds_opts_not_allowed
    
    syntax [ namelist(local) ] ///
    [ ,                        ///
        NOT                    ///
        Alpha                  ///
        Detail                 ///
        Varwidth(passthru)     ///
        Skip(passthru)         ///
        HAS(passthru)          ///
        NOT(passthru)          ///
        INSEnsitive            ///
        INDENT(passthru)       ///
        ///  no additional options
    ]
    
    foreach opt of local namelist {
        
        if (`"``opt''"' != "") opt_not_allowed ``opt''
        
    }
    
end


program findname_opts_not_allowed
    
    syntax [ namelist(local) ]                     ///
    [ ,                                            ///
        INSEnsitive                                ///
        LOCal(passthru)                            ///
        NOT                                        ///
        PLACEholder(passthru)                      /// 
        Alpha                                      ///
        Detail                                     ///
        INDENT(passthru)                           ///    
        Skip(passthru)                             ///
        Varwidth(passthru)                         ///
        Type(passthru)                             ///
        ALL(passthru)                              ///
        ANY(passthru)                              ///
        Format(passthru)                           ///
        COLumns(passthru)                          ///
        VARLabel VARLabeltext(passthru)            ///
        VALLabel VALLabelname(passthru)            ///
        VALLABELText(passthru)                     /// 
        VALLABELTEXTDef(passthru)                  /// 
        VALLABELTEXTUse(passthru)                  /// 
        VALLABELCOUNTDef(passthru)                 ///
        VALLABELCOUNTUse(passthru)                 ///
        Char Charname(passthru) CHARText(passthru) ///
        ///                      no additional options
    ]
    
    foreach opt of local namelist {
        
        if (`"``opt''"' != "") opt_not_allowed ``opt''
        
    }
    
end


program opt_not_allowed

    local 0 , notallowed `0'
    syntax  , NOTALLOWED
    
end


program old_syntax
    
    /*
        Support old syntax (up to version 1.2.0).
        
        Old syntax and modern syntax partly overlap:
        
            . usesome using <filename> , has() not() insensitive
            
        is documented new syntax but
        
            . usesome <varspec> using <filename> , has() not() insensitive
            
        and
            
            . usesome using <filename> , has() not() insensitive <options>
            
        are old syntax; has() and not() add to <varspec>.
        
        We consider all of the above old syntax, technically.
        
        However, documented overlaps do not trigger the old syntax warning.
    */
    
    c_local old_syntax "old_syntax"
    
    capture syntax [ anything(id = "varspec" everything) ] ///
        [ , HAS(passthru) NOT(passthru) INSEnsitive ]
    
    if ( !_rc ) ds_findname , ds(`has' `not' `insensitive')
    else {
        
        display as txt "(note: you are using old {bf:usesome}" ///
        " syntax; see {help usesome:{bf:usesome}} for new syntax)"
        
        syntax [ anything(id = "varspec") ] using/ ///
        [ ,                                        ///
            /// ds options
            Alpha                          /// ignored
            Detail                         /// ignored
            Varwidth(passthru)             /// ignored
            Skip(passthru)                 /// ignored
            HAS(passthru)                          ///
            NOT(passthru)                          ///
            INSEnsitive                            ///
            INDENT(passthru)               /// ignored
            /// old if() and in() options
            IFf(string asis)                       ///
            INn(string)                            ///        
            /// findname
            FINDNAME                               ///
            FINDNAMENOT                            ///
            *      /// options passed thru to findname
        ]
        
        if (`"`iff'"' != "") local ifin `ifin' if `iff'
        if ( "`inn'"  != "") local ifin `ifin' in `inn'
        
        if ( mi("`findname'`findnamenot'") ) opt_not_allowed `options'
        else if ( mi(`"`options'"') ) {
            
            display as err "findname options required"
            exit 198
            
        }
        else {
            
            if ( ("`findname'"!="") & ("`findnamenot'"!="") ) {
                
                display as err "may not combine findname and findnamenot"
                exit 198
                
            }
            
            local options `options' `insensitive'
            findname_opts_not_allowed not , `options'
            
            if ("`findnamenot'" == "findnamenot") local options `options' not
            
        }
        
        local ds  `has' `not' `insensitive'
        
    }
    
    c_local anything   : copy local anything
    c_local ifin       : copy local ifin
    c_local using      : copy local using
    c_local ds         : copy local ds
    c_local findname   : copy local options
    
end


/*  _______________________________________________________________  Mata  */

version 10.1


local usesome_info struct usesome_info scalar


mata :


mata set matastrict   on
mata set mataoptimize on


struct usesome_info
{
    
    // input from caller
    string scalar    anything
    string scalar    ifin
    string scalar    fn
    real   scalar    not
    string scalar    label
    string scalar    ds
    string scalar    findname
    real   scalar    rresults
    real   scalar    readdta
    real   scalar    old_syntax
    
    
    // derived from input
    string scalar    varspec
    
    
    // used for reading the dta file
    real   scalar    fh
    real   scalar    ds_fmt
    real   scalar    msf
    
    
    // info from the dta file
    real   scalar    nvar
    string rowvector varlist
    
    
    // selection vectors for variables
    real   rowvector vartag
    real   rowvector dsvars
    
    
    // subsets of variables in the dta file
    real   scalar    nchunk
    string rowvector chunks
    
}


/*  _____________________________________  main  */
void usesome(
    
    string scalar anything,
    string scalar ifin,
    string scalar fn,
    real   scalar not,
    string scalar label,
    string scalar ds,
    string scalar findname,
    real   scalar rresults,
    real   scalar readdta,
    real   scalar old_syntax
    
    )
{
    `usesome_info' info
    
    
    info.anything   = anything
    info.ifin       = ifin
    info.fn         = fn
    info.not        = not
    info.label      = label
    info.ds         = ds
    info.findname   = findname
    info.rresults   = rresults
    info.readdta    = readdta
    info.old_syntax = old_syntax
    
    parse_syntax(info)
    
    describe_dta(info)
    
    parse_varspec(info)
    
    use_dta(info)
}

    /*  _________________________________  parse modern syntax  */
void parse_syntax(`usesome_info' info)
{
    transmorphic scalar t
    
    
    if (info.fn == "") {
        
        /*
            Modern syntax allows regular -if- and -in- qualifiers;
            we put them into -anything- to prevent premature checks.
            
            Here, we manually split -anything- into
                
                [ <varspec> ] [ <if> ] [ <in> ] using <filename>
        */
        
        t = tokeninit(" ", J(1, 0, ""), (`"`""'"', `""""', "()"))
            tokenset(t, info.anything)
        
        while ( !anyof(("if", "in", "using", ""), tokenpeek(t)) )
            info.varspec = info.varspec + tokenget(t) + char(32)
        
        while ( !anyof(("using", ""), tokenpeek(t)) )
            info.ifin = info.ifin + tokenget(t) + char(32)
        
        if (tokenget(t) != "using") {
            
            errprintf("using required\n")
            exit(100)
            
        }
    
        if ((info.fn=tokenget(t)) == "")  {
            
            errprintf("invalid file specification\n")
            exit(198)
            
        }
        else info.fn = tokens(info.fn) // remove outside quotes
    
        if (tokenpeek(t) != "") {
            
            if ( !anyof(("if", "in"), tokenpeek(t)) ) {
                
                errprintf("invalid '%s'\n", tokenget(t))
                exit(198)
                
            }
            
            info.ifin = info.ifin + tokenrest(t) + char(32)
            
        }
        
    }
    else info.varspec = info.anything
    
    if (pathsuffix(info.fn) == "") info.fn = info.fn + ".dta"
    else if ( !anyof((".dta", ".tmp"), pathsuffix(info.fn)) ) {
        
        errprintf(`"file %s not Stata format\n"', info.fn)
        exit(610)
        
    }
}


    /*  _________________________________  describe  */
void describe_dta(`usesome_info' info)
{
    
    /*
        We want r(k) and r(varlist)
        
        We check whether Stata's -describe- can do the job;
        if so, we are done here.
        
        -describe- might fail because of 
            
            r(103) := too many variables
            r(###) := some other problem with the file
            
        we handle r(103) below and exit with r(###) otherwise
    */
    
    if ( whether_describe_works(info) ) return
    
    /*
        Stata's -describe- failed with r(103)
        
        There are too many variables in the file.
        Below, we manually read the dta file.
        
        We support dta-formats:
            
            121 := Stata release 18 (alias variables; more then 32,767 variables)
            120 := Stata release 18 (alias variables)
            
            119 := Stata release 15--18 (more than 32,767 variables)
            118 := Stata release 14--18
            117 := Stata release 13
            
            115 := Stata release 12
            114 := Stata release 10
            113 := Stata release 8
            
        For more information on how the below routines work, see:
            
            . help dta
            (https://www.stata.com/help.cgi?dta)
            
        The general idea is that each section 
            - reads the required information
            - finds the offset for the next piece of information
            
        In case of error, the (sub)routines
            - close fh (the file handle)
            - exit with the respective Stata error message
    */
    
    if ( (info.fh=_fopen(info.fn, "r")) < 0 ) exit( error(610) )
    
    info.ds_fmt = ascii(fread(info.fh, 1))
    if ( !anyof((113, 114, 115), info.ds_fmt) ) {
        
        fseek(info.fh, -1, 0)
        get_ds_fmt(info)
        
    }
    
    whether_msf(info)
    
    get_varlist(info)
    
    fclose(info.fh)
}


        /*  _____________________________  Stata's describe  */
real scalar whether_describe_works(`usesome_info' info)
{
    real scalar rc
    
    
    rc = _stata(sprintf(`"_describe using "%s" , short varlist"', info.fn), 1)
    
    if (rc == 103) return(0) // failed; too many variables
    else if ( rc ) exit( error(rc) ) // failed; error out
    
        // force reading dta manually; used for certification
    if ( info.readdta ) return(0)
    
    info.nvar    = st_numscalar("r(k)")
    info.varlist = tokens(st_global("r(varlist)"))
    
    return(1) // everything went well
}


        /*  _____________________________  dta-format  */
void get_ds_fmt(`usesome_info' info)
{
    real rowvector supported_dta_fmt
    
    
    supported_dta_fmt = 
        117,
        118,
        119,
        120,
        121
        
    assert_marker(info, "<stata_dta><header><release>")
    info.ds_fmt = strtoreal(fread(info.fh, 3))
    assert_marker(info, "</release><byteorder>")
    
    if ( anyof(supported_dta_fmt, info.ds_fmt) ) return
    
    fclose(info.fh)
    
    errprintf("file format %f is not supported\n", info.ds_fmt)
    exit(698)
}


        /*  _____________________________  byteorder  */
void whether_msf(`usesome_info' info)
{
    if (info.ds_fmt <= 115) {
        
        info.msf = (ascii(fread(info.fh, 1)) == 1)
        fseek(info.fh, 2, 0)
        
    }
    else {
        
        info.msf = (fread(info.fh, 3) == "MSF")
        assert_marker(info, "</byteorder><K>")
        
    }
}


        /*  _____________________________  varlist  */
void get_varlist(`usesome_info' info)
{
    real scalar step
    real scalar i
    
    
    info.nvar = hexread(info, ( anyof((119, 121), info.ds_fmt) ? 4 : 2))
    
    if ( !info.nvar ) return
    
    info.varlist = J(1, info.nvar, "")
    
    if (info.ds_fmt <= 115) {
        
        fseek(info.fh, 109+info.nvar, -1)
        step = 33
        
    }
    else {
        
        assert_marker(info, "</K><N>")
        (void) fread(info.fh, ((info.ds_fmt==117) ? 4 : 8))
        assert_marker(info, "</N><label>")
        (void) fread(info.fh, hexread(info, ((info.ds_fmt==117) ? 1 : 2)))
        assert_marker(info, "</label><timestamp>")
        (void) fread(info.fh, hexread(info, 1))
        assert_marker(info, "</timestamp></header><map>")
        (void) fread(info.fh, 24)
        fseek(info.fh, hexread(info, 8), -1)
        assert_marker(info, "<varnames>")
        step = (info.ds_fmt==117) ? 33 : 129
        
    }
    
    for (i=1; i<=info.nvar; ++i) info.varlist[i] = fread(info.fh, step)
    info.varlist = substr(info.varlist, 1, strpos(info.varlist, char(0)):-1)
}


        /*  _____________________________  file reading utilities  */
void assert_marker(`usesome_info' info, string scalar should_be)
{   
    string scalar is
    
    
    if ((is=fread(info.fh, strlen(should_be))) == should_be) return
    
    fclose(info.fh)
    
    errprintf("%s found where %s expected\n", is, should_be)
    exit(692)
}


real scalar hexread(`usesome_info' info, real scalar nbytes)
{
    transmorphic rowvector h
    real         scalar    i
    
    
    h = fread(info.fh, nbytes)
    h = inbase(16, ascii( (info.msf ? h : strreverse(h)) )) 
    for (i=2; i<=cols(h); ++i) h[1] = h[1] + substr("0"+h[i], -2)
    
    return( frombase(16, h[1]) )
}


    /*  _________________________________  parse varspec  */
void parse_varspec(`usesome_info' info)
{
    real   scalar    nvar
    string colvector varspec
    
    
    get_vartag(info)
        
    ds_findname(info)
    
    if ( info.not ) info.vartag = !info.vartag
    
    nvar = cols( (varspec=select(info.varlist, info.vartag)) )
    info.varspec = invtokens(varspec)    
    rreturn(info) // we always clear r() here
    
    if ( !nvar )             exit( error(102) )
    if (nvar >= c("maxvar")) exit( error(900) )
}


        /*  _____________________________  selection vector  */
void get_vartag(`usesome_info' info)
{
    transmorphic scalar t
    string       scalar tok
    
    
    info.vartag = J(1, info.nvar, (info.varspec=="")&(!info.old_syntax))
    
    t = tokeninit(" ", "-", "()")
        tokenset(t, info.varspec)
    
    /*
        <varspec> contains:
            
            (<numlist>) := variable column positions as a numlist
            <varname>   := variable name; possibly with wildcards
            <var>-<var> := a range of variable names
            
        We have a subroutine for all 3 elements. 
        Subroutines convert elements to possitions in <vartag>
        
        <vartag>
            
              0 := variable was not selected
            !=0 := variable was selected; possibly more than once
    */
    
    while ((tok=tokenget(t)) != "") {
        
        if ( regexm(tok, "^\((.*)\)$") ) 
            expand_numlist(info, regexs(1))
        else if (tokenpeek(t) != "-") 
            expand_varnames(info, tok)
        else {
            (void) tokenget(t) // known to be "-"
            expand_varrange(info, (tok, tokenget(t)))
        }
        
    }
    
    info.vartag = (info.vartag:>0)
}


            /*  _________________________  expand numeric list  */
void expand_numlist(`usesome_info' info, string scalar nl)
{
    
    /* 
        Replicates Stata's -numlist- with
            
            no limits on the number of elements
            placeholder <k> (old syntax)
    */
    
    transmorphic scalar    t
    real         scalar    a, b, d
    string       scalar    tok
    real         rowvector R
    
    
    nl = subinstr(subinstr(subinstr(nl, "[", "("), "]", ")"), " to ", ":")
    
    t = tokeninit(" ", ("/", "(", ")", ":", ","))
        tokenset(t, nl)
    
    while ((tok=tokenget(t)) != "") {
        
        a = R = get_nlist_el(tok, info)
        if ((tok=tokenget(t)) == "/") 
            R = (a..get_nlist_el(tokenget(t), info))
        else if (tok == "(") {
            
            if ( _strtoreal(tokenget(t), d=.) ) exit( error(121) )
            d = get_nlist_el(abs(d), info)
            if (tokenget(t) != ")")             exit( error(121) )
            b = get_nlist_el(tokenget(t), info)
            R = (0..trunc((b - a)/d)) :* d :+ a
        
        }
        else if (tok != "") {
            
            if (tok == ",") {
                tok = tokenget(t)
                if ( anyof((",", ""), tok) )    exit( error(121) )
            }
            
            if (tokenpeek(t) == ":") {
                if ( _strtoreal(tok, d=.) )     exit( error(121) )
                if (d < 0)                      exit( error(121) )
                d = get_nlist_el(d, info)
                d = (d - a)
                (void) tokenget(t)
                b = get_nlist_el(tokenget(t), info)
                if ((a==b)                 |
                    (((a+d)<a)&(b>a))      |
                    (((a+d)>a)&(b<a))      |
                    (((a+d)>a)&((a+d)>=b)) |
                    (((a+d)<a)&((a+d)<=b))
                )     exit( error(121) )
                R = (0..trunc((b - a)/abs(d))) :* abs(d) :+ a
            }
            else tokenset(t, tok+tokenrest(t))
            
        }
        info.vartag[R] = (info.vartag[R]:+1)
        if (tokenpeek(t) != ",") continue
        (void) tokenget(t) // skip comma
        if (tokenpeek(t) == "") exit( error(121) )
        
    }
}


real scalar get_nlist_el(
    
    transmorphic scalar el, 
    `usesome_info' info,
  | real         scalar intonly
    
    )
{
    real scalar isreal
    real scalar realel
    
    
    if ( !(isreal=isreal(el)) )
        if ( (isreal=(!_strtoreal(el, realel))) ) el = realel
    
    if ( isreal ) {
        
        if ( missing(el) )               exit( error(127) )
        if ( (el!=trunc(el)) & intonly ) exit( error(126) )
        if (abs(el) > info.nvar)         exit( error(125) )
        if ( !el )                       exit( error(125) )
        
        return( (el<0) ? (info.nvar + el + 1) : el )
        
    }
    
    /*
        Old syntax (up to version 1.2.0)
            
            <el> := k
            <el> := k-#
            <el> := k*#
        
        where k := info.nvar
    */
    
    if ( !strpos((el=strlower(el)), "k") )          exit( error(121) )
    el = subinstr(el, "k", strofreal(info.nvar))
    if ( any(strpos(el, ("-", "*"))) ) {
        
        if ( _stata("local EL: display " + el, 1) ) exit( error(121) )
        if ( _strtoreal(st_local("EL"), el) )       exit( error(121) )
        
    }
    
    return( get_nlist_el(el, info, 0) )
}


            /*  _________________________  expand variable names  */
void expand_varnames(`usesome_info' info, string scalar tok)
{
    real   scalar    tld
    real   scalar    qmk
    real   scalar    ast
    string scalar    cpy
    real   rowvector tag
    
    
    tld = strpos(tok, "~")
    qmk = strpos(tok, "?")
    ast = strpos(tok, "*")
    
    cpy = tok
    
    if ( !any((tld, qmk, ast)) ) assert_name(tok)
    
    if ( tld ) {
        
        if ( any((qmk, ast)) ) {
            errprintf("may not combine ~ and *-or-? notation\n")
            exit(198)
        }
        
        tok = subinstr(tok, "~", "*")
        
    }
    
    tag = strmatch(info.varlist, tok)
    
    if ( !any(tag) ) {
        
        if (tok == "_all") tag = J(1, info.nvar, 1)
        else if ( !any((tld, qmk, ast)) & (c("varabbrev") == "on") ) {
            tld = 1
            tag = strmatch(info.varlist, tok+"*")
        }
        
        if ( !any(tag) ) not_found(cpy)
        
    }
    
    if ( tld ) {
        
        if (rowsum(tag) > 1) {
            errprintf("%s ambiguous abbreviation\n", cpy)
            exit(111)
        }
        
    }
    
    info.vartag = (info.vartag :+ tag)
}


            /*  _________________________  expand variable range  */
void expand_varrange(`usesome_info' info, string rowvector tok)
{
    real scalar tag1, tag2
    
    
    assert_name(tok[2])
    assert_name(tok[1], "-")
    
    if ( !any((tag1=(info.varlist:==tok[1]))) ) not_found(tok[1])
    if ( !any((tag2=(info.varlist:==tok[2]))) ) not_found(tok[2])
    
    info.vartag = (info.vartag :+ tag1 :+ tag2)
    
    tag1 = select((1..cols(info.varlist)), tag1) 
    tag2 = select((1..cols(info.varlist)), tag2)
    
    if (tag1 <= tag2) return
    
    errprintf("variables out of order\n")
    exit(111)
}


        /*  _____________________________  ds and findname  */
void ds_findname(`usesome_info' info)
{
    real   scalar i, rc
    string scalar usecmd
    
    
    if ( (info.ds=="") & (info.findname=="") ) return
    
    if (info.ds != "") 
        info.ds = sprintf(`"quietly : ds , %s"', info.ds)
    if (info.findname != "") 
        info.findname = sprintf(`"quietly : findname , %s"', info.findname)
    
    usecmd = sprintf(`"quietly use %%s using "%s" , clear"', info.fn)
    
    info.dsvars = J(1, info.nvar, 0)
    
    chunk_varlist(info)
    
    /*
        The calls to st_ds_findname()
        assure that even on errors, we return in r():
            
            r(k)          := number of variables in <filename>
            r(chunks)     := number of <varlists>
            r(varlist[#]) := variable names in chunk #
            r(varspec)    := <void> in case of error
    */
    
    st_ds_findname("preserve", info, 0)
    for (i=1; i<=info.nchunk; ++i) {
        
        st_ds_findname(sprintf(usecmd, info.chunks[i]), info, 0)
        if (info.ds       != "") st_ds_findname(info.ds, info)
        if (info.findname != "") st_ds_findname(info.findname, info)
        if ( all(info.dsvars) ) break
        
    }
    st_ds_findname("restore", info, 0)
    
    if ( !info.old_syntax ) 
        info.vartag = info.vartag :* (info.dsvars:>0)
    else 
        info.vartag = info.vartag :+ (info.dsvars:>0)
}


        /*  _____________________________  get r(varlist)  */
void st_ds_findname(

    string scalar  cmdline, 
    `usesome_info' info, 
  | real  scalar   getvarlist
  
  )
{
    real   scalar    rc
    real   scalar    c
    string rowvector rvarlist
    
    
    if ( (rc=_stata(cmdline)) ) {
        
        info.varspec = ""
        rreturn(info)
        exit( rc )
        
    }
    
    if ( !getvarlist ) return
    
    c = cols( (rvarlist=tokens(st_global("r(varlist)"))) )
    while ( c ) info.dsvars = info.dsvars :+ (info.varlist:==rvarlist[c--])
}


        /*  _____________________________  varspec parsing utilities  */
void assert_name(string scalar n, | string scalar ename)
{
    if ( !st_isname(n) ) {
        
        errprintf("%s invalid name\n", (args()>1 ? ename :n))
        exit(198)
        
    }
}


void not_found(string scalar v)
{
    errprintf("variable %s not found\n", v)
    exit(111)
}


    /*  _________________________________  chunk variable list  */
void chunk_varlist(`usesome_info' info)
{
    real scalar maxvar
    real scalar i, j
    
    
    info.nchunk = ceil( info.nvar / (maxvar=c("maxvar")-1) )
    info.chunks = J(1, info.nchunk, "")
    
    for (i=j=1; i<=info.nvar; i=i+maxvar) info.chunks[j++] = 
    invtokens(info.varlist[i..min((i+maxvar-1, info.nvar))])
}


    /*  _________________________________  r()  */
void rreturn(`usesome_info' info)
{
    real scalar i
    
    
    st_rclear()
    
    if ( !info.rresults ) return
    
    if (info.nchunk == .) chunk_varlist(info)
    
    st_numscalar("r(k)"     , info.nvar)
    st_numscalar("r(chunks)", info.nchunk)
    
    if ((i=info.nchunk) == 1) st_global("r(varlist)", invtokens(info.varlist))
    else while ( i ) st_global(sprintf("r(varlist%f)", i), info.chunks[i--])
    st_global("r(varspec)", info.varspec)
}


    /*  _________________________________  use  */
void use_dta(`usesome_info' info)
{
    real scalar rc
    
    
    if ( (rc=_stata(sprintf(`"use %s %s using "%s" , clear %s"', 
    info.varspec, info.ifin, info.fn, info.label))) ) exit( rc )
}


end


exit


/*  _________________________________________________________________________
                                                              version history

2.1.0   03oct2023   support dta formats 120 and 121 (Stata 18)
                    bug fix: multiply -k- may result in non-integers
2.0.1   23sep2021   minor code polish
2.0.0   13may2021   new syntax; old syntax still supported
                    standard -if- and -in- qualifiers
                    new option -noreturn-; not documented
                    support dta formats up to Stata 17 (113--115, 117--119)
                    complete rewrite
1.2.0   22dec2013   fix bug: allow all types of numlists in <varspec>
                    return results in r()
                    allow abbreviations in <varspec>
                    new -if()- option
                    support Stata 13 dta format 117
                    -k- is case-insensitive
                    use Mata to obtain varlists from <filename>
1.1.1   22apr2012   may multiply -k-
1.1.0   23mar2012   -k- may be used in <varspec>
1.0.0   09feb2012   first release on SSC
