*! version 1.2 2024-05-01

program define mlad
  version 16.1 
  syntax anything [fw pw iw aw] [if][in] ,       ///
                  llfile(string)                 ///
                  [                              ///
                   ADTYPE(string)                ///
                   ALLBetas                      ///   
                   ID(varname)                   ///
                   INIT(string)                  ///
                   noJIT                         ///
                   LLSETup(string)               ///
                   MATrices(string)              ///
                   MATNames(string)              ///
                   MINLIKE                       ///
                   MLMETHod(string)              ///
                   OTHERvars(varlist)            ///
                   OTHERVARnames(string)         /// 
                   PYGradient                    ///   
                   PYHessian                     ///
                   PYMINIMIZEOPTS(string)        /// Not implemented yet
                   PYOPTimize                    ///
                   PYSETup(string)               ///
                   ROBUSTOK                      ///
                   SCORETYPE(string)             ///
                   SCALars(string)               ///
                   SCALARNames(string)           ///
                   STATICScalars(string)         /// 
                   SEARCH(string)                ///
                   VERBOSE                       ///
                  *]

  _get_diopts diopts options, `options'   
  mlopts mlopts, `options'
  local constraints `s(constraints)'
  marksample touse

// drop program so different modules can be loaded
  capture pr drop mlad_ll
  
  if "`mlmethod'" == "" local mlmethod d2
  if inlist("`mlmethod'","d0","d1","d2","d1debug","d2debug") == 0 {
    di as error "Only the d0, d1, d2, d1debug, d2debug methods are allowed."
    exit 198
  }
  
  if "`adtype'" == "" {
    local adtype revrev
  }
  if !inlist("`adtype'","fwdrev","revfwd","revrev","fwdfwd") {
    di as error "adtype must be either fwdrev, revfwd, revrev, fwdfwd"
    exit 198
  }
  

  if "`robustok'" != "" {
    if "`scoretype'" == "" local scoretype equation
  }

// check python and modules
  quietly python query
  if "`r(execpath)'" == "" {
    di as error "No link to python executable."
    exit 198
  }
  foreach m in jax scipy importlib numpy {
    capture python which `m'
    if _rc {
      di as error "Python module `m' need to be installed."
      exit 198
    }
  }

// varnames
    if "`othervarnames'" != "" {
      if wordcount("`othervarnames'") != wordcount("`othervars'") {
        di as error "Number of othervarnames must equal number of othervars"
        exit 198      
      }
    }
    else {
      local othervarnames `othervars'
    }
  
// new ID variables
  if "`id'" != "" {
    tempvar tmpid
    qui egen `tmpid' = group(`id') if `touse'
    qui replace `tmpid' = `tmpid' - 1 if `touse'
    qui levelsof `tmpid' if `touse'
    local Nid `r(r)'
  }
  
// matrices
  if "`matrices'" != "" {
    foreach mat in `matrices' {
      confirm matrix `mat'
    }
    if "`matnames'" != ""{
      if wordcount("`matnames'") != wordcount("`matrices'") {
        di as error "Number of matrix names must equal number of matrices"
        exit 198
      }
    }
    else {
      local matnames `matrices'
    }
  }

// scalars
  if "`scalars'" != "" {
    foreach sc in `scalars' {
      confirm scalar `sc'
    }
    if "`scalarnames'" != "" {
      if wordcount("`scalarnames'") != wordcount("`scalars'") {
        di as error "Number of scalar names must equal number of scalars"
        exit 198
      }
    } 
    else {
      local scalarnames `scalars'
    }
 }   
 
 // static scalars
  if "`staticscalars'" != "" {
    foreach sc in `staticscalars' {
      confirm scalar `sc'
    }
  }   
 
  global MLAD_hasid         = "`id'" != ""
  global MLAD_hasmatrices   = "`matrices'" != "" 
  global MLAD_hasscalars    = "`scalars'" != "" 
  global MLAD_hasjit        = "`jit'" == ""
  global MLAD_haspygradient = "`pygradient'" != ""
  global MLAD_haspyhessian  = "`pyhessian'" != ""
  global MLAD_allbetas      = "`allbetas'" != ""  
  global MLAD_minlike       = "`minlike'" != ""  
  global MLAD_pyoptimize    = "`pyoptimize'" != ""  
  global MLAD_verbose       = "`verbose'" != ""

  global MLAD_touse          `touse'
  global MLAD_othervars      `othervars'
  global MLAD_othervarnames  `othervarnames'
  global MLAD_idvar          `tmpid'
  global MLAD_idorig         `id'
  global MLAD_Nid            `Nid'
  global MLAD_matrices       `matrices'
  global MLAD_matnames       `matnames' 
  global MLAD_scalars        `scalars'
  global MLAD_scalarnames    `scalarnames'
  global MLAD_staticscalars  `staticscalars'
  global MLAD_hessian_adtype `adtype'
  global MLAD_llfile         `llfile'
  global MLAD_pysetupfile    `pysetup' 
  global MLAD_llsetup        `llsetup' 
  global MLAD_scoretype      `scoretype'
  global MLAD_firstcall      1

  if "`search'" != "" local search search(`search')
  if "`init'" != "" local init init(`init')
  
  ml model `mlmethod' mlad_ll `anything' [`weight'`exp'] if `touse', ///
                                                     `options'       ///
                                                     `search'        ///
                                                     `maximize'      ///
                                                     `init'          ///
                                                     maximize        ///
                                                     nopreserve    
                                                      
  if "`robustok'" != "" {
    forvalues i = 1/`e(k_eq)' {
      tempname eq`i'
    }
    mlad_ll robust e(b)
  }
                                                      
// Tidy up
// remove data loaded in python
  mlad_ll tidy

// drop globals  
  foreach n in touse othervars othervarnames hasid idvar      ///
                     hasscalars scalars scalarnames           ///
                     hasmatrices matrices matnames            ///
                     firstcall                                ///
                     hasanyfv gname Hname                     ///
                     llfile hasjit                            ///
                     staticscalars  hessian_adtype            ///
                     hasfv1 hasfv2 hasfv3 hasfv4              ///
                     haspyhessian haspygradient               ///
                     setupfile allbetas                       ///
                     pyoptimize minlike verbose               ///
                     llsetup stpm3_hazard_setup               ///
                     scoretype Nid idorig                     ///
  {
    macro drop MLAD_`n'
  }

end

  




