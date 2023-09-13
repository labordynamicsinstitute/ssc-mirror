program define stpm3_predictions_eg
  version 16.1
  args eg
  // Load Data
  if "`eg'" == "0" {
    if _N!=0 {
      di as error "Need to start with an empty data set."
      exit 198
    }
    di "Load data for stpm3 prediction example."
    use https://www.pclambert.net/data/rott2b
    stset os, failure(osi = 1) scale(12) exit(time 120)
  }
  // Example 1
  if "`eg'" == "1a" {
    di "Fit a simple model with one covariate."
    stpm3 i.hormon, scale(lncumhazard) df(5) eform
    predict S0 S1, surv ci at1(hormon 0) at2(hormon 1) timevar(0 10)
    frame stpm3_pred {
      line S0 S1 tt
      list in 1/10
    }
  }
  if "`eg'" == "1b" {
    di "Specifying a frame."
    predict S0 S1, surv ci at1(hormon 0) at2(hormon 1) timevar(0 10) frame(p, replace)
    frame p: describe
  }  
  if "`eg'" == "1c" {
    di "Using timevar() with a varname."
    range tt 0 10 100
    predict S0 S1, surv ci at1(hormon 0) at2(hormon 1) timevar(tt) frame(p, replace)
    frame p: list in 1/10 
  }    
  if "`eg'" == "1d" {
    di "Using timevar() with the step() suboption."
    predict S0 S1, surv ci at1(hormon 0) at2(hormon 1) timevar(0 10, step(0.1)) frame(p, replace)
    frame p: list if inlist(tt,1,5,10), noobs 
  }      
  if "`eg'" == "1e" {
    di "Using timevar() with the n() and gen() suboptions."
    predict S0 S1, surv ci at1(hormon 0) at2(hormon 1) timevar(0 10, n(101) gen(time)) frame(p, replace)
    frame p: list in 1/10 
  }  
  if "`eg'" == "1f" {
    di "Using the merge option."
    predict S0 S1, surv ci at1(hormon 0) at2(hormon 1) timevar(0 10, step(0.1) gen(t)) merge
    list t S0* S1* in 1/10 
  }        
  // Example 2
  if "`eg'" == "2a" {
    di "Fit a model including hormon, size and age."
    stpm3 i.hormon##@ns(age,df(3)) i.size, scale(lncumhazard) df(5) eform
    predict S0 S1, surv ci at1(hormon 0 age 60 size 3) at2(hormon 1 age 60 size 3) timevar(0 10, step(0.1) gen(t)) frame(p, replace)
    frame stpm3_pred {
      line S0 S1 t
      list in 1/10
    }
  }  
  
  if "`eg'" == "2b" {
    di "Fit a model including hormon, size and age (non proportional hazards)."
    stpm3 i.hormon##@ns(age,df(3)) i.size, scale(lncumhazard) df(5) tvc(@ns(age,df(3))) dftvc(3)
    predict S0 S1, surv ci at1(hormon 0 age 60 size 3) at2(hormon 1 age 60 size 3) timevar(0 10, step(0.1) gen(t)) frame(p, replace)
    frame stpm3_pred {
      line S0 S1 t
      list in 1/10
    }
  }    
end
