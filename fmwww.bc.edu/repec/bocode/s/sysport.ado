#delim ;
prog def sysport;
version 16.0;
/*
 Input a list of system directory codewords
 and zip their corresponding directories to a zip file.
*!Author: Roger Newson
*!Date: 06 December 2021
*/


syntax , saving(passthru) [ Dirlist(namelist) ];
*
 saving() specifies a file to save.
 dirlist() specifies a list of names, which must be sysdir codewords.
*;

*
 Check that dirlist is valid
 and convert it to an actual directory list.
*;
if "`dirlist'"=="" local dirlist "plus";
local dirlist=lower(`"`dirlist'"');
local dirlist: list uniq dirlist;
local fsdirlist "";
foreach SD in `dirlist' {;
  local possdir=0;
  foreach PSD in plus personal site oldplace {;
    if strpos("`PSD'","`SD'")==1 {;
      local possdir=1;
      local fsdirlist "`fsdirlist' `PSD'";
      continue, break;
    };
  };
  if `possdir'==0 {;
    disp as error "Illegal system directory: `SD'";
    error 498;
  };
};
local fsdirlist: list uniq fsdirlist;
local asdirlist "";
foreach FSD in `fsdirlist' {;
  local asdirlist `"`asdirlist' `"`c(sysdir_`FSD')'"'"';
};


*
 Zip actual system dirlist
*;
zipfile `asdirlist', `saving';


end;