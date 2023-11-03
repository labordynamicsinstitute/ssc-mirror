// Checking error messages for the STATA program artcat
// Created by Ella Marley-Zagar, 11 June 2020
// Last updated: 11 Feb 2021
// Renamed errormsgs.do 1jun2022

clear all
set more off

which artcat

/*

************
* TO TEST:
************
							
pc missing
pc()
pc <1
pc >1

pe & or & rr missing
pe()
pe<1
pe>1
or()
or<1
or(0)
or(or1 or2)
rr()
rr<1
rr(0)
rr(200)
rr(rr1 rr2)

pe AND or
pe AND rr
or AND rr

power() and n() missing     
power()
power <1
power(0) 
power(1)
power >1
power(power1 power2)
n()      
n <1
n(0)
n(1000000) 
n(n1 n2)
power AND n()


alpha()                   
alpha(0)
alpha <0
alpha >1
alpha(alpha1 alpha2)

specify whitehead option without or() 
specify whitehead AND ologit
specify whitehead AND ologit(new)
specify whitehead and pe()
specify whitehead and rr()
specify ologit(NN NA)
specify ologit(NN AA)
specify ologit(NA AA)
specify ologit(NN NA AA)
specify all options at once

margin()                       
margin(margin1 margin2)
negative margin
margin(0)

incorrect spec of favourable and unfavourable


*/




* pc missing
artcat, pe(0.1) power(0.90)
* error message as required: option pc() required

* No value for pc()
artcat, pc() pe(0.1) power(0.90) 
* error message as required: option pc() required

* pc < 1
artcat, pc(-0.1) pe(0.2) power(0.90) 
* error message as required:  artcat: probabilities found in pc are non-positive

* pc > 1
artcat, pc(1.1) pe(0.2) power(0.90) 
* error message as required:  artcat: probabilities in pc sum to more than 1                

* pe, or and rr missing
artcat, pc(0.1) power(0.90) 
* error message as required: artcat: Please specify one of pe, or, rr

* No value for pe()
artcat, pc(0.1) pe() power(0.90) 
* error message as required: artcat: Please specify one of pe, or, rr

* pe <1
artcat, pc(0.1) pe(-0.2) power(0.90) 
* error message as required: artcat: probabilities found in pe are non-positive

* pe >1
artcat, pc(0.1) pe(1.2) power(0.90) 
* error message as required:  artcat: probabilities in pe sum to more than 1                  

* or()
artcat, pc(0.1) or() power(0.90) 
* error message as required: artcat: Please specify one of pe, or, rr

* or < 1
artcat, pc(0.1) or(-1) power(0.90) 
* error message: artcat: or must be >0

* or(0)
artcat, pc(0.1) or(0) power(0.90) 
* error message: artcat: or must be >0

* or(or1 or2)
artcat, pc(0.1) or(0.8 0.9) power(0.90) 
* error message as required: artcat: or() must be an expression                                                  

* rr()
artcat, pc(0.1) rr() power(0.90) 
* error message as required: artcat: Please specify one of pe, or, rr

* rr < 1
artcat, pc(0.1) rr(-1) power(0.90) 
* error message: artcat: rr must be >0

* rr(0)
artcat, pc(0.1) rr(0) power(0.90) 
* error message: artcat: rr must be >0

* One value of rr() which is out of range                                        
artcat, pc(0.1) rr(200) power(0.90)
* error message as required: artcat: rr option implies pe sums to more than 1

* rr(rr1 rr2)
artcat, pc(0.1) rr(0.8 0.9) power(0.90)
* error message as required: artcat: rr() must be an expression

* Trying to specify pe() AND or()
artcat, pc(0.2 0.5 0.2 0.1) pe(0.378 0.472 0.106 0.044) or(0.887) power(.9) whitehead
* error message as required: artcat: Please don't specify more than one of pe, or, rr

* Trying to specify pe() AND rr()
artcat, pc(0.05) pe(0.2) rr(0.92) power(.9) 
* error message as required: artcat: Please don't specify more than one of pe, or, rr

* Trying to specify or() AND rr()
artcat, pc(0.05) or(0.8) rr(0.92) power(.9) 
* error message as required: artcat: Please don't specify more than one of pe, or, rr

* power() AND n() missing
artcat, pc(0.1) pe(0.2)  
* defaults to power = 0.8 as required

* power()
artcat, pc(0.1) pe(0.2) power()
* defaults to power = 0.8 as required

* power < 1
artcat, pc(0.1) pe(0.2) power(-1)
* error message as required: artcat: power must be between 0 and 1

* power(0)
artcat, pc(0.1) pe(0.2) power(0)
* error message as required: artcat: power must be between 0 and 1

* power(1)
artcat, pc(0.1) pe(0.2) power(1)
* error message as required: artcat: power must be between 0 and 1                                  

* power > 1
artcat, pc(0.1) pe(0.2) power(1.1)
* error message as required: artcat: power must be between 0 and 1

* power(power1 power2)
artcat, pc(0.1) pe(0.2) power(0.8 0.9)
* error message as required: power() invalid -- single number required

* n()
artcat, pc(0.1) pe(0.2) n()
* deafults to power = 0.8 as required

* n < 1
artcat, pc(0.1) pe(0.2) n(-1)
* error message as required: artcat: n must be greater than 0

* n(0)
artcat, pc(0.1) pe(0.2) n(0)
* error message as required: artcat: n must be greater than 0

* n(1000000)
artcat, pc(0.1) pe(0.2) n(1000000)
* gives power of 1 as expected

* n(n1 n2)
artcat, pc(0.1) pe(0.2) n(100 200)
* error message as required: n() invalid -- single number required

* power() AND n()
artcat, pc(0.1) pe(0.2) power(0.8) n(200)
* error message as required: artcat: Please don't specify both power and n

* alpha()
artcat, pc(0.1) pe(0.2) alpha() power(0.8) 
* error message: option alpha() incorrectly specified
                   
* alpha(0)
artcat, pc(0.1) pe(0.2) alpha(0) power(0.8) 
* gives error message as required: artcat: alpha must be between 0 and 1

* alpha <0
artcat, pc(0.1) pe(0.2) alpha(-0.05) power(0.8)
* gives error message as required: artcat: alpha must be between 0 and 1                                   

* alpha >1
artcat, pc(0.1) pe(0.2) alpha(1.5) power(0.8)
* gives error message as required: artcat: alpha must be between 0 and 1                                         

* alpha(alpha1 alpha2)
artcat, pc(0.1) pe(0.2) alpha(0.05 0.1) power(0.8)
* error message: option alpha() incorrectly specified

* Trying to specify whitehead option without or() 
artcat, pc(0.2 0.5 0.2 0.1) power(.9) whitehead
* error message: artcat: Whitehead method requires or                        

* specify whitehead AND ologit
artcat, pc(0.2) or(0.8) power(.9) whitehead ologit
* error message as required: artcat: Please don't specify both whitehead and ologit

* specify whitehead AND ologit(new)
artcat, pc(0.2) or(0.8) power(.9) whitehead ologit(NN)
* error message as required: artcat: Please don't specify both whitehead and ologit

* specify whitehead AND ologit(new)
artcat, pc(0.2) or(0.8) power(.9) whitehead ologit(AA)
* error message as required: artcat: Please don't specify both whitehead and ologit

* specify whitehead and pe()
artcat, pc(0.2 0.5 0.2 0.1) pe(0.378 0.472 0.106 0.044) power(.9) whitehead
* error message as required: artcat: Whitehead method requires or

* specify whitehead and rr()
artcat, pc(0.2 0.5 0.2 0.1) rr(0.8) power(.9) whitehead
* error message as required: artcat: Whitehead method requires or

* specify ologit(NN NA)
artcat, pc(0.2 0.5) pe(0.4 0.6) power(.9) ologit(NN NA)
* error message: artcat: ologit(NN NA) not allowed

* specify ologit(NN AA)
artcat, pc(0.2 0.5) pe(0.4 0.6) power(.9) ologit(NN AA)
* error message: artcat: ologit(NN AA) not allowed

* specify ologit(NA AA)
artcat, pc(0.2 0.5) pe(0.4 0.6) power(.9) ologit(NA AA)
* error message: artcat: ologit(NA AA) not allowed

* specify ologit(NN NA AA)
artcat, pc(0.2 0.5) pe(0.4 0.6) power(.9) ologit(NN NA AA)
* error message: artcat: ologit(NN NA AA) not allowed

* specify all options at once
artcat, pc(0.2 0.5) pe(0.4 0.6) or(0.5) rr(0.5) power(.9) ologit ologit(NN) ologit(NA) ologit(AA) whitehead
* error message: option ologit() not allowed                                                           ***** perhaps could be more helpful ******************
artcat, pc(0.2 0.5) pe(0.4 0.6) or(0.5) rr(0.5) power(.9) ologit(NN) ologit(NA) ologit(AA) whitehead
* error message: option ologit() incorrectly specified

* margin()
artcat, pc(0.01) or(1) margin() power(.8) ologit
* error message: option margin() incorrectly specified

* margin(margin1 margin2)
artcat, pc(0.01) or(1) margin(1.33 1.5) power(.8) ologit
* error message: option margin() incorrectly specified

* Check get error message with negative margin
artcat, pc(0.01) or(1) margin(-1) power(.8) ologit
* Error message as required (artcat: margin must be expressed as an odds ratio greater than 0)                                                     

* Check get error message with margin(0)
artcat, pc(0.01) margin(0) power(.8)
* Error message as required (artcat: margin must be expressed as an odds ratio greater than 0) 

* check get error message is specify unfavourable incorrectly
artcat, pc(.1) pe(.2) alpha(0.1) power(.8) probtable ologit(NN) unfav
* Error message as required: artcat: or (2.249997) > margin (1) is incompatible with unfavourable option

* check get error message is specify favourable incorrectly
artcat, pc(.4 .2) margin(0.1) or(0.05) power(.8) probtable ologit favourable
* Error message a required: artcat: or (.05) < margin (.1) is incompatible with favourable option

* check incorrect specification with favourable and cumulative
artcat, pc(.6 .4 .2) rr(.5) margin(1.1) power(.9) probtable cum noround favourable
* Error message: artcat: cumulative probabilities found in pc are non-increasing

* check incorrect specification with unfavourable and cumulative
artcat, pc(.6 .4 .2) rr(.5) margin(1.1) power(.9) probtable cum noround unfavourable
* Error message: artcat: cumulative probabilities found in pc are non-increasing

*** end of errormsgs.do ***