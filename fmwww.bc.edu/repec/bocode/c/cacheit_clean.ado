/*==================================================
project:       Clean all cached commands
Author:        R.Andres Castaneda & Damian Clarke
E-email:       acastanedaa@worldbank.org
               dclarke4@worldbank.org / dclarke@fen.uchile.cl 
url:           
Dependencies:  The World Bank
----------------------------------------------------
Creation Date:     17 December 2024 - 02:48:28
Modification Date:   
Do-file version:    01
References:          
Output:             
==================================================*/

/*==================================================
              0: Program set up
==================================================*/
program define cacheit_clean, rclass

    syntax [anything(name=subcmd)] ///
    [,                   	       /// 
        pause                      ///
        clear                      ///
        replace                    ///
        force                      ///
        dir(string)                ///
        *                          ///
    ] 
    version 16.1


    /*==================================================
        1: clean up cache contents leaving machine clean
    ==================================================*/
    if ("`subcmd'" == "clean")  {
        //Check directory exists
        mata : st_numscalar("direxists", direxists("`dir'"))
        if direxists==0 {
            dis "The indicated directory (`dir') does not exist."
            exit 693
        }
        
        //Double check
        display in yellow "Warning: This will delete all files within `dir'"
        if ("`force'" == "") {
            display in yellow "Do you want to continue? (y/n): " _request(dcheck)
        }
        else global dcheck "y"

        //Clean if indicated
        if "${dcheck}"=="y" cacheit_cleanup, dir(`dir')
        else display "y not indicated.  Operation cancelled."

        //Exit
        return add
        exit
    }


end

//------------ Get Hash based on string 
program define cacheit_cleanup, rclass
	syntax [anything(name=subcmd)], [   ///
	dir(string)                         ///
	]

    local flist: dir "`dir'" files "*"
    foreach f of local flist {
       rm "`dir'/`f'"
    }
    cap rmdir "`dir'"
    if _rc {
        display "Cache files cleaned, but folder could not be removed"
        display "Ensure that `dir' does not contain subfolders"
        error 693
    }
end


cap program drop dirlist
program define dirlist

   syntax , fromdir(string)

   // list of all files in "`fromdir'"
   local flist: dir "`fromdir'" files "*"
   foreach f of local flist {
      rm "`fromdir'/`f'"
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


