/********************************************************************************

	Do-file:		cr_create_analysis_dataset.do

	Project:		Non-specific-immunity

	Programmed by:	Daniel Grint
					Adapted from covid/non-covid death (Fizz & Krishnan)

	Data used:		Data in memory (from input.csv)

	Data created:	cr_analysis_dataset.dta  (main analysis dataset)

	Other output:	None

********************************************************************************

	Purpose:		This do-file creates the variables required for the 
					main analysis and saves into Stata datasets.
  
********************************************************************************/
set linesize 100

* Open a log file
cap log close
log using ./logs/cr_analysis_dataset, replace t

clear
import delimited ./output/input.csv

merge m:1 msoa using ./lookups/MSOA_lookup
drop if _merge==2
drop _merge


di "STARTING COUNT FROM IMPORT:"
cou

rename hiv hiv_code

****************************
*  Create required cohort  *
****************************

* DROP IF COVID DIAGNOSIS BEFORE/ON STUDY START
noi di "COVID ON/BEFORE STUDY START DATE:" 
drop if date(covid_tpp_probable, "YMD")<=d(1/9/2020)
drop if date(first_pos_test_sgss, "YMD")<=d(1/9/2020)

* DROP IF HOSPITAL ADMISSION BEFORE/ON STUDY START
* XXX IF NO POSITIVE TEST PRIOR TO STUDY START THEN NO VALID HOSPITAL ADMISSION EITHER XXX
*noi di "HOSPTIAL ADMISSION ON/BEFORE STUDY START DATE:" 
*drop if date(covid_admission_date, "YMD")<=d(1/9/2020)

* DROP IF DIED ON/BEFORE STUDY START DATE
noi di "DIED ON/BEFORE STUDY START DATE:" 
drop if date(died_date_ons, "YMD")<=d(1/9/2020)


* Age: Exclude those with implausible ages
assert age<.
noi di "DROPPING AGE>105:" 
drop if age>105

* Sex: Exclude categories other than M and F
assert inlist(sex, "M", "F", "I", "U")
noi di "DROPPING GENDER NOT M/F:" 
drop if inlist(sex, "I", "U")


******************************
*  Convert strings to dates  *
******************************

* Outcomes
foreach var of varlist 	dereg_date						///
						died_date_ons 					///
						covid_vacc_date					///
						covid_tpp_probable				///
						covid_tpp_clin					///
						covid_tpp_test					///
						covid_tpp_seq					///
						first_pos_test_sgss				///
						covid_admission_date			///
						covid_discharge_date {
						
	confirm string variable `var'
	rename `var' `var'_dstr
	gen `var' = date(`var'_dstr, "YMD")
	order `var', after(`var'_dstr)
	drop `var'_dstr
	format `var' %td
	
}

* Recode RTI exposures to dates from the strings

ds *rti*, has(type string)

foreach var of varlist `r(varlist)' {
						
	confirm string variable `var'
	rename `var' `var'_dstr
	gen `var' = date(`var'_dstr, "YMD")
	order `var', after(`var'_dstr)
	drop `var'_dstr
	format `var' %td
}

*************************
*# Exposure definition #*
*************************

summ lrti_in_period, d
summ lrti_in_period if lrti_in_period > 0, d

summ rti_in_period, d
summ rti_in_period if rti_in_period > 0, d

drop lrti_in_period rti_in_period

ds *rti*, has(type float)				// Weekly LRTI flags

egen n_rti = rownonmiss(`r(varlist)')
summ n_rti, d
summ n_rti if n_rti > 0, d
drop n_rti

* Negative tests at time of RTI

ds *neg_*, has(type byte)
egen n_neg_rti = rowtotal(`r(varlist)')
summ n_neg_rti, d
summ n_neg_rti if n_neg_rti > 0, d
drop n_neg_rti

foreach week in 0900 0907 0914 0921 0928 1005 1012 1019 1026 1102 1109 1116 1123 1130 {
	
	gen nrti_`week' = .
	replace nrti_`week' = rti_`week' if neg_`week' == 1
	
}

ds nrti*, has(type float)

egen min_nrti = rowmin(`r(varlist)')	// Use first nRTI for now
format %td min_nrti


ds rti*, has(type float)

egen min_rti = rowmin(`r(varlist)')	// Use first RTI for now
format %td min_rti




* Covariates
foreach var of varlist 	bp_sys_date 					///
						bp_dias_date 					///
						hba1c_percentage_date			///
						hba1c_mmol_per_mol_date			///
						hypertension					///
						bmi_date_measured				///
						chronic_respiratory_disease 	///
						chronic_cardiac_disease 		///
						diabetes 						///
						lung_cancer 					///
						haem_cancer						///
						other_cancer 					///
						chronic_liver_disease 			///
						stroke							///
						dementia		 				///
						other_neuro 					///
						organ_transplant 				///	
						dysplenia						///
						sickle_cell 					///
						aplastic_anaemia 				///
						hiv_date						///
						permanent_immunodeficiency 		///
						temporary_immunodeficiency		///
						ra_sle_psoriasis  dialysis 	{
	confirm string variable `var'
	replace `var' = `var' + "-15"
	rename `var' `var'_dstr
	replace `var'_dstr = " " if `var'_dstr == "-15"
	gen `var'_date = date(`var'_dstr, "YMD") 
	order `var'_date, after(`var'_dstr)
	drop `var'_dstr
	format `var'_date %td
}

rename bmi_date_measured_date      bmi_date_measured
rename bp_dias_date_measured_date  bp_dias_date
rename bp_sys_date_measured_date   bp_sys_date
rename hba1c_percentage_date_date  hba1c_percentage_date
rename hba1c_mmol_per_mol_date_date  hba1c_mmol_per_mol_date
rename hiv_date_date hiv_date




*******************************
*  Recode implausible values  *
*******************************


* BMI 

* Only keep if within certain time period? using bmi_date_measured ?
* NB: Some BMI dates in future or after cohort entry

* Set implausible BMIs to missing:
replace bmi = . if !inrange(bmi, 15, 50)




**********************
*  Recode variables  *
**********************

* Sex
assert inlist(sex, "M", "F")
gen male = (sex=="M")
drop sex


* Smoking
label define smoke 1 "Never" 2 "Former" 3 "Current" 

gen     smoke = 1  if smoking_status=="N"
replace smoke = 2  if smoking_status=="E"
replace smoke = 3  if smoking_status=="S"
replace smoke = . if smoking_status=="M"
label values smoke smoke
drop smoking_status


* Ethnicity (5 category)
replace ethnicity = . if ethnicity==.
label define ethnicity 	1 "White"  					///
						2 "Mixed" 					///
						3 "Asian or Asian British"	///
						4 "Black"  					///
						5 "Other"					
						
label values ethnicity ethnicity


* Ethnicity (16 category)
replace ethnicity_16 = . if ethnicity==.
label define ethnicity_16 									///
						1 "British or Mixed British" 		///
						2 "Irish" 							///
						3 "Other White" 					///
						4 "White + Black Caribbean" 		///
						5 "White + Black African"			///
						6 "White + Asian" 					///
 						7 "Other mixed" 					///
						8 "Indian or British Indian" 		///
						9 "Pakistani or British Pakistani" 	///
						10 "Bangladeshi or British Bangladeshi" ///
						11 "Other Asian" 					///
						12 "Caribbean" 						///
						13 "African" 						///
						14 "Other Black" 					///
						15 "Chinese" 						///
						16 "Other" 							
						
label values ethnicity_16 ethnicity_16


* Ethnicity (16 category grouped further)
* Generate a version of the full breakdown with mixed in one group
gen ethnicity_16_combinemixed = ethnicity_16
recode ethnicity_16_combinemixed 4/7 = 4
label define ethnicity_16_combinemixed 	///
						1 "British or Mixed British" ///
						2 "Irish" ///
						3 "Other White" ///
						4 "All mixed" ///
						8 "Indian or British Indian" ///
						9 "Pakistani or British Pakistani" ///
						10 "Bangladeshi or British Bangladeshi" ///
						11 "Other Asian" ///
						12 "Caribbean" ///
						13 "African" ///
						14 "Other Black" ///
						15 "Chinese" ///
						16 "Other" 
						
label values ethnicity_16_combinemixed ethnicity_16_combinemixed
						

* STP 
rename stp stp_old
bysort stp_old: gen stp = 1 if _n==1
replace stp = sum(stp)
drop stp_old

egen n_stp = tag(stp)
count if n_stp

bysort stp: gen count = _N
summ count, d


/* MSOA/UTLA */

egen n_msoa = tag(msoa)
count if n_msoa

bysort msoa: gen count1 = _N
summ count1, d

egen n_utla = tag(utla)
count if n_utla

bysort utla: gen count2 = _N
summ count2, d


* Regroup UTLAs with small case numbers

gen utla_group = utla_name

replace utla_group = "Redbridge, Barking and Dagenham" if utla_name == "Barking and Dagenham"
replace utla_group = "Redbridge, Barking and Dagenham" if utla_name == "Redbridge"

replace utla_group = "Bucks/Ox/West. Berks/Swindon" if utla_name == "Buckinghamshire"
replace utla_group = "Bucks/Ox/West. Berks/Swindon" if utla_name == "Oxfordshire"
replace utla_group = "Bucks/Ox/West. Berks/Swindon" if utla_name == "Swindon"
replace utla_group = "Bucks/Ox/West. Berks/Swindon" if utla_name == "West Berkshire"

replace utla_group = "Camden and Westminster" if utla_name == "Camden"
replace utla_group = "Camden and Westminster" if utla_name == "Westminster"

replace utla_group = "" if utla_name == "Isles of Scilly"

replace utla_group = "Richmond and Hounslow" if utla_name == "Richmond upon Thames"
replace utla_group = "Richmond and Hounslow" if utla_name == "Hounslow"

replace utla_group = "Rutland and Lincoln" if utla_name == "Rutland"
replace utla_group = "Rutland and Lincoln" if utla_name == "Lincolnshire"

replace utla_group = "Bolton and Tameside" if utla_name == "Bolton"
replace utla_group = "Bolton and Tameside" if utla_name == "Tameside"

tab utla_group



**************************
*  Categorise variables  *
**************************


/*  Age variables  */ 

* Create categorised age
recode age 18/39.9999=1 40/49.9999=2 50/59.9999=3 ///
	60/69.9999=4 70/79.9999=5 80/max=6, gen(agegroup) 

label define agegroup 	1 "18-<40" ///
						2 "40-<50" ///
						3 "50-<60" ///
						4 "60-<70" ///
						5 "70-<80" ///
						6 "80+"
label values agegroup agegroup


* Create binary age
recode age min/69.999=0 70/max=1, gen(age70)

* Check there are no missing ages
assert age<.
assert agegroup<.
assert age70<.

* Create restricted cubic splines fir age
mkspline age = age, cubic nknots(4)


/* Household size */
summ household_size, d


/*  Body Mass Index  */

* BMI (NB: watch for missingness)
gen 	bmicat = .
recode  bmicat . = 1 if bmi<18.5
recode  bmicat . = 2 if bmi<25
recode  bmicat . = 3 if bmi<30
recode  bmicat . = 4 if bmi<35
recode  bmicat . = 5 if bmi<40
recode  bmicat . = 6 if bmi<.
replace bmicat = . if bmi>=.

label define bmicat 1 "Underweight (<18.5)" 	///
					2 "Normal (18.5-24.9)"		///
					3 "Overweight (25-29.9)"	///
					4 "Obese I (30-34.9)"		///
					5 "Obese II (35-39.9)"		///
					6 "Obese III (40+)"			
					
label values bmicat bmicat

* Create more granular categorisation
recode bmicat 1/3 . = 1 4=2 5=3 6=4, gen(obese4cat)

label define obese4cat 	1 "No record of obesity" 	///
						2 "Obese I (30-34.9)"		///
						3 "Obese II (35-39.9)"		///
						4 "Obese III (40+)"		
label values obese4cat obese4cat
order obese4cat, after(bmicat)



/*  Smoking  */


* Create non-missing 3-category variable for current smoking
recode smoke .=1, gen(smoke_nomiss)
order smoke_nomiss, after(smoke)
label values smoke_nomiss smoke



/*  Asthma  */


* Asthma  (coded: 0 No, 1 Yes no OCS, 2 Yes with OCS)
rename asthma asthmacat
recode asthmacat 0=1 1=2 2=3 .=1
label define asthmacat 1 "No" 2 "Yes, no OCS" 3 "Yes with OCS"
label values asthmacat asthmacat

gen asthma = (asthmacat==2|asthmacat==3)





/*  Blood pressure   */

* Categorise
gen     bpcat = 1 if bp_sys < 120 &  bp_dias < 80
replace bpcat = 2 if inrange(bp_sys, 120, 130) & bp_dias<80
replace bpcat = 3 if inrange(bp_sys, 130, 140) | inrange(bp_dias, 80, 90)
replace bpcat = 4 if (bp_sys>=140 & bp_sys<.) | (bp_dias>=90 & bp_dias<.) 
replace bpcat = . if bp_sys>=. | bp_dias>=. | bp_sys==0 | bp_dias==0

label define bpcat 1 "Normal" 2 "Elevated" 3 "High, stage I"	///
					4 "High, stage II" 
label values bpcat bpcat

recode bpcat .=1, gen(bpcat_nomiss)
label values bpcat_nomiss bpcat

* Create non-missing indicator of known high blood pressure
gen bphigh = (bpcat==4)
order bpcat bphigh, after(bp_dias_date)




/*  IMD  */

* Group into 5 groups
rename imd imd_o
egen imd = cut(imd_o), group(5) icodes
replace imd = imd + 1
replace imd = . if imd_o==-1
drop imd_o

* Reverse the order (so high is more deprived)
recode imd 5=1 4=2 3=3 2=4 1=5 .=.

label define imd 1 "1 least deprived" 2 "2" 3 "3" 4 "4" 5 "5 most deprived" 
label values imd imd 

noi di "DROPPING IF NO IMD" 
drop if imd>=.





/*  Centred age, sex, IMD, ethnicity (for adjusted KM plots)  */ 

* Centre age (linear)
summ age
gen c_age = age-r(mean)

* "Centre" sex to be coded -1 +1 
recode male 0=-1, gen(c_male)

* "Centre" IMD
gen c_imd = imd - 3

* "Centre" ethnicity
gen c_ethnicity = ethnicity - 3




**************************************************
*  Create binary comorbidity indices from dates  *
**************************************************

* Comorbidities ever before
foreach var of varlist	chronic_respiratory_disease_date 	///
						chronic_cardiac_disease_date 		///
						diabetes 							///
						chronic_liver_disease_date 			///
						stroke_date							///
						dementia_date						///
						other_neuro_date					///
						organ_transplant_date 				///
						aplastic_anaemia_date				///
						hypertension 						///
						dysplenia_date 						///
						sickle_cell_date 					///
						hiv_date							///
						permanent_immunodeficiency_date		///
						temporary_immunodeficiency_date		///
						ra_sle_psoriasis_date dialysis_date {
	local newvar =  substr("`var'", 1, length("`var'") - 5)
	gen `newvar' = (`var'< d(1/9/2020))
	order `newvar', after(`var')
}






***************************
*  Grouped comorbidities  *
***************************


/*  Neurological  */

* Stroke and dementia
egen stroke_dementia = rowmax(stroke dementia)
order stroke_dementia, after(dementia_date)


/*  Spleen  */

* Spleen problems (dysplenia/splenectomy/etc and sickle cell disease)   
egen spleen = rowmax(dysplenia sickle_cell) 
order spleen, after(sickle_cell)



/*  Cancer  */

label define cancer 1 "Never" 2 "Last year" 3 "2-5 years ago" 4 "5+ years"

* Haematological malignancies
gen     cancer_haem_cat = 4 if inrange(haem_cancer_date, d(1/1/1900), d(1/2/2015))
replace cancer_haem_cat = 3 if inrange(haem_cancer_date, d(1/2/2015), d(1/2/2019))
replace cancer_haem_cat = 2 if inrange(haem_cancer_date, d(1/2/2019), d(1/2/2020))
recode  cancer_haem_cat . = 1
label values cancer_haem_cat cancer


* All other cancers
gen     cancer_exhaem_cat = 4 if inrange(lung_cancer_date,  d(1/1/1900), d(1/2/2015)) | ///
								 inrange(other_cancer_date, d(1/1/1900), d(1/2/2015)) 
replace cancer_exhaem_cat = 3 if inrange(lung_cancer_date,  d(1/2/2015), d(1/2/2019)) | ///
								 inrange(other_cancer_date, d(1/2/2015), d(1/2/2019)) 
replace cancer_exhaem_cat = 2 if inrange(lung_cancer_date,  d(1/2/2019), d(1/2/2020)) | ///
								 inrange(other_cancer_date, d(1/2/2019), d(1/2/2020))
recode  cancer_exhaem_cat . = 1
label values cancer_exhaem_cat cancer


* Put variables together
order cancer_exhaem_cat cancer_haem_cat, after(other_cancer_date)



/*  Immunosuppression  */

* Immunosuppressed:
* HIV, permanent immunodeficiency ever, OR 
* temporary immunodeficiency or aplastic anaemia last year
gen temp1  = max(hiv, permanent_immunodeficiency)
gen temp2  = inrange(temporary_immunodeficiency_date, d(1/2/2019), d(1/2/2020))
gen temp3  = inrange(aplastic_anaemia_date, d(1/2/2019), d(1/2/2020))

egen other_immunosuppression = rowmax(temp1 temp2 temp3)
drop temp1 temp2 temp3
order other_immunosuppression, after(temporary_immunodeficiency)




/*  Hypertension  */

gen htdiag_or_highbp = bphigh
recode htdiag_or_highbp 0 = 1 if hypertension==1 




************
*   eGFR   *
************

* Set implausible creatinine values to missing (Note: zero changed to missing)
replace creatinine = . if !inrange(creatinine, 20, 3000) 
	
* Divide by 88.4 (to convert umol/l to mg/dl)
gen SCr_adj = creatinine/88.4

gen min=.
replace min = SCr_adj/0.7 if male==0
replace min = SCr_adj/0.9 if male==1
replace min = min^-0.329  if male==0
replace min = min^-0.411  if male==1
replace min = 1 if min<1

gen max=.
replace max=SCr_adj/0.7 if male==0
replace max=SCr_adj/0.9 if male==1
replace max=max^-1.209
replace max=1 if max>1

gen egfr=min*max*141
replace egfr=egfr*(0.993^age)
replace egfr=egfr*1.018 if male==0
label var egfr "egfr calculated using CKD-EPI formula with no eth"

* Categorise into ckd stages
egen egfr_cat = cut(egfr), at(0, 15, 30, 45, 60, 5000)
recode egfr_cat 0=5 15=4 30=3 45=2 60=0, generate(ckd)
* 0 = "No CKD" 	2 "stage 3a" 3 "stage 3b" 4 "stage 4" 5 "stage 5"
label define ckd 0 "No CKD" 1 "CKD"
label values ckd ckd
label var ckd "CKD stage calc without eth"

* Convert into CKD group
*recode ckd 2/5=1, gen(chronic_kidney_disease)
*replace chronic_kidney_disease = 0 if creatinine==. 

recode ckd 0=1 2/3=2 4/5=3, gen(reduced_kidney_function_cat)
replace reduced_kidney_function_cat = 1 if creatinine==. 
label define reduced_kidney_function_catlab ///
	1 "None" 2 "Stage 3a/3b egfr 30-60	" 3 "Stage 4/5 egfr<30"
label values reduced_kidney_function_cat reduced_kidney_function_catlab 

*More detailed version incorporating stage 5 or dialysis as a separate category	
recode ckd 0=1 2/3=2 4=3 5=4, gen(reduced_kidney_function_cat2)
replace reduced_kidney_function_cat2 = 1 if creatinine==. 
replace reduced_kidney_function_cat2 = 4 if dialysis==1 

label define reduced_kidney_function_cat2lab ///
	1 "None" 2 "Stage 3a/3b egfr 30-60	" 3 "Stage 4 egfr 15-<30" 4 "Stage 5 egfr <15 or dialysis"
label values reduced_kidney_function_cat2 reduced_kidney_function_cat2lab 
 
	
************
*   Hba1c  *
************
	

/*  Diabetes severity  */

* Set zero or negative to missing
replace hba1c_percentage   = . if hba1c_percentage<=0
replace hba1c_mmol_per_mol = . if hba1c_mmol_per_mol<=0


* Only consider measurements in last 15 months
replace hba1c_percentage   = . if hba1c_percentage_date   < d(1/11/2018)
replace hba1c_mmol_per_mol = . if hba1c_mmol_per_mol_date < d(1/11/2018)



/* Express  HbA1c as percentage  */ 

* Express all values as perecentage 
noi summ hba1c_percentage hba1c_mmol_per_mol 
gen 	hba1c_pct = hba1c_percentage 
replace hba1c_pct = (hba1c_mmol_per_mol/10.929)+2.15 if hba1c_mmol_per_mol<. 

* Valid % range between 0-20  
replace hba1c_pct = . if !inrange(hba1c_pct, 0, 20) 
replace hba1c_pct = round(hba1c_pct, 0.1)


/* Categorise hba1c and diabetes  */

* Group hba1c
gen 	hba1ccat = 0 if hba1c_pct <  6.5
replace hba1ccat = 1 if hba1c_pct >= 6.5  & hba1c_pct < 7.5
replace hba1ccat = 2 if hba1c_pct >= 7.5  & hba1c_pct < 8
replace hba1ccat = 3 if hba1c_pct >= 8    & hba1c_pct < 9
replace hba1ccat = 4 if hba1c_pct >= 9    & hba1c_pct !=.
label define hba1ccat 0 "<6.5%" 1">=6.5-7.4" 2">=7.5-7.9" 3">=8-8.9" 4">=9"
label values hba1ccat hba1ccat
tab hba1ccat

* Create diabetes, split by control/not
gen     diabcat = 1 if diabetes==0
replace diabcat = 2 if diabetes==1 & inlist(hba1ccat, 0, 1)
replace diabcat = 3 if diabetes==1 & inlist(hba1ccat, 2, 3, 4)
replace diabcat = 4 if diabetes==1 & !inlist(hba1ccat, 0, 1, 2, 3, 4)

label define diabcat 	1 "No diabetes" 			///
						2 "Controlled diabetes"		///
						3 "Uncontrolled diabetes" 	///
						4 "Diabetes, no hba1c measure"
label values diabcat diabcat

* Delete unneeded variables
drop hba1c_pct hba1c_percentage hba1c_mmol_per_mol


********************************
*  Outcomes and survival time  *
********************************

/*  Cohort entry and censor dates  */

* Date of cohort entry, 1 Sep 2020
* Date of censoring, 1 Dec 2020
gen enter_date = date("01/09/2020", "DMY")
gen censor_date = date("01/12/2020", "DMY")
format %d enter_date censor_date

/*   Outcomes   */
* Binary indicators for covid, hospital admission, and death
gen covid_diag 		= (covid_tpp_probable < .)
gen sgss_diag		= (first_pos_test_sgss < .)


/*  Create survival times  */
* Survival time = last followup date (first: censor, vaccination, or outcome)
gen cox_covid_date  	= min(censor_date, covid_vacc_date, covid_tpp_probable)
gen cox_sgss_date  	= min(censor_date, covid_vacc_date, first_pos_test_sgss)


* If outcome was after censoring occurred, set to zero
replace covid_diag 		= 0 if (covid_tpp_probable > cox_covid_date)
replace sgss_diag 		= 0 if (first_pos_test_sgss > cox_sgss_date) 



* Format date variables
format cox_covid_date cox_sgss_date covid_tpp_probable first_pos_test_sgss %td 

		
		
*********************
*  Label variables  *
*********************

* Demographics
label var patient_id					"Patient ID"
label var age 							"Age (years)"
label var agegroup						"Grouped age"
label var age70 						"70 years and older"
label var male 							"Male"
label var household_size				"Household size"
label var household_id					"Household ID"

label var bmi 							"Body Mass Index (BMI, kg/m2)"
label var bmicat 						"Grouped BMI"
label var bmi_date  					"Body Mass Index (BMI, kg/m2), date measured"
label var obese4cat						"Evidence of obesity (4 categories)"
label var smoke		 					"Smoking status"
label var smoke_nomiss	 				"Smoking status (missing set to non)"
label var imd 							"Index of Multiple Deprivation (IMD)"
label var ethnicity						"Ethnicity"
label var ethnicity_16					"Ethnicity in 16 categories"
label var ethnicity_16_combinemixed		"Ethnicity detailed with mixed groups combined"
label var stp 							"Sustainability and Transformation Partnership"
label var msoa	 						"Geographical region: MSOA"
label var utla							"Geographical region: UTLA"
label var utla_name						"Geographical region: UTLA name"
label var utla_group					"Geographical region: UTLA grouped"

label var hba1ccat						"Categorised hba1c"
label var egfr_cat						"Calculated eGFR"
	
label var bp_sys 						"Systolic blood pressure"
label var bp_sys_date 					"Systolic blood pressure, date"
label var bp_dias 						"Diastolic blood pressure"
label var bp_dias_date 					"Diastolic blood pressure, date"
label var bpcat 						"Grouped blood pressure"
label var bphigh						"Binary high (stage 1/2) blood pressure"
label var htdiag_or_highbp				"Diagnosed hypertension or high blood pressure"

label var age1 							"Age spline 1"
label var age2 							"Age spline 2"
label var age3 							"Age spline 3"
label var c_age							"Centred age"
label var c_male 						"Centred sex (code: -1/+1)"
label var c_imd							"Centred Index of Multiple Deprivation (values: -2/+2)"
label var c_ethnicity					"Centred ethnicity (values: -2/+2)"

* Exposure
label var min_rti						"First RTI"
label var rti_0900						"RTI: 09JUN - 31AUG"
label var rti_0907						"RTI: 01SEP - 07SEP"
label var rti_0914						"RTI: 08SEP - 14SEP"
label var rti_0921						"RTI: 15SEP - 21SEP"
label var rti_0928						"RTI: 22SEP - 28SEP"
label var rti_1005						"RTI: 29SEP - 05OCT"
label var rti_1012						"RTI: 06OCT - 12OCT"
label var rti_1019						"RTI: 13OCT - 19OCT"
label var rti_1026						"RTI: 20OCT - 26OCT"
label var rti_1102						"RTI: 27OCT - 02NOV"
label var rti_1109						"RTI: 03NOV - 09NOV"
label var rti_1116						"RTI: 10NOV - 16NOV"
label var rti_1123						"RTI: 17NOV - 23NOV"
label var rti_1130						"RTI: 24NOV - 30NOV"

label var min_nrti						"First nRTI"
label var nrti_0900						"nRTI: 09JUN - 31AUG"
label var nrti_0907						"nnRTI: 01SEP - 07SEP"
label var nrti_0914						"nRTI: 08SEP - 14SEP"
label var nrti_0921						"nRTI: 15SEP - 21SEP"
label var nrti_0928						"nRTI: 22SEP - 28SEP"
label var nrti_1005						"nRTI: 29SEP - 05OCT"
label var nrti_1012						"nRTI: 06OCT - 12OCT"
label var nrti_1019						"nRTI: 13OCT - 19OCT"
label var nrti_1026						"nRTI: 20OCT - 26OCT"
label var nrti_1102						"nRTI: 27OCT - 02NOV"
label var nrti_1109						"nRTI: 03NOV - 09NOV"
label var nrti_1116						"nRTI: 10NOV - 16NOV"
label var nrti_1123						"nRTI: 17NOV - 23NOV"
label var nrti_1130						"nRTI: 24NOV - 30NOV"

* Comorbidities
label var chronic_respiratory_disease	"Respiratory disease (excl. asthma)"
label var asthmacat						"Asthma, grouped by severity (OCS use)"
label var asthma						"Asthma"
label var chronic_cardiac_disease		"Heart disease"
label var diabetes						"Diabetes"
label var diabcat						"Diabetes, grouped"
label var cancer_exhaem_cat				"Cancer (exc. haematological), grouped by time since diagnosis"
label var cancer_haem_cat				"Haematological malignancy, grouped by time since diagnosis"
label var chronic_liver_disease			"Chronic liver disease"
label var stroke_dementia				"Stroke or dementia"
label var other_neuro					"Neuro condition other than stroke/dementia"	
label var reduced_kidney_function_cat	"Reduced kidney function" 
label var organ_transplant 				"Organ transplant recipient"
label var dysplenia						"Dysplenia (splenectomy, other, not sickle cell)"
label var sickle_cell 					"Sickle cell"
label var spleen						"Spleen problems (dysplenia, sickle cell)"
label var ra_sle_psoriasis				"RA, SLE, Psoriasis (autoimmune disease)"
label var aplastic_anaemia				"Aplastic anaemia"
label var hiv 							"HIV"
label var permanent_immunodeficiency 	"Permanent immunodeficiency"
label var temporary_immunodeficiency 	"Temporary immunosuppression"
label var other_immunosuppression		"Immunosuppressed (combination algorithm)"
label var chronic_respiratory_disease_date	"Respiratory disease (excl. asthma), date"
label var chronic_cardiac_disease_date	"Heart disease, date"
label var diabetes_date					"Diabetes, date"
label var lung_cancer_date				"Lung cancer, date"
label var haem_cancer_date				"Haem. cancer, date"
label var other_cancer_date				"Any cancer, date"
label var chronic_liver_disease_date	"Liver, date"
label var stroke_date					"Stroke, date"
label var dementia_date					"Dementia, date"
label var other_neuro_date				"Neuro condition other than stroke/dementia, date"	
label var organ_transplant_date			"Organ transplant recipient, date"
label var dysplenia_date				"Splenectomy etc, date"
label var sickle_cell_date 				"Sickle cell, date"
label var ra_sle_psoriasis_date			"RA, SLE, Psoriasis (autoimmune disease), date"
label var aplastic_anaemia_date			"Aplastic anaemia, date"
label var hiv_date 						"HIV, date"
label var permanent_immunodeficiency_date "Permanent immunodeficiency, date"
label var temporary_immunodeficiency_date "Temporary immunosuppression, date"
label var dialysis						"Dialysis"

* Dates
label var covid_vacc_date				"Date of first covid vaccination"
label var covid_tpp_probable			"Date of covid diagnosis TPP"
label var covid_tpp_clin				"Date of covid diagnosis CLIN"
label var covid_tpp_test				"Date of covid diagnosis TEST"
label var covid_tpp_seq					"Date of covid diagnosis SEQ"

label var first_pos_test_sgss			"Date of first SGSS positive test"
	
* Outcomes and follow-up
label var enter_date					"Date of study entry"
label var censor_date					"Date of study exit"

label var covid_diag					"Failure/censoring indicator for outcome: covid diagnosis"
label var cox_covid_date	 			"Date; outcome covid diagnosis"

label var sgss_diag						"Failure/censoring indicator for outcome: SGSS covid diagnosis"
label var cox_sgss_date	 				"Date; outcome SGSS covid diagnosis"


***************
*  Tidy data  *
***************

* REDUCE DATASET SIZE TO VARIABLES NEEDED
ds , has(varl)
keep `r(varlist)'


***************
*  Save data  *
***************

sort patient_id
label data "Viral competition: $S_DATE"

save ./analysis/cr_analysis_dataset.dta, replace


log close

