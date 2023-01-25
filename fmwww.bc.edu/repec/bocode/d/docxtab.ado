#delim ;
prog def docxtab, rclass;
version 16.0;
*
 List the variables in varlist as a table
 to a putdocx table.
 *! Author: Roger Newson
*! Date: 20 January 2023
*;

syntax [ varlist (min=1) ] [if] [in] , TABlename(name)
 [
  HEADChars(namelist) FOOTChars(namelist)
  HEADformat(string asis) FOOTFormat(string asis)
  TCOLchars(namelist)
  TROWseq(name)
  varnames obsno title(passthru) note(passthru)
  *
 ];
*
  varlist specifies variables to be written to table.
  tablename() specifies the name of a table to be generated.
  headchars() is a list of variable characteristics containing header rows.
  footchars() is a list of variable characteristics containing footer rows.
  headformat() is a list of cell format options for header rows.
  footformat() is a list of cell format options for footer rows.
  tcolchars() is a list of variable characteristics
    containing corresponding column formats.
  trowseq() specifies a generated variable
    containing the table row sequence for each observation.
  Other options (including varnames, obsno, title(), and note()) are passed to putdocx table.
*;


* Count variables and mark sample *;
local nvar: word count `varlist';
marksample touse, novarlist strok;


*
 Check that table row sequence variable is new if it is requested
*;
if "`trowseq'"!="" conf new var `trowseq';


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
* Initialise first and last head rows *;
if `nhead'==0 {;
  scal `fhead'=.;
  scal `lhead'=.;
};
else {;
  scal `fhead'=`nrow'+1;
  scal `lhead'=`nrow'+`nhead';
  scal `nrow'=`lhead';
};
* Initialise first and last body rows *;
if `nbody'==0 {;
  scal `fbody'=.;
  scal `lbody'=.;
};
else {;
  scal `fbody'=`nrow'+1;
  scal `lbody'=`nrow'+`nbody';
  scal `nrow'=`lbody';
};
* Initialise first and last foot rows *;
if `nfoot'==0 {;
  scal `ffoot'=.;
  scal `lfoot'=.;
};
else {;
  scal `ffoot'=`nrow'+1;
  scal `lfoot'=`nrow'+`nfoot';
  scal `nrow'=`lfoot';
};
* Update if title() option is present *;
if `"`title'"'!="" {;
  foreach X in nrow lfoot ffoot lhead fhead lbody fbody {;
    scal ``X''=``X''+1;
  };
};
* Update if note() option is present *;
if `"`note'"'!="" scal `nrow'=`nrow'+1;


* 
 Create initial table with just internal cells
 and title and note rows (if present)
*;
putdocx table `tablename'=data(`varlist') if `touse',
  `varnames' `obsno' `title' `note' `options';


*
 Count rows and columns
 (which may be affected by the options varnames, title, and/or note for rows
 and obsno for columns)
*;
qui putdocx describe `tablename';
scal `nrow'=r(nrows);
scal `ncol'=r(ncols);


*
 Add head char rows
*;
tempname cellcur;
if `nhead'>0 {;
  if `"`title'"'=="" {;
    * Add rows at top of table *;
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
  else {;
    * Add rows after title row *;
    forv i1=1(1)`=`nhead'' {;
      local charcur: word `i1' of `headchars';
      putdocx table `tablename'(1, .), addrows(1, after);
      forv i2=1(1)`nvar' {;
        local varcur: word `i2' of `varlist';
        mata: st_strscalar("`cellcur'",st_global("`varcur'[`charcur']"));
        local i3=`ncol'-`nvar'+`i2';
        putdocx table `tablename'(2, `i3') = (`cellcur');
      };
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
  if `"`note'"'=="" {;
    * Add rows after end of table *;
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
  else {;
    * Add rows before note row *;
    local nrowtemp=`nrow';
    forv i1=1(1)`=`nfoot'' {;
      local charcur: word `i1' of `footchars';
      putdocx table `tablename'(`nrowtemp', .), addrows(1, before);
      local nrowtemp=`nrowtemp'+1;
      forv i2=1(1)`nvar' {;
        local varcur: word `i2' of `varlist';
        mata: st_strscalar("`cellcur'",st_global("`varcur'[`charcur']"));
        local i3=`ncol'-`nvar'+`i2';
        putdocx table `tablename'(`=`nrowtemp'-1', `i3') = (`cellcur');
      };   
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
  local notepres=`"`note'"'!="";
  scal `ffoot'=`nrow'-`notepres'-`nfoot'+1;
  scal `lfoot'=`nrow'-`notepres';
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
 Use table column characteristics if requested
*;
if "`tcolchars'"!="" {;
  foreach TCC in `tcolchars' {;
    forv i1=1(1)`nvar' {;
      local i2 = `i1' + ("`obsno'"!="");
      local Vcur: word `i1' of `varlist';
      mata: st_local("TCCcontents",st_global("`Vcur'[`TCC']"));
      cap putdocx table `tablename'(.,`i2') , `TCCcontents';
    };  
  };
};


*
 Add table row sequence variable if requested
*;
if "`trowseq'"!="" qui {;
  gene byte `trowseq'=1 if `touse';
  replace `trowseq'=sum(`trowseq')+`nhead' if `touse';
  if `"`varnames'"'!="" replace `trowseq'=`trowseq'+1 if `touse';
  if `"`title'"'!="" replace `trowseq'=`trowseq'+1 if `touse';
  lab var `trowseq' "Table row sequence number";
};


*
 Return results
*;
foreach X in ncol nrow nfoot lfoot ffoot nhead lhead fhead nbody lbody fbody {;
  return scalar `X'=``X'';
};
return local varlist "`varlist'";
* Table column sequences *;
local tcolseq "";
forv i1=1(1)`nvar' {;
  local i2 = `i1' + ("`obsno'"!="");
  local tcolseq "`tcolseq' `i2'";
};  
local tcolseq: list clean tcolseq;
return local tcolseq "`tcolseq'";


end;
