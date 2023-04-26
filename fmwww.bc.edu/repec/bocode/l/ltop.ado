#delim ;
program define ltop, sortpreserve;
version 16.0;
*
 Input a weight expression containing line weights
 and (optionally) a list of internal by-variables
 and output a numeric variable containing page sequence numbers.
*!Author: Roger Newson
*!Date: 24 April 2023
*;

syntax newvarname  [if] [in] [fweight pweight aweight iweight /]
  [ , MAXlperp(numlist min=1 max=1 >0) by(varlist) iby(varlist) ];
/*
  maxlperp() gives maximum number of lines per page.
  by() specifies a varlist specifying by-groups,
    within which page numbers are defined.
  iby() specifies a varlist specifying inner by-groups,
    which must be within pages and not split between pages,
    and which defaults to the virtual variable _n.
*/

*
 Set defaults
*;
if `"`exp'"'=="" local exp "1";
if "`maxlperp'"=="" local maxlperp=50;

*
 Mark sample and sort by to-use indicator and by-group
*;
marksample touse, novarlist;
sort `touse' `by', stable;

*
 Set default iby() iption
*;
if "`iby'"=="" {;
  tempvar ibyvar;
  qui {;
   by `touse' `by': gene long `ibyvar'=_n if `touse';
    compress `ibyvar';
  };
  local iby "`ibyvar'";
};

*
 Sort dataset by to-use indicator, by-group, and iby-group
*;
sort `touse' `by' `iby', stable;

*
 Generate sum of weights variable by iby-group,
 and fail if it is ever greater than maxlperp() option.
*;
tempvar sumwtvar;
qui by `touse' `by' `iby': egen `sumwtvar'=total(`exp') if `touse';
cap assert `sumwtvar'<=`maxlperp' if `touse';
if _rc {;
  disp as error
    "At least 1 iby-group total weight"
    _n "is greater than the maximum lines per page of:"
    _n "`maxlperp'";
  error 498;
};

*
 Generate iby-group first-observation indicator
 and iby-group start-observation position within by-group.
*;
tempvar ifirst istart;
qui {;
  by `touse' `by' `iby': gene byte `ifirst'=_n==1 if `touse';
  by `touse' `by': gene long `istart'=_n if `touse' & `ifirst';
  compress `istart';
  by `touse' `by' `iby': replace `istart'=`istart'[1] if `touse';
};

*
 Create cumulative sum of weights variable (within page),
 new page indicator variable,
 and page sequence number variable.
*;
* Cumulative sum of weights variable (within page) *;
tempvar cumwtvar;
qui {;
  gene double `cumwtvar'=.;
  by `touse' `by': replace `cumwtvar'=cond(_n==1,
    `sumwtvar',
    cond(`ifirst',
      cond(`sumwtvar'+`cumwtvar'[_n-1]>`maxlperp',
        `sumwtvar',
        `sumwtvar'+`cumwtvar'[_n-1]
        ),
      `cumwtvar'[`istart']
      )
    )
    if `touse';
  compress `cumwtvar';
};
* New page indicator variable *;
tempvar newpagevar;
qui {;
  gene byte `newpagevar'=0 if `touse';
  by `touse' `by': replace `newpagevar'=cond(_n==1,
       1,
       cond(`ifirst' & (`sumwtvar'+`cumwtvar'[_n-1]>`maxlperp'),
         1,
         0
       )
     )
     if `touse';
};
* Page number variable *;
tempvar pagenumvar;
qui {;
  by `touse' `by': gene double `pagenumvar'=sum(`newpagevar') if `touse';
  compress `pagenumvar';
};

*
 Rename page number variable
*;
rename `pagenumvar' `varlist';
lab var `varlist' "Page number";

end;
