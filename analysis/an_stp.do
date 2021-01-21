/********************************************************************************

	Do-file:		an_stp.do

	Project:		Non-specific-immunity

	Programmed by:	Daniel Grint

	Data used:		Data in memory (from input.csv)

	Data created:	
	
	Other output:	None

********************************************************************************

	Purpose:		This do-file summarises STPs to identify which need to be
					grouped
  
********************************************************************************/

set linesize 100

* Open a log file
cap log close
log using ./logs/an_stp, replace t

*import delimited "C:\Users\EIDEDGRI\Documents\GitHub\non-specific-immunity-research\lookups\MSOA_lookup.csv", varnames(1) clear
*order msoa, first
*save "C:\Users\EIDEDGRI\Documents\GitHub\non-specific-immunity-research\lookups\MSOA_lookup", replace
*import delimited "C:\Users\EIDEDGRI\Documents\GitHub\non-specific-immunity-research\output\input.csv", clear

clear
import delimited ./output/input.csv


* Get case counts and denominator by STP region

gen covid_tpp_probable_dt = date(covid_tpp_probable, "YMD")


* TPP probable
gen incohort_date_tpp = covid_tpp_probable_dt
replace incohort_date_tpp = . if incohort_date_tpp < date("01/09/2020", "DMY")
replace incohort_date_tpp = . if incohort_date_tpp > date("01/12/2020", "DMY")


tab stp
disp "Number of unique STPs = " `r(r)'

table stp, contents(count incohort_date_tpp count patient_id)


log close
