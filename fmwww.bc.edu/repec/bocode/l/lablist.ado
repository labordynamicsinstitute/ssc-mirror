#delim ;
prog def lablist, rclass;
version 10.0;
/*
 List value labels (if possible) for variables in a varlist.
*!Author: Roger Newson
*!Date: 05 November 2015
*/

syntax [varlist] [, VARlabel noUNlabelled ];

*
 List labels for each variable with a value label
*;
foreach X of var `varlist' {;
  local Xlab: value label `X';
  if "`Xlab'"!="" | "`unlabelled'"!="nounlabelled" {;
    disp _n as text "Variable: " as result "`X'";
    if "`varlabel'"!="" {;
      local Xvarlab: variable label `X';
      if `"`Xvarlab'"'=="" {;
        disp as text "No variable label present";      
      };
      else {;
        disp as text "Variable label: " as result `"`Xvarlab'"';
      };
    };
    if `"`Xlab'"'=="" {;
      disp as text "No value label present";
    };
    else {;
      disp as text "Value label: " as result "`Xlab'";
      retu clear;
      lab list `Xlab';
      retu add;
    };
  };
};

end;
