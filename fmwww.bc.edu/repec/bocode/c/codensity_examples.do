local default = cond(c(version) >= 18, "stcolor", "s1color")
set scheme `default'

sysuse auto, clear
label var price "Price (USD)"

codensity gen price, over(foreign) min(0) max(18000)
codensity super, xtitle("`: var label price'") name(DE1, replace)

codensity super, recast(area) opt1(lcolor(orange) color(orange%40)) opt2(lcolor(blue) color(blue%40)) title("Price (USD)") name(DE2, replace)

su _density1, meanonly
local max = r(max)
su _density2, meanonly
local max = max(`max', r(max))
gen where1 = -`max'/15
gen where0 = -`max'/30
local rugcode addplot(scatter where0 price if !foreign, ms(|) mc(orange) || scatter where1 price if foreign, ms(|) mc(blue))
codensity super, recast(area) opt1(lcolor(orange) color(orange%40)) opt2(lcolor(blue) color(blue%40)) title("Price (USD)") ytitle(Density) `rugcode' name(DE3, replace)

codensity clear
codensity gen price, kernel(biweight) bw(400 600 800 1000) labelwith(bwidth)
codensity super, title(Price (USD)) opt1(lp(dash)) opt3(lp(dash)) xla(4000(4000)16000) name(DE4, replace)

codensity bystyle, byopts(title(Price (USD)) note("biweight kernels, different bandwidth")) name(DE5, replace)

codensity clear
codensity gen price, trans(identity root cube_root log) labelwith(trans)
codensity bystyle, byopts(title(Price (USD)) note("transform, estimate and back-transform")) name(DE6, replace)

codensity clear
codensity gen price weight mpg length
codensity juxta, combineopts(name(DE7, replace))

codensity bystyle, name(DE8, replace)

codensity clear
codensity generate mpg, over(foreign) kernel(biweight) bwidth(4) min(8) max(45)
gen where = foreign + 0.97
egen mean = mean(mpg), by(foreign)
codensity stack, recast(area) xtitle(Miles per gallon) xla(10(5)45) note("means are centres of gravity" "biweight kernel: bandwidth 4")  addplot(scatter where mean if foreign, ms(T) mc(stc2) msize(*2) || ///
scatter where mean if !foreign, ms(T) mc(stc1) msize(*2)) name(DE9, replace)

codensity stack, vertical recast(rarea) ytitle(Miles per gallon) yla(10(5)45) name(DE10, replace)

use palmer_penguins, clear
* myaxis is from Stata Journal (Cox 2021)
myaxis SPECIES=species, sort(mean bill_depth)
codensity generate bill_depth, over(SPECIES) min(12) max(22)
codensity super, name(DE11, replace) xtitle("`: var label bill_depth'") legend(row(1) pos(12))
 
