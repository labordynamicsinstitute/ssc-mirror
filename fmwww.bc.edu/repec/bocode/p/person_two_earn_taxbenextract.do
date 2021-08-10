*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*                   S E T  U P  P E R S O N A L  C H A R A C T E R I S T I C S

set more off

capture pr drop tbpers
pr def tbpers
version 7
	
	* number of months in unemployment */
			/* (UA is in all cases automatically cancelled if time>99) */
			/* reset value to begin with */
			
			capture global mintime = "$ue_months"
			/* line was capture local mintime = ue_months[$run_no] but that didn't work */
					
			if "$mintime" == "." | "$mintime" == "" {
				global mintime = 2
			}
			
	
			clear
	
			* do you allow the spouse to have previous experience or current earnings, yes(1) or no(0)?
			if "$sps_ins" == "" {
				if $spouse_works == 1 					  global sps_ins = 1					/* default value is yes */
				if $spouse_works == 0 | $spouse_works==2  global sps_ins = 1					
			}
			display "$sps_ins"
			
	/*$share has been added in run-types 1 and 4 to take into account the % of APW as ref. earnings, DP 11-04-06*/
	

	global share = $SHR

	if $SELECT==0 {
		* you have chosen to develop over a five year period, now determine:
		* the full time earnings level of partner 2's (spouse) income
		if "$sps_inc" == "" {
				global sps_inc = $SEWage_level		/* default value */
			}
		if $DB_WS==1 {
			global spsinc = $value_selected_wage_s * $share * $sps_inc
		}	
		if $DB_WS==0 {
			global spsinc = 0
		}
		* new condition for spouse not working but available to work
		if $DB_WS==2 {
			global spsinc = 0
		}


		* the number of days both partners work per week
		if "$sps_dw" == "" {
				global sps_dw = $SEdays		/* default value */
		}
		if $DB_WS==1 {
			global wd_s = ${sps_dw}		/* days/week worked by spouse*/
		}
		if $DB_WS==0 {
			global wd_s = 0
		}
		* new condition for spouse not working but available to work
		if $DB_WS==2 {
			global wd_s = 0
		}

		if "$pri_dw" == "" {
			global pri_dw = $Pdays		/* default value */
		}
		global wd_p = ${pri_dw}		/* days per week worked by principal*/
	}

	if $SELECT==1 {
	
		if "$sps_pinc" == "" {
				global sps_pinc = $SEWage_level	/* default value */

		}
		* you have chosen to develop over earnings, now determine:
		* the minimum earnings level you allow partner 1 (spouse)
		global min = $true_APW * 0*$share*$sps_pinc
		* the maximum earnings level you allow partner 1 (spouse)
		global max = $true_APW * 2*$share*$sps_pinc

		* the earnings level of partner 2's (spouse)
		if "$sps_inc" == "" {
				global sps_inc = $SEWage_level		/* default value */
		}
		if $DB_WS==1 {
			global spsinc = $value_selected_wage_s * $share * $sps_inc
		}
		if $DB_WS==0 {
			global spsinc = 0 
		}
		* new condition for spouse not working but available to work
		if $DB_WS==2 {
			global spsinc = 0
		}

		
		* the number of days both partners work per week
		if "$sps_dw" == "" {
			global sps_dw = $SEdays		/* default value: 0 to be eligible for UB, 26/02 dp */
		}
		if $DB_WS==1 {
			global wd_s = ${sps_dw}		/* days/week worked by spouse */
		}
		if $DB_WS==0 {
			global wd_s = 0
		}
		* new condition for spouse not working but available to work
		if $DB_WS==2 {
			global wd_s = 0
		}

		if "$pri_dw" == "" {
			global pri_dw = $Pdays			/* default value */
		}
		global wd_p = ${pri_dw}			/* days per week worked by principal, 0 to be eligible for UB, 08/04/03*/
		
		* do you want to include UI waiting days, yes(1) or no(0)?
		*global   wait  = 0
	}

	if $SELECT==2 {
		* you have chosen to develop over days worked by principal, now determine:
        * the full time earnings of partner 1 (principal) as a share of APW
        * global share   = 1
        * the level of partner 2's (spouse) income
        if "$sps_inc" == "" {
			global sps_inc = $SEWage_level		/* default value */
		}
        if $DB_WS==1 {
        	global spsinc = $value_selected_wage_s * $share * $sps_inc
        }
        if $DB_WS==0 {
			global spsinc = 0
        }
        * new condition for spouse not working but available to work
	if $DB_WS==2 {
			global spsinc = 0
	}

        
        * the number of days partner 2 works per week
        if "$sps_dw" == "" {
			global sps_dw = $SEdays		/* default value */
		}
        if $DB_WS==1 {
			global wd_s = ${sps_dw}		/* days/week worked by spouse*/
        }
        if $DB_WS==0 {
			global wd_s = 0
        }
        * new condition for spouse not working but available to work
	if $DB_WS==2 {
			global wd_s = 0
	}

        
	}

	if $SELECT==3 {
		* you have chosen to develop over days worked by spouse, now determine:
		* the full time earnings of partner 1 (principal) as a share of APW
		* global share = 1 	/* HI 27/08/03: commented out. why was it used? */
				
		* the level of partner 2's (spouse) income
		if "$sps_inc" == "" {
			global sps_inc = $SEWage_level		/* default value */
		}
		global spsinc = $value_selected_wage_s * $share * $sps_inc
		
		* the number of days partner 1 (principal) works per week
		if "$pri_dw" == "" {
			global pri_dw = $Pdays			/* default value */
		}
		global wd_p = ${pri_dw}			/* days per week worked by principal */
		
	}
	
	if $SELECT==4 {
		if "$sps_inc" == "" {
				global sps_inc = $SEWage_level		/* default value */
			}
		* you have chosen to develop over earnings, now determine:
		* the minimum earnings level you allow partner 1 (spouse)
		global min = $true_APW * 0*$share*$sps_inc
		* the maximum earnings level you allow partner 1 (spouse)
		global max = $true_APW * 2*$share*$sps_inc

		* the earnings level of partner 2's (spouse)
		if "$sps_inc" == "" {
			global sps_inc = $SEWage_level		/* default value */
		}
		if $DB_WS==1 {
			global spsinc = $value_selected_wage_s * $share * $sps_inc
		}
		if $DB_WS==0 {
			global spsinc = 0
		}
		* new condition for spouse not working but available to work
		if $DB_WS==2 {
			global spsinc = 0
		}

		* the number of days both partners work per week
		if "$sps_dw" == "" {
			global sps_dw = $SEdays		/* default value */
		}
		if $DB_WS==1 {
			global wd_s = $sps_dw		/* days/week worked by spouse*/
		}
		if $DB_WS==0 {
			global wd_s = 0
		}
		* new condition for spouse not working but available to work
		if $DB_WS==2 {
			global wd_s = 0
		}
		
		* the number of days partner 1 (principal) works per week
		if "$pri_dw" == "" {
			global pri_dw = $Pdays			/* default value */
		}
		global wd_p = ${pri_dw}			/* days per week worked by principal */
				
	}


/*++++++++++++++++ Do not change between these lines +++++++++++++++++++++++++++++++++++++++++*/
	if $SELECT==0 {
		range time 1 60 60
		if "$pri_inc" == "" {
			global pri_inc = $PWage_level		/* default value */
		}
		gen double earnings = $value_selected_wage_p * $share * $pri_inc
		gen double spousinc = $spsinc
		gen workdayp = $wd_p
		gen workdays = $wd_s
		/* This file: two (potential) earner case. SELECT=0: principal is UE */
		/* ==> by default principal's previous earnings are APW */
		if "$pri_pinc" == "" {
			global pri_pinc = $PWage_level		/* default value */
		}
		gen prv_earn_p = $value_selected_wage_p * $share * $pri_pinc
		if "$sps_pinc" == "" {
				global sps_pinc = $SEWage_level		/* default value */
		}
		gen prv_earn_s = $value_selected_wage_s * $share * $sps_pinc
	}

	if $SELECT==1 { 
		/*range earnings $min $max 201
		gen double spousinc = $spsinc*/
		/*if sp income 100$APW=$spsinc, dp, 07/04/03*/
		/*the principal earner is working 67% of APW, the sp working from 0 to 200. Disactivate the first two lines with /*...*/, and activate the following two lines, 08/04/03, dp*/

		range spousinc $min $max 201
		format spousinc %10.0g
		if "$pri_inc" == "" {
			global pri_inc = $PWage_level		/* default value */
		}
		gen double earnings= $value_selected_wage_p * $share * $pri_inc
		gen workdayp = $wd_p
		gen workdays = $wd_s
		gen time = $mintime
		/* This file: two (potential) earner case. */
		/* SELECT=1: spouse UE; varying levels of prev. earn (stored in spousinc) */
		/* ==> spouse's previous earnings are spousinc */
		if "$pri_pinc" == "" {
			global pri_pinc = $PWage_level		/* default value */
		}
		gen prv_earn_p = $value_selected_wage_p * $share * $pri_pinc
		
		
		* HI ToDo: change this so that spouse's previous earnings can be specified separately
		gen prv_earn_s = spousinc
	}
        
	if $SELECT==2 {
		range workdayp 0 11 221	/*originally 5 500 or 10 201(for METR)*/
		if "$pri_inc" == "" {
			global pri_inc = $PWage_level		/* default value */
		}
		gen double earnings = $value_selected_wage_p * $share * $pri_inc
		gen workdays = $wd_s
		gen spousinc = $spsinc
		gen time = $mintime
		/* This file: two (potential) earner case. */
		/* SELECT=2: principal with varying working hours; hourly wage = APW wage */
		/* ==> principal's previous earnings are APW (assuming full time in prv. job) */
		if "$pri_pinc" == "" {
			global pri_pinc = $PWage_level			/* default value */
		}
		gen prv_earn_p = $value_selected_wage_p * $share * $pri_pinc
		if "$sps_pinc" == "" {
			global sps_pinc = $SEWage_level		/* default value */
		}
		gen prv_earn_s = $value_selected_wage_s * $share * $sps_pinc
	}

	if $SELECT==3 {
		range workdays 0 11 221  /*originally 5 500 or 5 101(for METR)*/
		
		if "$pri_inc" == "" {
			global pri_inc = $PWage_level			/* default value */
			/*.67 in the case that the principal earner is receiving 2/3 of APW, 08/04/03, dp*/
		}
		gen double earnings = $value_selected_wage_p * $share * $pri_inc
		gen workdayp = $wd_p
		
		gen double spousinc = $spsinc
		gen time = $mintime
		/* This file: two (potential) earner case. */
		/* SELECT=3: spouse with varying levels of hours; hourly wage = APW wage */
		/* ==> spouse's previous earnings are APW (assuming full time in prv. job) */
		if "$pri_pinc" == "" {
			global pri_pinc = $PWage_level			/* default value */
		}
		gen prv_earn_p = $value_selected_wage_p * $share * $pri_pinc
		if "$sps_pinc" == "" {
			global sps_pinc = 1		/* default value */
		}
		gen prv_earn_s = $value_selected_wage_s * $share * $sps_pinc
	}

	if $SELECT==4 {
		/*the spouse is receiving from 0 to 200% of APW */
		/*range earnings $min $max 201
		gen double spousinc = max(0,(earnings/$spsinc)*$spsinc)*/
		/*if sp income 100$APW=$spsinc, dp, 07/04/03*/
		/*the principal earner is working 67% of APW, the sp working from 0 to 200. Disactivate the first two lines with /*...*/, and activate the following two lines, 08/04/03, dp*/
		range spousinc $min $max 201
		
		if "$pri_inc" == "" {
			global pri_inc = $PWage_level		/* default value */
			/*0.67 in the case that the principal earner is receiving 2/3 of APW, 08/04/03, dp*/
		}
		gen double earnings = $value_selected_wage_p * $share * $pri_inc
		gen workdayp = $wd_p
		replace workdayp=0 if earnings==0
		
		gen workdays = $wd_s
		replace workdays=0 if spousinc==0
		
		gen time = $mintime
		/* This file: two (potential) earner case. */
		/* SELECT=4: spouse full time employed; varying levels of earnings */
		/* ==> spouse's previous earnings are same as current earnings */
		if "$pri_pinc" == "" {
			global pri_pinc = $PWage_level		/* default value */
		}
		* gen prv_earn_p = $APW * $share * $pri_pinc
		gen prv_earn_p = $value_selected_wage_p * $share * $pri_pinc
		
		if "$sps_pinc" == "" {
			global sps_pinc = $SEWage_level		/* default value */
		}
		* HI ToDo: change this so that spouse's previous earnings can be specified separately
		gen prv_earn_s = spousinc
	}

/************************************************************************************************************************************/
/* CHILD CARE CHILD CARE CHILD CARE CHILD CARE CHILD CARE CHILD CARE CHILD CARE CHILD CARE CHILD CARE CHILD CARE CHILD CARE */

		if $SELECT==5 {
			
			/* Childcare fees are the only thing which changes. Childcare costs will vary from 0 to 100% of APW */
			range CC_Fee 35 0 201
			replace CC_Fee = CC_Fee/100 * $APW 
			
			/* Current earnings level */
			if "$pri_inc" == "" {
				global pri_inc = $PWage_level		/* default value */
			}
			if "$sps_inc" == "" {		/* HI 22/08/06 corrected. Was: `sps_inc' */
				global sps_inc = $SEWage_leve	/* default value */
				/*0.67 in the case that the spouse earner is receiving 2/3 of APW, 08/04/03, dp*/
			}
			gen double earnings = $value_selected_wage_p * $share * $pri_inc
			gen double spousinc = $value_selected_wage_s * $share * $sps_inc


			/* At the moment, we assume both work full time if we are doing childcare. If we 	*/
			/* decide to do other variations, it will be necessary to introduce a variable for the	*/
			/* number of hours spent in child care. 16-11-2004 DB					*/
			
			/* Current number of workdays */			
			gen workdayp = 5
			replace workdayp=0 if earnings==0

			gen workdays = 5
			replace workdays=0 if spousinc==0
			
			/* Previous income is set to zero */
			if "$pri_pinc" == "" {
				global pri_pinc = $PWage_level			/* default value */
			}
			if "$sps_pinc" == "" {
				global sps_pinc = $SEWage_level		/* default value */
			}
			
			gen prv_earn_p = $value_selected_wage_p * $share * $pri_pinc
			gen prv_earn_s = $value_selected_wage_s * $share * $sps_pinc

			gen time = $mintime
			
	}

/************************************************************************************************************************************/

/* begin CHILD AGE EVOLUTION */

if $SELECT==6 {  

        * the number of days both partners work per week
        if $DB_WS==1 {
        mac def   wd_s  = 5}        /* days/week worked by spouse*/
        if $DB_WS==0 {
        mac def   wd_s  = 0}
        * new condition for spouse not working but available to work
	if $DB_WS==2 {
	mac def   wd_s  = 0}


        mac def   wd_p  = 5        /* days per week worked by principal*/
      
        /*the principal earner is receiving from 0 to 200$ of APW, and the spouse is earning the same level of APW as the principal*/
       
      	range time -12 324 337
      	      	
      	gen k1 = $CHAGE1
	replace k1 = ($CHAGE1+(time/12)) if $CHIL>=1
	format k1 %9.2f
	      			
	gen k2 = $CHAGE2
	replace k2 = ($CHAGE2+(time/12)) if $CHIL>=2
	format k2 %9.2f
			
	gen k3 = $CHAGE3
	replace k3 = ($CHAGE3+(time/12)) if $CHIL>=3
	format k3 %9.2f
			
	gen k4 = $CHAGE4
	replace k4 = ($CHAGE4+(time/12)) if $CHIL==4
	format k4 %9.2f
      	
      	/* Current earnings level */
	if "$pri_inc" == "" {
				global pri_inc = $PWage_level		/* default value */
				}
	if "$sps_inc" == "" {
				global sps_inc = $SEWage_level	/* default value */
				
			}
	if $DB_WS==0 { 
			global sps_inc = 0
		    }
	* new condition for spouse not working but available to work
	if $DB_WS==2 { 
			global sps_inc = 0
		    }
		    
		    
    gen double earnings = $value_selected_wage_p * $share * $pri_inc
	gen double spousinc = $value_selected_wage_s * $share * $sps_inc
	gen workdayp = $wd_p
	gen workdays = $wd_s
        
            
      
      	/* Previous income is set to zero */
	if "$pri_pinc" == "" {
				global pri_pinc = $PWage_level			/* default value */
				}
	if "$sps_pinc" == "" {
				global sps_pinc = $SEWage_level		/* default value */
				}
			
	gen prv_earn_p = $value_selected_wage_p * $share * $pri_pinc
	gen prv_earn_s = $value_selected_wage_s * $share * $sps_pinc
      			
	}

/***************************************** end CHILD AGE EVOLUTION **********************************/

// Constant earnings splits for two earner couples
// Added by bkp 14/6/12


if $SELECT == 7 {

	// Set up spouse defaults
	
        if "$sps_inc" == "" {
		
		global sps_inc = $SEWage_level		
	
	}
			
	if "$sps_pinc" == "" {
		
		global sps_pinc = $SEWage_level		 
	
	}
			



	// Set up primary defaults
	
        if "$pri_inc" == "" {
		
		global pri_inc = $PWage_level			// Default
	
	}
			
	if "$pri_pinc" == "" {
		
		global pri_pinc = $PWage_level			// Default 
	
	}
	
	// Set up run so that each step is 1 per cent of $share * $APW
	
	range totalday 0 11 221
	
	gen workdayp = totalday * $pri_inc / ($sps_inc + $pri_inc)	
		
	gen workdays = totalday * $sps_inc / ($sps_inc + $pri_inc)	
		
	gen earnings = $APW * $share 
	
	gen spousinc = earnings 		// Spouse has same hourly wage rate as primary

	gen prv_earn_p = $value_selected_wage_p * $share * $pri_pinc
	
	gen prv_earn_s = $value_selected_wage_s * $share * $sps_pinc

	gen time = $mintime
	
	
}

// Constant gross family earnings, varying splits for two earner couples
// Added by bkp 14/6/12


if $SELECT == 8 {

	// Set up spouse defaults
	
        if "$sps_inc" == "" {
		
		global sps_inc = $SEWagel_evel		// Default 
	
	}
			
	if "$sps_pinc" == "" {
		
		global sps_pinc = 	$SEWagel_evel	// Default 
	
	}
			



	// Set up primary defaults
	
        if "$pri_inc" == "" {
		
		global pri_inc = $PWage_level		// Default
	
	}
			
	if "$pri_pinc" == "" {
		
		global pri_pinc = $PWage_level		// Default 
	
	}
	
	// Set up run
	
	range pct_p 0 100 101
	
	gen pct_s = 100 - pct_p
	
	gen target = $APW * $share * ($pri_inc + $sps_inc)
	
	gen target_p = (pct_p/100) * target
	
	gen target_s = target - target_p
	
	gen workdayp = 5 * min( 1, target_p / ($APW * $share))
	
	gen workdays = 5 * min( 1, target_s / ($APW * $share))
			
	gen earnings = 5 * target_p / workdayp if workdayp > 0
	
	replace earnings = 0 if workdayp == 0
	
	gen spousinc = 5 * target_s / workdays if workdays > 0
	
	replace spousinc = 0 if workdays == 0

	gen prv_earn_p = $value_selected_wage_p * $share * $pri_pinc
	
	gen prv_earn_s = $value_selected_wage_s * $share * $sps_pinc

	gen time = $mintime
	
	drop target target_p target_s
}

/*****************************************************************************/
	
	gen spousins = $sps_ins
	gen incl_SA  = $incl_sa
	gen spouse_w = $DB_WS /* new line for 'spouse works'options, dp, 09-01-09*/
	
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/


	* age of the individuals
	gen age = $adage

	* the employment record equals the contribution record equals (in months)
	gen record = $crec
	
	* marital status assumption: is the person single (0) or married (1)? 
	gen marstat = $DB_mars-1

	la var marstat  "marital status"
	la def mar 0 "single" 1 "married"
	la val marstat married
   	
   	/************************************************************************/
	/* children's ages, take oldest kids first, never more than 4 		*/
	/* (if the age of a child is under 4 than the programme assumes		*/
	/* childcare)								*/
	/************************************************************************/
	
	if $SELECT!=6 {  	
		gen k1 = $CHAGE1
		gen k2 = $CHAGE2
		gen k3 = $CHAGE3
		gen k4 = $CHAGE4	
	}
	
	* rental cost: rent can be set in control file (as parameter "Hcost") but is 20% of APW by default.
	gen rent = $h_cost*$APW

	* For Ireland, rent allowance was excluded for this year's publication        
	*        replace rent=0 if "`x'"== "ir"

	/* -------------------------------------------------------------------------------------------- */
	/* For publications prior to 2004, child care costs were estimated using a method similar	*/
	/* to the rent assumption. The variable 'cc_cost' was set to 15% of APW per child. We will	*/
	/* not be using that assumption in the upcoming publication(s), and thus I am removing the	*/
	/* variable definition. 16-11-2004 DB*/
	
	 /* need cc_cost for programs prior 2001*/
	 
	 *gen cc_cost = 0.15*$APW*((k1>0)*(k1<4)+(k2>0)*(k2<4)+(k3>0)*(k3<4)+(k4>0)*(k4<4))  commented bkp 5/3/13		
		

	/*FOR TABLE 4.1, COLUMN 4: WORKDAYS=2*/
	*replace workdays=2
	/*FOR TABLE 4.1, COLUMN 2: WORKDAYP=2*/
	*replace workdayp=0.5
   cd "$path"
   compress
   save "${OUTPATH}pers",replace		/*pers file is stored in the temporary name-specified subfolder, 13-11-09*/

end

tbpers
