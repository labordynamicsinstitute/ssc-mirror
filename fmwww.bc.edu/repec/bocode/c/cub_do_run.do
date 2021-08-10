********************************************************************************
*! "CUB_TO_RUN.DO", v.25, Cerulli, 03dic2020
********************************************************************************
*
********************************************************************************
* Application to the dataset "universtata.dta"
********************************************************************************

* Load the dataset
use universtata , clear

* Run "scattercub" for cub00 to graph the feeling/uncertainty graph
. scattercub informat willingn officeho compete global, save_graph(mygraph1)

* Run cub00
. cub officeho

* Run cub00 with the predicted probabilities and the graph
. cub officeho, prob(_PROB) graph save_graph(mygraph2) outname("OFFICEHO")

* De-mean the log of "age"  
. gen lage=ln(age)
. egen mlage=mean(lage)
. gen slnage=lage-mlage

* Run CUB with covariates
. cub officeho , pi(slnage gender) xi(slnage freqserv)

* Produce linear predictions
. predict pred_xi, equation(xi_gamma) xb
. predict pred_pi, equation(pi_beta) xb

* Form the four groups
. gen group=.
. replace group=1 if gender==1 & freqserv==1
. replace group=2 if gender==0 & freqserv==1
. replace group=3 if gender==1 & freqserv==0
. replace group=4 if gender==0 & freqserv==0

* Generate the "feeling" and the "uncertainty" variables
. gen feeling=invlogit(1-pred_xi)
. gen uncertainty=invlogit(1-pred_pi)

* Plot the graph
. sort(uncertainty)
. tw ///
(line feeling uncertainty if group==1 & age<=22 , lw(medthick)) ///
(line feeling uncertainty if group==2 & age<=22 , lw(medthick)) ///
(line feeling uncertainty if group==3 & age>22 , lw(medthick)) ///
(line feeling uncertainty if group==4 & age>22 , lw(medthick)) , ///
legend(label(1 "Younger user man") label(2 "Younger user Woman") ///
label(3 "Older not-user man") label(4 "Older not-user Woman")) ///
scheme(s2mono) xtitle("Uncertainty") ytitle("Feeling") saving(mygraph3, replace)

* Run CUB with covariates and shelter
. cub officeho , pi(slnage gender) xi(slnage freqserv) shelter(5)

* Run CUB with hidden categories
. cub officeho , m(9)

********************************************************************************
* Run cub00 separately for "freqserv==1" and "freqserv==0" and plot jointly the probability graph
* CUB for "freqserv==1"
qui cub officeho if freqserv==1 ,  prob(predicted_probs) save_graph(gr_m) graph  // male
mat P_m=e(M)
* CUB for "freqserv==0"
qui cub officeho if freqserv==0 ,  prob(predicted_probs) save_graph(gr_f) graph  // female
mat P_f=e(M)
* Generate the adjoint matrix P
mat P=P_m,P_f
mat list P
* Generate the 4 probabilities' variables (actual and fitted by gender)
preserve
svmat2 P ,  rnames(categories)       
destring categories , replace
drop if categories==.
keep categories P*
* Run the graph
sort categories
tw (connected P1 categories) (connected P2 categories) (connected P3 categories) (connected P4 categories) ,  ///
legend(order(1 "freqserv_1 fitted" 2 "freqserv_1 actual" 3 "freqserv_0 fitted" 4 "freqserv_0 actual"))
restore
********************************************************************************
* END
********************************************************************************
