# Viral competition and transient non-specific immunity to COVID-19

This project is retired. 
It is also described here https://www.opensafely.org/approved-projects/#project-79.

Results in this repository MUST NOT be considered an accurate or valid representation of the study purpose. These data may reflect an incomplete or incorrect analysis with no further ongoing work. The repository content has ONLY been made public to support the OpenSAFELY open science and transparency principles and to support the sharing of re-usable code for other subsequent users. The results have not been peer-reviewed. No clinical, policy or safety conclusions must be drawn from any of the data here

This is a study of non-specific immunity to COVID-19 due to viral competition resulting from non-COVID-19 respiratory infections.


This is the code and configuration for our analysis

* The paper is not yet written
* Raw model outputs, including charts, crosstabs, etc, are in `released_outputs/`
* If you are interested in how we defined our variables, take a look at the [study definition](analysis/study_definition.py); this is written in `python`, but non-programmers should be able to understand what is going on there
* If you are interested in how we defined our code lists, look in the [codelists folder](./codelists/).
* Developers and epidemiologists interested in the code should review
[DEVELOPERS.md](./docs/DEVELOPERS.md).

# About the OpenSAFELY framework

The OpenSAFELY framework is a new secure analytics platform for
electronic health records research in the NHS.

Instead of requesting access for slices of patient data and
transporting them elsewhere for analysis, the framework supports
developing analytics against dummy data, and then running against the
real data *within the same infrastructure that the data is stored*.
Read more at [OpenSAFELY.org](https://opensafely.org).

The framework is under fast, active development to support rapid
analytics relating to COVID19; we're currently seeking funding to make
it easier for outside collaborators to work with our system.  You can
read our current roadmap [here](ROADMAP.md).
