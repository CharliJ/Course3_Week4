# Reference: https://drive.google.com/file/d/0B1r70tGT37UxYzhNQWdXS19CN1U/view
# Reference: https://thoughtfulbloke.wordpress.com/2015/09/09/getting-and-cleaning-the-assignment/


library(dplyr)
library(data.table)
library(plyr)

# #Download and unzip the file
# temp <- tempfile()
# fileURL<- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
# download.file(fileURL,temp)
# unzip(temp)
# unlink(temp)

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

# merge the test and train data sets
data<-rbind(test,train)

# identify which features are means or stds
patterns <- c("-mean\\()", "-std\\()")
mean_std<-filter(features, grepl(paste(patterns, collapse="|"), measurement))


# creates a vector to tie between the data set and the feature names that have mean or std
mean_std_col <- paste0("V",mean_std$meas_id)

# subset the data that has mean or std
data1<- data[,c("subject","class", mean_std_col)]
data1<- data1[order(data1$subject),]

# make the names in the format desired
mean_std$measurement<-gsub("\\()","",as.character(mean_std$measurement))
mean_std$measurement<-gsub("-","\\.",as.character(mean_std$measurement))
mean_std$measurement<-gsub("^t","time.",as.character(mean_std$measurement))
mean_std$measurement<-gsub("^f","freq.",as.character(mean_std$measurement))
colnames(data1)<- c("subject", "class", as.character(mean_std$measurement))

# merge for activity names - used join instead of merge to not reorder rows
data2<- as.data.table(join(activities, data1 , by = "class"))
data2$class <- NULL

# clean up format
data2$activity <- tolower(data2$activity)
data2<- data2[order(data2$subject),]
data2names <- names(data2)
data2names[1]<-"subject"
data2names[2]<-"activity"
setcolorder(data2,data2names)

#create summary data set w/ descriptive names
setkey(data2, subject, activity)
data3<- data2[,lapply(.SD,mean), by = c("subject", "activity")]
data3names <- paste0("Mean.", names(data3))
data3names[1]<-"subject"
data3names[2]<-"activity"
setnames(data3, data3names)

write.table(data3,"Part5data.txt", row.names = FALSE)

# data3check<- read.table("Part5data.txt", header = TRUE)
