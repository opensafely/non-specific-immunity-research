/*==============================================================================
DO FILE NAME:			00_Test_runs_and_feasibility
PROJECT:				Non-specific immunity
DATE: 					9th November 2020 
AUTHOR:					Daniel Grint 										
DESCRIPTION OF FILE:	Test runs and feasibility
DATASETS USED:			data in memory (from analysis/input.csv)
DATASETS CREATED: 		
OTHER OUTPUT: 			logfiles, printed to folder analysis/$logdir
							
==============================================================================*/

cd C:\Users\EIDEDGRI\Documents\GitHub\non-specific-immunity-research

log using logs/model.log
import delimited output/input.csv
log close


keep patient_id sgss_covid_test_ever* covid_anytest* covid_negtest covid_tpp_probable

