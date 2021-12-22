#delim ;
prog def docxtab, rclass;
version 16.0;
*
 List the variables in varlist as a table
 to a putdocx table.
 *! Author: Roger Newson
*! Date: 04 December 2021
*;

syntax [ varlist (min=1) ] [if] [in] , TABlename(name)
 [
  HEADChars(namelist) FOOTChars(namelist)
  HEADformat(string asis) FOOTFormat(string asis) *
 ];
*
  varlist specifies variables to be written to table.
  tablename() specifies the name of a table to be generated.
  headshars() is a list of variable characteristics containing header rows.
  footchars() is a list of variable characteristics containing footer rows.
  headformat() is a list of cell format options for header rows.
  footformat() is a list of cell format options for footer rows.
  Other options are passed to putdocx table.
*;


* Count variables and mark sample *;
local nvar: word count `varlist';
marksample touse, novarlist strok;


*
 Scalars to be eventually output
*;
tempname nrow ncol nfoot lfoot ffoot nhead lhead fhead nbody lbody fbody;
summ `touse', meanonly;
scal `nbody'=r(sum);
if "`headchars'"=="" {;
  scal `nhead'=0;
};
else {;
  local nheadl: word count `headchars';
  scal `nhead'=`nheadl';
};
if "`footchars'"=="" {;
  scal `nfoot'=0;
};
else {;
  local nfootl: word count `footchars';
  scal `nfoot'=`nfootl';
};
* Initialise cumulative number of rows *;
scal `nrow'=0;
* First and last head rows *;
if `nhead'==0 {;
  scal `fhead'=.;
  scal `lhead'=.;
};
else {;
  scal `fhead'=`nrow'+1;
  scal `lhead'=`nrow'+`nhead';
  scal `nrow'=`lhead';
};
* First and last body rows *;
if `nbody'==0 {;
  scal `fbody'=.;
  scal `lbody'=.;
};
else {;
  scal `fbody'=`nrow'+1;
  scal `lbody'=`nrow'+`nbody';
  scal `nrow'=`lbody';
};
* First and last foot rows *;
if `nfoot'==0 {;
  scal `ffoot'=.;
  scal `lfoot'=.;
};
else {;
  scal `ffoot'=`nrow'+1;
  scal `lfoot'=`nrow'+`nfoot';
  scal `nrow'=`lfoot';
};


* 
 Create initial table with just internal cells
*;
putdocx table `tablename'=data(`varlist') if `touse', `options';


*
 Count rows and columns
 (which may be affected by the options varnames and obsno,
 respectively)
 and modify output scalars for foot rows accordingly.
*;
qui putdocx describe `tablename';
scal `nrow'=r(nrows);
scal `ncol'=r(ncols);


*
 Add head char rows
*;
tempname cellcur;
if `nhead'>0 {;
  forv i1=`=`nhead''(-1)1 {;
    local charcur: word `i1' of `headchars';
    putdocx table `tablename'(1, .), addrows(1, before);
    forv i2=1(1)`nvar' {;
      local varcur: word `i2' of `varlist';
      mata: st_strscalar("`cellcur'",st_global("`varcur'[`charcur']"));
      local i3=`ncol'-`nvar'+`i2';
      putdocx table `tablename'(1, `i3') = (`cellcur');
    };
  };
};


*
 Count rows and columns again
*;
qui putdocx describe `tablename';
scal `nrow'=r(nrows);
scal `ncol'=r(ncols);


*
 Add foot char rows
*;
tempname cellcur;
if `nfoot'>0 {;
  local nrowtemp=`nrow';
  forv i1=1(1)`=`nfoot'' {;
    local charcur: word `i1' of `footchars';
    putdocx table `tablename'(`nrowtemp', .), addrows(1, after);
    local nrowtemp=`nrowtemp'+1;
    forv i2=1(1)`nvar' {;
      local varcur: word `i2' of `varlist';
      mata: st_strscalar("`cellcur'",st_global("`varcur'[`charcur']"));
      local i3=`ncol'-`nvar'+`i2';
      putdocx table `tablename'(`nrowtemp', `i3') = (`cellcur');
    };
  };
};


*
 Count rows and columns again
*;
qui putdocx describe `tablename';
scal `nrow'=r(nrows);
scal `ncol'=r(ncols);
if `nfoot'>0 {;
  scal `ffoot'=`nrow'-`nfoot'+1;
  scal `lfoot'=`nrow';
};


*
 Add header and footer format options if required
*;
if `nhead'>0 & `"`headformat'"'!="" {;
  putdocx table `tablename'(`=`fhead''/`=`lhead'',.), `headformat';
};
if `nfoot'>0 & `"`footformat'"'!="" {;
  putdocx table `tablename'(`=`ffoot''/`=`lfoot'',.), `footformat';
};


*
 Return results
*;
foreach X in ncol nrow nfoot lfoot ffoot nhead lhead fhead nbody lbody fbody {;
  return scalar `X'=``X'';
};


end;
