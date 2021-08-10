#delim ;
prog def xdir;
version 10.0;
/*
 Create a resultsset with 1 obs per file
 in a specified directory with a specified pattern.
*! Author: Roger Newson
*! Date: 03 April 2017
*/


syntax [,
  DIRname(string) PAttern(string) FType(string) noFAil RESpectcase
  LIst(string asis) SAving(string asis) noREstore FAST FList(string)
  LOcal(name)
  PATH IDNum(string) IDStr(string) REName(string) GSort(string) KEep(namelist)
  ];
/*
DIRname() contains the directory name.
PAttern() contains the file pattern.
FType specifies the file type to be used in the resultsset
  (files, directories or other).
noFAil specifies that if the directory contains too many filenames to fit into a macro,
  then the filenames that fit into the macro should be returned
  and used to create the resultsset.
RESpectcase specifies that cases in file names should be respected
  under the Microsoft Windows operating environment.
LIst() contains a varlist of variables to be listed,
  expected to be present in the output data set
  and referred to by the new names if REName is specified,
  together with optional if and/or in subsetting clauses and/or list_options
  as allowed by the list command.
SAving() specifies a data set in which to save the output data set.
noREstore specifies that the pre-existing data set
  is not restored after the output data set has been produced
  (set to norestore if FAST is present).
FAST specifies that xdir will not preserve the original data set
  so that it can be restored if the user presses Break
  (intended for use by programmers).
  The user must specify at least one of the four options
  list, saving, norestore and fast,
  because they specify whether the output data set
  is listed to the log, saved to a disk file,
  written to the memory (destroying any pre-existing data set),
  or multiple combinations of these possibilities.
FList() is a global macro name,
  belonging to a macro containing a filename list (possibly empty),
  to which xdir will append the name of the data set
  specified in the SAving() option.
  This enables the user to build a list of filenames
  in a global macro,
  containing the output of a sequence of model fits,
  which may later be concatenated using dsconcat (if installed) or append.
LOcal specifies the name of a local macro in the calling program,
  to contain the file list.
PAth specifies that a new variable path will be created,
  contaiing the entire file path
  (directory name plus delimiter plus filename).
IDNum() is an ID number for the model fit,
  used to create a numeric variable idnum in the output data set
  with the same value for all observations.
  This is useful if the output data set is concatenated
  with other xdir output data sets,
  using dsconcat (if installed) or append.
IDStr() is an ID string for the model fit,
  used to create a string variable idstr in the output data set
  with the same value for all observations.
PATH specifies that a new variable path will be created,
  contaiing the entire file path
  (directory name plus delimiter plus filename).
REName() contains a list of alternating old and new variable names,
  so the user can rename variables in the output data set.
GSort() specifies a gsort list by which the resultsset should be sorted.
KEep() option specifies the variables to keep
  in the output data set.
*/


*
 Set default dirname() option
*;
if `"`dirname'"'=="" {;
  local dirname `"`c(pwd)'"';
};


*
 Set default pattern() option
*;
if `"`pattern'"'=="" {;
  local pattern "*";
};


*
 Correct the ftype() option
*;
if strpos("files",`"`ftype'"')==1 & strpos(`"`ftype'"',"file")==1 {;
  local ftype "files";
};
else if strpos("dirs",`"`ftype'"')==1 & strpos(`"`ftype'"',"dir")==1 {;
  local ftype "dirs";
};
else if `"`ftype'"'=="other" {;
  local ftype "other";
};
else if `"`ftype'"'=="" {;
  local ftype "files";
};
else {;
  disp as error `"Illegal ftype(`ftype')"';
  error 498;
};


*
 Extract output filename list into a local macro
*;
local outflist: dir "`dirname'" `ftype' "`pattern'", `fail' `respectcase';
local outflist: list sort outflist;


*
 Set restore to norestore if fast is present
 and check that the user has specified one of the five options:
 local and/or list and/or saving and/or norestore and/or fast.
*;
if "`fast'"!="" {;
    local restore="norestore";
};
if ("`local'"=="" & `"`list'"'=="") & (`"`saving'"'=="") & ("`restore'"!="norestore") & ("`fast'"=="") {;
    disp as error "You must specify at least one of the five options:"
      _n "local(), list(), saving(), norestore, and fast."
      _n "If you specify local(), then the file name list is output to a local macro."
      _n "If you specify list(), then the output variables specified are listed."
      _n "If you specify saving(), then the new data set is output to a disk file."
      _n "If you specify norestore and/or fast, then the new data set is created in the memory,"
      _n "and any existing data set in the memory is destroyed."
      _n "For more details, see {help xdir:on-line help for xdir}.";
    error 498;
};


*
 Return local result if requested
*;
if "`local'"!="" {;
  c_local `local': copy local outflist;
};


*
 Beginning of resultsset-generating section (NOT INDENTED)
*;
if (`"`list'"'!="") | (`"`saving'"'!="") | ("`restore'"=="norestore") | ("`fast'"!="") {;


*
 Preserve old data set if restore is set or fast unset
*;
if("`fast'"==""){;
    preserve;
};


*
 Initialize resultsset
*;
drop _all;
local Noutf: word count `outflist';
qui set obs `Noutf';


*
 Create variables dirname and filename
 containing names of directory and files, respectively
*;
qui gene dirname=`"`dirname'"';
qui gene filename="";
forv i1=1(1)`Noutf' {;
  local outfcur: word `i1' of `outflist';
  qui replace filename=`"`outfcur'"' in `i1';
};
lab var dirname "Directory name";
lab var filename "File name";
sort dirname filename;


*
 Create path variable if requested
*;
if "`path'"!="" {;
  qui gene path=dirname+c(dirsep)+filename;
  lab var path "File path";
};


*
 Left-justify formats for all character variables
 in the base output variable set
*;
unab outvars: *;
foreach X of var `outvars' {;
    local typecur: type `X';
    if strpos("`typecur'","str")==1 {;
        local formcur: format `X';
        local formcur=subinstr("`formcur'","%","%-",1);
        format `X' `formcur';
    };
};


*
 Create numeric and/or string ID variables if requested
 and move them to the beginning of the variable order
*;
if("`idstr'"!=""){;
    qui gene str1 idstr="";
    qui replace idstr=`"`idstr'"';
    qui compress idstr;
    qui order idstr;
    lab var idstr "String ID";
};
if("`idnum'"!=""){;
    qui gene double idnum=real("`idnum'");
    qui compress idnum;
    qui order idnum;
    lab var idnum "Numeric ID";
};


*
 Rename variables if requested
*;
if "`rename'"!="" {;
    local nrename:word count `rename';
    if mod(`nrename',2) {;
        disp as text "Warning: odd number of variable names in rename list - last one ignored";
        local nrename=`nrename'-1;
    };
    local nrenp=`nrename'/2;
    local i1=0;
    while `i1'<`nrenp' {;
        local i1=`i1'+1;
        local i3=`i1'+`i1';
        local i2=`i3'-1;
        local oldname:word `i2' of `rename';
        local newname:word `i3' of `rename';
        cap{;
            confirm var `oldname';
            confirm new var `newname';
        };
        if _rc!=0 {;
            disp as text "Warning: it is not possible to rename `oldname' to `newname'";
        };
        else {;
            rename `oldname' `newname';
        };
    };
};


*
 Sort if requested
*;
if "`gsort'"!="" {;
  tempvar tiebreak;
  qui gene long `tiebreak'=_n;
  qui compress `tiebreak';
  gsort `gsort' + `tiebreak';
  drop `tiebreak';
};


*
 Keep only selected variables if requested
*;
if "`keep'"!="" {;
    unab keepvars: `keep';
    confirm variable `keepvars';
    keep `keepvars';
};


*
 List variables if requested
*;
if `"`list'"'!="" {;
    list `list';
};


*
 Save data set if requested
*;
if(`"`saving'"'!=""){;
    capture noisily save `saving';
    if(_rc!=0){;
        disp as error `"saving(`saving') invalid"';
        exit 498;
    };
    tokenize `"`saving'"', parse(" ,");
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
 Restore old data set if restore is set
 or if program fails when fast is unset
*;
if "`fast'"=="" {;
    if "`restore'"=="norestore" {;
        restore, not;
    };
    else {;
        restore;
    };
};


};
*
 End of resultsset-generating section (NOT INDENTED)
*;


end;
