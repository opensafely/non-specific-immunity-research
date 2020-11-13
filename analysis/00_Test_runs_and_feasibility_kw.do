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

/* === Housekeeping === */
/*handled in model.do
global outdir  	  "output"
global logdir     "log"
global tempdir    "tempdata"
*/


* Open a log file
cap log close
log using $logdir/00_Test_runs_and_feasibility, replace t
*log using "C:\Users\EIDEDGRI\Documents\GitHub\non-specific-immunity-research\logs\test_log", replace t

* Import dataset into STATA
import delimited "output/input.csv", clear

*cd C:\Users\EIDEDGRI\Documents\GitHub\non-specific-immunity-research
*import delimited output/input.csv, clear

* Keep test variables
keep patient_id age sgss_covid_test_ever* covid_anytest* covid_negtest covid_tpp_probable

set linesize 200

list in 1/40, clean header(10) ab(30) noobs

* How many covid_anytests?
summ covid_anytest_count, d


/* === Age groups === */ 

* Create categorised age 
recode age 0/9.9999 = 1 ///
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


/* === Dates === */

ds, has(type string)

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
<<<<<<< HEAD:analysis/00_Test_runs_and_feasibility_kw.do
=======
		
>>>>>>> 6d89d32dd9d4f002b628c8d212128fc4fc9e621e:analysis/00_Test_runs_and_feasibility.do
}


/* === Frequency of covid tests === */

* ##### COVID TPP positive tests #####
table covid_tpp_probable_week agegroup, contents(count covid_tpp_probable) row col

preserve

	gen count=1 if covid_tpp_probable !=.
	collapse (count) count, by(agegroup covid_tpp_probable_week)
	*export excel using "C:\Users\EIDEDGRI\Filr\My Files\OpenSafely\Non-specific immunity\Outputs\tpp_count.xlsx", first(var) replace
	export excel using $outdir\tpp_count.xlsx, first(var) replace
restore

* ##### COVID antigen negative tests #####
table covid_negtest_week agegroup, contents(count covid_negtest) row col

preserve

	gen count=1 if covid_negtest !=.
	collapse (count) count, by(agegroup covid_negtest_week)
	*export excel using "C:\Users\EIDEDGRI\Filr\My Files\OpenSafely\Non-specific immunity\Outputs\negtest_count.xlsx", first(var) replace
	export excel using $outdir\negtest_count.xlsx, first(var) replace
restore

* ##### COVID first anytest #####
table covid_anytest_first_week agegroup, contents(count covid_anytest_first) row col

preserve

	gen count=1 if covid_anytest_first !=.
	collapse (count) count, by(agegroup covid_anytest_first_week)
	*export excel using "C:\Users\EIDEDGRI\Filr\My Files\OpenSafely\Non-specific immunity\Outputs\anytest_first_count.xlsx", first(var) replace
	export excel using $outdir\anytest_first_count.xlsx, first(var) replace
restore

* ##### COVID last anytest #####
table covid_anytest_last_week agegroup, contents(count covid_anytest_last) row col

preserve

	gen count=1 if covid_anytest_last !=.
	collapse (count) count, by(agegroup covid_anytest_last_week)
	*export excel using "C:\Users\EIDEDGRI\Filr\My Files\OpenSafely\Non-specific immunity\Outputs\anytest_last_count.xlsx", first(var) replace
	export excel using $outdir\anytest_last_count.xlsx, first(var) replace
restore


log close



