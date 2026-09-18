version 14.2
clear all
set more off

webuse hypoxia, clear

* Add descriptive labels solely to demonstrate automatic label propagation.
label define pelnode_lbl 0 "Node negative" 1 "Node positive"
label values pelnode pelnode_lbl

stset dftime, failure(failtype==1)
stcrreg ifp tumsize i.pelnode, compete(failtype==2) nolog

fgcifplot pelnode, ///
    values(0 1) ///
    risktimes(0 2 4 6 8) ///
    risktable(all) ///
    name(fgcifplot_demo)
