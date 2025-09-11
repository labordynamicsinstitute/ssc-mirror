*! version 1.0.1  13aug2025
program markobs
    
    version 11.2
    
    capture syntax varlist(ts fv) [ , * ]
    if ( _rc ) {
        
        gettoken newmarkvar 0 : 0
        
        nobreak {
            
            mark `newmarkvar' `macval(0)'
            
            char `newmarkvar'[markobs] OK
            
        }
        
        exit
        
    }
    
    gettoken markvar : varlist
    
    local OK : char `markvar'[markobs]
    
    if ("`OK'" != "OK") {
        
        display as err "`markvar' not created by markobs"
        exit 498
        
    }
    
    markout `macval(0)'
    
end


exit


/*  _________________________________________________________________________

1.0.1   13aug2025   fix error message
1.0.0   12aug2025   release on GitHub   
