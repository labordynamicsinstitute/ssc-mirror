*! version 1.3.0  07oct2024
program encodelabel
    
    version 11.2
    
    syntax varname(string) [ if ] [ in ]              ///
    , /* { Generate(name) | REPLACE  } */ Label(name) ///
    [                                                 ///
        Generate(name)                                ///
        REPLACE                                       ///
        DEfine                                        ///
        MIN(integer 1)                                ///
        noSORT                                        ///
    ]
    
    if ("`replace'" == "replace") {
        
        if ("`generate'" != "") {
            
            display as err "only one of generate() or replace allowed"
            exit 198
            
        }
        
        tempvar generate
        
    }
    else if ("`generate'" == "") {
        
        display as err "option generate() or replace required"
        exit 198
        
    }
    else confirm new variable `generate'
    
    tempname tmplabel
    
    capture label copy `label' `tmplabel'
    if ( _rc ) {
        
        if ( ("`define'"!="define") | (_rc!=111) ) ///
            label copy `label' `tmplabel'
            // NotReached
        
    }
    
    marksample touse , strok
    
    mata : encodelabel("`varlist'","`touse'","`tmplabel'",`min',"`sort'")
    
    nobreak {
        
        encode `varlist' if `touse' , generate(`generate') label(`tmplabel')
        
        label copy `tmplabel' `label' , replace
        
        label values `generate' `label'
        
        if ("`replace'" == "replace") {
            
            order `generate' , after(`varlist')
            drop `varlist'
            rename `generate' `varlist'
            
        }
        
    }
    
end


/*  _________________________________________________________________________
                                                                     Mata  */

version 11.2


mata :


mata set matastrict   on
mata set mataoptimize on


void encodelabel(
    
    string scalar vname, 
    string scalar touse, 
    string scalar lname,
    real   scalar count,
    string scalar nosort
    
    )
{
    real    colvector values
    string  colvector labels
    string  colvector levels
    real    scalar    i
    
    
    pragma unset values
    pragma unset labels
    
    
    levels = st_sdata(.,vname,touse)
    if (nosort != "nosort") 
        levels = uniqrows(levels)
    
    st_vlload(lname,values,labels)
    values = select(values,((values:>=count):&(values:<.)))
    
    for (i=1; i<=rows(levels); i++) {
        
        if (st_vlsearch(lname,levels[i]) != .) 
            continue
        
        while ( anyof(values,count) ) count++
        
        st_vlmodify(lname,count++,levels[i])
        
    }
    
    if (--count > c("max_N_theory")) {
        
        errprintf("may not label %f\n",count)
        exit(198)
        
    }
}


end


exit


/*  _________________________________________________________________________
                                                              version history

1.3.0   07oct2024   new option -define-
1.2.0   06nov2020   add option -nosort-
                    preserve value label
                    rewrite Mata code
1.1.0   30oct2020   add option -replace-
1.0.1   16oct2020   bug fix multiple nullstrings
1.0.0   15oct2020   posted to Statalist
