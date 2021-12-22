*!version 2.0.0 EMZ    08nov2021
* version 1.2.13EMZ    08nov2021
* version 1.2.12EMZ    04nov2021
* version 1.2.11EMZ    21oct2021
* version 1.2.10EMZ    07oct2021
* version 1.2.9 EMZ    16sep2021
* version 1.2.8 EMZ    21june2021
* version 1.2.7 EMZ    20may2021
* version 1.2.6 EMZ    15apr2021
* version 1.2.5 EMZ    12apr2021
* version 1.2.4 EMZ    01mar2021
* version 1.2.3 EMZ    15feb2021
* version 1.2.2 EMZ    04feb2021
* version 1.2.1 AB/EMZ 28jan2021
* version 1.2.0 EMZ    26oct2020
* version 1.1.9 EMZ    17sep2020
* version 1.1.8 EMZ    03sep2020
* version 1.1.7 EMZ    24aug2020
* version 1.1.6 EMZ    13aug2020
* version 1.1.5 AGB    08may2020
* version 1.1.4 EMZ    30may2019
* version 1.1.3 EMZ    11mar2019
* version 1.1.2 PR     17apr2018
* version 1.1.1 AGB    05aug2016
* version 1.1.0 AGB    12feb2014
* version 1.0.0 SB     06mar2004
* version 1.0.0 PR     23mar2004
* Based on Abdel Babiker ssizebi.ado version 1.1  20/4/97

*	History
	
/*
2.0.0   08nov2021   Release
1.2.13  08nov2021   Minor change to favourable/unfavourable text in output table
1.2.12  04nov2021   Fixed so that returned results for number of events -r(D)- is unrounded.
1.2.11  21oct2021   Added extra line in output table for fav/unfav status if user has not specified it.  Changed some wording of the error 
                    messages.  Disallowed -doses- for 2-arm trials.
1.2.10  07oct2021   Changed wording in table for fav/unfav as per PR suggestion.
1.2.9   16sep2021   From PR testing: put version statements in to all subroutines.  Modified and streamlined error messages. Added ltfu() option.
1.2.8   21june2021  Bug fix: ccorrect was not displaying in output table if undocumented nchi option was used, now fixed.
1.2.7   20may2021   As a result of IW testing: Added fav/unfav options to 2-arm superiority case.  Changed ordering of the output table.  Put returned 	
					values in order for k groups.  Made minor formatting changes to error messages, output table and decimal places. Using artbin v 0.12.
					Issue a warning when p1+margin is not in (0,1).  If user specifies n (to calculate power) turn noround on (otherwise for example, if 
					the user specifies n(1000) for 3 groups they will obtain n = 1002 as each group SS of 333.33 rounded up to 334).
1.2.6   15apr2021	Put score test in table output when the defult is used (to make it clear for the user).  Updated the banner in artbin to
					include all authors.  Changed the expected number of events (D) to be calculated on rounded n (if n is rounded), and to not round
					D itself except to display it in the output table. Using artbin v 0.11.
1.2.5   12apr2021   From IW testing results: replaced q0 with q1 in equation for k-arms trend wald test, as before wald was giving the same answer as 	
					score for this test.  Removed the warning message so that if the user selects wald the default will go to nvm(1) *without* a 
					warning message.  Removed reference to nvm from the output table.  Added in an error message for > 2 groups if the user specifies 
					less numbers in aratios than prs, send to error message [as aratios(2) means aratios(1 2) for 2 arms but 
					aratios(2 2 2) with 3 arms]. Changed the output table so that the wald test is included in the description of the statistical test 
					used, with the separate wald yes/no line removed. For >2 groups the alpha output to just be alpha (value).  Wrote out the doses for 
					the trend test in the table.  Changed the returned values so that the following are available: total SS, SS per group, number of 
					events and power.  Changed the code so that rounding is done per arm for all groups, including for code that is sent to art2bin.  Put 
					breakdown of ss per group in output table and in returned values for > 2 groups.  Put in error message if user tries to use old syntax
					(-ni- or -distant-) - included distant as a numlist back in the syntax options so can alert any users who are trying to use the old 
					syntax.  Changed all the error messages/checks involving ni to involving margin criteria instead.  Also added error message for  
					conditional and wald being specified together.												
1.2.4   01mar2021   From IW testing results: Added returned results of n/power and D if user selects -notable-.  Put all output options in sentence 
                    case.  Took out null variance method used in table output.  Changed art2bin v009 to 010.  Made table output for 2 and 2+ arm 
					superiority trials consistent.  Applied -noround- to D as well.
1.2.3   15feb2021   If conditional and not local (i.e. default distant) are selected, produce warning message saying local will be used instead. Added 
                    error message if user specifies ccorrect in the 2-arm superiority conditional case as not currently available.	Put in the output 
					table when ccorrect and wald have been used.  Added in an undocumented option -algorithm- for testing to state whether the k-arm or 
					2-arm (art2bin) algorithm has been used to calculate the sample size/power.
1.2.2   04feb2021   Put error message in if user specifies conditional and not local (distant).	Put in favourable/unfavourable trial outcome options 
					(user can specify fav/unfav, if specified then sense checked, if not specified then inferred).  	
					Removed eventtype(string) option as this has been super-seeded by favourable/unfavourable.  Changed super-superiority terminology to
					be substantial-superiority.  Made pr() into a numlist instead of a string, to prevent program errors occuring when the user specifies 
					pr(0.000001 0.000002) (when a string, Stata converts this to 1.00000000e-06 2.00000000e-06).
1.2.1   28jan2021   Changed default in syntax to NVMethod(numlist max=1) (instead of NVMethod(int 0)).  This is because we need to distinugush cases 
					where the user has actually specified nvm (as opposed to leaving it blank, e.g. when nvm() is not specified and wald is selected, the 
					code defaults to nvm(1)). Otherwise the default nvm is set to 3 later in the code. Allow local to be specified with ni and 
					margin!=0 as per Ab's advice.  Added in coding for wald & > 2 groups. (These were the changes made by AGB to artbin_v119ab/suggested 
					by Ab, put in to this version by EMZ).  Now calls art2bin_v009 instead of v008. Removed the error message if >2 arm trial and user 
					specifies local and condit. 	
1.2.0   26oct2020   Tidied unused code and typos.  Changed so that wald without nvm() goes to nvm(1) (instead of an error message) with a warning that
					the default nmv(3) has been changed to nvm(1).  Added in error message for wald with 3+ groups.  Changed local D=int(`D'+1) to 
					local D=ceil(`D'), and applied -ceil- to the other calculations of D (e.g. for superiority). Calls art2bin_v008 which has also had 
					rounding change.  Added undocumented option notable so that just the sample size/power can be outputted for testing.  Changed the 
					format of the macro altp to take out the spaces/addtional quotation marks.
1.1.9   17sep2020   Changed the code so that condit is allowed for superiority 2 groups and is sent to the artbin code (as opposed to art2bin) in this 
					case.  Changed the rounding of the sample size to be rounded UP to the nearest integer.  Calls art2bin_v007 which has also had 
					rounding change.
1.1.8   03sep2020   Changed the code so that the user is to identify whether the trial aim is to demonstrate that the intervention increases or 
					decreases the outcome probability relative to {control probability + margin} and then the program determines the type of trial 
					(NI/Sup-sup/Sup). Therefore took out error message if user specifies margin(<0) and specifies ni, error message if user specifies 
					margin(> 0) and doesn't specify ni and added error mesages so that the user can not specify ni(0) and an NI trial design, or a 
					Super-superiority trial design and ni.  Changed alpha 2-sided output in table so states two-sided (taken as `alpha/2' one-sided). 
					Produce error messages for the following cases: if 2-arm trial and user specifies condit (if not undocumented nchi), if 2-arm trial 
					and user specifies trend, if >2 arm trial and user specifies local and condit, if 2-arm trial with undocumented nchi and user 
					specifies local and condit or the trend test.  Change rounding option so rounds n to the nearest integer if -noround- (new option) is 
					not specified
1.1.7   24aug2020   From v1.1.0 onwards where art2bin was called for non-inferiority trials, the margin was taken as p2-p1 and p2 was reset to p1.  This 
					has now been changed so that if the user selects ni then they will have to specify a margin, and p1 p2 will remain as entered in 
					pr(). Added in error message to not allow Wald and Local at the same time, to not allow local & nvmethod ~=3 with nvmethod=3 as the 
					default.  Add in error message so do not allow Wald & nvmethod ~=1.
1.1.6   13aug2020	Put in the following error messages: If user specifies negative ni() produce error message.  Also produce error message in the 
                    following cases: If the user specifies margin(> 0) and doesn't specify ni, if specifies margin (0) and specifies ni, if specifies 
					margin(<0) and ni.  Put in description table whether local or distant, whether artbin or art2bin calcs used, whether the trial is “NI 
					(margin >0)" or “Super-superiority (margin <0)" or "Superiority (margin = 0)".  Added in code so ccorrect can be turned on/off like ni 
					and onsesided.  Put in error message so can't specify margin!=0 and local.  Changed allocation ratio coding so that it is always 
					displayed for every permuation (previously was missing in the display for artbin v 1.1.2 for trial artbin, pr(0.05 0.08)  alpha(0.05) 
					power(0.8) ni(1) ar(1 2)).  Changed wrapper so that it includes an option for super-superiority trial (margin<0). Added in error 
					message so can't have NI and local.  Changed wrapper so that art2bin is called in all cases where there are 2 groups, except for the 
					undocumented case of superiority 2-arms nchi. Added in warning message that if have NI and nchi / non-zero margin and nchi that it 
					won't be nchi (as it will go to art2bin). Added in Wald option to artbin syntax so it can be parsed to 
					the new art2bin v0.05 which has this additional option.  Added local and wald macros to the code where art2bin is called, as the new 
					version now has these options.  Added in error msg so that numlist is not allowed in pr().
1.1.5   08may2020   Changed the artbin code so that distant is the default option (not local): the option distant() was removed and replaced by    
                    -local- in the syntax.  Used simpler formula for trend when there are only twogroups.  Other code simplification.  
1.1.4   30may2019   Removed the error message "By specifying n(0) / n() missing, sample size will be calculated by artbin" and added a clarification 
                    instead in the helpfile.  Changed the error message of 'Number of groups equals 2 but more than 2 proportions specified.  Mean of the 
					proportions will be taken' to be a general warning message stating 'Mismatch between the number of proportions and the number of 
					groups specified - ngroups value will be ignored.'  Changed the default number of groups to be the number of proportions (npr), 
					instead of 2 as per previous versions of artbin.  
					Also changed the value of ngroups to be the number of proportions in all cases where there is a mismatch between the two values. 
					Please note that previously, if ngroups > npr and npr > 2 then artbin would calculate each of the remaining probabilities to be equal 
					to the mean of the given event probabilities.  This is now not the case - the ngroups value will be replaced by the npr value and a 
					warning message will be issued.  Also moved these ngroups modifications/warnings to be before the art2bin wrapper code.   
					Changed "Number of groups" in the output table to be `npr' instead of `ngroups' so that the correct number is taken when there is a 
					mismatch.  Commented out the screen printing of the ni value and superiority/non-inferiority.   Placed the 'ap2' error message (Group 
					2 event probability under the alternative hypothesis must be >0 & <1) to be before the art2bin wrapper. 
					Took out the restriction on margin being between 0 and 1.  Changed text output from P0 and P1 to P1 and P2.  Please note therefore 
					that the control group for non-inferiority trials is P1.  
1.1.3   11mar2019   Added margin option in.  Added nchi as an option in the syntax.  Added a wrapper to call art2bin if number of proportions =2 and nchi 
                    is not specified. Returned art2bin results so that the output is the same as the artbin output (i.e. not just a single number).
                    Changed version number in table output. Added in option to switch ni on and off, while retaining existing syntax. Added eventtype 
					option in.
					Restricted p0, p1 etc so that they can only take values between 0 and 1 (previosuly allowed >1).  Put in a warning message that the 
					mean of the proportions will be taken if the user specifies more than 3 proportions but ngroups=2.  Put in warning message to clarify 
					that if a sample size of 0 is specified (n(0)) then sample size will actually be calculated.  Changed ngroups to be a numlist instead 
					of integer with defaut = 2 so that it can be identified whether or not the user actually specified ngroups() or left it missing 
					(required for some of the error messages).  Created error message if p0=p1.  Created error message if margin is not between 0-1 and
					if margin is specified with more than 2 groups.  Changed table output so that Ho : p1 - p0 >= mrg.  Changed text output so consisitent 
					with art2bin (using terminology p0 and p1 when 2 groups instead of p1 and p2).  Added in the option of Onesided so that the user can 
					also "switch" onesided on or off like ni.
1.1.2	17apr2018	Trivial correction to formatting of allocation ratios
1.1.1	05aug2016	One-sided option for non-inferiority corrected
					(previous version double-adjusted alpha)
1.1.0	12feb2013	Non-inferiority is now correctly implemented (calls art2bin)

*/
program define artbin, rclass
version 8

gettoken number : 1
if "`1'"! = "," {
    di as err "artbin syntax is: artbin, pr()"
	exit 198
}

syntax , PR(numlist min=2 >0 <1) [ Margin(numlist max=1) ALpha(real 0.05) ARatios(string) UNFavourable FAVourable UNFavorable FAVorable COndit LOcal 	///
	DOses(string) N(integer 0) NGroups(numlist max=1) ni NI2(numlist max=1) Onesided Onesided2(numlist max=1)		///
	POwer(real 0.8) TRend NVMethod(numlist max=1) ap2(real 0) Ccorrect Ccorrect2(numlist max=1) nchi WAld FORCE NOROUND NOTABLE ALGorithm ///
	DIstant(numlist max=1) LTFU(numlist max=1 >0 <1)]


local version "binary version 2.0 08nov2021"

numlist "`pr'"
local npr: word count `pr'


if !mi("`ni'") | !mi("`ni2'") {
	di as err "You are using the old syntax: pr(p1 p2) ni.  The new syntax for the equivalent expression is pr(p1 p1) margin(p2-p1)"
	exit 198
	}
	
if !mi("`distant'") {
	di as err " You are using the old syntax distant().  Distant is the default, if you require local please specify -local-"
	exit 198
}

if `npr'<2 {
	di as err "At least two event probabilities required"
	exit 198
}
numlist "`pr'", sort
local minpr : word 1 of `r(numlist)'
    local maxpr : word `npr' of `r(numlist)'
    if `minpr'<0 | `maxpr'>1 & `maxpr'!=. { 
	di as err "Event probabilities out of range"
	exit 198
    }  
	
if "`margin'"!="" & `npr'>2 & `npr'!=. { 
	di as err "Can not have margin with >2 groups"
	exit 198
    } 
	
	
if `npr'==2 & `minpr'==`maxpr' & "`margin'"=="" {
    di as err "Event probabilities can not be equal with 2 groups"
    exit 198
    } 

if ("`ngroups'"!="") & ("`ngroups'"!="`npr'") {
    di "{it: WARNING: Mismatch between the number of proportions and the number of groups specified - ngroups value will be ignored.}"
}
local ngroups = `npr'

* create a marker -niss- to indicate if non-inferiority/super-superiority trial (niss=1), otherwise superiority (niss=0).  

if mi("`margin'") | "`margin'"=="0" local niss 0
else local niss 1


* similarly do for onesided
local onesided2missing 0
if "`onesided2'"=="" local onesided2missing 1
if "`onesided2'"=="" local onesided2 0

if `onesided2'==0 & `onesided2missing'!=1 & "`onesided'"!=""  {
    di as err "Can not select both one-sided and two-sided"
	exit 198
}

* want if `onesided'==1, then onesided, otherwise two-sided.  
if (`onesided2'>0 | "`onesided'"!="") {
	local onesided 1 
	local sided two
}
else {
	local onesided 0
	local sided one
}


* similarly do for ccorrect
local ccorrect2missing 0
if "`ccorrect2'"=="" local ccorrect2missing 1
if "`ccorrect2'"=="" local ccorrect2 0

if `ccorrect2'==0 & `ccorrect2missing'!=1 & "`ccorrect'"!=""  {
    di as err "Can not select both ccorrect on and off"
	exit 198
}

* want if `ccorrect'==1, then ccorrect, otherwise off.  
if (`ccorrect2'>0 | "`ccorrect'"!="") local ccorrect 1 
else local ccorrect 0


* Produce warning message if user specifies ni/ss trial and nchi 
if `niss' & "`nchi'" == "nchi" {
		di "{it: WARNING: nchi will be ignored.}"
}

* Add in error messages to not allow local and wald at the same time
    if "`local'" != "" & "`wald'" != "" {
		di as error "Local and Wald not allowed together"
                exit 198
	}
	
* Do not allowe conditional and wald together
	if !mi("`condit'") & !mi("`wald'") {
			di as error " Conditional and Wald not allowed together"
			exit 198
	}

* Do not allow wald & nvmethod ~=1 (if nvm is specified)
	  if "`wald'"!="" & "`nvmethod'"!="" & "`nvmethod'"!="1" {
	  	di as error "Need nvm(1) if Wald specified"
        exit 198
	  }
	  
* If nvm() is not specified and wald is selected, default to nvm(1) 
	if "`wald'"!="" & "`nvmethod'"=="" {
		local nvmethod = 1
*	  	di "{it: WARNING: the default nvm(3) has been changed to nvm(1) as Wald has been selected}"
	  }

* Make nvmethod=3 the default if not specified 
	 if "`nvmethod'"!="" {
		if `nvmethod'>3 | `nvmethod'<1  {
		local nvmethod 3
		}
	 }
	 else if "`nvmethod'"=="" local nvmethod 3
	  	  
* Do not allow local & nvmethod ~=3
	  if "`local'"!="" & `nvmethod'!=3 {
	  	di as error "Need nvm(3) if local specified"
        exit 198
	  }

* Produce error message if NI/Sup-sup trial and user specifies condit 
if `niss'  & "`condit'"!="" {
	di as err "Can not select conditional option for non-inferiority/substantial-superiority trial"
	exit 198
	}
					
* Produce error message if if 2-arm trial and user specifies trend
if `npr' == 2 & "`trend'"!="" {
	di as err "Can not select trend option for a 2-arm trial"
	exit 198
}

* Produce error message if if 2-arm trial and user specifies doses
if `npr' == 2 & "`doses'"!="" {
	di as err "Can not select doses option for a 2-arm trial"
	exit 198
}

* Produce error message if 2-arm trial with undocumented nchi and user specifies local and condit
if `npr' == 2 & "`nchi'"!="" & "`local'"!="" & "`condit'"!="" {
	di as err "Can not select conditional AND local options for 2-arm nchi trial"
	exit 198
}

* Produce error message if 2-arm trial with undocumented nchi and user specifies the trend test	
if `npr' == 2 & "`nchi'"!="" & "`trend'"!="" {
	di as err "Can not select trend test for 2-arm nchi trial"
	exit 198
}

* If conditional and not local (i.e. default distant) are selected, produce warning message saying local will be used instead
if !mi("`condit'") & "`local'"=="" {
		* change to local with a warning message
		local local "local"
    	di "{it: NOTE: As conditional has been selected local will be used.}"
}


* Produce error message if ccorrect is specified in the 2-arm superiority conditional case as it is currently not coded
if `npr'==2 & (mi("`margin'") | "`margin'" == "0") & !mi("`condit'") & `ccorrect' {
    	di as err "Sorry ccorrect is not currently available in the 2-arm superiority conditional case"
	exit 198
} 

* Event probability in group 2 under the alternative hypothesis H1: range check*
if (`ap2'<0 | `ap2'>1) {
		di as err  "Group 2 event probability under the alternative hypothesis must be >0 & <1"
		exit 198
}


* If the user specifies n, turn noround on
if ("`n'"!="0") local noround = "noround"


* If there are >2 groups and the user specifies less numbers in aratios than prs, send to error message
if !mi("`aratios'") {
    numlist "`aratios'"
	local nar: word count `aratios'
		if `npr'>2 & `nar'<`npr' {
			di as err "Please specify the same number of aratios() as pr() for >2 groups"
			exit 198
		}
}
else local nar `npr'

* obtain cumulative sum of allocation ratios for sample size per group calculation
if !mi("`aratios'") {
		tokenize `"`aratios'"'
		forvalues a=1/`nar' {
			local allr`a' = "``a''"
		}
}
else forvalues a=1/`npr' {
	local allr`a' = 1
}

forvalues a=1/`nar' {
	if `a'==1 local totalallr = `allr`a''
	else local totalallr = `totalallr' + `allr`a''
}

* create marker if user has not entered fav/unfav status
if mi("`favourable'") & mi("`unfavourable'") local infer 1
else local infer 0

* From artcat: accommodate American spellings
if !mi("`favorable'") local favourable favourable
if !mi("`unfavorable'") local unfavourable unfavourable

if !mi("`unfavourable'") & !mi("`favourable'") {
	di as err "Can not specify both unfavourable and favourable"
	exit 198
}

 if `npr'==2 {
 	
		* if margin is not specified set it as the default 0
		if "`margin'" == "" local margin = 0
		if `margin' == 0 local trialtype = "superiority"

		tokenize `pr'
		local w1 `1'
		local w2 `2'

		local threshold = `w1' + `margin'
		if (`threshold' < 0 | `threshold' > 1) di "{it: WARNING: p1 + margin is not in (0,1)}"
		
		
		
	if mi("`favourable'`unfavourable'") { // infer outcome direction if not specified
	
		if `w2' < `threshold' local trialoutcome = "unfavourable"
		if `w2' > `threshold' local trialoutcome = "favourable"
	}
	else {
		
		if !mi("`unfavourable'") local trialoutcome = "unfavourable"
		if !mi("`favourable'") local trialoutcome = "favourable"	
	}
	
		if `w2' == `threshold' {
			di as err "p2 can not equal p1 + margin"
			exit 198
		}
		
		* Stop program with error if wrong option is used, unless 'force' is specified
		if "`trialoutcome'" == "unfavourable" & `threshold' < `w2' & "`force'" == "" {
			di as err "artbin thinks your outcome is favourable. Please check your command. If your command is correct then consider using the -force- option."
			exit 198
		}
		else if "`trialoutcome'" == "unfavourable" & `threshold' < `w2' & "`force'" == "force" {
			di "{it: WARNING: artbin thinks your outcome should be favourable.}"
		}
		if "`trialoutcome'" == "favourable" & `threshold' > `w2' & "`force'" == "" {
			di as err "artbin thinks your outcome is unfavourable. Please check your command. If your command is correct then consider using the -force- option."
			exit 198
		}
		else if "`trialoutcome'" == "favourable" & `threshold' > `w2' & "`force'" == "force" {
			di "{it: WARNING: artbin thinks your outcome should be unfavourable.}"
		}
		
		* Define NI and substantial-superiority
		if ("`trialoutcome'" == "unfavourable" & `margin' > 0 | "`trialoutcome'" == "favourable" & `margin' < 0) {
			local trialtype "non-inferiority"
		}
		else if ("`trialoutcome'" == "unfavourable" & `margin' < 0 | "`trialoutcome'" == "favourable" & `margin' > 0) {
			local trialtype "substantial-superiority"
		}
		if "`trialoutcome'" == "unfavourable" {
			local H0 = "H0: p2-p1>= `margin'"
			local H1 = "H1: p2-p1< `margin'"
		}
		else if "`trialoutcome'" == "favourable" {
			local H0 = "H0: p2-p1<= `margin'"
			local H1 = "H1: p2-p1> `margin'"
		}
	}
	
* Produce error message if user selects NI trial and niss=0
	if !`niss' & "`trialtype'" == "non-inferiority" {
		di as error "Can not select non-inferiority trial and superiority option (margin=0 or missing)"
        exit 198
	  }

* wrapper for art2bin to be called if ngoups=2 (unless undocumented case of superiority 2-arms nchi or if condit is specified)
	if `npr'==2 & !(`niss'==0 & "`nchi'"=="nchi") & "`condit'"=="" {
	    

	  * overwrite default for onesided and put in to required format for art2bin
	  if `onesided'==0 {
	       local onesided "" 
		   local sided "two"  
		   }
	  else {
	        local onesided "onesided"
			local sided "one"
			}
	  * overwrite default for ccorrect and put in to required format for art2bin  
	  if `ccorrect'==0 local ccorrect ""     
	  else local ccorrect "ccorrect"
	  * If margin is specified and it is a non-inferiority/substantial-superiority trial, then input p1 p2 and margin into art2bin as required
	  if ("`trialtype'"=="non-inferiority" | "`trialtype'"=="substantial-superiority") {
	  qui art2bin `w1' `w2', margin(`margin') n(`n') ar(`aratios') alpha(`alpha') power(`power') nvmethod(`nvmethod') `onesided' `ccorrect' `local' `wald' `noround'
		 }
	 * If it is a superiority trial, then margin=0 in art2bin 
	  else if "`trialtype'"=="superiority" {
	  qui art2bin `w1' `w2', margin(0) n(`n') ar(`aratios') alpha(`alpha') power(`power') nvmethod(`nvmethod') `onesided' `ccorrect' `local' `wald' `noround'
		 }
	  * for output table at the end
	  local p1 = `w1'
	  local p2 = `w2'
	  local Power `r(power)'
*	  local Margin1 `r(margin)'
*	  local nvm `r(nvm)'
*	  local method`nvm' "`r(vmethod)'"
	  local Alpha `r(alpha)'
	  local tit2 "unconditional comparison of 2 binomial proportions P1 and P2"
	  local allocr "`r(allocr)'"
	  local D `r(Dart)'                                                        
	  *di `D'
		  if `n'==0 {
	      local ssize 1
		  local n `r(n)'
		  local n1 = `r(n0)'
		  local n2 = `r(n1)'
          }
          else {
		  local ssize 0
		  local power `Power'
		  }
	  local altd1 = `w2' - `w1'
*	  frac_ddp `altd1' 3
	  local altd1 : di %6.3f `altd1'
*	  local altd `r(ddp)'
*	  frac_ddp `w1' 3
	  local w1dp : di %-6.3f `w1'
*	  local w1dp `r(ddp)'
*	  frac_ddp `w2' 3
      local w2dp : di %-6.3f `w2'
*	  local w2dp `r(ddp)'
	  local altp "`w1dp', `w2dp'"
	  local off 40
      local longstring 38
      local maxwidth 78
	  if "`local'" == "" local localdescr "distant"
	  else if "`local'" == "local" local localdescr "local"
	  local artcalcused "2-arm"
	}
   else {


if max(`alpha',1-`alpha')>=1 { 
	di as err "alpha() out of range"
	exit 198
}
if max(`power',1-`power')>=1 {
	di as err "power() out of range"
	exit 198
}
if `n'<0 { 
	di as err "n() out of range"
	exit 198
}

if `niss' & ((`npr'>2)|(`ngroups'>2)) {
	di as err "Only two groups allowed for non-inferiority/substantial superiority designs"
	exit 198
}

if `ccorrect' & (`ngroups'>2) {
	di as err "Correction for continuity not allowed in comparison of > 2 groups"
	exit 198
}
if `onesided' & (`ngroups'>2) {
	di as err "One-sided not allowed in comparison of > 2 groups"
	exit 198
}

if `n'==0 {
	local ssize 1
}
else local ssize 0


if "`local'"~="" {	/* local alternative (default is non-local) */
	local locmess "(local)"
	local localdescr "local"
}
else {
	local locmess "(distant)"
	local localdescr "distant"
	
}

* `Alpha' is value as supplied; `alpha' is for use in calculations
local Alpha `alpha'
if `onesided' {
	local alpha=2*`alpha'
	local sided one
}
else local sided two
local Power `power'	/* as supplied */
 
 if "`margin'"!="" & "`margin'"!="0" { 
	local tit2 "comparison of 2 binomial proportions P1 and P2"
	
	/* Method of estimating event probabilities for the purpose of estimating
		the variance of the difference in proportions under the null hypothesis H0 */
	local nvm = `nvmethod'  
	if `nvm'>3 | `nvm'<1 {
		local nvm 3
	}
	local method1 Sample estimate
	local method2 Fixed marginal totals
	local method3 Constrained maximum likelihood

	if "`aratios'"=="" | "`aratios'"=="1" | "`aratios'"=="1 1" {
		local allocr "equal group sizes"
		local ar21 1
	}
	else {
		tokenize `aratios'
		forvalues i=1/2 {
 			confirm number ``i''
 			if ``i''<=0 {
				di as err  "Allocation ratio <=0 not alllowed"
				exit 198
			}
		}
		local ar21 = `2'/`1'
		local allocr `1':`2'
	}
	tokenize `pr'
	local p1 `1'
*	frac_ddp `margin' 3
	local margin : di %6.3f `margin'
*	local Margin `r(ddp)'
	local p2 = cond(`ap2'==0, `p1', `ap2')
	local altp
	local co
	forvalues i=1/2 {
		frac_ddp `p`i'' 3
		local altp `altp'`co' `r(ddp)'
		local co ,
	}
	frac_ddp `p2'-`p1' 3
	local altd `r(ddp)'	// Difference in probabilities under alternative hypothesis //
	
	* overwrite default for onesided and put in to required format for art2bin
	  if `onesided'==0 {
	       local onesided "" 
		   local sided "two"  
		   }
	  else {
	        local onesided "onesided"
			local sided "one"
			}
	  * overwrite default for ccorrect and put in to required format for art2bin  
	  if `ccorrect'==0 local ccorrect ""     
	  else local ccorrect "ccorrect"
	
	if `ssize' {
		qui art2bin `p1' `p2', margin(`margin') ar(`ar21')	///
		alpha(`alpha') power(`power') nvmethod(`nvm') `onesided' `ccorrect' `local' `wald' `noround'
		local n `r(n)'
		local artcalcused "2-arm"
	}
	else {
		local n0 = floor(`n'/(1+`ar21'))
		local n1 = floor(`n'*`ar21'/(1+`ar21'))
		qui art2bin `p1' `p2', margin(`margin') ar(`ar21') n0(`n0')	///
			n1(`n1') alpha(`alpha') nvmethod(`nvm') `onesided' `ccorrect' `local' `wald' `noround'
		local power `r(power)'	
		local artcalcused "2-arm"
	}
*	local D = ceil(`n'*(`p1' + `p2'*`ar21')/(1+`ar21'))                      
	local D = `n'*(`p1' + `p2'*`ar21')/(1+`ar21')
	*di `D'
}

else {                                                                          /*****************3+ groups starts here *************/
	// Superiority //
	local trialtype "superiority"
	preserve
	drop _all


* to revisit the following; - might not be neccessary 
* **********************************************************************************************
	if (`ngroups'==2) {	/* use trend test on 2 groups - more accurate for large alpha values */
		local trend trend
	}
* **********************************************************************************************

	qui set obs `ngroups'
	tempname PI pibar
	qui gen double `PI'=.
	tokenize `pr'
*	local altp : di %6.3f "`1'"
	frac_ddp "`1'" 3
	local altp `r(ddp)'
	forvalues i=1/`npr' {
		confirm number `1'
		if max(`1',1-`1')>=1 { 
			di as err "Event probabilities out of range"
			exit 198
		}	
		qui replace `PI'=`1' in `i'
		if `i'>1 {
			frac_ddp `1' 3
			local altp `altp', `r(ddp)'
		}
		macro shift
	}
	summ `PI',meanonly
	scalar `pibar'=r(mean)
	if r(max)<=r(min) {
		di as err "At least two distinct alternative event probabilities required"
		exit 198
	}

	tempname AR sar
	qui gen double `AR'=.
	if "`aratios'"=="" | "`aratios'"=="1 1" | "`aratios'"=="1 1 1" {
		qui replace `AR'=1/`ngroups'
		local allocr "equal group sizes"
	}
	else {
		scalar `sar'=0
		tokenize `aratios'
		* currently allocation ratios for this section are displayed as 1.00 : 2.00 instead of 1:2 like all other sections so changing it to be the same
		* frac_ddp `1' 2
		frac_ddp `1' 0
		local allocr `r(ddp)'
		local i 1
		while `i'<=_N {
			if "`1'"!="" {
				confirm number `1'
				if `1'<=0 {
					di as err  "Allocation ratio <=0 not alllowed"
					exit 198
				}
			
				qui replace `AR'=`1' in `i'
			}
			else qui replace `AR'=`AR'[`i'-1] in `i'
			scalar `sar'=`sar'+`AR'[`i']
			if `i'>1 {
				* currently alloc ratios for this section are displayed as 1.00 : 2.00 instead of 1:2 like all other sections so changing it to be the same
				* frac_ddp `AR'[`i'] 2
				frac_ddp `AR'[`i'] 0
				local allocr `allocr':`r(ddp)'
			}
			local ++i
			macro shift
		}
		qui replace `AR'=`AR'/`sar'
	}
	summ `PI' [w=`AR'],meanonly
	scalar `pibar'=r(mean)	
	local s = `pibar'*(1-`pibar')
	tempvar S
	gen double `S' = `PI'*(1-`PI')
	summ `S' [w=`AR'],meanonly
	local sbar=r(mean)
	tempname DOSE
	if "`trend'"!=""|"`doses'"!="" {
		local trtest "Linear trend test: doses are"
		qui gen double `DOSE'=.
		if "`doses'"=="" {
			qui replace `DOSE'=_n-1
			forval d = 1/`ngroups' {
			    if `d'==1 local tabledose `d',
				else if `d'!=`ngroups' local tabledose `tabledose' `d',
				else if `d'==`ngroups' local tabledose `tabledose' `d'
			}
			local doses "`tabledose'"
		}
		else {
			parse "`doses'",parse(" ")
			frac_ddp "`1'" 2
			local score `r(ddp)'
			local i 1
			while `i'<=_N {
				if "`1'"!="" {
					confirm number `1'
					if `1'<0 {
						di as err  "Dose < 0 not alllowed"
						exit 198
					}
					qui replace `DOSE'=`1' in `i'
				}
				else qui replace `DOSE'=`DOSE'[`i'-1] in `i'
				if `i'>1 {
					frac_ddp `DOSE'[`i'] 2
					local score `score', `r(ddp)'
				}
				local ++i
				macro shift
			}
			local doses "`score'"
		}
		sum `DOSE' [w=`AR'],meanonly
		qui replace `DOSE'=`DOSE'-r(mean)
	}
	tempname b MU Q0 q0 a D
	local K=`ngroups'-1
	scalar `b'=1-`power'
	* Variance-covariance matrix under alternative hypothesis
		if "`wald'" ~="" {
			tempname VA
			mat `VA' = J(`K',`K',0)
			forvalues k=1/`K' {
				forvalues l=1/`K' {
					local kk = `k'+1
					local ll = `l'+1
					mat `VA'[`k',`l'] = `S'[`kk']*((`k'==`l')/`AR'[`kk']-1) - `S'[`ll']+`sbar'
				}
			}
		}
	if "`condit'"=="" {
		local test0 "unconditional"
		local tit2 "unconditional comparison of `ngroups' binomial proportions"
		qui gen double `MU'=`PI'-`pibar'
		tempname s
		scalar `s'=`pibar'*(1-`pibar')
		if "`trtest'"=="" {
			if "`wald'" ~="" {
				local test1 "Wald test"
				mkmat `MU' if _n>1
				mat `Q0' = `MU''*syminv(`VA')*`MU'
				local q0 = `Q0'[1,1]                                                   
			}
			else {
					
			local test1 "Chisquare test"
			_sp `MU' `MU' `AR', out(`q0')
			scalar `q0'=`q0'/`s'                                                      
			}
			scalar `a'=invchi2(`K',1-`alpha')
	
			if "`local'"~=""|"`wald'" ~="" {
				if `n'==0 {
					local n=npnchi2(`K',`a',`b')/`q0'
*					if mi("`noround'") local D=ceil(`n'*`pibar')                         
*					else local D=`n'*`pibar'
					local D=`n'*`pibar'
				}
				else scalar `b'=nchi2(`K',`n'*`q0',`a')
			}
			else {
				tempname S sbar W  a0 a1 q1 eta g psi l
				qui gen double `S'=`PI'*(1-`PI')
				sum `S' [w=`AR'],meanonly
				scalar `sbar'=r(mean)
				sum `S',meanonly
				scalar `a0'=(r(sum)-`sbar')/`s'
				_sp `MU' `MU' `S' `AR', out(`q1')
				scalar `q1'=`q1'/`s'^2
				qui gen double `W'=1-2*`AR'
				_sp `S' `S' `W', out(`a1')
				scalar `a1'=(`a1'+`sbar'^2)/`s'^2
				if `n'==0 {
					* Solve for n iteratvely
					tempname n0 nl nu b0 sm
					scalar `sm'=0.001
					local i 1
					scalar `n0'=npnchi2(`K',`a',`b')/`q0'
					_pe2 `a0' `q0' `a1' `q1' `K' `n0' `a' `b0'
					if abs(`b0'-`b')<=`sm' {
						local i 0
					}
					else {
						if `b0'<`b' {
							scalar `nu'=`n0'
							scalar `nl'=`n0'/2                                   
						}
						else {
							scalar `nl'=`n0'
							scalar `nu'=2*`n0'                                   
						}
					}
					while `i' {
						scalar `n0'=(`nl'+`nu')/2
						_pe2 `a0' `q0' `a1' `q1' `K' `n0' `a' `b0'
						if abs(`b0'-`b')<=`sm' {
							local i 0
						}
						else {
							if `b0'<`b' {
								scalar `nu'=`n0'
							}
							else scalar `nl'=`n0'
							local i=`i'*((`nu'-`nl')>1)
						}
					}
					local n=`n0'
				}
				else _pe2 `a0' `q0' `a1' `q1' `K' `n' `a' `b'
			}
		}
		else {
			local test1 "`trtest'`doses'"
/* To revisit
********************************************************************
		if `ngroups'==2 & "`doses'"=="" local test1 "Chisquare test"
********************************************************************
*/
			tempname tr q1
			_sp `MU' `DOSE' `AR', out(`tr')
			_sp `DOSE' `DOSE' `AR', out(`q0')
			scalar `q0'=`q0'*`s'
			if "`local'"~="" {
			scalar `q1'=`q0'
			}
			else {
				tempname S W 
				qui gen double `S'=`PI'*(1-`PI')
				_sp `DOSE' `DOSE' `S' `AR', out(`q1')
			}
			if !mi("`wald'") scalar `a'=sqrt(`q1')*invnorm(1-`alpha'/2)         
			else scalar `a'=sqrt(`q0')*invnorm(1-`alpha'/2)
			if `n'==0 {
				scalar `a'=`a'+sqrt(`q1')*invnorm(`power')
				local n=(`a'/`tr')^2                                             
			}
			else {
				scalar `a'=abs(`tr')*sqrt(`n')-`a'
				scalar `b'=1-normprob(`a'/sqrt(`q1'))
			}
		}
		local D=`n'*`pibar'                                         
	}
	else {
		local test0 "Conditional"
		local tit2 "Conditional test using Peto's approximation to the odds ratio"
		tempname LOR l d v
		scalar `v'=`pibar'*(1-`pibar')
		qui gen double `LOR'=log(`PI')-log(1-`PI')-log(`PI'[1])+log(1-`PI'[1])
		qui replace `LOR'=0 in 1
		sum `LOR' [w=`AR'],meanonly
		qui replace `LOR'=`LOR'-r(mean)
		if "`trtest'"=="" {
			local test1 "Chisquare test"
			_sp `LOR' `LOR' `AR', out(`q0')
			scalar `a'=invchi2(`K',1-`alpha')
			if `n'==0 {
				scalar `l'=npnchi2(`K',`a',`b')
				scalar `d'=`l'
				scalar `l'=sqrt(`l'*(`l'-4*`q0'*`v'))
				scalar `d'=(`d'+`l')/(2*`q0'*(1-`pibar'))
				local n=`d'/`pibar'                                              
			}
			else {
				scalar `d'=`n'*`pibar'
				scalar `l'=`d'*(`n'-`d')*`q0'/(`n'-1)
				scalar `b'=nchi2(`K',`l',`a')
			}
		}
		else {
			local test1 "`trtest'`doses'"
/* To revisit
********************************************************************
		if `ngroups'==2 & "`doses'"=="" local test1 "Chisquare test"
********************************************************************
*/
			tempname tr
			_sp `DOSE' `LOR' `AR', out(`tr')
			_sp `DOSE' `DOSE' `AR', out(`q0')
			scalar `a'=invnorm(1-`alpha'/2)
			if `n'==0 {
				scalar `a'=sqrt(`q0')*(`a'+invnorm(`power'))
				scalar `l'=(`a'/`tr')^2
				scalar `d'=`l'
				scalar `l'=sqrt(`l'*(`l'-4*`v'))
				scalar `d'=(`d'+`l')/(2*(1-`pibar'))
				local n=`d'/`pibar'                                                
			}
			else {
				scalar `d'=`n'*`pibar'
				scalar `l'=`d'*(`n'-`d')/(`n'-1)
				scalar `a'=abs(`tr')*sqrt(`l'/`q0')-`a'
				scalar `b'=1-normprob(`a')
			}
		}
		*local D=`d'                                                             
 *        if "`noround'"=="" local D=ceil(`d')
*		 else local D=`d'
		 local D=`d'
	}
	local power=1-`b'

}

if `ngroups'==2 {
	local gplist "(groups 1, 2)"
}
else local gplist "(groups 1,..,`ngroups')"
local off 40
local longstring 38
local maxwidth 78
local artcalcused "k-arm"
}



* Change rounding option so rounds UP to the nearest integer if noround is not specified - PER GROUP, FOR ALL ARMS (incl results from art2bin)

* if ngroups = 2 but user has only specified 1 allocation ratio, redefine allr1 and allr2 (at present allr1 will be aratio and allr2 is blank)
if `npr'==2 & `nar'==1 {
	 local allr2 = `allr1' 
	 local allr1 = 1
	 local totalallr = `allr1' + `allr2'
	 local aratios 1 `allr2'
	 local allocr 1:`allr2'
}

* If first allocation ratio is not 1 (e.g. 2:3) re-scale so that rounding works
* (otherwise artbin, pr(.15 .15) margin(.1) aratio(1 1.5) vs. artbin, pr(.15 .15) margin(.1) aratio(2 3) doea not give the same answer:
* the latter is over-rounded so gives a higher SS)


if `allr1'!=1 {
	local baseallr = `allr1'
	forvalues r=1/`npr' {
		local allr`r' = `allr`r'' / `baseallr'
	}
	local totalallr = `totalallr'/`baseallr'
}

* Account for loss to follow up
if !mi("`ltfu'") local n = `n' /(1 - `ltfu')

	local nbygroup=`n'/`totalallr'
	

	 
	forvalues a=1/`npr' {
			if "`noround'"=="" {
				local n`a' = ceil(ceil(`nbygroup') * `allr`a'')
				if `a'==1 local n = `n`a''
				else local n = `n' + `n`a''
*				local D=ceil(`D') 
				* calculate D for rounded n, and do not round D
				* calculation of D based on SS if art2bin wrapper was called
					 if `ssize'==1 {
						if `npr'==2 & !(`niss'==0 & "`nchi'"=="nchi") & "`condit'"=="" {
							local D = (`n1'*`p1') + (`n2'*`p2')
						}
						* otherwise if art2bin wrapper not called
						else local D = `n'*`pibar'
					}			 
				}
				else {
				local n`a' = `nbygroup' * `allr`a''
				if `a'==1 local n = `n`a''
				else local n = `n' + `n`a''
				* calculate D for non-rounded n, and do not round D
				* calculation of D based on SS if art2bin wrapper was called
					if `ssize'==1 {
						if `npr'==2 & !(`niss'==0 & "`nchi'"=="nchi") & "`condit'"=="" {
							local D = (`n1'*`p1') + (`n2'*`p2')
						}
						* otherwise if art2bin wrapper not called
						else local D = `n'*`pibar'
					}
*				local D = `D'                                                      
*				local power=1-`b'
			}
	if `a'!=`npr' local ntable `ntable' `n`a'',
	else if `a'==`npr' local ntable `ntable' `n`a''
	return scalar n`a' = `n`a''
	}
	
	
* Put D to 2.d.p. for table output only (returned value will have full d.p.)
*local Dtable = `D'
*frac_ddp `Dtable' 2
local Dtable : di %-9.2f `D'

* loss to follow up as a percentage for the table
if !mi("`ltfu'")  {
	local ltfuperc = `ltfu' * 100
	local ltfuperc = "`ltfuperc' %"
}

if "`notable'"=="" {
* For table output
local Alphadiv2 = `alpha'/2

di as text _n "{hi:ART} - {hi:A}NALYSIS OF {hi:R}ESOURCES FOR {hi:T}RIALS" /*
 */ " (`version')" _n "{hline `maxwidth'}"
display as text "A sample size program by Abdel Babiker, Patrick Royston, Friederike Barthel, "
display as text "Ella Marley-Zagar and Ian White"
display as text "MRC Clinical Trials Unit at UCL, London WC1V 6LJ, UK." _n "{hline `maxwidth'}"
di as text "Type of trial" _col(`off') as res "`trialtype'"
artformatnos, n(`tit2') maxlen(`longstring')
local nlines=r(lines)
di as text "Number of groups" _col(`off') as res "`npr'"
if `ngroups' == 2 {
    di as text "Favourable/unfavourable outcome" _col(`off') as res "`trialoutcome'"
	if `infer'==1 {
		di as text _col(`off') "{it:Inferred by the program}"
*		di as text _col(`off') "{it:To override use the force option}"
	}
}
else di as text "Favourable/unfavourable outcome" _col(`off') as res "not determined"
di as text "Allocation ratio" _col(`off') as res "`allocr'"

forvalues i=1/`nlines' {
	if `i'==1 {
		di as text "Statistical test assumed" _col(`off') as res "`r(line`i')'"
	}
	else di as text _col(`off') as res " `r(line`i')'"
	}
	if mi("`wald'")  di as text _col(`off') as res " using the score test"
	if !mi("`wald'") di as text _col(`off') as res " using the wald test"

di as text "Local or distant" _col(`off') as res "`localdescr'"
if ("`ccorrect'" == "ccorrect" | "`ccorrect'" == "1") di as text "Continuity correction" _col(`off') as res "yes"
else if ("`ccorrect'" == "" | "`ccorrect'" == "0") di as text "Continuity correction" _col(`off') as res "no"
	
if ("`trialtype'"=="non-inferiority" | "`trialtype'"=="substantial-superiority") {
	di as txt "Null hypothesis H0:" _col(`off') as res "`H0'"        
	di as txt "Alternative hypothesis H1:" _col(`off') as res "`H1'"
}

if !mi("`algorithm'") di as text "Algorithm used:" _col(`off') as res "`artcalcused'"

if `ngroups'>2 & "`trtest'"!="" {
	di as text "`trtest'" _col(`off') as res "`doses'"
}
di as text _n "Anticipated event probabilities" _col(`off') as res "`altp'"
if mi("`onesided'") {
    di as text _n "Alpha" _col(`off') %5.3f as res `Alpha' " (`sided'-sided)"
	if "`sided'" == "two" di as text _col(`off') as res "(taken as `Alphadiv2' one-sided)"
}
else di as text _n "Alpha" _col(`off') %5.3f as res `Alpha' " (`sided'-sided)"
if `ssize'==1 {
 	di as text "Power (designed)" _col(`off') %5.3f as res `Power'
	return scalar power=`Power'
 	local mess (calculated)
}
if `ssize'==0 {
 	di as text "Power (calculated)" _col(`off') %5.3f as res `power'
 	return scalar power=`power'
 	local mess (designed)
}
if !mi("`ltfu'") di as text _n "Loss to follow up assumed:" _col(`off') as text "`ltfuperc'"
di as text _n "Total sample size `mess'" _col(`off') as res `n' 
di as text _n "Sample size per group `mess'" _col(`off') as res `ntable'
di as text "Expected total number of events" _col(`off') as res "`Dtable'" " 
di as text "{hline `maxwidth'}"

return scalar n=`n'
return scalar D=`D'                                                             

}
else if "`notable'"!="" {
	if `ssize'==0 {
 	di as text "Power (calculated) is: " %5.3f as res `power'
	return scalar power=`power'
	return scalar D=`D' 
	}
	else if `ssize'==1 {
 	di as text "Total sample size (calculated) is: " as res `n'
	return scalar n=`n'
	return scalar D=`D' 
	}
}


end


program define _sp
version 8
* Calculate sum of products.
syntax varlist(min=1) [, OUt(string)]
tokenize `varlist'
tempvar SP
qui gen double `SP'=`1'
macro shift
while "`1'"!="" {
	qui replace `SP'=`SP'*`1'
	macro shift
}
summ `SP',meanonly
scalar `out'=r(sum)
end


program define _pe2
version 8
* Calculate beta=P(type II error)
args a0 q0 a1 q1 k n a b
tempname b0 b1 f l
scalar `b0'=`a0'+`n'*`q0'
scalar `b1'=`a1'+2*`n'*`q1'
scalar `l'=`b0'^2-`k'*`b1'
scalar `f'=sqrt(`l'*(`l'+`k'*`b1'))
scalar `l'=(`l'+`f')/`b1'
scalar `f'=`a'*(`k'+`l')/`b0'
scalar `b'=nchi2(`k',`l',`f')
end
