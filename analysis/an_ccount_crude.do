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


/* COVID in cohort */

gen covid_incohort = covid_tpp_probable
replace covid_incohort = . if covid_tpp_probable < enter_date
replace covid_incohort = . if covid_tpp_probable > censor_date

gen covid_incohort_wk = week(covid_incohort)

table covid_incohort_wk , contents(count covid_incohort) row col

bysort utla: egen n_covid = count(covid_incohort)
summ n_covid, d





log close