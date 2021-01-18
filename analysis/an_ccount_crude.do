/*================================================================================

	Do-file:		an_case_counts_crude_analysis.do

	Project:		Non-specific-immunity

	Programmed by:	Daniel Grint

	Data used:		cr_create_analysis_dataset.dta

	Data created:	

	Other output:	an_ccount_crude.log
					

================================================================================

	Purpose:	This do file:
					Summarises covid diagnoses by UTLA region over time
					Runs a crude unadjusted analysis based on LRTI codes											
  
================================================================================*/

set linesize 100

* Open a log file
cap log close
log using ./logs/an_ccount_crude, replace t


clear
*use "C:\Users\EIDEDGRI\Documents\GitHub\non-specific-immunity-research\analysis\cr_create_analysis_dataset"
use ./analysis/cr_create_analysis_dataset.dta


gen test_censor = date("01/01/2021", "DMY")


/* COVID in cohort */
* Overall
egen incohort_date_covid = rowmin(covid_tpp_probable first_pos_test_sgss)
replace incohort_date_covid = . if incohort_date_covid < enter_date
replace incohort_date_covid = . if incohort_date_covid > censor_date

* TPP probable
gen incohort_date_tpp = covid_tpp_probable
replace incohort_date_tpp = . if incohort_date_tpp < enter_date
replace incohort_date_tpp = . if incohort_date_tpp > censor_date

* TPP clinical
gen incohort_date_tppclin = covid_tpp_clin
replace incohort_date_tppclin = . if incohort_date_tppclin < enter_date
replace incohort_date_tppclin = . if incohort_date_tppclin > censor_date

* TPP test
gen incohort_date_tpptest = covid_tpp_test
replace incohort_date_tpptest = . if incohort_date_tpptest < enter_date
replace incohort_date_tpptest = . if incohort_date_tpptest > censor_date

* TPP seq
gen incohort_date_tppseq = covid_tpp_seq
replace incohort_date_tppseq = . if incohort_date_tppseq < enter_date
replace incohort_date_tppseq = . if incohort_date_tppseq > censor_date

* SGSS
gen incohort_date_sgss = first_pos_test_sgss
replace incohort_date_sgss = . if incohort_date_sgss < enter_date
replace incohort_date_sgss = . if incohort_date_sgss > censor_date

format %td incohort_date_*


* Save daily counts to matrix
foreach var in tpp tppclin tpptest tppseq sgss {
	tab incohort_date_`var', matcell(`var'_n) matrow(`var'_dt)
		
	* Create variables from matrix
	svmat `var'_n
	svmat `var'_dt

} 

format %td *_dt1

label var tpp_n1		"TPP"
label var tppclin_n1	"TPP Clinical"
label var tpptest_n1	"TPP Test"
label var tppseq_n1		"TPP Seq"
label var sgss_n1		"SGSS"

* Graph COVID diagnoses by TPP and SGSS
line tpp_n1 tpp_dt1 || line sgss_n1 sgss_dt1, name(tpp_sgss) ytitle("Daily COVID diagnoses")
graph export ./output/tpp_sgss_counts.svg, name(tpp_sgss) as(svg) replace

* Graph COVID diagnoses in TPP
line tppclin_n1 tppclin_dt1 || line tpptest_n1 tpptest_dt1 || line tppseq_n1 tppseq_dt1, name(tpp_type) ytitle("Daily COVID diagnoses")
graph export ./output/tpp_type_counts.svg, name(tpp_type) as(svg) replace
			
/*
gen covid_incohort_wk = week(covid_incohort)

table covid_incohort_wk , contents(count covid_incohort) row col

bysort utla: egen n_covid = count(covid_incohort)
summ n_covid, d
*/



* Get case counts and denominator by region

tab utla
disp "Number of unique UTLAs = " `r(r)'

table utla_name, contents(count incohort_date_tpp count patient_id)



* Fit fractional polynomials to case counts by region

fp <tpp_dt1>: regress tpp_n1 <tpp_dt1>

regress tpp_n1 tpp_dt1_1 tpp_dt1_1
predict p_tpp

line tpp_n1 tpp_dt1 || line p_tpp tpp_dt1, name(tpp_fp) ytitle("Daily COVID diagnoses")
graph export ./output/tpp_fp.svg, name(tpp_fp) as(svg) replace


log close