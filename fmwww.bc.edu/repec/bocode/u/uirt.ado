*uirt.ado 
*ver 2.2.1
*2022.11.13
*everythingthatcounts@gmail.com

capture prog drop uirt
program define uirt, eclass
version 10
syntax [varlist] [if] [in] [, GRoup(str asis)  pcm(varlist) gpcm(varlist) GUEssing(str) chi2w(str) sx2(str) icc(str asis) esf(str asis) inf(str asis) PRiors(str) THeta(str) fix(str) init(str) ERRors(str) TRace(numlist integer max=1 >=0 <=2) nip(numlist integer max=1 >=2 <=195) nit(numlist integer max=1 >=0) NINrf(numlist integer max=1 >=0) crit_ll(numlist max=1 >0 <1) crit_par(numlist max=1 >0 <1) NOTable NOHeader SAVingname(namelist max=1) ANegative]

	

	if replay() {
			if("`e(cmd)'" != "uirt"){
				error 301
			}
			else{
				di "/estimates replay/"
				di "Unidimensional item response theory model         Number of obs     =        `e(N)'"
				di "                                                  Number of items   =        `e(N_items)'"
				di "                                                  Number of groups  =        `e(N_gr)'"
				di "Log likelihood = "  %15.4f `e(ll)'
				di ""
				ereturn display
			}
	}
	else{

		marksample touse ,novarlist 
		
		m: eret_cmdline="uirt "+`"`0'"'
		m: eret_if=`"`if'"'
		m: eret_in=`"`in'"'
				
		unab items: `varlist'
	
		m: st_local("items_isnumvar",verify_isnumvar("`items'"))
		if(strlen("`items_isnumvar'")){
			di as err "{p 0 2}string variables not allowed in item varlist;{p_end}"
			di as err "{p 0 2}the following item variables are strings: `items_isnumvar'{p_end}"
			exit 109
		}
		
		m: st_local("items_duplicates",verify_dupvars("`items'"))
		if(strlen("`items_duplicates'")){
			di as err "{p 0 2}the following item variables are entered multiple times:{p_end}"
			di as err "{p 0 2}`items_duplicates'{p_end}"
			exit 198
		}
		

*************************************************		
		if("`anegative'"==""){
			local check_a = 1
		}
		else{
			local check_a = 0
		}
		
*************************************************
		if(strlen("`fix'")){
			cap __fix_option , `fix'
			if(_rc){
				di as err "{p 0 2}A problem was encountered in the  fix() option;{p_end}"
				di as err "{p 0 2}the proper syntax is: fix([prev from(str) used i(str) d(str) c(str) miss]){p_end}"
				di as err "{p 0 2}fix(`fix') returns the following error:{p_end}"
				qui __fix_option , `fix'
			}
			if(strlen("`s(fix_note)'")){
					di "{p 0 2}`s(fix_note)'{p_end}"
			}
			local fix_imatrix="`s(fix_imatrix)'"
			local fix_dmatrix="`s(fix_dmatrix)'"
			local fix_cmatrix="`s(fix_cmatrix)'"
			local fix_miss="`s(fix_miss)'"
			local fix_V_greenlight="`s(fix_V_greenlight)'"
			local fix_prev="`s(fix_prev)'"
		}
		else{
			local fix_imatrix=""
			local fix_dmatrix=""
			local fix_cmatrix=""
			local fix_miss=""
			local fix_V_greenlight="0"
			local fix_prev=""
		}
		
		if(strlen("`fix_imatrix'")){
			cap mat l `fix_imatrix'
			if(_rc){
				qui mat l `fix_imatrix'
			}
		}
		
		if(strlen("`fix_dmatrix'")){
			cap mat l `fix_dmatrix'
			if(_rc){
				qui mat l `fix_dmatrix'
			}
		}
		
		if(strlen("`fix_cmatrix'")){
			cap mat l `fix_cmatrix'
			if(_rc){
				qui mat l `fix_cmatrix'
			}
		}
		
		if("`fix_miss'"==""){
			local check_miss_fix=1
		}
		else{
			local check_miss_fix=0
		}
		m: check_matrices("`fix_imatrix'","`fix_cmatrix'","`fix_dmatrix'",.,`check_miss_fix', `check_a')

*******************************************************
		if(strlen("`errors'")==0){
			local errors="cdm"
			m: stored_V=J(0,0,.)
		}
		else{
			if(lower("`errors'")=="cdm" | lower("`errors'")=="rem" | lower("`errors'")=="sem"| lower("`errors'")=="cp" | lower("`errors'")=="stored"){
				if(lower("`errors'")=="cdm" | lower("`errors'")=="rem" | lower("`errors'")=="sem"| lower("`errors'")=="cp"){
					local errors=lower("`errors'")
					m: stored_V=J(0,0,.)
				}
				else{
					if(lower("`errors'")=="stored" & `fix_V_greenlight'){
						local errors=lower("`errors'")
						m: stored_V=st_matrix("e(V)")
					}
					else{
						di as err "{p 0 2}errors(stored) require fix(prev) or fix(form()){p_end}"
						exit 198
					}
				}
			}
			else{
				di as err "{p 0 2}`errors' is not a valid errors() value;{p_end}"
				di as err "{p 0 2}allowed values are: cdm | rem | sem | cp{p_end}"
				exit 198
			}
		}
		
*************************************************
		if(strlen("`init'")){
			cap __init_option , `init'
			if(_rc){
				di as err "{p 0 2}A problem was encountered in the init() option;{p_end}"
				di as err "{p 0 2}the proper syntax is: init([prev from(str) used i(str) d(str) miss]){p_end}"
				di as err "{p 0 2}init(`init') returns the following error:{p_end}"
				qui __init_option , `init'
			}
			if(strlen("`s(init_note)'")){
					di "{p 0 2}`s(init_note)'{p_end}"
			}
			local init_imatrix="`s(init_imatrix)'"
			local init_dmatrix="`s(init_dmatrix)'"
			local init_miss="`s(init_miss)'"
			local init_prev="`s(init_prev)'"
		}
		else{
			local init_imatrix=""
			local init_dmatrix=""
			local init_miss=""
			local init_prev=""
		}

		if(strlen("`init_imatrix'")){
			cap mat l `init_imatrix'
			if(_rc){
				qui mat l `init_imatrix'
			}
		}
		
		if(strlen("`init_dmatrix'")){
			cap mat l `init_dmatrix'
			if(_rc){
				qui mat l `init_dmatrix'
			}
		}
		
		if(strlen("`init_dmatrix'") & strlen("`fix_dmatrix'")){
			di as err "{p 0 2}distribution parameters were declared both in fix() and init() options{p_end}"
			exit 198
		}
		
		if("`init_miss'"==""){
			local check_miss_init=1
		}
		else{
			local check_miss_init=0
		}
		
		m: check_matrices("`init_imatrix'","`fix_catimatrix'","`init_dmatrix'",.,`check_miss_init', `check_a')
					
*************************************************
		if(strlen("`theta'")){
			cap __theta_option `theta'
			if(_rc){
				di as err "{p 0 2}A problem was encountered in the theta() option;{p_end}"
				di as err "{p 0 2}the proper syntax is: theta([vn1 vn2] [,eap nip(#) pv(#) pvreg(str) suf(str) sc(#,#) skipn]){p_end}"
				di as err "{p 0 2}theta(`theta') returns the following error:{p_end}"
				qui __theta_option `theta'
			}
			local theta_skipnote="`s(theta_skipnote)'"
			
			if(strlen("`s(theta_suffix)'")){
				local theta_suffix="`s(theta_suffix)'"
			}
			else{
				local theta_suffix="."
			}
			
			
			if(strlen("`s(theta_eap)'")){
				m: st_local("thexistlist",verify_thetaexist(eap_names))
				if(strlen("`thexistlist'")){
					di as err "{p 0 2}The following variables you asked to create are already defined: `thexistlist'{p_end}"
					exit 110
				}
				local add_theta=1
			}
			else{
				local add_theta=0
			}
			
			if(strlen("`s(theta_pv)'")){
				local pv=`s(theta_pv)'
				m: st_local("pvexistlist",verify_pvexist(`pv',"`theta_suffix'"))
				if(strlen("`pvexistlist'")){
					di as err "{p 0 2}The following variables you asked to create are already defined: `pvexistlist'{p_end}"
					exit 110
				}
			}
			else{
				local pv=0
			}
			
			if(strlen("`s(theta_pvreg)'")==0){
				local pvreg="."
			}
			else{
				local pvreg="`s(theta_pvreg)'"
				if(`pv'==0){
					di as err "{p 0 2}you have to provide a positive number of PVs in pv() option in order to use pvreg() option{p_end}"
					exit 198
				}
				if(strpos("`pvreg'",",")){
					di as err char(34)+","+char(34)+" is not allowed in the pvreg() option"
					exit 198
				}
				
				if(strlen("`fix_prev'")|strlen("`init_prev'")){
					m: backup_est=st_tempname()
					m: stata("qui estimates store "+backup_est)
				}
				
				tempvar verify_xtmixed
				qui gen `verify_xtmixed'=rnormal() if `touse'
				if(`c(stata_version)'>=12){
					version `c(stata_version)'
				}
				cap xtmixed `verify_xtmixed' `pvreg',iter(0)
				if(_rc){
					di as err "{p 0 2}A problem was encountered in the  pvreg() option;{p_end}"
					di as err "{p 0 2}xtmixed depvar `pvreg' returns the following error:{p_end}"
					qui xtmixed `verify_xtmixed' `pvreg',iter(0)
				}
				else{
					qui drop `verify_xtmixed'
				}
				if((`c(stata_version)'<12)&(`e(k_r)')>1){
					if(strpos("`pvreg'","||")){
						di as err "{p 0 2}Multilevel syntax is not allowed in the pvreg() option if Stata version is lower than 12.0{p_end}"
						exit 198
					}
				}
				version 10
				
				if(strlen("`fix_prev'")|strlen("`init_prev'")){
					m: stata("qui estimates restore "+backup_est)
					m: stata("qui estimates drop "+backup_est)
				}
				
			}
			
			m: st_local("if_theta_scale",strofreal(cols(theta_scale)==2))
			if(`if_theta_scale'){
				if(`add_theta' | `pv'){
					m: st_local("theta_sd",strofreal(theta_scale[2]))
					if(`theta_sd'<=0){
						m: _error("theta(scale()): standard deviation of theta scale must be positive")
					}
				}
				else{
					m: theta_scale=J(0,0,.)
				}
			}
			else{
				m: theta_scale=J(0,0,.)
			}
			
			if(strlen("`theta_skipnote'")==0){
				m: theta_notes=eret_cmdline
			}
			else{
				m: theta_notes=""
			}
			
			
		}
		else{
			local theta_suffix="."
			local add_theta=0
			local pv=0
			local pvreg="."
			m: theta_scale=J(0,0,.)
			m: theta_notes=""
			m: eap_names=""
		}
	
		
*************************************************
		if(strlen(`"`group'"')){
		
			cap __group_option `group'
			if(_rc){
				di as err "{p 0 2}A problem was encountered in the  group() option;{p_end}"
				di as err "{p 0 2}the proper syntax is: group(varname [, ref(#) dif(varlist) free slow ]){p_end}"
				di as err "{p 0 2}group(`group') returns the following error:{p_end}"
				qui __group_option `group'
			}
			local group="`s(group_var)'"
			local reference="`s(group_reference)'"
			local dist="`s(group_free)'"
			local noupd_quad_betw_em="`s(group_slow)'"
			local dif="`s(group_dif)'"
			local dif_format="`s(group_dif_format)'"
			local dif_tw=`"`s(group_dif_tw)'"'
			local dif_colors="`s(group_dif_colors)'"
			m: etet_grstrip="`s(group_cmdstrip)'"
			
			m: st_local("gr_is_item",strofreal(sum("`group'":==tokens("`items'")')))
			if(`gr_is_item'){
				di as err "{p 0 2}grouping variable `group' is also declared as an item{p_end}"
				exit 198
			}
			
			if(strlen("`s(group_dif_cleargraphs)'")){
				local dif_cleargraphs=1
			}
			else{
				local dif_cleargraphs=0
			}
			
			if("`reference'"==""){
		        local reference=.
	        }
	        else{
	        	qui tab `group' if `group'==`reference' & `touse'
		        if(r(N)==0){
		        	di as err "{p 0 2}grouping variable `group' has no valid observations for ref(`reference'){p_end}"
		        	error(2000)
		        }
	        }
			
			if("`dist'"!=""){
				if(strlen("`fix_imatrix'")==0){
					di as err "{p 0 2}group(,free) option requires fixing parameters of at least one item{p_end}"
					exit 198
				}
				else{
					local estimate_dist=1
				}
			}
			else{
				local estimate_dist=0
			}
			
			if("`noupd_quad_betw_em'"!=""){
				local upd_quad_betw_em=0
			}
			else{
				local upd_quad_betw_em=1
			}
	
			if (strlen("`dif'")>0){
				qui tab `group' if `touse'
				if(r(r)!=2){
					di as err "{p 0 2}grouping variable must have exactly two values in order to analyze for DIF{p_end}"
					exit 198
				}
				else{
					if("`dif'"=="."){
						local dif_list="`items'"
					}
					else{
						unab dif_list: `dif'
						
						m: st_local("dif_missinall",*compare_varlist("`items'","`dif_list'")[4])
						if(`dif_missinall'>0){
							di as err "{p 0 2}`dif_missinall' items in group(,dif()) are not declared in the main list of items:{p_end}"
							m: st_local("dif_misslist",*compare_varlist("`items'","`dif_list'")[3])
							di as err "{p 0 2}`dif_misslist'{p_end}"
							exit 198
						}
					}
								
					local okdif=0
					local notokdif=0
					m: diflist=J(0,1,"")
					m: nodif_list=""
					foreach item of varlist `dif_list'{
						qui tab `group' `item' if `touse'
						if(r(r)==2){
							local okdif=`okdif'+1
							m: diflist=diflist\"`item'"
						}
						else{
							local ++notokdif					
							m: nodif_list=nodif_list+" `item'"					
						}
					}
					if(`notokdif'>0){
						di "{p 0 2}Note: `notokdif' items for DIF analysis not responded in both groups; `okdif' items left for DIF analysis{p_end}"
					}
					if(`okdif'==0){
						m: diflist=J(0,1,"")
					}
				}
			}
			else{
				m: diflist=J(0,1,"")
			}
			
			
		}
		else{
			local group="."
			local reference=.
			local estimate_dist=0
			local upd_quad_betw_em=1
			m: diflist=J(0,1,"")
			m: etet_grstrip=""
			local dif_format=""
			local dif_tw=""
			m: dif_colours=""
			local dif_cleargraphs=0
		}
		
		if(strlen("`dif_format'")==0){
			local dif_format="png"
			local default_dif_format=1
		}
		else{
			if("`dif_format'"=="png" | "`dif_format'"=="gph" | "`dif_format'"=="eps"){
				local dif_format="`dif_format'"
				local default_dif_format=0
			}
			else{
				di as err "{p 0 2}`dif_format' is not a valid dif(,format()) value;{p_end}"
				di as err "{p 0 2}only: png | gph | eps entries are allowed{p_end}"
				exit 198
			}
		}

		
*******************************************************
		if(strlen("`priors'")){
			cap __priors_option `priors'
			if(_rc){
				di as err "{p 0 2}A problem was encountered in the priors() option;{p_end}"
				di as err "{p 0 2}the proper syntax is: priors(varlist [, a(#,#) b(#,#) c(#,#)]){p_end}"
				di as err "{p 0 2}priors(`priors') returns the following error:{p_end}"
				qui __priors_option `priors'
			}
			m: eret_priorstrip="`s(priors_cmdstrip)'"
			if(strlen("`s(priors_varlist)'")){
				unab priors_list: `s(priors_varlist)'
				m: st_local("priors_missinall",*compare_varlist("`items'","`priors_list'")[4])
				if(`priors_missinall'>0){
					di as err "{p 0 2}`priors_missinall' items in priors() are not declared in the main list of items:{p_end}"
					m: st_local("priors_misslist",*compare_varlist("`items'","`priors_list'")[3])
					di as err "{p 0 2}`priors_misslist'{p_end}"
					exit 198
				}
				m: st_local("priors_duplicates",verify_dupvars("`priors_list'"))
				if(strlen("`priors_duplicates'")){
					di as err "{p 0 2}the following item variables are entered multiple times in priors():{p_end}"
					di as err "{p 0 2}`priors_duplicates'{p_end}"
					exit 198
				}
				m: priorslist=tokens("`priors_list'")'	
			}
			else{
				m: priorslist=tokens("`items'")'
			}
		}
		else{
			m: priorslist=J(0,1,"")
			m: a_normal_prior=.
			m: b_normal_prior=.
			m: c_beta_prior=.
			m: eret_priorstrip=""
		}
		
*******************************************************
		if strlen("`pcm'")>0{
			unab allvars: *
			if("`allvars'"=="`pcm' `touse'"){
				local pcm_list="`items'"
			}
			else{
				unab pcm_list: `pcm'
			}
			
			m: st_local("pcm_missinall",*compare_varlist("`items'","`pcm_list'")[4])
			if(`pcm_missinall'>0){
				di as err "{p 0 2}`pcm_missinall' items in pcm() are not declared in the main list of items:{p_end}"
				m: st_local("pcm_misslist",*compare_varlist("`items'","`pcm_list'")[3])
				di as err "{p 0 2}`pcm_misslist'{p_end}"
				exit 198
			}
			m: st_local("pcm_duplicates",verify_dupvars("`pcm_list'"))
			if(strlen("`pcm_duplicates'")){
				di as err "{p 0 2}the following item variables are entered multiple times in pcm():{p_end}"
				di as err "{p 0 2}`pcm_duplicates'{p_end}"
				exit 198
			}
			
			m: pcmlist=tokens("`pcm_list'")'
		}
		else{
			m: pcmlist=J(0,1,"")
		}
		
*******************************************************
		if strlen("`gpcm'")>0{
			unab allvars: *
			if("`allvars'"=="`gpcm' `touse'"){
				local gpcm_list="`items'"
			}
			else{
				unab gpcm_list: `gpcm'
			}
			
			m: st_local("gpcm_missinall",*compare_varlist("`items'","`gpcm_list'")[4])
			if(`gpcm_missinall'>0){
				di as err "{p 0 2}`gpcm_missinall' items in gpcm() are not declared in the main list of items:{p_end}"
				m: st_local("gpcm_misslist",*compare_varlist("`items'","`gpcm_list'")[3])
				di as err "{p 0 2}`gpcm_misslist'{p_end}"
				exit 198
			}
			m: st_local("gpcm_duplicates",verify_dupvars("`gpcm_list'"))
			if(strlen("`gpcm_duplicates'")){
				di as err "{p 0 2}the following item variables are entered multiple times in gpcm():{p_end}"
				di as err "{p 0 2}`gpcm_duplicates'{p_end}"
				exit 198
			}
			
			m: gpcmlist=tokens("`gpcm_list'")'
		}
		else{
			m: gpcmlist=J(0,1,"")
		}

*******************************************************		
		if(strlen("`guessing'")){
		
			cap __guess_option `guessing'
			if(_rc){
				di as err "{p 0 2}A problem was encountered in the guess() option;{p_end}"
				di as err "{p 0 2}the proper syntax is: guess(varlist [, att(#) lr(#)]){p_end}"
				di as err "{p 0 2}guess(`guessing') returns the following error:{p_end}"
				qui __guess_option `guessing'
			}
			
			local guessing_attempts=`s(guess_attempts)'
			local guessing_lrcrit="`s(guess_lrcrit)'"
			if("`guessing_lrcrit'"==""){
				local guessing_lrcrit=0.05
			}
			
			if(strlen("`s(guess_varlist)'")){
			
				unab guess_list: `s(guess_varlist)'
				
				m: st_local("guess_missinall",*compare_varlist("`items'","`guess_list'")[4])
				if(`guess_missinall'>0){
					di as err "{p 0 2}`guess_missinall' items in guess() are not declared in the main list of items:{p_end}"
					m: st_local("guess_misslist",*compare_varlist("`items'","`guess_list'")[3])
					di as err "{p 0 2}`guess_misslist'{p_end}"
					exit 198
				}
				m: st_local("guess_duplicates",verify_dupvars("`guess_list'"))
				if(strlen("`guess_duplicates'")){
					di as err "{p 0 2}the following item variables are entered multiple times in guess():{p_end}"
					di as err "{p 0 2}`guess_duplicates'{p_end}"
					exit 198
				}
					
			}
			else{
				local guess_list="`items'"
			}
			
			local okguess=0
			local notokguess=0
			m: guesslist=J(0,1,"")
			m: noguess_list=""
			foreach item of varlist `guess_list'{
				qui tab `item' if `touse'
				if(r(r)==2){
					local okguess=`okguess'+1
					m: guesslist=guesslist\"`item'"
				}
				else{
					local ++notokguess					
					m: noguess_list=noguess_list+" `item'"					
				}
			}
			if(`notokguess'>0){
				di "{p 0 2}Note: `notokguess' items specified for fitting 3PLM have more than 2 response categories; `okguess' items left for 3PLM{p_end}"			
			}
			if(`okguess'==0){
				m: guesslist=J(0,1,"")
			}
		}
		else{
			m: guesslist=J(0,1,"")
			local guessing_attempts=5
			local guessing_lrcrit=0.05
		}

*******************************************************		
		m: st_local("comp_pcm_gpcm",strofreal(rows(pcmlist)*rows(gpcmlist)>0))
		if(`comp_pcm_gpcm'){
			m: st_local("common_n",*compare_varlist("`pcm_list'","`gpcm_list'")[2])
			if(`common_n'){
				di as err "{p 0 2}`common_n' items are listed both in pcm() and gpcm():{p_end}"
				m: st_local("common_list",*compare_varlist("`pcm_list'","`gpcm_list'")[1])
				di as err "{p 0 2}`common_list'{p_end}"
				exit 198
			}
		}
	
		m: st_local("comp_pcm_guess",strofreal(rows(pcmlist)+rows(guesslist)>0))
		if(`comp_pcm_guess'){
			m: st_local("common_n",*compare_varlist("`pcm_list'","`guess_list'")[2])
			if(`common_n'){
				di as err "{p 0 2}`common_n' items are listed both in pcm() and guessing():{p_end}"
				m: st_local("common_list",*compare_varlist("`pcm_list'","`guess_list'")[1])
				di as err "{p 0 2}`common_list'{p_end}"
				exit 198
			}
		}
		
		m: st_local("comp_gpcm_guess",strofreal(rows(gpcmlist)*rows(guesslist)>0))
		if(`comp_gpcm_guess'){
			m: st_local("common_n",*compare_varlist("`gpcm_list'","`guess_list'")[2])
			if(`common_n'){
				di as err "{p 0 2}`common_n' items are listed both in gpcm() and guessing():{p_end}"
				m: st_local("common_list",*compare_varlist("`gpcm_list'","`guess_list'")[1])
				di as err "{p 0 2}`common_list'{p_end}"
				exit 198
			}
		}
		
*******************************************************
		if(strlen("`icc'")){
		
			cap __icc_option `icc'
			if(_rc){
				di as err "{p 0 2}A problem was encountered in the  icc() option;{p_end}"
				di as err "{p 0 2}the proper syntax is: icc(varlist [, bins(#) format(str) noobs pv pvbin(#) c(str) tw(str) pref(str) suf(str) cl]){p_end}"
				di as err "{p 0 2}icc(`icc') returns the following error:{p_end}"
				qui __icc_option `icc'
			}

			local icc_bins="`s(icc_bins)'"
			local icc_format="`s(icc_format)'"
			local icc_noobs="`s(icc_noobs)'"
			local icc_pv="`s(icc_pv)'"
			local icc_pvbin="`s(icc_pvbin)'"
			local icc_tw=`"`s(icc_tw)'"'
			
			if(strlen("`s(icc_cleargraphs)'")){
				local icc_cleargraphs=1
			}
			else{
				local icc_cleargraphs=0
			}
			
			if(strlen("`s(icc_varlist)'")){
				unab icc_list: `s(icc_varlist)'
				m: st_local("icc_missinall",*compare_varlist("`items'","`icc_list'")[4])
				if(`icc_missinall'>0){
					di as err "{p 0 2}`icc_missinall' items in icc() are not declared in the main list of items:{p_end}"
					m: st_local("icc_misslist",*compare_varlist("`items'","`icc_list'")[3])
					di as err "{p 0 2}`icc_misslist'{p_end}"
					exit 198
				}
				m: st_local("icc_duplicates",verify_dupvars("`icc_list'"))
				if(strlen("`icc_duplicates'")){
					di as err "{p 0 2}the following item variables are entered multiple times in icc():{p_end}"
					di as err "{p 0 2}`icc_duplicates'{p_end}"
					exit 198
				}
				m: icclist=tokens("`icc_list'")'	
			}
			else{
				m: icclist=tokens("`items'")'
			}
		}
		else{
			m: icclist=J(0,1,"")
			m: icc_prefix_suffix=("","")'
			local icc_bins=""
			local icc_format=""
			local icc_noobs=""
			local icc_cleargraphs=0
			local icc_pv=""
			local icc_pvbin=""
			local icc_tw=""
			m: icc_colours=""
		}

		if(strlen("`icc_noobs'")==0){
			local icc_obs=1
		}
		else{
			local icc_obs=0
			local icc_bins=""
			local icc_pv=""
			local icc_pvbin=""
		}
		
		if(strlen("`icc_format'")==0){
			local icc_format="png"
		}
		else{
			if("`icc_format'"=="png" | "`icc_format'"=="gph" | "`icc_format'"=="eps"){
				local icc_format="`icc_format'"
				if(`default_dif_format'){
					local dif_format="`icc_format'"
				}
			}
			else{
				di as err "{p 0 2}`icc_format' is not a valid icc(,format()) value;{p_end}"
				di as err "{p 0 2}only: png | gph | eps entries are allowed{p_end}"
				exit 198
			}
		}
		
		if(strlen("`icc_pv'")==0){
			if(strlen("`icc_pvbin'")){
				di "{p 0 2}Note: icc_pvbin(`icc_pvbin') will not take effect unless you add icc_pv option; observed proportions will be computed by numerical itegration{p_end}"
			}
			local icc_pvbin=0
		}
		else{
			if(strlen("`icc_pvbin'")==0){
				local icc_pvbin=10000
			}
		}
		
		if(strlen("`icc_bins'")==0){
			local icc_bins=100
		}

*******************************************************
		if(strlen("`esf'")){
		
			cap __esf_option `esf'
			if(_rc){
				di as err "{p 0 2}A problem was encountered in the  esf() option;{p_end}"
				di as err "{p 0 2}the proper syntax is: esf(varlist [, tesf all bins(#) noobs c(str) tw(str) format(str) pref(str) suf(str) cl]){p_end}"
				di as err "{p 0 2}esf(`esf') returns the following error:{p_end}"
				qui __esf_option `esf'
			}

			local esf_bins="`s(esf_bins)'"
			local esf_format="`s(esf_format)'"
			local esf_noobs="`s(esf_noobs)'"
			local esf_mode=`s(esf_mode)'
			local esf_tw=`"`s(esf_tw)'"'
			
			if(strlen("`s(esf_cleargraphs)'")){
				local esf_cleargraphs=1
			}
			else{
				local esf_cleargraphs=0
			}
			
			if(strlen("`s(esf_varlist)'")){
				unab esf_list: `s(esf_varlist)'
				m: st_local("esf_missinall",*compare_varlist("`items'","`esf_list'")[4])
				if(`esf_missinall'>0){
					di as err "{p 0 2}`esf_missinall' items in esf() are not declared in the main list of items:{p_end}"
					m: st_local("esf_misslist",*compare_varlist("`items'","`esf_list'")[3])
					di as err "{p 0 2}`esf_misslist'{p_end}"
					exit 198
				}
				m: st_local("esf_duplicates",verify_dupvars("`esf_list'"))
				if(strlen("`esf_duplicates'")){
					di as err "{p 0 2}the following item variables are entered multiple times in esf():{p_end}"
					di as err "{p 0 2}`esf_duplicates'{p_end}"
					exit 198
				}
				m: esflist=tokens("`esf_list'")'	
			}
			else{
				m: esflist=tokens("`items'")'
			}
		}
		else{
			m: esflist=J(0,1,"")
			m: esf_prefix_suffix=("","")'
			local esf_bins=""
			local esf_format=""
			local esf_noobs=""
			local esf_mode=.
			local esf_cleargraphs=0
			local esf_tw=""
			m: esf_colour=""
		}

		if(strlen("`esf_noobs'")==0){
			local esf_obs=1
		}
		else{
			local esf_obs=0
			local esf_bins=""
		}
		
		if(strlen("`esf_format'")==0){
			local esf_format="png"
		}
		else{
			if("`esf_format'"=="png" | "`esf_format'"=="gph" | "`esf_format'"=="eps"){
				local esf_format="`esf_format'"
				if(`default_dif_format'){
					local dif_format="`esf_format'"
				}
			}
			else{
				di as err "{p 0 2}`esf_format' is not a valid esf(,format()) value;{p_end}"
				di as err "{p 0 2}only: png | gph | eps entries are allowed{p_end}"
				exit 198
			}
		}
				
		if(strlen("`esf_bins'")==0){
			local esf_bins=100
		}
		
*******************************************************
		if(strlen("`inf'")){
		
			cap __inf_option `inf'
			if(_rc){
				di as err "{p 0 2}A problem was encountered in the  inf() option;{p_end}"
				di as err "{p 0 2}the proper syntax is: inf(varlist [, test se gr tw(str)]){p_end}"
				di as err "{p 0 2}inf(`inf') returns the following error:{p_end}"
				qui __inf_option `inf'
			}
			
			if(strlen("`s(inf_note)'")){
				di "{p 0 2}`s(inf_note)'{p_end}"
			}

			local inf_mode=`s(inf_mode)'
			local inf_ifgr=`s(inf_ifgr)'
			local inf_tw=`"`s(inf_tw)'"'
						
			if(strlen("`s(inf_varlist)'")){
				unab inf_list: `s(inf_varlist)'
				m: st_local("inf_missinall",*compare_varlist("`items'","`inf_list'")[4])
				if(`inf_missinall'>0){
					di as err "{p 0 2}`inf_missinall' items in inf() are not declared in the main list of items:{p_end}"
					m: st_local("inf_misslist",*compare_varlist("`items'","`inf_list'")[3])
					di as err "{p 0 2}`inf_misslist'{p_end}"
					exit 198
				}
				m: st_local("inf_duplicates",verify_dupvars("`inf_list'"))
				if(strlen("`inf_duplicates'")){
					di as err "{p 0 2}the following item variables are entered multiple times in inf():{p_end}"
					di as err "{p 0 2}`inf_duplicates'{p_end}"
					exit 198
				}
				m: inflist=tokens("`inf_list'")'	
			}
			else{
				m: inflist=tokens("`items'")'
			}
		}
		else{
			m: inflist=J(0,1,"")
			local inf_mode=.
			local inf_ifgr=.
			local inf_tw=""
		}
							
							
*******************************************************	

		if(strlen("`chi2w'")){
			cap __chi2w_option `chi2w'
			if(_rc){
				di as err "{p 0 2}A problem was encountered in the  chi2w() option;{p_end}"
				di as err "{p 0 2}the proper syntax is: chi2w(varlist [, bins(#) npqm(#) npqr]){p_end}"
				di as err "{p 0 2}chi2w(`chi2w') returns the following error:{p_end}"
				qui __chi2w_option `chi2w'
			}
			local chi2w_bins="`s(chi2w_bins)'"
			local chi2w_npqmin="`s(chi2w_npqmin)'"
			local chi2w_npqreport="`s(chi2w_npqreport)'"
	
			if(strlen("`s(chi2w_varlist)'")){
				unab chi2w_list: `s(chi2w_varlist)'
				m: st_local("chi2w_missinall",*compare_varlist("`items'","`chi2w_list'")[4])
				if(`chi2w_missinall'>0){
					di as err "{p 0 2} `chi2w_missinall' items in chi2w() are not declared in the main list of items:{p_end}"
					m: st_local("chi2w_misslist",*compare_varlist("`items'","`chi2w_list'")[3])
					di as err "{p 0 2} `chi2w_misslist'{p_end}"
					exit 198
				}
				m: st_local("chi2w_duplicates",verify_dupvars("`chi2w_list'"))
				if(strlen("`chi2w_duplicates'")){
					di as err "{p 0 2} the following item variables are entered multiple times in chi2w():{p_end}"
					di as err "{p 0 2} `chi2w_duplicates'{p_end}"
					exit 198
				}
				m: chi2wlist=tokens("`chi2w_list'")'	
			}
			else{
				m: chi2wlist=tokens("`items'")'
			}
		}
		else{
			m: chi2wlist=J(0,1,"")
			local chi2w_bins=""
			local chi2w_npqmin=""
			local chi2w_npqreport=""
		}
		
		m: chi2w_control=J(3,1,.)
		if("`chi2w_bins'"==""){
			m: chi2w_control[1]=.
		}
		else{
			m: chi2w_control[1]=`chi2w_bins'
		}
		
		if("`chi2w_npqmin'"==""){
			m: chi2w_control[2]=20
		}
		else{
			m: chi2w_control[2]=`chi2w_npqmin'
		}
		
		if("`chi2w_npqreport'"==""){
			m: chi2w_control[3]=0
		}
		else{
			m: chi2w_control[3]=1
		}
		
		
*******************************************************
		if(strlen("`sx2'")){
			cap __sx2_option `sx2'
			if(_rc){
				di as err "{p 0 2}A problem was encountered in the  sx2() option;{p_end}"
				di as err "{p 0 2}the proper syntax is: sx2(varlist [, minf(#)]){p_end}"
				di as err "{p 0 2}sx2(`sx2') returns the following error:{p_end}"
				qui __sx2_option `sx2'
			}
			local sx2_minfreq="`s(sx2_minfreq)'"

			if(strlen("`s(sx2_varlist)'")){
				unab sx2_list: `s(sx2_varlist)'
				m: st_local("sx2_missinall",*compare_varlist("`items'","`sx2_list'")[4])
				if(`sx2_missinall'>0){
					di as err "{p 0 2}`sx2_missinall' items in sx2() are not declared in the main list of items:{p_end}"
					m: st_local("sx2_misslist",*compare_varlist("`items'","`sx2_list'")[3])
					di as err "{p 0 2}`sx2_misslist'{p_end}"
					exit 198
				}
				m: st_local("sx2_duplicates",verify_dupvars("`sx2_list'"))
				if(strlen("`sx2_duplicates'")){
					di as err "{p 0 2}the following item variables are entered multiple times in sx2():{p_end}"
					di as err "{p 0 2}`sx2_duplicates'{p_end}"
					exit 198
				}
				m: sx2list=tokens("`sx2_list'")'	
			}
			else{
				m: sx2list=tokens("`items'")'
			}
		}
		else{
			m: sx2list=J(0,1,"")
			local sx2_minfreq=""
		}
		
		
		if("`sx2_minfreq'"==""){
			m: sx2_min_freq=1
		}
		else{
			m: sx2_min_freq=`sx2_minfreq'
		}	
		
				
*******************************************************
		if(strlen("`savingname'")==0){
			local savingname="."
		}
	
		if("`nip'"==""){
			local nip=51
		}
		if("`theta_nip'"==""){
			local theta_nip=195
		}
	 
		if("`crit_ll'"==""){
			local crit_ll=10^-9
		}
		if("`crit_par'"==""){
			local crit_par=10^-4
		}
		if("`nit'"==""){
			local nit=100
		}	
		if("`ninrf'"==""){
			local ninrf=20
		}			
		if("`trace'"==""){
			local trace=1
		}
		
						
		m: uirt( "`touse'", "`items'", "`group'", `reference', `estimate_dist', `upd_quad_betw_em', "`errors'",stored_V, pcmlist, gpcmlist, guesslist, `guessing_attempts',`guessing_lrcrit', diflist,`add_theta', eap_names, "`theta_suffix'", `theta_nip', theta_scale, theta_notes, "`savingname'", "`fix_imatrix'", "`init_imatrix'", "`fix_cmatrix'", "`init_dmatrix'", "`fix_dmatrix'", `icc_cleargraphs',`icc_obs', icclist, chi2wlist, chi2w_control, sx2list, sx2_min_freq,`trace',`nip',`nit', `ninrf', `pv', "`pvreg'", `crit_ll', `crit_par', `icc_bins', `icc_pvbin', "`icc_format'",st_local("icc_tw"),icc_colours, icc_prefix_suffix, "`dif_format'",st_local("dif_tw"),dif_colours,`dif_cleargraphs', a_normal_prior, b_normal_prior, c_beta_prior, priorslist,esflist, `esf_bins', "`esf_format'",st_local("esf_tw"),esf_colour, esf_prefix_suffix, `esf_cleargraphs',`esf_obs', `esf_mode', inflist,`inf_mode', st_local("inf_tw"), `inf_ifgr', `check_a' )
		
		m: stata("ereturn local cmdline "+char(34)+eret_cmdline+char(34))
		m: eret_cmdstrip=strtrim("uirt `e(depvar)' "+eret_if+" "+eret_in+","+etet_grstrip+" nip(`nip') ninrf(`ninrf') crit_par(`crit_par') crit_ll(`crit_ll') `anegative' "+eret_priorstrip)
		m: stata("ereturn local cmdstrip "+char(34)+eret_cmdstrip+char(34))
		
*clean up mata objects
		foreach mata_obj in a_normal_prior b_normal_prior c_beta_prior chi2w_control chi2wlist diflist eret_cmdline eret_cmdstrip eret_if eret_in eret_priorstrip etet_grstrip gpcmlist guesslist icc_colours icc_prefix_suffix icclist esf_colour esf_prefix_suffix esflist dif_colours  pcmlist priorslist stored_V sx2_min_freq sx2list theta_notes theta_scale eap_names inflist{
			cap m: mata drop `mata_obj'
		}
		
	
*display results
		if("`noheader'"==""){
			di ""
			di "Unidimensional item response theory model         Number of obs     =        `e(N)'"
			di "                                                  Number of items   =        `e(N_items)'"
			di "                                                  Number of groups  =        `e(N_gr)'"
			di "Log likelihood = "  %15.4f `e(ll)'
			di ""
		}
		if("`notable'"==""){
			ereturn display
		}
}

end

// PROGRAMS TO HANDLE OPTIONS
cap program drop __priors_option
program define __priors_option, sclass
syntax varlist [, Anormal(numlist max=2 min=2) Bnormal(numlist max=2 min=2) Cbeta(numlist max=2 min=2)] 
	unab allvars: *
	if("`allvars'"=="`varlist'"){
		local varlist=""
	}
	sreturn local priors_varlist="`varlist'"
	m: a_normal_prior=strtoreal(tokens("`anormal'"))
	m: b_normal_prior=strtoreal(tokens("`bnormal'"))
	m: c_beta_prior=strtoreal(tokens("`cbeta'"))
	
	if(strlen("`anormal'`bnormal'`cbeta'")){
		sreturn local priors_cmdstrip="priors(`varlist'"+"*"*("`varlist'"=="")+","+"a(`anormal')"*(strlen("`anormal'")>0)+"b(`bnormal')"*(strlen("`bnormal'")>0)+"c(`cbeta')"*(strlen("`cbeta'")>0)+")"
	}
	else{
		sreturn local priors_cmdstrip=""
	}
	
	
end

cap program drop __guess_option
program define __guess_option, sclass
syntax varlist [, ATTempts(integer 5) LRcrit(numlist max=1 >0 <=1)] 
	unab allvars: *
	if("`allvars'"=="`varlist'"){
		local varlist=""
	}
	sreturn local guess_varlist="`varlist'"
	sreturn local guess_attempts="`attempts'"
	sreturn local guess_lrcrit="`lrcrit'"
end

cap program drop __icc_option
program define __icc_option, sclass
syntax varlist [, bins(numlist integer max=1 >=1) Format(str) CLeargraphs NOObs pv pvbin(numlist max=1 >=100 <=100000) Colors(str) tw(str asis) PREFix(str) SUFfix(str)] 
	unab allvars: *
	if(strlen(`"`tw'"')){
		qui gr dir
		local previous=r(list)			
		cap tw function x, `tw' nodraw		
		if(_rc){
			di as err "{p 0 2}A problem was encountered in the tw() option in icc();{p_end}"
			m: stata("di as err "+char(34)+"{p 0 2}twoway, "+`"`tw'"'+" returns the following error:{p_end}"+char(34))
			tw function x, `tw' nodraw
		}
		else{
			qui gr dir
			local current=r(list)
			local new : list  current - previous
			if(strlen("`new'")){
				gr drop `new'
			}
		}
	}
	if("`allvars'"=="`varlist'"){
		local varlist=""
	}
	sreturn local icc_varlist="`varlist'"
	sreturn local icc_bins="`bins'"
	sreturn local icc_format="`format'"
	sreturn local icc_cleargraphs="`cleargraphs'"
	sreturn local icc_noobs="`noobs'"
	sreturn local icc_pv="`pv'"
	sreturn local icc_pvbin="`pvbin'"
	m: icc_colours=tokens("`colors'")'
	sreturn local icc_tw=`"`tw'"'
	
	if(strlen("`prefix'")){
		local prefix="_"+strtoname("`prefix'")
		while(strpos("`prefix'","_")==1){
			local prefix=substr("`prefix'",2,strlen("`prefix'"))
		}
	}
	if(strlen("`suffix'")){
		local suffix="_"+strtoname("`suffix'")
		while(strpos("`suffix'","_")==1){
			local suffix=substr("`suffix'",2,strlen("`suffix'"))
		}	
	}
	m: icc_prefix_suffix=("`prefix'","`suffix'")'
	
end

cap program drop __esf_option
program define __esf_option, sclass
syntax varlist [, bins(numlist integer max=1 >=1) Format(str) tesf all CLeargraphs NOObs Color(str) tw(str asis) PREFix(str) SUFfix(str)] 
	unab allvars: *
	if(strlen(`"`tw'"')){	
		qui gr dir
		local previous=r(list)			
		cap tw function x, `tw' nodraw	
		if(_rc){
			di as err "{p 0 2}A problem was encountered in the tw() option in esf();{p_end}"
			m: stata("di as err "+char(34)+"{p 0 2}twoway, "+`"`tw'"'+" returns the following error:{p_end}"+char(34))
			tw function x, `tw' nodraw
		}
		else{
			qui gr dir
			local current=r(list)
			local new : list  current - previous
			if(strlen("`new'")){
				gr drop `new'
			}
		}
	}
	if("`allvars'"=="`varlist'"){
		local varlist=""
	}
	sreturn local esf_varlist="`varlist'"
	sreturn local esf_bins="`bins'"
	sreturn local esf_format="`format'"
	sreturn local esf_cleargraphs="`cleargraphs'"
	sreturn local esf_noobs="`noobs'"
	m: esf_colour=tokens("`color'")'
	sreturn local esf_tw=`"`tw'"'
	
	if(strlen("`prefix'")){
		local prefix="_"+strtoname("`prefix'")
		while(strpos("`prefix'","_")==1){
			local prefix=substr("`prefix'",2,strlen("`prefix'"))
		}
	}
	if(strlen("`suffix'")){
		local suffix="_"+strtoname("`suffix'")
		while(strpos("`suffix'","_")==1){
			local suffix=substr("`suffix'",2,strlen("`suffix'"))
		}	
	}
	m: esf_prefix_suffix=("`prefix'","`suffix'")'
	
	local esf_mode=2
	if(strlen("`tesf'")){
		local esf_mode=3
	}
	if(strlen("`all'")){
		local esf_mode=4
	}
	sreturn local esf_mode=`esf_mode'
	
end

cap program drop __inf_option
program define __inf_option, sclass
syntax varlist [, Test se GRoups tw(str asis)] 
	unab allvars: *
	if(strlen(`"`tw'"')){
		qui gr dir
		local previous=r(list)			
		cap tw function x, `tw' nodraw	
		if(_rc){
			di as err "{p 0 2}A problem was encountered in the tw() option in inf();{p_end}"
			m: stata("di as err "+char(34)+"{p 0 2}twoway, "+`"`tw'"'+" returns the following error:{p_end}"+char(34))
			tw function x, `tw' nodraw
		}
		else{
			qui gr dir
			local current=r(list)
			local new : list  current - previous
			if(strlen("`new'")){
				gr drop `new'
			}
		}
	}
	if("`allvars'"=="`varlist'"){
		local varlist=""
	}
	
	if((strlen("`test'")==0) & (strlen("`se'")>0)){
		sreturn local inf_note= "Note: uirt_inf option -se- is applicable only together with option -test-; -se- will be ignored"
		local se="" 
	}
	else{
		sreturn local inf_note=""
	}
	
	sreturn local inf_varlist = "`varlist'"
	sreturn local inf_mode = (strlen("`test'")>0) + (strlen("`se'")>0)
	sreturn local inf_ifgr = (strlen("`groups'")>0)
	sreturn local inf_tw = `"`tw'"'
		
end


cap program drop __group_option
program define __group_option, sclass
syntax varname [, REFerence(numlist max=1) dif(varlist) free slow CLeargraphs dif_format(str) dif_colors(str) dif_tw(str asis) ]
	m: st_local("gr_isnumvar",verify_isnumvar("`varlist'"))
	if(strlen("`gr_isnumvar'")){
		di as err "{p 0 2}grouping variable must be numeric, `gr_isnumvar' is not{p_end}"
		exit 109
	}

	unab allvars: *
	if("`allvars'"=="`dif'"){
		local dif="."
	}
	sreturn local group_var="`varlist'"
	sreturn local group_reference="`reference'"
	sreturn local group_free="`free'"
	sreturn local group_slow="`slow'"
	sreturn local group_dif="`dif'"
	sreturn local group_dif_cleargraphs="`cleargraphs'"
	sreturn local group_dif_format="`dif_format'"
	m: dif_colours=tokens("`dif_colors'")
	sreturn local group_dif_tw=`"`dif_tw'"'
	
	if(strlen("`reference'`free'`slow'")){
		if(strlen("`reference'")){
			sreturn local group_cmdstrip="gr(`varlist', ref(`reference') `free' `slow')"
		}
		else{
			sreturn local group_cmdstrip="gr(`varlist', `free' `slow')"
		}
	}
	else{
		sreturn local group_cmdstrip="gr(`varlist')"
	}
end

cap program drop __chi2w_option
program define __chi2w_option, sclass
syntax varlist [, bins(numlist integer max=1 >=1) NPQmin(numlist max=1 >0) NPQReport] 
	unab allvars: *
	if("`allvars'"=="`varlist'"){
		local varlist=""
	}
	sreturn local chi2w_varlist="`varlist'"
	sreturn local chi2w_bins="`bins'"
	sreturn local chi2w_npqmin="`npqmin'"
	sreturn local chi2w_npqreport="`npqreport'"
end

cap program drop __sx2_option
program define __sx2_option, sclass
syntax varlist [, MINFreq(numlist max=1 >0)] 
	unab allvars: *
	if("`allvars'"=="`varlist'"){
		local varlist=""
	}
	sreturn local sx2_varlist="`varlist'"
	sreturn local sx2_minfreq="`minfreq'"
end

cap program drop __fix_option
program define __fix_option, sclass
syntax [anything] [, prev from(namelist max=1) USEDist Imatrix(namelist max=1) Dmatrix(namelist max=1) Cmatrix(namelist max=1) miss ] 
	if(strlen("`prev'") & strlen("`from'")){
		di as err "{p 0 2}you should use either fix(prev) or fix(from(str)) option, not both{p_end}"
		exit 198
	}
	if( (strlen("`prev'") | strlen("`from'")) & strlen("`dmatrix'") & strlen("`usedist'") ){
		di as err "{p 0 2}you should use either usedist or dmatrix() option, not both{p_end}"
		exit 198
	}
	if(strlen("`prev'") | strlen("`from'")){
		if(strlen("`prev'")){
			if("`e(cmd)'" != "uirt"){
				error 301
			}
			else{
				sreturn local fix_imatrix="e(item_par)"
				sreturn local fix_cmatrix="e(item_cats)"
				sreturn local fix_V_greenlight="1"
				if(strlen("`usedist'")){
					sreturn local fix_dmatrix="e(group_par)"
				}
				else{
					sreturn local fix_dmatrix="`dmatrix'"
				}
			}
		}
		else{
			qui estimates restore `from'
			sreturn local fix_imatrix="e(item_par)"
			sreturn local fix_cmatrix="e(item_cats)"
			sreturn local fix_V_greenlight="1"
			if(strlen("`usedist'")){
				sreturn local fix_dmatrix="e(group_par)"
			}
			else{
				sreturn local fix_dmatrix="`dmatrix'"
			}
		}
		if( strlen("`imatrix'") | strlen("`cmatrix'") | strlen("`miss'") ){
			sreturn local fix_note= "Note: if you use fix(prev) or fix(from(str)) these options are ignored: i(),cat() miss"
		}
	}
	else{
		sreturn local fix_imatrix="`imatrix'"
		sreturn local fix_dmatrix="`dmatrix'"
		sreturn local fix_cmatrix="`cmatrix'"
		sreturn local fix_miss="`miss'"
		sreturn local fix_note=""
		sreturn local fix_V_greenlight="0"
	}
	sreturn local fix_prev="`prev'`from'"
end

cap program drop __init_option
program define __init_option, sclass
syntax [anything] [, prev from(namelist max=1) USEDist Imatrix(namelist max=1) Dmatrix(namelist max=1) miss] 
	if(strlen("`prev'") & strlen("`from'")){
		di as err "{p 0 2}you should use either init(prev) or init(from(str)) option, not both{p_end}"
		exit 198
	}
	if( (strlen("`prev'") | strlen("`from'") ) & strlen("`dmatrix'") & strlen("`usedist'") ){
		di as err "{p 0 2}you should use either usedist or dmatrix() option, not both{p_end}"
		exit 198
	}
	if(strlen("`prev'") | strlen("`from'")){
		if(strlen("`prev'")){
			if("`e(cmd)'" != "uirt"){
				error 301
			}
			else{
				sreturn local init_imatrix="e(item_par)"
				if(strlen("`usedist'")){
					sreturn local init_dmatrix="e(group_par)"
				}
				else{
					sreturn local init_dmatrix="`dmatrix'"
				}
			}
		}
		else{
			qui estimates restore `from'
			sreturn local init_imatrix="e(item_par)"
			if(strlen("`usedist'")){
				sreturn local init_dmatrix="e(group_par)"
			}
			else{
				sreturn local init_dmatrix="`dmatrix'"
			}
		}
		if( strlen("`imatrix'") | strlen("`miss'") ){
			sreturn local init_note= "Note: if you use init(prev) or init(from(str)) these options are ignored: i(), miss"
		}
	}
	else{
		sreturn local init_imatrix="`imatrix'"
		sreturn local init_dmatrix="`dmatrix'"
		sreturn local init_miss="`miss'"
		sreturn local init_note=""
	}
	sreturn local init_prev="`prev'`from'"
end

cap program drop __theta_option
program define __theta_option, sclass
syntax [namelist] [, eap nip(numlist integer max=1 >=2 <=195) pv(numlist integer max=1 >=0) pvreg(str) SUFfix(namelist max=1) SCale(numlist max=2 min=2) SKIPNote] 
		
		m: eap_names=tokens("`namelist'")
		m: st_local("names_ncol",strofreal(cols(eap_names)))
		if( (`names_ncol' !=0) & ((`names_ncol' !=2)) ){
			di as err "{p 0 2}Either 0 or exactly 2 new variable names are required,{p_end}"
			di as err "{p 0 2}uirt found `names_ncol' names: `namelist'{p_end}"
			di as err "{p 0 2}Maybe missing comma before options?{p_end}"
			exit 198
		}
		if(`names_ncol' == 0){
			sreturn local theta_eap="`eap'"
			if(strlen("`eap'")){
				if(strlen("`suffix'")){
					m: eap_names=("theta_","se_theta_"):+"`suffix'"
				}
				else{
					m: eap_names=("theta","se_theta")
				}
			}
		}
		if(`names_ncol' == 2){
			sreturn local theta_eap="eap"
		}
				
		sreturn local theta_nip="`nip'"
		sreturn local theta_pv="`pv'"
		sreturn local theta_pvreg="`pvreg'"
		sreturn local theta_suffix="`suffix'"
		sreturn local theta_skipnote="`skipnote'"
		m: theta_scale=strtoreal(tokens("`scale'"))		
end


mata:
// CLASSES

	class ITEMS{
		public:
			real scalar names, m_curr ,m_asked ,fix, init, pars ,n_cat , n_par, n_par_model, n_fix, n_init, cns, n_cns, p_cat, g_tot, init_fail, warning_cats, fit_sx2, viable_sx2, delta, a_prior, b_prior, c_prior, se, chi2W_res, SX2_res, par_labs
			real scalar n_prop
			real scalar n
			pointer vector ITEMS_DATA
			transmorphic matrix get()
			void put()
			void new()
			void populate()
	}
	
	void ITEMS::new(){
		names=1
		m_curr=2
		m_asked=3
		fix=4
		init=5
		pars=6
		n_cat=7
		n_par=8
		n_par_model=9
		n_fix=10
		n_init=11
		cns=12
		n_cns=13
		p_cat=14
		g_tot=15
		init_fail=16
		warning_cats=17
		fit_sx2=18
		viable_sx2=19
		delta=20
		a_prior=21
		b_prior=22
		c_prior=23
		se=24
		chi2W_res=25
		SX2_res=26
		par_labs=27
	
		n_prop=27
	}
	
	void ITEMS::populate(string colvector namevec){
		if(n==.){
			n=rows(namevec)
					
			ITEMS_DATA=J(n,1,NULL)
			for(i=1;i<=n;i++){
				ITEMS_DATA[i]=&J(n_prop,1,NULL)
			}
			
			put(names,.,namevec)
			put(m_curr,.,J(n,1,""))
			put(m_asked,.,J(n,1,""))
			put(fix,.,J(n,1,.))
			put(init,.,J(n,1,.))
			put(pars,.,J(n,1,.))
			put(cns,.,J(n,1,.))
			put(n_cat,.,J(n,1,.))
			
			put(n_par_model,.,J(n,1,.))
			
			put(init_fail,.,J(n,1,0))
			put(warning_cats,.,J(n,1,0))
			put(fit_sx2,.,J(n,1,0))
			put(viable_sx2,.,J(n,1,0))
			
			put(delta,.,J(n,1,.))
			put(a_prior,.,J(n,1,.))
			put(b_prior,.,J(n,1,.))
			put(c_prior,.,J(n,1,.))
			put(se,.,J(n,1,.))
			
			put(chi2W_res,.,J(n,1,.))
			put(SX2_res,.,J(n,1,.))
			
			put(par_labs,.,J(n,1,""))
			
			put(p_cat,.,J(n,1,NULL))
			put(g_tot,.,J(n,1,.))
		}
		else{
			select=J(0,1,.)
			for(i=1;i<=rows(namevec);i++){
				row=select((1::n),get(names,.):==namevec[i])
				if(rows(row)==1){
					select=select\row
				}
			}
			
			n=rows(select)
			
			if(n){
				ITEMS_DATA=ITEMS_DATA[select,.]
			}
			else{
				ITEMS_DATA=J(n,1,NULL)
			}
		}
			
	}
	
	function ITEMS::get(real scalar what, real matrix where ){
		if(where==.){
			where=(1::rows(ITEMS_DATA))
		}
		if( sum(what:==(pars,fix,init,cns,delta,a_prior,b_prior,c_prior,se,chi2W_res,SX2_res,par_labs)) ){
			if(what==par_labs){
				empty=""
			}
			else{
				empty=.
			}
			toreturn	=	*(*ITEMS_DATA[where[1]])[what]
			max_col		=	cols(toreturn)
			for(i=2;i<=rows(where);i++){
				toreturn_row=*(*ITEMS_DATA[where[i]])[what]
				row_delta	= cols(toreturn_row) - max_col
				if(row_delta>0){
					toreturn	=	toreturn,J(rows(toreturn),row_delta,empty)
					max_col		=	cols(toreturn_row)
				}
				if(row_delta<0){
					toreturn_row=toreturn_row,J(1,-row_delta,empty)
				}
				toreturn	=	toreturn\toreturn_row
			}
		}
		else{
			toreturn=*(*ITEMS_DATA[where[1]])[what]
			for(i=2;i<=rows(where);i++){
				toreturn=toreturn\*(*ITEMS_DATA[where[i]])[what]
			}
		}
		return(toreturn)
	}
	
	void ITEMS::put(real scalar what, real matrix where, transmorphic matrix contents ){
		if(where==.){
			where=(1::rows(ITEMS_DATA))
		}
		for(i=1;i<=rows(where);i++){
			if( sum(what:==(pars,fix,init,cns,delta,a_prior,b_prior,c_prior,se,chi2W_res,SX2_res,par_labs)) ){
				if(cols(contents[i,.])){
					if(what==par_labs){
						empty=""
					}
					else{
						empty=.
					}
					max_col=max(select(1::cols(contents),contents[i,.]':!=empty))
					temp=(*ITEMS_DATA[where[i]])[n_par_model]
					if(temp!=NULL){
					    temp=*temp
    					if( sum(what:==(a_prior,b_prior,c_prior,chi2W_res,SX2_res,par_labs))==0 & temp!=. ){
							max_col=min((temp,cols(contents[i,.])))
						}
					}
					(*ITEMS_DATA[where[i]])[what]= return_pointer(contents[i,1..max_col])
				}
			}
			else{
				(*ITEMS_DATA[where[i]])[what]= return_pointer(contents[i,.])
			}
			if(what==fix){
				(*ITEMS_DATA[where[i]])[n_fix]= return_pointer(nonmissing(contents[i,.]))
			}
			if(what==init){
				(*ITEMS_DATA[where[i]])[n_init]= return_pointer(nonmissing(contents[i,.]))
			}
			if(what==pars){
				(*ITEMS_DATA[where[i]])[n_par]= return_pointer(nonmissing(contents[i,.]))
			}
			if(what==cns){
				(*ITEMS_DATA[where[i]])[n_cns]= return_pointer(sum(contents[i,.]))
			}
		}
	}
	
		
	class GROUPS{
		public:
			real scalar val, label, n_uniq, n_total, pars, cns, n_cns, X_k, A_k, delta, se
			real scalar n_prop
			real scalar n
			string scalar v_name
			real colvector data
			pointer vector GROUPS_DATA
			transmorphic matrix get()
			void put()
			void new()
			void populate()
	}
	
	void GROUPS::new(){
		val=1
		label=2
		n_uniq=3
		n_total=4
		pars=5
		cns=6
		n_cns=7
		X_k=8
		A_k=9
		delta=10
		se=11
	
		n_prop=11
	}
	
	void GROUPS::populate(real colvector values){
		if(n==.){
			n=rows(values)
					
			GROUPS_DATA=J(n,1,NULL)
			for(i=1;i<=n;i++){
				GROUPS_DATA[i]=&J(n_prop,1,NULL)
			}
			
			put(val,.,values)			
			put(label,.,J(n,1,""))
			put(n_uniq,.,J(n,1,.))
			put(n_total,.,J(n,1,.))
			
			put(pars,.,J(n,1,.))
			put(cns,.,J(n,1,.))
			
			put(delta,.,J(n,1,.))
			put(se,.,J(n,1,.))
		}
		else{
			select=J(0,1,.)
			for(i=1;i<=rows(values);i++){
				row=select((1::n),get(val,.):==values[i])
				if(rows(row)==1){
					select=select\row
				}
			}
			
			n=rows(select)
			
			if(n){
				GROUPS_DATA=GROUPS_DATA[select,.]
			}
			else{
				GROUPS_DATA=J(n,1,NULL)
			}
		}
	}
	
	function GROUPS::get(real scalar what, real matrix where ){
		if(where==.){
			where=(1::rows(GROUPS_DATA))
		}
		toreturn=*(*GROUPS_DATA[where[1]])[what]
		for(i=2;i<=rows(where);i++){
			toreturn=toreturn\*(*GROUPS_DATA[where[i]])[what]
		}
		return(toreturn)
	}
	
	void GROUPS::put(real scalar what, real matrix where, transmorphic matrix contents ){
		if(where==.){
			where=(1::rows(GROUPS_DATA))
		}
		for(i=1;i<=rows(where);i++){
			(*GROUPS_DATA[where[i]])[what]= return_pointer(contents[i,.])
			if(what==cns){
				(*GROUPS_DATA[where[i]])[n_cns]= return_pointer(sum(contents[i,.]))
			}
		}
	}

// THE UIRT
	void uirt(string scalar touse, string scalar items, string scalar group, real scalar ref, real scalar estimate_dist, real scalar upd_quad_betw_em, string scalar errors, real matrix stored_V, string matrix pcmlist,string matrix gpcmlist, string matrix guesslist, real scalar guessing_attempts, real scalar guessing_lrcrit, string matrix diflist, real scalar add_theta, string matrix eap_names, string scalar theta_suffix, real scalar theta_nip, real matrix theta_scale, string scalar theta_notes, string scalar savingname , string scalar fiximatrix, string scalar initimatrix, string scalar catimatrix, string scalar initdmatrix, string scalar fixdmatrix, real scalar icc_cleargraphs, real scalar icc_obs, string matrix icclist, string matrix fitlist, real matrix chi2w_control, string matrix sx2_fitlist, real scalar sx2_min_freq, real scalar trace, real scalar nip,real scalar nit,real scalar nnirf,real scalar pv,string scalar pvreg, real scalar crit_ll, real scalar crit_par, real scalar icc_bins, real scalar icc_pvbin,string scalar icc_format, string scalar icc_tw, string matrix icc_colours, string matrix icc_prefix_suffix, string scalar dif_format, string scalar dif_tw, string matrix dif_colours, real scalar dif_cleargraphs, real matrix a_normal_prior, real matrix b_normal_prior, real matrix c_beta_prior, string matrix priorslist, string matrix esflist, real scalar esf_bins, string scalar esf_format, string scalar esf_tw, string matrix esf_colour, string matrix esf_prefix_suffix, real scalar esf_cleargraphs, real scalar esf_obs, real scalar esf_mode, string matrix inflist, real scalar inf_mode, string scalar inf_tw, inf_ifgr ,real scalar check_a){
	
		N_iter		=nit
		N_iter_NRF	=nnirf
		
		class ITEMS scalar Q
		Q	= ITEMS()
		
		Q.populate(tokens(items)')
		
		starting_values_fixORinit(Q,fiximatrix,initimatrix,errors!="stored")
		
		class GROUPS scalar G
		G	= GROUPS()
		
		iflogist_del=1 
		while(iflogist_del==1){
			
			G	= return_group_item_info(Q,catimatrix,touse,group,ref)
		
			cats_and_models(Q,guesslist,pcmlist,gpcmlist)
			
			if(rows(priorslist)){
				add_priors(selectQ(Q,priorslist), a_normal_prior, b_normal_prior, c_beta_prior, check_a)
			}
				
			data_pointers	= return_data_pointers(Q,G)
			point_Uigc		= *data_pointers[1]
			point_Fg		= *data_pointers[2]
			Theta_id		= *data_pointers[3]
			Theta_dup		= *data_pointers[4]
			data_pointers	= J(0,0,NULL)		
	
			if( sum(Q.get(Q.n_par,.):!=Q.get(Q.n_par_model,.))>0 | sum(Q.get(Q.init_fail,.)) ){
			
				if( sum(Q.get(Q.n_par,.):!=Q.get(Q.n_par_model,.))>0){
					starting_values_logistic(Q, G, Theta_id, Theta_dup, point_Uigc, "" ,check_a)
				}
				
				if( sum(Q.get(Q.init_fail,.)) ){
					
					dropped_items_range		= select((1::Q.n), Q.get(Q.init_fail,.):>0 )
					dropped_items		= Q.get(Q.names,dropped_items_range)
					dropped_item_whyfail= Q.get(Q.init_fail,dropped_items_range)
		
					display("Note: "+strofreal(rows(dropped_items))+" items are dropped from analysis:")
					for(i=1;i<=rows(dropped_items);i++){
						if(dropped_item_whyfail[i]==1){
							display("      failed generating starting values (convergence): "+dropped_items[i])
						}
						if(dropped_item_whyfail[i]==2){
							display("      failed generating starting values (a<0)        : "+dropped_items[i])
						}
						if(dropped_item_whyfail[i]==3){
							display("      item has all values missing                    : "+dropped_items[i])	
						}
						if(dropped_item_whyfail[i]==4){
							display("      item has zero variance                         : "+dropped_items[i])
						}
					}
					
					kept_items_range	= select((1::Q.n), Q.get(Q.init_fail,.):==0 )
					kept_items			= Q.get(Q.names,kept_items_range)
					
					Q.populate(kept_items)
					
				}
				else{
					iflogist_del=0
				}
			}
			else{
				iflogist_del=0
			}
		
		}
		
		if(sum(Q.get(Q.warning_cats,.))){
			warn_items=""
			for(i=1;i<=Q.n;i++){
				if(Q.get(Q.warning_cats,i)){
					warn_items=warn_items+" "+Q.get(Q.names,i)
				}
			}
			display("Note: when you fix item parameters and do not provide a matrix with item categories uirt will assume item categories to be consecutive integers")
			display("      (0..max_cat, where max_cat is inferred from item model and item parameters);")
			display("      this was applied to "+strofreal(sum(Q.get(Q.warning_cats,.)))+" items: "+warn_items)
		}
		
		if(strlen(fixdmatrix)){
			group_pars(Q, G, nip, fixdmatrix, -1)
		}
		else{
			group_pars(Q, G, nip, initdmatrix, estimate_dist)
		}	
		
		
		//checking if sx2 can be computed
		if(rows(sx2_fitlist)){
			check_sx2(Q, G, sx2_fitlist)
		}
		
		
		
// THE EM
			em_results				= em(Q, G, estimate_dist, N_iter, trace, errors, crit_ll, guessing_attempts, guessing_lrcrit, eap_names, theta_nip, theta_scale, theta_notes, Theta_id, Theta_dup, savingname, point_Uigc, point_Fg  , upd_quad_betw_em, N_iter_NRF, crit_par, check_a)
			logL					= *em_results[1]
			long_EMhistory_matrix	= *em_results[2]
			if_em_converged			= *em_results[3]

			if(sum(Q.get(Q.init_fail,.))){
				kept_items_range	= select((1::Q.n), Q.get(Q.init_fail,.):==0 )
				kept_items			= Q.get(Q.names,kept_items_range)
				Q.populate(kept_items)
			}
			
			
// ERRORS 
		if(errors!="."){
			if(errors=="sem" | errors=="rem" |  errors=="cdm" ){		
				perturbation = crit_par*10		
				errors_DM_results		= errors_DM(Q, G, errors, perturbation, long_EMhistory_matrix, point_Uigc, point_Fg, N_iter_NRF, crit_par)
				V						= *errors_DM_results[1]
				eret_Cns				= *errors_DM_results[2]
			}
			if(errors=="cp"){
				errors_CP_results		=	errors_CP(Q, G, point_Uigc, point_Fg)
				V						= *errors_CP_results[1]
				eret_Cns				= *errors_CP_results[2]
			}
			// this option is not documented, used to speed up postestimation
			if(errors=="stored"){
				V						= stored_V
				se=sqrt(rowsum(diag(V)))
				Q.put(Q.se,.,uncreate_long_vector(Q, G, se,0))
				G.put(G.se,.,uncreate_long_vector(Q, G, se,1))
				
				Q.put(Q.cns,.,  ((Q.get(Q.se,.):==0) :* ((Q.get(Q.se,.):*0):+1)) )
				G.put(G.cns,.,  (G.get(G.se,.):==0) )
				eret_Cns=create_long_Cns_matrix(Q,G)
				
				Q.put(Q.fix,.,  Q.get(Q.pars,.):/Q.get(Q.cns,.) )
				
			}
		}
		else{
			Q.put(Q.se,.,Q.get(Q.pars,.):*0)
			G.put(G.se,.,G.get(G.pars,.):*0)
		}
		
		// creates matrices to post in ereturn
		store_matrices(Q, G, logL, "")
		
		
// ADDING PVs
		if(pv>0){
			// giving small burn, because we have a proposition distribution fixed at the unconditioned a posteriori
			burn					= 40
			draw_from_chain			= 10
			max_independent_chains	=	100
			if(group!="."){
				if(pvreg!="."){
					pvreg= "i."+group+" "+pvreg
				}
			}
			
			PV 				= generate_pv(Q, G, pv, draw_from_chain, max_independent_chains, burn, Theta_dup, point_Uigc, point_Fg, pvreg, Theta_id, 1, V)

			if(theta_suffix!="."){
				index_temp=st_addvar("double",J(1,pv,"pv_")+strofreal((1..pv))+J(1,pv,"_"+theta_suffix))
				if(pv>1){
					mess = "Added variables: pv_1_"+theta_suffix+" - pv_"+strofreal(pv)+"_"+theta_suffix
				}
				else{
					mess = "Added variable: pv_1_"+theta_suffix
				}
			}
			else{
				index_temp=st_addvar("double",J(1,pv,"pv_")+strofreal((1..pv)))
				if(pv>1){
					mess = "Added variables: pv_1 - pv_"+strofreal(pv)
				}
				else{
					mess = "Added variable: pv_1"
				}		
			}
			
			if(cols(theta_scale)==2){
				m_ref=G.get(G.pars,1)[1]
				sd_ref=G.get(G.pars,1)[2]
				st_store(Theta_id,index_temp, ( (PV :* (theta_scale[2]/sd_ref)) :+ (theta_scale[1]-m_ref*theta_scale[2]/sd_ref)) )
			}
			else{
				st_store(Theta_id,index_temp,PV)
			}
			
			if(strlen(theta_notes)){
				for(i=1;i<=pv;i++){
					if(theta_suffix!="."){
						pvvar="pv_"+strofreal(i)+"_"+theta_suffix
					}
					else{
						pvvar="pv_"+strofreal(i)
					}
					stata("note "+pvvar+":Plausible value number "+strofreal(i)+" after fitting: "+theta_notes+" (time:`c(current_date)' `c(current_time)')")
				}
			}
			
			display(mess)
			PV = J(0,0,.)
		}

// GRAPHS

// ICC
		if(rows(icclist)){
		
			if_makeicc=J(Q.n,1,0)
			for(i=1;i<=rows(icclist);i++){
				if_makeicc=if_makeicc+(Q.get(Q.names,.):==icclist[i])
			}
			
			if(icc_obs){
				if(icc_pvbin){
					Pj_centile = Pj_centile_pv(Q, G , if_makeicc, Theta_dup, point_Uigc, point_Fg ,  icc_pvbin, icc_bins,V)
				}
				else{
					Pj_centile = Pj_centile_integrated(Q, G , point_Uigc, icc_bins)
				}
			}
			else{
				Pj_centile=J(0,0,.)
			}
	
			icc_graph(cloneQ(Q), cloneG(G), Pj_centile,if_makeicc,icc_format, icc_tw, icc_colours, icc_prefix_suffix, point_Uigc,point_Fg, eap_names, 0, icc_cleargraphs)
			
		}
// ESF		
		if(rows(esflist)){
		
			if_makeesf=J(Q.n,1,0)
			for(i=1;i<=rows(esflist);i++){
				if_makeesf=if_makeesf+(Q.get(Q.names,.):==esflist[i])
			}
			
			if(esf_obs){
				Pj_centile = Pj_centile_integrated(Q, G , point_Uigc, esf_bins)
			}
			else{
				Pj_centile=J(0,0,.)
			}
				
			icc_graph(cloneQ(Q), cloneG(G), Pj_centile,if_makeesf,esf_format, esf_tw, esf_colour, esf_prefix_suffix, point_Uigc,point_Fg, eap_names, esf_mode , esf_cleargraphs)
			
		}
// INF		
		if(rows(inflist)){
			if_makeinf=J(Q.n,1,0)
			for(i=1;i<=rows(inflist);i++){
				if_makeinf=if_makeinf+(Q.get(Q.names,.):==inflist[i])
			}		
			inf_graph(Q, G, if_makeinf, inf_tw, inf_mode, eap_names, inf_ifgr )
		}
				
// FIT		
		if(rows(fitlist)){

			fit_N_intervals=chi2w_control[1]
			fit_npq_crit=chi2w_control[2]
			report_min_npq=chi2w_control[3]
			
			fit_indx=J(0,1,.)
			for(i=1;i<=Q.n;i++){
				if( sum(fitlist:==Q.get(Q.names,i)) ){
					
					chi2W_item_results	=	chi2W_item(Q, cloneG(G) ,i , fit_N_intervals , fit_npq_crit,  point_Uigc, point_Fg)
					
					n_est_par			= Q.get(Q.n_par,i):-Q.get(Q.n_fix,i)
					
					Q.put(Q.chi2W_res, i, (*chi2W_item_results[1],*chi2W_item_results[2],*chi2W_item_results[3], n_est_par ,min(*chi2W_item_results[8])) )
					
					fit_indx=fit_indx\i
				}
			}
			
			if(report_min_npq){
				st_matrix("item_fit_chi2W",Q.get(Q.chi2W_res,fit_indx))
				st_matrixcolstripe("item_fit_chi2W", (J(5,1,""),("chi2W","p-val","df","n_par","min_npq")'))
				st_matrixrowstripe("item_fit_chi2W", (J(rows(fit_indx),1,""),Q.get(Q.names,fit_indx)))
			}
			else{
				st_matrix("item_fit_chi2W",Q.get(Q.chi2W_res,fit_indx)[.,1..4])
				st_matrixcolstripe("item_fit_chi2W", (J(4,1,""),("chi2W","p-val","df","n_par")'))
				st_matrixrowstripe("item_fit_chi2W", (J(rows(fit_indx),1,""),Q.get(Q.names,fit_indx)))
			}
		}
		
		if(sum(Q.get(Q.fit_sx2,.))){
					
			SX2(Q, cloneG(G),  sx2_min_freq,  point_Uigc, point_Fg)
			
			fit_indx=select((1::Q.n),Q.get(Q.fit_sx2,.))
			
			st_matrix("item_fit_SX2",Q.get(Q.SX2_res,fit_indx))
			st_matrixcolstripe("item_fit_SX2", (J(4,1,""),("SX2","p-val","df","n_par")'))
			st_matrixrowstripe("item_fit_SX2", (J(rows(fit_indx),1,""),Q.get(Q.names,fit_indx)))
			
		}
		
// DIF
		if(rows(diflist)>0){	
			
			if(errors=="stored"){
				N_iter=100
			}
		
			dif_results = dif(Q, G, diflist, logL, dif_format, dif_tw, dif_colours , N_iter, crit_ll, theta_nip, Theta_id, Theta_dup, point_Uigc, point_Fg, upd_quad_betw_em, N_iter_NRF, crit_par, eap_names, dif_cleargraphs,check_a)
		
			st_matrix("dif_results",dif_results)
			st_matrixcolstripe("dif_results", (J(8,1,""),("LR","p-value","P-DIF|GR","P-DIF|GF","E(parR,GR)","E(parF,GR)","E(parR,GF)","E(parF,GF)")'))
			st_matrixrowstripe("dif_results", (J(rows(diflist),1,""),diflist))
			
		}
		
		
		
// ereturn posting 

	stata("ereturn clear")
	
//MATRICES
	eret_b			= create_long_vector(Q, G, "pars")'
	eret_b_colnames	= J(2,cols(eret_b),"")
	range_start=1
	for(g=1;g<=G.n;g++){
			range_stop=range_start+2-1
			eret_b_colnames[1,range_start..range_stop]=J(1,2,"group_"+strofreal(G.get(G.val,g)))
			eret_b_colnames[2,range_start..range_stop]=("mean_theta","sd_theta")
			range_start=range_stop+1
	}
	for(i=1;i<=Q.n;i++){
		inpar=Q.get(Q.n_par,i)
		range_stop=range_start+inpar-1
		eret_b_colnames[1,range_start..range_stop]=J(1,inpar,Q.get(Q.names,i))
		model_i=Q.get(Q.m_curr,i)
		if(model_i=="1plm"){
			eret_b_colnames[2,range_start..range_stop]=model_i:+("_b")
		}		
		if(model_i=="2plm"){
			eret_b_colnames[2,range_start..range_stop]=model_i:+("_a","_b")
		}
		if(model_i=="3plm"){
			eret_b_colnames[2,range_start..range_stop]=model_i:+("_a","_b","_c")
		}
		if(model_i=="pcm"){
			eret_b_colnames[2,range_start..range_stop]=model_i:+("_a",("_b":+strofreal(1..inpar-1)))
		}
		if(model_i=="gpcm"){
			eret_b_colnames[2,range_start..range_stop]=model_i:+("_a",("_b":+strofreal(1..inpar-1)))
		}		
		if(model_i=="grm"){
			eret_b_colnames[2,range_start..range_stop]=model_i:+("_a",("_b":+strofreal(1..inpar-1)))
		}
		range_start=range_stop+1
	}

// parameter matrix
	st_matrix("b",eret_b)
	st_matrixcolstripe("b",eret_b_colnames')
	st_matrixrowstripe("b", ("","y1"))

//covariance matrix		
	st_matrix("V",V)
	st_matrixcolstripe("V", eret_b_colnames')
	st_matrixrowstripe("V", eret_b_colnames')
// constraints matrix
	st_matrix("Cns",eret_Cns)
	st_matrixcolstripe("Cns",(eret_b_colnames'\("_Cns","_r")))

	
// eret post
	stata("ereturn post b V Cns, esample("+touse+") obs("+strofreal(sum(G.get(G.n_total,.)))+")")

// additional matrices
	if(rows(diflist)>0){	
		stata("ereturn matrix dif_results dif_results")
		stata("ereturn matrix dif_item_par_GR itemsDIF_GR")
		stata("ereturn matrix dif_item_par_GF itemsDIF_GF")
	}
	if(rows(fitlist)>0){	
		stata("ereturn matrix item_fit_chi2W item_fit_chi2W")
	}

	if(sum(Q.get(Q.fit_sx2,.))>0){	
		stata("ereturn matrix item_fit_SX2 item_fit_SX2")
	}
	
	stata("ereturn matrix item_cats item_cats")
	stata("ereturn matrix item_group_N item_group_N")
	stata("ereturn matrix group_N group_N")
	stata("ereturn matrix group_ll ll")
	stata("ereturn matrix group_par_se dist_se")
	stata("ereturn matrix group_par dist")
	stata("ereturn matrix item_par_se items_se")
	stata("ereturn matrix item_par items")			
		
//MACROS
	stata("ereturn local cmd "+char(34)+"uirt"+char(34))
	stata("ereturn local title "+char(34)+"Unidimensional item response theory model"+char(34))
	eret_depvar=""
	for(i=1;i<=Q.n;i++){
		eret_depvar=eret_depvar+" "+Q.get(Q.names,i)
	}	
	stata("ereturn local depvar "+char(34)+eret_depvar+char(34))
	
// SCALARS	
	stata("ereturn scalar ll="+strofreal(sum(logL),"%15.4f"))
	df_m = G.n*2 +sum(Q.get(Q.n_par,.)) - sum(Q.get(Q.n_fix,.)) - sum(G.get(G.cns,.))
	stata("ereturn scalar df_m="+strofreal(df_m) )
	stata("ereturn scalar N_items="+strofreal(Q.n))
	stata("ereturn scalar N_gr="+strofreal(G.n))
	stata("ereturn scalar converged="+strofreal(if_em_converged))
	

	}
		

	
// FUNCTIONS BELOW
	pointer colvector errors_CP(_Q, _G, pointer matrix point_Uigc, pointer matrix point_Fg){
		
		class ITEMS scalar Q
		Q=_Q
		class GROUPS scalar G
		G=_G
	
		N_gr	= G.n
		I		= Q.n
		
		long_final_estimates=create_long_vector(Q,G,"pars")
		N_par= rows(long_final_estimates)
		Cns_matrix=create_long_Cns_matrix(Q,G)
		
		long_obsdata_Score_crosspr	= J(N_par,N_par,0)

		class ITEMS scalar Qg
		class GROUPS scalar Gg
		for(g=1;g<=N_gr;g++){
		
			N_par_g			=	2
			range_start		=	(g-1)*2+1
			range_stop		=	range_start+2-1
			par_range_g		=	(range_start::range_stop)				
			range_start		= N_gr*2+1
			
			for(i=1;i<=I;i++){
				range_stop=range_start+Q.get(Q.n_par,i)-1
				if(Q.get(Q.g_tot,i)[g]:>0){
					par_range_g	=	par_range_g\(range_start::range_stop)
					N_par_g=N_par_g+(range_stop-range_start+1)
				}
				range_start=range_stop+1
			}
			
			Fg = *point_Fg[g]
			
			itemselectrange_g=select((1::I),Q.get(Q.g_tot,.)[.,g]:>0)
			
			Qg=cloneQ(selectQ(Q,Q.get(Q.names,itemselectrange_g)))
			Gg=cloneG(selectG(G,g))
			
			DIST_g=Gg.get(Gg.pars,.)
			Cns_DIST_g=Gg.get(Gg.cns,.)
			
			quad_GH_g	= get_quad_GH(195,DIST_g)
			Gg.put(Gg.X_k,.,*quad_GH_g[1])
			Gg.put(Gg.A_k,.,*quad_GH_g[2])
			
			PXk_Uj = eE_step(Qg, Gg, point_Uigc[.,g])
			PXk_Uj = PXk_Uj :/ rowsum(PXk_Uj)
			theta =  rowsum(PXk_Uj :* Gg.get(Gg.X_k,.))

			crossme_g	= J(rows(theta),N_par_g,0)
			
			range_start		=	1
			range_stop		=	range_start+2-1
			X1				=	(1-Cns_DIST_g[1]):*(theta:-DIST_g[1]):/DIST_g[2]^2
			X2				=	(1-Cns_DIST_g[2]):*( (theta:-DIST_g[1]):*(theta:-DIST_g[1]):-DIST_g[2]^2 ):/DIST_g[2]^3
			crossme_g[.,range_start..range_stop] 	= X1,X2
			
			I_g=Qg.n
			range_start			= range_stop+1
			for(i=1;i<=I_g;i++){
			
				range_stop=range_start+Qg.get(Qg.n_par,i)-1
				
				if(Qg.get(Qg.n_cns,i)<Qg.get(Qg.n_par,i)){
				
					//2plm
					if(Qg.get(Qg.m_curr,i)=="2plm"){
					
						pars_i=Qg.get(Qg.pars,i)
						cns_i=Qg.get(Qg.cns,i)
						model_i=("2plm","2")

						a = pars_i[1]
						b = pars_i[2]
						
						X_b =(theta :-b)			
						Pij = f_Pitem_theta_01(pars_i,model_i,theta)
						
						X1=J(rows(theta),1,0)
						X2=J(rows(theta),1,0)								
						for(c=1;c<=2;c++){
							ord_c			=		*(*point_Uigc[i,g])[c]
							if(cns_i[1]==0){
								X1[ord_c]		=		( ( (c-1) :- Pij[ord_c] ) :* X_b[ord_c] ) 
							}
							if(cns_i[2]==0){
								X2[ord_c]		=		( ( (c-1) :- Pij[ord_c] ) :* (-a) )
							}
						}
						
						crossme_g[.,range_start..range_stop] 	= X1,X2	
					}
					
					//3plm
					if(Qg.get(Qg.m_curr,i)=="3plm"){
					
						pars_i=Qg.get(Qg.pars,i)
						cns_i=Qg.get(Qg.cns,i)
						model_i=("3plm","2")
	
						a = pars_i[1]
						b = pars_i[2]
						ccc = pars_i[3]
						
						X_b =(theta :- b)
						Pij = f_Pitem_theta_01(pars_i,model_i, theta)
						V = (Pij:-ccc) :/ (Pij :* (1-ccc))
						
						X1=J(rows(theta),1,0)
						X2=J(rows(theta),1,0)
						X3=J(rows(theta),1,0)								
						for(c=1;c<=2;c++){
							ord_c			=		*(*point_Uigc[i,g])[c]
							if(cns_i[1]==0){
								X1[ord_c]		=		( ( (c-1) :- Pij[ord_c] ) :* X_b[ord_c]  :* V[ord_c] )
							}
							if(cns_i[2]==0){
								X2[ord_c]		=		( ( (c-1) :- Pij[ord_c] ) :* (-a) :* V[ord_c] )
							}
							if(cns_i[3]==0){
								X3[ord_c]		=		( ( (c-1) :- Pij[ord_c] ) :* (1/(1-ccc))) :/ Pij[ord_c]
							}
						}	
						
						crossme_g[.,range_start..range_stop] 	= X1,X2,X3				
					}
					
					//grm
					if(Qg.get(Qg.m_curr,i)=="grm"){
					
						n_cat=Qg.get(Qg.n_cat,i)
						pars_i=Qg.get(Qg.pars,i)
						cns_i=Qg.get(Qg.cns,i)
						model_i=("grm",strofreal(Qg.get(Qg.n_cat,i)))
					
						Pij_0c						=	f_Pitem_theta_0c(pars_i,model_i,theta)
					
						Pij_0c_star					=	J(rows(theta),n_cat+1,.)
						Pij_0c_star[.,1]			=	J(rows(theta),1,1)
						Pij_0c_star[.,n_cat+1]		=	J(rows(theta),1,0)
						
						grm_parameters = J(n_cat-1,1,pars_i[1]) , pars_i[2..n_cat]'
						dummy_2plm_model=("2plm","2")
						for(c=2;c<=n_cat;c++){
							Pij_0c_star[.,c]		=	f_Pitem_theta_01(grm_parameters[c-1,.],dummy_2plm_model,theta)
						}

						P_starxQ_star				=	Pij_0c_star :* (1 :- Pij_0c_star)
						
						X_b_star					=	J(rows(theta),n_cat+1,.)
						X_b_star[.,1]					=	J(rows(theta),1,0)
						X_b_star[.,n_cat+1]			=	J(rows(theta),1,0)
						for(c=2;c<=n_cat;c++){
							X_b_star[.,c]			=	theta :- grm_parameters[c-1,2]
						}								
						
						X_b_starxP_starxQ_star		=	X_b_star :* P_starxQ_star
						
						a							=	pars_i[1]								
						
						Score_ij	= J(rows(theta),n_cat,0)
						for(c=1;c<=n_cat;c++){
							ord_c								=	*(*point_Uigc[i,g])[c]
							if(c<n_cat){
								Score_ij[ord_c,1+c] 			=	(a) :* ( P_starxQ_star[ord_c,c+1] :* ( 1 :/Pij_0c[ord_c,c]) )
							}
							if(c>1){
								Score_ij[ord_c,1+c-1] 			=	(-a) :* ( P_starxQ_star[ord_c,c] :* ( 1 :/Pij_0c[ord_c,c]) )
							}
							Score_ij[ord_c,1]					=	( 1 :/ Pij_0c[ord_c,c] ) :* (X_b_starxP_starxQ_star[ord_c,c] :- X_b_starxP_starxQ_star[ord_c,c+1])
						}
						for(c=1;c<=n_cat;c++){
							if(cns_i[c]){
								Score_ij[.,c]=J(rows(theta),1,0)
							}
						}
						
						crossme_g[.,range_start..range_stop] 	= Score_ij		
					}
					
					//gpcm|pcm
					if(Qg.get(Qg.m_curr,i)=="gpcm" | Qg.get(Qg.m_curr,i)=="pcm" ){
					
						n_cat=Qg.get(Qg.n_cat,i)
						pars_i=Qg.get(Qg.pars,i)
						cns_i=Qg.get(Qg.cns,i)
						model_i=("gpcm",strofreal(Qg.get(Qg.n_cat,i)))
					
						Pij_0c	=	f_Pitem_theta_0c(pars_i,model_i,theta)
						
						a=pars_i[1]	
						b_1tomax=pars_i[2..n_cat]
						
						Zc_1toc=J(rows(theta),n_cat-1,.)
						for(c=1;c<=n_cat-1;c++){
							Zc_1toc[.,c] = a :* ( c :* theta :- sum(b_1tomax[1..c]) )
						}
						Sum_Pc_ctomax=J(rows(theta),n_cat-1,0)
						for(c=1;c<=n_cat-1;c++){
							for(cc=c+1;cc<=n_cat;cc++){
								Sum_Pc_ctomax[.,c]=Sum_Pc_ctomax[.,c] :+ Pij_0c[.,cc]
							}
						}	
						Sum_PcZc_1tomax=J(rows(theta),1,0)
						for(c=1;c<=n_cat-1;c++){
							Sum_PcZc_1tomax=Sum_PcZc_1tomax :+ ( Pij_0c[.,c+1] :* Zc_1toc[.,c])
						}				
						
						Score_ij	= J(rows(theta),n_cat,0)
						for(c=1;c<=n_cat-1;c++){
							for(cat=1;cat<=c;cat++){
								ord_cat				=	*(*point_Uigc[i,g])[cat]							
								Score_ij[ord_cat,c+1] =	Score_ij[ord_cat,c+1] :+ Sum_Pc_ctomax[ord_cat,c]
							}
							for(cat=c+1;cat<=n_cat;cat++){
								ord_cat				=	*(*point_Uigc[i,g])[cat]							
								Score_ij[ord_cat,c+1] =	Score_ij[ord_cat,c+1] :- ( 1 :- Sum_Pc_ctomax[ord_cat,c] )
							}
							Score_ij[.,c+1]			= 	a :* Score_ij[.,c+1]
						}
						if(Qg.get(Qg.m_curr,i)=="gpcm"){
							ord_1						=	*(*point_Uigc[i,g])[1]
							Score_ij[ord_1,1]			= 	Score_ij[ord_1,1] :- Sum_PcZc_1tomax[ord_1]
							for(cat=2;cat<=n_cat;cat++){
								ord_cat					=	*(*point_Uigc[i,g])[cat]
								Score_ij[ord_cat,1]		= 	Score_ij[ord_cat,1] :+ (Zc_1toc[ord_cat,cat-1] :- Sum_PcZc_1tomax[ord_cat])
							}
							Score_ij[.,1]				= 	(1/a) :* Score_ij[.,1]
						}
						for(c=1;c<=n_cat;c++){
							if(cns_i[c]){
								Score_ij[.,c]=J(rows(theta),1,0)
							}
						}
		
						crossme_g[.,range_start..range_stop] 	= Score_ij
					
					}
				
				}
				
				range_start=range_stop+1
			}

			for(j=1;j<=rows(Fg);j++){				
				long_obsdata_Score_crosspr[par_range_g,par_range_g']=long_obsdata_Score_crosspr[par_range_g,par_range_g'] :+ (cross(crossme_g[j,.],crossme_g[j,.]):*  Fg[j])
			}	
		}	
		
		V= invsym(long_obsdata_Score_crosspr)	
		
		// rescaling if pcm
		if(sum(Q.get(Q.m_curr,.):=="pcm")>0 & G.get(G.cns,1)[1]==1 & G.get(G.cns,1)[2]==0){
		
			sel_non3plm=select((1::Q.n) , (Q.get(Q.m_curr,.):!="3plm"))
			Q.put(Q.pars,sel_non3plm,( Q.get(Q.pars,sel_non3plm)[.,1]*G.get(G.pars,1)[2] , Q.get(Q.pars,sel_non3plm)[.,2..max(Q.get(Q.n_par,sel_non3plm))]/G.get(G.pars,1)[2] ) )
									
			sel_3plm=select((1::Q.n) , (Q.get(Q.m_curr,.):=="3plm"))
			if(rows(sel_3plm)){
				Q.put(Q.pars,sel_3plm,( Q.get(Q.pars,sel_3plm)[.,1]*G.get(G.pars,1)[2] , Q.get(Q.pars,sel_3plm)[.,2..max(Q.get(Q.n_par,sel_3plm))]/G.get(G.pars,1)[2] ) )
			}
			
			G.put(G.X_k,.,G.get(G.X_k,.)/G.get(G.pars,1)[2])
			G.put(G.pars,.,G.get(G.pars,.)/G.get(G.pars,1)[2])
				
			indexoffirstpcm=min(select((1::Q.n),Q.get(Q.m_curr,.):=="pcm"))
			indexoffirstpcm=G.n*2+sum(Q.get(Q.n_par,(1::indexoffirstpcm)))-Q.get(Q.n_par,indexoffirstpcm)+1

			Vtemp=V
			Vtemp[.,2]=V[.,indexoffirstpcm]
			Vtemp[.,indexoffirstpcm]=V[.,2]*G.get(G.pars,1)[2]
			V=Vtemp
			V[2,.]=Vtemp[indexoffirstpcm,.]
			V[indexoffirstpcm,.]=Vtemp[2,.]*G.get(G.pars,1)[2]
			Vtemp=J(0,0,.)
			V=V/G.get(G.pars,1)[2]^2
			
			G.put(G.cns,1,(1,1))
			Cns_matrix=create_long_Cns_matrix(Q,G)
			
		}
				
		se=sqrt(rowsum(diag(V)))
		Q.put(Q.se,.,uncreate_long_vector(Q, G, se,0))
		G.put(G.se,.,uncreate_long_vector(Q, G, se,1))
		
		results = J(2,1,NULL)
		results[1] = &V
		results[2] = &Cns_matrix

		return(results)
		
	}
	
	
	pointer colvector errors_DM(_Q, _G, string scalar errors, real scalar perturbation, real matrix long_EMhistory_matrix, pointer matrix point_Uigc, pointer matrix point_Fg, real scalar N_iter_NRF, real scalar crit_par){
		
		class ITEMS scalar Q
		Q=_Q
		class GROUPS scalar G
		G=_G
		
		N_gr	= G.n
		I		= Q.n
		
		long_final_estimates=create_long_vector(Q,G,"pars")
		N_par=rows(long_final_estimates)
		Cns_matrix=create_long_Cns_matrix(Q,G)
		
		// compute Fisher information
		long_completedata_Fisher=J(N_par,N_par,0)
		range_start=1
		for(g=1;g<=N_gr;g++){
			range_stop		= range_start+2-1
			total_obs_g		= G.get(G.n_total,g)
			variance_g		= G.get(G.pars,g)[2]^2
			long_completedata_Fisher[range_start::range_stop,range_start..range_stop] = ( (total_obs_g/variance_g)*(1-G.get(G.cns,g)[1]) , 0 \ 0 , 2*total_obs_g/variance_g*(1-G.get(G.cns,g)[2]) )
			range_start		= range_stop+1
		}
		
		e_step_results	= e_step(cloneQ(Q), cloneG(G),point_Uigc,point_Fg)
		p_ik			= *e_step_results[3]
		p_ck			= *e_step_results[4]
		f_ik			= *e_step_results[5]

		for(i=1;i<=I;i++){
			n_cat = Q.get(Q.n_cat,i)
			if(n_cat>2){
				row_p_ck = sum(select(Q.get(Q.n_cat,(1::i)),Q.get(Q.n_cat,(1::i)):>2))-n_cat+1		
				pi_ck=p_ck[(row_p_ck::row_p_ck+n_cat-1),.]				
				Fisher_i=m_step(selectQ(cloneQ(Q),Q.get(Q.names,i)),G.get(G.X_k,.)', f_ik[i,.], p_ik[i,.], pi_ck,1)
			}
			else{
				Fisher_i=m_step(selectQ(cloneQ(Q),Q.get(Q.names,i)),G.get(G.X_k,.)', f_ik[i,.], p_ik[i,.], p_ck,1)
			}
			range_stop=range_start+cols(Fisher_i)-1
			long_completedata_Fisher[range_start::range_stop,range_start..range_stop]=Fisher_i
			range_start=range_stop+1
		}
		
		class ITEMS scalar Qpar
		class GROUPS scalar Gpar
		
		// REM | CDM
		if(errors=="rem" |  errors=="cdm" ){
			if(errors=="rem"){
				max_rem_iter = 4
			}
			if(errors=="cdm"){
				max_rem_iter = 2
			}
			
			long_DM_marix=J(N_par,N_par,0)
			perturbation_rem_vector=(perturbation,-perturbation,2*perturbation,-2*perturbation)
			multiplyby_rem_vector=(8,-8,-1,1)
			
			stata("display "+char(34)+"Calculating errors ("+strupper(errors)+"): 0%"+char(34)+" _c")
			previous_progress=0
			
			for(rem_iter=1;rem_iter<=max_rem_iter;rem_iter++){
				for(par=1;par<=N_par;par++){
				
					current_progress	= 100 * ( N_par*(rem_iter-1) + par ) / (max_rem_iter*N_par)
					previous_progress	= progress(current_progress,previous_progress)
					
					if(sum(abs(Cns_matrix[.,par]))==0){
		
						long_final_estimates_par			= long_final_estimates
						long_final_estimates_par[par]		= long_final_estimates_par[par]+perturbation_rem_vector[rem_iter]
						
						Qpar=cloneQ(Q)
						Qpar.put(Qpar.pars,.,uncreate_long_vector(Q, G, long_final_estimates_par,0))

						Gpar=cloneG(G)
						Gpar.put(Gpar.pars,.,uncreate_long_vector(Q, G, long_final_estimates_par,1))
										
						X_k_upd_quad = G.get(G.X_k,.)
						for(g=1;g<=N_gr;g++){				
							if(g>1-sum(G.get(G.cns,1):==0)){
								X_k_upd_quad[g,.] 	=(((G.get(G.X_k,g) :- G.get(G.pars,g)[1])/G.get(G.pars,g)[2]):*Gpar.get(Gpar.pars,g)[2]):+Gpar.get(Gpar.pars,g)[1]
							}
						}
						Gpar.put(Gpar.X_k,.,X_k_upd_quad)
						
						em_step_results			= em_step(Qpar, Gpar, point_Uigc,point_Fg  , 0,N_iter_NRF,crit_par)
								
						long_final_estimates_par_plus1	=create_long_vector(Qpar,Gpar,"pars")
						long_DM_marix[par,.]				= long_DM_marix[par,.]:+(long_final_estimates_par_plus1':*multiplyby_rem_vector[rem_iter])
						
					}
				}
			}
			if(errors=="rem"){
				long_DM_marix		= long_DM_marix :/ (12*perturbation)
			}
			if(errors=="cdm"){
				long_DM_marix		= long_DM_marix :/ (16*perturbation)
			}
		}
		
		// SEM
		if(errors=="sem"){
		
			crit_sem			= crit_par^0.5
			long_starti_vector	= J(N_par,1,2)
			shift_stop			= min(long_starti_vector)+1
		
			long_DM_marix		= J(N_par,N_par,0)
			long_DM_marix_less1	= J(N_par,N_par,1)
			long_DM_marix_fix	= (J(N_par,1,colsum(abs(Cns_matrix[.,1..N_par]))) + J(N_par,1,colsum(abs(Cns_matrix[.,1..N_par])))') :!= 0
			DM_tocoverge        = sum(long_DM_marix_fix:==0)
			
			for(sem_iter=0;sem_iter<=cols(long_EMhistory_matrix)-shift_stop;sem_iter++){
			
				N_converged = sum(long_DM_marix_fix)
				if(N_converged!=N_par^2){
				stata("display "+char(34)+"Calculating errors ("+strupper(errors)+";it="+strofreal(sem_iter)+";conv="+strofreal(floor(100*(DM_tocoverge-sum(long_DM_marix_fix:==0))/DM_tocoverge))+"%): 0%"+char(34)+" _c")
				previous_progress=0
				}
				
				for(par=1;par<=N_par;par++){
				
					if(N_converged!=N_par^2){
						current_progress	= 100 * par / N_par
						previous_progress	= progress(current_progress,previous_progress)
					}
					
					if(sum(abs(Cns_matrix[.,par]))==0){
						if(sum(long_DM_marix_fix[par,.])<N_par ){		
		
							long_starti_vector[par]=long_starti_vector[par]+1
			
							long_final_estimates_par			= long_final_estimates
							long_final_estimates_par[par]		= long_EMhistory_matrix[par,long_starti_vector[par]]
							
							Qpar=cloneQ(Q)
							Qpar.put(Qpar.pars,.,uncreate_long_vector(Q, G, long_final_estimates_par,0))
		
							Gpar=cloneG(G)
							Gpar.put(Gpar.pars,.,uncreate_long_vector(Q, G, long_final_estimates_par,1))
							
							X_k_upd_quad = G.get(G.X_k,.)
							for(g=1;g<=N_gr;g++){				
								if(g>1-sum(G.get(G.cns,1):==0)){
									X_k_upd_quad[g,.] 	=(((G.get(G.X_k,g) :- G.get(G.pars,g)[1])/G.get(G.pars,g)[2]):*Gpar.get(Gpar.pars,g)[2]):+Gpar.get(Gpar.pars,g)[1]
								}
							}
							Gpar.put(Gpar.X_k,.,X_k_upd_quad)
							
							em_step_results			= em_step(Qpar, Gpar, point_Uigc,point_Fg  , 0,N_iter_NRF,crit_par)
							
							long_final_estimates_par_plus1	=create_long_vector(Qpar,Gpar,"pars")	
									
							for(j=1;j<=N_par;j++){
								if(long_DM_marix_fix[par,j]==0 & sum(abs(Cns_matrix[.,j]))==0  ){
									long_DM_marix[par,j]=(long_final_estimates_par_plus1[j]-long_final_estimates[j])/(long_final_estimates_par[par]-long_final_estimates[par])
								}
							}
						}
					}		
				}
				
				if(sem_iter==0){
					long_DM_marix_less1=long_DM_marix		
				}
				
				// checking for convergence of [par1,par2] element of long_DM_marix			
				if(sem_iter>=1){
					for(par1=1;par1<=N_par;par1++){
						for(par2=1;par2<=N_par;par2++){
							if(long_DM_marix_fix[par1,par2]==0){
								abs1	= abs(long_DM_marix_less1[par1,par2]-long_DM_marix[par1,par2])
								if(abs1<crit_sem){
									long_DM_marix_fix[par1,par2]=1
								}
							}						
						}
					}
					long_DM_marix_less1=long_DM_marix
				}
				
			}
			
			N_converged = sum(long_DM_marix_fix)
			if(N_converged!=N_par^2){
				display("Calculating errors: Warning; "+strofreal(N_par^2-N_converged)+" of "+strofreal(N_par^2)+"elements of DM matrix did not reach convergence; errors may be inadequate")
			}
			else{
				display("Calculating errors: SEM converged")
			}
		}

		V= invsym(long_completedata_Fisher) * luinv(I(N_par) - long_DM_marix)
		V=(makesymmetric(V):+makesymmetric(V')):/2
		
		// rescaling if pcm
		if(sum(Q.get(Q.m_curr,.):=="pcm")>0 & G.get(G.cns,1)[1]==1 & G.get(G.cns,1)[2]==0){
		
			sel_non3plm=select((1::Q.n) , (Q.get(Q.m_curr,.):!="3plm"))
			Q.put(Q.pars,sel_non3plm,( Q.get(Q.pars,sel_non3plm)[.,1]*G.get(G.pars,1)[2] , Q.get(Q.pars,sel_non3plm)[.,2..max(Q.get(Q.n_par,sel_non3plm))]/G.get(G.pars,1)[2] ) )
									
			sel_3plm=select((1::Q.n) , (Q.get(Q.m_curr,.):=="3plm"))
			if(rows(sel_3plm)){
				Q.put(Q.pars,sel_3plm,( Q.get(Q.pars,sel_3plm)[.,1]*G.get(G.pars,1)[2] , Q.get(Q.pars,sel_3plm)[.,2..max(Q.get(Q.n_par,sel_3plm))]/G.get(G.pars,1)[2] ) )
			}
			
			G.put(G.X_k,.,G.get(G.X_k,.)/G.get(G.pars,1)[2])
			G.put(G.pars,.,G.get(G.pars,.)/G.get(G.pars,1)[2])
				
			indexoffirstpcm=min(select((1::Q.n),Q.get(Q.m_curr,.):=="pcm"))
			indexoffirstpcm=G.n*2+sum(Q.get(Q.n_par,(1::indexoffirstpcm)))-Q.get(Q.n_par,indexoffirstpcm)+1

			Vtemp=V
			Vtemp[.,2]=V[.,indexoffirstpcm]
			Vtemp[.,indexoffirstpcm]=V[.,2]*G.get(G.pars,1)[2]
			V=Vtemp
			V[2,.]=Vtemp[indexoffirstpcm,.]
			V[indexoffirstpcm,.]=Vtemp[2,.]*G.get(G.pars,1)[2]
			Vtemp=J(0,0,.)
			V=V/G.get(G.pars,1)[2]^2
			
			G.put(G.cns,1,(1,1))
			Cns_matrix=create_long_Cns_matrix(Q,G)
			
		}
		
		se=sqrt(rowsum(diag(V)))
		Q.put(Q.se,.,uncreate_long_vector(Q, G, se,0))
		G.put(G.se,.,uncreate_long_vector(Q, G, se,1))
		
		results = J(2,1,NULL)
		results[1] = &V
		results[2] = &Cns_matrix
		return(results)
		
	}
	
	real matrix dif(_Q, _G ,string colvector diflist, real colvector logL , string scalar dif_format , string scalar dif_tw, string matrix dif_colours, real scalar N_iter, real scalar crit_ll, real scalar theta_nip, real colvector Theta_id, real colvector Theta_dup, pointer matrix point_Uigc, pointer matrix point_Fg, real scalar upd_quad_betw_em, real scalar N_iter_NRF, real scalar crit_par, string matrix eap_names, real scalar dif_cleargraphs, real scalar check_a){
		
		class ITEMS scalar Q
		Q=_Q
		class GROUPS scalar G
		G=_G
		
		item_n_cat = Q.get(Q.n_cat,.)
	
		dif_results=J(rows(diflist),8,.)
		
		LL0=sum(logL)
		
		I		= Q.n
		I_dif	= rows(diflist)

		class ITEMS scalar Q_DIF_GR
		Q_DIF_GR.populate(diflist)
		class ITEMS scalar Q_DIF_GF
		Q_DIF_GF.populate(diflist)
		
		class ITEMS scalar Qg
		class ITEMS scalar Qdif
		class GROUPS scalar Gdif
		for(i=1;i<=I_dif;i++){
			
			point_Uigc_dif=J(I,2,NULL)
			for(g=1;g<=2;g++){

				itemselectrange_g=select((1::I),Q.get(Q.g_tot,.)[.,g]:>0)
			
				Qg=cloneQ(selectQ(Q,Q.get(Q.names,itemselectrange_g)))
				I_g=Qg.n
				
				no_dif_range_g		= select((1::I_g),Qg.get(Qg.names,.):!=diflist[i])
				dif_range_g			= select((1::I_g),Qg.get(Qg.names,.):==diflist[i])
				
				point_Uigc_dif[1::I_g,g]	= point_Uigc[no_dif_range_g,g] \ point_Uigc[dif_range_g,g]
			}

			
			no_dif_range			= select((1::I),Q.get(Q.names,.):!=diflist[i])
			dif_range				= select((1::I),Q.get(Q.names,.):==diflist[i])		
			dif_reindex				= no_dif_range\dif_range\dif_range
			
			Qdif=cloneQ(selectQ(Q, Q.get(Q.names,dif_reindex) ))
			Qdif.put(Qdif.names, I+1, Q.get(Q.names,dif_range)+"_GF" )
			Qdif.put(Qdif.g_tot,I,(Qdif.get(Qdif.g_tot,I)[1],0))
			Qdif.put(Qdif.g_tot,I+1,(0,Qdif.get(Qdif.g_tot,I+1)[2]))
									
			Gdif=cloneG(G)

			em_results				= em(Qdif, Gdif, 0, N_iter, 0, ".", crit_ll, 0 , 1 ,"", theta_nip,J(0,0,.),"", Theta_id, Theta_dup, ".", point_Uigc_dif, point_Fg  , upd_quad_betw_em, N_iter_NRF, crit_par, check_a)
			
			Q_DIF_GR.put(Q_DIF_GR.pars,i, Qdif.get(Qdif.pars, I))
			Q_DIF_GR.put(Q_DIF_GR.m_curr,i, Qdif.get(Qdif.m_curr, I))
			Q_DIF_GR.put(Q_DIF_GR.par_labs,i, Qdif.get(Qdif.par_labs, I))
			Q_DIF_GF.put(Q_DIF_GF.pars,i, Qdif.get(Qdif.pars, I+1))
			Q_DIF_GF.put(Q_DIF_GF.m_curr,i, Qdif.get(Qdif.m_curr, I+1))
			Q_DIF_GF.put(Q_DIF_GF.par_labs,i, Qdif.get(Qdif.par_labs, I+1))

			
			parameters_resdif		= Qdif.get(Qdif.pars, (I::I+1))
			logL_resdif				= *em_results[1]
			X_k_resdif				= Gdif.get(Gdif.X_k,.)'
			A_k				= Gdif.get(Gdif.A_k,.)'
			model_resdif			= Qdif.get(Qdif.m_curr, (I::I+1)),strofreal(Qdif.get(Qdif.n_cat, (I::I+1)))

			LL1			= sum(logL_resdif)
			LR			= 2*(LL1-LL0)
			if(model_resdif[1,1]==model_resdif[2,1]){
			
				df0		=sum(Q.get(Q.n_par,.))-sum(Q.get(Q.n_fix,.))
				df1		=sum(Qdif.get(Qdif.n_par,.))-sum(Qdif.get(Qdif.n_fix,.)) 
				df		=df1-df0
				pvalue	= 1-chi2(df,LR)
				
				print_notnested=0
			}
			else{
				pvalue	= .
				print_notnested=1
			}
	
			n_cat	= item_n_cat[dif_range]
			
			if(n_cat == 2 & model_resdif[1,1]!="pcm"){
				mean1GR = sum(f_PiXk_01(parameters_resdif[1,.],model_resdif[1,.],X_k_resdif[.,1])*A_k[.,1])
				mean2GR = sum(f_PiXk_01(parameters_resdif[2,.],model_resdif[2,.],X_k_resdif[.,1])*A_k[.,1])
				mean1GF = sum(f_PiXk_01(parameters_resdif[1,.],model_resdif[1,.],X_k_resdif[.,2])*A_k[.,2])
				mean2GF = sum(f_PiXk_01(parameters_resdif[2,.],model_resdif[2,.],X_k_resdif[.,2])*A_k[.,2])
			}
			else{
				mean1GR = 0
				mean2GR = 0
				mean1GF = 0
				mean2GF = 0
				PiXk_11 = f_PiXk_0c(parameters_resdif[1,.],model_resdif[1,.],X_k_resdif[.,1])
				PiXk_21 = f_PiXk_0c(parameters_resdif[2,.],model_resdif[2,.],X_k_resdif[.,1])
				PiXk_12 = f_PiXk_0c(parameters_resdif[1,.],model_resdif[1,.],X_k_resdif[.,2])
				PiXk_22 = f_PiXk_0c(parameters_resdif[2,.],model_resdif[2,.],X_k_resdif[.,2])
				for(c=2;c<=n_cat;c++){
					mean1GR = mean1GR + (c-1)*sum(PiXk_11[c,.]*A_k[.,1])
					mean2GR = mean2GR + (c-1)*sum(PiXk_21[c,.]*A_k[.,1])
					mean1GF = mean1GF + (c-1)*sum(PiXk_12[c,.]*A_k[.,2])
					mean2GF = mean2GF + (c-1)*sum(PiXk_22[c,.]*A_k[.,2])		
				}
			}
			
			
			display("")
			display("_____________________________________________________________________")
			display("DIF analysis of item "+diflist[i]+" (GR: "+G.v_name+"="+strofreal(G.get(G.val,1))+" , GF: "+G.v_name+"="+strofreal(G.get(G.val,2))+")")
							
			display("")
			stata("display _col(10) %10s "+char(34)+"GR"+char(34)+" _col(20)  %10s "+char(34)+"GF"+char(34))	
			stata("display %10s "+char(34)+"a"+char(34)+" _col(10) %10.4f "+strofreal(parameters_resdif[1,1])+" _col(20) %10.4f "+strofreal(parameters_resdif[2,1]))
			if(strpos(model_resdif[1,1],"plm")){
				stata("display %10s "+char(34)+"b"+char(34)+" _col(10) %10.4f "+strofreal(parameters_resdif[1,2])+" _col(20) %10.4f "+strofreal(parameters_resdif[2,2]))
			}
			if(sum(model_resdif:=="3plm")){
				stata("display %10s "+char(34)+"c"+char(34)+" _col(10) %10.4f "+strofreal(parameters_resdif[1,3])+" _col(20) %10.4f "+strofreal(parameters_resdif[2,3]))
			}
			if(n_cat>2 | model_resdif[1,1]=="pcm"){
				for(c=1;c<=n_cat-1;c++){
					stata("display %10s "+char(34)+"b"+strofreal(c)+char(34)+" _col(10) %10.4f "+strofreal(parameters_resdif[1,1+c])+" _col(20) %10.4f "+strofreal(parameters_resdif[2,1+c]))
				}
			}		
			
			display("")
			stata("display %15s "+char(34)+"E(parR,GR)"+char(34)+" _col(15)  %15s "+char(34)+"E(parF,GR)"+char(34)+" _col(30)  %15s "+char(34)+"E(parR,GF)"+char(34)+" _col(45)  %15s "+char(34)+"E(parF,GF)"+char(34))
			stata("display %15.4f "+strofreal(mean1GR)+" _col(15) %15.4f "+strofreal(mean2GR)+" _col(30) %15.4f "+strofreal(mean1GF)+" _col(45) %15.4f "+strofreal(mean2GF))

			display("")			
			if(print_notnested){
				display("Note: DIF model is not nested, item has different IRF between groups, p-value not computed")
				display("")		
			}
			stata("display %10s "+char(34)+"LR"+char(34)+" _col(10)  %10s "+char(34)+"p-value"+char(34)+" _col(20)  %10s "+char(34)+"P-DIF|GR"+char(34)+" _col(30)  %10s "+char(34)+"P-DIF|GF"+char(34))
			stata("display %10.4f "+strofreal(LR)+" _col(10) %10.4f "+strofreal(pvalue)+" _col(20) %10.4f "+strofreal(mean2GR-mean1GR)+" _col(30) %10.4f "+strofreal(mean1GF-mean2GF))
			
				
			dif_results[i,.]=(LR,pvalue,mean2GR-mean1GR, mean1GF-mean2GF, mean1GR,mean2GR,mean1GF,mean2GF)
			
			Qdif=cloneQ( selectQ( Qdif, Qdif.get(Qdif.names,(I::I+1)) ) )
			
			icc_graph(Qdif, cloneG(Gdif), J(0,0,.),(1\1),dif_format, dif_tw, dif_colours,("","")', point_Uigc,point_Fg, eap_names, 1, dif_cleargraphs)			
		
		}
		
		store_matrices(Q_DIF_GR, G, J(0,0,.), "DIF_GR")
		store_matrices(Q_DIF_GF, G, J(0,0,.), "DIF_GF")
		
		return(dif_results)
	}



	function create_long_vector(_Q, _G, string scalar what){
		class ITEMS scalar Q
		Q=_Q
		class GROUPS scalar G
		G=_G
		
		long_vector=J(2*G.n + sum(Q.get(Q.n_par,.)),1,. )
		range_start=1
		for(g=1;g<=G.n;g++){
			range_stop=range_start+2-1
			if(what=="pars"){
				long_vector[range_start::range_stop]=G.get(G.pars,g)'
			}
			if(what=="cns"){
				long_vector[range_start::range_stop]=G.get(G.cns,g)'
			}
			range_start=range_stop+1
		}
		for(i=1;i<=Q.n;i++){
			range_stop=range_start+Q.get(Q.n_par,i)-1
			if(what=="pars"){
				long_vector[range_start::range_stop]=Q.get(Q.pars,i)'
			}
			if(what=="cns"){
				long_vector[range_start::range_stop]=Q.get(Q.cns,i)'
			}
			range_start=range_stop+1
		}
		return(long_vector)
	}


		
	function  create_long_Cns_matrix(_Q, _G){
		
		class ITEMS scalar Q
		Q=_Q
		class GROUPS scalar G
		G=_G
	
		Cns_long_vector=create_long_vector(Q,G,"cns")
		long_final_estimates=create_long_vector(Q,G,"pars")
		N_par=rows(long_final_estimates)
		
		N_gr=G.n
		I=Q.n
		
		Cns_matrix_C=J(0,N_par,.)
		Cns_matrix_R=J(0,1,.)
		range_start=1
		for(g=1;g<=N_gr;g++){
			range_stop=range_start+2-1
			for(par=range_start;par<=range_stop;par++){
				if(Cns_long_vector[par]){
					Cns_matrix_C_par=J(1,N_par,0)
					Cns_matrix_C_par[par]=1
					Cns_matrix_C=Cns_matrix_C\Cns_matrix_C_par
					Cns_matrix_R=Cns_matrix_R\long_final_estimates[par]
				}
			}
			range_start=range_stop+1
		}
		indexoffirstpcm=0
		for(i=1;i<=I;i++){
			Cns_parameters_extract=Q.get(Q.cns,i)
			range_stop=range_start+cols(Cns_parameters_extract)-1
			if(Q.get(Q.m_curr,i)=="pcm"){
				if(indexoffirstpcm==0){
					indexoffirstpcm=range_start
				}
				else{
					Cns_matrix_C_par=J(1,N_par,0)
					Cns_matrix_C_par[indexoffirstpcm]=1
					Cns_matrix_C_par[range_start]=-1
					Cns_matrix_C=Cns_matrix_C\Cns_matrix_C_par
					Cns_matrix_R=Cns_matrix_R\0					
				}
				for(par=range_start+1;par<=range_stop;par++){
					if(Cns_long_vector[par]){
						Cns_matrix_C_par=J(1,N_par,0)
						Cns_matrix_C_par[par]=1
						Cns_matrix_C=Cns_matrix_C\Cns_matrix_C_par
						Cns_matrix_R=Cns_matrix_R\long_final_estimates[par]
					}
				}
			}
			else{
				for(par=range_start;par<=range_stop;par++){
					if(Cns_long_vector[par]){
						Cns_matrix_C_par=J(1,N_par,0)
						Cns_matrix_C_par[par]=1
						Cns_matrix_C=Cns_matrix_C\Cns_matrix_C_par
						Cns_matrix_R=Cns_matrix_R\long_final_estimates[par]
					}
				}
			}
			range_start=range_stop+1
		}
		
		long_Cns_matrix=Cns_matrix_C,Cns_matrix_R
		return(long_Cns_matrix)
	}

	function uncreate_long_vector(_Q, _G, real matrix long_vector, real scalar ifdist){
		class ITEMS scalar Q
		Q=_Q
		class GROUPS scalar G
		G=_G
		
		toreturn=G.get(G.pars,.)
		N_gr=G.n
		range_start=1
		for(g=1;g<=N_gr;g++){
			range_stop=range_start+2-1
			toreturn[g,.]=long_vector[range_start::range_stop]'
			range_start=range_stop+1
		}
		if(ifdist==0){
			toreturn=Q.get(Q.pars,.)
			for(i=1;i<=rows(toreturn);i++){
				for(c=1;c<=cols(toreturn);c++){
					if(toreturn[i,c]!=.){
						toreturn[i,c]=long_vector[range_start]
						range_start=range_start+1
					}
				}
			}
		}
		return(toreturn)
	}

	
	
	
// draws icc line for a single item parameter matrix. If last argument is if_esf==1, it will return the item response function without formatting 
	string scalar icc_graph_function(_Qi, string matrix colours_vector, real scalar if_esf){
	
		class ITEMS scalar Qi
		Qi=_Qi	
	
		n_cat=Qi.get(Qi.n_cat,.)
		model=Qi.get(Qi.m_curr,.)
		pars=Qi.get(Qi.pars,.)
		cats=*Qi.get(Qi.p_cat,.)
		
		stata_command=""
		
		if(n_cat==2){
		
			if(if_esf==0){
			
				if (model=="2plm" | model=="pcm"){
					stata_command=stata_command+"(function invlogit("+strofreal(pars[1])+"*(x-"+strofreal(pars[2])+")), range(-4 4) clcolor("+colours_vector[2]+"))"
				}
				if (model=="3plm" ){
					stata_command=stata_command+"(function "+strofreal(pars[3])+" +(1-"+strofreal(pars[3])+")*invlogit("+strofreal(pars[1])+"*(x-"+strofreal(pars[2])+")), range(-4 4) clcolor("+colours_vector[2]+")) || (function "+strofreal(pars[3])+", range(-4 4) clcolor("+colours_vector[1]+") clpattern(dash))"
				}
				
			}
			else{

				if (model=="2plm" | model=="pcm"){
					stata_command=stata_command + "( invlogit(" + strofreal(pars[1]) + "*(x-" + strofreal(pars[2]) + ")) )"
				}
				if (model=="3plm" ){
					stata_command=stata_command + "( " + strofreal(pars[3]) + " + (1-" + strofreal(pars[3]) + ")*invlogit(" + strofreal(pars[1]) + "*(x-" + strofreal(pars[2]) + ")) )"
				}
			
				stata_command = stata_command + "*" + strofreal(cats[2]) + " + (1 - " + stata_command + ")*" + strofreal(cats[1])
				
			}
		}
		
		if(n_cat>2){
		
			if(if_esf==0){
				if ( model=="grm"){
					stata_command=stata_command+"(function 1-invlogit("+strofreal(pars[1])+"*(x-"+strofreal(pars[2])+")), range(-4 4) clcolor("+colours_vector[1]+")) || "
					for(c=2;c<=n_cat-1;c++){
						stata_command=stata_command+"(function (invlogit("+strofreal(pars[1])+"*(x-"+strofreal(pars[c])+"))-invlogit("+strofreal(pars[1])+"*(x-"+strofreal(pars[c+1])+"))), range(-4 4) clcolor("+colours_vector[c]+")) || "
					}
					stata_command=stata_command+"(function invlogit("+strofreal(pars[1])+"*(x-"+strofreal(pars[c])+")), range(-4 4) clcolor("+colours_vector[c]+")) || "
				}
				if (model!="grm"){
					expsum_all_function="(1+"
					for(c=2;c<=n_cat;c++){
						expsum_all_function=expsum_all_function+"exp("+strofreal(pars[1])+"*("+strofreal(c-1)+"*x-("+strofreal(sum(pars[2..c]))+")))+"
					}
					expsum_all_function=expsum_all_function+")"
					expsum_all_function=subinstr(expsum_all_function,"+)",")")
					stata_command=stata_command+"(function 1/"+expsum_all_function+", range(-4 4) clcolor(red)) || "
					for(c=2;c<=n_cat;c++){
						expsum_cat_function="exp("+strofreal(pars[1])+"*("+strofreal(c-1)+"*x-("+strofreal(sum(pars[2..c]))+")))"				
						stata_command=stata_command+"(function "+expsum_cat_function+"/"+expsum_all_function+", range(-4 4) clcolor("+colours_vector[c+1]+")) || "
					}
				}
			
			}
			else{
			
				if ( model=="grm"){
					stata_command=stata_command+"( 1-invlogit("+strofreal(pars[1])+"*(x-"+strofreal(pars[2])+")) )*" + strofreal(cats[1])
					for(c=2;c<=n_cat-1;c++){
						stata_command=stata_command+" + ( (invlogit("+strofreal(pars[1])+"*(x-"+strofreal(pars[c])+"))-invlogit("+strofreal(pars[1])+"*(x-"+strofreal(pars[c+1])+"))) )*" + strofreal(cats[c])
					}
					stata_command=stata_command+" + ( invlogit("+strofreal(pars[1])+"*(x-"+strofreal(pars[c])+")) )*" + strofreal(cats[c])
				}
				if (model!="grm"){
				
					expsum_all_function="(1+"
					for(c=2;c<=n_cat;c++){
						expsum_all_function=expsum_all_function+"exp("+strofreal(pars[1])+"*("+strofreal(c-1)+"*x-("+strofreal(sum(pars[2..c]))+")))+"
					}
					expsum_all_function=expsum_all_function+")"
					expsum_all_function=subinstr(expsum_all_function,"+)",")")
					
					
					stata_command=stata_command+"(  1/"+expsum_all_function+")*" + strofreal(cats[1])
					for(c=2;c<=n_cat;c++){
						expsum_cat_function="exp("+strofreal(pars[1])+"*("+strofreal(c-1)+"*x-("+strofreal(sum(pars[2..c]))+")))"				
						stata_command=stata_command+" + ("+expsum_cat_function+"/"+expsum_all_function+")*" + strofreal(cats[c])
					}
				}
			
			
			}
			
		}
			
		return(stata_command)
	}

	
	
	pointer colvector icc_graph_emppoints(_Qi, real matrix Pj_centile, pointer matrix point_Uixx, pointer matrix point_Fg, string matrix colours_vector, real scalar if_esf){

		class ITEMS scalar Qi
		Qi=_Qi	
	
		// discard ploting frequency in a quantile of less than min_icc_pvbin is observed
		min_icc_pvbin=10
		
		icc_intervals=cols(Pj_centile)
		
		N_gr=rows(point_Fg)
		
		stata_command=""
		
		X_k_icc = invnormal( ((1::icc_intervals):-0.5):/icc_intervals )

		n_cat=Qi.get(Qi.n_cat,.)
		if(n_cat == 2 & if_esf==0){
			P_item=J(icc_intervals,1,0)
		}
		else{
			P_item=J(icc_intervals,n_cat,0)
		}
						
		weight_g=sum(Qi.get(Qi.g_tot,.))
		
		min_icc_pvbin_matrix=J(1,icc_intervals,0)
		group_range_stop=0		
		for(g=1;g<=N_gr;g++){
		
			Fg	= *point_Fg[g]
			
			group_range_start=group_range_stop+1
			group_range_stop=group_range_stop+rows(Fg)
			
			if(Qi.get(Qi.g_tot,.)[g]){
				
				nonmiss_U_ig_vector=J(0,1,.)
				for(c=1;c<=n_cat;c++){
					nonmiss_U_ig_vector=nonmiss_U_ig_vector\(*(*point_Uixx[g])[c])
				}
				min_icc_pvbin_matrix	=	min_icc_pvbin_matrix :+ colsum( (*point_Fg[g])[nonmiss_U_ig_vector] :* (Pj_centile[nonmiss_U_ig_vector,.]:>0) )
	
				weight_ig = Qi.get(Qi.g_tot,.)[g]/weight_g

				Pj_centile_g = Pj_centile[group_range_start::group_range_stop,.]
				
				denominator=colsum( Fg[nonmiss_U_ig_vector] :* Pj_centile_g[nonmiss_U_ig_vector,.] )
				
				if(n_cat==2 & if_esf==0){
					P_item_ig_weight= ( colsum( Fg[*(*point_Uixx[g])[2]] :* Pj_centile_g[*(*point_Uixx[g])[2],.] ) :/ denominator  )'
					P_item[(1::icc_intervals)]=rowsum( (P_item[(1::icc_intervals)] , P_item_ig_weight * weight_ig) )
				}
				else{			
					for(c=1;c<=n_cat;c++){
						P_item_ig_weight= ( colsum( Fg[*(*point_Uixx[g])[c]] :* Pj_centile_g[*(*point_Uixx[g])[c],.] ) :/ denominator )'
						P_item[(1::icc_intervals),c]=rowsum( (P_item[(1::icc_intervals),c] , P_item_ig_weight * weight_ig) )
					}
				}
			}
		}
		
		min_icc_pvbin_matrix=(min_icc_pvbin_matrix' :< min_icc_pvbin)
		if(sum(min_icc_pvbin_matrix)){
			miss_index=select((1::icc_intervals),min_icc_pvbin_matrix)
			P_item[miss_index,.]=J(rows(miss_index),cols(P_item),.)
		}

		tempvarlist=""
		ThetaMode_var=st_tempname()
		tempvarlist=tempvarlist+" "+ThetaMode_var
		index_temp=st_addvar("double",ThetaMode_var)
		nobs=st_nobs()
		if(icc_intervals>nobs){
			st_addobs(icc_intervals-nobs)
			dropaddedobs="qui drop in "+strofreal(nobs+1)+"/"+strofreal(icc_intervals)
		}
		else{
			dropaddedobs=""
		}
		st_store((1::icc_intervals),ThetaMode_var,X_k_icc)
		
		if(if_esf==0){
			P_sum=J(0,0,.)
			if(n_cat==2){
				ItemMean_var=st_tempname()
				tempvarlist=tempvarlist+" "+ItemMean_var
				index_temp=st_addvar("double",ItemMean_var)
				st_store((1::icc_intervals),ItemMean_var,P_item[(1::icc_intervals)])
				stata_command=stata_command+"(scatter  "+ItemMean_var+" "+ThetaMode_var+", mcolor("+substr(colours_vector[2],1,strlen(colours_vector[2])-1)+"*0.5"+char(34)+") msize(vsmall)) || "	
			}
			else{
				for(c=1;c<=n_cat;c++){
					ItemMean_var=st_tempname()
					tempvarlist=tempvarlist+" "+ItemMean_var
					index_temp=st_addvar("double",ItemMean_var)
					st_store((1::icc_intervals),ItemMean_var,P_item[(1::icc_intervals),c])
					stata_command=stata_command+"(scatter  "+ItemMean_var+" "+ThetaMode_var+", mcolor("+substr(colours_vector[c],1,strlen(colours_vector[c])-1)+"*0.5"+char(34)+") msize(vsmall)) || "
				}
			}
		}
		else{
			cats=*Qi.get(Qi.p_cat,.)
			P_sum=J(icc_intervals,1,0)
			for(c=1;c<=rows(cats);c++){
				P_sum = P_sum :+ ( cats[c] :* P_item[(1::icc_intervals),c])
			}
			
			ItemMean_var=st_tempname()
			tempvarlist=tempvarlist+" "+ItemMean_var
			index_temp=st_addvar("double",ItemMean_var)
			st_store((1::icc_intervals),ItemMean_var,P_sum)
			stata_command=stata_command+"(scatter  "+ItemMean_var+" "+ThetaMode_var+", mcolor("+substr(colours_vector[1],1,strlen(colours_vector[1])-1)+"*0.5"+char(34)+") msize(vsmall)) || "

		}
		
		
		results = J(4,1,NULL)
		results[1] = &stata_command
		results[2] = &tempvarlist
		results[3] = &dropaddedobs
		results[4] = &P_sum
		return(results)
	}

	// icc_mode==0 -> ICC; icc_mode==1 -> DIF; icc_mode==2 -> item ESF ; icc_mode==3 -> test ESF ; icc_mode==4 -> test and item ESF
	void icc_graph(_Qx, _Gx, real matrix Pj_centile, real matrix if_makeicc, string scalar icc_format,string scalar icc_twoway, string matrix icc_colours, string matrix icc_prefix_suffix,  pointer matrix point_Uigc, pointer matrix point_Fg, string matrix eap_names, real scalar icc_mode, real scalar cleargraphs){
		
		class ITEMS scalar Qx
		Qx=_Qx
		class GROUPS scalar Gx
		Gx=_Gx
	
		if(sum(if_makeicc)){
		
			I=Qx.n
			N_gr=Gx.n

			if(cols(eap_names)==2){
				thetan=eap_names[1]
			}
			else{
				thetan="theta"
			}
	
			if(rows(Pj_centile)>0){
				icc_obs=1
			}
			else{
				icc_obs=0
			}
			
			// DIF graph
			if(I==2 & icc_mode==1){
			
				itemname=Qx.get(Qx.names,1)
				filename=icc_prefix_suffix[1]+(strlen(icc_prefix_suffix[1])==0)*"DIF"+"_"+itemname+(strlen(icc_prefix_suffix[2])>0)*"_"+icc_prefix_suffix[2]
				
				stata_command="qui twoway "

				n_cat = Qx.get(Qx.n_cat,1)
				if(cols(icc_colours)<2){
					colours_vector=J(n_cat,1,("red","blue"))
				}
				else{
					icc_colours=char(34):+ subinstr(icc_colours,char(34),"") :+char(34)
					colours_vector=J(n_cat,1,icc_colours[.,1..2])
				}
				shift_legend=(0\0)
				if(n_cat == 2){
					shift_legend=shift_legend:+(Qx.get(Qx.m_curr,1::2):=="3plm")
					title_cat=strofreal((*Qx.get(Qx.p_cat,1))[2])
				}
				else{
					shift_legend=shift_legend:+(n_cat-1)
					title_cat="cat"
				}
				for(g=1;g<=N_gr;g++){
					stata_command=stata_command+icc_graph_function(selectQ(Qx,Qx.get(Qx.names,g)), colours_vector[.,g],0)
					stata_command=stata_command+ " (function normalden(x,"+strofreal(Gx.get(Gx.pars,g)[1])+","+strofreal(Gx.get(Gx.pars,g)[2])+"), range(-4 4) lcolor("+colours_vector[1,g]+"*0.5) lpattern(dash)) "
				}
				stata_command=stata_command+",  legend(cols(2) order(1 "+char(34)+"P(item="+title_cat+"|{&theta};GR)"+char(34)+" "+strofreal(2+shift_legend[1])+" "+char(34)+"{&psi}({&theta};GR)"+char(34)+" "+strofreal(3+shift_legend[1])+" "+char(34)+"P(item="+title_cat+"|{&theta};GF)"+char(34)+" "+strofreal(4+sum(shift_legend))+" "+char(34)+"{&psi}({&theta};GF)"+char(34)+" )) xtitle("+char(34)+thetan+char(34)+") xscale(range(-4 4)) ytitle("+char(34)+"P("+itemname+"="+title_cat+")"+char(34)+") yscale(range(0 1)) ylabel(0(0.2)1) graphregion(color(white)) bgcolor(white) "+icc_twoway
				
				if( cleargraphs | strpos(icc_twoway,"name"+char(40)) ){
					gr_name=""
				}
				else{
					gr_name=" name("+filename+")"
					stata("cap graph drop "+filename)
				}
				stata_command=stata_command+gr_name
				
				stata(stata_command)
				
				graph_save(icc_format, filename)
				
			}
			
			// ICC graph
			if(icc_mode==0){
				colours_vector=(char(34)+"242 0 60"+char(34) , char(34)+"248 89 0"+char(34) , char(34)+"242 136 0"+char(34) , char(34)+"242 171 0"+char(34) , char(34)+"239 204 0"+char(34) , char(34)+"240 234 0"+char(34) , char(34)+"177 215 0"+char(34) , char(34)+"0 202 36"+char(34) , char(34)+"0 168 119"+char(34) , char(34)+"0 167 138"+char(34) , char(34)+"0 165 156"+char(34) , char(34)+"0 163 172"+char(34) , char(34)+"0 147 175"+char(34) , char(34)+"0 130 178"+char(34) , char(34)+"0 110 191"+char(34) , char(34)+"125 0 248"+char(34) , char(34)+"159 0 197"+char(34) , char(34)+"185 0 166"+char(34) , char(34)+"208 0 129"+char(34) , char(34)+"226 0 100" + char(34), char(34)+"161 0 40" + char(34) , char(34)+"165 59 0" + char(34) , char(34)+"161 91 0" + char(34) , char(34)+"161 114 0" + char(34) , char(34)+"159 136 0" + char(34) , char(34)+"160 156 0" + char(34) , char(34)+"118 143 0" + char(34) , char(34)+"0 135 24" + char(34) , char(34)+"0 112 79" + char(34) , char(34)+"0 111 92" + char(34))'
				if(sum(icc_colours:!="")){
					colours_vector_a= char(34):+ subinstr(icc_colours,char(34),"") :+char(34)
					if(rows(icc_colours)<rows(colours_vector)){
						colours_vector_b=colours_vector[rows(icc_colours)+1::rows(colours_vector)]
						colours_vector=colours_vector_a\colours_vector_b
					}
					else{
						colours_vector=colours_vector_a
					}
				}
								
				for(i=1;i<=I;i++){
					if(if_makeicc[i]){
						
						itemname=Qx.get(Qx.names,i)
						filename=icc_prefix_suffix[1]+(strlen(icc_prefix_suffix[1])==0)*"ICC"+"_"+itemname+(strlen(icc_prefix_suffix[2])>0)*"_"+icc_prefix_suffix[2]
						
						stata_command="qui twoway "
						n_cat = Qx.get(Qx.n_cat,i)
						
						catcaption=" "
						catcaption_pos=1
						marginsize=strofreal(7+2*max(strlen(strofreal(*Qx.get(Qx.p_cat,i)))))
						if(n_cat == 2){
							title_cat=strofreal((*Qx.get(Qx.p_cat,i))[2])
							for(c=2;c<=n_cat;c++){
								catcaption=catcaption+" text("+strofreal(catcaption_pos)+" 4.15 "+char(34)+"cat="+strofreal((*Qx.get(Qx.p_cat,i))[c])+char(34)+",color("+colours_vector[c]+") place(e)) "
								catcaption_pos=catcaption_pos-0.04
							}
						}
						else{
							title_cat="cat"
							for(c=1;c<=n_cat;c++){
								catcaption=catcaption+" text("+strofreal(catcaption_pos)+" 4.15 "+char(34)+"cat="+strofreal((*Qx.get(Qx.p_cat,i))[c])+char(34)+",color("+colours_vector[c]+") place(e)) "
								catcaption_pos=catcaption_pos-0.04
							}
						}
						if(icc_obs==1){
							point_Uixx = J(1,N_gr,NULL)
							for(g=1;g<=N_gr;g++){
								if(Qx.get(Qx.g_tot,i)[g]>0){
									i_g = sum(Qx.get(Qx.g_tot,1::i)[.,g]:>0)
									point_Uixx[g]	= point_Uigc[i_g,g]
								}
								else{
									point_Uixx[g]	= &J(0,0,.)
								}
							}
							
							icc_graph_emppoints_res		= icc_graph_emppoints( selectQ(Qx,Qx.get(Qx.names,i)) , Pj_centile, point_Uixx, point_Fg, colours_vector, 0)
							stata_command				= stata_command+(*icc_graph_emppoints_res[1])
						}

						stata_command = stata_command+icc_graph_function(selectQ(Qx,Qx.get(Qx.names,i)), colours_vector,0)
						
						stata_command=stata_command+", legend(off) xtitle("+char(34)+thetan+char(34)+") xscale(range(-4 4)) ytitle("+char(34)+"P("+itemname+"="+title_cat+")"+char(34)+") yscale(range(0 1)) ylabel(0(0.2)1) graphregion(color(white)) bgcolor(white) graphregion(margin(r="+marginsize+"))"+ catcaption	+icc_twoway
		
						if( cleargraphs | strpos(icc_twoway,"name"+char(40)) ){
							gr_name=""
						}
						else{
							gr_name=" name("+filename+")"
							stata("cap graph drop "+filename)
						}
						stata_command=stata_command+gr_name
						
						
						stata(stata_command)
						
						graph_save(icc_format, filename)
						
						if(icc_obs==1){
							stata( "qui drop "+(*icc_graph_emppoints_res[2]) )
							if(*icc_graph_emppoints_res[3]!=""){
								stata(*icc_graph_emppoints_res[3])
							}
						}
					}
				}
			}
					
			// ESF graph
			if(icc_mode>=2){
			
				if(sum(icc_colours:!="")){
					esf_colour = char(34):+ subinstr(icc_colours,char(34),"") :+char(34)	
				}
				else{
					esf_colour = char(34):+ "green" :+char(34)
				}		
				
				if(icc_mode>=3){
					tau_min = 0
					tau_max = 0
					if(icc_obs==1){
						E_tau = J(cols(Pj_centile),1,0)
					}
					tau_function=" 0 "
				}
				
				for(i=1;i<=I;i++){
					if(if_makeicc[i]){

						itemname=Qx.get(Qx.names,i)
						filename=icc_prefix_suffix[1]+(strlen(icc_prefix_suffix[1])==0)*"IESF"+"_"+itemname+(strlen(icc_prefix_suffix[2])>0)*"_"+icc_prefix_suffix[2]
						
						stata_command="qui twoway "
						n_cat = Qx.get(Qx.n_cat,i)
						
						y_min = (*Qx.get(Qx.p_cat,i))[1]
						y_max = (*Qx.get(Qx.p_cat,i))[n_cat]
						
						if(icc_mode>=3){
							tau_min = tau_min + y_min
							tau_max = tau_max + y_max
						}
						
						y_labs_v = strofreal (( ((0::5)/5) * (y_max-y_min) ) :+ y_min)
						y_labs = ""
						for(v=1;v<=rows(y_labs_v);v++){
							y_labs = y_labs + " " + y_labs_v[v]
						}
						y_range=strofreal(y_min) + " " + strofreal(y_max)
						
						if(icc_obs==1){
							point_Uixx = J(1,N_gr,NULL)
							for(g=1;g<=N_gr;g++){
								if(Qx.get(Qx.g_tot,i)[g]>0){
									i_g = sum(Qx.get(Qx.g_tot,1::i)[.,g]:>0)
									point_Uixx[g]	= point_Uigc[i_g,g]
								}
								else{
									point_Uixx[g]	= &J(0,0,.)
								}
							}
							
							icc_graph_emppoints_res		= icc_graph_emppoints( selectQ(Qx,Qx.get(Qx.names,i)) , Pj_centile, point_Uixx, point_Fg, esf_colour,1)
							stata_command				= stata_command+(*icc_graph_emppoints_res[1])
							
							if(icc_mode>=3){
								E_tau = E_tau :+ (*icc_graph_emppoints_res[4]) 
							}
						}

						esf_curve = icc_graph_function(selectQ(Qx,Qx.get(Qx.names,i)), "" ,1)
						
						if(icc_mode>=3){
							tau_function = tau_function + " + " + esf_curve
						}
							
						if(icc_mode!=3){
							stata_command = stata_command + " (function " + esf_curve + ",range(-4 4) color("+ esf_colour +"))"
						
							stata_command=stata_command+", legend(off) xtitle("+char(34)+thetan+char(34)+") xscale(range(-4 4)) ytitle("+char(34)+"E("+itemname+"|{&theta})"+char(34)+") yscale(range(" + y_range + ")) ylabel(" + y_labs + ") graphregion(color(white)) bgcolor(white)" + icc_twoway
			
							if( cleargraphs | strpos(icc_twoway,"name"+char(40)) ){
								gr_name=""
							}
							else{
								gr_name=" name("+filename+")"
								stata("cap graph drop "+filename)
							}
							stata_command=stata_command+gr_name
							
							
							stata(stata_command)
							
							graph_save(icc_format, filename)
						}
						
						if(icc_obs==1){
							stata( "qui drop "+(*icc_graph_emppoints_res[2]) )
							if(*icc_graph_emppoints_res[3]!=""){
								stata(*icc_graph_emppoints_res[3])
							}
						}
					}
				}
			}
			
			// TRF graph
			if(icc_mode>=3){
			
				filename=icc_prefix_suffix[1]+(strlen(icc_prefix_suffix[1])>0)*"_"+"TESF"+(strlen(icc_prefix_suffix[2])>0)*"_"+icc_prefix_suffix[2]
				
				stata_command="qui twoway "
				
				tempvarlist=""
				dropaddedobs=""
				
				if(icc_obs==1){
				
					icc_intervals = rows(E_tau)
					X_k_icc = invnormal( ((1::icc_intervals):-0.5):/icc_intervals )
				
					ThetaMode_var=st_tempname()
					tempvarlist=tempvarlist+" "+ThetaMode_var
					index_temp=st_addvar("double",ThetaMode_var)
					nobs=st_nobs()
					if(icc_intervals>nobs){
						st_addobs(icc_intervals-nobs)
						dropaddedobs=dropaddedobs+"qui drop in "+strofreal(nobs+1)+"/"+strofreal(icc_intervals)
					}
					st_store((1::icc_intervals),ThetaMode_var,X_k_icc)
					
					ItemMean_var=st_tempname()
					tempvarlist=tempvarlist+" "+ItemMean_var
					index_temp=st_addvar("double",ItemMean_var)
					st_store((1::icc_intervals),ItemMean_var,E_tau)
					
					stata_command=stata_command+"(scatter  "+ItemMean_var+" "+ThetaMode_var+", mcolor("+substr(esf_colour,1,strlen(esf_colour)-1)+"*0.5"+char(34)+") msize(vsmall)) || "	
					

				}
			
				stata_command = stata_command + " (function " + tau_function + ",range(-4 4) color("+ esf_colour +"))"
					
				y_min = tau_min
				y_max = tau_max
				
				y_labs_v = strofreal (( ((0::5)/5) * (y_max-y_min) ) :+ y_min)
				y_labs = ""
				for(v=1;v<=rows(y_labs_v);v++){
					y_labs = y_labs + " " + y_labs_v[v]
				}
				y_range=strofreal(y_min) + " " + strofreal(y_max)
					
				stata_command=stata_command+", legend(off) xtitle("+char(34)+thetan+char(34)+") xscale(range(-4 4)) ytitle("+char(34)+"E(X|{&theta})"+char(34)+") yscale(range(" + y_range + ")) ylabel(" + y_labs + ") graphregion(color(white)) bgcolor(white)" + icc_twoway

				if( cleargraphs | strpos(icc_twoway,"name"+char(40)) ){
					gr_name=""
				}
				else{
					gr_name=" name("+filename+")"
					stata("cap graph drop "+filename)
				}
				stata_command=stata_command+gr_name
				
				
				stata(stata_command)
				
				graph_save(icc_format, filename)
				
				if(icc_obs==1){
					stata( "qui drop "+tempvarlist )
					if(dropaddedobs==""){
						stata(dropaddedobs)
					}
				}
				
			}		
		}
	}
	
	pointer colvector em(_Q, _G, real scalar estimate_dist, real scalar N_iter, real scalar trace, string scalar errors, real scalar crit_ll, real scalar guessing_attempts, real scalar guessing_lrcrit,string matrix eap_names, real scalar theta_nip, real matrix theta_scale, string scalar theta_notes, real colvector Theta_id, real colvector Theta_dup, string scalar savingname, pointer matrix point_Uigc, pointer matrix point_Fg , real scalar upd_quad_betw_em, real scalar N_iter_NRF, real scalar crit_par, real scalar check_a){

		class ITEMS scalar Q
		Q=_Q

		class GROUPS scalar G
		G=_G

		I=Q.n
		
		I_guess=(sum((Q.get(Q.m_curr,.):=="2plm"):*(Q.get(Q.m_asked,.):=="3plm")))
		guessing_attempts_count=1
		
		for(i=1;i<=I;i++){
			Q.put(Q.delta,i,Q.get(Q.pars,i):*0)
		}
		G.put(G.delta,.,G.get(G.pars,.):*0)
		
		delta_ll=1
		display_logLdecrese=0
				
		if(errors=="sem"){
			long_EMhistory_matrix=J(2*G.n+sum(Q.get(Q.n_par,.)),N_iter,.)
		}
		else{
			long_EMhistory_matrix=J(0,0,.)
		}
		
		if((cols(Q.get(Q.a_prior,.))==2)|(cols(Q.get(Q.b_prior,.))==2)|(cols(Q.get(Q.c_prior,.))==2)){
			if_priors=1
			if(N_iter){
				display("Warning: logL may decrease because item parameter estimation involves priors; convergence will be monitored only with crit_par(#)")
			}
			else{
				display("Warning: item parameter estimation involves priors")
			}
			if(cols(Q.get(Q.c_prior,.))==2){
				if_priors_c=1
			}
			else{
				if_priors_c=0
			}
		}
		else{
			if_priors=0
			if_priors_c=0
		}

		haywire_list=""
		haywire_guess_list=""
		if_em_converged=1
		for(iter=1;iter<=N_iter;iter++){
		
				if(  (( (max(abs(Q.get(Q.delta,.)))>crit_par) | (max(abs(G.get(G.delta,.)))>crit_par) ) & (delta_ll>crit_ll | if_priors) ) | iter==1 ){
			
				if(iter==1 | haywire_list!="" | haywire_guess_list!=""){
					previous_ll=-10^20	
				}
				else{
					previous_ll=sum(logL)
				}				
												
				em_step_results	= em_step(Q, G , point_Uigc,point_Fg  , upd_quad_betw_em,N_iter_NRF,crit_par)
				logL			= *em_step_results[1]
				f_ik			= *em_step_results[2]
				p_ik			= *em_step_results[3]

				delta_ll=(previous_ll-sum(logL))/sum(logL)
				
				print_iter(Q, G, iter, logL, trace)
								
				// adding 3plm items that have guessing<0 to haywire_list (	delta[i,.]==delta[i,.]*0)
				if(sum((Q.get(Q.m_curr,.):=="3plm"))){	
					index_haywire_guess=select((1::I),(Q.get(Q.m_curr,.):=="3plm") :* (Q.get(Q.pars,.)[.,3]:<0) )
					if(rows(index_haywire_guess)){
						Q.put(Q.delta, index_haywire_guess, Q.get(Q.pars,index_haywire_guess):*0)
					}
				}
				
				haywire_list=""
				haywire_guess_list=""
				haywire_indexes=J(0,1,.)
				ok_indexes=J(0,1,.)
				for(i=1;i<=I;i++){
					if(max(abs(Q.get(Q.delta,i)))==0 & Q.get(Q.n_fix,i)<Q.get(Q.n_par,i)){
						if(sum(index_haywire_guess:==i)){
							haywire_guess_list=haywire_guess_list+" "+Q.get(Q.names,i)
						}
						else{
							haywire_list=haywire_list+" "+Q.get(Q.names,i)
						}
						haywire_indexes=haywire_indexes\i
					}
					else{
						ok_indexes=ok_indexes\i
					}
				}	
				if(rows(haywire_indexes)){
				
					if(strlen(haywire_list)){
						display("estimates of folowing items went haywire (|delta_par|>5), their starting values will be refined, logL may increase:")
						display(haywire_list)
					}
					if(strlen(haywire_guess_list)){
						display("guessing parameter turned negative (c<0) for the following items, their starting values will be refined, logL may increase:")
						display(haywire_guess_list)
					}
		
					point_Uigc_ok=J(Q.n,G.n,NULL)
					for(g=1;g<=G.n;g++){
						isel_gall=select((1::I),Q.get(Q.g_tot,.)[.,g]:>0)
						isel_gok=select((1::I)[ok_indexes],Q.get(Q.g_tot,ok_indexes)[.,g]:>0)
						if(rows(isel_gok)){
							isel_g=select((1::rows(isel_gall)),rowsum(isel_gall:==J(rows(isel_gall),1,isel_gok')))
							point_Uigc_ok[1::rows(isel_g),g]=point_Uigc[isel_g,g]
						}
					}
					
					ll_theta_se = return_ll_theta_se(selectQ(Q,Q.get(Q.names,ok_indexes)), G ,1 ,195, point_Uigc_ok, point_Fg)
					
					X_var=st_tempname()
					index_temp=st_addvar("double",X_var)
					//  drawing pseudoplausible values, errors in estimating parameters are not accounted for but better solution that EAP
					st_store(Theta_id,index_temp,rnormal(1,1,(*ll_theta_se[2])[Theta_dup],(*ll_theta_se[3])[Theta_dup]))

					// if a 3pl item went haywire the model is changed to 2pl
					sel_3plm=select(haywire_indexes,Q.get(Q.m_curr,haywire_indexes):=="3plm")
					if(rows(sel_3plm)){
						Q.put(Q.m_curr,sel_3plm,J(rows(sel_3plm),1,"2plm"))
						Q.put(Q.n_par_model,sel_3plm,J(rows(sel_3plm),1,2))
						Q.put(Q.cns,sel_3plm,Q.get(Q.cns,sel_3plm)[.,1..2])
						Q.put(Q.par_labs,sel_3plm,J(rows(sel_3plm),1,("a","b")))
						Q.put(Q.delta,sel_3plm,J(rows(sel_3plm),1,(0,0)))
						guesslist = select(Q.get(Q.names,.),(Q.get(Q.m_curr,.):=="2plm"):*(Q.get(Q.m_asked,.):=="3plm"))
						I_guess = rows(guesslist)
					}
					
					Q.put(Q.pars,haywire_indexes,Q.get(Q.fix,haywire_indexes))
					
					starting_values_logistic(Q, G, Theta_id, Theta_dup, point_Uigc, X_var, check_a )
					
					if(sum(Q.get(Q.init_fail,.))){
							
						dropped_items_range		= select((1::Q.n), Q.get(Q.init_fail,.):>0 )
						dropped_items		= Q.get(Q.names,dropped_items_range)
						dropped_item_whyfail= Q.get(Q.init_fail,dropped_items_range)
						display("Note: "+strofreal(rows(dropped_items))+" items are dropped from analysis:")
						for(i=1;i<=rows(dropped_items);i++){
							if(dropped_item_whyfail[i]==1){
								display("      failed generating starting values (convergence): "+dropped_items[i])
							}
							if(dropped_item_whyfail[i]==2){
								display("      failed generating starting values (a<0)        : "+dropped_items[i])
							}
						}
						
						kept_items_range	= select((1::Q.n), Q.get(Q.init_fail,.):==0 )
						kept_items			= Q.get(Q.names,kept_items_range)
						Q.populate(kept_items)
					
						I=Q.n
						guesslist = select(Q.get(Q.names,.),(Q.get(Q.m_curr,.):=="2plm"):*(Q.get(Q.m_asked,.):=="3plm"))
						I_guess = rows(guesslist)
						
						data_pointers	= return_data_pointers(Q,G)
						point_Uigc		= *data_pointers[1]
						point_Fg		= *data_pointers[2]
						Theta_id		= *data_pointers[3]
						Theta_dup		= *data_pointers[4]
						data_pointers	= J(0,0,NULL)
						
					}
								
				}
													
				if(errors=="sem"){
					// and so we have a problem with this guessing generation in the context of sem, all previous history becomes discarded :/	
					long_EMhistory_vector=create_long_vector(Q, G, "pars")
					if(rows(long_EMhistory_vector)!=rows(long_EMhistory_matrix)){
						long_EMhistory_matrix=J(rows(long_EMhistory_vector),N_iter,.)
					}
					long_EMhistory_matrix[.,iter]=create_long_vector(Q, G, "pars")
				}							

			
				if(savingname!="."){
					save_iteration_matrices(Q, G ,savingname)
				}

									
				if(sum((Q.get(Q.m_curr,.):=="pcm"):*(Q.get(Q.m_asked,.):=="gpcm")) & (max(abs(Q.get(Q.delta,.)))<(10^(log10(crit_par)/2)))){
				
					sel_gpcm=select((1::Q.n) , (Q.get(Q.m_curr,.):=="pcm"):*(Q.get(Q.m_asked,.):=="gpcm") )
					sel_gpcm_free=select((1::Q.n) , (Q.get(Q.m_curr,.):=="pcm"):*(Q.get(Q.m_asked,.):=="gpcm"):*(Q.get(Q.fix,.)[.,1]:==1) )
					
					Q.put(Q.m_curr,sel_gpcm,J(rows(sel_gpcm),1,"gpcm"))
					if(rows(sel_gpcm_free)){
					    gpcm_sel_fix=Q.get(Q.fix,sel_gpcm_free)
						gpcm_sel_fix[.,1]=J(rows(sel_gpcm_free),1,.)
						gpcm_sel_cns=(gpcm_sel_fix:!=.)
					    Q.put(Q.fix,sel_gpcm_free,gpcm_sel_fix)
						Q.put(Q.cns,sel_gpcm_free,gpcm_sel_cns)
					}

					if(sum(Q.get(Q.m_curr,.):=="pcm")==0 & estimate_dist==0){
					
						sel_non3plm=select((1::Q.n) , (Q.get(Q.m_curr,.):!="3plm"))
						Q.put(Q.pars,sel_non3plm,( Q.get(Q.pars,sel_non3plm)[.,1]*G.get(G.pars,1)[2] , Q.get(Q.pars,sel_non3plm)[.,2..max(Q.get(Q.n_par,sel_non3plm))]/G.get(G.pars,1)[2] ) )
												
						sel_3plm=select((1::Q.n) , (Q.get(Q.m_curr,.):=="3plm"))
						if(rows(sel_3plm)){
							Q.put(Q.pars,sel_3plm,( Q.get(Q.pars,sel_3plm)[.,1]*G.get(G.pars,1)[2] , Q.get(Q.pars,sel_3plm)[.,2..max(Q.get(Q.n_par,sel_3plm))]/G.get(G.pars,1)[2] ) )
						}
						
						G.put(G.X_k,.,G.get(G.X_k,.)/G.get(G.pars,1)[2])
						G.put(G.pars,.,G.get(G.pars,.)/G.get(G.pars,1)[2])
					}
					
				}
			
				if(I_guess>0){
					if( ( (max(abs(Q.get(Q.delta,.)))<(10^(log10(crit_par)/((1-guessing_attempts_count)/guessing_attempts+2)))) & (guessing_attempts_count<=guessing_attempts) ) | (iter>1 & if_priors_c & guessing_attempts_count<=guessing_attempts) ){
	
						display("generating starting values for guessing parameters for "+strofreal(I_guess)+" item(s); attempt="+strofreal(guessing_attempts_count))
						
						starting_values_guess(Q, G , guessing_lrcrit, f_ik, p_ik, point_Uigc, point_Fg)
						
						I_guess = I_guess=(sum((Q.get(Q.m_curr,.):=="2plm"):*(Q.get(Q.m_asked,.):=="3plm")))
						guessing_attempts_count++
					}
				}				
			}
			else{
				if( (delta_ll<0) & (if_priors==0) ){
					display_logLdecrese=1
				}
			}		
		}
		
		if( (iter>N_iter)& ( ( max(abs(Q.get(Q.delta,.)))>crit_par ) | ( max(abs(G.get(G.delta,.)))>crit_par ) ) & (delta_ll>crit_ll | if_priors) ){
			if_em_converged=0
		}

		if(display_logLdecrese){
			display("Warning: logL started to decrease, this should not happen in EM algorithm, try increasing nip() or use slow if multigroup")
			if_em_converged=0
		}
		
		if(if_em_converged==0){
			display("Warning: the EM algorithm did not reach convergence criteria")
		}
	
		if(errors=="sem"){
			if(nonmissing(long_EMhistory_matrix)){
				long_EMhistory_matrix=select(long_EMhistory_matrix',rownonmissing(long_EMhistory_matrix'):>0)'
			}
		}


// recalculate ll, obtain theta and theta_se estimates if requested		
		add_theta = (cols(eap_names)==2)
		ll_theta_se = return_ll_theta_se(Q, G, add_theta , theta_nip, point_Uigc, point_Fg)
	
		if(add_theta==1){
			thvar=eap_names[1]
			sevar=eap_names[2]
			index_temp=st_addvar("double",(thvar,sevar))
			if(cols(theta_scale)==2){
				m_ref=G.get(G.pars,1)[1]
				sd_ref=G.get(G.pars,1)[2]
				st_store(Theta_id,index_temp,( (*ll_theta_se[2] :* (theta_scale[2]/sd_ref)) :+ (theta_scale[1]-m_ref*theta_scale[2]/sd_ref) , (*ll_theta_se[3] :* (theta_scale[2]/sd_ref) ))[Theta_dup,.])
			}
			else{
				st_store(Theta_id,index_temp,(*ll_theta_se[2],*ll_theta_se[3])[Theta_dup,.])
			}
			if(strlen(theta_notes)){
				stata("note "+thvar+":EAP point estimate of theta after fitting: "+theta_notes+" (time:`c(current_date)' `c(current_time)')")
				stata("note "+sevar+":Standard error of EAP point estimate of theta after fitting: "+theta_notes+" (time:`c(current_date)' `c(current_time)')")
			}
			display("Added variables: "+thvar+", "+sevar)
		}
				
		results = J(3,1,NULL)
		results[1] = &(*ll_theta_se[1])
		results[2] = &long_EMhistory_matrix
		results[3] = &if_em_converged
		return(results)
	}


	pointer colvector em_step(_Q, _G , pointer matrix point_Uigc, pointer matrix point_Fg , real scalar upd_quad_betw_em, real scalar N_iter_NRF, real scalar crit_par){
		
		class ITEMS scalar Q
		Q=_Q
		class GROUPS scalar G
		G=_G
		
		e_step_results	= e_step(Q, G,point_Uigc,point_Fg)
		logL			= *e_step_results[1]
		A_k_estimated	= *e_step_results[2]
		p_ik			= *e_step_results[3]
		p_ck			= *e_step_results[4]
		f_ik			= *e_step_results[5]

		N_gr=G.n
		K=cols(G.get(G.A_k,.))
		
		X_k= G.get(G.X_k,.)'
		X_k_upd_quad = X_k
		for(g=1;g<=N_gr;g++){				
			if(G.get(G.cns,g)[1]==0){
				X_mean_g 		= sum(X_k[.,g] :* A_k_estimated[.,g])
			}
			else{
				X_mean_g 		= G.get(G.pars,g)[1]
			}
			
			if(G.get(G.cns,g)[2]==0){
				X_sd_g 			= ((sum(X_k[.,g] :* X_k[.,g] :* A_k_estimated[.,g]) - sum(X_k[.,g] :* A_k_estimated[.,g])^2)^0.5)
			}
			else{
				X_sd_g			= G.get(G.pars,g)[2]
			}
			
			X_k_upd_quad[.,g] 	=((X_k[.,g] - J(K,1,G.get(G.pars,g)[1]))/G.get(G.pars,g)[2])*X_sd_g+J(K,1,X_mean_g)
			
			G.put(G.delta,g,( G.get(G.pars,g) :- (X_mean_g,X_sd_g) ))
			G.put(G.pars,g,(X_mean_g,X_sd_g))
		}
					
		if(upd_quad_betw_em==1 & sum(Q.get(Q.m_asked,.):=="pcm")==0){
			X_k = X_k_upd_quad
		}

		
		pars_0=Q.get(Q.pars,.)
		Q.put(Q.pars,., ( Q.get(Q.pars,.) :+ m_step(Q,X_k, f_ik, p_ik, p_ck,0) ) )
		for(iter_NRF=2;iter_NRF<=N_iter_NRF;iter_NRF++){
			if((max(abs(Q.get(Q.delta,.)))>crit_par/10)){
				Q.put(Q.pars,., ( Q.get(Q.pars,.) :+ m_step(Q,X_k, f_ik, p_ik, p_ck,0) ) )
			}
		}
		
		delta=Q.get(Q.pars,.)-pars_0
		for(i=1;i<=Q.n;i++){
			if(max(abs(delta[i,.]))>5){
				Q.put(Q.pars,i,pars_0[i,.])
				Q.put(Q.delta,i,pars_0[i,.]*0)
			}
			else{
				Q.put(Q.delta,i,delta[i,.])
			}
		}
		
		
		X_k = X_k_upd_quad
		G.put(G.X_k,.,X_k')

		results = J(4,1,NULL)
		results[1] = &logL
		results[2] = &f_ik
		results[3] = &p_ik
		results[4] = &p_ck
		return(results)
				
	}


	pointer colvector e_step(_Q, _G, pointer matrix point_Uigc, pointer matrix point_Fg){
	
		class ITEMS scalar Q
		Q=_Q
		class GROUPS scalar G
		G=_G
		
		I=Q.n
		I_c = sum(select(Q.get(Q.n_cat,.),Q.get(Q.n_cat,.):>2))
		K=cols(G.get(G.A_k,.))
		N_gr=G.n
		
		A_k_estimated = J(K,N_gr,.) 
		f_ik = J(I,0,.)
		p_ik = J(I,0,.)
		p_ck = J(I_c,0,.)
		logL = J(N_gr,1,0)

		class ITEMS scalar Qg
		class GROUPS scalar Gg
		
		for(g=1;g<=N_gr;g++){
			
			Fg = *point_Fg[g]
			
			itemselectrange_g=select((1::I),Q.get(Q.g_tot,.)[.,g]:>0)
			
			Qg=selectQ(Q,Q.get(Q.names,itemselectrange_g))
			Gg=selectG(G,g)
			
			I_g = Qg.n
			I_c_g =	sum(select(Qg.get(Qg.n_cat,.),Qg.get(Qg.n_cat,.):>2))
						
			PXk_Uj = eE_step(Qg, Gg, point_Uigc[.,g])
			logL[g] = sum( Fg :* ln(rowsum(PXk_Uj)) )
			PXk_Uj = PXk_Uj :/ rowsum(PXk_Uj)
			
			f_ik_g = J(I_g,K,0)
			p_ik_g = J(I_g,K,0)
			p_ck_g = J(I_c_g,K,0)
			for(i=1;i<=I_g;i++){
				n_cat = Qg.get(Qg.n_cat,i)
				cat_freqs = J(n_cat,K,.)
				for(c=1;c<=n_cat;c++){
					ord_ic = *(*point_Uigc[i,g])[c]
					if(rows(ord_ic)){ // in case of fixing and missing
						cat_freqs[c,.] = colsum( Fg[ord_ic] :* PXk_Uj[ord_ic,.] )
					}
					f_ik_g[i,.]=f_ik_g[i,.]+cat_freqs[c,.]
				}
				if(n_cat==2){
					p_ik_g[i,.] = cat_freqs[2,.] :/ f_ik_g[i,.]
				}
				else{
					row_p_ck_g = sum(select(Qg.get(Qg.n_cat,(1::i)),Qg.get(Qg.n_cat,(1::i)):>2))-n_cat+1
					for(c=1;c<=n_cat;c++){
						p_ck_g[row_p_ck_g,.] = cat_freqs[c,.]:/ f_ik_g[i,.]
						row_p_ck_g++
					}
				}
			}
			
			temp=J(I,K,0)
			temp[itemselectrange_g,.]=f_ik_g
			f_ik=f_ik,temp
			temp = J(I,K,0)
			temp[itemselectrange_g,.]=p_ik_g
			p_ik=p_ik,temp	
			temp = J(I_c,K,.)
			if(I_c_g){
				okrange=J(0,1,.)
				range_start=1
				for(i=1;i<=I;i++){
					if(Q.get(Q.n_cat,i)>2){
						range_stop=range_start+Q.get(Q.n_cat,i)-1
						if(Q.get(Q.g_tot,i)[g]){
							okrange=okrange\(range_start::range_stop)
						}
						range_start=range_stop+1
					}
				}
			temp[okrange,.]=p_ck_g
			}
			p_ck=p_ck,temp
			
			if(g>1-sum(G.get(G.cns,1):==0)){
				A_k_estimated[.,g] =(colsum(Fg :* PXk_Uj)/G.get(G.n_total,g))'
			}
		
			
		}
		
		results = J(5,1,NULL)
		results[1] = &logL
		results[2] = &A_k_estimated
		results[3] = &p_ik
		results[4] = &p_ck
		results[5] = &f_ik
		return(results)
		
	}



	pointer colvector return_ll_theta_se(_Q, _G , real scalar add_theta, real scalar theta_nip, pointer matrix point_Uigc, pointer matrix point_Fg){
	
		class ITEMS scalar Q
		Q=_Q
		class ITEMS scalar Qx
		Qx=cloneQ(Q)
		
		class GROUPS scalar G
		G=_G
		class GROUPS scalar Gx
		Gx=cloneG(G)
		
		N_gr=Gx.n
		I=Qx.n
		K=cols(Gx.get(Gx.X_k,.))
		logL = J(N_gr,1,0)

		if(add_theta==1){
			theta_rangestart = 1
			theta = J(sum(Gx.get(Gx.n_uniq,.)),1,.)
			se = theta
		}
		else{
			theta = J(0,0,.)
			se = J(0,0,.)
		}
		
		class ITEMS scalar Qg
		class GROUPS scalar Gg
		
		for(g=1;g<=N_gr;g++){
			
			itemselectrange_g=select((1::I),Qx.get(Qx.g_tot,.)[.,g]:>0)
			
			Qg=selectQ(Qx,Qx.get(Qx.names,itemselectrange_g))
			Gg=selectG(Gx,g)
						
			PXk_Uj = eE_step(Qg, Gg, point_Uigc[.,g])

			logL[g] = sum( (*point_Fg[g]) :* ln(rowsum(PXk_Uj)) )			
			
			if(add_theta==1){
				
				theta_rangestop=theta_rangestart+Gg.get(Gg.n_uniq,.)-1
				
				if(theta_nip!=K){
					DIST_g=Gg.get(Gg.pars,.)
					quad_GH_g	= get_quad_GH(theta_nip,DIST_g)
					Gg.put(Gg.X_k,.,*quad_GH_g[1])
					Gg.put(Gg.A_k,.,*quad_GH_g[2])
					
					PXk_Uj = eE_step(Qg, Gg, point_Uigc[.,g])
					PXk_Uj = PXk_Uj :/ rowsum(PXk_Uj)
				}
				else{
					PXk_Uj = PXk_Uj :/ rowsum(PXk_Uj)
				}
				X_k_theta = Gg.get(Gg.X_k,.)'
								
				theta[theta_rangestart::theta_rangestop]	= rowsum(PXk_Uj :* X_k_theta')
				se[theta_rangestart::theta_rangestop]		= sqrt(rowsum(PXk_Uj :* (X_k_theta' :* X_k_theta')) :- (theta[theta_rangestart::theta_rangestop] :* theta[theta_rangestart::theta_rangestop]))
				
				theta_rangestart=theta_rangestop+1
				
			}
		}
		
		results = J(3,1,NULL)
		results[1] = &logL
		results[2] = &theta
		results[3] = &se

		return(results)
		
	}	


	void save_iteration_matrices(_Q, _G , string scalar savingname){
	
		class ITEMS scalar Q
		Q=_Q
		class GROUPS scalar G
		G=_G
		
		unlink("_inms_"+savingname+".matrix")
		inmsf = fopen("_inms_"+savingname+".matrix", "w")
			fputmatrix(inmsf,Q.get(Q.names,.))
		fclose(inmsf)

		unlink("_iprs_"+savingname+".matrix")				
		iprsf = fopen("_iprs_"+savingname+".matrix", "w")
			fputmatrix(iprsf,Q.get(Q.pars,.))
		fclose(iprsf)
		
		unlink("_dprs_"+savingname+".matrix")				
		dprsf = fopen("_dprs_"+savingname+".matrix", "w")
			fputmatrix(dprsf,G.get(G.pars,.))
		fclose(dprsf)
			
		unlink("_gvls_"+savingname+".matrix")				
		gvlsf = fopen("_gvls_"+savingname+".matrix", "w")
			fputmatrix(gvlsf,G.get(G.val,.))
		fclose(gvlsf)
	
	}
	

	real matrix eE_step(_Qg, _Gg, pointer matrix point_Uxgx){
	
		class ITEMS scalar Qg
		Qg=_Qg

		class GROUPS scalar Gg
		Gg=_Gg
		
		I=Qg.n
		K=cols(Gg.get(Gg.X_k,.))
		Obs_g=Gg.get(Gg.n_uniq,.)
		X_k=Gg.get(Gg.X_k,.)'
		A_k=Gg.get(Gg.A_k,.)'
		
		LXk_Uj=J(Obs_g,K,1)
		for(i=1;i<=I;i++){
			n_cat	= Qg.get(Qg.n_cat,i)
			model	= (Qg.get(Qg.m_curr,i),strofreal(n_cat))
			pars_i	= Qg.get(Qg.pars,i)
			if(n_cat==2  & model[1]!="pcm"){
				PiXk_0c=(1 :- f_PiXk_01(pars_i,model,X_k)) \ f_PiXk_01(pars_i,model,X_k)
			}
			else{
				PiXk_0c=f_PiXk_0c(pars_i,model,X_k)
			}
	
			for(c=1;c<=n_cat;c++){
				ord_ic = *(*point_Uxgx[i])[c]
				if(rows(ord_ic)){ // in case of fixing and missing
					LXk_Uj[ord_ic,.] = LXk_Uj[ord_ic,.] :* PiXk_0c[c,.]
				}
			}
		}
	
		PXk_Uj=A_k' :* LXk_Uj

		return(PXk_Uj)
	}
	
		
	real matrix m_step(_Q, real matrix X_k,real matrix f_ik,real matrix p_ik,real matrix p_ck,real scalar delta_fisher_score){
		
		class ITEMS scalar Q
		Q=_Q
	
		I=Q.n
		K=rows(X_k)
		N_gr=cols(X_k)
		
		model		= (Q.get(Q.m_curr,.),strofreal(Q.get(Q.n_cat,.)))
		parameters	= Q.get(Q.pars,.)
		
		
		PiXk=J(I,0,.)
		for(g=1;g<=N_gr;g++){
			PiXk_g=f_PiXk_01(parameters,model,X_k[.,g])
			PiXk=PiXk,PiXk_g
		}
		
		for(i=1;i<=I;i++){
		
			n_cat	= Q.get(Q.n_cat,i)
			pars_i	= Q.get(Q.pars,i)

			if(Q.get(Q.n_par,i)>Q.get(Q.n_fix,i)){

				if(model[i,1]=="2plm"){
					
					a = pars_i[1]
					b = pars_i[2]
					
					Fxp_P = f_ik[i,.] :* (p_ik[i,.]-PiXk[i,.])
					X_b=J(1,0,.)
					for(g=1;g<=N_gr;g++){
						X_b =X_b , (X_k[.,g]'-J(1,K,b))
					}
					FxPxQ = f_ik[i,.] :* (PiXk[i,.] :* (J(1,N_gr*K,1)-PiXk[i,.]))
					
					
					L1_gk		= (Fxp_P :* X_b)
					L2_gk		= -a :* (Fxp_P)
					Score_gk	= (L1_gk \ L2_gk)
					Score 		= rowsum(Score_gk)
					
					L11 		= -sum(FxPxQ :* (X_b :* X_b))
					L22 		= -a^2*sum(FxPxQ)
					L12 		= a*sum(FxPxQ :* X_b)
					
					if(cols(Q.get(Q.a_prior,i))==2){
						a_prior_mu=Q.get(Q.a_prior,i)[1]
						a_prior_sigma=Q.get(Q.a_prior,i)[2]
						
						prior_a=-(a-a_prior_mu)/a_prior_sigma^2
						prior_aa=-1/a_prior_sigma^2
					
						Score[1]=Score[1]+prior_a	
						L11=L11+prior_aa
					}

					if(cols(Q.get(Q.b_prior,i))==2){
						b_prior_mu=Q.get(Q.b_prior,i)[1]
						b_prior_sigma=Q.get(Q.b_prior,i)[2]
						
						prior_b=-(b-b_prior_mu)/b_prior_sigma^2
						prior_bb=-1/b_prior_sigma^2
					
						Score[2]=Score[2]+prior_b
						L22=L22+prior_bb
					}
					
					Fisher 		= -1*(L11,L12\L12,L22)
						
					if(Q.get(Q.n_fix,i)){
						free	= 1:-Q.get(Q.cns,i)
						Fisher	= Fisher	:*cross(free,free)
						Score_gk= Score_gk	:*free' 
						Score	= Score		:*free'
					}
					
					if(delta_fisher_score==0){
						Q.put(Q.delta, i, (invsym(Fisher)*Score)')
					}					
					if(delta_fisher_score==1){
						return(Fisher)
					}
					if(delta_fisher_score==2){
						return(Score_gk)
					}
					
				}
					
				if(model[i,1]=="3plm"){

					a = pars_i[1]
					b = pars_i[2]
					c = pars_i[3]
					
					V = (PiXk[i,.]-J(1,N_gr*K,c)) :/ (PiXk[i,.] :* J(1,N_gr*K,1-c))
					VV = V :* V
					
					Fxp_P = f_ik[i,.] :* (p_ik[i,.]-PiXk[i,.])
					X_b=J(1,0,.)
					for(g=1;g<=N_gr;g++){
						X_b =X_b , (X_k[.,g]'-J(1,K,b))
					}
					FxPxQ = f_ik[i,.] :* (PiXk[i,.] :* (J(1,N_gr*K,1)-PiXk[i,.]))
					FxQ=(f_ik[i,.] :* (J(1,N_gr*K,1)-PiXk[i,.])) 
					
					L1_gk		= (Fxp_P :* X_b :* V)
					L2_gk		= -a :* (Fxp_P :* V)
					L3_gk		= (1/(1-c)) :* (Fxp_P :/ PiXk[i,.])
					Score_gk	= (L1_gk \ L2_gk \ L3_gk)
					Score 		= rowsum(Score_gk)
					
					L11 = -sum(FxPxQ :* (X_b :* X_b) :* VV)
					L22 = -a^2*sum(FxPxQ :* VV)
					L33 = -(1/(1-c))^2*sum(FxQ :/ PiXk[i,.])
					L12 = a*sum(FxPxQ :* X_b :* VV)
					L13 = -(1/(1-c))*sum(FxQ :* X_b :* V)
					L23 = (a/(1-c))*sum(FxQ :* V)
					
					if(cols(Q.get(Q.a_prior,i))==2){
						a_prior_mu=Q.get(Q.a_prior,i)[1]
						a_prior_sigma=Q.get(Q.a_prior,i)[2]
						
						prior_a=-(a-a_prior_mu)/a_prior_sigma^2
						prior_aa=-1/a_prior_sigma^2
					
						Score[1]=Score[1]+prior_a	
						L11=L11+prior_aa
					}

					if(cols(Q.get(Q.b_prior,i))==2){
						b_prior_mu=Q.get(Q.b_prior,i)[1]
						b_prior_sigma=Q.get(Q.b_prior,i)[2]
						
						prior_b=-(b-b_prior_mu)/b_prior_sigma^2
						prior_bb=-1/b_prior_sigma^2
					
						Score[2]=Score[2]+prior_b
						L22=L22+prior_bb
					}					
					
					if(cols(Q.get(Q.c_prior,i))==2){
						prior_alpha=Q.get(Q.c_prior,i)[1]
						prior_beta=Q.get(Q.c_prior,i)[2]
										
						prior_c=(prior_alpha-1)/c - (prior_beta-1)/(1-c)
						prior_cc= -(prior_alpha-1)/c^2 - (prior_beta-1)/(1-c)^2
						
						Score[3]=Score[3]+prior_c
						L33=L33+prior_cc
					}
					
					Fisher = -1*(L11,L12,L13\L12,L22,L23\L13,L23,L33)
					
					if(Q.get(Q.n_fix,i)){
						free	= 1:-Q.get(Q.cns,i)
						Fisher	= Fisher	:*cross(free,free)
						Score_gk= Score_gk	:*free' 
						Score	= Score		:*free'
					}
					
					if(delta_fisher_score==0){
						Q.put(Q.delta, i, (invsym(Fisher)*Score)')
					}
					if(delta_fisher_score==1){
						return(Fisher)
					}
					if(delta_fisher_score==2){
						return(Score_gk)
					}
		
				}
				
				if(model[i,1]=="grm"){
				
		// 	PiXk_0c[1,.] -->cat=0
		// 	PiXk_0c[n_cat,.] -->cat=n_cat-1
					PiXk_0c=J(n_cat,0,.)
					for(g=1;g<=N_gr;g++){
						PiXk_0c_g=f_PiXk_0c(pars_i[.],model[i,.],X_k[.,g])
						PiXk_0c=PiXk_0c,PiXk_0c_g
					}
					
		// 	pi_ck[1,.] -->cat=0
		// 	pi_ck[n_cat,.] -->cat=n_cat-1	
					row_p_ck = sum(select(Q.get(Q.n_cat,(1::i)),Q.get(Q.n_cat,(1::i)):>2))-n_cat+1		
					pi_ck=p_ck[(row_p_ck::row_p_ck+n_cat-1),.]
	
		// 	PiXk_0c_star[1,.] -->cat>-1, i.e. dummy constant=1 function
		// 	PiXk_0c_star[2,.] -->cat>0, 
		// 	PiXk_0c_star[n_cat,.] -->cat>n_cat-2,
		// 	PiXk_0c_star[n_cat+1,.] -->cat>n_cat-1, i.e. dummy constant=0 function
					PiXk_0c_star=J(n_cat+1,N_gr*K,.)
					PiXk_0c_star[1,.]=J(1,N_gr*K,1)
					PiXk_0c_star[n_cat+1,.]=J(1,N_gr*K,0)
					
					grm_parameters = J(n_cat-1,1,pars_i[1]) , pars_i[2..n_cat]'
					dummy_2plm_model=J(n_cat-1,1,("2plm","2"))
					for(g=1;g<=N_gr;g++){
						PiXk_0c_star[(2::n_cat),((g-1)*K+1..g*K)]=f_PiXk_01(grm_parameters,dummy_2plm_model,X_k[.,g])
					}
							
					P_starxQ_star=PiXk_0c_star :* (1 :- PiXk_0c_star)
	
		// 	X_b_star[1,.] --> dummy 0, because always multiplied by 0
		// 	X_b_star[2,.] --> X_x - b of P(cat>0) 
		// 	X_b_star[n_cat,.] --> X_x - b of P(cat>n_cat-2)
		// 	X_b_star[n_cat+1,.] --> dummy 0, because always multiplied by 0
					X_b_star=J(n_cat+1,N_gr*K,.)
					X_b_star[1,.]=J(1,N_gr*K,0)
					X_b_star[n_cat+1,.]=J(1,N_gr*K,0)
					for(g=1;g<=N_gr;g++){
						X_b_star[(2::n_cat),((g-1)*K+1..g*K)] =(J(n_cat-1,1,X_k[.,g]') :- grm_parameters[.,2])
					}
					
					X_b_starxP_starxQ_star = X_b_star :* P_starxQ_star
					
					a=pars_i[1]
					
					Score_gk	= J(n_cat,N_gr*K,.)					
					Score		= J(n_cat,1,.)
					Fisher 		= J(n_cat,n_cat,0)
					
		// summation over categories cat\in{0...n_cat-2}
					for(c=1;c<=n_cat-1;c++){
						Score_gk[c,.] 		= a :* (f_ik[i,.] :* P_starxQ_star[c+1,.] :* ((pi_ck[c,.]:/PiXk_0c[c,.])-(pi_ck[c+1,.]:/PiXk_0c[c+1,.])))
					}
					Score_gk[n_cat,.]		= ( f_ik[i,.] :* colsum( (pi_ck[(1::n_cat),.] :/ PiXk_0c[(1::n_cat),.]) :* (X_b_starxP_starxQ_star[(1::n_cat),.] - X_b_starxP_starxQ_star[(2::n_cat+1),.]) ) )

					Score 					= rowsum(Score_gk)
					
											
					for(c=1;c<=n_cat-1;c++){
						Fisher[c,c] = -a^2 * sum(f_ik[i,.] :* P_starxQ_star[c+1,.] :* P_starxQ_star[c+1,.] :* ((1 :/ PiXk_0c[c,.])+(1 :/ PiXk_0c[c+1,.])))
						if(c<n_cat-1){
							Fisher[c,c+1] = a^2 * sum(f_ik[i,.] :* P_starxQ_star[c+1,.] :* P_starxQ_star[c+2,.] :* (1 :/ PiXk_0c[c+1,.]))
							Fisher[c+1,c] = Fisher[c,c+1]
						}
					}
					for(c=1;c<=n_cat-1;c++){
						Fisher[c,n_cat] = -a * sum(f_ik[i,.] :* P_starxQ_star[c+1,.] :* (( (X_b_starxP_starxQ_star[c,.] - X_b_starxP_starxQ_star[c+1,.]) :/ PiXk_0c[c,.])-( (X_b_starxP_starxQ_star[c+1,.] - X_b_starxP_starxQ_star[c+2,.]) :/ PiXk_0c[c+1,.])))
						Fisher[n_cat,c] = Fisher[c,n_cat]
					}
					Fisher[n_cat,n_cat] = - sum( f_ik[i,.] :* colsum( ((X_b_starxP_starxQ_star[(1::n_cat),.] - X_b_starxP_starxQ_star[(2::n_cat+1),.]) :* (X_b_starxP_starxQ_star[(1::n_cat),.] - X_b_starxP_starxQ_star[(2::n_cat+1),.])) :/ PiXk_0c[(1::n_cat),.] ) )
	
					
					Fisher = -1*Fisher
					
		// reordering parameters
					Fishertemp=Fisher[.,n_cat],Fisher[.,1..n_cat-1]
					Fisher=Fishertemp[n_cat,.]\Fishertemp[1::n_cat-1,.]
					Score_gk=Score_gk[n_cat,.]\Score_gk[1::n_cat-1,.]
					Score=Score[n_cat]\Score[1::n_cat-1]
					
					if(Q.get(Q.n_fix,i)){
						free	= 1:-Q.get(Q.cns,i)
						Fisher	= Fisher	:*cross(free,free)
						Score_gk= Score_gk	:*free' 
						Score	= Score		:*free'
					}
					
					if(delta_fisher_score==0){
						Q.put(Q.delta, i, (invsym(Fisher)*Score)')
					}
					if(delta_fisher_score==1){
						return(Fisher)
					}
					if(delta_fisher_score==2){
						return(Score_gk)
					}

					
				}
				
				//GPCM
				if(model[i,1]=="gpcm" | model[i,1]=="pcm"){
						
					PiXk_0c=J(n_cat,0,.)
					for(g=1;g<=N_gr;g++){
						PiXk_0c_g=f_PiXk_0c(pars_i[.],model[i,.],X_k[.,g])
						PiXk_0c=PiXk_0c,PiXk_0c_g
					}
							
					if(n_cat>2){		
						row_p_ck = sum(select(Q.get(Q.n_cat,(1::i)),Q.get(Q.n_cat,(1::i)):>2))-n_cat+1		
						pi_ck=p_ck[(row_p_ck::row_p_ck+n_cat-1),.]
					}
					else{
						pi_ck=(1:-p_ik[i,.])\p_ik[i,.]
					}
					
					a=pars_i[1]
					b_1tomax=pars_i[2..n_cat]		
					
					Zc_1toc=J(n_cat-1,cols(pi_ck),.)
					for(c=1;c<=n_cat-1;c++){
						for(g=1;g<=N_gr;g++){
							Zc_1toc[c,((g-1)*K+1..g*K)] = a :* ( c :* X_k[.,g]' :- sum(b_1tomax[1..c]) )
						}
					}
				
					Sum_Pc_ctomax=J(n_cat-1,cols(pi_ck),0)
					for(c=1;c<=n_cat-1;c++){
						for(cc=c+1;cc<=n_cat;cc++){
							Sum_Pc_ctomax[c,.]=Sum_Pc_ctomax[c,.] :+ PiXk_0c[cc,.]
						}
					}
					
					Sum_PcZc_1tomax=J(1,cols(pi_ck),0)
					for(c=1;c<=n_cat-1;c++){
						Sum_PcZc_1tomax=Sum_PcZc_1tomax :+ (PiXk_0c[c+1,.] :* Zc_1toc[c,.])
					}
					
					fik			= 			f_ik[i,.]
					afik		= a 	:*	fik
					asqfik		= a^2 	:* 	fik
					ainvfik		= 1/a 	:*	fik
					ainvsqfik	= 1/a^2 :*	fik
					
					Score_gk					= J(n_cat,N_gr*K,0)
					for(c=1;c<=n_cat-1;c++){
						for(cat=1;cat<=c;cat++){
							Score_gk[c,.]		= Score_gk[c,.] :+ (pi_ck[cat,.] :* Sum_Pc_ctomax[c,.] )
						}
						for(cat=c+1;cat<=n_cat;cat++){
							Score_gk[c,.]		= Score_gk[c,.] :- (pi_ck[cat,.] :* ( 1 :- Sum_Pc_ctomax[c,.] ) )
						}
						Score_gk[c,.]			= afik :* Score_gk[c,.]
					}
					Score_gk[n_cat,.]			= Score_gk[n_cat,.] :- (pi_ck[1,.] :* Sum_PcZc_1tomax )
					for(cat=2;cat<=n_cat;cat++){
						Score_gk[n_cat,.]		= Score_gk[n_cat,.] :+ (pi_ck[cat,.] :* (Zc_1toc[cat-1,.] :- Sum_PcZc_1tomax) )
					}
					Score_gk[n_cat,.]			= ainvfik :* Score_gk[n_cat,.]
					Score 						= rowsum(Score_gk)	
				
					Fisher 						= J(n_cat,n_cat,0)
					for(c=1;c<=n_cat-1;c++){
						for(cc=c;cc<=n_cat-1;cc++){
							Fisher_ccc			= J(1,N_gr*K,0)
							for(cat=1;cat<=n_cat;cat++){
								Fisher_ccc		= Fisher_ccc :+ (pi_ck[cat,.] :* ( (Sum_Pc_ctomax[c,.] :* Sum_Pc_ctomax[cc,.]) :- Sum_Pc_ctomax[max((c,cc)),.]))
							}
							Fisher_ccc			= sum(asqfik :* Fisher_ccc)
							Fisher[c,cc]		= Fisher_ccc
							Fisher[cc,c]		= Fisher_ccc
						}
					}
					derb_dera_wrr_ctomax=J(n_cat-1,cols(pi_ck),0)
					for(c=1;c<=n_cat-1;c++){
						for(cc=c;cc<=n_cat-1;cc++){
							derb_dera_wrr_ctomax[c,.]=derb_dera_wrr_ctomax[c,.] :+ (PiXk_0c[cc+1,.] :* (Zc_1toc[cc,.] :- Sum_PcZc_1tomax) )
						}
					}
					for(c=1;c<=n_cat-1;c++){
						Fisher_cncat			= J(1,N_gr*K,0)
						for(cat=1;cat<=n_cat;cat++){
							Fisher_cncat		= Fisher_cncat :+ (pi_ck[cat,.] :* derb_dera_wrr_ctomax[c,.])
						}
						Fisher_cncat			= sum(fik :* Fisher_cncat)
						Fisher[c,n_cat]			= Fisher_cncat
						Fisher[n_cat,c]			= Fisher_cncat					
					}
					dera_dera_wrr_ctomax=J(1,cols(pi_ck),0)
					for(c=1;c<=n_cat-1;c++){
						dera_dera_wrr_ctomax=dera_dera_wrr_ctomax :+ (PiXk_0c[c+1,.] :* Zc_1toc[c,.] :* (Sum_PcZc_1tomax :- Zc_1toc[c,.] ) )
					}
					Fisher_ncatncat				= J(1,N_gr*K,0)
					for(cat=1;cat<=n_cat;cat++){
						Fisher_ncatncat			= Fisher_ncatncat :+ (pi_ck[cat,.] :* dera_dera_wrr_ctomax)
					}
					Fisher[n_cat,n_cat]			= sum(ainvsqfik :* Fisher_ncatncat)	
					
								
					Fisher = -1*Fisher
	
					
					// reordering parameters
					Fishertemp=Fisher[.,n_cat],Fisher[.,1..n_cat-1]
					Fisher=Fishertemp[n_cat,.]\Fishertemp[1::n_cat-1,.]
					Score_gk=Score_gk[n_cat,.]\Score_gk[1::n_cat-1,.]
					Score=Score[n_cat]\Score[1::n_cat-1]
					
					if(Q.get(Q.n_fix,i)){
						free	= 1:-Q.get(Q.cns,i)
						Fisher	= Fisher	:*cross(free,free)
						Score_gk= Score_gk	:*free' 
						Score	= Score		:*free'
					}
					
					if(delta_fisher_score==0){
						Q.put(Q.delta, i, (invsym(Fisher)*Score)')
					}
					if(delta_fisher_score==1){
						return(Fisher)
					}
					if(delta_fisher_score==2){
						return(Score_gk)
					}
	
				}
			
			}
			else{
				if(delta_fisher_score==1){
					//return(Fisher)
					return(J(nonmissing(parameters[i,.]),nonmissing(parameters[i,.]),0))
					return(J(Q.get(Q.n_par,i),Q.get(Q.n_par,i),0))
				}
				if(delta_fisher_score==2){
					//return(Score_gk)
					return(J(Q.get(Q.n_par,i),N_gr*K,0))
				}
				Q.put(Q.delta, i, (pars_i*0) )
			}
				
		}

		if(delta_fisher_score==0){
			return(Q.get(Q.delta, .))
		}
	}
	
	
	function f_PiXk_01(real matrix parameters,string matrix model, real matrix X_k){
		K=rows(X_k)
		I=rows(parameters)		

		PiXk=J(I,K,.)
		for(i=1;i<=I;i++){
			if(model[i,2]=="2"){
				if(model[i,1]=="3plm"){
					PiXk[i,.]=invlogit(parameters[i,1]:*(X_k':-parameters[i,2])):*(1-parameters[i,3]):+parameters[i,3]
				}
				else{
					PiXk[i,.]=invlogit(parameters[i,1]*(X_k':-parameters[i,2]))
				}
			}
		}
		return(PiXk)	
	}

	
	function f_Pitem_theta_01(real matrix parameters,string matrix model, real matrix theta){
		K=rows(theta)
		Pitem_theta=J(K,1,.)
		if(model[2]=="2"){
			if(model[1]=="3plm"){
				Pitem_theta=invlogit(parameters[1]:*(theta:-parameters[2])):*(1-parameters[3]):+parameters[3]
			}
			else{
				Pitem_theta=invlogit(parameters[1]*(theta:-parameters[2]))
			}
		}
		return(Pitem_theta)	
	}
	
			
	function f_PiXk_0c(real matrix parameters,string matrix model, real matrix X_k){
		K		= rows(X_k)
		n_cat	= strtoreal(model[2])
		PiXk	= J(n_cat,K,.)
		
		if(model[1]=="grm"){
			PiXk[1,.] 	= 1 :- invlogit(parameters[1] :* (X_k' :- parameters[2]))
			PiXk[n_cat,.] = invlogit(parameters[1] :* (X_k' :- parameters[n_cat]))
			for(c=2;c<=n_cat-1;c++){
				PiXk[c,.] = invlogit(parameters[1] :* (X_k' :- parameters[c]))  :- invlogit(parameters[1] :* (X_k' :- parameters[1+c]))
			}
		}
		
		if(model[1]=="gpcm" | model[1]=="pcm"){
			expsum_all = 1
			for(c=2;c<=n_cat;c++){
				expsum_all = expsum_all :+ exp( parameters[1] :* ( (c-1) :* X_k' :- sum(parameters[2..c]) ) )
			}
			PiXk[1,.]	= 1 :/ expsum_all
			for(c=2;c<=n_cat;c++){
				PiXk[c,.] = exp( parameters[1] :* ( (c-1) :* X_k' :- sum(parameters[2..c]) ) ) :/ expsum_all
			}	
		}
		
		return(PiXk)	
	}


	function f_Pitem_theta_0c(real matrix parameters,string matrix model, real matrix theta){
		K		= rows(theta)
		n_cat	= strtoreal(model[2])	
		Pitem_theta=J(K,n_cat,.)
		
		if(model[1]=="grm"){
			Pitem_theta[.,1] = 1 :- invlogit(parameters[1] :* (theta :- parameters[2]))
			Pitem_theta[.,n_cat] = invlogit(parameters[1] :* (theta :- parameters[n_cat]))	
			for(c=2;c<=n_cat-1;c++){
				Pitem_theta[.,c] = invlogit(parameters[1] :* (theta :- parameters[c]))  :- invlogit(parameters[1] :* (theta :- parameters[1+c]))
			}
		}
		
		if(model[1]=="gpcm" | model[1]=="pcm"){
			expsum_all = 1
			for(c=2;c<=n_cat;c++){
				expsum_all = expsum_all :+ exp( parameters[1] :* ( (c-1) :* theta :- sum(parameters[2..c]) ) )
			}
			Pitem_theta[.,1]	= 1 :/ expsum_all
			for(c=2;c<=n_cat;c++){
				Pitem_theta[.,c] = exp( parameters[1] :* ( (c-1) :* theta :- sum(parameters[2..c]) ) ) :/ expsum_all
			}	
		}
		
		return(Pitem_theta)	
	}

	void store_matrices(_Q, _G, real matrix logL, string scalar temporary_suffix){
		
		class ITEMS scalar Q
		Q=_Q
		class GROUPS scalar G
		G=_G

		I=Q.n
		N_gr=G.n
		
		itemlist=Q.get(Q.names,.)
		models=Q.get(Q.m_curr,.)
		
		par_labels=uniqrows(vec(Q.get(Q.par_labs,.)))
		par_labels=select(par_labels,par_labels:!="")
		if(sum(par_labels:=="c") & rows(par_labels)>3){
			par_labels=par_labels[1::2]\par_labels[rows(par_labels)]\par_labels[3::rows(par_labels)-1]
		}
		if(sum(par_labels:=="b20")){
			pos_b2=select(1::rows(par_labels),par_labels:=="b2")
			pos_b3=select(1::rows(par_labels),par_labels:=="b3")
			par_labels=par_labels[1::pos_b2]\par_labels[pos_b3::rows(par_labels)]\par_labels[pos_b2+1::pos_b3-1]
		}
		if(sum(par_labels:=="b10")){
			pos_b1=select(1::rows(par_labels),par_labels:=="b1")
			pos_b2=select(1::rows(par_labels),par_labels:=="b2")
			par_labels=par_labels[1::pos_b1]\par_labels[pos_b2::rows(par_labels)]\par_labels[pos_b1+1::pos_b2-1]
		}


		n_lab=rows(par_labels)
		par_labels_err="se_":+par_labels
		
		item_parameters=J(I,n_lab,.)
		item_parameters_err=J(I,n_lab,.)
		for(i=1;i<=Q.n;i++){
			i_labels=Q.get(Q.par_labs,i)
			col_indx=select((1::n_lab),rowsum(J(1,cols(i_labels),par_labels):==i_labels))
			item_parameters[i,col_indx']=Q.get(Q.pars,i)
			se_i=Q.get(Q.se,i)
			if(cols(se_i)!=rows(col_indx)){
				se_i=se_i,J(1,rows(col_indx)-cols(se_i),.)
			}
			item_parameters_err[i,col_indx']=se_i
		}
				
		st_matrix("items"+temporary_suffix, item_parameters)
		st_matrixrowstripe("items"+temporary_suffix, (itemlist,models))
		st_matrixcolstripe("items"+temporary_suffix, (J(n_lab,1,""),par_labels))
		
		if(rows(logL)){
			st_matrix("dist"+temporary_suffix, G.get(G.pars,.)')
			st_matrixrowstripe("dist"+temporary_suffix, (J(2,1,""),("mean"\"sd")))
			st_matrixcolstripe("dist"+temporary_suffix, (J(N_gr,1,""),("group" :+ "_":+strofreal(G.get(G.val,.)))))
	
			st_matrix("items_se"+temporary_suffix, item_parameters_err)
			st_matrixrowstripe("items_se"+temporary_suffix, (itemlist,models))
			st_matrixcolstripe("items_se"+temporary_suffix, (J(n_lab,1,""),par_labels_err))
					
			st_matrix("dist_se"+temporary_suffix, G.get(G.se,.)')
			st_matrixrowstripe("dist_se"+temporary_suffix, (J(2,1,""),("se_mean"\"se_sd")))
			st_matrixcolstripe("dist_se"+temporary_suffix, (J(N_gr,1,""),("group" :+ "_":+strofreal(G.get(G.val,.)))))
			
			st_matrix("ll"+temporary_suffix, logL')
			st_matrixrowstripe("ll"+temporary_suffix, ("","logL"))
			st_matrixcolstripe("ll"+temporary_suffix, (J(N_gr,1,""),("group" :+ "_":+strofreal(G.get(G.val,.)))))
			
			st_matrix("item_group_N",Q.get(Q.g_tot,.))
			st_matrixrowstripe("item_group_N",(J(I,1,""),itemlist))
			st_matrixcolstripe("item_group_N",(J(N_gr,1,""),("group" :+ "_":+strofreal(G.get(G.val,.)))))
			
			item_cats=J(I,max(Q.get(Q.n_cat,.)),.)
			for(i=1;i<=I;i++){
				icat_i=*Q.get(Q.p_cat,i)'
				item_cats[i,1..cols(icat_i)]=icat_i
			}
			st_matrix("item_cats",item_cats)
			st_matrixrowstripe("item_cats",(J(I,1,""),itemlist))
			st_matrixcolstripe("item_cats",(J(cols(item_cats),1,""),("cat_":+strofreal((1::cols(item_cats))))) )
			
			st_matrix("group_N",G.get(G.n_total,.)')
			st_matrixrowstripe("group_N",("","N"))
			st_matrixcolstripe("group_N",(J(N_gr,1,""),("group" :+ "_":+strofreal(G.get(G.val,.)))))
		}

	}
			
	void starting_values_logistic(_Q, _G,   real colvector Theta_id, real colvector Theta_dup , pointer matrix point_Uigc, string scalar X_var , real scalar check_a){
		
	
		class ITEMS scalar Q
		Q=_Q

		class GROUPS scalar G
		G=_G
	
		item_group_totalobs=Q.get(Q.g_tot,.)  
	
		I = Q.n
		N_gr = G.n
		
		if(strlen(X_var)==0){
			X_sum		= J(sum(G.get(G.n_uniq,.)),1,0)
			X_max		= J(sum(G.get(G.n_uniq,.)),1,0)
			X_rangestart	= 1		
			for(g=1;g<=N_gr;g++){
				X_rangestop=X_rangestart+G.get(G.n_uniq,g)-1
				
				itemselectrange_g = select((1::I),item_group_totalobs[.,g]:>0)
				
				itemlist_g = Q.get(Q.names,itemselectrange_g)
				item_n_cat_g = Q.get(Q.n_cat,itemselectrange_g)
				I_g = rows(itemlist_g)
				
				
				for(i=1;i<=I_g;i++){
					n_cat = item_n_cat_g[i]
					for(c=1;c<=n_cat;c++){
						category_range = (X_rangestart::X_rangestop)[*(*point_Uigc[i,g])[c]]
						X_max[category_range] = X_max[category_range] :+ (n_cat-1)
						if(c>1){
							X_sum[category_range] = X_sum[category_range] :+ (c-1)
						}
					}
				}
				
				X_rangestart=X_rangestop+1
			}
			
			X	= X_sum :/ X_max
			X	= X[Theta_dup]
			X	= (X:-mean(X)):/sqrt(variance(X))
			
			X_var=st_tempname()
			index_temp=st_addvar("double",X_var)
			st_store(Theta_id,index_temp,X)
			
			X_sum=J(0,0,.)
			X_max=J(0,0,.)		
			X=J(0,0,.)
		}
		
		for(i=1;i<=I;i++){
			
			if(Q.get(Q.n_par,i):!=Q.get(Q.n_par_model,i) & Q.get(Q.init_fail,i)==0){
			
				i_name=Q.get(Q.names,i)
				
				// a remedy for DIF items which are not present in the dataset
				if(_st_varindex(i_name)==.){
					i_name=substr(i_name,1,strlen(i_name)-3)
				}
				
				// 3plm added in case of fixing other-than-c parameters of a 3plm item
				if(  Q.get(Q.m_curr,i)=="3plm" | Q.get(Q.m_curr,i)=="2plm" |  Q.get(Q.m_curr,i)=="grm"){
					stata("cap ologit " + i_name + " " + X_var)
					if(sum(st_matrix("e(V)"))){
					
						pars_curr=Q.get(Q.pars,i)
						
						ologit_coefs = st_matrix("e(b)")
						n_cat = cols(ologit_coefs)
						pars_init = ologit_coefs[1],(ologit_coefs[2..n_cat] :/ ologit_coefs[1])
						for(c=1;c<=cols(pars_curr);c++){
							if(pars_curr[c]==.){
								pars_curr[c]=pars_init[c]
							}
						}
						
						if(pars_curr[1]<0 & check_a){	
							Q.put(Q.init_fail,i,2)
						}
						else{
							Q.put(Q.pars,i,pars_curr)
						}
					}
					else{
						Q.put(Q.init_fail,i,1)
					}
				}
				if( Q.get(Q.m_curr,i)=="gpcm" |  Q.get(Q.m_curr,i)=="pcm"){
					n_cat		= Q.get(Q.n_cat,i)
					item_cats	= *Q.get(Q.p_cat,i)
							
					constraints = ""
					if( Q.get(Q.m_curr,i)=="pcm"){
						stata("constraint define 1000 ["+strofreal(item_cats[2])+"]" + X_var + "=1")
						constraints = constraints + "1000,"
					}
					if(n_cat>2){
						for(c=3;c<=n_cat;c++){
							stata("constraint define "+strofreal(1000+c)+" ["+strofreal(item_cats[2])+"]" + X_var + "=["+strofreal(item_cats[c])+"]" + X_var)
							constraints = constraints + strofreal(1000+c) + ","				
						}
					}
					
					stata("cap mlogit " + i_name + " " + X_var + ", baseoutcome("+strofreal(item_cats[1])+") constraints("+constraints+")")
					if(sum(st_matrix("e(V)"))){
					
						pars_curr=Q.get(Q.pars,i)
					
						mlogit_coefs = st_matrix("e(b)")
						// remedy for problem whem working under lower versions of Stata
						shift=0
						if(rows(st_matrix("e(Cns)"))==0){
							shift=2
						}			
						pars_init = mlogit_coefs[3-shift]
						for(c=2;c<=n_cat;c++){
							pars_init= pars_init,(- mlogit_coefs[2*c-shift]:/mlogit_coefs[3-shift])
						}
						
						for(c=1;c<=cols(pars_curr);c++){
							if(pars_curr[c]==.){
								pars_curr[c]=pars_init[c]
							}
						}

						if(pars_curr[1]<0 & check_a){	
							Q.put(Q.init_fail,i,2)
						}
						else{
							Q.put(Q.pars,i,pars_curr)
						}
					}
					else{
						Q.put(Q.init_fail,i,1)
					}
					if(strlen(constraints)){
						// mlogit adds two additional constraints
						stata("constraint drop "+constraints+"1998,1999")
					}
				}
		
			}
		}
		
		stata("qui drop " + X_var)
		
	}
	
	
	function grm_dummy(real matrix Ui , real scalar max_cat){
		Ui_dummy = J(rows(Ui),max_cat,.)
		for(c=1;c<=max_cat;c++){
			Ui_dummy[.,c] = (Ui :> (c-1))
		}
		return(Ui_dummy)
	}

	
	void starting_values_guess(_Q, _G, real scalar guessing_lrcrit, real matrix f_ik, real matrix p_ik, pointer matrix point_Uigc, pointer matrix point_Fg){

		class ITEMS scalar Q
		Q=_Q

		class GROUPS scalar G
		G=_G
		
		I=Q.n
		N_gr=G.n
		
		// when guessing_lrcrit==1 no LR testing is performed, only lack of convergence can suppress fitting the c parameter	
		if(guessing_lrcrit<1){
			logL_0 = J(N_gr,1,0)
			for(g=1;g<=N_gr;g++){			
				Fg = *point_Fg[g]
				itemselectrange_g=select((1::I),Q.get(Q.g_tot,.)[.,g]:>0)
				Qg=selectQ(Q,Q.get(Q.names,itemselectrange_g))
				Gg=selectG(G,g)
				PXk_Uj = eE_step(Qg, Gg, point_Uigc[.,g])
				logL_0[g] = sum( Fg :* ln(rowsum(PXk_Uj)) )
			}
			logL_0=sum(logL_0)
		}
		
		// absolute difference in easiness based on 2plm and 3plm curve	criterion	
		means_difference_crit=0.3
		
		model_2pl	= ("2plm","2")
		model_3pl	= ("3plm","2")
		failed_list	=""

		class ITEMS scalar Qx
		class ITEMS scalar Q0
		Q0=cloneQ(Q)
		
		for(i=1;i<=I;i++){
			if(Q.get(Q.m_curr,i)=="2plm" & Q.get(Q.m_asked,i)=="3plm"){
			
				if_item_found = 0
				
				pars_i_2pl	= Q.get(Q.pars,i)[1..2]
								
				mean_item_2plm = f_PiXk_01(pars_i_2pl,model_2pl,G.get(G.X_k,1)')*G.get(G.A_k,1)'
				
				if(cols(Q.get(Q.c_prior,i))==2){
					starting_c=(Q.get(Q.c_prior,i)[1]-1)/(sum(Q.get(Q.c_prior,i))-2)
				}
				else{
					starting_c = 0.1
				}

				pars_i_3pl	= pars_i_2pl,starting_c
			
				// reafining ab parameters for given starting_c by ML with c fixed
				KK=cols(G.get(G.X_k,.))
				for(iter=1;iter<=20;iter++){
					PiXk=J(1,0,.)
					for(g=1;g<=N_gr;g++){
						PiXk_g=f_PiXk_01(pars_i_3pl,model_3pl,G.get(G.X_k,g)')
						PiXk=PiXk,PiXk_g
					}
											
					a = pars_i_3pl[1]
					b = pars_i_3pl[2]
					c = pars_i_3pl[3]
			
					V = (PiXk-J(1,N_gr*KK,c)) :/ (PiXk :* J(1,N_gr*KK,1-c))
					VV = V :* V
			
					Fxp_P = f_ik[i,.] :* (p_ik[i,.]-PiXk)
					X_b=J(1,0,.)
					for(g=1;g<=N_gr;g++){
						X_b =X_b , (G.get(G.X_k,g)-J(1,KK,b))
					}
					FxPxQ = f_ik[i,.] :* (PiXk :* (J(1,N_gr*KK,1)-PiXk))
					FxQ=(f_ik[i,.] :* (J(1,N_gr*KK,1)-PiXk)) 
			
					L1 = sum(Fxp_P :* X_b :* V)
					L2 = -a*sum(Fxp_P :* V)
					L11 = -sum(FxPxQ :* (X_b :* X_b) :* VV)
					L22 = -a^2*sum(FxPxQ :* VV)
					L12 = a*sum(FxPxQ :* X_b :* VV)
											
					Jacob = (L1,L2)'
					Fisher = -1*(L11,L12\L12,L22)
					
					if(Q.get(Q.n_fix,i)){
						free	= 1:-Q.get(Q.cns,i)
						Fisher	= Fisher	:*cross(free,free)
						Jacob	= Jacob		:*free'
					}
					
					pars_i_3pl[1..2]=pars_i_3pl[1..2]+(invsym(Fisher)*Jacob)'
				}

				Qx=cloneQ(Q0)
				Qx.put(Qx.m_curr,i,"3plm")
				Qx.put(Qx.n_par_model,i,3)
				Qx.put(Qx.pars,i,pars_i_3pl)
				Qx.put(Qx.cns,i,(Qx.get(Qx.cns,i)[1..2],0))
				Qx.put(Qx.delta, ., (Qx.get(Qx.pars,.)*0) )
				ind_other_i=select((1::I),(1::I):!=i)
				Qx.put(Qx.fix,ind_other_i,Qx.get(Qx.pars,ind_other_i))
				
				for(iter=1;iter<=20;iter++){
					Qx.put(Qx.pars,., ( Qx.get(Qx.pars,.) :+ m_step(Qx, G.get(G.X_k,.)', f_ik, p_ik, J(0,0,.),0) ) )
				}
				
				pars_i_3pl=Qx.get(Qx.pars,i)
				mean_item_3plm = f_PiXk_01(pars_i_3pl,model_3pl,G.get(G.X_k,1)')*G.get(G.A_k,1)'
				
				// testing whether maximisation converges
				if( (abs(mean_item_3plm - mean_item_2plm) < means_difference_crit) & pars_i_3pl[1]>0 & pars_i_3pl[3]>0 & abs(pars_i_3pl[2]-pars_i_2pl[2])<20 & pars_i_3pl[1]<20 ){
					if_item_found=1
				}
				else{
					failed_list=failed_list + " " + Q.get(Q.names,i) + "[conv]"
				}

				if( if_item_found==1){
					if(guessing_lrcrit<1){
						logL = J(N_gr,1,0)
						for(g=1;g<=N_gr;g++){
							Fg = *point_Fg[g]
							itemselectrange_g=select((1::I),Qx.get(Qx.g_tot,.)[.,g]:>0)
							Qg=selectQ(Qx,Qx.get(Qx.names,itemselectrange_g))
							Gg=selectG(G,g)
							PXk_Uj = eE_step(Qg, Gg, point_Uigc[.,g])
							logL[g] = sum( Fg :* ln(rowsum(PXk_Uj)) )
						}
						logL=sum(logL)
						pvalue=1-chi2(1,2*(logL-logL_0))
					}
					else{
						pvalue=0
					}
					
					if(pvalue<guessing_lrcrit){
						Q.put(Q.m_curr,i,"3plm")
						Q.put(Q.n_par_model,i,3)
						Q.put(Q.pars,i,pars_i_3pl)
						Q.put(Q.par_labs,i,("a","b","c"))
						Q.put(Q.delta,i,(pars_i_3pl-(pars_i_2pl,0)))
						Q.put(Q.cns,i,(Q.get(Q.cns,i)[1..2],0))
					}
					else{
						failed_list=failed_list + " " + Q.get(Q.names,i)+"[LR]"
					}	
				}
				
				
			}
		}
		
		if(failed_list!=""){
			display("Note: did not generate starting values for "+strofreal(rows(tokens(failed_list)'))+ " items: "+failed_list)
		}
	}
	
	
	
	
	void print_iter(_Q, _G, real scalar iter, real matrix logL, real scalar trace){
		
		class ITEMS scalar Q
		Q=_Q

		class GROUPS scalar G
		G=_G
	
		if(trace==1){
			printf("ITERATION=%3.0f;logL=%15.4f\n",iter,sum(logL))
		}
		
		
		if(trace==2){
			delta=Q.get(Q.delta,.)
			I=Q.n
			
			index_Xplm=select((1::I),strpos(Q.get(Q.m_curr,.),"plm"))
			index_3plm=select((1::I),strpos(Q.get(Q.m_curr,.),"3plm"))
			index_notXplm=select((1::I),strpos(Q.get(Q.m_curr,.),"plm"):==0)
			
			n_parcols=1+(rows(index_Xplm)>0)+(rows(index_3plm)>0)
			if(rows(index_notXplm)){
				n_parcols=n_parcols+max(Q.get(Q.n_par,index_notXplm))-1
			}
			
			max_cat=max(Q.get(Q.n_cat,.))
			
			item_parameter_labels=J(1,n_parcols,"")
			parmaxs=J(1,n_parcols,.)
			
			count_par=1
			parmaxs[count_par]=max(abs(delta[.,1]))
			item_no=max((abs(delta[.,1]):==parmaxs[count_par]):*(1::I))								
			item_parameter_labels[count_par]="a["+strofreal(item_no)+"]"
			parmaxs[count_par]=delta[item_no,1]
			
			if(rows(index_Xplm)){
				count_par++
				parmaxs[count_par]=max(abs(delta[index_Xplm,2]))
				item_no=max((abs(delta[index_Xplm,2]):==parmaxs[count_par]):*index_Xplm)
				item_parameter_labels[count_par]="b[" + strofreal(item_no) + "]"
				parmaxs[count_par]=delta[item_no,2]
			}
			if(rows(index_3plm)){
				count_par++				
				parmaxs[count_par]=max(abs(delta[index_3plm,3]))
				item_no=max((abs(delta[index_3plm,3]):==parmaxs[count_par]):*index_3plm)
				item_parameter_labels[count_par]="c[" + strofreal(item_no) + "]"
				parmaxs[count_par]=delta[item_no,3]
			}
			if(rows(index_notXplm)){
				for(c=1;c<=max_cat-1;c++){	
					count_par++				
					parmaxs[count_par]=max(abs(delta[index_notXplm,1+c]))
					item_no=max((abs(delta[index_notXplm,1+c]):==parmaxs[count_par]):*index_notXplm)
					item_parameter_labels[count_par]="b" + strofreal(c) + "[" + strofreal(item_no) + "]"
					parmaxs[count_par]=delta[item_no,1+c]
				}
			}
			
			display("______________________________________")
			printf("ITERATION=%3.0f;logL=%15.2f\n",iter,sum(logL))
			display("")
			display("Largest par change")
			stataline1="_col(10) "
			stataline2=char(34)+"Delta"+char(34)+" _col(10) "
			for(i=1;i<=n_parcols;i++){
				stataline1=stataline1+"%10s "+char(34)+item_parameter_labels[i]+char(34)+" _col("+strofreal(10+10*i)+") "
				stataline2=stataline2+"%10.4f "+strofreal(parmaxs[i])+" _col("+strofreal(10+10*i)+") "
			}
			stata("di "+stataline1)
			stata("di "+stataline2)
			display("")
			
			DIST=G.get(G.pars,.)'
			Cns_DIST=G.get(G.cns,.)'
			if(cols(DIST)>1-sum(Cns_DIST[.,1]) & trace){
				display("Parameters by group:")
				stataline3=char(34)+"Parameter"+char(34)+" _col(15) "	
				stataline4=char(34)+"logL"+char(34)+" _col(15) "	
				stataline5=char(34)+"mean"+char(34)+" _col(15) "	
				stataline6=char(34)+"sd"+char(34)+" _col(15) "	
				for(i=1;i<=cols(DIST);i++){
					stataline3=stataline3+"%10s "+char(34)+"Group="+strofreal(G.get(G.val,i))+char(34)+" _col("+strofreal(15+12*i)+") "
					stataline4=stataline4+"%12.2f "+strofreal(logL[i])+" _col("+strofreal(15+12*i)+") "
					stataline5=stataline5+"%10.4f "+strofreal(DIST[1,i])+" _col("+strofreal(15+12*i)+") "
					stataline6=stataline6+"%10.4f "+strofreal(DIST[2,i])+" _col("+strofreal(15+12*i)+") "
				}
				stata("di "+stataline3)
				stata("di "+stataline4)
				stata("di "+stataline5)
				stata("di "+stataline6)
			}
		}
	}
	
 
 	real matrix generate_pv(_Q, _G, real scalar pv, real scalar draw_from_chain, real scalar max_independent_chains, real scalar burn, real matrix Theta_dup, pointer matrix  point_Uigc, pointer matrix point_Fg, string scalar pvreg, real matrix Theta_id, real scalar if_progress, real matrix V){
	
		class ITEMS scalar Q
		Q=_Q
		class GROUPS scalar G
		G=_G
	
		N_gr	= G.n
		I		= Q.n

		//and, unfortunatelly, now we have to uncontract the point_Uigc
		point_Uigc_dup			= J(I,N_gr,NULL)
		total_obs_rangestart	= 1
		group_previousuniqueobs	= 0
		point_uncontracted_group_range	=J(N_gr,1,NULL)
		for(g=1;g<=N_gr;g++){

			itemselectrange_g=select((1::I),Q.get(Q.g_tot,.)[.,g]:>0)
			item_n_cat_g 		= Q.get(Q.n_cat,itemselectrange_g)
			I_g 				= rows(itemselectrange_g)				
			
			total_obs_rangestop					= total_obs_rangestart+G.get(G.n_total,g)-1
			point_uncontracted_group_range[g]	= &(total_obs_rangestart::total_obs_rangestop)
			uncontracted_group_range			= Theta_dup[*point_uncontracted_group_range[g]] :-group_previousuniqueobs
			for(i=1;i<=I_g;i++){
				n_cat	= item_n_cat_g[i]
				U_ig	= J(G.get(G.n_uniq,g),1,.)
				for(c=1;c<=n_cat;c++){
					ord_ic 		= *(*point_Uigc[i,g])[c]
					if(rows(ord_ic)){
						U_ig[ord_ic]= J(rows( ord_ic ),1,c)
					}
				}
				point_Uigc_dup[i,g] = &return_category_range_pointers2((1::n_cat) , U_ig[uncontracted_group_range],total_obs_rangestart-1)
			}
			total_obs_rangestart	= total_obs_rangestart    + G.get(G.n_total,g)
			group_previousuniqueobs	= group_previousuniqueobs + G.get(G.n_uniq,g)
			
		}
		
		PV = J(sum(G.get(G.n_total,.)),pv,.)
		
		long_final_estimates			= create_long_vector(Q,G,"pars")
		estim_range						= select((1::rows(long_final_estimates)),rowsum(V):!=0)
		long_final_estimates_perturbed  = long_final_estimates

		count_pv=0
		if(if_progress){
			if(if_progress==1){
				stata("display "+char(34)+"Generating PVs: 0%"+char(34)+" _c")
			}
			if(if_progress==2){
				stata("display "+char(34)+"Generating PVs for item fit: 0%"+char(34)+" _c")
			}
			previous_progress=0
			progress_counter=0
		}

		// if there is more PVs that the maximum number of independent chains, some pvs will be drawn from the same chain, governed by the draw_from_chain parameter
		if(pv>max_independent_chains){
			max_chain			=	max_independent_chains
			draw_at_chain_ceil	=	ceil(pv/max_independent_chains)
			draw_at_chain_floor	=	floor(pv/max_independent_chains)
			chain_ceilfloor_cut	=	max_chain-mod(pv,max_independent_chains)
		}
		else{
			max_chain=pv
			draw_at_chain_ceil	=	1
			draw_at_chain_floor	=	1
			chain_ceilfloor_cut	=	max_chain
		}

		class ITEMS scalar Qx
		class GROUPS scalar Gx
		
		for(chain=1;chain<=max_chain;chain++){
			
			if(chain>chain_ceilfloor_cut){
				max_i=1+draw_from_chain*(draw_at_chain_ceil-1)
			}
			else{
				max_i=1+draw_from_chain*(draw_at_chain_floor-1)
			}
			
			if_draw_from_chain=0
			
			for(i=1-burn;i<=max_i;i++){
			
				if(if_progress){
					progress_counter=progress_counter+1
					current_progress=100 * progress_counter / ( (chain_ceilfloor_cut)*(burn+1+draw_from_chain*(draw_at_chain_floor-1)) + (max_chain-chain_ceilfloor_cut)*(burn+1+draw_from_chain*(draw_at_chain_ceil-1)) )
					previous_progress=progress(current_progress,previous_progress)
				}
				// this perturbs model parameters so they would involve noise due error of estimation
				// only once a chain
				if(i==(1-burn)){
					// probably need to be adjusted for ordering in grm (is not)
					if(rows(estim_range)>0){
						long_final_estimates_perturbed[estim_range]	= multinormal(long_final_estimates[estim_range]',V[estim_range,estim_range'],1)'
					}
					
					parameters_perturbed	= uncreate_long_vector(Q, G, long_final_estimates_perturbed,0)
					aminus_range			= select(1::I,parameters_perturbed[.,1]:<0)
					if(rows(aminus_range)>0){
						parameters_perturbed[aminus_range,1]=J(rows(aminus_range),1,0.1)
					}
					if(sum(Q.get(Q.m_curr,.):=="3plm")){
						cminus_range			= select(1::I,(parameters_perturbed[.,3]:<0) :* (Q.get(Q.m_curr,.):=="3plm"))
						if(rows(cminus_range)>0){
							parameters_perturbed[cminus_range,3]=J(rows(cminus_range),1,0.01)
						}
						cabove_range			= select(1::I,(parameters_perturbed[.,3]:>1) :* (Q.get(Q.m_curr,.):=="3plm") )
						if(rows(cabove_range)>0){
							parameters_perturbed[cabove_range,3]=J(rows(cabove_range),1,0.99)
						}
					}
					
					Qx=cloneQ(Q)
					Qx.put(Qx.pars,.,parameters_perturbed)

					Gx=cloneG(G)
					Gx.put(Gx.pars,.,uncreate_long_vector(Q, G, long_final_estimates_perturbed,1))
					
					ll_theta_se = return_ll_theta_se(Qx, Gx ,1 ,195, point_Uigc, point_Fg)
					theta_tt 	= (*ll_theta_se[2])[Theta_dup]	
					sd_prop		= (*ll_theta_se[3])[Theta_dup]
					
					prior_mean	=  J(sum(G.get(G.n_uniq,.)),1,.)
					prior_sd 	=  prior_mean
					unique_obs_rangestart = 1
					for(g=1;g<=N_gr;g++){
						unique_obs_rangestop									= unique_obs_rangestart+G.get(G.n_uniq,g)-1
						prior_mean[unique_obs_rangestart::unique_obs_rangestop]	= J(G.get(G.n_uniq,g),1,Gx.get(Gx.pars,g)[1])
						prior_sd[unique_obs_rangestart::unique_obs_rangestop]	= J(G.get(G.n_uniq,g),1,Gx.get(Gx.pars,g)[2])
						unique_obs_rangestart									= unique_obs_rangestop+1
					}
					prior_mean = prior_mean[Theta_dup]
					prior_sd = prior_sd[Theta_dup]	
				}
				
				
				if(pvreg=="." | (i+burn)>ceil(burn/2)){
					theta_tt = mcmc_step(Qx, theta_tt, sd_prop , prior_mean, prior_sd, point_Uigc_dup)
				}
				else{  // MUST be repeated several times, otherwise estimates are biased downwards!!
				
					current_pv_name			= st_tempname()
					current_pv_index		= st_addvar("double",current_pv_name)
					st_store(Theta_id,current_pv_index,theta_tt)

	//xtmixed in Stata 10 does not handle factor notation
					if(stataversion()>=1200){
						statasetversion(stataversion())
					}
					stata("qui xtmixed "+current_pv_name+" "+pvreg+",iter(50)")
					k_random_effects		= st_numscalar("e(k_r)")
					
					current_prior_name		= st_tempname()
					stata("qui predict "+current_prior_name+",fit")
					current_prior_E			= st_data(Theta_id,current_prior_name)
	//				without error of estimation of predictions we would have simply				
	//				prior_mean				= current_prior_E
					stata("qui predict "+current_prior_name+"e0,stdp")
					current_prior_S			= st_data(Theta_id,current_prior_name+"e0")
					if(k_random_effects>1){
						current_prior_S		= current_prior_S:*current_prior_S
						stata("qui predict "+current_prior_name+"e*,reses")
						for(k=1;k<=k_random_effects-1;k++){
							current_prior_S	= current_prior_S :+ st_data(Theta_id,current_prior_name+"e"+strofreal(k)):* st_data(Theta_id,current_prior_name+"e"+strofreal(k))
						}
						current_prior_S		= sqrt(current_prior_S)
					}
					
					statasetversion(1000) // resetting to Stata 1000
					
					prior_ES=(current_prior_E, current_prior_S )
					prior_ES_unique=uniqrows(prior_ES)
					for(p=1;p<=rows(prior_ES_unique);p++){
						if(prior_ES_unique[p,1]!=.){
							E_perturbed = rnormal(1,1,prior_ES_unique[p,1],prior_ES_unique[p,2])
							prior_sel	= select( (1::rows(prior_ES)),rowsum(prior_ES:==prior_ES_unique[p,.]):==2)
							prior_mean[prior_sel] = J(rows(prior_sel),1,E_perturbed)
						}
					}
					
					residuals = theta_tt-prior_mean
										
					stata("qui drop " + current_prior_name+"*")
					
					stata("qui drop " + current_pv_name)
					
					//computing prior_sd from residuals and rescaling the priors to sync with DIST_perturbed
					for(g=1;g<=N_gr;g++){
					
						mean_prior_mean=mean(prior_mean[*point_uncontracted_group_range[g]])
						variance_prior_mean=variance(prior_mean[*point_uncontracted_group_range[g]])
						mean_prior_sd = sqrt(variance(residuals[*point_uncontracted_group_range[g]]))
						rescaling_factor=((Gx.get(Gx.pars,g)[2]^2)/(mean_prior_sd^2+variance_prior_mean))
						prior_mean[*point_uncontracted_group_range[g]]	= (prior_mean[*point_uncontracted_group_range[g]] :- mean_prior_mean):*rescaling_factor :+ Gx.get(Gx.pars,g)[1]
						prior_sd[*point_uncontracted_group_range[g]] = J(Gx.get(Gx.n_total,g),1, mean_prior_sd * rescaling_factor )

					}

					theta_tt = mcmc_step(Qx, theta_tt, sd_prop , prior_mean, prior_sd, point_Uigc_dup)
					
				}
				
				
				if(i>0){
					if_draw_from_chain=if_draw_from_chain+1
					if(if_draw_from_chain==draw_from_chain | i==1){
						count_pv=count_pv+1
						PV[.,count_pv] = theta_tt
						if_draw_from_chain=0
					}
				}	
			}
		}
		return(PV)
	}

	
	real colvector mcmc_step(_Qx, real matrix theta_t, real matrix sd_prop , real matrix prior_mean, real matrix prior_sd, pointer matrix point_Uigc_dup){

		class ITEMS scalar Qx
		Qx=_Qx
			
		J=rows(theta_t)
		
		theta_tt = rnormal(1,1,theta_t,sd_prop)
		
		L_tt	= likelihood(Qx,theta_tt, point_Uigc_dup) :* normalden(theta_tt,prior_mean,prior_sd)
		L_t		= likelihood(Qx,theta_t, point_Uigc_dup) :* normalden(theta_t,prior_mean,prior_sd)
				
		alpha = rowmin( ( J(J,1,1) , (L_tt :/ L_t) ) )
		Uni=runiform(J,1)
		theta_tt_select=select((1::J), Uni :> alpha )
		if(rows(theta_tt_select)){
			theta_tt[theta_tt_select]=theta_t[theta_tt_select]
		}
				
		return(theta_tt)

	}
	
	real colvector likelihood(_Qx, real colvector theta, pointer matrix point_Uigc_dup){

		class ITEMS scalar Qx
		Qx=_Qx

		N_gr=cols(point_Uigc_dup)
		
		L=J(rows(theta),1,1)
		
		class ITEMS scalar Qg
		
		for(g=1;g<=N_gr;g++){
			
			itemselectrange_g=select((1::Qx.n),Qx.get(Qx.g_tot,.)[.,g]:>0)
			
			Qg				= cloneQ(selectQ(Qx,Qx.get(Qx.names,itemselectrange_g)))
			I_g				= Qg.n
		
			for(i=1;i<=I_g;i++){
				n_cat = Qg.get(Qg.n_cat,i)
				model = Qg.get(Qg.m_curr,i)
				pars_i= Qg.get(Qg.pars,i)
				if(n_cat==2){
					ord_i0		= (*(*point_Uigc_dup[i,g])[1])
					ord_i1		= (*(*point_Uigc_dup[i,g])[2])
					if(model=="2plm" | model=="pcm"){
						if(rows(ord_i0)){ // in case of fixing and missing
							L_i0	= 1 :- (invlogit(pars_i[1] :* (theta[ord_i0] :- pars_i[2])))
						}
						if(rows(ord_i1)){ // in case of fixing and missing
							L_i1	= invlogit(pars_i[1] :* (theta[ord_i1] :- pars_i[2]))				
						}
					}
					if(model=="3plm"){
						if(rows(ord_i0)){ // in case of fixing and missing
							L_i0	= 1 :- (invlogit(pars_i[1] :* (theta[ord_i0] :- pars_i[2])) :* (1-pars_i[3]) :+ pars_i[3])
						}
						if(rows(ord_i1)){ // in case of fixing and missing
							L_i1	= invlogit(pars_i[1] :* (theta[ord_i1] :- pars_i[2])) :* (1-pars_i[3]) :+ pars_i[3]
						}
					}
					if(rows(ord_i0)){ // in case of fixing and missing
						L[ord_i0]	= L[ord_i0] :* L_i0
					}
					if(rows(ord_i1)){ // in case of fixing and missing
						L[ord_i1]	= L[ord_i1] :* L_i1
					}

				}
				else{				
					if(model=="grm"){
						for(c=1;c<=n_cat;c++){
							ord_ic = (*(*point_Uigc_dup[i,g])[c])
							if(rows(ord_ic)){ // in case of fixing and missing
								if(c == 1){
									L_ic = 1 :- invlogit(pars_i[1] :* (theta[ord_ic] :- pars_i[2]))
								}
								if(c == n_cat){
									L_ic = invlogit(pars_i[1] :* (theta[ord_ic] :- pars_i[n_cat]))
								}
								if(c>1 & c<n_cat){
									L_ic = invlogit(pars_i[1] :* (theta[ord_ic] :- pars_i[c]))  :- invlogit(pars_i[1] :* (theta[ord_ic] :- pars_i[1+c]))
								}
								L[ord_ic]=L[ord_ic] :* L_ic
							}
						}
					}
					if(model=="gpcm" | model=="pcm"){
						for(c=1;c<=n_cat;c++){
							ord_ic = (*(*point_Uigc_dup[i,g])[c])
							if(rows(ord_ic)){ // in case of fixing and missing
								expsum_all = 1
								for(cc=2;cc<=n_cat;cc++){
									expsum_all = expsum_all :+ exp(pars_i[1] :* ( (cc-1) :* theta[ord_ic] :- sum(pars_i[2..cc]) ) )
								}
								if(c == 1){
									L_ic = 1 :/ expsum_all
								}
								else{
									L_ic = exp( pars_i[1] :* ( (c-1) :* theta[ord_ic] :- sum(pars_i[2..c]) ) ) :/ expsum_all
								}
								L[ord_ic]=L[ord_ic] :* L_ic
							}
						}					
					}
				}
			}
		}
			
		return(L)	
	}
	
	
	function Pj_centile_pv(_Q, _G, real matrix if_makeicc, real matrix Theta_dup, pointer matrix point_Uigc, pointer matrix point_Fg, real scalar icc_pvbin, real scalar icc_bins, real matrix V){
	
		class ITEMS scalar Q
		Q=_Q
		class GROUPS scalar G
		G=_G
	
		N_pv_max	= 10000
		min_ig_obs	= min(rowsum(select(Q.get(Q.g_tot,.),if_makeicc)))
		N_pv		= ceil( (icc_pvbin * icc_bins) / min_ig_obs )

		if(N_pv>N_pv_max){
			N_pv	=  N_pv_max
			icc_pvbin_reduced=round( (N_pv * min_ig_obs) / icc_bins ,0.1)
			display("Note: minimum number of observations for an item is "+strofreal(min_ig_obs)+" so icc_pvbin() was reduced to " +strofreal(icc_pvbin_reduced))
		}
	
		// very small burn assuming that stationary distribution is obtained right away, due to starting point at eap,se_eap
		burn=10		
		draw_from_chain=1			
		max_independent_chains=20
		
		PV = generate_pv(Q, G, N_pv, draw_from_chain, max_independent_chains, burn, Theta_dup, point_Uigc, point_Fg, ".", J(0,0,.), 2, V)

		J_all=rows(PV)
		
		X_low = J(icc_bins,1,.)
		X_up = J(icc_bins,1,.)
		X_low[1,1] = -1000
		X_up[icc_bins,1] = 1000 
		for(i=1;i<=icc_bins-1;i++){
			X_low[i+1,1]=invnormal(i/icc_bins)
			X_up[i,1]=X_low[i+1,1]
		}

		Pj_centile_all=J(J_all,icc_bins,0)
		
		for(i=1;i<=icc_bins;i++){
			Pj_centile_all[.,i] = rowsum((X_low[i,1] :< PV ) :* (PV :<= X_up[i,1])) :/ N_pv
		}
		
		N_gr=G.n
		F=J(0,1,.)
		for(g=1;g<=N_gr;g++){
			F=F\(*point_Fg[g])
		}
		
		Pj_centile=J(rows(F),icc_bins,0)
		up=0
		for(j=1;j<=rows(F);j++){		
			low=up+1
			up=up+F[j]
					
			if((up-low)){
				Pj_centile[j,.]=mean(Pj_centile_all[(low::up),.])
			}
			else{
				Pj_centile[j,.]=Pj_centile_all[low,.]			
			}
		}
		
		return(Pj_centile)
	}

	
	pointer PXk_Uj_all(_Q, _Gx, pointer matrix point_Uigc){
		
		class ITEMS scalar Q
		Q=_Q
		class GROUPS scalar Gx
		Gx=_Gx
	
		I=Q.n
		N_gr=Gx.n

		nip=cols(Gx.get(Gx.X_k,.))
		PXk_Uj_all	=J(sum(Gx.get(Gx.n_uniq,.)),nip,1)
		
		class ITEMS scalar Qg
		class GROUPS scalar Gg
				
		range_start=1
		range_stop=0
		for(g=1;g<=N_gr;g++){
		
				range_stop=range_stop+Gx.get(Gx.n_uniq,g)
		
				itemselectrange_g=select((1::I),Q.get(Q.g_tot,.)[.,g]:>0)
			
				Qg=cloneQ(selectQ(Q,Q.get(Q.names,itemselectrange_g)))
				Gg=cloneG(selectG(Gx,g))

				PXk_Uj_all[range_start::range_stop,.]= *( PXk_Uj_fit_g(Qg, Gg, point_Uigc[.,g], 0)[1] )
				
				range_start=range_stop+1
		}
		
		results=J(1,1,NULL)
		results[1]=return_pointer(PXk_Uj_all)
		return(results)
		
	}	
	

	function Pj_centile_integrated(_Q, _G, pointer matrix point_Uigc, real scalar icc_bins){
	
		class ITEMS scalar Q
		Q=_Q
		class GROUPS scalar G
		G=_G
		
		class GROUPS scalar Gx
		Gx=cloneG(G)
		nip=151
		quad_GH	= get_quad_GH(nip,Gx.get(Gx.pars,.))
		Gx.put(Gx.X_k,.,*quad_GH[1])
		Gx.put(Gx.A_k,.,*quad_GH[2])
			
		P_all=	rowsum( *( PXk_Uj_all(Q, Gx, point_Uigc)[1] ) )
		
		borders_icc=-100,invnormal((1..icc_bins-1):/icc_bins),100
		
		K=31
		Pj_centile=J(rows(P_all),icc_bins,.)
		for(d=1;d<=icc_bins;d++){
		
			U	=	borders_icc[d+1]
			L	=	borders_icc[d]
			
			quad_GL	= get_quad_GL(U, L, K, Gx.get(Gx.pars,.))
			Gx.put(Gx.X_k,.,*quad_GL[1])
			Gx.put(Gx.A_k,.,*quad_GL[2])
			
			Pj_centile[.,d]= rowsum( *( PXk_Uj_all(Q, Gx, point_Uigc)[1] ) )
			
		}
	
		Pj_centile=Pj_centile:/P_all
		
		return(Pj_centile)
	}
	
	
	void starting_values_fixORinit(_Q, string scalar fiximatrix, string scalar initimatrix, real scalar if_comment){
	
		class ITEMS scalar Q
		Q=_Q
		
		I			= Q.n
		itemlist	= Q.get(Q.names,.)
					
		if(initimatrix!=""){
			saved_init_rown=st_matrixrowstripe(initimatrix)
			saved_init_coln=st_matrixcolstripe(initimatrix)[.,2]
			saved_init_iprs=st_matrix(initimatrix)
			
			shift=(sum(saved_init_coln:=="b")>0)+(sum(saved_init_coln:=="c")>0)
			
			for(i=1;i<=I;i++){
				sel = select( (1::rows(saved_init_rown)) ,saved_init_rown[.,1]:==itemlist[i])
				if(rows(sel)){
					if(nonmissing(saved_init_iprs[sel,.])){
						if(saved_init_rown[sel,2]=="2plm"){
							Q.put(Q.init,i,saved_init_iprs[sel,1..2])
							Q.put(Q.m_curr,i,"2plm")
							Q.put(Q.m_asked,i,"2plm")
						}
						if(saved_init_rown[sel,2]=="3plm"){
							Q.put(Q.init,i,saved_init_iprs[sel,1..3])
							if(saved_init_iprs[sel,3]!=.){
								Q.put(Q.m_curr,i,"3plm")
							}
							else{
								Q.put(Q.m_curr,i,"2plm")
							}
							Q.put(Q.m_asked,i,"3plm")
						}
						if(saved_init_rown[sel,2]!="2plm" & saved_init_rown[sel,2]!="3plm"){
							temp=saved_init_iprs[sel,.]'
							stop_b=max(select(strtoreal(subinstr(saved_init_coln,"b","")),temp!=.))+1+shift
							if(stop_b==.){
								Q.put(Q.init,i,saved_init_iprs[sel,1])
							}
							else{
								Q.put(Q.init,i,(saved_init_iprs[sel,1],saved_init_iprs[sel,2+shift..stop_b]))
							}
							Q.put(Q.m_curr,i,saved_init_rown[sel,2])
							Q.put(Q.m_asked,i,saved_init_rown[sel,2])
						}
					}
				}
			}
		}
		
		
		if(fiximatrix!=""){
			saved_fix_rown=st_matrixrowstripe(fiximatrix)
			saved_fix_coln=st_matrixcolstripe(fiximatrix)[.,2]
			saved_fix_iprs=st_matrix(fiximatrix)
			
			shift=(sum(saved_fix_coln:=="b")>0)+(sum(saved_fix_coln:=="c")>0)
			
			for(i=1;i<=I;i++){
				sel = select( (1::rows(saved_fix_rown)) ,saved_fix_rown[.,1]:==itemlist[i])
				if(rows(sel)){
					if(nonmissing(saved_fix_iprs[sel,.])){
						if(saved_fix_rown[sel,2]=="2plm"){
							Q.put(Q.fix,i,saved_fix_iprs[sel,1..2])
							Q.put(Q.m_curr,i,"2plm")
							Q.put(Q.m_asked,i,"2plm")
						}
						if(saved_fix_rown[sel,2]=="3plm"){
							Q.put(Q.fix,i,saved_fix_iprs[sel,1..3])
							if(saved_fix_iprs[sel,3]!=.){
								Q.put(Q.m_curr,i,"3plm")
							}
							else{
								Q.put(Q.m_curr,i,"2plm")
							}
							Q.put(Q.m_asked,i,"3plm")
						}
						if(saved_fix_rown[sel,2]!="2plm" & saved_fix_rown[sel,2]!="3plm"){
							temp=saved_fix_iprs[sel,.]'
							stop_b=max(select(strtoreal(subinstr(saved_fix_coln,"b","")),temp!=.))+1+shift
							if(stop_b==.){
								Q.put(Q.fix,i,saved_fix_iprs[sel,1])
							}
							else{
								Q.put(Q.fix,i,(saved_fix_iprs[sel,1],saved_fix_iprs[sel,2+shift..stop_b]))
							}
							Q.put(Q.m_curr,i,saved_fix_rown[sel,2])
							Q.put(Q.m_asked,i,saved_fix_rown[sel,2])
						}
					}
				}
			}
		}
		
					

	// fixing clears initiating
		item_fix_init_left_strlist	= J(3,1,"")
		for(i=1;i<=I;i++){
			if(Q.get(Q.n_fix,i)){
				Q.put( Q.pars, i, Q.get(Q.fix,i) )	
			}
			if(Q.get(Q.n_init,i)){
				if(Q.get(Q.n_fix,i)){
					len_f=cols(Q.get(Q.fix,i))
					len_i=cols(Q.get(Q.init,i))
					if(len_f>len_i){
						temp=Q.get(Q.init,i)
						temp=temp,J(1,len_f-len_i,.)
						Q.put(Q.init,i,temp)
					}
					if(len_f<len_i){
						temp=Q.get(Q.fix,i)
						temp=temp,J(1,len_i-len_f,.)
						Q.put(Q.fix,i,temp)	
					}
					temp_f=Q.get(Q.fix,i)
					temp_i=Q.get(Q.init,i)
					for(p=1;p<=cols(temp_f);p++){
						if(temp_f[p]==.){
							temp_f[p]=temp_i[p]
						}
						else{
							temp_i[p]=.
						}
					}
					Q.put( Q.pars, i, temp_f )
					Q.put( Q.init, i, temp_i )
				}
				else{
					Q.put( Q.pars, i, Q.get(Q.init,i) )
				}
			}
			
			if(Q.get(Q.n_fix,i)){
				item_fix_init_left_strlist[1] = item_fix_init_left_strlist[1]+" "+itemlist[i]
			}
			if(Q.get(Q.n_init,i)){
				item_fix_init_left_strlist[2] = item_fix_init_left_strlist[2]+" "+itemlist[i]
			}
			if(Q.get(Q.n_fix,i)==0 & Q.get(Q.n_init,i)==0){
				item_fix_init_left_strlist[3] = item_fix_init_left_strlist[3]+" "+itemlist[i]	
			}
		}		

		
		// posting comments
		if(if_comment){
			fix_sum = cols(tokens(item_fix_init_left_strlist[1]))
			init_sum = cols(tokens(item_fix_init_left_strlist[2]))
			
			if(fiximatrix!=""){
				if(fix_sum){
					display(strofreal( sum(Q.get(Q.n_fix,.)) )+" parameters of "+strofreal(fix_sum)+" requested items were found in "+fiximatrix+" matrix; uirt will set them fixed:")
					display(item_fix_init_left_strlist[1])
				}
				else{
					display("Note: no parameters for requested items found in "+fiximatrix+" matrix")
				}
			}
			
			if(initimatrix!=""){
				if(init_sum){
					if(fix_sum){
						display(strofreal( sum(Q.get(Q.n_init,.)) )+" additional initial parameters of "+strofreal(init_sum)+" requested items were found in "+initimatrix+" matrix:")
					}
					else{
						display(strofreal( sum(Q.get(Q.n_init,.)) )+" initial parameters of "+strofreal(init_sum)+" requested items were found in "+initimatrix+" matrix:")
					}
					display(item_fix_init_left_strlist[2])			
				}
				else{
					if(fix_sum){
						display("Note: no additional parameters found for requested items in "+initimatrix+" matrix")
					}
					else{
						display("Note: no parameters for requested items found in "+initimatrix+" matrix")
					}
				}
			}
			
			if(fiximatrix!=""|initimatrix!=""){
				if((fix_sum + init_sum)<I){
					display("parameters for remaining "+strofreal(I-(fix_sum + init_sum))+" requested items were not found:")
					display(item_fix_init_left_strlist[3])
					display("Note: uirt will try to initiate any remaining item parameters by defaults")
				}
			}
		}
	}

	
	pointer get_quad_GH(real scalar nip, real matrix DIST){
		if(stataversion()>=1200){
			temp=_gauss_hermite_nodes(nip)
			XGH_k=temp[1,.]
			AGH_k=temp[2,.]
		}
		else{
			N=st_nobs()
			if(nip>N){
				st_addobs(nip-N)
			}
			x_name=st_tempname()
			a_name=st_tempname()
			index=st_addvar("double",(x_name,a_name))
			stata("_GetQuad, avar("+x_name+") wvar("+a_name+") quad("+strofreal(nip)+")")
			XGH_k = st_data((nip::1),x_name)'
			AGH_k = st_data((nip::1),a_name)'
			if(nip>N){
				stata("qui drop in "+strofreal(N+1)+"/"+strofreal(nip))
			}
			stata("qui drop "+x_name+" "+a_name)
		}
		X_k0 = (XGH_k*2^0.5)
		A_k0 = (AGH_k/pi()^0.5)

		A_k = J(rows(DIST),1,A_k0)
		X_k = J(rows(DIST),nip,.)
		for(g=1;g<=rows(DIST);g++){
			X_k[g,.]=X_k0:*DIST[g,2]:+DIST[g,1]			
		}
		
		results=J(2,1,NULL)
		results[1]=return_pointer(X_k)
		results[2]=return_pointer(A_k)
		return(results)
	}		

	function return_pointer(transmorphic matrix input_matrix){
		return(	&input_matrix )
	}
		
	function return_range_pointer( real scalar range_end, real matrix logical_vector){
		return(	&select(1::range_end,logical_vector)	)
	}	

	
	pointer colvector return_category_range_pointers(real colvector item_cats, real colvector item_obs){
		range_end 		= rows(item_obs)
		pointer_vector	= J(rows(item_cats),1,NULL)
		for(i=1;i<=rows(item_cats);i++){
			pointer_vector[i] = return_range_pointer(range_end , item_obs :== item_cats[i] )
		}
		return(pointer_vector)
	}
	
	
	function return_range_pointer2(real scalar range_end, real matrix logical_vector,real scalar shift){
		return(	&(select(1::range_end,logical_vector):+shift)	)
	}
	
	
	pointer colvector return_category_range_pointers2(real colvector item_cats, real colvector item_obs, real scalar shift){
		range_end		= rows(item_obs)
		pointer_vector	= J(rows(item_cats),1,NULL)
		for(i=1;i<=rows(item_cats);i++){
			pointer_vector[i] = return_range_pointer2(range_end , item_obs :== item_cats[i] ,shift)
		}
		return(pointer_vector)
	}

	
	function restrict_point_Uigc(real matrix item_range, real matrix item_group_totalobs,  pointer matrix point_Uigc){
	 
	 	point_Uigc_restricted=J(rows(point_Uigc),cols(point_Uigc),NULL)
	 	N_gr=cols(item_group_totalobs)
	 	I=rows(item_group_totalobs)
	 	for(g=1;g<=N_gr;g++){
	 		point_Uigc_G=J(0,1,NULL)
	 		for(i=1;i<=I;i++){
		 		if(item_group_totalobs[i,g]>0 & sum(item_range:==i)>0){
		 			i_g = sum(item_group_totalobs[1::i,g]:>0)
		 			point_Uigc_G=point_Uigc_G\point_Uigc[i_g,g]
		 		}
		 	}
		 	if(rows(point_Uigc_G)){
		 		point_Uigc_restricted[1::rows(point_Uigc_G),g]=point_Uigc_G
		 	}
	 	}
	 	return(point_Uigc_restricted)
	 }
	
	
	function return_group_item_info(_Q,string scalar catimatrix, string scalar touse, string scalar group, real scalar ref){
	
		class ITEMS scalar Q
		Q=_Q
		
		
		N_itms			= Q.n
		itemlist	= Q.get(Q.names,.)
		items=""
		for(i=1;i<=N_itms;i++){
			items=items+" "+itemlist[i]			
		}
		
		N_obs = st_nobs()
		range1_N_obs = (1::N_obs)
				
		if(group=="."){

			group_vals = J(1,1,1)
			group_labels = J(1,1,"0")
			N_gr = 1
			group_rec_data = J(N_obs,1,1)
			group_missingallitems_tempvar=st_tempname()
			stata("qui egen "+group_missingallitems_tempvar+"=rownonmiss("+items+")")
			select_missingallitems_group = select(range1_N_obs , (st_data(.,group_missingallitems_tempvar):== 0) + (st_data(.,touse):== 0))		
			stata("qui drop " + group_missingallitems_tempvar)
			if(rows(select_missingallitems_group)){
				group_rec_data[select_missingallitems_group] = J(rows(select_missingallitems_group),1,.)
				st_store(select_missingallitems_group,touse,J(rows(select_missingallitems_group),1,0))
			}
			select_missingallitems_group = J(0,0,.)
			
		}
		else{
			group_org_data = st_data(.,group)
			group_vals = uniqrows(select(group_org_data,st_data(.,touse):== 1))
			group_vals = select(group_vals,group_vals :< .)
			N_gr = rows(group_vals)	


			if(ref != . & N_gr>1){
				group_vals = ref \ sort( select(group_vals , group_vals :!= ref) , 1 )
			}
			else{
				group_vals = sort(group_vals,1)
			}
			
			stata("local gr_labelname: val l "+group)
			if(strlen(st_local("gr_labelname"))){
				group_labels=st_vlmap(st_local("gr_labelname"),group_vals)
				for(g=1;g<=N_gr;g++){
					if(strlen(group_labels[g])==0){
						group_labels[g]=strofreal(group_vals[g])
					}
				}
			}
			else{
				group_labels="_":+strofreal(group_vals)
			}
			group_labels[1]="[ref] "+group_labels[1]
			
			group_rec_data = J(N_obs,1,.)
			for(g=1;g<=N_gr;g++){
				index_g = select( range1_N_obs ,  group_org_data :== group_vals[g])
				group_rec_data[index_g] = J(rows(index_g),1,g)
			}
			group_org_data = J(0,0,.)
			index_g = J(0,0,.)
			
			group_missingallitems_tempvar=st_tempname()
			stata("qui egen "+group_missingallitems_tempvar+"=rownonmiss("+items+")")
			select_missingallitems_group = select(range1_N_obs , (st_data(.,group_missingallitems_tempvar):== 0) + (st_data(.,touse):== 0))		
			stata("qui drop " + group_missingallitems_tempvar)
			if(rows(select_missingallitems_group)){
				group_rec_data[select_missingallitems_group] = J(rows(select_missingallitems_group),1,.)
				st_store(select_missingallitems_group,touse,J(rows(select_missingallitems_group),1,0))
			}
			select_missingallitems_group = J(0,0,.)
					
		}
				

		point_obs_g=J(N_gr,1,NULL)
		for(g=1;g<=N_gr;g++){
			point_obs_g[g] = return_pointer(select(range1_N_obs,group_rec_data:==g))
		}
		range_groupnonmissing = select(range1_N_obs,group_rec_data:!=.)

		if(catimatrix!=""){
			icats_rown=st_matrixrowstripe(catimatrix)[.,2]
			icats_val=st_matrix(catimatrix)
		}
		else{
			icats_rown=""
		}
		
		item_n_cat = J(N_itms,1,0)
		point_item_cats = J(N_itms,1,NULL)
		item_group_totalobs = J(N_itms, N_gr, 0)
		for(i=1;i<=N_itms;i++){
		
			U_i_all = st_data(.,itemlist[i])	
		
			sel=select((1::rows(icats_rown)),icats_rown:==itemlist[i])
			if(rows(sel)==1){
				item_cats=select(icats_val[sel,.]',icats_val[sel,.]':<.)
			}
			else{
				
				if(Q.get(Q.n_fix,i)==0){
					item_cats = uniqrows(U_i_all[range_groupnonmissing])
					item_cats = select(item_cats,item_cats:<.)
				}
				else{
					if( Q.get(Q.m_curr,i)=="2plm" | Q.get(Q.m_curr,i)=="3plm"){
						item_cats = (0::1)
					}
					else{
						item_cats = (0::cols(Q.get(Q.fix,i))-1)
					}
					Q.put(Q.warning_cats,i,1)
				}
			}
			item_n_cat[i] = rows(item_cats)
			if(rows(item_cats)>0){
				point_item_cats[i] = return_pointer(item_cats[.])
				for(g=1;g<=N_gr;g++){
					item_group_totalobs[i,g] = sum( (J(1,item_n_cat[i],U_i_all[(*point_obs_g[g])]):==item_cats') )
				}
			}
			else{
				point_item_cats[i] = return_pointer(.)
				for(g=1;g<=N_gr;g++){
					item_group_totalobs[i,g] = 0
				}
			}
			

		}
		
		
		Q.put(Q.n_cat,.,item_n_cat)
		Q.put(Q.g_tot,.,item_group_totalobs)
		Q.put(Q.p_cat,.,point_item_cats)
		
		dropped_items_miss=select((1::N_itms),   (rowsum(item_group_totalobs):==0) )
		if(rows(dropped_items_miss)){
			Q.put(Q.init_fail, dropped_items_miss, J(rows(dropped_items_miss),1,3) )
		}
		dropped_items_zerovar=select((1::N_itms),   (item_n_cat:==1):*(Q.get(Q.n_fix,.):==0) )
		if(rows(dropped_items_zerovar)){
			Q.put(Q.init_fail, dropped_items_zerovar, J(rows(dropped_items_zerovar),1,4) )
		}
		
		class GROUPS scalar G		
		
		G.populate(group_vals)
		G.put(G.label,.,group_labels)
		G.data=group_rec_data
		G.v_name=group
		
		return(G)
		
	}
	
	
// display progress	
	function progress(real scalar current_progress,real scalar previous_progress){
		current_progress=floor(current_progress)
		while(current_progress>=previous_progress+2){
			previous_progress=previous_progress+2
			if(previous_progress/10==floor(previous_progress/10)){
				if(previous_progress<100){
					stata("display "+char(34)+strofreal(previous_progress)+"%"+char(34)+" _c")
				}
				else{
					stata("display "+char(34)+strofreal(previous_progress)+"%"+char(34))
				}
			}
			else{
				stata("display "+char(34)+"."+char(34)+" _c")
			}
		}
		return(previous_progress)
	}

	real matrix multinormal(real rowvector mu, real matrix sigma, real scalar obs){
		return(mu:+ (cholesky(sigma)*rnormal(rows(sigma),obs,0,1))')
	}	
	
	
	function verify_isnumvar(string scalar items){
		itemlist	= tokens(items)'
		notoklist		=""
		for(i=1;i<=rows(itemlist);i++){
			if(st_isnumvar(itemlist[i])==0){
				notoklist	= notoklist+" "+itemlist[i]
			}
		}
		return(notoklist)
	}

	function verify_dupvars(string scalar items){
		itemlist		= tokens(items)'
		uniq_itemlist	= uniqrows(itemlist)
		duplist			= ""
		for(i=1;i<=rows(uniq_itemlist);i++){
			s=sum(itemlist:==uniq_itemlist[i])
			if(s>1){
				duplist=duplist+" "+uniq_itemlist[i]+"(x"+strofreal(s)+")"
			}
		}
		return(duplist)
	}

	function verify_thetaexist(string matrix theta_names){
		existlist=""
		if(_st_varindex(theta_names[1])<.){
			existlist=existlist+" "+theta_names[1]
		}
		if(_st_varindex(theta_names[2])<.){
			existlist=existlist+" "+theta_names[2]
		}
		return(existlist)
	}
	
	
	function verify_pvexist(real scalar pv, string scalar theta_suffix){
		existlist=""
		if(theta_suffix=="."){
			s=sum(_st_varindex( ("pv_":+strofreal((1..pv))) ):<.)
			if(s){
				existlist=existlist+"pv_.. (x"+strofreal(s)+")"
			}
		}
		else{
			s=sum(_st_varindex( ("pv_":+strofreal((1..pv)):+"_":+theta_suffix) ):<.)
			if(s){
				existlist=existlist+"pv_.._"+theta_suffix+" (x"+strofreal(s)+")"
			}
		}
		return(existlist)
	}
	
	
	function compare_varlist(string scalar items1, string scalar items2){
		itemlist1		= tokens(items1)'
		itemlist2		= tokens(items2)'
		common_list		=""
		common_n		=0
		missin1_list	=""
		missin1_n		=0
		for(i=1;i<=rows(itemlist2);i++){
			s=sum(itemlist1:==itemlist2[i])
			if(s==0){
				missin1_list	= missin1_list+" "+itemlist2[i]
				missin1_n		= missin1_n+1		
			}
			else{
				common_list		= common_list+" "+itemlist2[i]
				common_n		= common_n+1
			}
		}
		results = J(4,1,NULL)
		results[1] = &common_list
		results[2] = &strofreal(common_n)
		results[3] = &missin1_list
		results[4] = &strofreal(missin1_n)
		return(results)
	}
	
// FIT functions
	void SX2(_Q, _Gx, real scalar sx2_min_freq, pointer matrix point_Uigc, pointer matrix point_Fg){
	
		class ITEMS scalar Q
		Q=_Q
		class GROUPS scalar Gx
		Gx=_Gx
	
		I=Q.n
		item_indx=select((1::I),Q.get(Q.fit_sx2,.))
		I_fit=rows(item_indx)
		
		S=sx2_S(Q.get(Q.viable_sx2,.), point_Uigc, point_Fg)
		
		for(i=1;i<=I_fit;i++){
		
			LW_results=sx2_lord_wingersky(Q, Gx,  item_indx[i])
			Eik_i=*LW_results[1]
			Sk_all_i=*LW_results[2]
			
			collapse_cats_results=sx2_collapse_cats(Eik_i,Sk_all_i,sx2_min_freq, sum(*point_Fg[1]))
			Eik=*collapse_cats_results[1]
			score_range=*collapse_cats_results[2]
			
			n_est_par	= Q.get(Q.n_par,item_indx[i]):-Q.get(Q.n_fix,item_indx[i])

			SX2_item_results	=	sx2_orlando_thissen(item_indx[i], Eik, score_range, S, n_est_par, point_Uigc, point_Fg)
			
			Q.put(Q.SX2_res, item_indx[i], (*SX2_item_results[1],*SX2_item_results[2],*SX2_item_results[3],n_est_par) )

		}
			
	}
	

	pointer sx2_orlando_thissen(real scalar item_for_fit, real matrix Eik, real matrix score_range, real matrix S, real scalar n_est_par, pointer matrix point_Uigc, pointer matrix point_Fg ){
	
		obs_i=J(rows(*point_Fg[1]),1,0)
		ord_ic = (*(*point_Uigc[item_for_fit,1])[2])
		if(rows(ord_ic)){
			obs_i[ord_ic]=J(rows(ord_ic),1,1)
		}
		
		Oik=J(rows(Eik),1,0)
		Nik=J(rows(Eik),1,0)
		for(i=1;i<=rows(Eik);i++){
			sel_i=select((1::rows(obs_i)), (S:>=score_range[i,1] ):* (S:<=score_range[i,2] ))
			if(rows(sel_i)){
				Nik[i]=sum((*point_Fg[1])[sel_i])
				Oik[i]=cross( (*point_Fg[1])[sel_i] , obs_i[sel_i])/ Nik[i]
			}
		}
		
		SX2=sum(( Nik:*(Oik:-Eik):*(Oik:-Eik)):/(Eik:*(1:-Eik)))
		
		df=rows(Eik)-n_est_par
		
		pvalue=(1:-chi2(df,SX2))
		
		results=J(5,1,NULL)
		results[1]=return_pointer(SX2)
		results[2]=return_pointer(pvalue)
		results[3]=return_pointer(df)
		results[4]=return_pointer(Oik)
		results[5]=return_pointer(Nik)
		
		return(results)
	
	}	
	
	pointer sx2_collapse_cats(real matrix Eik_in, real matrix Sk_all_in, real scalar sx2_min_freq, real scalar N_obs){
	
		Eik=Eik_in
		Sk_all=Sk_all_in
		N=N_obs
		
		warning=""

		N=N-N*(Sk_all[1]+Sk_all[rows(Sk_all)])
		Sk_all=Sk_all[2::rows(Sk_all)-1]
		
		n_sc=rows(Sk_all)
		score_range=(1::n_sc),(1::n_sc)
		exp_freq_1=N:*Sk_all:*Eik
		for(i=1;i<=n_sc;i++){
			if(exp_freq_1[i]<sx2_min_freq){
				if(rows(score_range)>2){
					if(i==1){
						Eik = ( (Eik[i::i+1]'*Sk_all[i::i+1])/sum(Sk_all[i::i+1]) ) \ Eik[i+2::n_sc]
						Sk_all = sum(Sk_all[i::i+1])\ Sk_all[i+2::n_sc]
						score_range = (score_range[i,1],score_range[i+1,2]) \ score_range[i+2::n_sc,]
					}
					if(i>1 & i<=n_sc-2){
						Eik = Eik[1::i-1] \ ( (Eik[i::i+1]'*Sk_all[i::i+1])/sum(Sk_all[i::i+1]) ) \ Eik[i+2::n_sc]
						Sk_all = Sk_all[1::i-1] \ sum(Sk_all[i::i+1]) \ Sk_all[i+2::n_sc]
						score_range = score_range[1::i-1,] \ (score_range[i,1],score_range[i+1,2]) \ score_range[i+2::n_sc,]
					}
					if(i==n_sc-1){
						Eik = Eik[1::i-1] \ ( (Eik[i::i+1]'*Sk_all[i::i+1])/sum(Sk_all[i::i+1]) )
						Sk_all = Sk_all[1::i-1] \ sum(Sk_all[i::i+1])
						score_range = score_range[1::i-1,] \ (score_range[i,1],score_range[i+1,2])
					}
					if(i==n_sc){
						Eik = Eik[1::i-2] \ ( (Eik[i-1::i]'*Sk_all[i-1::i])/sum(Sk_all[i-1::i]) )  
						Sk_all = Sk_all[1::i-2] \ sum(Sk_all[i-1::i])
						score_range = score_range[1::i-2,] \ (score_range[i-1,1],score_range[i,2])
					}
					exp_freq_1=N:*Sk_all:*Eik
					n_sc=n_sc-1
					i=i-1
				}
				else{
					warning="could not collapse cats with sx2_min_freq="+strofreal(sx2_min_freq)
				}
			}
		}
		
		exp_freq_0=N:*Sk_all:*(1:-Eik)
		i=n_sc
		while(n_sc>1 & i>2){
			if(exp_freq_0[i]<sx2_min_freq){
				if(rows(score_range)>2){
					if(i==n_sc){
						Eik = Eik[1::i-2] \ ( (Eik[i-1::i]'*Sk_all[i-1::i])/sum(Sk_all[i-1::i]) )  
						Sk_all = Sk_all[1::i-2] \ sum(Sk_all[i-1::i])
						score_range = score_range[1::i-2,] \ (score_range[i-1,1],score_range[i,2])
					}
					else{
						Eik= Eik[1::i-2] \ ( (Eik[i-1::i]'*Sk_all[i-1::i])/sum(Sk_all[i-1::i]) ) \ Eik[i+1::n_sc]
						Sk_all= Sk_all[1::i-2] \ sum(Sk_all[i-1::i]) \ Sk_all[i+1::n_sc]
						score_range= score_range[1::i-2,] \ (score_range[i-1,1],score_range[i,2]) \ score_range[i+1::n_sc,]
					}
					exp_freq_0=N:*Sk_all:*(1:-Eik)
					n_sc=n_sc-1
				}
				else{
					warning="could not collapse cats with sx2_min_freq="+strofreal(sx2_min_freq)
				}
			}
			i=i-1
		}
		exp_freq_1=N:*Sk_all:*Eik
		
		results=J(6,1,NULL)
		results[1]=return_pointer(Eik)
		results[2]=return_pointer(score_range)
		results[3]=return_pointer(Sk_all)
		results[4]=return_pointer(exp_freq_1)
		results[5]=return_pointer(exp_freq_0)
		results[6]=&warning
		
		return(results)
	
	}
	
		
	pointer sx2_lord_wingersky(_Q, _Gx, real scalar item_for_fit){
	
		class ITEMS scalar Q
		Q=_Q
		class GROUPS scalar Gx
		Gx=_Gx
	
		I=Q.n
		itemselectrange_g 	= select((1::I),Q.get(Q.viable_sx2,.))
		itemselectrange_g	= select(itemselectrange_g,itemselectrange_g:!=item_for_fit)\item_for_fit
		parameters_g 		= Q.get(Q.pars,itemselectrange_g)
		model_curr_asked_g	= Q.get(Q.m_curr,itemselectrange_g),strofreal(Q.get(Q.n_cat,itemselectrange_g))
		I=rows(parameters_g)
		
		K=151
		quad_GH		= get_quad_GH(K,Gx.get(Gx.pars,.))
		quadpts 	= *quad_GH[1]
		P_quadpts	= *quad_GH[2]

		f_PiXk_matrix=J(I,K,.)
		for(i=1;i<=I;i++){
			if(model_curr_asked_g[i,1]!="pcm"){
				f_PiXk_matrix[i,.]=f_PiXk_01(parameters_g[i,.],model_curr_asked_g[i,.],quadpts')
			}
			else{
				f_PiXk_matrix[i,.]=f_PiXk_0c(parameters_g[i,.],model_curr_asked_g[i,.],quadpts')[2,.]
			}
		}
		
		Sk_less=J(I+1,K,1)
		
		Sk_less[1,]=(1:-f_PiXk_matrix[1,]) 
		Sk_less[2,]=f_PiXk_matrix[1,] 

		for(i=2;i<=I-1;i++){
			current=Sk_less[1,]
			Sk_less[1,]=current :*(1:-f_PiXk_matrix[i,]) 
			for(s=2;s<=i;s++){
				previous=current
				current=Sk_less[s,]
				Sk_less[s,]=  ( previous :*f_PiXk_matrix[i,] ) :+ ( current :*(1:-f_PiXk_matrix[i,]) ) 
			}
			previous=current
			Sk_less[i+1,]= ( previous :*f_PiXk_matrix[i,] )
		}
		
		Sk_all=Sk_less
		
		for(i=I;i<=I;i++){
			current=Sk_all[1,]
			Sk_all[1,]= current :*(1:-f_PiXk_matrix[i,]) 
			for(s=2;s<=i;s++){
				previous=current
				current=Sk_all[s,]
				Sk_all[s,]= ( previous :*f_PiXk_matrix[i,] ) :+ ( current :*(1:-f_PiXk_matrix[i,]) )
			}
			previous=current
			Sk_all[i+1,]=  ( previous :*f_PiXk_matrix[i,] ) 
		}

		Eik=J(I-1,1,.)
		for(i=1;i<=I-1;i++){
			Eik[i] =	rowsum(P_quadpts :* (f_PiXk_matrix[I,] :* Sk_less[i,]) ):/ rowsum(P_quadpts :* Sk_all[i+1,])
		}	
		
		results=J(2,1,NULL)
		results[1]=return_pointer(Eik)
		results[2]=return_pointer(rowsum(P_quadpts :* Sk_all))
		return(results)
	
	}
	
	function sx2_S(real colvector viable_for_sx2,pointer matrix point_Uigc, pointer matrix point_Fg){
		S=J(rows(*point_Fg[1]),1,0)
		for(i=1;i<=rows(viable_for_sx2);i++){
			if( viable_for_sx2[i]){
				ord_ic = (*(*point_Uigc[i,1])[2])
				if(rows(ord_ic)){
					S[ord_ic]=S[ord_ic]:+1
				}
			}
		}
		return(S)
	}
	
	pointer chi2W_item(_Q, _Gx, real scalar item_for_fit, real scalar N_Intervals, real scalar npq_crit, pointer matrix point_Uigc, pointer matrix point_Fg){
	
		class ITEMS scalar Q
		Q=_Q
		class GROUPS scalar Gx
		Gx=_Gx
		
		n_est_par	= Q.get(Q.n_par,item_for_fit):-Q.get(Q.n_fix,item_for_fit)
		N_gr=Gx.n
	
		K=151
		quad_GH	= get_quad_GH(K,Gx.get(Gx.pars,.))
		Gx.put(Gx.X_k,.,*quad_GH[1])
		Gx.put(Gx.A_k,.,*quad_GH[2])

		PXk_Uj_fit_results = PXk_Uj_fit(Q, Gx, point_Uigc,  point_Fg, item_for_fit, 1)
	
		if(N_Intervals==.){
			N_intervals=max(  (3 , (Q.get(Q.n_par,item_for_fit)-Q.get(Q.n_fix,item_for_fit)+1) )  )
		}
		else{
		    N_intervals=N_Intervals
		}		
		
		borders	= *chi2W_collapse_intervals(Q, Gx, item_for_fit, N_intervals, npq_crit, PXk_Uj_fit_results)[1]
	
		N_interv= cols(borders)-1

		P_all	=	*PXk_Uj_fit_results[1]
		P_all	=	rowsum(P_all)
		
		Fg_i=*PXk_Uj_fit_results[3]
		Y_i=*PXk_Uj_fit_results[4]
		nonmiss_U_ig_count=*PXk_Uj_fit_results[5]
		
		n_cat_i	=Q.get(Q.n_cat,item_for_fit)
		model_i	=Q.get(Q.m_curr,item_for_fit),strofreal(n_cat_i)
		pars_i	=Q.get(Q.pars,item_for_fit)
		
		
		K=30
		Pkq=J(rows(P_all),N_interv,.)
		Ekq=J(rows(P_all),N_interv,.)
		PQq=J(rows(P_all),N_interv,.)
		Pkq_less_i=J(rows(P_all),N_interv,.)
		
		for(d=1;d<=N_interv;d++){		
			
			U=borders[d+1]
			L=borders[d]	
			
			quad_GL	= get_quad_GL(U, L, K, Gx.get(Gx.pars,.))
			Gx.put(Gx.X_k,.,*quad_GL[1])
			Gx.put(Gx.A_k,.,*quad_GL[2])
			quadpts		= *quad_GL[1]'
			
			PXk_Uj_fit_results = PXk_Uj_fit(Q, Gx, point_Uigc,  point_Fg, item_for_fit, 0)
			
			Pkq[.,d]=rowsum( (*PXk_Uj_fit_results[1]) )
			Pkq_less_i[.,d]=rowsum( (*PXk_Uj_fit_results[2]) )
			
			E_quadpts=J(rows(P_all),K,.)
			range_start=1
			range_stop=0
			for(g=1;g<=N_gr;g++){
				if(nonmiss_U_ig_count[g]){
					range_stop=range_stop+nonmiss_U_ig_count[g]
					
						if(n_cat_i==2  & model_i[1]!="pcm"){
							PiXk_0c=(1 :- f_PiXk_01(pars_i,model_i,quadpts[.,g])) \ f_PiXk_01(pars_i,model_i,quadpts[.,g])
						}
						else{
							PiXk_0c=f_PiXk_0c(pars_i,model_i,quadpts[.,g])
						}
						
						E_temp=J(1,K,0)
						for(c=2;c<=n_cat_i;c++){
								E_temp = E_temp :+ ((c-1) :* PiXk_0c[c,.])
						}
					
						E_quadpts[range_start::range_stop,.]=J(nonmiss_U_ig_count[g],1,E_temp)
					
					range_start=range_stop+1
				}
			}
			Ekq[.,d]=rowsum( (*PXk_Uj_fit_results[2]) :* E_quadpts)
			PQq[.,d]=rowsum( (*PXk_Uj_fit_results[2]) :* E_quadpts :* ((n_cat_i-1):-E_quadpts))
		}
	
		Pkq_simplex=Pkq:/P_all
		
		exp_N=colsum(Fg_i:*Pkq_simplex)
		
		E=colsum(Fg_i:*(Ekq:/Pkq_less_i):*Pkq_simplex):/exp_N
		
		O=colsum(Fg_i:*Pkq_simplex:*Y_i):/exp_N
		
		inv_COV_D=invsym(quadcross((sqrt(Fg_i):*Pkq_simplex:*(Y_i:-J(rows(Y_i),1,O) ):/exp_N),(sqrt(Fg_i):*Pkq_simplex:*(Y_i:-J(rows(Y_i),1,O) ):/exp_N)))
		
		d=(O-E)
		
		NPQ=colsum(Fg_i:*(PQq:/Pkq_less_i):*Pkq_simplex)
		
		W			=	d*inv_COV_D*d'
		df_W		=	rank(inv_COV_D)-n_est_par
		pvalue		=	1:-chi2(df_W,W)
		sign_W		=	(pvalue< 0.05)
		
		
		results = J(9,1,NULL)
		results[1] = return_pointer(W)
		results[2] = return_pointer(pvalue)
		results[3] = return_pointer(df_W)
		results[4] = return_pointer(sign_W)
		results[5] = return_pointer(E)
		results[6] = return_pointer(O)
		results[7] = return_pointer(exp_N)		
		results[8] = return_pointer(NPQ)
		results[9] = return_pointer(borders)
		
		return(results)
	}	



	pointer chi2W_collapse_intervals(_Q,_Gx, real scalar item_for_fit, real scalar N_Intervals, real scalar npq_crit, pointer matrix PXk_Uj_fit_results){
	
		class ITEMS scalar Q
		Q=_Q
		class GROUPS scalar Gx
		Gx=_Gx
		
		n_est_par	= Q.get(Q.n_par,item_for_fit):-Q.get(Q.n_fix,item_for_fit)
		
		warning=""
		
		if(N_Intervals-n_est_par<1){
			N_interv=n_est_par+5
		}
		else{
			N_interv=N_Intervals
		}
		
		P_all=*PXk_Uj_fit_results[1]
		Fg_i=*PXk_Uj_fit_results[3]
		quadpts=Gx.get(Gx.X_k,.)'
		nonmiss_U_ig_count=*PXk_Uj_fit_results[5]
		
		N_gr=Gx.n

		n_cat_i	=Q.get(Q.n_cat,item_for_fit)
		model_i	=Q.get(Q.m_curr,item_for_fit),strofreal(n_cat_i)
		pars_i	=Q.get(Q.pars,item_for_fit)
		
		K=cols(P_all)
		E_quadpts=J(rows(P_all),K,.)
		range_start=1
		range_stop=0
		for(g=1;g<=N_gr;g++){
			if(nonmiss_U_ig_count[g]){
			
				range_stop=range_stop+nonmiss_U_ig_count[g]
				
					if(n_cat_i==2  & model_i[1]!="pcm"){
						PiXk_0c=(1 :- f_PiXk_01(pars_i,model_i,quadpts[.,g])) \ f_PiXk_01(pars_i,model_i,quadpts[.,g])
					}
					else{
						PiXk_0c=f_PiXk_0c(pars_i,model_i,quadpts[.,g])
					}
					
					E_temp=J(1,K,0)
					for(c=2;c<=n_cat_i;c++){
							E_temp = E_temp :+ ((c-1) :* PiXk_0c[c,.])
					}
				
					E_quadpts[range_start::range_stop,.]=J(nonmiss_U_ig_count[g],1,E_temp)
				
				range_start=range_stop+1
				
			}
		}
		
		PQ_quadpts=E_quadpts:*((n_cat_i-1):-E_quadpts)
		
		
		
		NPQ_all=sum( Fg_i :* P_all :* PQ_quadpts :/ rowsum(P_all) )
		P_all=	rowsum(Fg_i :* P_all)
		
		if( (NPQ_all/N_interv) < npq_crit ){
			N_interv = floor(NPQ_all/npq_crit)
		}
		
		if(N_interv-n_est_par<1){
			N_interv=n_est_par+1
			warning="N*p*q~"+substr(strofreal(NPQ_all/N_interv),1,4)+"<10, chi2 approximation may be unreliable"
		}
		
		NPQ_d_crit=NPQ_all/N_interv
		
		if( (NPQ_all/N_interv)>1 ){
			N_int=1000
		}
		else{
			N_int=10000
		}
		K=11
		bord=-10,invnormal((1..N_int-1):/N_int),10
		E_d=J(1,N_int,.)
		for(d=1;d<=N_int;d++){
			U=bord[d+1]
			L=bord[d]
			
			// performed only on the refference distribution; would be better to average distributions over number of item observations within groups
			quad_GL	= get_quad_GL(U, L, K, Gx.get(Gx.pars,1))
			quadpts= (*quad_GL[1]')
			P_N01_quadpts= (*quad_GL[2]')
			
			if(n_cat_i==2  & model_i[1]!="pcm"){
				PiXk_0c=(1 :- f_PiXk_01(pars_i,model_i,quadpts)) \ f_PiXk_01(pars_i,model_i,quadpts)
			}
			else{
				PiXk_0c=f_PiXk_0c(pars_i,model_i,quadpts)
			}
			
			E_temp=J(1,K,0)
			for(c=2;c<=n_cat_i;c++){
					E_temp = E_temp :+ ((c-1) :* PiXk_0c[c,.])
			}
			
			E_d[d]=E_temp*P_N01_quadpts/sum(P_N01_quadpts)
			
		}
		
		NPQ=(sum(Fg_i)/N_int):*E_d:*((n_cat_i-1):-E_d)
	
		NPQ_crit=NPQ_d_crit*0.99*(sum(NPQ)/NPQ_all)
		borders=-10,J(1,N_interv-1,.),10
		up=1
		b_up=2
		b_down=N_interv
		int_up=1
		int_down=N_int
		proceed=1
		for(k=1;k<=N_interv-1;k++){
			if(proceed){
				if(up){
					S=0
					int_start=int_up
					while(S<NPQ_crit){
						S=sum(NPQ[int_start..int_up])
						int_up++
					}
					borders[b_up]=bord[int_up]
					b_up++
					up=0
				}
				else{
					S=0
					int_start=int_down
					while(S<NPQ_crit){
						S=sum(NPQ[int_down..int_start])
						int_down--
					}
					borders[b_down]=bord[int_down]
					b_down--
					up=1
				}
				
				proceed=-1
				r_int_span=(int_down-int_up)/(N_interv-k)
				for(r=1;r<=N_interv-k;r++){
					if( sum(NPQ[int_up+floor((r-1)*r_int_span)+1..int_up+floor(r*r_int_span)]) < NPQ_crit ){
						proceed=1
					}
				}
				
			}

			if(proceed==-1){
				r=1
				for(b=b_up;b<=b_down;b++){
					borders[b]=bord[int_up+floor(r*r_int_span)+1]
					r++
				}
				proceed=0
			}
		}	
							
		results = J(2,1,NULL)
		results[1] = return_pointer(borders)
		results[2] = &warning
		
		return(results)

	}
	
	
	
	pointer PXk_Uj_fit(_Q, _Gx, pointer matrix point_Uigc, pointer matrix point_Fg, real scalar item_for_fit, real scalar if_FY){
	
		class ITEMS scalar Q
		Q=_Q
		class GROUPS scalar Gx
		Gx=_Gx
				
		N_gr=Gx.n
		I=Q.n
		K=cols(Gx.get(Gx.X_k,.))	
		
		item_group_totalobs_i=Q.get(Q.g_tot,item_for_fit)
		n_cat_i=Q.get(Q.n_cat,item_for_fit)
		
		point_Uixx = J(1,N_gr,NULL)
		for(g=1;g<=N_gr;g++){
			if(item_group_totalobs_i[g]){
				i_g = sum(Q.get(Q.g_tot,1::item_for_fit)[.,g]:>0)
				point_Uixx[g]	= point_Uigc[i_g,g]
			}
			else{
				point_Uixx[g]	= &J(0,0,.)
			}
		}
		
		PXk_Uj_i	=J(sum(Gx.get(Gx.n_uniq,.)),K,1)
		PXk_Uj_less_i=J(sum(Gx.get(Gx.n_uniq,.)),K,1)
		if(if_FY){
			Fg_i	=	J(sum(Gx.get(Gx.n_uniq,.)),1,1)
			Y_i		=	J(sum(Gx.get(Gx.n_uniq,.)),1,1)
		}
		else{
			Fg_i	=	J(0,0,.)
			Y_i		=	J(0,0,.)		
		}
				
		range_start=1
		range_stop=0
		nonmiss_U_ig_count=J(N_gr,1,0)
		class ITEMS scalar Qg
		class GROUPS scalar Gg
		for(g=1;g<=N_gr;g++){
			if(item_group_totalobs_i[g]){
				
				nonmiss_U_ig_vector	=J(0,1,.)
				Y_ig				= J(0,1,.)
				for(c=1;c<=n_cat_i;c++){
					ord_ic 		= (*(*point_Uixx[g])[c])
					nonmiss_U_ig_vector=nonmiss_U_ig_vector\ord_ic
					if(if_FY){
						Y_ig= Y_ig\J(rows(ord_ic),1,c-1)
					}
				}
				
				nonmiss_U_ig_count[g]=rows(nonmiss_U_ig_vector)
				range_stop=range_stop+nonmiss_U_ig_count[g]
				
				itemselectrange_g=select((1::I),Q.get(Q.g_tot,.)[.,g]:>0)
				Qg=cloneQ(selectQ(Q,Q.get(Q.names,itemselectrange_g)))
				Gg=cloneG(selectG(Gx,g))

				item_for_fit_g=select((1::rows(itemselectrange_g)),itemselectrange_g:==item_for_fit)
				
				PXk_Uj_fit_g_results = PXk_Uj_fit_g(Qg, Gg, point_Uigc[.,g], item_for_fit_g)
				
				PXk_Uj_i[range_start::range_stop,.]			=	(*PXk_Uj_fit_g_results[1])[nonmiss_U_ig_vector,.]
				PXk_Uj_less_i[range_start::range_stop,.]	=	(*PXk_Uj_fit_g_results[2])[nonmiss_U_ig_vector,.]
				if(if_FY){
					Fg_i[range_start::range_stop,.]				=	(*point_Fg[g])[nonmiss_U_ig_vector]
					Y_i[range_start::range_stop,.]				=	Y_ig
				}
			
				range_start=range_stop+1
				
			}
		}
		
		PXk_Uj_i=PXk_Uj_i[1::range_stop,.]
		PXk_Uj_less_i=PXk_Uj_less_i[1::range_stop,.]
		if(if_FY){
			Fg_i	=	Fg_i[1::range_stop]
			Y_i		=	Y_i[1::range_stop]
		}
		
		results=J(5,1,NULL)
		results[1]=return_pointer(PXk_Uj_i)
		results[2]=return_pointer(PXk_Uj_less_i)
		results[3]=return_pointer(Fg_i)
		results[4]=return_pointer(Y_i)
		results[5]=return_pointer(nonmiss_U_ig_count)
		return(results)
		
	}
	

	pointer PXk_Uj_fit_g(_Qg, _Gg, pointer matrix point_Uxgx, real scalar item_for_fit){
	
		class ITEMS scalar Qg
		Qg=_Qg
		class GROUPS scalar Gg
		Gg=_Gg
	
		I=Qg.n
		Obs_g=Gg.get(Gg.n_uniq,.)
		X_k=Gg.get(Gg.X_k,.)'
		K=rows(X_k)
		
		LXk_Uj=J(Obs_g,K,1)
		for(i=1;i<=item_for_fit-1;i++){
			n_cat=Qg.get(Qg.n_cat,i)
			pars_i=Qg.get(Qg.pars,i)
			model_i=(Qg.get(Qg.m_curr,i),strofreal(n_cat))
			if(n_cat==2  & model_i[1]!="pcm"){
				PiXk_0c=(1 :- f_PiXk_01(pars_i,model_i,X_k)) \ f_PiXk_01(pars_i,model_i,X_k)
			}
			else{
				PiXk_0c=f_PiXk_0c(pars_i,model_i,X_k)
			}
	
			for(c=1;c<=n_cat;c++){
				ord_ic = *(*point_Uxgx[i])[c]
				if(rows(ord_ic)){ // in case of fixing and missing
					LXk_Uj[ord_ic,.] = LXk_Uj[ord_ic,.] :* PiXk_0c[c,.]
				}
			}
		}
		for(i=item_for_fit+1;i<=I;i++){
			n_cat=Qg.get(Qg.n_cat,i)
			pars_i=Qg.get(Qg.pars,i)
			model_i=(Qg.get(Qg.m_curr,i),strofreal(n_cat))
			if(n_cat==2  & model_i[1]!="pcm"){
				PiXk_0c=(1 :- f_PiXk_01(pars_i,model_i,X_k)) \ f_PiXk_01(pars_i,model_i,X_k)
			}
			else{
				PiXk_0c=f_PiXk_0c(pars_i,model_i,X_k)
			}
	
			for(c=1;c<=n_cat;c++){
				ord_ic = *(*point_Uxgx[i])[c]
				if(rows(ord_ic)){ // in case of fixing and missing
					LXk_Uj[ord_ic,.] = LXk_Uj[ord_ic,.] :* PiXk_0c[c,.]
				}
			}
		}
	
		if(item_for_fit){
		
			PXk_Uj_less_i=Gg.get(Gg.A_k,.) :* LXk_Uj
			
			i		= item_for_fit
			
			n_cat	= Qg.get(Qg.n_cat,i)
			model_i	= (Qg.get(Qg.m_curr,i),strofreal(n_cat))
			pars_i=Qg.get(Qg.pars,i)
			
			if(n_cat==2  & model_i[1]!="pcm"){
				PiXk_0c=(1 :- f_PiXk_01(pars_i,model_i,X_k)) \ f_PiXk_01(pars_i,model_i,X_k)
			}
			else{
				PiXk_0c=f_PiXk_0c(pars_i,model_i,X_k)
			}
	
			for(c=1;c<=n_cat;c++){
				ord_ic = *(*point_Uxgx[i])[c]
				if(rows(ord_ic)){ // in case of fixing and missing
					LXk_Uj[ord_ic,.] = LXk_Uj[ord_ic,.] :* PiXk_0c[c,.]
				}
			}
			
		}
		else{
			PXk_Uj_less_i=J(0,0,.)
		}
		
		PXk_Uj=Gg.get(Gg.A_k,.) :* LXk_Uj
		
		results=J(2,1,NULL)
		results[1]=return_pointer(PXk_Uj)
		results[2]=return_pointer(PXk_Uj_less_i)
		return(results)
	}
	
	// part of get_quad_GL() function below adapts a code from:
	// Adrian Mander, 2012. "INTEGRATE: Stata module to perform one-dimensional integration," 
	// Statistical Software Components S457429, Boston College Department of Economics, revised 10 Aug 2018.
	pointer get_quad_GL(real scalar UP, real scalar LO, real scalar nip, real matrix DIST){
		
		i = (1..nip-1)
		b = i:/sqrt(4:*i:^2:-1) 
		z1 = J(1,nip,0)
		z2 = J(1,nip-1,0)
		CM = ((z2',diag(b))\z1) + (z1\(diag(b),z2'))
		V=.
		XGL_k=.
		symeigensystem(CM, V, XGL_k)
		AGL_k = (2:* V':^2)[,1]'
		
		X_k = J(rows(DIST),nip,.)
		A_k = J(rows(DIST),nip,.)
		for(g=1;g<=rows(DIST);g++){				
			X_k[g,.]= ( (UP-LO) :* XGL_k :+ (UP+LO) ) :/2  
			A_k[g,.]= (UP-LO) :* AGL_k :* normalden( X_k[g,.] ,DIST[g,1],DIST[g,2] )/2
		}
		X_k=X_k[.,nip..1]
		A_k=A_k[.,nip..1]	
		
		results=J(2,1,NULL)
		results[1]=return_pointer(X_k)
		results[2]=return_pointer(A_k)
		return(results)
	}	
	
	
	void cats_and_models(_Q, string matrix guesslist,string matrix pcmlist,string matrix gpcmlist){

		class ITEMS scalar Q
		Q=_Q
		
		itemlist	= Q.get(Q.names,.)
				
		for(i=1;i<=Q.n;i++){
			if(Q.get(Q.init_fail,i)!=3){
		
				if(Q.get(Q.m_curr,i)==""){
					if(Q.get(Q.n_cat,i)==2){
						if(sum(guesslist:==itemlist[i])){
							Q.put(Q.m_curr,i,"2plm")
							Q.put(Q.m_asked,i,"3plm")
						}
						else{
							Q.put(Q.m_curr,i,"2plm")
							Q.put(Q.m_asked,i,"2plm")
						}
					}
					if(sum(pcmlist:==itemlist[i])){
						Q.put(Q.m_curr,i,"pcm")
						Q.put(Q.m_asked,i,"pcm")
					}
					else{
						if(Q.get(Q.n_cat,i)>2){
							if(sum(gpcmlist:==itemlist[i])){
								Q.put(Q.m_curr,i,"pcm")
								Q.put(Q.m_asked,i,"gpcm")
							}
							else{
								Q.put(Q.m_curr,i,"grm")
								Q.put(Q.m_asked,i,"grm")						
							}
						}
					}
				}
				
				if( (Q.get(Q.m_asked,i)=="gpcm" | Q.get(Q.m_asked,i)=="grm" ) & Q.get(Q.n_cat,i)==2 ){
					Q.put(Q.m_curr,i,"2plm")
					Q.put(Q.m_asked,i,"2plm")
				}
				
				if(Q.get(Q.m_curr,i)=="2plm" & sum(guesslist:==itemlist[i]) ){
					Q.put(Q.m_asked,i,"3plm")
				}
				
				if(Q.get(Q.m_curr,i)=="2plm"){
					n_par_model=2
					par_labs=("a","b")
				}
				if(Q.get(Q.m_curr,i)=="3plm"){
					n_par_model=3
					par_labs=("a","b","c")
				}
				if(Q.get(Q.m_curr,i)!="2plm" & Q.get(Q.m_curr,i)!="3plm"){
					n_par_model=Q.get(Q.n_cat,i)
					par_labs=("a"),("b":+strofreal(1..Q.get(Q.n_cat,i)-1))
				}
				Q.put(Q.n_par_model,i,n_par_model)
				Q.put(Q.par_labs,i,par_labs)
				
				delta=n_par_model-cols(Q.get(Q.pars,i))
				if(delta>0){
					Q.put(Q.pars,i,(Q.get(Q.pars,i),J(1,delta,.)))
				}
				delta=n_par_model-cols(Q.get(Q.fix,i))
				if(delta>0){
					Q.put(Q.fix,i,(Q.get(Q.fix,i),J(1,delta,.)))
				}
				delta=n_par_model-cols(Q.get(Q.init,i))
				if(delta>0){
					Q.put(Q.init,i,(Q.get(Q.init,i),J(1,delta,.)))
				}
				
				if(Q.get(Q.m_curr,i)=="pcm"){
					fix_i=Q.get(Q.fix,i)
					if(fix_i[1]==.){
						fix_i[1]=1
						Q.put(Q.fix,i,fix_i)
					}
				}
			
				cns=(Q.get(Q.fix,i):!=.)
				Q.put(Q.cns,i,cns)

			}
		}
	}
	
	
	void add_priors(_Q, real matrix a_normal_prior, real matrix b_normal_prior, real matrix c_beta_prior ,real scalar check_a){
		
		if((cols(a_normal_prior)==2)|(cols(b_normal_prior)==2)|(cols(c_beta_prior)==2)){
			
			class ITEMS scalar Q
			Q=_Q
		
			viable_for_priors= select((1::Q.n),strpos(Q.get(Q.m_curr,.),"plm"))
			
			if(rows(viable_for_priors)){
			
				if(rows(viable_for_priors)){
				
					if(cols(a_normal_prior)==2){
						if(a_normal_prior[1]<=0 & check_a){
							_error("mean of normal prior for the discrimination parameter has to be positive")
						}
						if(a_normal_prior[2]<=0){
							_error("sd of normal prior for the discrimination parameter has to be positive")
						}
						Q.put(Q.a_prior,viable_for_priors,J(rows(viable_for_priors),1,a_normal_prior))
					}
					
					if(cols(b_normal_prior)==2){
						if(b_normal_prior[2]<=0){
							_error("sd of normal prior for the difficulty parameter has to be positive")
						}
						Q.put(Q.b_prior,viable_for_priors,J(rows(viable_for_priors),1,b_normal_prior))
					}
					
					if(cols(c_beta_prior)==2){
						if(sum(c_beta_prior:>0)<2){
							_error("both parameters of beta prior for the guessing parameter have to be greater than 1")
						}
						Q.put(Q.c_prior,viable_for_priors,J(rows(viable_for_priors),1,c_beta_prior))
					}					
				}
				
				
			}
			else{
				stata("di in red "+char(34)+"{p 0 2}Warning: priors are implemented only for 2plm and 3plm items and there are no such items in varlist of priors() option; priors will not be used{p_end}"+char(34))
			}
			
		}
	
	}
	
	
	
	void group_pars(_Q, _G, real scalar nip, string scalar initdmatrix, real scalar estimate_dist){
	
		class ITEMS scalar Q
		Q=_Q
	
		class GROUPS scalar G
		G=_G
	
		if(sum(Q.get(Q.n_fix,.))==0 & estimate_dist==1){
			estimate_dist=0
			stata("di in red "+char(34)+"{p 0 2}Warning: parameters of reference group will remain fixed; dist requires fixing parameters of at least one item{p_end}"+char(34))
		}
		
		if(initdmatrix==""){
			DIST=J(1,G.n,(0\1))
		}
		else{
			DIST=st_matrix(initdmatrix)
			
			saved_group_vals=st_matrixcolstripe(initdmatrix)
			saved_group_vals=strtoreal(subinstr(st_matrixcolstripe(initdmatrix)[.,2],"group_",""))
			
			if(rows(saved_group_vals)!=G.n){
				_error("number of groups in matrix "+initdmatrix+" is not " +strofreal(G.n))
			}
			else{
				if(sum(saved_group_vals:!=G.get(G.val,.))){
					_error("group values in matrix "+initdmatrix+" differ from those specified in current run")			
				}
			}	
		}
		
		quad_GH	= get_quad_GH(nip,DIST')
		
		G.put(G.pars,.,DIST')
		G.put(G.X_k,.,*quad_GH[1])
		G.put(G.A_k,.,*quad_GH[2])
		
		if(estimate_dist==-1){
			Cns_DIST				= (DIST :* 0) :+1
		}
		else{
			Cns_DIST				= DIST :* 0
			if(estimate_dist==0){
				Cns_DIST[.,1]=(1\1)
			}
			if(estimate_dist==0 & sum(Q.get(Q.m_asked,.):=="pcm")>0 ){
				Cns_DIST[.,1]=(1\0)
			}
		}
		G.put(G.cns,.,Cns_DIST')
		
	}
	

	
	function selectQ(_Q, string colvector namevec){
		class ITEMS scalar selectQ
		selectQ=_Q
		selectQ.populate(namevec)
		return(selectQ)
	}
	
	function selectG(_G, real colvector groups){
		class GROUPS scalar selectG
		selectG=_G
		values=selectG.get(selectG.val,groups)
		selectG.populate(values)
		return(selectG)
	}
	
	function cloneQ(_Q){
		class ITEMS scalar Q
		Q=_Q
		class ITEMS scalar cloneQ
		cloneQ.populate(Q.get(Q.names,.))
		for(p=1;p<=Q.n_prop;p++){
			for(i=1;i<=Q.n;i++){
				cloneQ.put(p,i,Q.get(p,i))
			}
		}
		return(cloneQ)
	}
	
	function cloneG(_G){
		class GROUPS scalar G
		G=_G
		class GROUPS scalar cloneG
		cloneG.populate(G.get(G.val,.))
		for(p=1;p<=G.n_prop;p++){
			cloneG.put(p,.,G.get(p,.))
		}
		return(cloneG)
	}

	void check_matrices(string scalar ipar, string scalar icats, string scalar grpar, real vector checklist, real scalar check_miss, real scalar check_a){

		
		if(checklist==.){
		//	checklist=(strlen((ipar\icats\grpar\grn\igrn)):>0)
		checklist=(strlen((ipar\icats\grpar)):>0)
		}

		//ipar
		if(checklist[1]){
			ipar_rown=st_matrixrowstripe(ipar)
			ipar_coln=st_matrixcolstripe(ipar)[.,2]
			ipar_val=st_matrix(ipar)
			
			// proper size
			if(cols(ipar_val)<2){
				stata("di as err "+char(34)+"{p 0 2}item parameter matrix ("+ipar+") has "+strofreal(cols(ipar_val))+" columns{p_end}"+char(34))
				_error("{p 0 2}at least 2 columns are required to specify the simplest models{p_end}")
			}
			if(rows(ipar_val)<1){
				stata("di as err "+char(34)+"{p 0 2}item parameter matrix ("+ipar+") has "+strofreal(rows(ipar_val))+" rows{p_end}"+char(34))
				_error("{p 0 2}at least 1 row is required{p_end}")
			}
			
			// if parnames are ok - general
			if(cols(ipar_val)==2){
				proper_colnames=("a","b")\("a","b1")
				firstcol=("2plm:"\"pcm:")
			} 
			if(cols(ipar_val)==3){
				proper_colnames=("a","b","c")\("a","b","b1")\("a","b1","b2")
				firstcol=("3plm:"\"2plm & pcm:"\"grm | pcm | gpcm")
			}
			if(cols(ipar_val)>3 ){
				proper_colnames=(("a","b","c"),("b":+strofreal(1..(cols(ipar_val)-3))) )\(("a","b","b1"),("b":+strofreal(2..(cols(ipar_val)-2))) )\(("a","b1","b2"),("b":+strofreal(3..(cols(ipar_val)-1))) )
				if(cols(ipar_val)==4){
					firstcol=("3plm & pcm :"\"2plm & (grm | pcm | gpcm):"\"grm | pcm | gpcm :")
				}
				else{
					firstcol=("3plm & (grm | pcm | gpcm):"\"2plm & (grm | pcm | gpcm):"\"grm | pcm | gpcm :")
				}
			}
			if( sum(rowsum((ipar_coln':==proper_colnames)):==cols(ipar_val))!=1 ){
				stata("di as err "+char(34)+"{p 0 2}parameter names in columns of item parameter matrix ("+ipar+") are incorrect:{p_end}"+char(34))
				di_matrix_as_err(ipar_coln',J(0,cols(ipar_val),""))
				stata("di as err "+char(34)+"{p 0 2}for a "+strofreal(cols(ipar_val))+"-column item parameter matrix correct entries can be only one of the following..{p_end}"+char(34))
				di_matrix_as_err((firstcol,proper_colnames),J(0,1+cols(ipar_val),""))
				_error("provide proper column names of item parameter matrix")
			}

			
			// if model names are ok
			row_errors=(rowsum(J(1,5,ipar_rown[.,2]):==("2plm","3plm","grm","pcm","gpcm")):!=1)
			if(sum(row_errors)){
				stata("di as err "+char(34)+ "{p 0 2}"+strofreal(sum(row_errors)) + " rows in item parameter matrix ("+ipar+") have incorrect model specification:{p_end}"+char(34))
				select_err=select(ipar_rown,row_errors)
				di_matrix_as_err(select_err,("item","model"))
				_error("allowed values are: 2plm | 3plm | grm | pcm | gpcm")
			}
			
			// if item names are unique
			dup_items=rows(ipar_rown[.,1])-rows(uniqrows(ipar_rown[.,1]))
			if(dup_items){
				stata("di as err "+char(34)+ "{p 0 2}duplicate item names in item parameter matrix ("+ipar+"); surplus="+strofreal(dup_items)+"{p_end}"+char(34))
				_error("duplicate item names are not allowed")
			}

			// if discrimination values are nonnegative (not performed if ANegative was called)
			if(check_a){
				row_errors=(ipar_val[.,1]:<=0)
				if(sum(row_errors)){
					stata("di as err "+char(34)+"{p 0 2}"+ strofreal(sum(row_errors)) + " items in item parameter matrix ("+ipar+") have incorrect discrimination parameter:{p_end}"+char(34))
					select_err=select(ipar_rown,row_errors),select(strofreal(ipar_val[.,1]),row_errors)
					di_matrix_as_err(select_err,("item","model","a"))
					_error("discrimination has to be positive")
				}
			}
			
			// if discrimination values are nonmissing
			if(check_miss){
				row_errors=rowmissing(ipar_val[.,1])
				if(sum(row_errors)){
					stata("di as err "+char(34)+"{p 0 2}"+ strofreal(sum(row_errors)) + " items in item parameter matrix ("+ipar+") have incorrect discrimination parameter:{p_end}"+char(34))
					select_err=select(ipar_rown,row_errors),select(strofreal(ipar_val[.,1]),row_errors)
					di_matrix_as_err(select_err,("item","model","a"))
					_error("discrimination has to be nonmissing")
				}
			}
			
			
			
			// if 3plm values and parnames are ok
			if(sum(ipar_rown[.,2]:=="3plm")>0){
				if(cols(ipar_val)<3){
					stata("di as err "+char(34)+ "{p 0 2}item parameter matrix ("+ipar+") has "+strofreal(cols(ipar_val))+" columns{p_end}"+char(34))
					_error("at least 3 columns are required to specify 3plm properly")
				}
				if(ipar_coln[1::3]!=("a"\"b"\"c")){
					stata("di as err "+char(34)+"{p 0 2}parameter names in columns of item parameter matrix ("+ipar+") are incorrect{p_end}"+char(34))
					di_matrix_as_err(J(0,4,""),("first 3 columns are named:",(ipar_coln[1::3]')))
					_error("if 3plm is to be used first 3 columns should be: "+char(34)+"a"+char(34)+" "+char(34)+"b"+char(34)+" "+char(34)+"c"+char(34))
				}
				row_errors=(ipar_rown[.,2]:=="3plm"):*(ipar_val[.,3]:<0):*(ipar_val[.,3]:>1)
				if(sum(row_errors)){
					stata("di as err "+char(34)+"{p 0 2}"+ strofreal(sum(row_errors)) + " items in item parameter matrix ("+ipar+") have incorrect guessing parameter:{p_end}"+char(34))
					select_err=select(ipar_rown,row_errors),select(strofreal(ipar_val[.,3]),row_errors)
					di_matrix_as_err(select_err,("item","model","c"))
					_error("guessing has to be >0 and <1")
				}
				if(check_miss){
					row_errors=(ipar_rown[.,2]:=="3plm"):*rowmissing(ipar_val[.,3])
					if(sum(row_errors)){
						stata("di as err "+char(34)+"{p 0 2}"+ strofreal(sum(row_errors)) + " items in item parameter matrix ("+ipar+") have incorrect guessing parameter:{p_end}"+char(34))
						select_err=select(ipar_rown,row_errors),select(strofreal(ipar_val[.,3]),row_errors)
						di_matrix_as_err(select_err,("item","model","c"))
						_error("guessing has to be nonmissing")
					}
				}
			}
			
			// if difficulty parnames are ok
			if(sum((rowsum(J(1,2,ipar_rown[.,2]):==("2plm","3plm")):==1))>0){
				if(ipar_coln[1::2]!=("a"\"b")){
					stata("di as err "+char(34)+"{p 0 2}parameter names in columns of item parameter matrix ("+ipar+") are incorrect{p_end}"+char(34))
					di_matrix_as_err(J(0,3,""),("first 2 columns are named:",(ipar_coln[1::2]')))
					_error("if 2plm or 3plm is to be used first 2 columns should be: "+char(34)+"a"+char(34)+" "+char(34)+"b"+char(34))
				}
				if(check_miss){
					row_errors=((rowsum(J(1,2,ipar_rown[.,2]):==("2plm","3plm")):==1)):*rowmissing(ipar_val[.,2])
					if(sum(row_errors)){
						stata("di as err "+char(34)+"{p 0 2}"+  strofreal(sum(row_errors)) + " items in item parameter matrix ("+ipar+") have incorrect difficulty parameter:{p_end}"+char(34))
						select_err=select(ipar_rown,row_errors),select(strofreal(ipar_val[.,2]),row_errors)
						di_matrix_as_err(select_err,("item","model","2"))
						_error("2plm and 3plm require difficulty to be nonmissing")
					}
				}
			}
			
			// if nonmissing b# entries in 2plm or 3plm
			if(sum((rowsum(J(1,2,ipar_rown[.,2]):==("2plm","3plm")):==1))>0){
			
				if(cols(ipar_val)>3 & (sum(ipar_rown[.,2]:=="3plm")>0)){
					row_errors=(rowsum(J(1,2,ipar_rown[.,2]):==("2plm","3plm")):==1):*(rownonmissing(ipar_val[.,4..cols(ipar_val)]):>0)
					if(sum(row_errors)){
						stata("di as err "+char(34)+"{p 0 2}"+ strofreal(sum(row_errors)) + " items in item parameter matrix ("+ipar+") have nonmissing b# values for 2plm|3plm:{p_end}"+char(34))
						col_errors=colnonmissing(select(ipar_val,row_errors)[.,4..cols(ipar_val)])
						col_errors_ind=select(4::cols(ipar_val),col_errors')'
						select_err=select(ipar_rown,row_errors),select(strofreal(ipar_val[.,col_errors_ind]),row_errors)
						di_matrix_as_err(select_err,(("item","model"),ipar_coln'[col_errors_ind]))
						_error("only "+char(34)+"a"+char(34)+" and "+char(34)+"b"+char(34)+" entries are allowed in 2plm; only "+char(34)+"a"+char(34)+" and "+char(34)+"b"+char(34)+" and "+char(34)+"c"+char(34)+" in 3plm")
					}				
				}
				
				if(cols(ipar_val)>2 & (sum(ipar_rown[.,2]:=="3plm")==0)){
					row_errors=(ipar_rown[.,2]:=="2plm"):*(rownonmissing(ipar_val[.,3..cols(ipar_val)]):>0)
					if(sum(row_errors)){
						stata("di as err "+char(34)+"{p 0 2}"+ strofreal(sum(row_errors)) + " items in item parameter matrix ("+ipar+") have nonmissing b# values for 2plm:{p_end}"+char(34))
						col_errors=colnonmissing(select(ipar_val,row_errors)[.,3..cols(ipar_val)])
						col_errors_ind=select(3::cols(ipar_val),col_errors')'
						select_err=select(ipar_rown,row_errors),select(strofreal(ipar_val[.,col_errors_ind]),row_errors)
						di_matrix_as_err(select_err,(("item","model"),ipar_coln'[col_errors_ind]))
						_error("only "+char(34)+"a"+char(34)+" and "+char(34)+"b"+char(34)+" entries are allowed in 2plm")
					}					
				}
				
			}
			
			// if grm, pcm, gpcm dont have b or c entries
			if(sum((rowsum(J(1,3,ipar_rown[.,2]):==("grm","pcm","gpcm")):==1))>0){
				
				if(sum(ipar_coln:=="c")){
					row_errors=(rowsum(J(1,3,ipar_rown[.,2]):==("grm","pcm","gpcm")):==1):*(rownonmissing(ipar_val[.,3]):>0)
					if(sum(row_errors)){
						stata("di as err "+char(34)+"{p 0 2}"+ strofreal(sum(row_errors)) + " items in item parameter matrix ("+ipar+") have nonmissing c values for grm|pcm|gpcm model:{p_end}"+char(34))
						select_err=select(ipar_rown,row_errors),select(strofreal(ipar_val[.,3]),row_errors)
						di_matrix_as_err(select_err,("item","model","c"))
						_error("only "+char(34)+"a"+char(34)+" and "+char(34)+"b#"+char(34)+" entries are allowed in grm|pcm|gpcm")
					}
				}
				
				if(sum(ipar_coln:=="b")){
					row_errors=(rowsum(J(1,3,ipar_rown[.,2]):==("grm","pcm","gpcm")):==1):*(rownonmissing(ipar_val[.,2]):>0)
					if(sum(row_errors)){
						stata("di as err "+char(34)+"{p 0 2}"+ strofreal(sum(row_errors)) + " items in item parameter matrix ("+ipar+") have nonmissing b values for grm|pcm|gpcm model:{p_end}"+char(34))
						select_err=select(ipar_rown,row_errors),select(strofreal(ipar_val[.,2]),row_errors)
						di_matrix_as_err(select_err,("item","model","b"))
						_error("only "+char(34)+"a"+char(34)+" and "+char(34)+"b#"+char(34)+" entries are allowed in grm|pcm|gpcm")
					}
				}
							
			}
			
			// if b# in grm are ok			
			if(sum(ipar_rown[.,2]:=="grm")>0){
				row_errors=(ipar_rown[.,2]:=="grm")
				col_offset=sum((ipar_coln:=="b"):+(ipar_coln:=="c"))
				for(r=1;r<=rows(ipar_val);r++){
					if(row_errors[r]==1){
						checkme=ipar_val[r,2+col_offset..cols(ipar_val)]'
						if(check_miss){
							if(checkme==sort(checkme,1)){
								row_errors[r]=0
							}
						}
						else{
							checkme=select(checkme,checkme:!=.)
							if(checkme==sort(checkme,1)){
								row_errors[r]=0
							}						
						}
					}
				}
				if(sum(row_errors)){
					stata("di as err "+char(34)+"{p 0 2}"+ strofreal(sum(row_errors)) + " items in item parameter matrix ("+ipar+") have incorrect b# parameters for grm:{p_end}"+char(34))
					select_err=select(ipar_rown,row_errors),select(strofreal(ipar_val[.,2+col_offset..cols(ipar_val)]),row_errors)
					di_matrix_as_err(select_err,(("item","model"),ipar_coln'[2+col_offset..cols(ipar_val)]))
					_error("b# parameters in grm have to be in increasing order starting from b1")
				}
				
			}
			
			// if b# in pcm|gpcm are nonmissing
			if(check_miss){
				if(sum((rowsum(J(1,2,ipar_rown[.,2]):==("pcm","gpcm")):==1))>0){
					row_errors=(rowsum(J(1,2,ipar_rown[.,2]):==("pcm","gpcm")):==1)
					col_offset=sum((ipar_coln:=="b"):+(ipar_coln:=="c"))
					for(r=1;r<=rows(ipar_val);r++){
						if(row_errors[r]==1){
							checkme=ipar_val[r,2+col_offset..cols(ipar_val)]
							if(nonmissing(checkme)==nonmissing(checkme[1..nonmissing(checkme)])){
								row_errors[r]=0
							}
						}
					}
					if(sum(row_errors)){
						stata("di as err "+char(34)+"{p 0 2}"+ strofreal(sum(row_errors)) + " items in item parameter matrix ("+ipar+") have incorrect b# parameters for pcm|gpcm:{p_end}"+char(34))
						select_err=select(ipar_rown,row_errors),select(strofreal(ipar_val[.,2+col_offset..cols(ipar_val)]),row_errors)
						di_matrix_as_err(select_err,(("item","model"),ipar_coln'[2+col_offset..cols(ipar_val)]))
						_error("b# parameters in pcm|gpcm have to start from b1 without missings until the last category")
					}
					
				}
			}
			
		}
		
		//////////////////////////////////////////////////////////////
		//icats
		if(checklist[2]){
		
			icats_rown=st_matrixrowstripe(icats)[.,2]
			icats_coln=st_matrixcolstripe(icats)[.,2]
			icats_val=st_matrix(icats)
			
			// proper size
			if(cols(icats_val)<2){
				stata("di as err "+char(34)+"{p 0 2}item categories matrix ("+icats+") has "+strofreal(cols(icats_val))+" columns{p_end}"+char(34))
				_error("at least 2 columns are required")
			}
			if(rows(icats_val)<1){
				stata("di as err "+char(34)+"{p 0 2}item parameter matrix ("+icats+") has "+strofreal(rows(icats_val))+" rows{p_end}"+char(34))
				_error("at least 1 row is required")
			}

			// if colnames are ok
			proper_colnames="cat_":+strofreal((1..cols(icats_val)))
			if( sum(rowsum((icats_coln':==proper_colnames)):==cols(icats_val))!=1 ){
				stata("di as err "+char(34)+"{p 0 2}category names in item categories matrix ("+icats+") are incorrect{p_end}:"+char(34))
				di_matrix_as_err(icats_coln',J(0,cols(icats_val),""))
				stata("di as err "+char(34)+"{p 0 2}for a "+strofreal(cols(icats_val))+"-column item categories matrix correct entries can be only{p_end}:"+char(34))
				di_matrix_as_err(proper_colnames,J(0,cols(icats_val),""))
				_error("provide proper column names of item categories matrix")
			}
		
			// if item names are unique
			dup_items=rows(icats_rown)-rows(uniqrows(icats_rown))
			if(dup_items){
				stata("di as err "+char(34)+ "{p 0 2}duplicate item names in item categories matrix ("+icats+"); surplus="+strofreal(dup_items)+"{p_end}"+char(34))
				_error("duplicate item names are not allowed")
			}
			
			// if cat_# values are ok			
			row_errors_order=J(rows(icats_val),1,1)
			row_errors_uniq=J(rows(icats_val),1,1)
			row_errors_N=J(rows(icats_val),1,1)
			for(r=1;r<=rows(icats_val);r++){
				if(icats_val[r,.]' == sort(icats_val[r,.]',1)){
					row_errors_order[r]=0
				}
				if( nonmissing(uniqrows(icats_val[r,.]')) == nonmissing(icats_val[r,.]') ){
					row_errors_uniq[r]=0
				}
				if(nonmissing(uniqrows(icats_val[r,.]'))>1){
					row_errors_N[r]=0
				}			
			}
			if(sum(row_errors_order)){
				stata("di as err "+char(34)+"{p 0 2}"+ strofreal(sum(row_errors_order)) + " items in item categories matrix ("+icats+") have incorrect cat_# entries:{p_end}"+char(34))
				select_err=select(icats_rown,row_errors_order),select(strofreal(icats_val),row_errors_order)
				di_matrix_as_err(select_err,("item",icats_coln'))
				_error("nonmissing cat_# entries have to be in increasing order starting from cat_1")
			}
			if(sum(row_errors_uniq)){
				stata("di as err "+char(34)+"{p 0 2}"+ strofreal(sum(row_errors_uniq)) + " items in item categories matrix ("+icats+") have duplicate cat_# entries:{p_end}"+char(34))
				select_err=select(icats_rown,row_errors_uniq),select(strofreal(icats_val),row_errors_uniq)
				di_matrix_as_err(select_err,("item",icats_coln'))
				_error("nonmissing cat_# entries have to be unique")
			}
			if(sum(row_errors_N)){
				stata("di as err "+char(34)+"{p 0 2}"+ strofreal(sum(row_errors_N)) + " items in item categories matrix ("+icats+") have only a single cat_# entry:{p_end}"+char(34))
				select_err=select(icats_rown,row_errors_N),select(strofreal(icats_val),row_errors_N)
				di_matrix_as_err(select_err,("item",icats_coln'))
				_error("at least 2 cat_# entries are required for each item")
			}
			
			//if ipar models are ok with cat number
			if(checklist[1] & check_miss){
				row_errors=J(rows(icats_val),1,0)
				model_err=J(0,2,"")
				for(r=1;r<=rows(icats_rown);r++){
					ipar_ind=select(1::rows(ipar_rown),ipar_rown[.,1]:==icats_rown[r])
					if(rows(ipar_ind)){
						if( (sum(ipar_rown[ipar_ind,2]:==("2plm","3plm"))==1) & nonmissing(icats_val[r,.])>2 ){
							row_errors[r]=1
							model_err=model_err\(ipar_rown[ipar_ind,2],"2 cats vs. "+strofreal(nonmissing(icats_val[r,.]))+" cats")
						}
						if( (sum(ipar_rown[ipar_ind,2]:==("2plm","3plm"))==0) & (nonmissing(icats_val[r,.])!=nonmissing(ipar_val[ipar_ind,.])) ){
							row_errors[r]=1
							model_err=model_err\(ipar_rown[ipar_ind,2],strofreal(nonmissing(ipar_val[ipar_ind,.]))+" cats vs. "+strofreal(nonmissing(icats_val[r,.]))+" cats")
						}
					}
				}
				
				if(sum(row_errors)){
					stata("di as err "+char(34)+"{p 0 2}"+ strofreal(sum(row_errors)) + " items in categories matrix ("+icats+") are in conflict with model specification in item parameter matrix ("+ipar+"):{p_end}"+char(34))
					select_err=select(icats_rown,row_errors),model_err,select(strofreal(icats_val),row_errors)
					di_matrix_as_err(select_err,(("item","model","conflict"),icats_coln'))
					_error("item model name and number of parameters have to be in sync with number of item categories")
				}
			}
										
		}
		
		
		//////////////////////////////////////////////////////////////
		//grpar
		if(checklist[3]){
		
			grpar_rown=st_matrixrowstripe(grpar)[.,2]
			grpar_coln=st_matrixcolstripe(grpar)[.,2]
			grpar_val=st_matrix(grpar)
			
			// proper size
			if(cols(grpar_val)==0){
				stata("di as err "+char(34)+"{p 0 2}group parameter matrix ("+grpar+") has "+strofreal(cols(grpar_val))+" columns{p_end}"+char(34))
				_error("at least 1 column is required")
			}
			if(grpar_rown!=("mean"\"sd")){
				stata("di as err "+char(34)+"{p 0 2}parameter names in rows of group parameter matrix ("+grpar+") are incorrect:{p_end}"+char(34))
				di_matrix_as_err(grpar_rown,J(0,1,""))
				stata("di as err "+char(34)+"{p 0 2}group parameter matrix must have 2 rows that are named:{p_end}"+char(34))
				di_matrix_as_err(("mean"\"sd"),J(0,1,""))
				_error("provide proper row names of group parameter matrix")
			}
			
			// proper group names
			if(sum(strpos(grpar_coln,"group_"))!=rows(grpar_coln)){
				stata("di as err "+char(34)+"{p 0 2}column names of group parameter matrix ("+grpar+") are incorrect:{p_end}"+char(34))
				di_matrix_as_err(grpar_coln',J(0,rows(grpar_coln),""))
				_error("columns should be named "+char(34)+"group_#"+char(34)+", where "+char(34)+"#"+char(34)+" are numbers that indicate groups")
			}
			if(rows(uniqrows(grpar_coln))!=rows(grpar_coln)){
				stata("di as err "+char(34)+ "{p 0 2}duplicate group names in group parameter matrix ("+grpar+"); surplus="+strofreal(rows(grpar_coln)-rows(uniqrows(grpar_coln)))+":{p_end}"+char(34))
				di_matrix_as_err(grpar_coln',J(0,rows(grpar_coln),""))
				_error("duplicate group names are not allowed")
			}
			if(missing(strtoreal(subinstr(grpar_coln,"group_","")))>0){
				stata("di as err "+char(34)+"{p 0 2}column names of group parameter matrix ("+grpar+") are incorrect:{p_end}"+char(34))
				di_matrix_as_err(grpar_coln',J(0,rows(grpar_coln),""))
				_error("columns should be named "+char(34)+"group_#"+char(34)+", where "+char(34)+"#"+char(34)+" are numbers that indicate groups")
			}
			
			//if parameter values are ok
			if(check_miss){
				if(missing(grpar_val)){
					stata("di as err "+char(34)+"{p 0 2}group parameter matrix ("+grpar+") has "+strofreal(missing(grpar_val))+" missing values{p_end}"+char(34))
					_error("all group parameters must be nonmissing")
				}
			}
			col_errors=(grpar_val[2,.]:<=0)
			if(sum(col_errors)){
				stata("di as err "+char(34)+"{p 0 2}"+ strofreal(sum(col_errors)) + " groups in group parameter matrix ("+grpar+") have incorrect standard deviation:{p_end}"+char(34))
				col_errors_ind=select(1::cols(grpar_val),col_errors')'
				select_err=grpar_rown[2],strofreal(grpar_val[2,col_errors_ind])
				di_matrix_as_err(select_err,("",grpar_coln'[col_errors_ind]))
				_error("standard deviation has to be positive")
			}
			
	
		}
		
		
	}
		
	
	void di_matrix_as_err(string matrix to_disp, string matrix colnames){
		todisp=colnames\to_disp
		todi=todisp[.,1]
		if(cols(todisp)>1){
			for(c=2;c<=cols(todisp);c++){
				todi=todi:+ (" ":*(5:+max(strlen(todisp[.,c-1])):-strlen(todisp[.,c-1]))) + todisp[.,c]
			}
		}
		for(r=1;r<=rows(todi);r++){
			stata("di as err "+char(34)+todi[r]+char(34))
		}
	}
	
	
	pointer colvector return_data_pointers(_Q,_G){
	
		class ITEMS scalar Q
		Q=_Q

		class GROUPS scalar G
		G=_G

		group_rec_data=G.data
		N_gr=G.n
		item_group_totalobs=Q.get(Q.g_tot,.)
		point_item_cats=Q.get(Q.p_cat,.)
				
		N_itms			= Q.n
		itemlist	= Q.get(Q.names,.)
		items=""
		for(i=1;i<=N_itms;i++){
			items=items+" "+itemlist[i]			
		}
		
		N_obs = st_nobs()
		
		Theta_id = select((1::N_obs),group_rec_data:!=.)
		N_Theta_id=rows(Theta_id)
		Theta_id_sorted=J(N_Theta_id,1,.)
		Theta_dup = J(N_Theta_id,1,.)
			
	
	//	establishing pointers and sorting stuff
		point_Uigc=J(N_itms,N_gr,NULL)
		point_Fg=J(N_gr,1,NULL)
		row_Theta_dup=1
		for(g=1;g<=N_gr;g++){
			
			Theta_id_g = select(Theta_id,group_rec_data[Theta_id]:==g)
			N_Theta_id_g=rows(Theta_id_g)			
			
			
			itemselectrange_g = select((1::N_itms),item_group_totalobs[.,g]:>0)
			itemlist_g =  itemlist[itemselectrange_g]
			point_item_cats_g = point_item_cats[itemselectrange_g]
			I_g = rows(itemlist_g)
			
			U_g=sort((st_data(Theta_id_g,itemlist_g'),Theta_id_g),(1..I_g+1))
			
			Theta_id_sorted[ (nonmissing(Theta_id_sorted)+1) :: (nonmissing(Theta_id_sorted)+N_Theta_id_g)]=U_g[.,I_g+1]
			U_g=U_g[.,(1..I_g)]
			
			Fg=J(N_Theta_id_g,1,.)
			unique_pattern_rows=J(N_Theta_id_g,1,0)
			pattern=U_g[1,.]
			counter=0
			rowFg=1
			for(j=1;j<=N_Theta_id_g;j++){
				if(rowsum(U_g[j,.]:==pattern)==I_g){
					counter++
					if(j>1){
						Theta_dup[row_Theta_dup]=Theta_dup[row_Theta_dup-1]
					}
					else{
						if(g==1){
							Theta_dup[row_Theta_dup]=1
						}
						else{
							Theta_dup[row_Theta_dup]=max(Theta_dup)+1
						}
					}
				}
				else{
					unique_pattern_rows[j-1]=1
					Fg[rowFg]=counter
					Theta_dup[row_Theta_dup]=Theta_dup[row_Theta_dup-1]+1
					pattern=U_g[j,.]
					counter=1
					rowFg++
				}
				row_Theta_dup++
			}
			Fg[rowFg]=counter
			unique_pattern_rows[j-1]=1		
			U_g=select(U_g,unique_pattern_rows)
	
	//	establishing pointer to fweights	
				point_Fg[g]=return_pointer(Fg[1::nonmissing(Fg)])
				
	//	establishing pointers to category ranges
				for(i=1;i<=I_g;i++){
					point_Uigc[i,g]=&return_category_range_pointers(*point_item_cats_g[i],U_g[.,i])
				}
			}
	
		
			
	// getting rid of these huge matrices
			Theta_id_g=J(0,0,.)
			Fg=J(0,0,.)
			U_g=J(0,0,.)
			G.data=J(0,0,.)
	
			for(g=1;g<=N_gr;g++){
				G.put(G.n_uniq,g,rows(*point_Fg[g]))
				G.put(G.n_total,g,sum(*point_Fg[g]))
			}			
		
		results = J(4,1,NULL)
		results[1] = &point_Uigc
		results[2] = &point_Fg
		results[3] = &Theta_id_sorted
		results[4] = &Theta_dup
		return(results)
	}
	
	void check_sx2(_Q, _G, string matrix sx2_fitlist){
		class ITEMS scalar Q
		Q=_Q
	
		class GROUPS scalar G
		G=_G
	
		if(G.n==1){
			
			viable_for_sx2= (Q.get(Q.g_tot,.):==G.get(G.n_total,.)) :* (Q.get(Q.n_cat,.):==2)
			
			if_fit_sx2=J(Q.n,1,0)
			items_missing_or_ncat="     "
			N_missing_or_ncat=0
			
			for(i=1;i<=rows(sx2_fitlist);i++){
				if(sum( (Q.get(Q.names,.):==sx2_fitlist[i]):*viable_for_sx2 )){
					if_fit_sx2=if_fit_sx2:+(Q.get(Q.names,.):==sx2_fitlist[i])
				}
				else{
					items_missing_or_ncat=items_missing_or_ncat+" "+sx2_fitlist[i]
					N_missing_or_ncat=N_missing_or_ncat+1
				}
			}
						
			N_for_sx2_required=3
			if_fit_sx2_models=select(Q.get(Q.m_asked,.),if_fit_sx2)
			if(sum(if_fit_sx2_models:=="3plm")){
				N_for_sx2_required=N_for_sx2_required+3
			}
			else{
				if(sum(if_fit_sx2_models:=="2plm")+sum(if_fit_sx2_models:=="grm")+sum(if_fit_sx2_models:=="gpcm")){
					N_for_sx2_required=N_for_sx2_required+2
				}
				else{
					if(sum(if_fit_sx2_models:=="pcm")){
						N_for_sx2_required=N_for_sx2_required+1
					}
				}
			}
			
			if(N_missing_or_ncat){
				display("Note: "+strofreal(N_missing_or_ncat)+" items specified for SX2 fit statistic have missing responses, are polytomous, or were discarded:")
				display(items_missing_or_ncat)
				if(sum(if_fit_sx2)){
					display( "      "+ strofreal(sum(if_fit_sx2)) + " items left for SX2")
				}
				else{
					display( "      no valid items left for SX2")
				}
			}

			if(sum(if_fit_sx2)){			
				if(N_for_sx2_required>sum(viable_for_sx2)){
					display("Note: To compute SX2 fit statistic there need to be at least "+strofreal(N_for_sx2_required)+" dichotomously scored items with no missing values in your test,")
					display("      there is only "+strofreal(sum(viable_for_sx2))+" such items, SX2 will not be computed")
					if_fit_sx2=J(Q.n,1,0)
					viable_for_sx2=J(Q.n,1,0)
				}
			}
		}
		else{
			if_fit_sx2=J(Q.n,1,0)
			viable_for_sx2=J(Q.n,1,0)
			display("Note: SX2 is implemented only for a single group setting, you defined "+strofreal(G.n)+" groups, SX2 will not be computed")
		}
		
		Q.put(Q.fit_sx2,.,if_fit_sx2)
		Q.put(Q.viable_sx2,.,viable_for_sx2)
		
	}
	
	void graph_save(string scalar icc_format, string scalar filename){
		if(icc_format=="gph"){
			stata("qui graph save "+filename+", replace")
		}
		if(icc_format=="eps"){
				stata("qui graph export "+filename+".eps,  mag(200)  replace")
		}
		if(icc_format=="png"){
			if("`c(os)'"=="Windows"){
				stata("qui graph export "+filename+".png, width(1244) replace")
			}
			if("`c(os)'"=="Unix"){
								
				if(fileexists(filename+".png")){
					unlink(filename+".png")
				}
				errcode = _stata("cap graph export "+filename+".png, width(1244) replace")
				if(errcode | fileexists(filename+".png")==0 ){
					stata("qui graph export "+filename+".eps,  mag(200)  replace")
					stata("! gs -dSAFER -dEPSCrop -r160 -sDEVICE=pngalpha -o "+filename+".png "+filename+".eps")
					if(fileexists(filename+".png")){
						unlink(filename+".eps")
					}
					else{
						display("unable to perform: ! gs -dSAFER -dEPSCrop -r160 -sDEVICE=pngalpha -o "+filename+".png "+filename+".eps")
					}
				}							
		
			}
		}
	}
	
	void inf_graph(_Qx, _G, real matrix if_makeinf, string scalar inf_twoway, real scalar inf_mode , string matrix eap_names , real scalar if_groups){
		
		class ITEMS scalar Qx
		Qx = _Qx
		class GROUPS scalar G
		G=_G
		
		
		
		n_sel = sum(if_makeinf)
	
		if(n_sel){
		
			i_names		= J(n_sel,1,"")
			i_functions	= J(n_sel,1,"")
			
			r=0
			for(i=1;i<=Qx.n;i++){
				if(if_makeinf[i]){
					++r
					i_name			= Qx.get(Qx.names,i)								
					i_names[r]  	= i_name
					i_functions[r] = item_information_function( selectQ(Qx,i_name) )
				}
			}
			
			if(cols(eap_names)==2){
				thetan=eap_names[1]
			}
			else{
				thetan="theta"
			}

			if(inf_mode==0){
			
				i_functions = "( function " :+ i_functions :+ ",range(-4 4) yvarlab(" :+ i_names :+ ") )"
				
				stata_command = "qui twoway "
				for(i=1;i<=n_sel;i++){
					stata_command = stata_command + i_functions[i] + " || "*(i<n_sel)
				}
				
				if(n_sel>1){
					title = " title(Item information functions) "
					legend = "legend(c(5))"
				}
				else{
					title = " title(Information function for item "+i_names[1]+") "
					legend = " legend(off) "
				}
				
				ytitle =  " ytitle("+char(34)+"I({&theta})"+char(34)+") "
				
			}
			else{
				
				if(G.n>1 & if_groups){
					th_sd = strofreal(G.get(G.pars,.)[.,2])
					gr_names = G.v_name :+ "=" :+ strofreal(G.get(G.val,.))
					legend = " legend(c(4)) "
				}
				else{
					th_sd = strofreal(G.get(G.pars,1)[2])
					gr_names = strofreal(G.get(G.val,1))
					legend = " legend(off) "
				}
			
				tif = "(  (1/" :+ th_sd :+ "^2) +"
				for(i=1;i<=n_sel;i++){
					tif = tif :+ " ( " :+ i_functions[i] :+ " ) " :+ " + "*(i<n_sel)
				}
				tif = tif :+ ")"
				
				stata_command = "qui twoway "
				
				if(inf_mode==1){
					for(g=1;g<=rows(tif);g++){
						stata_command =  stata_command + " ( function " + tif[g] + ", range(-4 4)  yvarlab(" + gr_names[g] + ") ) " + " || "*(g<rows(tif))
					}				
					ytitle =  " ytitle("+char(34)+"I({&theta})"+char(34)+") "
					title = " title(Test information function) "
				}
	
				if(inf_mode==2){
					for(g=1;g<=rows(tif);g++){
						stata_command =  stata_command + " ( function (1/sqrt(" + tif[g] + ")), range(-4 4)  yvarlab(" + gr_names[g] + ") ) " + " || "*(g<rows(tif)) 
					}					
					ytitle = " ytitle("+char(34)+"Standard error"+char(34)+") "
					title = " title(Standard error of {&theta} estimates) "
				}
			
			}
			
			stata_command= stata_command + ", graphregion(color(white)) bgcolor(white) xscale(range(-4 4)) xtitle("+char(34)+thetan+char(34)+") " + ytitle + title + legend + inf_twoway

			
			stata(stata_command)

		}
	}
	
	
	
	string scalar item_information_function(_Qi){
	
		class ITEMS scalar Qi
		Qi=_Qi	
	
		n_cat=Qi.get(Qi.n_cat,.)
		model=Qi.get(Qi.m_curr,.)
		pars=strofreal(Qi.get(Qi.pars,.))
		
		stata_command=""
		
		if(n_cat==2){
		
			_a = pars[1]
			_b = pars[2]
				
			if (model=="2plm" | model=="pcm"){
				_f = "( invlogit(" + _a + "*(x-" + _b + ")) )"
				stata_command=stata_command + _a + "^2 * " + _f + " * (1 -" + _f + ")"
			}
			if (model=="3plm" ){
				_c=pars[3]
				_f = "( " + _c + " + (1-" + _c + ")*invlogit(" + _a + "*(x-" + _b + ")) )"
				_v =  "( (" + _f + " - " + _c + ") / (" + _f + " * (1 - " + _c + " )" + ") )"
				stata_command=stata_command + _a + "^2 * " + _f + " * (1 -" + _f + ") * " + _v + "^2"
			}
							
		}
		
		if(n_cat>2){
		
			_a=pars[1]
					
			if ( model=="grm"){
			
				_fk = "( invlogit(" :+ _a :+ "*(x-" :+ pars[2..cols(pars)]' :+ ")) )"
				_fk = "1" \ _fk \ "0"
				_qk = "(1 -" :+ _fk :+ ")"
				
				stata_command=stata_command + _a + "^2 * ("
				for(c=2;c<=rows(_fk);c++){
					stata_command=stata_command + (c>2)*" + " + "( ( " + _fk[c-1] + "*" + _qk[c-1] + " - " + _fk[c] + "*" + _qk[c] + " )^2 / ("+ _fk[c-1] + " - "+ _fk[c] + ") )"
				}
				stata_command=stata_command + ")"
			
			}
			if (model!="grm"){
			
				pars_num=Qi.get(Qi.pars,.)
			
				expsum_all_function="(1 "
				for(c=2;c<=n_cat;c++){
					expsum_all_function=expsum_all_function + " + " + "exp(" + _a + "*(" + strofreal(c-1) + "*x-(" + strofreal(sum(pars_num[2..c])) + ")))"
				}
				expsum_all_function=expsum_all_function+")"
				
				_fk = "1"
				for(c=2;c<=n_cat;c++){
					_fk = _fk \ "exp(" + _a + "*(" + strofreal(c-1) + "*x-(" + strofreal(sum(pars_num[2..c])) + ")))"				
				}
				_fk = _fk :+ " / " :+ expsum_all_function
				
				_t = "("
				for(c=1;c<=rows(_fk);c++){
					_t = _t + (c>1)*" + " + strofreal(c-1) + " * (" + _fk[c] + ")" 
				}
				_t = _t+ ")"
				
				stata_command=stata_command + _a + "^2 * ("
				for(c=1;c<=rows(_fk);c++){
					stata_command=stata_command + (c>1)*" + " + "( ( " + strofreal(c-1) + " - " + _t + " )^2 * " + _fk[c] + " )"
				}
				stata_command=stata_command + ")"
				
			}
			
			
		}
			
		return(stata_command)
	}
	
		
end
