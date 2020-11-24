/*==============================================================================
DO FILE NAME:			00_Test_runs_and_feasibility
PROJECT:				Non-specific immunity
DATE: 					9th November 2020 
AUTHOR:					Daniel Grint 										
DESCRIPTION OF FILE:	Test runs and feasibility
DATASETS USED:			data in memory (from analysis/input.csv)
DATASETS CREATED: 		
OTHER OUTPUT: 			logfile
						testing frequency files .xlsx
							
==============================================================================*/


* Open a log file
cap log close
*log using $logdir/00_Test_runs_and_feasibility, replace t
log using "C:\Users\EIDEDGRI\Documents\GitHub\non-specific-immunity-research\logs\test_log", replace t

set linesize 150

cd C:\Users\EIDEDGRI\Documents\GitHub\non-specific-immunity-research

* Import dataset into STATA
import delimited "output/input.csv", clear

* Keep test variables
keep patient_id age covid_* died_*
drop covid_admission_primary*

/* === Age groups === */ 

* Create categorised age 
recode age 	0/9.9999 =   1 ///
			10/17.9999 = 2 ///
			18/29.9999 = 3 /// 
			30/39.9999 = 4 /// 
			40/49.9999 = 5 ///
			50/59.9999 = 6 ///
			60/69.9999 = 7 ///
			70/79.9999 = 8 ///
			80/max = 9, gen(agegroup) 

label define agegroup 	1 "<10" ///
						2 "10-<18" ///
						3 "18-<30" ///
						4 "30-<40" ///
						5 "40-<50" ///
						6 "50-<60" ///
						7 "60-<70" ///
						8 "70-<80" ///
						9 "80+"
						
label values agegroup agegroup

tab agegroup

drop if !inrange(agegroup,1,9)


/* === Dates === */

ds , has(type string)

* Recode to dates from the strings 
foreach var of varlist `r(varlist)' {
						
	confirm string variable `var'
	rename `var' `var'_dstr
	gen `var' = date(`var'_dstr, "YMD")
	format `var' %td
	
	*Week of year
	gen `var'_eflag=1 if !inlist(year(`var'),2020,.)
	gen `var'_week=week(`var') if year(`var')==2020
	
	* XXX Year_flag indicates error in dates XXX
	tab `var'_eflag, m

}

drop *_eflag


/* === Covid testing summaries === */

* #### How many negative tests? ####
	gen has_neg=0
	replace has_neg=1 if covid_negtest_first !=.

	tab agegroup has_neg, row
	summ covid_negtest_count if has_neg==1, d	// number of negative tests
	bysort agegroup: summ covid_negtest_count if has_neg==1, d

* #### Negative test followed by a positive ####
	gen neg_pos=0 if has_neg==1
	gen pos_neg=neg_pos

	replace neg_pos=1 if has_neg==1 & covid_tpp_probable != . & covid_tpp_probable > covid_negtest_last
	replace pos_neg=1 if has_neg==1 & covid_negtest_last > covid_tpp_probable
	
	tab neg_pos
	tab pos_neg

* Time from negative to positive (days)
	gen time_neg_pos=covid_tpp_probable-covid_negtest_last if neg_pos==1
	summ time_neg_pos if neg_pos==1, d
	
* Negative to positive by agegroup
	tab agegroup neg_pos, row	// negative test with following covid diagnosis
	bysort agegroup: summ time_neg_pos if neg_pos==1, d	// time from negative to diagnosis

	tab agegroup pos_neg, row	// covid diagnoses with negative test after -
								// indicates taking last negative insufficient
								
* Distribution of neg_pos pair timings
	histogram covid_negtest_last_week if neg_pos==1, freq kden name(negtest)
	histogram covid_tpp_probable_week if neg_pos==1, freq kden name(covid_tpp)

	
/* === Covid positives by negative test and agegroup over time === */
	bysort has_neg: table covid_tpp_probable_week agegroup if covid_tpp_probable_week > 15, contents(count covid_tpp_probable) row col


/* === Outcomes following negative test === */

* ICU admission
	gen neg_icu=0 if has_neg==1
	replace neg_icu=1 if has_neg==1 & covid_icu_date !=.

	tab agegroup neg_icu, row

	gen time_neg_icu=covid_icu_date-covid_negtest_last if neg_icu==1

	bysort agegroup: summ time_neg_icu if neg_icu==1, d	// time from negative to icu
	
	table covid_icu_date_week agegroup if has_neg==1 & covid_icu_date_week > 15, contents(count covid_icu_date) row col
	
	
* Death
	gen neg_died=0 if has_neg==1
	replace neg_died=1 if has_neg==1 & died_date_ons !=.
	
	gen neg_cdied=0 if has_neg==1
	replace neg_cdied=1 if neg_died==1 & died_ons_covid_flag_any==1

	tab neg_died
	tab neg_cdied
	tab agegroup neg_died, row
	tab agegroup neg_cdied, row

	gen time_neg_died=died_date_ons-covid_negtest_last if neg_died==1
	
	summ time_neg_died if neg_died==1, d
	bysort agegroup: summ time_neg_died if neg_died==1, d	// time from negative to death

	
/* === Outcomes general pop === */

* ICU admission
	gen gen_icu=0 if has_neg==0
	replace gen_icu=1 if covid_icu_date !=. & has_neg==0
	
	tab gen_icu
	tab agegroup gen_icu, row
	
	table covid_icu_date_week agegroup if has_neg==0 & covid_icu_date_week > 15, contents(count covid_icu_date) row col

* Death
	gen gen_died=0 if has_neg==0
	replace gen_died=1 if died_date_ons !=. & has_neg==0
	
	gen gen_cdied=0 if has_neg==0
	replace gen_cdied=1 if gen_died==1 & died_ons_covid_flag_any==1
	
	tab gen_died
	tab gen_cdied
	tab agegroup gen_died, row
	tab agegroup gen_cdied, row


log close



