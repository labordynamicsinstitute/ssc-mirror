*! version 1.0.0 15nov2020 daniel klein
program elabel_fcn_encode
    version 11.2
    
    elabel fcncall define elblnamelist 0 : `0'
    
    elabel parse elblnamelist(newlblnamelist) : `elblnamelist'
    
    local lblnamelist : list lblnamelist - newlblnamelist
    local lblnamelist : list uniq lblnamelist
    
    syntax varlist(string) [ if ] [ in ] ///
    [ ,                                  ///
        MODIFY                           ///
        MIN(integer 1)                   ///
        noSORT                           ///
    ]
    
    local varlist : list uniq varlist
    
    marksample touse , novarlist strok
    
    mata : elabel_fcn_encode()
end

version 11.2

mata :

mata set matastrict on

void elabel_fcn_encode()
{
    string       rowvector varlist
    string       colvector strings
    real         scalar    i, j, c
    string       rowvector lnames
    real         colvector values
    string       colvector labels
    
    varlist = tokens( st_local("varlist") )
    
    pragma unset strings
    
    for (i=1; i<=cols(varlist); ++i) 
        strings = (strings\ auniq(st_sdata(., varlist[i], st_local("touse"))))
    
    strings = (st_local("sort") == "nosort") ? auniq(strings) : uniqrows(strings)
    
    if ( !rows((strings=select(strings, (strings:!="")))) ) {
        errprintf("no labels found\n")
        exit(2000)
    }
    
    lnames = tokens( st_local("lblnamelist") )
    
    pragma unset values
    pragma unset labels 
    
    for (i=1; i<=cols(lnames); ++i) {
        c = strtoreal( st_local("min") )
        st_vlload(lnames[i], values, labels)
        values = select(values, ((values:>=c) :& (values:<.)))
        for (j=1; j<=rows(strings); ++j) {
            if (st_vlsearch(lnames[i], strings[j]) != .) continue
            while ( anyof(values, c) ) c++
            st_vlmodify(lnames[i], c++, strings[j])
        }
        if (--c > c("max_N_theory")) {
            errprintf("may not label %f\n", c)
            exit(198)
        }
    }
    
    lnames = tokens( st_local("newlblnamelist") )
    c = strtoreal(st_local("min"))
    for (i=1; i<=cols(lnames); ++i) 
        st_vlmodify(lnames[i], (c::rows(strings)+(c-1)), strings)
}

end
exit
