#delim ;
program define xcontract;
version 16.0;
/*
  Extended version of -contract- with by-groups,
  percentages within by-group,
  cumulative frequencies and percentages within by-group,
  and an output data set that can be listed to the Stata log,
  saved to a disk file, or written to memory
  (overwriting any pre-existing data set in memory).
  This program contains re-engineered code
  originally derived from official Stata's -contract- and -fillin-.
*! Author: Roger Newson
*! Date: 01 March 2024
*/

syntax varlist [if] [in] [fw aw pw iw] [,  LIst(string asis) FRAme(string asis) SAving(string asis) noREstore FAST FList(string)
  Freq(name) Percent(name) CFreq(name) CPercent(name) ZTOtal(passthru) PTYpe(passthru) PFOrmat(passthru)
  by(varlist)
  IDNum(string) NIDNum(name) IDStr(string) NIDStr(name)
  FOrmat(string)
  Zero noMISS ];
/*

Output-destination options:

-list- contains a varlist of variables to be listed,
  expected to be present in the output data set
  and referred to by the new names if REName is specified,
  together with optional if and/or in subsetting clauses and/or list_options
  as allowed by the list command.
-frame-  specifies a Stata data frame in which to create the output data set.
-saving- specifies a data set in which to save the output data set.
-norestore- specifies that the pre-existing data set
  is not restored after the output data set has been produced
  (set to norestore if FAST is present).
-fast- specifies that -xcontract- will not preserve the original data set
  so that it can be restored if the user presses Break
  (intended for use by programmers).
  The user must specify at least one of the four options
  list, saving, norestore and fast,
  because they specify whether the output data set
  is listed to the log, saved to a disk file,
  written to the memory (destroying any pre-existing data set),
  or multiple combinations of these possibilities.
-flist- is a global macro name,
  belonging to a macro containing a filename list (possibly empty),
  to which -xcontract- will append the name of the data set
  specified in the SAving() option.
  This enables the user to build a list of filenames
  in a global macro,
  containing the output of a sequence of model fits,
  which may later be concatenated using dsconcat (if installed) or append.

Output-variable options:

-freq- is the name of the frequency variable (defaulting to _freq).
-percent- is the name of the percent variable (defaulting to _percent).
-cfreq- is the name of the cumulative frequency variable
  (created only if specified).
-cpercent- is the name of the cumulative percent variable
  (created only if specified).
-ptype- is the storage type for generated percentage variable(s)
  (defaulting to -float-).
-pformat- specifies a format for output percent variables.
-ztotal()- specifies a value (usually missing) for percents from zero totals.
-by- contains a list of by-variables.
-idnum- is an ID number for the output data set,
  used to create a numeric variable idnum in the output data set
  with the same value for all observations.
  This is useful if the output data set is concatenated
  with other output data sets using -dsconcat- (if installed) or -append-.
-nidnum- specifies a name for the numeric ID variable (defaulting to -idnum-).
-idstr- is an ID string for the output data set,
  used to create a string variable (defaulting to -idstr-) in the output data set
  with the same value for all observations.
-nidstr- specifies a name for the numeric ID variable (defaulting to -idstr-).
-format- contains a list of the form varlist1 format1 ... varlistn formatn,
  where the varlists are lists of variables in the output data set
  and the formats are formats to be used for these variables
  in the output data sets.

Other options:

-zero- specifies that combinations of values of -varlist- with zero frequencies
  are to be included in the output data set.
-nomiss- specifies that combinations of values of -varlist- with missing values
  are not to be included in the output data set.
*/

*
 Make varlists unique
*;
local varlist: list uniq varlist;

*
 Set restore to norestore if fast is present
 and check that the user has specified one of the four options:
 list and/or saving and/or norestore and/or fast.
*;
if "`fast'"!="" {;
    local restore="norestore";
};
if (`"`list'"'=="")&(`"`frame'"'=="")&(`"`saving'"'=="")&("`restore'"!="norestore")&("`fast'"=="") {;
    disp as error "You must specify at least one of the five options:"
      _n "list(), frame(), saving(), norestore, and fast."
      _n "If you specify list(), then the new data set is listed."
      _n "f you specify frame(), then the new data set is output to a data frame."
      _n "If you specify saving(), then the new data set is output to a disk file."
      _n "If you specify norestore and/or fast, then the new data set is created in the memory,"
      _n "and any existing data set in the memory is destroyed."
      _n "For more details, see {help xcontract:on-line help for xcontract}.";
    error 498;
};


*
 Parse frame() option if present
*;
if `"`frame'"'!="" {;
  cap frameoption `frame';
  if _rc {;
    disp as error `"Illegal frame option: `frame'"';
    error 498;
  };
  local framename "`r(namelist)'";
  local framereplace "`r(replace)'";
  local framechange "`r(change)'";
  if `"`framename'"'=="`c(frame)'" {;
    disp as error "frame() option may not specify current frame."
      _n "Use norestore or fast instead.";
    error 498;
  };
  if "`framereplace'"=="" {;
    cap noi conf new frame `framename';
    if _rc {;
      error 498;
    };
  };
};


*
 Mark sample for use
 (note that, if the if-expression contains _n or _N,
 then these are interpreted as the observation sequence or observation number, respectively,
 for the whole input data set before any exclusions are made) 
*;
if "`miss'"=="nomiss" {;
  marksample touse , strok;
};
else {;
  marksample touse , strok novarlist;
};


* Fill in -freq- macro value if missing *;
if `"`freq'"' == "" {;
  local freq "_freq";
};


*
 Create weight-expression variable
 (note that, if the weight expression contains _n or _N,
 then these are interpreted as the observation sequence or observation number, respectively,
 for the whole input data set before any exclusions are made)
*;
tempvar expvar;
if `"`exp'"' == "" {;
  local exp "= 1";
};
qui {;
  gene double `expvar' `exp';
  compress `expvar';
};


*
 Beginning of frame block (NOT INDENTED)
*;
local oldframe=c(frame);
tempname tempframe;
frame put `touse' `by' `varlist' `expvar', into(`tempframe');
frame `tempframe' {;


* Keep only observations to be used *;
qui keep if `touse';
if _N == 0 {;
  error 2000;
};


*
  Create data set with 1 obs per value combination
  and variable -freq- containing frequencies
*;
qui {;
  sort `by' `varlist', stable;
  by `by' `varlist' : gen double `freq' = sum(`expvar');
  by `by' `varlist' : keep if _n == _N;
  compress `freq';
  label var `freq' "Frequency";
};


*
  Create variable -bygrp- containing sequential order of by-group
  (to be used in calculating percents
  and filling in zero-frequency combinations)
*;
tempvar bygrp;
if "`by'"=="" {;
  qui gene byte `bygrp'=1;
  local nbygrp=1;
  sort `bygrp';
};
else {;
  gsort `by', gene(`bygrp');
  local nbygrp=`bygrp'[_N];
};


*
 Fill in zero-frequency combinations of -varlist- if requested.
 (This may involve some extra frame processing.)
*;
if "`zero'"!="" {;
  local curframe=c(frame);
  tempname tfr0;
  qui frame copy `curframe' `tfr0', replace;
  if "`by'"!="" {;
    * Save frame of by-groups with data on by-variable values *;
    tempvar inseq inmin inmax;
    tempname byframe;
    keep `bygrp' `by';
    sort `bygrp';
    qui {;
      gene long `inseq'=_n;
      by `bygrp': gene long `inmin'=`inseq'[1];
      by `bygrp': gene long `inmax'=`inseq'[_N];
      drop `inseq';
      by `bygrp': keep if _n==1;
      frame copy `curframe' `byframe', replace;
    };
  };
  drop _all;
  forv i1=1(1)`nbygrp' {;
    tempname tfr`i1';
    qui {;
      if "`by'"=="" {;
        frame `tfr0': frame put `varlist' `freq' `bygrp', into(`tfr`i1'');
      };
      else {;
        frame `byframe' {;
          local inmincur=`inmin'[`i1'];
          local inmaxcur=`inmax'[`i1'];
        };
        frame `tfr0': frame put  `varlist' `freq' `bygrp' in `inmincur'/`inmaxcur',
          into(`tfr`i1'');
      };
      frame `tfr`i1'' {;
        _fillin `varlist';
        replace `freq'=0 if missing(`freq');
        replace `bygrp'=`i1' if missing(`bygrp');
      };
    };
  };
  qui frame drop `tfr0';
  forv i1=1(1)`nbygrp' {;
    qui _appendframe `tfr`i1'', drop;
  };  
  if "`by'"!="" {;
    * Merge in by-variables *;
    qui {;
      sort `bygrp' `varlist';
      tempvar bylinvar;
      frlink m:1 `bygrp', frame(`byframe') gene(`bylinvar');
      foreach X in `by' {;
        cap frget `X'=`X', from(`bylinvar');
      };
      drop `bylinvar';
      frame drop `byframe';
    };
  };
};


* Order and sort output data set *;
order `by' `varlist';
sort `bygrp' `varlist';


*
 Add percent and cumulative frequency variables
*;
if "`percent'"=="" {;
  local percent "_percent";
};
freqtop, freq(`freq') percent(`percent') cfreq(`cfreq') cpercent(`cpercent')
 `ptype' `pformat' by(`bygrp') fast;
 

*
 Keep only wanted variables in final order and sort order
*;
keep `by' `varlist' `freq' `percent' `cfreq' `cpercent';
order `by' `varlist' `freq' `percent' `cfreq' `cpercent';
sort `by' `varlist';
cap drop `tempcfreq';


*
 Create numeric and/or string ID variables if requested
 and move them to the beginning of the variable order
*;
if ("`nidstr'"=="") local nidstr "idstr";
if("`idstr'"!=""){;
    qui gene str1 `nidstr'="";
    qui replace `nidstr'=`"`idstr'"';
    qui compress `nidstr';
    qui order `nidstr';
    lab var `nidstr' "String ID";
};
if ("`nidnum'"=="") local nidnum "idnum";
if("`idnum'"!=""){;
    qui gene double `nidnum'=real("`idnum'");
    qui compress `nidnum';
    qui order `nidnum';
    lab var `nidnum' "Numeric ID";
};


*
 Format variables if requested
*;
if `"`format'"'!="" {;
    local vlcur "";
    foreach X in `format' {;
        if strpos(`"`X'"',"%")!=1 {;
            * varlist item *;
            local vlcur `"`vlcur' `X'"';
        };
        else {;
            * Format item *;
            unab Y : `vlcur';
            conf var `Y';
            cap format `Y' `X';
            local vlcur "";
        };
    };
};


*
 List variables if requested
*;
if `"`list'"'!="" {;
    if "`by'"=="" {;
        list `list';
    };
    else {;
        by `by':list `list';
    };
};


*
 Save dataset if requested
*;
if(`"`saving'"'!=""){;
    capture noisily save `saving';
    if(_rc!=0){;
        disp in red `"saving(`saving') invalid"';
        exit 498;
    };
    tokenize `"`saving'"',parse(" ,");
    local fname `"`1'"';
    if(strpos(`"`fname'"'," ")>0){;
        local fname `""`fname'""';
    };
    * Add filename to file list in FList if requested *;
    if(`"`flist'"'!=""){;
        if(`"$`flist'"'==""){;
            global `flist' `"`fname'"';
        };
        else{;
            global `flist' `"$`flist' `fname'"';
        };
    };
};


*
 Copy new frame to old frame if requested
*;
if "`restore'"=="norestore" {;
  frame copy `tempframe' `oldframe', replace;
};


};
*
 End of frame block (NOT INDENED)
*;


*
 Rename temporary frame to frame name (if frame is specified)
 and change current frame to frame name (if requested)
*;
if "`framename'"!="" {;
  if "`framereplace'"=="replace" {;
    cap frame drop `framename';
  };
  frame rename `tempframe' `framename';
  if "`framechange'"!="" {;
    frame change `framename';
  };
};


end;

program define _fillin;
/*
 Fill in combinations of varlist with zero frequencies,
 assuming that the varlist is the primary key of the current frame.
*/
version 16.0;
syntax varlist(min=2);
tempname FILLIN0 FILLIN1 curframe;
tempvar Xseq linvar;
local curframe=c(frame);
local Nvar: word count `varlist';
unab nonkeyvars: *;
local nonkeyvars: list nonkeyvars - varlist;

qui {;
  * Save current frame to be merged in later *;
  frame copy `curframe' `FILLIN0', replace;
  * Reduce current frame to have 1 obs per value of first variable *;
  local X: word 1 of `varlist';
  keep `X';
  sort `X';
  by `X': keep if _n==1;
  local varlist2 "`X'";
  * Loop over non-first variables *;
  forv i1=2(1)`Nvar' {;
    local X: word `i1' of `varlist';
    frame `FILLIN0' {;
      frame put `X', into(`FILLIN1');
    };
    frame `FILLIN1' {;
      sort `X';
      by `X': keep if _n==1;
      local Nval=_N;
      gene long `Xseq'=_n;
    };
    expand =`Nval';
    sort `varlist2';
    by `varlist2': gene long `Xseq'=_n;
    frlink m:1 `Xseq', frame(`FILLIN1') gene(`linvar');
    frget `X'=`X', from(`linvar');
    drop `linvar' `Xseq';
    local varlist2 "`varlist2' `X'";
    sort `varlist2';
    frame drop `FILLIN1';
  };
  * Merge in non-key variables if present *;
  if "`nonkeyvars'"!="" {;
    frlink 1:1 `varlist', frame(`FILLIN0') gene(`linvar');
    foreach Y in `nonkeyvars' {;
      cap frget `Y'=`Y', from(`linvar');
    };
  };
  frame drop `FILLIN0';
};

end;

prog def frameoption, rclass;
version 16.0;
*
 Parse frame() option
*;

syntax name [, replace CHange ];

return local change "`change'";
return local replace "`replace'";
return local namelist "`namelist'";

end;

#delim cr

program define _appendframe
/*
 Append one or more frames to the current frame.
 This program uses code modified
 from Jeremy Freese's SSC package frameappend.
*/

	version 16.0

	syntax namelist(name=frame_list) [, drop fast]
	/*
	  drop specifies that the from frame will be dropped.
	  fast speciffies that no work will be done to preserve the to frame
	    if the user presses Brak or other failure occurs
	*/

	* Check that all frame names belong to frames *
	foreach frame_name in `frame_list' {
	  confirm frame `frame_name'
	}

	* Preserve old dataset if requested *
	if "`fast'"=="" {
		preserve
	}
	
	* Beginning of frame loop *
	foreach frame_name in `frame_list' {
	* Beginning of main quietly block *
	quietly {
	
		* Get varlists from old dataset *
		ds
		local to_varlist "`r(varlist)'"
		* Get varlists from dataset to be appended *
		frame `frame_name': ds
		local from_varlist "`r(varlist)'"
		local shared_varlist : list from_varlist & to_varlist
		local new_varlist : list from_varlist - shared_varlist

		* Check modes of shared variables (numeric or string) *
		if "`shared_varlist'" != "" {
			foreach type in numeric string {
				ds `shared_varlist', has(type `type')
				local `type'_to "`r(varlist)'"
				frame `frame_name': ds `shared_varlist', has(type `type')
				local `type'_from "`r(varlist)'"
				local `type'_eq: list `type'_to === `type'_from
			}
			if (`numeric_eq' == 0) | (`string_eq' == 0) {
				di as err "shared variables in frames being combined must be both numeric or both string"
				error 109
			}
		}
		
		* get size of new dataframe *
		frame `frame_name' : local from_N = _N
		local to_N = _N
		local from_start = `to_N' + 1
		local new_N = `to_N' + `from_N'

		* Create variables for linkage in the 2 datasets *
		set obs `new_N'
		tempvar temp_n temp_link
		gen double `temp_n' = _n
		frame `frame_name' {
			gen double `temp_n' = _n + `to_N'
		}
	
		* Create linkage between the 2 datasets *
		frlink 1:1 `temp_n', frame(`frame_name') gen(`temp_link')
		
		* Import shared variables to old dataset *
		if "`shared_varlist'"!="" {
		  tempvar temphome
		  foreach X of varlist `shared_varlist' {
		    frget `temphome'=`X', from(`temp_link')
		    replace `X'=`temphome' in `=`to_N'+1' / `new_N'
		    drop `temphome'
		  }
		}
	
		* Import new variables to old dataset *
		if "`new_varlist'" != "" {
		  tempvar temphome2
		  foreach X in `new_varlist' {
		    frget `X'=`X', from(`temp_link')
		  }
	        }
	        
	        * Order variables (old ones first) *
	        order `to_varlist' `new_varlist'

	}
        * End of main quietly block *
        }
        * End of frame loop *

        * Restore old dataset if requested and necessary *
	if "`fast'"=="" {
        	restore, not
	}

	* Drop appended frame if requested *
	if "`drop'" == "drop" {
		foreach frame_name in `frame_list' {
			frame drop `frame_name'
		}
	}
		
end


