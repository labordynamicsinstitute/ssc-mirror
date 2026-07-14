version 19.5
clear
set more off
set varabbrev off

use recode12_example_data.dta, clear

* Source 1 is Female; it becomes the 1-coded indicator category.
recode12 female, yesvalue(1)

* Source 2 is the 1-coded category for all 20 demonstration variables.
recode12 owns_home owns_car uses_public_transit has_home_internet ///
    uses_smartphone college_graduate works_full_time self_employed ///
    has_retirement_plan exercises_weekly current_smoker drinks_weekly ///
    volunteers_monthly registered_voter voted_last_election has_children ///
    lives_with_partner lives_in_urban_area has_savings_account ///
    uses_online_banking, yesvalue(2)

list id female female_01 owns_home owns_home_01 has_children ///
    has_children_01 uses_online_banking uses_online_banking_01 ///
    in 1/10, separator(0)

return list
