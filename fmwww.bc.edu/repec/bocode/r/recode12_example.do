version 19.5
clear
set more off
set varabbrev off

* 1. Eligible numeric variables only.
use recode12_example_data.dta, clear
recode12 employed owns_home, yesvalue(2)
list id employed employed_01 owns_home owns_home_01 in 1/8, separator(0)

* 2. Eligible string variables only.  The first distinct nonmissing category
* encountered is source category 1; the second is source category 2.
use recode12_example_data.dta, clear
recode12 exam_result_text preferred_fruit, yesvalue(2)
list id exam_result_text exam_result_text_01 preferred_fruit ///
    preferred_fruit_01 in 1/8, separator(0)

* 3. Eligible numeric and string variables together.
use recode12_example_data.dta, clear
recode12 owns_car completed_training preferred_fruit, yesvalue(2)
list id owns_car owns_car_01 completed_training completed_training_01 ///
    preferred_fruit preferred_fruit_01 in 1/8, separator(0)

* 4. With no varlist, all eligible numeric and string variables are processed;
* variables with one, three, or no nonmissing string categories are skipped.
use recode12_example_data.dta, clear
recode12, yesvalue(2)
return list
