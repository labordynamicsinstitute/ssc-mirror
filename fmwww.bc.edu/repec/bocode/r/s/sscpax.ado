#delim ;
prog def sscpax, rclass;
version 10.0;
/*
 Input a list of SSC package names
 and describe, install, or uninstall them.
*!Author: Roger Newson
*!Date: 14 November 2021
*/


syntax namelist [ , Action(name) SOrt all replace ];
*
 action() specifies whether to describe, install,
   or uninstall the packages.
 sort specifies that packages will be processed in alphanumeric order.
 all specifies that ancillary files will be copied
   to the current working folder (if action(install) is specified).
 replace specifies that existing packages of the same names will be replaced
   (if action(install) is specified).
*;


*
 Make namelist unique and sorted
*;
local namelist: list uniq namelist;  
if "`sort'"!="" local namelist: list sort namelist;


*
 Complete the action option
*;
if "`action'"=="" local action "describe";
foreach AC in describe install uninstall {;
  if strpos("`AC'","`action'")==1 local action "`AC'";
};
if !inlist("`action'","describe","install","uninstall") {;
    disp as error "action(`action') not allowed";
        error 498;
};


*
 Process the named packages
*;
local present "";
local absent "";
if "`action'"=="describe" {;
    foreach X in `namelist' {;
        cap noi ssc describe `X';
        if _rc local absent "`absent' `X'";
        else local present "`present' `X'";
    };
  local present: list retokenize present;
  local absent: list retokenize absent;
  disp as text "Packages described: " as result "`present'";
  if "`absent'"!=""
      disp as text "Packages not described: " as result "`absent'";
};
else if "`action'"=="install" {;
    foreach X in `namelist' {;
        cap noi ssc install `X', `replace' `all';
        if _rc local absent "`absent' `X'";
        else local present "`present' `X'";
    };
  local present: list retokenize present;
  local absent: list retokenize absent;
  disp as text "Packages installed: " as result "`present'";
  if "`absent'"!=""
      disp as text "Packages not installed: " as result "`absent'";
};
else if "`action'"=="uninstall" {;
    foreach X in `namelist' {;
        cap noi ssc uninstall `X';
        if _rc local absent "`absent' `X'";
        else local present "`present' `X'";
    };
  local present: list retokenize present;
  local absent: list retokenize absent;
  disp as text "Packages uninstalled: " as result "`present'";
  if "`absent'"!=""
      disp as text "Packages not uninstalled: " as result "`absent'";
};


*
 Return results
*;
retu local present "`present'";
retu local absent "`absent'";


end;