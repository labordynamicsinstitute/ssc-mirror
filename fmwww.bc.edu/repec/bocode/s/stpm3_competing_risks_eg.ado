program define stpm3_competing_risks_eg
  version 16.1
  args eg
  // Load Data
  if "`eg'" == "0" {
    if _N!=0 {
      di as error "Need to start with an empty data set."
      exit 198
    }
    di "Load data for stpm3 competing risks example."
    use https://www.pclambert.net/data/rott2b
  }
  // Cancer Model 
  if "`eg'" == "1" {
    di as input "**Cancer model.**"
    diline: stset os, failure(cause = 1) scale(12) exit(time 120)
    diline: stpm3 @ns(age,df(3)) i.hormon, scale(lncumhazard) df(5) 
    diline: estimates store cancer
    diline: predict S0_age60 S1_age60, surv ci at1(age 60 hormon 0) at2(age 60 hormon 1) timevar(0 10) frame(cancer, replace)
    diline: frame cancer: line S0_age60 S1_age60 tt
  }
  if "`eg'" == "2" {
    di as input "**Other cause model.**"
    diline: stset os, failure(cause = 2) scale(12) exit(time 120)
    diline: stpm3 @ns(age,df(3)) i.hormon, scale(lncumhazard) df(5) 
    diline: estimates store other
    diline: predict S0_age60 S1_age60, surv ci at1(age 60 hormon 0) at2(age 60 hormon 1) timevar(0 10) frame(other, replace)
    diline: frame other: line S0_age60 S1_age60 tt
  }  
  if "`eg'" == "3" {
    di "**predicting CIFs**"
    predict CIF0_age60 CIF1_age60, cif crmodels(cancer other) ci timevar(0 10) at1(age 60 hormon 0) at2(age 60 hormon 1) frame(cif, replace)
    frame cif: line CIF0_age60_cancer CIF0_age60_other tt
  }    
  if "`eg'" == "4" {
    di "**predicting allcause probability of death**"
    predict F0_age60 F1_age60, failure ci crmodels(cancer other) at1(age 60 hormon 0) at2(age 60 hormon 1) frame(cif, merge)
    frame cif: twoway (area CIF0_age60_cancer tt) (rarea CIF0_age60_cancer F0_age60 tt), legend(order(1 "cancer" 2 "other")) 
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
    di "Fit a simple model including hormon, age and nodes."
    stpm3 i.hormon##@ns(age,df(3)) i.size, scale(lncumhazard) df(5) eform
    predict S0 S1, surv ci at1(hormon 0 age 60 size 3) at2(hormon 1 age 60 size 3) timevar(0 10, step(0.1) gen(t)) frame(p, replace)
    frame stpm3_pred {
      line S0 S1 t
      list in 1/10
    }
  }  
end

program define diline
  _on_colon_parse `0'
  di as input `". `s(after)'" 
  `s(after)'
  di ""
end