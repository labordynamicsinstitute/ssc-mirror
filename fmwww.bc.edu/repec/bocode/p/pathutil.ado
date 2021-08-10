*! version 2.2.0 19nov2020 daniel klein
program pathutil , sclass
    version 11.2
    
    gettoken subcmd 0 : 0
    
    if ( !inlist(`"`subcmd'"',    ///
        "split",                  ///
        "pieces",                 ///
        "join",                   ///
        "basename",               /// not documented
        "suffix",                 /// not documented
        "rmsuffix",               /// not documented
        "to", /* synonym */ "of", ///
        "confirm")                ///
       )                              err_subcmd `subcmd'
    else if ("`subcmd'" != "confirm") sreturn clear
    else { // confirm
        gettoken what zero : 0 , qed(quotes)
        if ( `quotes' ) local what // void
        else {
            local 0 , `what'
            syntax [ , NEW URL ISURL ABSolute ISABSolute * ]
            if      ("`isurl'" != "")                local what url
            else if ("`absolute'`isabsolute'" != "") local what abs
            if ( mi(`"`options'"') ) local 0 : copy local zero
            else {
                local 0 `what' `zero'
                local what // void
            }
        }
    }
    
    if ("`subcmd'" == "of") local subcmd to
    
    gettoken path void : 0 , qed(quotes)
    if ( mi(`"`path'"') ) {
        if      ("`subcmd'" == "confirm")            err_path_expected   7 
        else if ( (!`quotes') & ("`subcmd'"!="to") ) err_path_expected 198
    }
    
    if ("`subcmd'" == "join") {
        gettoken path2 void : void , qed(quotes)
        if ( (!`quotes') & mi(`"`path2'"') )         err_path_expected 198
    }
    
    if (`"`void'"' != "") {
        display as err `"invalid `void'"'
        exit 198
    }
    
    mata : pathutil_`subcmd'(st_local("path"))
end

program err_subcmd
    sreturn clear
    if ( mi("`0'") ) display as err "subcommand required"
    else         display as err `"invalid subcommand `0'"'
    exit 198
end

program err_path_expected
    display as err "'' found where path expected"
    exit `1'
end

version 11.2

mata :

mata set matastrict on

void pathutil_split(string scalar path)
{
    string scalar directory
    string scalar filename
    string scalar suffix
    
    suffix = pathsuffix(path)
    path   = pathrmsuffix(path)
    
    if ((filename=pathbasename(path)) == "") directory = path
    else {
        pragma unset directory
        pathsplit(path, directory, filename)
    }
    
    st_global("s(directory)", directory)
    st_global("s(suffix)",       suffix)
    st_global("s(extension)",    suffix)
    st_global("s(filename)",   filename)
}

void pathutil_pieces(string scalar path)
{
    string scalar piece
    real   scalar i
    
    pragma unset piece
    
    i = 0
    while (path != "") {
        pathsplit(path, path, piece)
        if ( anyof(("/", "\"), piece) ) continue
        st_global("s(piece" + strofreal(++i) + ")", piece)
    }
    
    st_global("s(pieces)", strofreal(i))
}

void pathutil_join(string scalar path) st_global("s(path)", pathjoin(path, st_local("path2")))
void pathutil_basename(string scalar path) st_global("s(basename)", pathbasename(path))
void pathutil_suffix(string scalar path) st_global("s(suffix)", pathsuffix(path))
void pathutil_rmsuffix(string scalar path) st_global("s(path)", pathrmsuffix(path))

void pathutil_to(string scalar path)
{
    string scalar pwd
    string scalar piece
    
    pwd = c("pwd")
    
    pragma unset piece
    
    while (pwd != "") {
        pathsplit(pwd, pwd, piece)
        if (anyof((piece, pwd), path)) {
            st_global("s(path)", pathjoin(pwd, piece))
            return
        }
    }
    
    pathutil_err(601, "%s not found in current working directory", path)
}

void pathutil_confirm(string scalar path)
{
    string scalar what
    
    what = st_local("what")
    
    if ( anyof(("", "new"), what) ) {
        if (pathsuffix(path) != "") pathutil_err(698, "%s not a directory", path)
        if ( direxists(path) ) {
            if (what == "new") pathutil_err(602, "directory %s already exists", path)
        }
        else if (what == "" )  pathutil_err(601, "directory %s not found", path)
    }
    else if ( (what=="url") & !pathisurl(path) ) pathutil_err(669, "%s not URL", path)
    else if ( (what=="abs") & !pathisabs(path) ) pathutil_err(698, "%s not absolute path", path)
}


void pathutil_err(real scalar rc, string scalar msg, string scalar path)
{
    errprintf(msg+"\n", path)
    exit(rc)
}

end
exit

/* ---------------------------------------
2.2.0 19nov2020 new subcommands -basename-, -[rm]suffix-; not documented
                rewrite; code polish
                no version in path.ado
2.1.1 21may2018 renamed pathutil
                code polish
2.1.0 03aug2016 new subcommands -pieces- and -of-
2.0.0 03aug2016 improved code subcommand -split-
                omitting path is now an error
                new subcommand -confirm- (nclass)
                released on SSC
1.0.0 06apr2016 initial version (not released)
