/*==================================================
project:       List cached commands
Author:        R.Andres Castaneda & Damian Clarke
E-email:       acastanedaa@worldbank.org
               dclarke4@worldbank.org / dclarke@fen.uchile.cl 
url:           
Dependencies:  The World Bank
----------------------------------------------------
Creation Date:     29 December 2024 - 19:52:49
Modification Date:   
Do-file version:    01
References:          
Output:             
==================================================*/

/*==================================================
              0: Program set up
==================================================*/
program define cacheit_list, rclass

    syntax [anything(name=subcmd)] ///
    [,                   	       /// 
        pause                      ///
        dir(string)                ///
    ] 
    version 16.1

    /*==================================================
        1: Print out cached commands
    ==================================================*/
    if ("`subcmd'" == "print")  {
        //Check directory exists
        mata : st_numscalar("direxists", direxists("`dir'"))
        if direxists==0 {
            dis as error `"The indicated directory (`dir') does not exist."'
            exit 693
        }
        mata : st_numscalar("fileexists", fileexists("`dir'/cached_commands.txt"))
        if fileexists==0 {
            disp as error `"No command has been cached in ("`dir'")"'
            exit 693
        }

        //list all cached command history
        type "`dir'/cached_commands.txt",  smcl 

        //Exit
        return add
        exit
    }


end




exit
/* End of do-file */

><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

Notes:
1.
2.
3.


Version Control:


