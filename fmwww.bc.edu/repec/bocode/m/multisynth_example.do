* multisynth - example script
* Requires: multisynth_example_data.dta in the working directory

* Basic usage
use multisynth_example_data, clear
multisynth y, unit(id) time(year) treated(treated) post(post)


* With controls and event-time graph
use multisynth_example_data, clear
multisynth y, unit(id) time(year) treated(treated) post(post) controls(x1 x2) graph


* Save augmented panel and donor weights
use multisynth_example_data, clear
multisynth y, unit(id) time(year) treated(treated) post(post) controls(x1 x2) ctrlweight(0.2) saving(multisynth_stack.dta) replace wsaving(multisynth_weights.dta) wreplace graph

* Inspect returned scalars
return list

* Example second stage: DiD on augmented panel
* treated x post coefficient is the ATT
use multisynth_stack.dta, clear
keep if clone == 1 | (treated == 1 & clone == 0)
regress y treated##i.post i.source_unit
