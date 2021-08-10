*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*                   S E T  U P  P E R S O N A L  C H A R A C T E R I S T I C S

set more off

capture pr drop tbpers
pr def tbpers
/* version 3.1 */
version 7

* number of months in unemployment */
/* (UA is in all cases automatically cancelled if time>99) */
/*$share has been added in run-types 1 and 4 to take into account the % of APW as ref. earnings, DP 11-04-06*/
/* set default values for current and previous earnings and change "mac def"by "global". Now consistent with two earner program. 12-03-09, DP*/

/* reset value to begin with */
local mintime	/* reset value to begin with */
capture local mintime = "$ue_months"

clear

* do you allow the spouse to have previous experience or current earnings, yes(1) or no(0)?
        global sps_ins = 0

* Do you include employment conditional benefits?
		*global iwb = 1

		global share = $SHR

if $SELECT==0 {  
	* : you have chosen to develop over a five year period, now determine:
   
        * the full time earnings level of partner 2's (spouse) income
        if $DB_WS==1 {
        global spsinc  = $APW*$share*$sps_inc}	
        if $DB_WS==0 {
        global spsinc  = 0}
        * new condition for spouse not working but available to work, 09-01-09, dp
	if $DB_WS==2 {
        global spsinc  = 0}

        * the number of days both partners work per week
        if $DB_WS==1 {
        global   wd_s  = 5}        /* days/week worked by spouse*/
        if $DB_WS==0 {
        global   wd_s  = 0}
        * new condition for spouse not working but available to work, 09-01-09, dp
	if $DB_WS==2 {
        global   wd_s  = 0}
        
        global   wd_p  = 0        /* days per week worked by principal*/
        }

if $SELECT==1 {  

	if "$pri_pinc" == "" {
			global pri_pinc = $PWage_level		/* default value */
		}
	*: you have chosen to develop over earnings, now determine:
        * the minimum earnings level you allow partner 1 (principal)
        global min = $APW*0*$share*$pri_pinc
        * the maximum earnings level you allow partner 1 (principal)
        global max  = $APW*2*$share*$pri_pinc

        * the maximum earnings level of partner 2's (spouse)
        if $DB_WS==1 {
        global spsinc  = $value_selected_wage_s*$share*$sps_inc}
        if $DB_WS==0 {
        global spsinc  = 0}
        * new condition for spouse not working but available to work, 09-01-09, dp
	if $DB_WS==2 {
        global  spsinc = 0}

        * the number of days both partners work per week
        if $DB_WS==1 {
        global   wd_s  = 0}        /* days/week worked by spouse, 0 to be eligible for UB, 26/02 dp*/
        if $DB_WS==0 {
        global   wd_s  = 0}
        * new condition for spouse not working but available to work, 09-01-09, dp
	if $DB_WS==2 {
        global   wd_s  = 0}

        global   wd_p  = 0       /* days per week worked by principal, 0 to be eligible for UB, 08/04/03*/

        * do you want to include UI waiting days, yes(1) or no(0)?
        *global   wait  = 0
        }

if $SELECT==2 {  
	*: you have chosen to develop over days woked by principal, now determine:
        * the full time earnings of partner 1 (principal) as a share of APW
        * global share   = 1
        * the level of partner 2's (spouse) income (set to zero if not used!)
		if "$sps_inc" == "" {
					global sps_inc = $SEWage_level		/* default value */
		}
		if $DB_WS==1 {
		global spsinc  = $value_selected_wage_s*$share*$sps_inc
		}
		if $DB_WS==0 {
		global spsinc  = 0*$APW
		}
		* new condition for spouse not working but available to work, 09-01-09, dp
		if $DB_WS==2 {
       		global spsinc = 0*$APW
       		}
       		
		* the number of days partner 2 works per week
		if $DB_WS==1 {
		global   wd_s  = 5    /* days/week worked by spouse*/
		}
		if $DB_WS==0 {
		global wd_s = 0
		}
		* new condition for spouse not working but available to work, 09-01-09, dp
		if $DB_WS==2 {
        	global wd_s  = 0}
		}

if $SELECT==3 {  
		*: you have chosen to develop over days woked by spouse, now determine:
		* the full time earnings of partner 1 (principal) as a share of APW
		if "$sps_inc" == "" {
			global sps_inc = $SEWage_level		/* default value */
		}
		global share   = 1 
		* the level of partner 2's (spouse) income
		global spsinc  = $value_selected_wage_s*$share*$sps_inc
		* the number of days partner 1 (principal) works per week
		global   wd_p  = 5   /* days/week worked by principal*/
        }
        
if $SELECT==4 { 

	if "$pri_inc" == "" {
			global pri_inc = $PWage_level		/* default value */
			}
*: you have chosen to develop over earnings, now determine:
        * the minimum earnings level you allow partner 1 (principal)
        global    min  = $APW*0*$share*$pri_inc
        * the maximum earnings level you allow partner 1 (principal)
        global    max  = $APW*2*$share*$pri_inc

        * the maximum earnings level of partner 2's (spouse)
        if $DB_WS==1 {
        global spsinc  = $value_selected_wage_s*$share*$sps_inc}
        if $DB_WS==0 {
        global spsinc  = 0}
        * new condition for spouse not working but available to work, 09-01-09, dp
	if $DB_WS==2 {
        global spsinc = 0}

        * the number of days both partners work per week
        if $DB_WS==1 {
        global   wd_s  = 5}        /* days/week worked by spouse*/
        if $DB_WS==0 {
        global   wd_s  = 0}
        * new condition for spouse not working but available to work, 09-01-09, dp
        if $DB_WS==2 {
        global   wd_s  = 0}
	
	* the number of days partner 1 (principal) works per week
	
	if "$pri_dw" == ""{
        	global pri_dw = $Pdays			/* default value */
				}
	global wd_p = $pri_dw				/* days per week worked by principal */
       }

/*++++++++++++++++ Do not change between these lines +++++++++++++++++++++++++++++++++++++++++*/

        if $SELECT==0 {
        range time 1 60 60
        gen double earnings = $value_selected_wage_p*$share
        gen double spousinc = $spsinc
        gen workdayp = $wd_p
        gen workdays = $wd_s
	/* This file: one (potential) earner case. */
	/* SELECT=0: principal is UE */
	/* ==> principal's previous earnings are APW */
	/*gen prv_earn_p = $APW * $share*/ 
	/*gen prv_earn_s = 0*/	
        /*}*/
        /*modification: previous earnings can vary, DP, 12-07*/
        if "$pri_pinc" == "" {
				global pri_pinc = $PWage_level		/* default value */
			}
			gen prv_earn_p = $value_selected_wage_p * $share * $pri_pinc
			if "$sps_pinc" == "" {
				global sps_pinc = 0		/* default value */
			}
			gen prv_earn_s = 0
	}

        if $SELECT==1 {
        
       	range earnings $min $max 201
        gen double spousinc = $spsinc

	 /*if sp income 100$APW=$spsinc, dp, 07/04/03*/
	
/*the principal earner is working 67$ of APW, the sp working from 0 to 200. Disactivate the first two lines with /*...*/, and activate the following two lines, 08/04/03, dp*/
	
	/* range spousinc $min $max 201
	format spousinc $10.0g
	gen double earnings= $APW*.67 */

        gen workdayp = $wd_p
        gen workdays = $wd_s
        gen time = `mintime'
	/* This file: one (potential) earner case. */
	/* SELECT=1: principal UE; varying levels of prev. earn (stored in earnings) */
	/* ==> principal's previous earnings are earnings */	
	gen prv_earn_p = earnings
	gen prv_earn_s = 0
        }
        
        
        if $SELECT==2 {
        if "$pri_inc" == "" {
		global pri_inc = $PWage_level		/* default value */
			}
        range workdayp 0 11 221	/*originally 5 500 or 10 201(for METR)*/
        gen double earnings = $share*$value_selected_wage_p*$pri_inc
        gen workdays = $wd_s
        gen spousinc = $spsinc
        gen time = `mintime'
	/* This file: one (potential) earner case. */
	/* SELECT=2: principal with varying levels of hours; hourly wage = APW wage */
	/* ==> principal's previous earnings are APW (assuming full time in prv. job) */
	
	/*modification: previous earnings can vary, dp, 12/07*/
	if "$pri_pinc" == "" {
	global pri_pinc = $PWage_level		/* default value */
			}
	gen prv_earn_p = $value_selected_wage_p * $share * $pri_pinc
	gen prv_earn_s = 0
	}

        if $SELECT==3 {
	range workdays 0 11 221  /*originally 5 500 or 5 101(for METR)*/
        gen double spousinc = $spsinc
        gen workdayp = $wd_p
        gen double earnings = $share*$value_selected_wage_p*$pri_inc

/*.67 in the case that the principal earner is receiving 2/3 of APW, 08/04/03, dp*/

        gen time = `mintime'
	/* This file: one (potential) earner case. */
	/* SELECT=3: spouse with varying levels of hours; hourly wage = APW wage */
	/* ==> spouse's previous earnings are APW (assuming full time in prv. job) */
	gen prv_earn_p = 0
	
	/*modification: previous earnings can vary, DP, 12-07*/
	
	if "$sps_pinc" == "" {
		global sps_pinc = $SEWage_level		/* default value */
			}
		gen prv_earn_s = $value_selected_wage_s * $share * $sps_pinc
        }

	if $SELECT==4 {

		/*the principal earner is receiving from 0 to 200$ of APW, and the spouse is earning the same level of APW as the principal*/
 
	        range earnings $min $max 201
		gen double spousinc = 0
	        * gen double spousinc = max(0,(earnings/$spsinc)*$spsinc)

		 /*if sp income 100$APW=$spsinc, dp, 07/04/03*/

		/*the principal earner is working 67$ of APW, the sp working from 0 to 200. Disactivate the first two lines with /*...*/, and activate the following two lines, 08/04/03, dp*/

		* range spousinc $min $max 201
		* gen double earnings= $APW*.67

	        gen workdayp = $wd_p
		replace workdayp=0 if earnings==0

	        gen workdays = $wd_s
		replace workdays=0 if spousinc==0

	        gen time = `mintime'
		/* This file: one (potential) earner case. */
		/* SELECT=4: principal full time employed; varying levels of earnings */
		/* ==> principal's previous earnings are same as current earnings */
		gen prv_earn_p = earnings
		gen prv_earn_s = 0
			
	        }
	        
/************************************************************************************************************************************/
/* CHILD CARE CHILD CARE CHILD CARE CHILD CARE CHILD CARE CHILD CARE CHILD CARE CHILD CARE CHILD CARE CHILD CARE CHILD CARE */

	if $SELECT==5 {
		range CC_Fee 35 0 201
		replace CC_Fee = CC_Fee/100 * $APW 
		
	        * the number of days both partners work per week
	        if $DB_WS==1 {
		        global   wd_s  = 5        /* days/week worked by spouse*/
		        }
        	if $DB_WS==0 {
        		global   wd_s  = 0
        		}
        	* new condition for spouse not working but available to work
		if $DB_WS==2 { 
			global  wd_s  = 0
		    }

        	global   wd_p  = 5        /* days per week worked by principal*/
		
		/* Current earnings level */
		if "`pri_inc'" == "" {
			local pri_inc = $PWage_level	/* default value */
			}
		if "`sps_inc'" == "" {
			local sps_inc = $SEWage_level	/* default value */
			/*0.67 in the case that the spouse earner is receiving 2/3 of APW, 08/04/03, dp*/
			}

		gen double earnings = $value_selected_wage_p * $share * `pri_inc'
		gen double spousinc = $value_selected_wage_s * $share * `sps_inc'

		/* Current number of workdays */			
		gen workdayp = $wd_p
		replace workdayp=0 if earnings==0

		gen workdays = $wd_s
		replace workdays=0 if spousinc==0
			
		/* Previous income is set to zero */
		if "`pri_pinc'" == "" {
			local pri_pinc = $PWage_level		/* default value */
			}
		if "`sps_pinc'" == "" {
			local sps_pinc = $SEWage_level		/* default value */
			}
		
		gen prv_earn_p = $value_selected_wage_p * $share * `pri_inc'
		gen prv_earn_s = $value_selected_wage_s * $share * `sps_inc'

		gen time = `mintime'

		/* Childcare fees are the only thing which changes. Childcare costs will vary from 0 to 100% of APW */

		}

/************************************************************************************************************************************/
/* begin CHILD AGE EVOLUTION */

if $SELECT==6 {  

        * the number of days both partners work per week
        if $DB_WS==1 {
        global   wd_s  = 5}        /* days/week worked by spouse*/
        if $DB_WS==0 {
        global   wd_s  = 0}
        * new condition for spouse not working but available to work
	if $DB_WS==2 { 
	global wd_s = 0}

        global   wd_p  = 5        /* days per week worked by principal*/
      
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
			global pri_inc = $PWage_level	/* default value */
			}
	if "$sps_inc" == "" {
			global sps_inc = $SEWage_level	/* default value */
				
			}
			
	if $DB_WS==0 { 
			global sps_inc = $SEWage_level
		    }
	* new condition for spouse not working but available to work
	if $DB_WS==2 { 
			global sps_inc = $SEWage_level
		    }
			
    gen double earnings = $value_selected_wage_p * $share * $pri_inc
	gen double spousinc = $value_selected_wage_s * $share * $sps_inc
	gen workdayp = $wd_p
	gen workdays = $wd_s
        
            
      
      	/* Previous income is set to zero */
	if "$pri_pinc" == "" {
				global pri_pinc = $PWage_level		/* default value */
				}
	if "$sps_pinc" == "" {
				global sps_pinc = $SEWage_level		/* default value */
				}
			
	gen prv_earn_p = $value_selected_wage_p * $share * $pri_pinc
	gen prv_earn_s = $value_selected_wage_s * $share * $sps_pinc
      			
	}

/***************************************** end CHILD AGE EVOLUTION *********************************
****************************************************************************/
	        
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
		
*	gen cc_cost = 0.15*$APW*((k1>0)*(k1<4)+(k2>0)*(k2<4)+(k3>0)*(k3<4)+(k4>0)*(k4<4)) 	commented bkp 5/3/13	
		

/*FOR TABLE 4.1, COLUMN 4: WORKDAYS=2*/
*replace workdays=2
/*FOR TABLE 4.1, COLUMN 2: WORKDAYP=2*/
*replace workdayp=0.5



   compress
   cd "${path}"
   save "${OUTPATH}pers" ,replace  /*pers file is stored in the temporary name-specified subfolder, 13-11-09*/
   end

tbpers
