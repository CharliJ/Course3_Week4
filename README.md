README
================

Summary
-------

The run\_analysis.R script analyzes "data collected from acceleromteres from the Samsung Galaxy S smartphone" (1), and generates a text file that contains the means of means and standard deviations of measurements taken per each of 30 subjects doing 6 activities. The generated text file is tidy, in that each variable is in its own column, and each observation is in its own row. run\_analysis.R is the only script used - it does not call any others. The data may be read using:

    read.table("Part5data.txt", header = TRUE)

Introduction
------------

"A full description {of the data} is available at the site where the data was obtained:

<http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones>"(1)

The data used for the analysis may be downloaded through R as follows:

    temp <- tempfile()
    fileURL<- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
    download.file(fileURL,temp)
    unzip(temp)
    unlink(temp)

The README.txt file included in the download describes the original experiment and processing. For clarity, the file descriptions of the files required for this analysis are repeated (2): " - 'features.txt': List of all features.

-   'activity\_labels.txt': Links the class labels with their activity name.

-   'train/X\_train.txt': Training set.

-   'train/y\_train.txt': Training labels.

-   'test/X\_test.txt': Test set.

-   'test/y\_test.txt': Test labels.

The following files are available for the train and test data. Their descriptions are equivalent.

-   'train/subject\_train.txt': Each row identifies the subject who performed the activity for each window sample. Its range is from 1 to 30. "

\*\*\* Please note that the Inertial Signals data included in the download are not needed for this analysis.

Data Analysis Overview
----------------------

The data analysis instructions were as follows (1):

1.  Merges the training and the test sets to create one data set.
2.  Extracts only the measurements on the mean and standard deviation for each measurement.
3.  Uses descriptive activity names to name the activities in the data set
4.  Appropriately labels the data set with descriptive variable names.
5.  From the data set in step 4, creates a second, independent tidy data set with the average of each variable for each activity and each subject.

The dplyr, plyr, and data.table libraries are need for this script.

Step 0: Data Reading & Pre-Processing
-------------------------------------

    # read in the files
    activities <- read.table("./UCI HAR Dataset/activity_labels.txt", col.names=c("class", "activity"))

    features <- read.table("./UCI HAR Dataset/features.txt", col.names=c("meas_id", "measurement"))

    subject_test<-read.table("./UCI HAR Dataset/test/subject_test.txt", col.names = c("subject"))
    x_test<-read.table("./UCI HAR Dataset/test/X_test.txt")
    y_test<-read.table("./UCI HAR Dataset/test/y_test.txt", col.names = c("class"))

    subject_train<-read.table("./UCI HAR Dataset/train/subject_train.txt", col.names = c("subject"))
    x_train<-read.table("./UCI HAR Dataset/train/X_train.txt")
    y_train<-read.table("./UCI HAR Dataset/train/y_train.txt", col.names = c("class"))

    # add the activity class and subject to the data in each data set 
    test<-cbind(subject_test, y_test, x_test)
    train<-cbind(subject_train, y_train, x_train)

Step 1: Merges the training and the test sets to create one data set.
---------------------------------------------------------------------

    data<-rbind(test,train)

Step 2: Extracts only the measurements on the mean and standard deviation for each measurement.
-----------------------------------------------------------------------------------------------

This step is open to interpretation, as noted in a few resources (3,4). This script only extracts measurements with mean() or std() in the variable name. This approach was chosen so as not to further confound weighted averages or complex calculations perhaps poorly represented as simply a "mean" without further explanation as provided in the original data.

    # identify which features are means or stds
    patterns <- c("-mean\\()", "-std\\()")
    mean_std<-filter(features, grepl(paste(patterns, collapse="|"), measurement))

    # creates a vector to tie between the data set and the feature names that have mean or std
    mean_std_col <- paste0("V",mean_std$meas_id)

    # subset the data that has mean or std
    data1<- data[,c("subject","class", mean_std_col)]
    data1<- data1[order(data1$subject),]

    # make the variable names in the format desired
    mean_std$measurement<-gsub("\\()","",as.character(mean_std$measurement))
    mean_std$measurement<-gsub("-","\\.",as.character(mean_std$measurement))
    mean_std$measurement<-gsub("^t","time.",as.character(mean_std$measurement))
    mean_std$measurement<-gsub("^f","freq.",as.character(mean_std$measurement))
    colnames(data1)<- c("subject", "class", as.character(mean_std$measurement))

Step 3: Uses descriptive activity names to name the activities in the data set
------------------------------------------------------------------------------

The English names of the six activities are associated with the activity class, rendering the activities into a descriptive, readable format.

    # merge for activity names - used join instead of merge to not reorder rows
    data2<- as.data.table(join(activities, data1 , by = "class"))
    data2$class <- NULL

    # cleans up format
    data2$activity <- tolower(data2$activity) #makes activities lower case
    data2<- data2[order(data2$subject),]
    data2names <- names(data2)
    data2names[1]<-"subject"
    data2names[2]<-"activity"
    setcolorder(data2,data2names) 

Step 4: Appropriately labels the data set with descriptive variable names.
--------------------------------------------------------------------------

In "clean-as-you-go" style, this step was completed under Step 2, where the variable names were re-formatted. Repeated again here for clarity:

    # make the variable names in the format desired
    mean_std$measurement<-gsub("\\()","",as.character(mean_std$measurement))
    mean_std$measurement<-gsub("-","\\.",as.character(mean_std$measurement))
    mean_std$measurement<-gsub("^t","time.",as.character(mean_std$measurement))
    mean_std$measurement<-gsub("^f","freq.",as.character(mean_std$measurement))
    colnames(data1)<- c("subject", "class", as.character(mean_std$measurement))

Step 5: From the data set in step 4, creates a second, independent tidy data set with the average of each variable for each activity and each subject.
------------------------------------------------------------------------------------------------------------------------------------------------------

The data.table package was used here for ease. "Mean" was added to each variable name to make them more descriptive and more easily differentiated from the original, un-average variables.

The produced data set is tidy in the wide format. It has the average of each feature that had mean() or std() in the variable name for each activity for each subject. Each line contains the measurements for only one observation (1 subject, 1 activity).

    #create summary data set w/ descriptive names
    setkey(data2, subject, activity)
    data3<- data2[,lapply(.SD,mean), by = c("subject", "activity")]
    data3names <- paste0("Mean.", names(data3))
    data3names[1]<-"subject"
    data3names[2]<-"activity"
    setnames(data3, data3names)

    write.table(data3,"Part5data.txt", row.names = FALSE)

References
----------

1.  <https://www.coursera.org/learn/data-cleaning/peer/FIZtT/getting-and-cleaning-data-course-project>
2.  UCI HAR Dataset README.txt
3.  <https://drive.google.com/file/d/0B1r70tGT37UxYzhNQWdXS19CN1U/view>
4.  <https://thoughtfulbloke.wordpress.com/2015/09/09/getting-and-cleaning-the-assignment/>
