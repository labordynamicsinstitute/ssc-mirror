*! stanrun v2.1.0 - Modern interface to CmdStan with Variational Inference
*! Author: Ben A. Dwamena, University of Michigan
*! Enhanced from StataStan (Robert Grant & Mustafa Ascha)
*! Date: 2026-03-09
*! Requires: CmdStan 2.26 or higher, RTools (Windows)
*! Description: Runs Bayesian models via CmdStan with HMC/NUTS and ADVI support

capture program drop stanrun

program define stanrun
    version 14.0
    syntax varlist [if] [in] , ///
        /// File specifications
        MODELfile(string) ///
        [ DATAfile(string) OUTPUTfile(string) ///
        CHAINFile(string) MODESfile(string) INITsfile(string) ///
        WINLOGfile(string) ///
        /// Model specification
        INLINE THISFILE(string) RERUN ///
        /// Sampling parameters
        CHAINS(integer 4) WARMUP(integer 1000) ITER(integer 1000) ///
        THIN(integer 1) SEED(integer -1) ///
        /// Parallelization
        THREADS(integer -1) THREADSperchain(integer -1) ///
        PARallel NOWait ///
        /// HMC tuning
        STEPSIZE(real -1) STEPSIZEJITTER(real 0) ///
        ADAPTdelta(real -1) MAXtreedepth(integer -1) ///
        /// Variational Inference
        VARiational VIalgorithm(string) VIiter(integer 10000) ///
        VIgrad_samples(integer 1) VIelbo_samples(integer 100) ///
        VIeta(real -1) VIadapt_engaged(integer 1) VIadapt_iter(integer 50) ///
        VItol_rel_obj(real 0.01) VIeval_elbo(integer 100) ///
        VIoutput_samples(integer 1000) ///
        /// Operations
        MODE OPTIMize DIAGnose LOAD ///
        /// Data handling
        SKipmissing MATrices(string) GLobals(string) ///
        /// System
        CMDstandir(string) KEEPFiles NOPywarn VERbose LOG ]

    /*
    =============================================================================
    STANRUN v2.1 - Modern CmdStan Interface for Stata
    =============================================================================
    Changes in v2.1.0 (2026-03-09):
      - Replaced windowsmonitor with synchronous shell execution
      - Updated Stan array syntax for CmdStan 2.33+
      - Added automatic RTools detection (4.2-4.5)
      - Added CSV import/load step for posterior draws
      - Fixed variable naming for Stata 19.5 import delimited
      - Added quiet mode (suppress CmdStan output unless verbose)
      - Skips recompilation when executable already exists
    =============================================================================
    */

    // =========================================================================
    // Platform check
    // =========================================================================
    if lower("$S_OS") != "windows" {
        di as error "stanrun v2.1 currently supports Windows only."
        di as error "Detected OS: `=lower("$S_OS")'"
        exit 498
    }

    // =========================================================================
    // Version and compatibility checks
    // =========================================================================
    local stanrunversion "2.1.0"
    local stataver = c(stata_version)

    // Verbose inherits from log option
    if "`log'" != "" & "`verbose'" == "" {
        local verbose "verbose"
    }

    if `stataver' > 15.9 & "`nopywarn'" == "" & "`verbose'" != "" {
        di as text "{hline}"
        di as text "Note: Stata `stataver' detected. Since version 16.0, Stan can also"
        di as text "be accessed via Python integration (CmdStanPy)."
        di as text "Use option {cmd:nopywarn} to suppress this message."
        di as text "{hline}"
    }

    // =========================================================================
    // Setup and validation
    // =========================================================================
    local wdir "`c(pwd)'"
    local cdir "`cmdstandir'"

    if "`cdir'" == "" {
        local cdir "$CMDSTAN"
        if "`cdir'" == "" {
            di as error "CmdStan directory not specified."
            di as error "Either use cmdstandir() option or set global CMDSTAN."
            error 198
        }
    }

    // Verify CmdStan installation
    capture confirm file "`cdir'/bin/stanc"
    if _rc {
        capture confirm file "`cdir'/bin/stanc.exe"
        if _rc {
            di as error "CmdStan not found at: `cdir'"
            di as error "Please verify your CmdStan installation path."
            error 601
        }
    }

    // Get CmdStan version
    tempfile cmdstanversioncheck
    shell "`cdir'\bin\stanc" --version > "`cmdstanversioncheck'"
    capture {
        file open cv using "`cmdstanversioncheck'", read text
        file read cv cvline
        local cmdstanversion = substr("`cvline'", 15, .)
        file close cv
    }
    if "`cmdstanversion'" == "" {
        local cmdstanversion "unknown"
    }

    if "`verbose'" != "" {
        di as result "{hline}"
        di as result "STANRUN version: `stanrunversion'"
        di as result "CmdStan version: `cmdstanversion'"
        di as result "Stata version: `stataver'"
        di as result "Working directory: `wdir'"
        di as result "{hline}"
    }

    qui shell del "`cmdstanversioncheck'" >nul 2>&1

    // =========================================================================
    // File name defaults and validation
    // =========================================================================
    if "`datafile'" == "" {
        local datafile "stanrun_data.R"
    }
    if "`modelfile'" == "" {
        local modelfile "stanrun_model.stan"
    }
    if "`outputfile'" == "" {
        local outputfile "output"
    }
    if "`modesfile'" == "" {
        local modesfile "modes.csv"
    }
    if "`chainfile'" == "" {
        local chainfile "stanrun_chains.csv"
    }
    if "`winlogfile'" == "" {
        local winlogfile "stanrun_winlog.txt"
    }

    // Verify model file ends in .stan
    local lenmod = length("`modelfile'")
    if substr("`modelfile'", `lenmod' - 4, 5) != ".stan" {
        di as error "Model file must end in .stan"
        error 198
    }

    // Check for name conflicts
    if "`chainfile'" == "`outputfile'" | "`chainfile'" == "`outputfile'.csv" {
        di as error "chainfile and outputfile cannot have the same name"
        error 198
    }

    // Create executable file name
    local lenmod = `lenmod' - 5
    local execfile = substr("`modelfile'", 1, `lenmod')
    local cppfile  "`execfile'.hpp"
    local execfile "`execfile'.exe"

    // =========================================================================
    // Handle initial values
    // =========================================================================
    if "`initsfile'" == "" {
        local initlocation = 1
    }
    else {
        local initlocation "`wdir'\\`initsfile'"
    }

    // =========================================================================
    // Variational Inference setup
    // =========================================================================
    if "`variational'" == "variational" {

        if "`vialgorithm'" == "" {
            local vialgorithm "meanfield"
        }
        else if !inlist("`vialgorithm'", "meanfield", "fullrank") {
            di as error "vialgorithm must be 'meanfield' or 'fullrank'"
            error 198
        }

        local vicom "method=variational algorithm=`vialgorithm'"
        local vicom "`vicom' iter=`viiter'"
        local vicom "`vicom' grad_samples=`vigrad_samples'"
        local vicom "`vicom' elbo_samples=`vielbo_samples'"

        if `vieta' > 0 {
            local vicom "`vicom' eta=`vieta'"
        }

        local vicom "`vicom' adapt engaged=`viadapt_engaged'"
        local vicom "`vicom' adapt iter=`viadapt_iter'"
        local vicom "`vicom' tol_rel_obj=`vitol_rel_obj'"
        local vicom "`vicom' eval_elbo=`vieval_elbo'"
        local vicom "`vicom' output_samples=`vioutput_samples'"

        if `chains' > 1 {
            local chains = 1
        }

        if "`mode'" == "mode" | "`optimize'" == "optimize" {
            local mode ""
            local optimize ""
        }

        if "`verbose'" != "" {
            di as result "Variational Inference: `vialgorithm', max iter=`viiter', output_samples=`vioutput_samples'"
        }
    }
    else {
        local vicom ""
    }

    // =========================================================================
    // Parallelization setup
    // =========================================================================
    if `chains' < 1 {
        di as error "Must specify at least 1 chain"
        error 198
    }

    if "`variational'" != "variational" {

        if `threadsperchain' > 0 {
            local threadcom "num_threads=`threadsperchain'"
        }
        else if `threads' > 0 {
            local threadsperchain = floor(`threads' / `chains')
            if `threadsperchain' < 1 {
                local threadsperchain = 1
            }
            local threadcom "num_threads=`threadsperchain'"
        }
        else {
            local threadcom ""
            local threadsperchain = 1
        }

        if "`parallel'" == "parallel" {
            local doparallel = 1
        }
        else {
            local doparallel = 0
        }

        if "`nowait'" == "nowait" {
            local waitflag ""
        }
        else {
            local waitflag "/w"
        }
    }
    else {
        local threadcom ""
        local doparallel = 0
    }

    // =========================================================================
    // Sampling parameter setup
    // =========================================================================
    if `seed' == -1 {
        local seedcom ""
    }
    else {
        local seedcom "random seed=`seed'"
    }

    if "`variational'" != "variational" {

        if `warmup' == -1 {
            local warmcom ""
        }
        else {
            local warmcom "num_warmup=`warmup'"
        }

        if `iter' == -1 {
            local itercom ""
        }
        else {
            local itercom "num_samples=`iter'"
        }

        if `thin' == -1 {
            local thincom ""
        }
        else {
            local thincom "thin=`thin'"
        }

        if `stepsize' == -1 {
            local stepcom ""
        }
        else {
            local stepcom "stepsize=`stepsize'"
        }

        if `stepsizejitter' > 0 {
            local stepjcom "stepsize_jitter=`stepsizejitter'"
        }
        else {
            local stepjcom ""
        }

        if `adaptdelta' == -1 {
            local adaptcom ""
        }
        else {
            if `adaptdelta' < 0 | `adaptdelta' > 1 {
                di as error "adaptdelta must be between 0 and 1"
                error 198
            }
            local adaptcom "adapt delta=`adaptdelta'"
        }

        if `maxtreedepth' == -1 {
            local treedepthcom ""
        }
        else {
            local treedepthcom "algorithm=hmc engine=nuts max_depth=`maxtreedepth'"
        }

        if "`verbose'" != "" {
            di as result "MCMC: `chains' chains, `warmup' warmup, `iter' samples, thin=`thin'"
        }
    }

    // =========================================================================
    // Check for existing output files
    // =========================================================================
    local outputcheck "`wdir'\\stanrun_outputcheck.tmp"

    shell if exist "`cdir'\\`outputfile'*.csv" (echo yes) else (echo no) > "`outputcheck'"
    capture confirm file "`outputcheck'"
    if !_rc {
        file open oc using "`outputcheck'", read text
        file read oc ocline
        file close oc
        if "`ocline'" == "yes" {
            di as error "Files named `outputfile'*.csv already exist in `cdir'"
            di as error "Please rename or delete them first."
            capture erase "`outputcheck'"
            error 602
        }
    }

    shell if exist "`wdir'\\`outputfile'*.csv" (echo yes) else (echo no) > "`outputcheck'"
    capture confirm file "`outputcheck'"
    if !_rc {
        file open oc using "`outputcheck'", read text
        file read oc ocline
        file close oc
        if "`ocline'" == "yes" {
            di as error "Files named `outputfile'*.csv already exist in `wdir'"
            di as error "Please rename or delete them first."
            capture erase "`outputcheck'"
            error 602
        }
    }
    capture erase "`outputcheck'"

    // =========================================================================
    // Data preparation
    // =========================================================================
    preserve
    if "`if'" != "" | "`in'" != "" {
        keep `if' `in'
    }

    if "`skipmissing'" != "skipmissing" {
        local n_orig = _N
        foreach v of local varlist {
            qui count if `v' != .
            local nthisvar = r(N)
            qui drop if `v' == . & `nthisvar' > 1
        }
        local n_final = _N
        if `n_orig' != `n_final' {
            local n_dropped = `n_orig' - `n_final'
            if "`verbose'" != "" {
                di as text "Dropped `n_dropped' observations with missing values"
            }
        }
    }

    // =========================================================================
    // Write data and model files
    // =========================================================================
    capture noisily {

        // Handle inline model specification
        if "`inline'" != "" {

            tempname fin
            tempfile tdirls
            local tdir "`c(tmpdir)'"

            if "`thisfile'" == "" {
                tempname lsin
                shell dir "`tdir'" -b -o:-D > "`tdirls'"
                capture file close `lsin'
                file open `lsin' using "`tdirls'", read text
                file read `lsin' thisname

                local tempprefix "STD"

                while substr("`thisname'", 1, 3) != "`tempprefix'" & !r(eof) {
                    file read `lsin' thisname
                    if r(eof) {
                        di as error "Could not locate do-file in Stata temporary folder."
                        di as error "Use thisfile() option to specify the path explicitly."
                        capture file close `lsin'
                        error 601
                    }
                }

                local thisfile "`tdir'\`thisname'"
                capture file close `lsin'
            }

            capture file close `fin'
            file open `fin' using "`thisfile'", read text
            file read `fin' line

            tokenize `"`line'"'
            local line1 `"`1'"'
            file read `fin' line
            tokenize `"`line'"'

            while (("`line1'" != "/*" | substr(`"`1'"', 1, 4) != "data") & !r(eof)) {
                local line1 "`1'"
                file read `fin' line
                tokenize `"`line'"'
            }

            if r(eof) {
                di as error "Inline model block not found"
                capture file close `fin'
                error 601
            }

            tempname fout
            capture file close `fout'
            file open `fout' using "`modelfile'", write replace
            file write `fout' "`line'" _n
            file read `fin' line
            while ("`line'" != "*/") {
                file write `fout' "`line'" _n
                file read `fin' line
            }
            file close `fin'
            file close `fout'
        }

        // Write data file in R/S format
        capture file close dataf
        file open dataf using "`datafile'", write text replace

        foreach v of local varlist {
            confirm numeric variable `v'
            qui count if `v' != .
            local nthisvar = r(N)

            if `nthisvar' > 1 {
                file write dataf "`v' <- c("
                if "`skipmissing'" == "skipmissing" {
                    local nlines = 0
                    local i = 1
                    local linedata = `v'[`i']
                    while `nlines' < `nthisvar' {
                        if `linedata' != . & `nlines' < (`nthisvar' - 1) {
                            file write dataf "`linedata', "
                            local ++i
                            local ++nlines
                            local linedata = `v'[`i']
                        }
                        else if `linedata' != . & `nlines' == (`nthisvar' - 1) {
                            file write dataf "`linedata')" _n
                            local ++nlines
                        }
                        else {
                            local ++i
                            local linedata = `v'[`i']
                        }
                    }
                }
                else {
                    forvalues i = 1/`nthisvar' {
                        local linedata = `v'[`i']
                        if `i' < `nthisvar' {
                            file write dataf "`linedata', "
                        }
                        else {
                            file write dataf "`linedata')" _n
                        }
                    }
                }
            }
            else if `nthisvar' == 1 {
                local linedata = `v'[1]
                file write dataf "`v' <- `linedata'" _n
            }
        }

        // Write matrices
        if "`matrices'" != "" {
            if "`matrices'" == "all" {
                local matrices : all matrices
            }
            foreach mat in `matrices' {
                capture confirm matrix `mat'
                if !_rc {
                    local mrow = rowsof(`mat')
                    local mcol = colsof(`mat')

                    if `mrow' == 1 {
                        if `mcol' == 1 {
                            local mval = `mat'[1,1]
                            file write dataf "`mat' <- `mval'" _n
                        }
                        else {
                            file write dataf "`mat' <- c("
                            local mcolminusone = `mcol' - 1
                            forvalues i = 1/`mcolminusone' {
                                local mval = `mat'[1,`i']
                                file write dataf "`mval',"
                            }
                            local mval = `mat'[1,`mcol']
                            file write dataf "`mval')" _n
                        }
                    }
                    else if `mcol' == 1 & `mrow' > 1 {
                        file write dataf "`mat' <- c("
                        local mrowminusone = `mrow' - 1
                        forvalues i = 1/`mrowminusone' {
                            local mval = `mat'[`i',1]
                            file write dataf "`mval',"
                        }
                        local mval = `mat'[`mrow',1]
                        file write dataf "`mval')" _n
                    }
                    else {
                        file write dataf "`mat' <- structure(c("
                        local mrowminusone = `mrow' - 1
                        local mcolminusone = `mcol' - 1
                        forvalues j = 1/`mcolminusone' {
                            forvalues i = 1/`mrow' {
                                local mval = `mat'[`i',`j']
                                file write dataf "`mval',"
                            }
                        }
                        forvalues i = 1/`mrowminusone' {
                            local mval = `mat'[`i',`mcol']
                            file write dataf "`mval',"
                        }
                        local mval = `mat'[`mrow',`mcol']
                        file write dataf "`mval'), .Dim=c(`mrow',`mcol'))" _n
                    }
                }
            }
        }

        // Write global macros
        if "`globals'" != "" {
            if "`globals'" == "all" {
                local globals : all globals
            }
            foreach g in `globals' {
                capture confirm number ${`g'}
                if !_rc {
                    file write dataf "`g' <- ${`g'}" _n
                }
            }
        }

    } // End of capture noisily block

    capture file close dataf
    restore

    // =========================================================================
    // PLATFORM-SPECIFIC EXECUTION (Windows)
    // =========================================================================

    // Copy files to CmdStan directory
    if "`rerun'" != "rerun" {
        shell copy "`wdir'\\`modelfile'" "`cdir'\\`modelfile'" >nul 2>&1
    }
    else {
        shell copy "`wdir'\\`execfile'" "`cdir'\\`execfile'" >nul 2>&1
    }

    qui cd "`cdir'"

    // Compile model (skip if executable already exists)
    if "`rerun'" == "" {
        capture confirm file "`execfile'"
        if _rc {
            di as result "{hline}"
            di as result "COMPILING STAN MODEL"
            di as result "{hline}"

            // Auto-detect RTools
            local rtools_path ""
            foreach rtver in 45 44 43 42 {
                capture confirm file "C:\rtools`rtver'\usr\bin\make.exe"
                if !_rc {
                    local rtools_path "C:\rtools`rtver'"
                    continue, break
                }
            }

            local gpp_path ""
            if "`rtools_path'" != "" {
                foreach gdir in "x86_64-w64-mingw32.static.posix\bin" "mingw64\bin" "usr\bin" {
                    capture confirm file "`rtools_path'\\`gdir'\\g++.exe"
                    if !_rc {
                        local gpp_path "`rtools_path'\\`gdir'"
                        continue, break
                    }
                }
            }

            if "`rtools_path'" == "" {
                di as error "GNU make not found. Please install RTools for Windows."
                di as error "Download from: https://cran.r-project.org/bin/windows/Rtools/"
                error 601
            }

            di as text "Compiling (this may take 1-5 minutes)..."
            if "`gpp_path'" != "" {
                shell set "PATH=`rtools_path'\usr\bin;`gpp_path';%PATH%" && make "`execfile'"
            }
            else {
                shell set "PATH=`rtools_path'\usr\bin;%PATH%" && make "`execfile'"
            }

            capture confirm file "`execfile'"
            if _rc {
                di as error "Compilation failed - executable `execfile' not created"
                error 601
            }
            di as result "Compilation successful"
        }
        else {
            if "`verbose'" != "" {
                di as text "Using existing executable: `execfile'"
            }
        }
        ! copy "`cdir'\\`cppfile'"  "`wdir'\\`cppfile'" >nul 2>&1
        ! copy "`cdir'\\`execfile'" "`wdir'\\`execfile'" >nul 2>&1
    }

    // =====================================================================
    // VARIATIONAL INFERENCE (Windows)
    // =====================================================================
    if "`variational'" == "variational" {
        if "`verbose'" != "" {
            di as result "{hline}"
            di as result "VARIATIONAL INFERENCE (ADVI)"
            di as result "{hline}"
        }

        local _scmd `""`cdir'\\`execfile'" `vicom' `seedcom' output file="`wdir'\\`outputfile'.csv" data file="`wdir'\\`datafile'""'
        if "`verbose'" != "" {
            shell `_scmd'
        }
        else {
            shell `_scmd' >"`wdir'\\stanrun_sampling.log" 2>&1
        }
    }
    // =====================================================================
    // MCMC SAMPLING (Windows)
    // =====================================================================
    else {
        if "`verbose'" != "" {
            di as result "{hline}"
            di as result "SAMPLING"
            di as result "{hline}"
        }

        if `chains' == 1 {
            if "`verbose'" != "" di as result "Running chain 1..."
            local _scmd `""`cdir'\\`execfile'" method=sample `warmcom' `itercom' `thincom' `treedepthcom' `adaptcom' `stepcom' `stepjcom' `threadcom' `seedcom' output file="`wdir'\\`outputfile'.csv" data file="`wdir'\\`datafile'""'
            if "`verbose'" != "" {
                shell `_scmd'
            }
            else {
                shell `_scmd' >"`wdir'\\stanrun_sampling.log" 2>&1
            }
        }
        else {
            forvalues c = 1/`chains' {
                if "`verbose'" != "" {
                    di as result "Running chain `c' of `chains'..."
                }
                else {
                    di as text "." _continue
                }
                local _scmd `""`cdir'\\`execfile'" id=`c' method=sample `warmcom' `itercom' `thincom' `treedepthcom' `adaptcom' `stepcom' `stepjcom' `threadcom' `seedcom' output file="`wdir'\\`outputfile'`c'.csv" data file="`wdir'\\`datafile'""'
                if "`verbose'" != "" {
                    shell `_scmd'
                }
                else {
                    shell `_scmd' >>"`wdir'\\stanrun_sampling.log" 2>&1
                }
            }
            if "`verbose'" == "" di ""
        }
    }

    // =====================================================================
    // LOAD: Import CmdStan CSV output into Stata
    // =====================================================================
    if "`load'" == "load" {
        qui cd "`wdir'"
        if "`verbose'" != "" {
            di as result "{hline}"
            di as result "LOADING POSTERIOR DRAWS"
            di as result "{hline}"
        }

        // Strip comment lines from each chain CSV
        forvalues c = 1/`chains' {
            local csvfile "`outputfile'`c'.csv"
            capture confirm file "`csvfile'"
            if _rc {
                local csvfile "`outputfile'.csv"
                capture confirm file "`csvfile'"
                if _rc {
                    di as error "Output file `csvfile' not found"
                    error 601
                }
            }

            local strippedfile "stanrun_stripped_`c'.csv"
            capture file close _csvin
            capture file close _csvout
            file open _csvin using "`csvfile'", read text
            file open _csvout using "`strippedfile'", write text replace
            file read _csvin _csvline
            while r(eof) == 0 {
                if substr(`"`_csvline'"', 1, 1) != "#" {
                    file write _csvout `"`_csvline'"' _n
                }
                file read _csvin _csvline
            }
            file close _csvin
            file close _csvout
        }

        // Import chain 1
        qui import delimited using "stanrun_stripped_1.csv", clear delimiters(",") varnames(1)
        qui gen int chain = 1
        qui save "stanrun_chain_combined.dta", replace

        // Append remaining chains
        forvalues c = 2/`chains' {
            qui import delimited using "stanrun_stripped_`c'.csv", clear delimiters(",") varnames(1)
            qui gen int chain = `c'
            qui append using "stanrun_chain_combined.dta"
            qui save "stanrun_chain_combined.dta", replace
        }

        // Clean up temp files
        forvalues c = 1/`chains' {
            capture erase "stanrun_stripped_`c'.csv"
        }
        capture erase "stanrun_chain_combined.dta"

        // Fallback renaming for older Stata versions (19.5 strips dots automatically)
        capture rename Sigma_1_1 sigma11
        capture rename Sigma_2_2 sigma22
        capture rename Sigma_1_2 sigma12
        capture rename Sigma_2_1 sigma21
        capture rename mul_2 mul2
        capture rename lamda_1 lamda1
        capture rename lamda_2 lamda2

        // Save combined draws
        qui save "`chainfile'", replace
        local ndraws = _N
        di as text "Loaded `ndraws' draws from `chains' chains"
        if "`verbose'" != "" {
            di as text "Combined draws saved to: `chainfile'"
        }
    }

    // =====================================================================
    // DIAGNOSE: Basic diagnostics
    // =====================================================================
    if "`diagnose'" == "diagnose" & "`load'" == "load" {
        capture confirm variable divergent__
        if !_rc {
            qui count if divergent__ == 1
            local ndiv = r(N)
            if `ndiv' > 0 {
                di as error "Warning: `ndiv' divergent transitions detected"
                di as error "Consider increasing adapt_delta or reparameterizing the model"
            }
            else {
                di as text "No divergent transitions detected"
            }
        }

        capture confirm variable treedepth__
        if !_rc {
            qui summarize treedepth__, meanonly
            if r(max) >= 10 {
                di as text "Warning: Maximum tree depth reached in some iterations"
            }
        }
    }

    // Clean up
    if "`keepfiles'" == "" {
        capture erase "`wdir'\\stanrun_sampling.log"
    }

end
