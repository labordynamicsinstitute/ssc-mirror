#delim ;
prog def pcontract;
version 8.0;
/*
  Extended version of -contract- with percentages
  and (optionally) cumulative frequencies and percentages.
*! Author: Roger Newson
*! Date: 31 July 2003
*/

syntax varlist [fweight] [in] [if] [, Freq(name) Percent(name) CFreq(name) CPercent(name) FLOAT FORMat(string) * ];

* Type and format for generated numeric variables *;
if "`float'" == "" {;
  local numtype "double";
};
else {;
  local numtype "float";
};
if "`format'"=="" {;
    local format "%8.2f";
};

* Default names for generated variables *;
if "`freq'"=="" {;local freq "_freq";};
if "`percent'"=="" {;local percent "_percent";};
if "`cfreq'"=="" & "`cpercent'"!="" {;tempvar cfreq;};

preserve;

contract `varlist' [`weight' `exp'] `in' `if' , freq(`freq') `options' ;
order `varlist';

* Generate generated variables *;
qui {;
  summ `freq';
  local Ntot=r(sum);
  gene `numtype' `percent'=(100*`freq')/`Ntot';
  lab var `percent' "Percent";
  format `percent' `format';
  if "`cfreq'"!="" {;
    gene `numtype' `cfreq'=sum(`freq');
    lab var `cfreq' "Cumulative frequency";
  };
  if "`cpercent'"!="" {;
    gene `numtype' `cpercent'=(100*`cfreq')/`Ntot';
    lab var `cpercent' "Cumulative percent";
    format `cpercent' `format';
  };
  compress `percent' `cfreq' `cpercent';
};

restore,not;

end;
