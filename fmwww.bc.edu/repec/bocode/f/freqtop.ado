#delim ;
prog def freqtop, sortpreserve;
version 16.0;
/*
  Input a frequency variable
  and generate percents and/or cumulative frequencies and/or percents,
  possibly within by-groups.
*! Author: Roger Newson
*! Date: 01 March 2024
*/


syntax [if] [in] [, 
  Freq(name) Percent(name) CFreq(name) CPercent(name)
  PTYpe(string) PFOrmat(string) ZTOtal(string) by(varlist)
  FAST
  replace
  ];
/*
 freq() specifies the input frequency variable999
 percent() specifies the output percent variable.
 cfreq() specifies the output cumulative frequency variable.
 cpercent() zpecifies the output cumulative percent variable.
 ptype() specifies the storage type for percent output variables.
 pformat() specifies the display format for percent output variables.
 ztotal() specifies the value (usually missing) for percents using zero totals.
 fast specifies that freqtop will do no extra work to preserve the input dataset
  in the event of failure.
 replace specifies that variables with the same names as the output variables
  will be replaced.
*/


*
 Set default input and output options
*;
if "`freq'"=="" {;
  local freq "_freq";
};
cap conf numeric var `freq';
if _rc {;
  disp as error `"Illegal freq(`freq')"';
  error 498;
};
if "`percent'"=="" {;
  local percent "_percent";
};


* Check for name clashes between input and/or output variables *;
local iovars "`freq' `percent' `cfreq' `cpercent'";
local Niovar: word count `iovars';
local iovars: list uniq iovars;
local Niovar2: word count `iovars';
if `Niovar2'!=`Niovar' {;
  disp as error "Name clashes between input and output variables:"
    _n as error `"freq(`freq') percent(`percent') cfreq(`cfreq') cpercent(`cpercent')"';
  error 498;
};


if "`fast'"=="" {;
  preserve;
};


marksample touse;
sort `touse' `by', stable;

*
 Set bybyvars macro.
*;
local bybyvars "by `touse' `by':";


* Default type for percent variables *;
if "`ptype'" == "" {;
  local ptype "float";
};


* Default format for percent variables *;
if `"`pformat'"'=="" {;
  local pformat "%8.2f";
};
cap conf numeric format `pformat';
if _rc {;
  disp as error `"Illegal pformat(`pformat')"';
  error 498;
};


* Default value for percents with zero totals *;
if "`ztotal'"=="" local ztotal=.;
tempname sztotal;
cap mata: st_numscalar("`sztotal'",`ztotal');
if _rc {;
  disp as error `"Illegal ztotal(`ztotal')"';
  error 498;
};


* Default names for percent and cumulative frequency variables *;
if "`percent'"=="" {;
  local percent "_percent";
};
if "`cfreq'"=="" & "`cpercent'"!="" {;
  tempvar tempcfreq;
  local cfreq "`tempcfreq'";
};


* Evaluate percent and cumulative frequency variables *;
if "`replace'"!="" {;
  foreach Y in `percent' `cfreq' `cpercent' {;
    cap drop `Y';
  };	  
};
tempvar Ninbygrp;
qui {;
  `bybyvars' egen double `Ninbygrp'=total(`freq') if `touse';
  gene `ptype' `percent'=cond(`Ninbygrp'==0,`ztotal',(100*`freq')/`Ninbygrp') if `touse';
  lab var `percent' "Percent";
  format `percent' `pformat';
  if "`cfreq'"!="" {;
    `bybyvars' gene double `cfreq'=sum(`freq') if `touse';
    lab var `cfreq' "Cumulative frequency";
  };
  if "`cpercent'"!="" {;
    `bybyvars' gene `ptype' `cpercent'=cond(`Ninbygrp'==0,`ztotal',100*sum(`freq')/`Ninbygrp') if `touse';
    lab var `cpercent' "Cumulative percent";
    format `cpercent' `pformat';
  };
  drop `Ninbygrp';
};


*
 Compress percent and cumulative frequency variables
 to minimum type possible without loss of precision
*;
qui compress `percent' `cfreq' `cpercent';


if "`fast'"=="" {;
  restore, not;
};


end;

