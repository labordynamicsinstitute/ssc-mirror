#delim ;
prog def cprd_common_dosages;
version 13.0;
*
 Create dataset common_dosages with 1 obs per common dosage.
 Add-on packages required:
 keyby
*;

syntax using [ , CLEAR ];

*
 Input data
*;
import delimited `using', varnames(1) `clear';
desc, fu;
cap lab var textid "Identifier allowing freetext dosage on therapy events to be retrieved";
cap lab var text "Anonymised textual dose associated with the therapy textid";
cap lab var daily_dose "Numerical equivalent of the given textual dose given in a per day format";
cap lab var dose_number "Amount in each dose";
cap lab var dose_unit "Unit of each dose";
cap lab var dose_frequency "How often a dose is taken in a day";
cap lab var dose_interval "Number in days that the dose is over, e.g. 1 every 2 weeks = 14, 4 a day = 0.25";
cap lab var choice_of_dose "Indicates if there is a choice the user can make as to how much they can take";
cap lab var dose_max_average "If dose was averaged, value = 2, if maximum was taken, value = 1, otherwise 0";
cap lab var change_dose "If an option between 2 parts of the dose was available, indicates the part used";
cap lab var dose_duration "If specified, the number of days the prescription is for";
keyby textid;
desc, fu;
char list;

end;
