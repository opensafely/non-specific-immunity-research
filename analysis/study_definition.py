# IMPORT STATEMENTS
# This imports the cohort extractor package. This can be downloaded via pip
from cohortextractor import (
    StudyDefinition,
    patients,
    codelist_from_csv,
    codelist,
    combine_codelists,
    filter_codes_by_category,
)

# dictionary of MSOA codes (for dummy data)
from dictionaries import dict_msoa

# IMPORT CODELIST DEFINITIONS FROM CODELIST.PY (WHICH PULLS THEM FROM
# CODELIST FOLDER
from codelists import *


# STUDY DEFINITION
# Defines both the study population and points to the important covariates and outcomes
study = StudyDefinition(
    default_expectations={
        "date": {"earliest": "1970-01-01", "latest": "today"},
        "rate": "uniform",
        "incidence": 0.2,
    },

   # STUDY POPULATION
    population=patients.registered_with_one_practice_between(
        "2019-09-01", "2020-09-01"
    ),

    dereg_date=patients.date_deregistered_from_all_supported_practices(
        on_or_after="2020-09-01", date_format="YYYY-MM",
    ),

    # OUTCOMES
    died_ons_covid_flag_any=patients.with_these_codes_on_death_certificate(
        covid_codelist,
        on_or_after="2020-02-01",
        match_only_underlying_cause=False,
        return_expectations={"date": {"earliest": "2020-02-01"}, "incidence" : 0.2},
    ),

    died_date_ons=patients.died_from_any_cause(
        on_or_after="2020-02-01",
        returning="date_of_death",
        include_month=True,
        include_day=True,
        return_expectations={"date": {"earliest": "2020-08-01"}, "incidence" : 0.1},
    ),


    ### Primary care COVID cases
    covid_tpp_probable=patients.with_these_clinical_events(
        combine_codelists(covid_identification_in_primary_care_case_codes_clinical,
                          covid_identification_in_primary_care_case_codes_test,
                          covid_identification_in_primary_care_case_codes_seq),
        return_first_date_in_period=True,
        include_day=True,
        return_expectations={"date": {"earliest": "2020-08-20"}, "incidence" : 0.6},
    ),

    covid_tpp_clin=patients.with_these_clinical_events(
        covid_identification_in_primary_care_case_codes_clinical,
        return_first_date_in_period=True,
        include_day=True,
        return_expectations={"date": {"earliest": "2020-08-20"}, "incidence" : 0.15},
    ),

    covid_tpp_test=patients.with_these_clinical_events(
        covid_identification_in_primary_care_case_codes_test,
        return_first_date_in_period=True,
        include_day=True,
        return_expectations={"date": {"earliest": "2020-08-20"}, "incidence" : 0.35},
    ),

    covid_tpp_seq=patients.with_these_clinical_events(
        covid_identification_in_primary_care_case_codes_seq,
        return_first_date_in_period=True,
        include_day=True,
        return_expectations={"date": {"earliest": "2020-08-20"}, "incidence" : 0.1},
    ),

    ### COVID test positive (SGSS)
    first_pos_test_sgss=patients.with_test_result_in_sgss(
       pathogen="SARS-CoV-2",
       test_result="positive",
       find_first_match_in_period=True,
       returning="date",
       date_format="YYYY-MM-DD",
       return_expectations={"date": {"earliest": "2020-06-01"},
                            "incidence": 0.4
       },
    ), 
   
    ### Admission to hospital - COVID diagnosis to be defined later
    covid_admission_date=patients.admitted_to_hospital(
        with_these_diagnoses=covid_codelist,
        returning= "date_admitted" , 
        on_or_after="2020-02-01",
        find_first_match_in_period=True,  
        date_format="YYYY-MM-DD",  
        return_expectations={"date": {"earliest": "2020-08-01"}, "incidence" : 0.3},
   ),

    covid_discharge_date=patients.admitted_to_hospital(
        with_these_diagnoses=covid_codelist,
        returning= "date_discharged" ,
        on_or_after="2020-02-01",
        find_first_match_in_period=True,  
        date_format="YYYY-MM-DD",  
        return_expectations={"date": {"earliest": "2020-03-01"}, "incidence" : 0.95},
   ),

    # Any COVID vaccination (first dose)
    covid_vacc_date=patients.with_tpp_vaccination_record(
        target_disease_matches="SARS-2 CORONAVIRUS",
        on_or_after="2020-12-01",  # check all december to date
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {
                "earliest": "2020-12-08",  # first vaccine administered on the 8/12
                "latest": "2021-01-31",
            },
                "incidence":0.2
        },
    ),

    # EXPOSURES
    lrti_in_period=patients.with_these_clinical_events(
        lrti_codes,
        between=["2020-06-09", "2020-12-01"],
        returning="number_of_matches_in_period",
        return_expectations={"int": {"distribution": "normal", "mean": 2, "stddev": 1}, "incidence": 0.2},
    ),    

    rti_in_period=patients.with_these_clinical_events(
        rti_codes,
        between=["2020-06-09", "2020-12-01"],
        returning="number_of_matches_in_period",
        return_expectations={"int": {"distribution": "normal", "mean": 2, "stddev": 1}, "incidence": 0.2},
    ),    

    rti_0900=patients.with_these_clinical_events(
        rti_codes,
        between=["2020-06-09", "2020-08-31"],
        returning="date",
        find_last_match_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": "2020-06-06", "latest": "2020-08-31"}, "incidence" : 0.1},
    ),    

    rti_0907=patients.with_these_clinical_events(
        rti_codes,
        between=["2020-09-01", "2020-09-07"],
        returning="date",
        find_last_match_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": "2020-09-07", "latest": "2020-09-13"}, "incidence" : 0.03},
    ),   

    rti_0914=patients.with_these_clinical_events(
        rti_codes,
        between=["2020-09-08", "2020-09-14"],
        returning="date",
        find_last_match_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": "2020-09-08", "latest": "2020-09-14"}, "incidence" : 0.03},
    ),   

    rti_0921=patients.with_these_clinical_events(
        rti_codes,
        between=["2020-09-15", "2020-09-21"],
        returning="date",
        find_last_match_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": "2020-09-15", "latest": "2020-09-21"}, "incidence" : 0.03},
    ),   

    rti_0928=patients.with_these_clinical_events(
        rti_codes,
        between=["2020-09-22", "2020-09-28"],
        returning="date",
        find_last_match_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": "2020-09-22", "latest": "2020-09-28"}, "incidence" : 0.03},
    ),   

    rti_1005=patients.with_these_clinical_events(
        rti_codes,
        between=["2020-09-29", "2020-10-05"],
        returning="date",
        find_last_match_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": "2020-09-29", "latest": "2020-10-05"}, "incidence" : 0.03},
    ),   

    rti_1012=patients.with_these_clinical_events(
        rti_codes,
        between=["2020-10-06", "2020-10-12"],
        returning="date",
        find_last_match_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": "2020-10-06", "latest": "2020-10-12"}, "incidence" : 0.03},
    ),   

    rti_1019=patients.with_these_clinical_events(
        rti_codes,
        between=["2020-10-13", "2020-10-19"],
        returning="date",
        find_last_match_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": "2020-10-13", "latest": "2020-10-19"}, "incidence" : 0.03},
    ),   

    rti_1026=patients.with_these_clinical_events(
        rti_codes,
        between=["2020-10-20", "2020-10-26"],
        returning="date",
        find_last_match_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": "2020-10-20", "latest": "2020-10-26"}, "incidence" : 0.03},
    ),  

    rti_1102=patients.with_these_clinical_events(
        rti_codes,
        between=["2020-10-27", "2020-11-02"],
        returning="date",
        find_last_match_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": "2020-10-27", "latest": "2020-11-02"}, "incidence" : 0.03},
    ),  

    rti_1109=patients.with_these_clinical_events(
        rti_codes,
        between=["2020-11-03", "2020-11-09"],
        returning="date",
        find_last_match_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": "2020-11-03", "latest": "2020-11-09"}, "incidence" : 0.03},
    ),  

    rti_1116=patients.with_these_clinical_events(
        rti_codes,
        between=["2020-11-10", "2020-11-16"],
        returning="date",
        find_last_match_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": "2020-11-10", "latest": "2020-11-16"}, "incidence" : 0.03},
    ),  

    rti_1123=patients.with_these_clinical_events(
        rti_codes,
        between=["2020-11-17", "2020-11-23"],
        returning="date",
        find_last_match_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": "2020-11-17", "latest": "2020-11-23"}, "incidence" : 0.03},
    ),  

    rti_1130=patients.with_these_clinical_events(
        rti_codes,
        between=["2020-11-24", "2020-11-30"],
        returning="date",
        find_last_match_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": "2020-11-24", "latest": "2020-11-30"}, "incidence" : 0.03},
    ),  


    ## DEMOGRAPHIC COVARIATES
    # AGE
    age=patients.age_as_of(
        "2020-09-01",
        return_expectations={
            "rate": "universal",
            "int": {"distribution": "population_ages"},
        },
    ),

    # SEX
    sex=patients.sex(
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"M": 0.49, "F": 0.51}},
        }
    ),

    # DEPRIVIATION
    imd=patients.address_as_of(
        "2020-09-01",
        returning="index_of_multiple_deprivation",
        round_to_nearest=100,
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"100": 0.1, "200": 0.2, "300": 0.7}},
        },
    ),

    # GEOGRAPHIC REGION CALLED STP
    stp=patients.registered_practice_as_of(
        "2020-09-01",
        returning="stp_code",
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "STP1": 0.1,
                    "STP2": 0.1,
                    "STP3": 0.1,
                    "STP4": 0.1,
                    "STP5": 0.1,
                    "STP6": 0.1,
                    "STP7": 0.1,
                    "STP8": 0.1,
                    "STP9": 0.1,
                    "STP10": 0.1,
                }
            },
        },
    ),

    # GEOGRAPHIC REGION MSOA
    msoa=patients.registered_practice_as_of(        
        "2020-09-01",
        returning="msoa_code",
        return_expectations={
            "rate": "universal",
            "category": {"ratios": dict_msoa},
        },
    ),

    # HOUSEHOLD INFORMATION
    household_id=patients.household_as_of(
        "2020-02-01",
        returning="pseudo_id",
        return_expectations={
            "int": {"distribution": "normal", "mean": 1000, "stddev": 200},
            "incidence": 1,
        },
    ),

    household_size=patients.household_as_of(
        "2020-02-01",
        returning="household_size",
        return_expectations={
            "int": {"distribution": "normal", "mean": 3, "stddev": 1},
            "incidence": 1,
        },
    ),

    care_home_type=patients.care_home_status_as_of(
        "2020-02-01",
        categorised_as={
            "PC": """
              IsPotentialCareHome
              AND LocationDoesNotRequireNursing='Y'
              AND LocationRequiresNursing='N'
            """,
            "PN": """
              IsPotentialCareHome
              AND LocationDoesNotRequireNursing='N'
              AND LocationRequiresNursing='Y'
            """,
            "PS": "IsPotentialCareHome",
            "U": "DEFAULT",
        },
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"PC": 0.05, "PN": 0.05, "PS": 0.05, "U": 0.85,},},
        },
    ),

    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/10
    bmi=patients.most_recent_bmi(
        on_or_after="2010-02-01",
        minimum_age_at_measurement=16,
        include_measurement_date=True,
        include_month=True,
        return_expectations={
            "date": {},
            "float": {"distribution": "normal", "mean": 35, "stddev": 10},
            "incidence": 0.95,
        },
    ),

    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/6
    smoking_status=patients.categorised_as(
        {
            "S": "most_recent_smoking_code = 'S'",
            "E": """
                 most_recent_smoking_code = 'E' OR (
                   most_recent_smoking_code = 'N' AND ever_smoked
                 )
            """,
            "N": "most_recent_smoking_code = 'N' AND NOT ever_smoked",
            "M": "DEFAULT",
        },
        return_expectations={
            "category": {"ratios": {"S": 0.6, "E": 0.1, "N": 0.2, "M": 0.1}}
        },
        most_recent_smoking_code=patients.with_these_clinical_events(
            clear_smoking_codes,
            find_last_match_in_period=True,
            on_or_before="2020-09-01",
            returning="category",
        ),
        ever_smoked=patients.with_these_clinical_events(
            filter_codes_by_category(clear_smoking_codes, include=["S", "E"]),
            on_or_before="2020-09-01",
        ),
    ),

    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/27
    ethnicity=patients.with_these_clinical_events(
        ethnicity_codes,
        returning="category",
        find_last_match_in_period=True,
        include_date_of_match=True,
        return_expectations={
            "category": {"ratios": {"1": 0.75, "2": 0.05, "3": 0.05, "4": 0.05, "5": 0.1}},
            "incidence": 0.75,
        },
    ),
    ethnicity_16=patients.with_these_clinical_events(
        ethnicity_codes_16,
        returning="category",
        find_last_match_in_period=True,
        include_date_of_match=True,
        return_expectations={
            "category": {"ratios": {"1": 0.8, "5": 0.1, "3": 0.1}},
            "incidence": 0.75,
        },
    ),
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/21
    chronic_respiratory_disease=patients.with_these_clinical_events(
        chronic_respiratory_disease_codes,
        return_first_date_in_period=True,
        include_month=True,
    ),
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/55
    asthma=patients.categorised_as(
        {
            "0": "DEFAULT",
            "1": """
                (
                  recent_asthma_code OR (
                    asthma_code_ever AND NOT
                    copd_code_ever
                  )
                ) AND (
                  prednisolone_last_year = 0 OR 
                  prednisolone_last_year > 4
                )
            """,
            "2": """
                (
                  recent_asthma_code OR (
                    asthma_code_ever AND NOT
                    copd_code_ever
                  )
                ) AND
                prednisolone_last_year > 0 AND
                prednisolone_last_year < 5
                
            """,
        },
        return_expectations={"category": {"ratios": {"0": 0.8, "1": 0.1, "2": 0.1}},},
        recent_asthma_code=patients.with_these_clinical_events(
            asthma_codes, between=["2017-02-01", "2020-09-01"],
        ),
        asthma_code_ever=patients.with_these_clinical_events(asthma_codes),
        copd_code_ever=patients.with_these_clinical_events(
            chronic_respiratory_disease_codes
        ),
        prednisolone_last_year=patients.with_these_medications(
            pred_codes,
            between=["2019-09-01", "2020-09-01"],
            returning="number_of_matches_in_period",
        ),
    ),

    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/7
    chronic_cardiac_disease=patients.with_these_clinical_events(
        chronic_cardiac_disease_codes,
        return_first_date_in_period=True,
        include_month=True,
    ),

    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/30
    diabetes=patients.with_these_clinical_events(
        diabetes_codes, return_first_date_in_period=True, include_month=True,
    ),

    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/32
    lung_cancer=patients.with_these_clinical_events(
        lung_cancer_codes, return_first_date_in_period=True, include_month=True,
    ),
    haem_cancer=patients.with_these_clinical_events(
        haem_cancer_codes, return_first_date_in_period=True, include_month=True,
    ),
    other_cancer=patients.with_these_clinical_events(
        other_cancer_codes, return_first_date_in_period=True, include_month=True,
    ),

    # # https://github.com/ebmdatalab/tpp-sql-notebook/issues/12
    chronic_liver_disease=patients.with_these_clinical_events(
        chronic_liver_disease_codes,
        return_first_date_in_period=True,
        include_month=True,
    ),

    # # https://github.com/ebmdatalab/tpp-sql-notebook/issues/14
    other_neuro=patients.with_these_clinical_events(
        other_neuro, return_first_date_in_period=True, include_month=True,
    ),
    stroke=patients.with_these_clinical_events(
        stroke, return_first_date_in_period=True, include_month=True,
    ),
    dementia=patients.with_these_clinical_events(
        dementia, return_first_date_in_period=True, include_month=True,
    ),

    # # Chronic kidney disease
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/17
    creatinine=patients.with_these_clinical_events(
        creatinine_codes,
        find_last_match_in_period=True,
        on_or_before="2020-09-01",
        returning="numeric_value",
        include_date_of_match=True,
        include_month=True,
        return_expectations={
            "float": {"distribution": "normal", "mean": 60.0, "stddev": 15},
            "date": {"earliest": "2019-02-28", "latest": "2020-08-29"},
            "incidence": 0.95,
        },
    ),
    dialysis=patients.with_these_clinical_events(
        dialysis_codes, return_first_date_in_period=True, include_month=True,
    ),

    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/31
    organ_transplant=patients.with_these_clinical_events(
        organ_transplant_codes, return_first_date_in_period=True, include_month=True,
    ),

    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/13
    dysplenia=patients.with_these_clinical_events(
        spleen_codes, return_first_date_in_period=True, include_month=True,
    ),
    sickle_cell=patients.with_these_clinical_events(
        sickle_cell_codes, return_first_date_in_period=True, include_month=True,
    ),

    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/36
    aplastic_anaemia=patients.with_these_clinical_events(
        aplastic_codes, return_last_date_in_period=True, include_month=True,
    ),
    hiv=patients.with_these_clinical_events(
        hiv_codes,
        returning="category", 
        find_first_match_in_period=True, 
        include_date_of_match=True,
        include_month=True,
        return_expectations={
            "category": {"ratios": {"43C3.": 0.8, "XaFuL": 0.2}},
            },
    ),   
    permanent_immunodeficiency=patients.with_these_clinical_events(
        permanent_immune_codes, return_first_date_in_period=True, include_month=True,
    ),
    temporary_immunodeficiency=patients.with_these_clinical_events(
        temp_immune_codes, return_last_date_in_period=True, include_month=True,
    ),

    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/23
    # immunosuppressant_med=
    # hypertension
    hypertension=patients.with_these_clinical_events(
        hypertension_codes, return_first_date_in_period=True, include_month=True,
    ),

    # Blood pressure
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/35
    bp_sys=patients.mean_recorded_value(
        systolic_blood_pressure_codes,
        on_most_recent_day_of_measurement=True,
        on_or_before="2020-02-01",
        include_measurement_date=True,
        include_month=True,
        return_expectations={
            "float": {"distribution": "normal", "mean": 80, "stddev": 10},
            "date": {"latest": "2020-08-29"},
            "incidence": 0.95,
        },
    ),
    bp_dias=patients.mean_recorded_value(
        diastolic_blood_pressure_codes,
        on_most_recent_day_of_measurement=True,
        on_or_before="2020-02-01",
        include_measurement_date=True,
        include_month=True,
        return_expectations={
            "float": {"distribution": "normal", "mean": 120, "stddev": 10},
            "date": {"latest": "2020-08-29"},
            "incidence": 0.95,
        },
    ),
    hba1c_mmol_per_mol=patients.with_these_clinical_events(
        hba1c_new_codes,
        find_last_match_in_period=True,
        on_or_before="2020-02-01",
        returning="numeric_value",
        include_date_of_match=True,
        include_month=True,
        return_expectations={
            "date": {"latest": "2020-08-29"},
            "float": {"distribution": "normal", "mean": 40.0, "stddev": 20},
            "incidence": 0.95,
        },
    ),
    hba1c_percentage=patients.with_these_clinical_events(
        hba1c_old_codes,
        find_last_match_in_period=True,
        on_or_before="2020-09-01",
        returning="numeric_value",
        include_date_of_match=True,
        include_month=True,
        return_expectations={
            "date": {"latest": "2020-08-29"},
            "float": {"distribution": "normal", "mean": 5, "stddev": 2},
            "incidence": 0.95,
        },
    ),

    # # https://github.com/ebmdatalab/tpp-sql-notebook/issues/49
    ra_sle_psoriasis=patients.with_these_clinical_events(
        ra_sle_psoriasis_codes, return_first_date_in_period=True, include_month=True,
    ),
)