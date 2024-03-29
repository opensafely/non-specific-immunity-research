/*==============================================================================
DO FILE NAME:			00_Test_runs_and_feasibility
PROJECT:				Non-specific immunity
DATE: 					9th November 2020 
AUTHOR:					Daniel Grint 										
DESCRIPTION OF FILE:	Test runs and feasibility
DATASETS USED:			data in memory (from analysis/input.csv)
DATASETS CREATED: 		
OTHER OUTPUT: 			logfile
						
							
==============================================================================*/


* Open a log file
cap log close

*log using "C:\Users\EIDEDGRI\Documents\GitHub\non-specific-immunity-research\logs\test_log", replace t
log using ./logs/00_Test_runs_and_feasibility, replace t

set linesize 150



*cd C:\Users\EIDEDGRI\Documents\GitHub\non-specific-immunity-research

* Import dataset into STATA

*import delimited "C:\Users\EIDEDGRI\Documents\GitHub\non-specific-immunity-research\output\input.csv", clear
import delimited ./output/input.csv, clear

/*
merge m:1 msoa using ./lookups/MSOA_lookup
drop if _merge==2
drop _merge

* Keep test variables
keep patient_id age covid_* died_* *lrti* utla
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

*/

/* === Dates === */

* Recode outcomes to dates from the strings

ds died_date_ons-covid_discharge_date, has(type string)

* Add _week variable for each outcome 
foreach var of varlist `r(varlist)' {
						
	confirm string variable `var'
	rename `var' `var'_dstr
	gen `var' = date(`var'_dstr, "YMD")
	format `var' %td
	
	*Week of year
	*gen `var'_eflag=1 if !inlist(year(`var'),2020,.)
	gen `var'_week=week(`var') if inlist(year(`var'),2020,2021)
	
	* XXX Year_flag indicates error in dates XXX
	*tab `var'_eflag, m

}

*drop *_eflag

* Recode lrti exposures to dates from the strings
/*

ds *lrti*, has(type string)

foreach var of varlist `r(varlist)' {
						
	confirm string variable `var'
	rename `var' `var'_dstr
	gen `var' = date(`var'_dstr, "YMD")
	format `var' %td
	
	drop `var'_dstr
}



/* === Exposures === */

* LRTIs
	gen had_lrti=0
	replace had_lrti=1 if inrange(lrti_in_period,1,100)
	
	tab had_lrti
	
	summ lrti_in_period if lrti_in_period > 0, d
	
* LRTIs plus COPD exacerbations
	gen had_c_lrti=0
	replace had_c_lrti=1 if inrange(c_lrti_in_period,1,100)
	
	tab had_c_lrti
	
	summ c_lrti_in_period if c_lrti_in_period > 0, d

	
/* === Outcomes === */

* COVID positive
	table covid_tpp_probable_week agegroup if covid_tpp_probable_week > 35, contents(count covid_tpp_probable) row col
	
	count if covid_tpp_probable != .
	
	gen covid_incohort = covid_tpp_probable
	replace covid_incohort = . if covid_tpp_probable < date("01sep2020", "DMY")
	replace covid_incohort = . if covid_tpp_probable > date("01dec2020", "DMY")
	
	count if covid_incohort != .
	
	bysort utla: egen n_covid = count(covid_incohort)
	
	summ n_covid, d
	


* Hospital admission
	gen hosp=0
	replace hosp=1 if covid_admission_date !=.

	*tab hosp
	*tab had_lrti hosp
	*tab had_c_lrti hosp

	table covid_admission_date_week agegroup if covid_admission_date_week > 35, contents(count covid_admission_date) row col

	*bysort had_c_lrti: table covid_admission_date_week agegroup if covid_admission_date_week > 15, contents(count covid_admission_date) row col


* ICU admission
	gen icu=0
	replace icu=1 if covid_icu_date !=.

	*tab icu
	*tab had_lrti icu
	*tab had_c_lrti icu

	table covid_icu_date_week agegroup if covid_icu_date_week > 35, contents(count covid_icu_date) row col

*/
	
* Hospital spell duration
	gen spell_days=covid_discharge_date-covid_admission_date
	
	* Last hospital discharge
	egen max_discharge = max(covid_discharge_date)
	disp "Last hospital discharge for COVID admission " %td max_discharge
	
	* Missing discharge dates
	count if covid_admission_date != . & spell_days==.
	
	summ spell_days, d
	summ spell_days if month(covid_admission_date)==4, d
	summ spell_days if month(covid_admission_date)==5, d
	summ spell_days if month(covid_admission_date)==6, d
	summ spell_days if month(covid_admission_date)==7, d
	summ spell_days if month(covid_admission_date)==8, d
	summ spell_days if month(covid_admission_date)==9, d
	summ spell_days if month(covid_admission_date)==10, d
	summ spell_days if month(covid_admission_date)==11, d
	summ spell_days if month(covid_admission_date)==12, d

	gen month=month(covid_admission_date)

	gen spells_60=spell_days
	replace spells_60=. if spell_days > 60
	
	graph box spells_60 if month > 2, over(month) ylabel(0 (15) 60) name(spells) ///
			title("Median COVID hospital spell duration by month of 2020" "APCS SUS cut: 5th Jan 21" "Last hospital discharge: 30th November")	///
			ytitle("Spell duration (Days)")
	graph export ./output/00_spells.svg, name(spells) as(svg)	
	
		


* Death
	gen died=0
	replace died=1 if died_date_ons !=.
	
	tab died_date_ons_week
	
	*gen cdied=0
	*replace cdied=1 if died_ons_covid_flag_any==1


/*
	
/* === Exposures over time === */

drop c_lrti_in_period

reshape long c_lrti_, i(patient_id) j(episode) string

gen c_lrti_week = week(c_lrti_)

hist c_lrti_week, frequency name(c_lrti_gph)
graph export ./output/00_c_lrti_week.svg, name(c_lrti_gph) as(svg)

table c_lrti_week agegroup if c_lrti_week > 15, contents(count c_lrti_) row col
	
*/
	
*/

log close


/*
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
	graph export ./output/00_negtests_by_week.svg, name(negtest) as(svg)
	
	histogram covid_tpp_probable_week if neg_pos==1, freq kden name(covid_tpp)
	graph export ./output/00_tpp_pos_by_week.svg, name(covid_tpp) as(svg)
	
/* === Covid positives by negative test and agegroup over time === */
	bysort has_neg: table covid_tpp_probable_week agegroup if covid_tpp_probable_week > 15, contents(count covid_tpp_probable) row col
*/
