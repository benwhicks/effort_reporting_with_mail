# Guide to effort reporting process

The following documents using the [Effort Tracking](https://efforttracking.com/) framework along side with interfacing with Edumate as a school information system. **To run this system you will need [R](https://www.r-project.org/) installed, and preferebly through [RStudio](https://www.rstudio.com/). Then clone or download this entire repository to run from your local machine.** 

The most relevant parts of this repository are:

* _code_ folder. This contains relevant __sql__ and __r__ scripts to use, either for wrangling data or performing analysis.
* _data_ folder. Directory for storing data, including any sample data. School data is not uploaded to this repo.
* _reports_ folder. Directory for outputting reports, including any sample reports. School reports and analysis not uploaded to this repo.

The less relevant parts are:

* _arxode_ folder. All archived code - unsorted and unruly.
* _oxley v1 effort system_ folder. A tidy collection of code for the pre-_Effort Tracking_ version. This involved a [google script](https://script.google.com/d/1hPkOWuOQs6az5Lpf9RFZCSlDeq1Oe1gYmRpWIN-0Lmm3oLgAEhx96yD2/edit) that retrieved responses and running r code to generate and email the reports.

## Wrangling data for _Effort Tracking_ system

The _Effort Tracking_ system specifies a template for the csv upload that it needs. The following process goes through extracting the data from Edumate and preparing it for the *Effort Tracking* system. 

### 0. Initial set up

1. Install Rstudio and the *plyr* package. To install this within R type `install.packages("plyr")` into the *Console* (where the `>` is) in RStudio and hit *Enter*. It should download and install automatically. To check it is installed type `library(plyr)` into the *Console* and hit enter - it should look like nothing happens if it is working correctly, and should throw an error if not.

2. Download this repository (which is an *R Project*). Go to the top of this screen and selecting *Download as zip*, then extract that folder and save it somewhere easy to find. You will need to open the file called *Effort Reporting.Rproj* from the extracted folder - which should open in RStudio.

Note that all files should be saved into the *data* folder within the downloaded folder, and with sensible names. 

### 1. Set up new reporting period on _Effort Tracking_

Go to the Effort Tracking site and create a new reporting period. Use the naming format _YYYY Term N_.

### 2. Extract enrolment data from Edumate. 

This is done with the script called *edumate_enrolment_ox.sql* but can also be found in *Reports - Enrolment Reports* on Edumate. The query is called *Current enrolments for effort reporting*. Unfortunately it does not include the *House* information for the students, so we have to run a seperate query (part 2) and then merge them together (part 4).

### 3. Extract student information from Edumate.

This is primarily to get the House field which is not extracted from the sql query in step 1. This is done entirely through Edumate by generating a custom report and selecting required fields: 

* *Student ID*
* *House*
* *Tutor Group* - this is extracted from the sql in part 1 but is incorrect
* *Form* 
* *Gender*

At the moment of writing this this is done through *Contacts -> Print -> Generate List* in Edumate. 

### 4. Extract academic data. (Not yet working - omit this step)

The sql query *edumate_academic_ox.sql* should extract all the academic data (i.e. assessment task marks) for the current academic year. This is found in *Reports - Academic Reports* on Edumate and is called *Academic Data Export for Effort Reporting*. In future, this will be used to upload the academic data to the Effort Tracking system, however this is yet to be implemented.

### 5. Merge Edumate csv files 

This step is done in the R programming environment, which is run through the program *Rstudio*. We want to merge the two (three eventually) csv files from steps 1 - 3 into relevant format for _Effort Tracking_ system. 

To merge the files we need to run the script *edumate_data_merger.R*.  Once in RStudio (having opened the R Project *Effort Reporting*) look for the *Files* section (within one of the 3 or 4 main windows, not in the normal File menu) where you should be able to navigate to the folder called *code* by clicking on the text *code*. Once there click on *edumate_data_merger.R* which should open the script in the editor window. 

Near the top of the *edumate_data_merger.R* file is the following section of code:

``` r
############# CHANGE THESE AS REQUIRED ###################
Enrolment_Data_Path <- "data/2018T3_edumate_enrolment_data.csv"
Student_Info_Path <- "data/2018T3_edumate_student_data.csv"
Effort_Tracking_Uploader_Filename <- "2018T3_merged_enrolment_data.csv"
##########################################################
```

The test within the quotes is the only part of the code that you need to change. The first line should point to the Edumate enrolment data file (file from step 1), and the second line should point to the student info data (file from step 2). The third line is the name of the output file (this will also be placed in the *data* folder).

Once the names have been adjusted run the script by clicking 'Run'. If you want to all the code in one go use Ctrl-a and then hit 'Run'. 

### 6. Add data to *Effort Tracking* upload template

Open the file generated by the *edumate_data_merger.R* script and check that it looks like the data you should be uploading. This will need to be added to the template provided by the *Effort Tracking* site. The best way to do this is to just copy the columns required across to the template, keeping the headings in the template. Format for the name should be `2018T3_effort_tracking_upload.csv`, that way each effort reporting cycle has four .csv files of similar name format. 

### 7. Upload to *Effort Tracking*

Upload the output csv file from step 5 to the _Effort Tracking_ site.
