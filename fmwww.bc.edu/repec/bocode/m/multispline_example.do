* ================================================
* MultiSpline Stata Package — Examples
* Author: Subir Hait, Michigan State University
* Version: 1.0.4  01mar2026
* ================================================

* ------------------------------------------------
* Example 1: Education — SES and Math Achievement
* ------------------------------------------------
clear
set seed 42
set obs 1000
gen schid     = ceil(_n/50)
gen ses       = rnormal(0,1)
gen math      = 50 + 0.9*ses - 0.25*ses^2 + rnormal(0,3)

multispline math ses, cluster(schid) nknots(4) plot

* ------------------------------------------------
* Example 2: Autoknot selection
* ------------------------------------------------
multispline math ses, cluster(schid) autoknots plot

* ------------------------------------------------
* Example 3: Grid predictions
* ------------------------------------------------
multispline math ses, cluster(schid) nknots(4) ///
            at(-3 -2 -1 0 1 2 3) plot

* ------------------------------------------------
* Example 4: Health Science — Dosage and Response
* ------------------------------------------------
clear
set seed 123
set obs 800
gen hospital  = ceil(_n/40)
gen dosage    = runiform(0,100)
gen response  = 20 + 0.5*dosage - ///
                0.005*dosage^2 + rnormal(0,5)

multispline response dosage, cluster(hospital) nknots(4) plot

* ------------------------------------------------
* Example 5: Real Stata data
* ------------------------------------------------
sysuse nlsw88, clear
multispline wage age, cluster(industry) nknots(4) plot
