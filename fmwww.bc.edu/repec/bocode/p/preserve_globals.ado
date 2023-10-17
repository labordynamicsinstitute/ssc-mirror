*! version 2.2.0  11oct2023
program preserve_globals
    
    version 16.1
    
    if (_caller() > 18) local version "version `=_caller()' :"
    
    gettoken comma_or_colon zero : 0 , parse(",:") quotes
    if ( inlist(`"`comma_or_colon'"', ",", ":") ) {
        
        if (`"`comma_or_colon'"' == ",") {
            
            gettoken     0 zero :    0 , parse(":") quotes
            gettoken colon zero : zero , parse(":") quotes
            
            if (`"`colon'"' != ":") error 198
            
            syntax [ , STRICT ]
            
        }
        
        mata : st_local("0", ustrltrim(st_local("zero")))
        
    }
    
    local global_names : all globals
    
    local i 0
    foreach gmname of local global_names {
        
        local GLOBAL`++i' : copy global `gmname'
        
    }
    
    nobreak {
        
        capture noisily break `version' execute `0'
        local rc = _rc
        
        local i 0
        foreach gmname of local global_names {
            
            global `gmname' : copy local GLOBAL`++i'
            
        }
        
        if ("`strict'" == "strict") delete_new_globals `global_names'
        
        mata : c_locals()
        
    }
    
    exit `rc'
    
end


program execute
    
    /*
        We run the command in a separate namespace
        to protect the local macros in the caller.
    */
    
    version 16.1
    
    tokenize // clear local macros 1, 2, ...
    
    version `=_caller()' : `0'
    
    mata : c_locals_()
    
end


program delete_new_globals
    
    syntax namelist(name = old_global_names)
    
    local new_global_names : all globals
    
    local new_global_names : list new_global_names - old_global_names
    
    foreach gmname of local new_global_names {
        
        global `gmname' // void
        
    }
    
end


/*  _________________________________________________________________________
                                                                     Mata  */

version 16.1


mata :


mata set matastrict   on
mata set mataoptimize on


void c_locals()
{
    string colvector c_locals
    real   scalar    i
    
    
    c_locals = st_dir("local", "macro", "C_LOCAL*")
    
    for (i=rows(c_locals); i; i--) {
        
        c_locals[i] = st_local(c_locals[i])
        st_c_local(
            usubstr(c_locals[i],1,ustrpos(c_locals[i],char(32))-1),
            usubstr(c_locals[i],ustrpos(c_locals[i],char(32))+1,.)
            )
        
    }
}


void c_locals_()
{
    string colvector lmnames
    real   scalar    i
    
    
    lmnames = st_dir("local", "macro", "*")
    
    if (st_local("0") == st_c_local("0")) 
        lmnames = select(lmnames, (lmnames:!="0"))
    
    for (i=rows(lmnames); i; i--) {
        
        st_local(lmnames[i], lmnames[i]+char(32)+st_local(lmnames[i]))
        st_c_local("C_LOCAL"+strofreal(i,"%18.0g"), st_local(lmnames[i]))
        
    }
}


end


exit


/*  _________________________________________________________________________
                                                              version history

2.2.0   11oct2023   bug fix: pass thru caller version 
                        if and only if version > 18
2.1.0   10oct2023   bug fix: pass thru caller version
                    new option -strict-
2.0.0   08oct2023   bug fix: handle left single quotes
                    pass local macros thru to caller
                    Stata 16.1 or higher is required
1.1.0   25may2023   bug fix: handle nested double quotes
                    do not error out when a global macro cannot be restored
                    no longer use temporary file
                    posted on Statalist
1.0.0   25may2023   initial draft; posted on Statalist