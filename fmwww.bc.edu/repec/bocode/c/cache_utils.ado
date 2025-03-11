/*==================================================
project:       Auxiliary functions for the whole cache package
Author:        R.Andres Castaneda 
E-email:       acastanedaa@worldbank.org
url:           
Dependencies:  The World Bank
----------------------------------------------------
Creation Date:     2024-09-27 
Modification Date:   
Do-file version:    01
References:          
Output:             
==================================================*/

/*==================================================
              0: Program set up
==================================================*/
program define cache_utils, rclass
    version 16.1
    syntax [anything(name=subcmd)]   ///
        [,                   	     /// 
            pause                    ///
            clear                    ///
            replace                  ///
            force                    ///
            *                        ///
        ] 


    /*==================================================
        1:  clean locals
    ==================================================*/
    if ("`subcmd'" == "clean_local")  {
        cache_utils_clean_local, `options'
        return add
        exit
    }



    /*==================================================
        2: 
    ==================================================*/




end 


program define cache_utils_clean_local, rclass
    syntax [anything(name=subcmd)], [   ///
        text(string)               ///
        strip                    ///
        ]

    if ("`strip'" != "") local text:  subinstr local text ":" "" 
    local text = strtrim("`text'")
    local text = stritrim("`text'")

    return local text =  "`text'"
    
end 

exit
/* End of do-file */

><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

Notes:
1.
2.
3.


Version Control:


