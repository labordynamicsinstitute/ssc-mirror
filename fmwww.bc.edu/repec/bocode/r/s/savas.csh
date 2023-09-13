#!/bin/csh -f
#/bin/csh -fx  ** -x to debug ** 

#Call package log facility
if (-e "/afs/isis/pkg/runlogger/bin/runlogger") then
  /afs/isis/pkg/runlogger/bin/runlogger savas-2
endif

#######################################################################
#
# version 3.0
#  Date: 25Mar2008 
#  - made it so that savas can now handle data files in directories
#     that have spaces in the names.
#  - made it so that -replace and -rename options only work with first
#     dataset unless the -force option is used.
#  - made savas Stata MP compatible
#  - made savas able to convert SPSS convertable files to Stata 
#  - fixed cd - to cd "$oldpwd" since csh in AIX doesn't like cd - .
#  - condensed multiple case commands inside the switch commands
#  - savas now catches situations where user supplied output dataset name
#     and prints error message and exits. 
#  - no longer checking if SAS datasets are sorted and passing sort vars to savastata
#     never needed to do this check for Stata datasets.
# version 2.2
#  Date: 13Sep2007
#  - fixed it so that p575s and yatta use /scr/APPS_SCRDIR for tmpdir
#  - fixed it so that if savas finds Stata in an LSF dir then it runs
#     the default version of Stata
#  - added check to make sure SAS or Stata are not being run in the background
#     when being invoked by savas. 
#  Date: 11Jun2007 
#  - fixed csh issue with removing or listing file like so: rm -r "/tmp"/_$$*
#     some versions of csh don't like the quotes
#  - added more information when -debug option used.
#  - added tip about how to use fdause and fdasave if user uses savas to 
#     convert files to or from a SAS xport file.
#  Date: 29Aug2006 
#  - put all the different settings per host in a big case command.
#  - if user has SAS in their path then use that SAS, otherwise if run
#     on a known host then set location of SAS executable.
#  - if user has Stata in their path then use that Stata, otherwise if run
#     on a known host then set location of Stata executable.
#  - create usagelog if it doesn't exist since it's in /tmp which gets
#     routinely cleaned up.
#  - added -force option which is equivalent to using both -rename and -replace options.
#  - added -debug option which will say how savas will invoke SAS and Stata.
#  Date: 21Jul2006
#  - made it so savas can run on StatApps, MacBeth, or Baobab by putting
#     all the ado files in /afs/isis/pkg/stata-9/.install/common/updates/
#     and modifying the location of the SAS and Stata locations.  Since
#     Stata requires all machines to have /usr/local/stata/ be the directory
#     or a link to the real directory I have set it to that.  Both uses of
#     SAS and Stata are runlogged.  
#  - added options -h, --help, and -? to show all options.
# version 2.01
#  Date: 08Aug2005
#  - added new savastata option char2lab for long SAS character vars 
#     to be made into numeric vars with value labels in Stata 9.
#     this requires the SAS macro char2fmt.sas
#  - now savas deletes the temporary intermediary files when savastata creates error
#     messages (which savas reports to the user).  
#  - now reads SAS xport files that were created with proc cport like -usesas- does
#    NOTE: SAS's CIMPORT procedure will not open a datafile created in later version of SAS
#  - if obs= or varfile= options now savas loads the input Stata data file like it does SAS 
#     with only the subset of observations and/or variables.  savas used to subset the dataset
#     after the file was loaded.
# version 1.20
#  Date: 29Oct04
#  - SAS xport filenames are 100% maintained even if they contain multiple extensions
# version 1.10
#  Date: 02Mar04
#  -temporary filename _$$_legal_name deleted if choose not to process with the
#  -improved TIP message 
#   suggested legal name.
#  Date: 09Dec03
#  -Legal Stata filenames that are illegal SAS filenames are fixed when going to SAS
#  -The following file extensions are recognized as SAS Transport/Xport files: 
#     .xpt, .xport, .exp, .export, .sasx, .stx, .v5x, .v6x, .trans, .expt
#
# version 1.00
#
# Date: 02Dec03
#
# Programmer: Dan Blanchette
#             Research Computing, UNC-CH
# Developed at The Carolina Population Center, UNC-CH
#              
#
# savas makes SAS copies of Stata datasets 
#    or makes Stata copies of SAS datasets
#
#  This program is released under the terms and conditions of GNU General Public License.
#
#  savas works with Stata version 8.1 or later.
#
#
#        NOTE FOR INSTALLATION
#
# savas requires that you have installed 4 Stata ado files:
#   savasas.ado    
#   sasexe.ado    
#   adoedit.ado    
#   tmpdir.ado    
# and the SAS macros: savastata.sas and char2fmt.sas
# 
# If you are installing this script on a new machine, you need to
# alter the following shell variables which define directory structure
# assumptions.  If the file "savas_usage.log" exists in a directory
# specified in savas, then savas script will keep a log of all 
# usage of the script.  Savasas.ado can also be set up to log to the
# same file. 
#
#######################################################################


# initialize vars
set default_SAS=0
set default_STATA=0
set default_tmpdir=0
set host_name=`hostname`

# use default temp directory (cannot contain spaces!) 
set tmpdir=/tmp

# make sure that SAS is not set to run in the background!
set dSAS=/afs/isis/pkg/sas/sas

# make sure that Stata is not set to run in the background!
set dSTATA=/usr/local/stata/stata-se
           
set ado_dir=/afs/isis/pkg/stata/.install/common/ado/updates  # Your SITE directory of ado files
set SAVASTATA=$ado_dir/savastata.sas          # Your savastata macro
set CHAR2FMT=$ado_dir/char2fmt.sas            # Your char2fmt macro
set SAVASAS=$ado_dir/savasas.ado              # Your savasas.ado
set GAWK=/afs/isis/pkg/gnu-utils/bin/gawk     # Your gawk executable

# Your usage log file name or directory name (cannot contain spaces!)
set usagelog=/afs/isis.unc.edu/some_dir/usage/savas_usage.log
set usagelog="do not log usage" #set usagelog to this if logging is desired

# Your SAS executable also needs to be set in sasexe.ado, bu $SAS is passed to savasas
#  so savas will invoke SAS that way.
# Your STATA executable also needs to be set in savastata.sas, but $STATA is passed to
#  the savastata macro when savas invokes SAS and $SAS is passed to savasas/sasexe when 
#  savas invokes Stata.

#set MANPATH=/usr/local/bin/MAN               # Directory with man-page

switch ("$host_name")
  # if run on gromit, sig or any other cpc UNIX/Linux machine
  case gromit:
  case sig:
  case *.cpc.unc.edu:
    set SAS=/usr/bin/sas                    # Your SAS executable - default version
    set dSTATA=/usr/bin/stata               # Your default STATA executable - default version
    set tmpdir="/tmpsas"                    # Your temp directory (cannot contain spaces)
  breaksw
  # if host_name starts with p575 or yatta:
  case p575*:
  case yatta*:
    #  > /dev/null suppresses error messages except for on Ubuntu Linux
    set SAS=`which sas > /dev/null `
    if ( $status != 0 ) then
      # use default version of Stata
      # check $status as this doesn't work: case *Command*not*found*:  #did not find SAS (in Linux)
      set default_SAS=1
    else
     # check to see if which found the path to SAS
     switch ("$SAS")
       case /afs*sas-*/bin*:    #found a specific version of SAS
         # shave off the /bin and use that version of SAS
         # set SAS=`echo "$SAS" | sed s%/bin%%`  might need this in the future
         set SAS="$SAS"  #just use this file since it's runlogged, could be sas-82 or sas-9x
         breaksw
       case /afs*sas/bin*:      #found default version of SAS
         # use default version of SAS
         set default_SAS=1
         breaksw
     endsw
    endif
    set tmpdir="/scr/APPS_SCRDIR"      # Your temp directory (cannot contain spaces)
  breaksw
  case *:
    #  > /dev/null suppresses error messages except for on Ubuntu Linux
    set SAS=`which sas > /dev/null`
    if ( $status != 0 ) then
      # use default version of SAS
      # check $status as this doesn't work: case *Command*not*found*:  #did not find SAS (in Linux)
      set default_SAS=1
    else
     # check to see if which found the path to SAS
     switch ("$SAS")
       case /afs*sas-*/bin*:    #found a specific version of SAS
         # shave off the /bin and use that version of SAS
         # set SAS=`echo "$SAS" | sed s%/bin%%`  might need this in the future
         set SAS="$SAS"  #just use this file since it's runlogged, could be sas-82 or sas-9x
         breaksw
       case /afs*sas/bin*:      #found default version of SAS
         # use default version of SAS
         set default_SAS=1
         breaksw
     endsw
    endif 
    set default_tmpdir=1
  breaksw
endsw


#Global settings for all hosts!:
#  > /dev/null suppresses error messages except for on Ubuntu Linux
set STATA=`which stata > /dev/null`              # Your Stata executable
if ( $status != 0 ) then
 # didn't find stata
 # use default version of Stata 
 # check $status as this doesn't work: case *Command*not*found*:  #did not find Stata (in Ubuntu Linux)
 set default_STATA=1
else
 set STATA=`which stata`                        # Your Stata executable
 # found stata but need to check that it's the appropriate non-LSF stata
 switch ("$STATA")
   case /afs*stata-*/bin*:    #found a specific version of Stata and the stata_central script
     # shave off the /bin and use that version of Stata because stata_central will put this in LSF
     set STATA=`echo "$STATA" | sed s%/bin%%`
    breaksw
   case /afs*stata/bin*:      #found default version of Stata and the stata_central script
   case /*lsf*:               #found the lsf script Stata
     # use default version of Stata because stata_central will put this in LSF
     set default_STATA=1
    breaksw
 endsw
endif

if (( $default_SAS == 1 ) || ( "$SAS" == "" )) then
   #use default setting of SAS
   set SAS="$dSAS"
endif
if (( $default_STATA == 1 ) || ( "$STATA" == "" )) then
   #use default setting of STATA
   set STATA="$dSTATA"
endif


#######################################################################
# End of installation aspects.
#######################################################################

# In case of <ctrl+C> from the keyboard, go to label panic:
onintr panic


# Set savas defaults:
set ascii=""
set sascode=""
set beep=0
set check=""
set curdir=0
set char2lab=""
set describe=""
set df_count=0
set engine=""  # use default version
set flag=0
set float=""
set formats=""
set formatsexist=0
set fmtext=""
set messy=0 
set legal=""
set nobs=0
set nice=20
set NSAS="nice +20 $SAS"             # Run SAS nicely
set NSTATA="nice +20 $STATA"         # Run Stata nicely
set os="`uname`"
set old=""
set intercooled=""
set quote=""
set rename=""
set replace=""
set force=""
set rights=0
set outfile=""
set datafiles=""
set datafile=""
set type="sas"
set debug=0
set verbal=1
set varfile=""
set sasl=""
set success=0
set trace=""
set xport=0

# Keep a log of users, create it if it doesn't already exist:
if (( ! -e "$usagelog" ) && ( "$usagelog" != "do not log usage" )) then
  echo "Log created on: `date` " > $usagelog
  chmod 666 $usagelog
  echo " " >> $usagelog
endif 

if (-e "$usagelog" ) then
   echo " " >> $usagelog
   echo "   $host_name  $user, "`date` >> $usagelog
   # $argv is all the arguments passed to savas
   echo     savas $argv    >> $usagelog
endif


if ($#argv == 0 || "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ) then
   echo "  "
   echo "savas copies SAS datasets as Stata datasets"
   echo "or Stata datasets as SAS datasets based on the input datafile's extension"
   echo "the new dataset will have the same name as the input dataset."
   echo ""
   echo "NOTE: You cannot tell savas what you want the output dataset to be named."
   echo ""
   echo "savas can do multiple files at a time"
   echo "Usage:  'savas [-options] dataset.ext ....'"
   echo "where -options may be:"
   echo "  -a/-ascii ------- only creates ascii (do+raw) files"
   echo "  -b/-beep -------- beeps upon completion"
   echo "  -char2lab-------- turn long SAS character variables into Stata numeric vars "
   echo "                     with value labels (only if using Stata 9 or higher)."
   echo "  -check ---------- create 2 check files to check if savas "
   echo "                     created the output dataset correctly."
   echo "  -c/-curdir ------ if the input dataset is not in the current directory,"
   echo "                     save output dataset to current directory"
   echo "  -f/-float ------- store numeric variables as float that would otherwise"
   echo "                     be stored as double"
   echo "  -fmts/-formats -- saves all value labels as user-defined formats in a formats"
   echo "                     catalog file (*.sas7bcat) with the same name and in same dir "
   echo "                     as dataset, for example: MyData.sas7bcat "
   echo "  -i/-intercooled - save as Intercooled if using SE or MP"
   echo "  -m/-messy ------- does not clean up temporary files"
   echo "  -n/-nice=n ------ makes SAS or Stata run nice +n (default 20)"
   echo "  -obs=n ---------- converts only the first n observations"
   echo "  -o/-old --------- save to previous version of Stata"
   echo "  -q/-quotes ------ replace double quotes in text vars and compound quotes"
   echo "  -ren/-rename ---- renames files/variables when necessary to make SAS work"
   echo "  -r/-replace ----- replaces existing output dataset without warning"
   echo "  -force ---------- both -rename and -replace options turned on and kept on "
   echo "                     if more than one file submitted to savas."
   echo "  -rights --------- make the output file have your default new file rights "
   echo "                     not necessarily the file permissions of the input file "
   echo "  -sas6 ----------- saves dataset as a SAS version 6 dataset"
   echo "  -sascode--------- only creates SAS input program file and data file"
   echo "  -sasx ----------- saves dataset as a SAS version 6 xport dataset"
   echo "  -s/-silent ------ makes savas operate silently"
   echo "  -varfile=filename converts only the variables in file filename"
   echo "                     must be a valid SAS or Stata varlist"
   echo "  -x/-xport ------- allows a single transport dataset to be processed"
   echo " "
   echo For more detailed information, type: man savas  
   echo " "
   set flag=1
   goto leave
endif	


	
#######################################################################
# Parse the command line.

while ("$1" != "")
   switch ("$1")
      case -ascii:      # only create ascii file
      case -a:          # only create ascii file
         set ascii="ascii"
	 set sascode="sascode"
         shift
         breaksw
      case -sascode:      # only create SAS program
	 set sascode="sascode"
         set ascii="ascii"
	 shift
	 breaksw
      case -beep:       # beep upon completion
      case -b:          # beep upon completion
	 set beep=1
	 shift
	 breaksw
      case -char2lab:        # make long SAS char vars into value labels
         set char2lab="char2lab"
	 shift
	 breaksw
      case -check:        # create 2 check files
         set check="check"
	 shift
	 breaksw
      case -curdir:     # save Stata dataset to current directory
      case -c:          # save Stata dataset to current directory
	 set curdir=1
	 shift
	 breaksw
      case -describe:    # describe: create Stata dataset containing metadata of SAS dataset
      case -de:          # describe: create Stata dataset containing metadata of SAS dataset
         echo " "
         echo "... -describe is an option for -usesas- only "
         echo -n "   Do you want savas to ignore this option and continue? (y/n)"
         set yesorno=$<
         if (($yesorno != "y") && ($yesorno != "Y")) then
           set flag=39
           goto leave
         endif
         echo " "
         shift
         breaksw
      case -float:      # float: do not create double variables
      case -f:          # float: do not create double variables
         set float="float"
         shift
         breaksw
      case -formats:    # create formats in formats catalog file in same dir as dataset
      case -fmts:       # create formats in formats catalog file in same dir as dataset
	 set formats="formats"
	 shift
	 breaksw
      case -intercooled: # save in Intercooled if using SE or MP
      case -i:          # save in Intercooled if using SE or MP
         set intercooled="intercooled"
         shift
         breaksw
      case -messy:      # messy: do not clean up
      case -m:          # messy: do not clean up
	 set messy=1
	 shift
	 breaksw
      case -n*:      # priority level for Stata and SAS (default=20)
      case -nice*:      # priority level for Stata and SAS (default=20)
	 set nice=`echo $1 | $GAWK '{tmp=split($1, words, "="); print words[2]}'`
	 if ("$nice" == "") then
	    echo " "
	    echo "ERROR: no spaces allowed around '=' in option -nice=n"
	    set flag=2
            goto leave
	 else if (($nice < 0) && (`whoami` != "root")) then
	    echo " "
	    echo "ERROR: only root may specify negative priority levels"
	    set flag=3
            goto leave
	 else if ($nice < 0) then
	    set NSTATA="nice $nice $STATA"       # Run Stata not-nicely
	    set NSAS="nice $nice $SAS"           # Run SAS not-nicely
	 else
	    set NSTATA="nice +$nice $STATA"      # Run Stata nicely
	    set NSAS="nice +$nice $SAS"          # Run SAS nicely
	 endif
	 shift
	 breaksw
      case -obs*:       # only subset of observations
	 set nobs=`echo $1 | $GAWK '{tmp=split($1, words, "="); print words[2]}'`
	 if ("$nobs" == "") then
	    echo " "
	    echo "ERROR: no spaces allowed around '=' in option -obs=n"
	    set flag=4
            goto leave
	 else if ($nobs <= 0) then
	    echo " "
	    echo "ERROR: number of observations must be strictly positive"
	    set flag=5
            goto leave
	 endif
	 shift
	 breaksw
      case -rename:      # renames variables when necessary to work for SAS 
      case -ren:         # renames variables when necessary to work for SAS 
         set rename="rename"
	 shift
	 breaksw
      case -replace:    # replace: replace existing output dataset without warning
      case -r:          # replace: replace existing output dataset without warning
	 set replace="replace"
	 shift
	 breaksw
      case -force:      # force -rename and -replace if needed
         set force="force"
         set rename="rename"
         set replace="replace"
	 shift
	 breaksw
      case -old:        # save to previous version of Stata
      case -o:          # save to previous version of Stata
         set old="old"
         shift
         breaksw
      case -quotes:        # replace double and compound quotes with single quotes
      case -q:           # replace double and compound quotes with single quotes
         set quote="quote"
         shift
         breaksw
      case -rights:     # use default file permissions
	 set rights=1
	 shift
	 breaksw
      case -sas6:        # saves dataset as SAS version 6 (*.ssd01)
         set type="sas6"
	 shift
	 breaksw
      case -debug :     # more verbal than verbal
	 set debug=1
	 shift
	 breaksw
      case -silent:     # be silent
      case -s:          # be silent
	 set verbal=0
	 shift
	 breaksw
      case -varfile*    # only subset of variables, listed in file $varfile
	 set varfile=`echo $1 | $GAWK '{tmp=split($1,words,"="); print words[2]}'`
	 if ("$varfile" == "") then
	    echo " "
	    echo "ERROR: no spaces allowed around '=' in option -varfile=filename"
	    set flag=6
            goto leave
	 else if ( ! -f $varfile) then
	    echo " "
	    echo ERROR: $varfile is not a file with variable names
	    set flag=7
            goto leave
	 endif
	 shift
	 breaksw
      case -sasx:       # saves dataset as SAS version 6 xport dataset (*.xpt)
         set type="sasx"
	 shift
	 breaksw
      case -trace:      # used for debugging, also sets mprint option in sas
         set trace="set trace on"
	 shift
	 breaksw
      case -xport:      # process transport dataset
         set xport=1
         shift
         breaksw
      case -x:          # process transport dataset
         set xport=1
         shift
         breaksw
      case -*:
	 echo "Illegal option, $1"
	 set flag=8
         goto leave
      default:
	 # There may be multiple data files
         if ( $df_count == 0 ) then
           # make datafiles an array
	   set datafiles = ( "$1:q" )
           else if ($df_count != 0) then
             set datafiles = ( $datafiles:q "$1:q" )
         endif
         @ df_count = $df_count + 1
	shift
   endsw
end # End of parsing the command line.

# Check that the gawk and all other executables exist
if ( ! -e "$GAWK") then
   echo " "
   echo ERROR: you need $GAWK to run savas
   set flag=9
   goto leave
endif
if ("$sascode" != "sascode") then
 if ( ! -e "$SAS") then
   echo " "
   echo ERROR: you need $SAS to run savastata
   set flag=10
   goto leave
 endif
 if ( ! -e "$SAVASAS") then
   echo " "
   echo ERROR: you need $SAVASAS to run savas
   set flag=11
   goto leave
 endif
endif
if ("$ascii" != "ascii") then
 if ( ! -e "$STATA") then
   echo " " 
   echo ERROR: you need $STATA to run savas
   set flag=12
   goto leave
 endif
 if ( ! -e "$SAVASTATA") then
   echo " "
   echo ERROR: you need $SAVASTATA to run savastata
   set flag=13
   goto leave
 endif
endif

# Must have tmpdir set  
if ( "$tmpdir" == "" ) then
  #use the default
  set tmpdir=/tmp
endif  
if ( ! -d "$tmpdir" ) then
  echo 'ERROR: you need to set $tmpdir in savas as your temporary directory'
  echo " This is not a directory: $tmpdir"
  set flag=14
  goto leave
endif

# Must have write permission in temporary working directory
if ( ! -w "$tmpdir") then
   echo " "
   echo "ERROR: you need to have write permission in $tmpdir directory"
   set flag=15
   goto leave
 endif

if ( $#datafiles == 0 ) then
   echo " "
   echo "ERROR: no dataset specified"
   set flag=16
   goto leave
endif
if (!(-e "$CHAR2FMT") && ("$char2lab" != "")) then
  echo " "
  echo WARNING: you need $CHAR2FMT to use the $char2lab option
  echo WARNING: this option will be ignored
  set char2lab=""
endif

set NSAS="$NSAS -SYSPARM $STATA "
if ($debug == 1) then
  echo savas will invoke SAS like so: $NSAS
  echo so savastata will invoke Stata like so: $STATA
  echo savas will invoke Stata like so: $NSTATA
  echo  and savasas will set usesas to $SAS
  echo the tmpdir will be: $tmpdir
  echo the temp files will start with: _$$ 
  set verbal=1
endif

# test to see if user created their submission like a stat/transfer
#  or dbms/copy one where the output filename is specified.
if ( $#datafiles > 1 ) then
  if (( "$datafiles[1]" != "" ) &&  ( "$datafiles[2]" != "" )) then
    if ( ! -e "$datafiles[2]" ) then
      echo 
      echo ERROR: dataset: \"$datafiles[2]\" does not exist.
      echo You cannot tell savas what you want the output dataset to be named.
      echo savas will use the input filename for the output filename and 
      echo  figure out if you want a SAS or Stata dataset based on the file
      echo  extension of the input dataset.
      echo For more detailed information, type: man savas  
      set flag=40
      goto leave 
      echo 
    endif
  endif
endif

#count how many times foreach loop loops
set f_loop_n=0
# Convert data files one at a time
# ":q" allows you to pass args into foreach loop even if args have spaces in them
foreach datafile ( $datafiles:q )
@ f_loop_n = $f_loop_n + 1

set cur_dir="$PWD"
# :h strips the file name and the last / off the string /some dir/my_file.sas7bdat
set pathname="$datafile:h"
if ("$pathname" == "$datafile") then
  set pathname="$cur_dir"
endif

# Must have write permission in current working directory
if ($curdir == 1 || "$pathname" == "$cur_dir") then
 if (! -w . ) then
   echo " $datafile"
   echo "ERROR: you need to have write permission in the current working directory"
   set flag=17
   goto leave
 endif
endif
# Must have write permission in directory where dataset is to be written
if ($curdir == 0) then
 if ( ! -w "$pathname") then
   echo " "
   echo "ERROR: you need to have write permission in the directory where dataset is to be written: "
   echo " $pathname "
   set flag=18
   goto leave
 endif
  # Stata cannot handle relative paths because it's run in /$tmpdir/
  cd "$pathname"
  set in_dir = "`pwd`"
  set out_dir = "`pwd`"
  cd "$cur_dir"
endif  # end of if curdir == 0 do loop 
if ($curdir == 1) then
 if ( ! -w "$cur_dir") then
   echo " "
   echo "ERROR: you need to have write permission in the directory where dataset is to be written: "
   echo " $cur_dir"
   set flag=19
   goto leave
 endif
  cd "$pathname"
  set in_dir = "`pwd`"
  cd "$cur_dir"
  set out_dir = "$cur_dir"
endif  # end of if curdir == 1 do loop 

   # :e returns just the file extension
   set ext="$datafile:e"
   set low_ext=` echo $ext | tr '[:upper:]' '[:lower:]'`
   if ($ext == "ssd01") then
      set engine="v6"
      set use="savastata"
    else if ($ext == "sas7bdat") then
       set engine=""  # use default version
       set use="savastata"
    else if ($ext == "dta") then
       set use="savasas"
    else if (($low_ext == "xpt") || ($ext == "exp") || ($ext == "v5x") || ($ext == "v6x") || ($ext == "stx") || ($ext == "export") || ($ext == "xport") || ($ext == "trans") || ($ext == "sasx") || ($ext == "expt") || ($ext == "cport") || ($ext == "ssp") || ($ext == "por"))  then
       set xport = 1
       set engine="xport"
       set use="savastata"
    else if ($xport == 1) then
       set engine="xport"
       set use="savastata"
    else if ( "$ext" == "" ) then
      echo "ERROR: Your file: $datafile  has no file extension."
      echo "  If it is a SAS Transport/Xport file, then use the option -x or -xport."
      echo  savas -xport \"${datafiles}\"  
      set flag=20  
      goto leave
    else
      echo " Is this a transport dataset?"
      echo " If so then use option -x or -xport like so:"
      echo "savas -x $datafile"
      set flag=21
      goto leave
   endif #end of if $ext == "ssd01"

   if ($use == "savasas") then
    set USE_S="Stata"
    set use_s="Stata"
   else if ($use == "savastata") then
    set USE_S="SAS"
    set use_s="sas"
   endif

   if ($verbal == 1) then
     if (($use == "savastata") && ($xport == 1) && ( "$low_ext" != "cport" ) && ( "$low_ext" != "ssp" ) && ( "$low_ext" != "por" )) then 
       echo " "
       echo " TIP: "
       echo "...The Stata command fdause reads in SAS Transport/Xport data sets like so: ..."
       echo "... fdause $datafile ... "
     else if (($use == "savasas") &&  ($type == "sasx")) then 
       echo " TIP: "
       echo " "
       echo "...The Stata command fdasave saves Stata datasets as SAS Transport/Xport data sets like so: ... "
       echo "... fdasave $datafile ..."
       echo " "
     endif #end of if $use == "savastata" ...
   endif #end of if $verbal == 1

   # :t strips the path from the file name
   set destfile="$datafile:t"
   # :r strips the file extension off the filename
   set destfile="$destfile:r"

   # recreate datafile so that it has expanded directory name if in current directory
   set datafile="$in_dir"/"$destfile"  # put the dir info on it
   set datafile="$datafile.$ext"     
   if ( ! -e "$datafile") then
      echo " "
      echo "ERROR: $datafile file does not exist."
      echo ""
      set flag=22
      goto leave
   endif

   set ssdname="$destfile"

   # make sure the new file is in all lowercase
   set destfile=`echo $destfile | tr '[:upper:]' '[:lower:]'`


   # Depending on whether -sascode was specified, the output files are a .xpt and
   # a .sas file (sascode only) or a .sas7bdat file.  Determine the names for the
   # three files; without -sascode, the .xpt and .sas files are temporary names.


      set newfile = ""
      set char=1
      set c_chk = ""

     if ("$use" == "savasas" ) then
      set legal="$tmpdir"/_$$_legal_name
      echo "$destfile" > $legal
      set newfile = ""
      set char=1
      while ( $char <= 32 )
       set c_chk = "`cut -c$char $legal`"
       if ( "$c_chk" == "" ) then
        set char = 33
       else if (( "$c_chk" == "_" ) || ( "$c_chk" == "a" ) || ( "$c_chk" == "b" ) || ( "$c_chk" == "c" ) || ( "$c_chk" == "d" ) || ( "$c_chk" == "e" ) || ( "$c_chk" == "f" ) || ( "$c_chk" == "g" ) || ( "$c_chk" == "h" ) || ( "$c_chk" == "i" ) || ( "$c_chk" == "j" ) || ( "$c_chk" == "k" ) || ( "$c_chk" == "l" ) || ( "$c_chk" == "m" ) || ( "$c_chk" == "n" ) || ( "$c_chk" == "o" ) || ( "$c_chk" == "p" ) || ( "$c_chk" == "q" ) || ( "$c_chk" == "r" ) || ( "$c_chk" == "s" ) || ( "$c_chk" == "t" ) || ( "$c_chk" == "u" ) || ( "$c_chk" == "v" ) || ( "$c_chk" == "w" ) || ( "$c_chk" == "x" ) || ( "$c_chk" == "y" ) || ( "$c_chk" == "z" ) || ( "$c_chk" == "A" ) || ( "$c_chk" == "B" ) || ( "$c_chk" == "C" ) || ( "$c_chk" == "D" ) || ( "$c_chk" == "E" ) || ( "$c_chk" == "F" ) || ( "$c_chk" == "G" ) || ( "$c_chk" == "H" ) || ( "$c_chk" == "I" ) || ( "$c_chk" == "J" ) || ( "$c_chk" == "K" ) || ( "$c_chk" == "L" ) || ( "$c_chk" == "M" ) || ( "$c_chk" == "N" ) || ( "$c_chk" == "O" ) || ( "$c_chk" == "P" ) || ( "$c_chk" == "Q" ) || ( "$c_chk" == "R" ) || ( "$c_chk" == "S" ) || ( "$c_chk" == "T" ) || ( "$c_chk" == "U" ) || ( "$c_chk" == "V" ) || ( "$c_chk" == "W" ) || ( "$c_chk" == "X" ) || ( "$c_chk" == "Y" ) || ( "$c_chk" == "Z" ) || ( "$c_chk" == "0" ) || ( "$c_chk" ==  "1" ) || ( "$c_chk" == "2" ) || ( "$c_chk" == "3" ) || ( "$c_chk" == "4" ) || ( "$c_chk" == "5" ) || ( "$c_chk" == "6" ) || ( "$c_chk" == "7" ) || ( "$c_chk" == "8" ) || ( "$c_chk" == "9" )) then 
         set newfile = "$newfile$c_chk"
       endif

       @ char = $char + 1
      end  # of while

      # make sure filename doesn't start with a number
      echo "$newfile" > $legal
      set c_chk = "`cut -c1 $legal`"
      if (( $c_chk == 0 ) || ( $c_chk == 1 ) || ( $c_chk == 2 ) || ( $c_chk == 3 ) || ( $c_chk == 4 ) || ( $c_chk == 5 ) || ( $c_chk == 6 ) || ( $c_chk == 7 ) || ( $c_chk == 8 ) || ( $c_chk == 9 )) then
       set newfile = "_$newfile"
      endif
      if ( "$newfile" == "" ) then
       set newfile = okpopeye
      endif
      if (( "$destfile" != "$newfile" ) && ( "$rename" != "rename" )) then
       echo "ERROR: $destfile is not a legal SAS filename.  "
       echo -n "   Do you want savas to name the output file: $newfile (y/n)"
        set yesorno=$<
        if (($yesorno != "y") && ($yesorno != "Y")) then
         set flag=23 
         rm -f "$legal"
         goto leave
        endif
       set destfile = "$newfile" 
      endif
      if (( "$destfile" != "$newfile" ) && ( "$rename" == "rename" )) then
       set destfile = "$newfile" 
      endif
     endif  # end of if use == savasas 

     if ("$type" == "sas") then
      set outfile="$destfile".sas7bdat   # SAS data file (permanent)
     endif
     if ("$type" == "sas6" || ($type == "sasx")) then
      ### test that destfile is 8 characters or less
      set sht_test1="$tmpdir"/_$$_sht_test1
      set sht_test2="$tmpdir"/_$$_sht_test2
      echo $destfile > $sht_test1
      cut -c9 $sht_test1 > $sht_test2
      set sht_test=`less $sht_test2`
      
      if ($sht_test != "") then
       echo $destfile > $sht_test1
       cut -c1-8 $sht_test1 > $sht_test2
       set sdestfile=`less $sht_test2`
       if ($rename != "rename") then
        echo "ERROR: filename $destfile is too long for a $type datafile name."
        echo -n " Do you want savas to name the output file: $sdestfile? (y/n) "
        set yesorno=$<
         if (($yesorno != "y") && ($yesorno != "Y")) then
            set flag=24 
            goto leave
         endif
       endif
       set destfile="$sdestfile"
      endif
     endif
     if ("$type" == "sas6" && $os != "Unix" ) then
      set outfile="$destfile".ssd01      # SAS data file (permanent)
     endif
     if ("$type" == "sas6" && $os == "Linux" ) then
      set outfile="$destfile".ssd02      # SAS data file (permanent)
     endif
     if ("$type" == "sasx") then
      set outfile="$destfile".xpt        # SAS data file (permanent)
     endif
     if ("$use" == "savastata") then
      set outfile="$destfile".dta        # Stata data file (permanent)
     endif
     set outfile="$out_dir"/"$outfile"   # add dir info to outfile 

   if ($sascode == "") then
     if ((-e "$outfile") && ("$replace" == "" )) then
	 echo -n "WARNING: "$outfile" already exists; overwrite? (y/n) "
	 #set yesorno=`line`
	 set yesorno=$<
	 if (($yesorno != "y") && ($yesorno != "Y")) then
            if ( -e "$legal" ) then
              rm -f "$legal"
            endif
            set flag=25
            goto leave
	 endif
         set replace="replace"
     endif
  
     if ((-e "$outfile") && ( ! -w "$outfile" )) then  
      echo "ERROR: You do not have permission to overwrite "$outfile". "
      set flag=26
      goto leave
     endif
   endif  # end of if sascode=="" do loop 


   if ("$sascode" == "sascode" ) then
    if ("$use" == "savasas" ) then 
     set infile="$out_dir"/"$destfile"_infile.sas
     set rawfile="$out_dir"/"$destfile".xpt
    endif
    if ("$use" == "savastata" ) then 
     set infile="$out_dir"/_"$destfile"_infile.do
     set rawfile="$out_dir"/_"$destfile"_.raw
    endif

    if ((-e "$infile") && ( ! -w "$infile" )) then  
     echo "ERROR: savas needs to create the file "$infile". "
     echo "ERROR: You do not have permission to overwrite "$infile". "
     set flag=27
     goto leave
    endif
   
    if ((-e "$rawfile") && ( ! -w "$rawfile" )) then  
     echo "ERROR: savas needs to create the file "$rawfile". "
     echo "ERROR: You do not have permission to overwrite "$rawfile". "
     set flag=28
     goto leave
    endif
    if ((-e "$infile") && ($replace == "" )) then
     echo -n "WARNING: "$infile" already exists; overwrite? (y/n) "
     set yesorno=$<
     if (($yesorno != "y") && ($yesorno != "Y")) then
      set flag=29
      goto leave
     endif
    endif
    if ((-e "$rawfile")  && ($replace == "" )) then
     echo -n "WARNING: "$rawfile" already exists; overwrite? (y/n) "
     set yesorno=$<
     if (($yesorno != "y") && ($yesorno != "Y")) then
      set flag=30
      goto leave
     endif
     set replace="replace"
    endif
   endif  # end of if sascode== "sascode" do loop.

   if ($verbal == 1) then
    echo " "
    if ("$use" == "savasas") then
     echo ...your Stata file is: "$datafile"
     if ("$sascode" == "" ) echo ...your SAS data file is: "$outfile"
    endif
    if ("$use" == "savastata") then
     echo ...your SAS file is: "$datafile"
     if ("$sascode" == "") echo ...your Stata data file is: "$outfile"
    endif
    if ($messy == 1) then 
     echo ...the files created by savas will be located in: "$tmpdir"/
     echo " "
    endif
    if ($sascode == "sascode") then
     if ("$use" == "savasas") then
      echo ...your SAS program to input the xport data is: "$infile"
      echo ...your xport data file is: "$rawfile"
     endif
     if ("$use" == "savastata") then
      echo ...your Stata program to input the raw data is: "$infile"
      echo ...your ASCII data file is: "$rawfile"
     endif
     echo " "
    endif
   endif #end of if verbal == 1

 if ("$use" == "savasas") then
   ############ SAVASAS CODE ############################################
   # Create the Stata do-file to get file contents:
   set cons="$tmpdir"/_$$_con.do
   set conl="$tmpdir"/_$$_con.log
   if ($sascode == "sascode") set sasl="$out_dir"/"$destfile"_infile.log
   if ($sascode == "") set sasl="$tmpdir"/_$$_infile.log
   set filesize=`ls -s "$datafile" | awk 'NF>0 {print $1}'`
   echo "global memory = int($filesize * 1.1)" >> $cons
   echo ' if $memory < 20000 { '  >> $cons
   echo '  global memory ="20000k" ' >> $cons
   echo " } " >> $cons
   echo " else { " >> $cons
   echo '  global memory = "$memory"+"k" ' >> $cons
   echo " } " >> $cons
   echo ' set memory $memory'    >> $cons
   echo "" >> $cons
   set  keep_obs=""
   if ($nobs != 0) then
    set  keep_obs=" in 1/$nobs"
   endif
   if ("$varfile" != "") then
    echo 'local my_vars "' `cat $varfile` '"' >> $cons
   endif
   # SEMP is 1 if either $S_StataSE or $S_StataMP = 1
   echo  'local SEMP = ("$S_StataSE"!="" | "$S_StataMP" != "")' >> $cons
   echo  capture use \`my_vars\'  $keep_obs  using \"$datafile\"   >> $cons
   echo   if _rc!=0 \& \`SEMP\' {   >> $cons
   echo    set maxvar 10000     >> $cons
   echo    capture use \`my_vars\'  $keep_obs  using \"$datafile\"   >> $cons
   echo    if _rc!=0 \& \`SEMP\' {   >> $cons
   echo     set maxvar 20000     >> $cons
   echo     capture use \`my_vars\'  $keep_obs   using \"$datafile\"   >> $cons
   echo     if _rc!=0 \& \`SEMP\' {   >> $cons
   echo      set maxvar 32767     >> $cons
   echo      capture use \`my_vars\'  $keep_obs  using \"$datafile\"   >> $cons
   echo     }    >> $cons
   echo    }    >> $cons
   echo   }    >> $cons
   echo   else if _rc!=0 \& \`SEMP\'==0 {   >> $cons
   echo  'global star="*" ' >> $cons
   echo  ' di "Dataset has more than 2,047 variables which requires Stata SE or MP.  $star " '   >> $cons
   echo  '} '  >> $cons

   echo $trace >> $cons

   # call savasas.ado 
   echo run \"$SAVASAS\" >> $cons
   if ((-e "$outfile") && ("$replace" == "replace") && ("$rights" == 1 )) then
    echo savasas using \"$tmpdir/$outfile:t\" , $replace $sascode messy type\($type\) $check sysjobid\(_$$\) $rename $formats udir\($tmpdir/\) usas\($SAS\) script >> $cons

   else 
    echo savasas using \"$outfile\" , $replace $sascode messy type\($type\) $check sysjobid\(_$$\) $rename $formats  udir\($tmpdir/\) usas\($SAS\) script >> $cons
   endif

   # Need to be in the directory where intermediary files are 
   cd "$tmpdir"/

   # Run Stata nicely to get the contents of the Stata dataset.
   $NSTATA -b do "$cons"


   # if replacing a file, move file from tmpdir to where it's supposed to be
   if ((-e "$outfile:t") && ( $replace == "replace")) then 
    mv -f "$outfile:t" "$outfile"
   endif

   # return to where user started 
   cd "$cur_dir"
 endif     ##### of SAVASAS CODE  #####

 if ("$use" == "savastata" ) then
   #######   SAVASTATA CODE  #############################################
   # Create the SAS program to get file contents:
   set cons="$tmpdir"/_$$_con.sas
   set conl="$tmpdir"/_$$_con.log
   set statal="$tmpdir"/_$$_infile.log
   echo "options nofmterr linesize=240;" > $cons

   # Use formats in a formats catalog file that are in the same directory as the dataset
   if ($formats == "formats") then
    if ("$engine" == "v6") then
     set fmtext = "sct01"
     if (-e "$in_dir.$ssdname.$fmtext") then 
      echo "options fmtsearch=(library.$ssdname library.formats); " >> $cons
      set formatsexist = 1
     endif
    else 
     set fmtext = "sas7bcat"
     if (-e "$in_dir/$ssdname.$fmtext") then 
      echo "options fmtsearch=(library.$ssdname library.formats); " >> $cons
      set formatsexist = 1
     endif
    endif
    if ($xport == 0 ) then 
     echo "libname library $engine '"$in_dir"' ; %let star=*;" >> $cons
    else 
     echo "libname library /* default engine */ '"$in_dir"' ; %let star=*;" >> $cons
    endif
    if ($formatsexist == 1) then
     echo "proc datasets; copy in=library out=work memtype=catalog;  " >> $cons
     echo "select $ssdname; change $ssdname=formats;  run; " >> $cons
    endif
    if ($formatsexist == 0) then
     echo "WARNING:  You have asked to use formats in $ssdname.sas7bcat formats catalog file "
     echo " that is located in the same directory as the dataset $in_dir/$ssdname.$ext, "
     echo " but there is no $in_dir/$ssdname.$fmtext formats catalog file in that directory.  " 
    if (($xport == 1 ) && ( ! -e "$in_dir/formats.$fmtext")) then 
      echo "NOTE: Savas can use $in_dir/formats.$fmtext for a formats file."
    endif
     if (-e "$in_dir/formats.$fmtext") then 
      echo "NOTE: Savas found $in_dir/formats.$fmtext and will use that for formats."
     else
      echo " Savas will continue to process your dataset anyway." 
     endif # end of format.sas7bdat exist 
    endif # end of formatsexist 
   endif  # end of formats 

   if ($xport == 0) then
    echo "libname in "$engine" '"$in_dir"' ;" >> $cons
   endif
   if ($xport == 1) then
    # libref assigned later in script
   endif

   if ($nobs != 0) then
     echo "option obs="$nobs";" >> $cons
   endif
   echo "%let sortedby=  ;" >> $cons  # leave for now since passing empty macro to savastata 
   if ($xport == 0) then
    if ("$varfile" == "") then
     echo "data "$ssdname"; set in."$ssdname"; run;" >> $cons
    else
     echo "data "$ssdname"; set in."$ssdname" (keep = " >> $cons
     cat $varfile >> $cons
     echo ");  run;" >> $cons
    endif
   endif # of if xport=0 loop

   if ($xport == 1) then
     echo 'filename ___in___ "'$datafile'";  ' >>  $cons
     echo '%macro ___xt___ ;  data _null_;  infile ___in___ ;   input  xt $ 1-6; ' >> $cons
     echo '  call symput("header",xt);   if _n_ = 1 then stop;  run; ' >> $cons
     echo ' %if %index(&header.,HEAD) ^= 0 %then %do; '      >> $cons
     echo '  libname ___in___ xport "'$datafile'";     data _null_;   set sashelp.vmember;  '    >> $cons
     echo '   if upcase(libname)="___IN___" and upcase(memtype)="DATA" then call symput("namex",memname); ' >> $cons
     echo "run;   %let namex=%trim(&namex); %if %upcase(&namex)^=%upcase("$ssdname") %then %do; " >> $cons
     echo "%let namex=%sysfunc(lowcase(%nrbquote(&namex))); " >> $cons
     echo 'data _null_ ; file "'$out_dir'/_'$$'_namex";  put "'$out_dir'/&namex..dta";  run; ' >> $cons
     echo "%put ...the name of the dataset in the SAS transport file "$datafile" is: &namex .  *; %end; " >> $cons
  
     echo "data &namex; set ___in___.&namex. "  >> $cons
     if ("$varfile" != "") then
       echo " (keep =  " >> $cons
       cat $varfile >> $cons
       echo ") " >> $cons
     endif
     echo ";  run; %end;" >> $cons
     #try to process an SPSS portable file
     echo ' %else %if %index(%lowcase('$datafile'),.por) %then %do; proc convert spss=___in___ out='$ssdname '; run;' >> $cons
     echo "%end;  " >> $cons
     #end SPSS loop
  
     echo ' %else %do; proc cimport data='$ssdname  >> $cons
     echo "infile=___in___; run; " >> $cons
     echo "%if &syserr ^= 0 %then %do; "  >> $cons
     echo " %put ERROR: SAS could not open '$datafile' because it was created in a newer version of SAS *;" >> $cons
     echo " %put ERROR:  or there is not just a data set named '$ssdname' in the file.   *;" >> $cons
     echo "%end;  " >> $cons
     if (($nobs != 0) || ("$varfile" != "")) then
       echo "%else %do; " >> $cons
       echo "data $ssdname ;  set $ssdname ( " >> $cons
       if ($nobs != 0) then
         echo "obs="$nobs  >> $cons
       endif
       if ("$varfile" != "") then
         echo "  keep = " >> $cons
         cat $varfile >> $cons
       endif
       echo "); run; " >> $cons
       echo "%end; " >> $cons
     endif
     echo "%end;   %mend ___xt___; " >> $cons
     # now run the ___xt___ macro 
     echo "  %___xt___; "  >> $cons

   endif  # of if xport file do loop
   
   if ("$trace" != "") then
    echo "options mprint;" >> $cons
   endif
   echo "%include'"$SAVASTATA"'; " >> $cons
   if ((-e "$CHAR2FMT") && ("$char2lab" != "")) then
    echo "%include'"$CHAR2FMT"'; " >> $cons
   endif
   if ($ascii == "ascii") then
    echo %savastata\(\"$out_dir/$outfile:t\", $old $intercooled $ascii $char2lab $check $replace $float $quote >> $cons
    echo  messy, \&sortedby , $destfile\)\; >> $cons   # destfile is used instead of $$ so that files have a nicer name
   else if ($ascii == "")  then
    echo %savastata\(\"$tmpdir/$outfile:t\", $old $intercooled $ascii $char2lab $check $replace $float $quote >> $cons 
    echo  messy, \&sortedby , $$, ,\"$out_dir\/\"\)\;  >> $cons
   endif


   # Run SAS to get the contents of the SAS dataset.
   $NSAS  -LOG $conl $cons


 endif     ##### of SAVASTATA CODE  #####

   # Hats off to Kasey Kasem!  
   # See if there were any *&$X%! messages from savas in con.log. 
   # savas error and warning messages have stars in them.
   if ($verbal == 1) then 
    echo " "
    #check to see if log file exists which indicates process is done
    if ( ! -e "$conl") then
     echo "...Hmmm? $USE_S didn't create $conl . "
     echo "...Make sure that $USE_S is not set up to run in the background."
     echo -n "...Want to check to see if $USE_S is still running?  (y/n)"
     set yesorno=$<
     if (($yesorno == "y") || ($yesorno == "Y")) then
      log_checker:  # come back to here if want to keep checking
      ps | grep " $use_s" | grep -v grep
      set yup=$status
      while ( $yup == 0 )
        echo -n "...Want to check again to see if $USE_S is still running?  (y/n)"
        set yesorno=$<
        if (($yesorno == "y") || ($yesorno == "Y")) then
         ps | grep " $use_s" | grep -v grep
         set yup=$status
        else
         echo -n "...Okay. Want to exit?  (y/n)"
         set yesorno=$<
         if (($yesorno == "y") || ($yesorno == "Y")) then
          set status=1
          if (-e "$cons") then 
            echo "These intermediary files have been created in $tmpdir :"
            set oldpwd="$PWD"
            cd "$tmpdir"
            ls -lt _$$*
            #cd - because this doesn't work in AIX
            cd "$oldpwd"
          else
            echo "Buh-bye!"
          endif
          set flag=37
          goto leave
         #else it continues looping
         endif
        endif
      end  # end of while
      echo " "
      echo "...Okay, we're good to go!..."
      echo " "
     else
      echo -n "...Okay2. Want to exit?  (y/n)"
      set yesorno=$<
      if (($yesorno == "y") || ($yesorno == "Y")) then
       set yup=1
       if (-e "$cons") then
         echo "These intermediary files have been created in $tmpdir :"
         set oldpwd="$PWD"
         cd "$tmpdir"
         ls -lt _$$*
         #cd - because this doesn't work in AIX
         cd "$oldpwd"
        else
         echo "Buh-bye!"
       endif
       set flag=38
       goto leave
      else
       echo "...Going back to checking in on $USE_S ..."
       goto log_checker
      endif
     endif  # if want to check if $use_s is still running
    endif  # if $conl doesn't exist
    # if $conl exists:
    if (-e "$conl") then
     if ("$use" == "savasas") then
      echo "...Notes from Stata's look at the dataset:"
      echo " "
      # not sure why grepping for savasas.ado, kinda nice to see which savasas is run
      #  so added if debug is on
      if ($debug == 1) then
        #formerly used egrep because wanted to grep for both stars and "savasas.ado"
        #egrep " \*|savasas\.ado"  $conl  | grep -v global
        grep "savasas\.ado"  $conl  | grep -v global
      endif
      grep " \*"  $conl  | grep -v global
     else if ("$use" == "savastata") then
      echo "...Notes from SAS's look at the dataset:"
      echo " "
      grep " \*"  $conl | grep -v "%put"
     endif
    endif
   endif  # end of if verbal


  if ("$use" == "savasas" ) then
   # See if there was a Stata error. 
   grep '^system limit exceeded - see manual' $conl > /dev/null
   if ($status == 0) then
    echo " "
    echo "Something went wrong in Stata; check its log-file, "$conl".  Most"
    echo "likely, insufficient memory was available to read in the data."
    set flag=31
    goto leave
   else
    grep '^r(' $conl > /dev/null
    if ($status == 0) then
     echo " "
     echo "Something went wrong while Stata was trying to determine the contents of"
     echo "the dataset.  Check file $conl for the error."
     #echo "Remember to delete all savas's intermediary files:" $tmpdir"/"_$$"*"
     echo "Remember to delete all savas's intermediary files in $tmpdir :"
     set oldpwd="$PWD"
     cd "$tmpdir"
     ls -lt _$$*
     #cd - because this doesn't work in AIX
     cd "$oldpwd"
     set flag=32
     goto leave
    endif

    # Check that SAS ran without errors:
    if (-e "$sasl" ) then
     grep  ERROR: $sasl | grep -v _ERROR_ >& /dev/null
     if ($status != 0) then
      set success=1
      if ($sascode == "" ) then
       if ((-e "$outfile") && (-e "$usagelog")) then
        echo "   " `ls -l "$outfile"` >> $usagelog
       endif
      endif
     endif  # end of if status != 0 i.e. success
    endif  # if saslog exists
    if ($sascode == "sascode" ) then
     if (-e "$rawfile") then
      set success=1
      if (-e "$usagelog") then
       echo "" >> $usagelog
       echo "  " `ls -l "$rawfile"` >> $usagelog
      endif
     endif
    endif  # end of if sascode only 
   endif  # end of else status not == 0 
  endif  # end of savasas's check for error

  if ("$use" == "savastata" ) then
   # See if there were any SAS error messages in con.log.
   grep ERROR  $conl | grep -v "Errors printed on page" | grep -v "Given transport file is bad" | grep -v " \*"  >& /dev/null
   if ($status == 0) then
    echo " "
    echo Something went wrong while SAS was trying to determine the contents of
    echo the dataset.  Check file $conl for the ERROR:
    grep ERROR: $conl | grep -v "Errors printed on page" | grep -v " \*"
    #echo "Remember to delete all savas's intermediary files:" $tmpdir"/"_$$"*"
    echo "Remember to delete all savas's intermediary files in $tmpdir :" 
    set oldpwd="$PWD"
    cd "$tmpdir"
    ls -lt _$$*
    #cd - because this doesn't work in AIX
    cd "$oldpwd"
    set flag=33
    goto leave
   endif

   # if error found by savastata not by SAS
   grep ERROR  $conl | grep  " \*"  >& /dev/null
   if ($status == 0) then
     goto next
   endif

   # check that Stata ran without errors:
   if (-e "$statal") grep '^r(' $statal > /dev/null
   if ($status != 0) then
    set success=1
    if ($ascii == "" ) then
     if ((-e "$datafile") && (-e "$usagelog")) then
      echo "   "`ls -l "$datafile"` >> $usagelog
     endif
    endif
   endif  # end of if no errors found in Stata log i.e. success
   if ($ascii == "ascii" ) then
    if (-e "$rawfile") then
     set success=1
     if  (-e "$usagelog" ) then
      echo "   "`ls -l "$rawfile"` >> $usagelog
     endif
     echo "These are the files you requested to be created:"
     ls -l "$out_dir"/_"$destfile"_*
    endif
   endif
  endif  # end of savastata check for errors


   if ("$success" == 1 ) then   ## if outputfile was created without error
    if ($sascode == "" ) then  # fix dta file permissions.

     ############################################################
     # Code to make the file permissions for the stata file
     #  to be the same as the sas file
     #  written 21nov2001 by jlw
     set owner=0
     set group=0
     set world=0
     #  begin reading the permissions column by column
     set perms=`ls -l "$datafile" | cut -c2 `
     if ( "$perms" == r ) @ owner=`expr $owner + 4 `
     set perms=`ls -l "$datafile"  | cut -c3`
     if ( "$perms" == w ) @ owner=`expr $owner + 2 `
     set perms=`ls -l "$datafile"  | cut -c4`
     if ( "$perms" == x ) @ owner=`expr $owner + 1 `
     set perms=`ls -l "$datafile"  | cut -c5`
     if ( "$perms" == r ) @ group=`expr $group + 4 `
     set perms=`ls -l "$datafile"  | cut -c6`
     if ( "$perms" == w ) @ group=`expr $group + 2 `
     set perms=`ls -l "$datafile"  | cut -c7`
     if ( "$perms" == x ) @ group=`expr $group + 1 `
     set perms=`ls -l "$datafile"  | cut -c8`
     if ( "$perms" == r ) @ world=`expr $world + 4 `
     set perms=`ls -l "$datafile"  | cut -c9`
     if ( "$perms" == w ) @ world=`expr $world + 2 `
     set perms=`ls -l "$datafile"  | cut -c10`
     if ( "$perms" == x ) @ world=`expr $world + 1 `
     #  calculate the final mode
      @ perms=`expr 100 \* $owner + 10 \* $group + $world `
     if (( $xport == 1 )  && ( -e "$out_dir"/_$$_namex )) then
       set xfile = `cat "$out_dir"/_$$_namex`
       if ( "$xfile" != "$datafile" ) set datafile="$xfile"
     endif
      if ( "$rights" == 0 ) then
        chmod $perms "$outfile"
      endif
     # end of code to figure file permissions
     ############################################################

    endif   # end of fixing dta file permisions.
      
    if ( "$check" == "check" ) then 
     if ("$use" == "savasas" ) then
      set checkfile = "$out_dir"/"$destfile""_STATAcheck.log"
      mv -f "$conl" "$checkfile"   # make Stata log file into _STATAcheck.log file 
     endif
     echo "...You have requested savas to generate a check file from SAS and Stata: "
     ls -lt "$destfile"_*check*
    endif
     goto next
   else    # if not success 
    if ("$use" == "savasas") then
     if ($sascode == "" ) then
      echo "ERROR: $outfile has not been created or modified."
      if (-e "$sasl" ) then
       grep ERROR: $sasl | grep -v "Errors printed on page"
       echo "Check "$sasl " for errors"
      endif
     endif
    endif
 
    if ("$use" == "savastata") then
     echo " "
     if ($ascii == "" ) then
      echo "ERROR: $outfile has not been created or modified."
     endif
     if ($ascii == "ascii" ) then
      echo "ERROR: $rawfile has not been created."
     endif
      echo " "
      grep '^system limit exceeded - see manual' $statal > /dev/null
      if ($status == 0) then
         echo "Something went wrong in Stata; check its log-file, "$statal".  Most"
         echo "likely, insufficient memory was available to read in the data. All"
      else
         echo "Something went wrong in Stata; check its log-file, "$statal".  All"
      endif
      echo "intermediary files are still in "$tmpdir" directory; all names begin"
      echo "with '_$$'.  Try to invoke Stata and read in the ascii data"
      echo  manually, by doing the file:     \"$tmpdir _$$_infile.do\"
      #echo "Do not forget to remove all intermediary files, $tmpdir '_$$*'."
      echo "Remember to remove all intermediary files $tmpdir :"
      set oldpwd="$PWD"
      cd "$tmpdir"
      ls -lt _$$*
      #cd - because this doesn't work in AIX
      cd "$oldpwd"
      echo " "
      set messy=1
      set flag=34
      goto next
     endif  # end of if savastata 

     if ($sascode == "sascode" ) then
      echo "ERROR: $rawfile has not been created."
     endif
      set messy=1
      set flag=35

      goto next
   endif  # end of success. There, I said it.

  next:  # Control is passed here to go to the next SAS file

  if ($verbal == 1) then
    echo " "
    echo " TIP: "
    if ("$use" == "savasas" ) then
     echo "...The Stata command -savasas- can save a Stata dataset "
     echo "...as a SAS dataset.  Copy and paste the following into Stata: "
     echo "  "  savasas using \"$out_dir/$outfile:t\", type\($type\) $replace $formats $rename $check $sascode 
    echo " "
    else
 echo "...The SAVASTATA SAS macro can save a SAS temporary/work (not saved) dataset "
 echo "...as a Stata dataset.  Copy and paste the following into your SAS program: "
     echo "  "  \%include\"$SAVASTATA\"\;
     echo "  "  \%savastata\(\"$out_dir/$outfile:t\",$replace $rename $quote $intercooled $formats $old $check $float $ascii \)\;
    echo " "
    endif
  endif  #end if $verbal == 1

       # Clean up after each SAS dataset is processed if -messy option not specified.
     if ($messy == 0) then
        ## cd to tmpdir since csh does not like this:
        ## rm -f "$tmpdir"/_$$*
        set oldpwd="$PWD"
        cd "$tmpdir"
        rm -f _$$*
        #cd - because this doesn't work in AIX
        cd "$oldpwd"
     else if ($messy == 1) then
      echo "...You have requested savas not to delete the intermediary files created by savas: "
      echo "...which are located in: $tmpdir : "
      ## cd to tmpdir since csh does not like this:
      ## ls -lt "$tmpdir"/_$$*
      set oldpwd="$PWD"
      cd "$tmpdir"
      ls -lt _$$*
      #cd - because this doesn't work in AIX
      cd "$oldpwd"
     endif


     if ( $#datafiles > 1 ) then
       #reset rename and replace if -force not set
       if ("$force" == "") then
         set rename=""
         set replace=""
       endif

       if (( $#datafiles > 1 ) && ( $f_loop_n != $#datafiles )) then
         echo '=-=-=-=-= Now processing the next dataset =-=-=-=-='
       endif
     endif

end  # end of foreach datafile loop.


# skip over panic
goto leave

# Following is some code to clean up
panic:   # script jumps to this label if the user hit <ctrl+C>
set flag=36

leave:   # some error was encountered; exit after some housekeeping
if (-e "$usagelog") then
   echo "   Error code $flag" >> $usagelog
   echo "" >> $usagelog
endif
if ($beep == 1) echo ^G

exit $flag

