/*================================================================================

	Do-file:		an_cox_models.do

	Project:		Non-specific-immunity

	Programmed by:	Daniel Grint

	Data used:		cr_analysis_dataset.dta

	Data created:	

	Other output:	an_cox_models.log
					

================================================================================

	Purpose:	This do file:
					Runs Cox models of increasing complexity for the association
					between exposure to an RTI and outcome of COVID diagnosis,
					hospital admission, and death.
  
================================================================================*/

set linesize 100

* Open a log file
cap log close
log using ./logs/an_cox_models, replace t


clear
*use "C:\Users\EIDEDGRI\Documents\GitHub\non-specific-immunity-research\analysis\cr_analysis_dataset"
use ./analysis/cr_analysis_dataset.dta


/* COVID DIAGNOSIS OUTCOME DATE DEFINED IN cr_analysis_dataset.do
== CONSIDER MOVING OUTCOME DEFINITION TO THIS DO FILE?
== cox_covid_date is date of covid diagnosis
*/


/* EXPOSURE DEFINITION */

* Using first RTI
gen first_rti = min_rti

* Administrative censor
replace first_rti = date("01dec2099", "DMY") if first_rti == .

format %td first_rti


/* COVID DIAGNOSIS AS OUTCOME MODELS */

stset stime_covid_diag, failure(covid_diag) entry(enter_date) exit(censor_date) origin(enter_date) id(patient_id) scale(1) 

strate , per(100)


* Split time on exposure status
stsplit t_rti, after(first_rti) at(0,28,56,84)

recode t_rti (-1 = 1 "pre-RTI") (0 = 2 "Month 1") (28 = 3 "Month 2") (56 = 4 "Month 3") (84 = 5 "Month 4+"), gen(exp_time)

strate exp_time, per(100)



/* UNADJUSTED COX MODEL */

stcox ib1.exp_time, base

sts graph , haz by(exp_time) width(5 5 5 5 5)	///
			xlabel(1 "01SEP" 31 "01OCT" 62 "01NOV" 91 "01DEC")	///
			legend(label(1 "pre-RTI") label(2 "Month 1") label(3 "Month 2") label(4 "Month 3") label(5 "Month 4+"))	///
			name(unadj_cox)
			
graph export ./output/unadj_cox_haz.svg, name(unadj_cox) as(svg) replace

* With regional stratification

stcox ib1.exp_time, base strata(utla_group)

sts graph , haz by(exp_time) width(5 5 5 5 5)	///
			xlabel(1 "01SEP" 31 "01OCT" 62 "01NOV" 91 "01DEC")	///
			legend(label(1 "pre-RTI") label(2 "Month 1") label(3 "Month 2") label(4 "Month 3") label(5 "Month 4+"))	///
			name(unadj_utla_cox)
			
graph export ./output/unadj_utla_cox_haz.svg, name(unadj_utla_cox) as(svg) replace

sts graph , haz by(utla_group) 	///
			xlabel(1 "01SEP" 31 "01OCT" 62 "01NOV" 91 "01DEC")	///
			legend(off)	///
			name(utla_haz)
			
graph export ./output/utla_haz.svg, name(utla_haz) as(svg) replace



log close
