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



/* EXPOSURE DEFINITION */

* Using first RTI
gen first_rti = min_rti
gen first_nrti = min_nrti
format %td first_rti first_nrti

twoway (hist first_rti, freq color(red%30)) (hist first_nrti, freq color(green%30)), legend(off)

graph export ./output/exposure_hist.svg, as(svg) replace


* Administrative censor
replace first_rti = date("01dec2099", "DMY") if first_rti == .
replace first_nrti = date("01dec2099", "DMY") if first_nrti == .

format %td first_rti first_nrti


/* COVID DIAGNOSIS AS OUTCOME MODELS */

stset cox_covid_date, failure(covid_diag) entry(enter_date) exit(censor_date) origin(enter_date) id(patient_id) scale(1) 

strate , per(100)


/* Split time on exposure status */

* 3 months after exposure (4 weeks each)
* RTI
stsplit t_rti, after(first_rti) at(0,28,56,84)

recode t_rti (-1 = 1 "pre-RTI") (0 = 2 "Month 1") (28 = 3 "Month 2") (56 = 4 "Month 3") (84 = 5 "Month 4+"), gen(exp_time)
strate exp_time, per(100)

* nRTI
stsplit t_nrti, after(first_nrti) at(0,28,56,84)

recode t_nrti (-1 = 1 "pre-nRTI") (0 = 2 "Month 1") (28 = 3 "Month 2") (56 = 4 "Month 3") (84 = 5 "Month 4+"), gen(nexp_time)
strate nexp_time, per(100)


* 12 weeks after exposure
* RTI
stsplit w_rti, after(first_rti) at(0,7,14,21,28,35,42,49,56,63,70,77,84)

recode w_rti (-1 = 1 "pre-RTI") (0 = 2 "Week 1") (7 = 3 "Week 2") (14 = 4 "Week 3") (21 = 5 "Week 4") (28 = 6 "Week 5") ///
			(35 = 7 "Week 6") (42 = 8 "Week 7") (49 = 9 "Week 8") (56 = 10 "Week 9") (63 = 11 "Week 10") (70 = 12 "Week 11") ///
			(77 = 13 "Week 12") (84 = 14 "Week 13+"), gen(exp_week)

* nRTI
stsplit w_nrti, after(first_nrti) at(0,7,14,21,28,35,42,49,56,63,70,77,84)

recode w_nrti (-1 = 1 "pre-nRTI") (0 = 2 "Week 1") (7 = 3 "Week 2") (14 = 4 "Week 3") (21 = 5 "Week 4") (28 = 6 "Week 5") ///
			(35 = 7 "Week 6") (42 = 8 "Week 7") (49 = 9 "Week 8") (56 = 10 "Week 9") (63 = 11 "Week 10") (70 = 12 "Week 11") ///
			(77 = 13 "Week 12") (84 = 14 "Week 13+"), gen(nexp_week)


/* UNADJUSTED COX MODEL */

/*
stcox ib1.exp_time, base

sts graph , haz by(exp_time) width(5 5 5 5 5)	///
			xlabel(1 "01SEP" 31 "01OCT" 62 "01NOV" 91 "01DEC")	///
			legend(label(1 "pre-RTI") label(2 "Month 1") label(3 "Month 2") label(4 "Month 3") label(5 "Month 4+"))	///
			name(unadj_cox)
			
graph export ./output/unadj_cox_haz.svg, name(unadj_cox) as(svg) replace
*/

* With regional stratification

* Months
* RTI
stcox ib1.exp_time age1 age2 age3 male, base strata(utla_group)

sts graph , haz by(exp_time) width(5 5 5 5 5)	///
			xlabel(1 "01SEP" 31 "01OCT" 62 "01NOV" 91 "01DEC")	///
			legend(label(1 "pre-RTI") label(2 "Month 1") label(3 "Month 2") label(4 "Month 3") label(5 "Month 4+"))	///
			name(unadj_cox_month)
			
graph export ./output/unadj_cox_month.svg, name(unadj_cox_month) as(svg) replace

/*
sts graph , haz by(utla_group) 	///
			xlabel(1 "01SEP" 31 "01OCT" 62 "01NOV" 91 "01DEC")	///
			legend(off)	///
			name(utla_haz)
			
graph export ./output/utla_haz.svg, name(utla_haz) as(svg) replace
*/

* nRTI
stcox ib1.nexp_time age1 age2 age3 male, base strata(utla_group)



* Weeks
* RTI
stcox ib1.exp_week age1 age2 age3 male, base strata(utla_group)

sts graph , haz by(exp_week) width(5 5 5 5 5 5 5 5 5 5 5 5 5 5)	///
			xlabel(1 "01SEP" 31 "01OCT" 62 "01NOV" 91 "01DEC")	///
			legend(label(1 "pre-RTI") label(2 "Week 1") label(3 "Week 2") label(4 "Week 3") label(5 "Week 4") ///
					label(6 "Week 5") label(7 "Week 6") label(8 "Week 7") label(9 "Week 8") label(10 "Week 9") ///
					label(11 "Week 10") label(12 "Week 11") label(13 "Week 12") label(14 "Week 13+") rows(3)) ///
			name(unadj_cox_week)
			
graph export ./output/unadj_cox_week.svg, name(unadj_cox_week) as(svg) replace

sts graph , haz by(exp_week) width(5 5 5 5 5 5 5 5 5 5 5 5 5 5)	///
			xlabel(1 "01SEP" 31 "01OCT" 62 "01NOV" 91 "01DEC")	///
			legend(off) ///
			name(unadj_cox_week1)
			
graph export ./output/unadj_cox_week_nl.svg, name(unadj_cox_week1) as(svg) replace


* nRTI
stcox ib1.nexp_week age1 age2 age3 male, base strata(utla_group)





/* With adjustment for region

encode utla_group, gen(utla_num)

* Months
stcox ib1.exp_time i.utla_num, base

sts graph , haz by(exp_time) width(5 5 5 5 5)	///
			xlabel(1 "01SEP" 31 "01OCT" 62 "01NOV" 91 "01DEC")	///
			legend(label(1 "pre-RTI") label(2 "Month 1") label(3 "Month 2") label(4 "Month 3") label(5 "Month 4+"))	///
			name(adj_utla_cox)
			
graph export ./output/utla_cox_month.svg, name(adj_utla_cox) as(svg) replace
*/


/* ========================================== */
/* == Using SGSS to define covid diagnosis == */
/* ========================================== */

stset, clear

/* COVID DIAGNOSIS AS OUTCOME MODELS */

stset cox_sgss_date, failure(sgss_diag) entry(enter_date) exit(censor_date) origin(enter_date) id(patient_id) scale(1) 

strate , per(100)


/* UNADJUSTED COX MODEL */

/*
stcox ib1.exp_time, base

sts graph , haz by(exp_time) width(5 5 5 5 5)	///
			xlabel(1 "01SEP" 31 "01OCT" 62 "01NOV" 91 "01DEC")	///
			legend(label(1 "pre-RTI") label(2 "Month 1") label(3 "Month 2") label(4 "Month 3") label(5 "Month 4+"))	///
			name(unadj_cox)
			
graph export ./output/unadj_cox_haz.svg, name(unadj_cox) as(svg) replace
*/

* With regional stratification

* Months
stcox ib1.exp_time age1 age2 age3 male, base strata(utla_group)

sts graph , haz by(exp_time) width(5 5 5 5 5)	///
			xlabel(1 "01SEP" 31 "01OCT" 62 "01NOV" 91 "01DEC")	///
			legend(label(1 "pre-RTI") label(2 "Month 1") label(3 "Month 2") label(4 "Month 3") label(5 "Month 4+"))	///
			name(unadj_sgss)
			
graph export ./output/unadj_sgss_month.svg, name(unadj_sgss) as(svg) replace


* Weeks
stcox ib1.exp_week age1 age2 age3 male, base strata(utla_group)

sts graph , haz by(exp_week) width(5 5 5 5 5 5 5 5 5 5 5 5 5 5)	///
			xlabel(1 "01SEP" 31 "01OCT" 62 "01NOV" 91 "01DEC")	///
			legend(label(1 "pre-RTI") label(2 "Week 1") label(3 "Week 2") label(4 "Week 3") label(5 "Week 4") ///
					label(6 "Week 5") label(7 "Week 6") label(8 "Week 7") label(9 "Week 8") label(10 "Week 9") ///
					label(11 "Week 10") label(12 "Week 11") label(13 "Week 12") label(14 "Week 13+") rows(3)) ///
			name(unadj_sgss_week)
			
graph export ./output/unadj_sgss_week.svg, name(unadj_sgss_week) as(svg) replace

sts graph , haz by(exp_week) width(5 5 5 5 5 5 5 5 5 5 5 5 5 5)	///
			xlabel(1 "01SEP" 31 "01OCT" 62 "01NOV" 91 "01DEC")	///
			legend(off) ///
			name(unadj_sgss_week1)
			
graph export ./output/unadj_sgss_week_nl.svg, name(unadj_sgss_week1) as(svg) replace






log close
