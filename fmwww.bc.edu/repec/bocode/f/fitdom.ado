*! fitdom version 0.0.0  11/21/2021 Joseph N. Luchman

program define fitdom, eclass //history and version information at end of file

version 12.1

syntax varlist(min = 1 ts fv) if [aw pw iw fw] , [Reg_fd(string) Postestimation(string) Fitstat_fd(string)]

gettoken dv ivs: varlist	//parse varlist line to separate out dependent from independent variables

gettoken reg regopts: reg_fd, parse(",")	//parse reg() option to pull out estimation command options

if strlen("`regopts'") gettoken erase regopts: regopts, parse(",")	//parse out comma if one is present

`reg' `dv' `ivs' [`weight'`exp'] `if', `regopts'	//conduct analysis without independent variables

`postestimation'

ereturn scalar fitstat = `=`fitstat_fd''

end


/* programming notes and history
- fitdom version 0.0.0 - Nov 21, 2021 
----
 */
