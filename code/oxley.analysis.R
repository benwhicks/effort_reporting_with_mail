# Analysis - Oxley

# importing and setting up data

library(tidyverse)
library(wesanderson)

trim_pref_name <- function(x) {
  x <- gsub( " *\\(.*?\\) *", "", x)
  return(x)
}

PATH_TO_ALL_EFFORT_DATA <- "/Users/tahrenhicks/Documents/Data Analysis/Oxley Data/oxley.all.effort.data.csv"
PATH_TO_ALL_STUDENT_INFO <- "/Users/tahrenhicks/Documents/Data Analysis/Oxley Data/oxley.all.student.info.csv"
PATH_TO_ALL_ACADEMIC_DATA_FOLDER <- "/Users/tahrenhicks/Documents/Data Analysis/Oxley Data/Edumate Export/"

all.effort.data <- readr::read_csv(PATH_TO_ALL_EFFORT_DATA)
student.info <- readr::read_csv(PATH_TO_ALL_STUDENT_INFO)
all.effort.data$Student.name <- trim_pref_name(
  stringr::str_to_title(all.effort.data$Student.name))
all.effort.data$Source <- factor(all.effort.data$Source, levels = c("Student", "Teacher"))

# removing unwanted fields
all.effort.data$Teacher.code <- NULL
all.effort.data$Teacher.name <- NULL
student.info$Student.name <- trim_pref_name(
  stringr::str_to_title(student.info$Student.name)
)
students <- unique(all.effort.data[complete.cases(all.effort.data),c("Student.name","Student.code")])
students <- students[order(students$Student.name),]

effort.means <- all.effort.data %>% 
  group_by(Student.code, Student.name, Source, Date) %>% 
  summarise(Effort = mean(Score, na.rm = T))

effort.means.category <- all.effort.data %>% 
  group_by(Student.code, Student.name, Source, Category, Date) %>% 
  summarise(Effort = mean(Score, na.rm = T))

# School Assessment Data
assessment.files <- list.files(PATH_TO_ALL_ACADEMIC_DATA_FOLDER, pattern = "*.csv", full.names = TRUE)
all.assessment.data <- do.call(rbind, lapply(assessment.files, readr::read_csv)) 
all.assessment.data$MARK_PERCENTAGE <- all.assessment.data$RAW_MARK / all.assessment.data$MARK_OUT_OF

# mucking around with assessment data
eff_merge <- effort.means
eff_merge$Type = "Effort"
eff_merge$Score <- eff_merge$Effort
eff_merge$Effort <- NULL
eff_merge$Student.name <- NULL
ach_merge <- select(all.assessment.data, 
                    Student.code = STUDENT_NUMBER,
                    Date = DUE_DATE,
                    Score = Z_SCORE)
ach_merge$Type = "Achievement"
ach_merge$Source = "Teacher"
eff_merge$Score <- (eff_merge$Score - mean(eff_merge$Score, na.rm = T))/sd(eff_merge$Score, na.rm = T)
ach_v_eff <- bind_rows(ach_merge, eff_merge)
ach_v_eff$Date <- lubridate::round_date(ach_v_eff$Date, unit = "3 months")

# mucking around with graph - teacher ach v eff
achVeff <- ach_v_eff[ach_v_eff$Source == "Teacher",] %>% 
  group_by(Student.code, Date, Type) %>% 
  summarise(Score = mean(Score)) %>%
  spread(key = Type, value = Score)
achVeffGraphData <- merge(achVeff[complete.cases(achVeff),],   student.info[,c("Student.code", "Student.name", "Gender")]) 
gtest1 <- ggplot(data = achVeffGraphData, aes(x = Effort, y = Achievement, colour = Gender)) + 
  geom_point(alpha = 0.2) + 
  scale_colour_manual(values = wes_palette("Darjeeling1")) +
  theme_minimal() +
  geom_rug(alpha = 0.1) + 
  geom_smooth(alpha = 0.2, size = 0.4, method = "loess") + 
  ggtitle("Teacher reported effort vs achievement")

# mucking around with graph - student eff v ach
achVeffStudent <- ach_v_eff[ach_v_eff$Type == "Achievement" | ach_v_eff$Source == "Student", ] %>%
  group_by(Student.code, Date, Type) %>%
  summarise(Score = mean(Score)) %>%
  spread(key = Type, value = Score)
achVeffStudent <- merge(achVeffStudent[complete.cases(achVeffStudent),],   student.info[,c("Student.code", "Student.name", "Gender")]) 
gtest2 <- ggplot(data = achVeffStudent, aes(x = Effort, y = Achievement, colour = Gender)) + 
  geom_point(alpha = 0.2) + 
  scale_colour_manual(values = wes_palette("Darjeeling1")) +
  theme_minimal() +
  geom_rug(alpha = 0.1) + 
  geom_smooth(alpha = 0.2, size = 0.4, method = "loess") + 
  ggtitle("Student reported effort vs achievement")

# mucking around with teacher v student
em <- merge(effort.means, student.info[,c("Student.code", "Form", "Gender")])
gtest3 <- ggplot(data = em[em$Form != "2017 Year 12",], aes(Effort, colour = Gender, linetype = Source)) +
  geom_density(bw = 0.2) +
  scale_color_manual(values = wes_palette("Royal1")) +
  scale_x_continuous(limits = c(1,5), labels = c("Unsatisfactory","Fair","Good","Very Good","Outstanding")) +
  theme_minimal() +
  ggtitle("Distribution by Cohort") +
  facet_grid(Form ~ .)
#ggsave("~/Desktop/cohort effort teacher student dist.png", gtest3)


# Getting course marks for each course per year level
# Focusing on 11 to 12 mathematics (data too messy)
course.assessment.data <- all.assessment.data[all.assessment.data$DUE_DATE > "2016-01-01",]
maths.assessment.data <- course.assessment.data[grepl("Math", course.assessment.data$COURSE),]

maths.assessment.data <- maths.assessment.data[
  0 < maths.assessment.data$WEIGHTING & 
    maths.assessment.data$WEIGHTING < 100 & 
    !(is.na(maths.assessment.data$WEIGHTING)),
  ]
maths.assessment.data[grepl("Half|half|mid|Mid", maths.assessment.data$TASK),] <- NULL
maths.assessment.data$WEIGHTED_MARK <- maths.assessment.data$WEIGHTING * maths.assessment.data$MARK_PERCENTAGE
maths.coursemarks <- maths.assessment.data[grepl("12|11",maths.assessment.data$FORM_RUN),] %>%
  group_by(STUDENT_NUMBER, STUDENT_FIRSTNAME, STUDENT_SURNAME, FORM_RUN, COURSE) %>%
  summarise(COURSE_MARK = sum(WEIGHTED_MARK), TOTAL_WEIGHT = sum(WEIGHTING))
# Getting rid of non 100 weights and subsetting
maths.marks <- maths.coursemarks[maths.coursemarks$TOTAL_WEIGHT == 100,]
maths.marks$FORM_RUN <- gsub("201..Year\\s","",maths.marks$FORM_RUN)
maths.marks$COURSE <- gsub("Year .. ","", maths.marks$COURSE)
maths.marks$COURSE <- gsub("General 2", "General", maths.marks$COURSE)
# Spread based on course
maths.marks <- maths.marks %>% spread(key = FORM_RUN, value = COURSE_MARK)
fitm <- lm(`12` ~ `11` ,data = maths.marks)
g_mathsHSCprogress <- ggplot(data = maths.marks, 
                             aes(x = `11`, y = `12`, color = COURSE)) + 
  geom_point() + 
  geom_rug() +
  geom_smooth(inherit.aes = FALSE, aes(x = `11`, y = `12`), 
              color = 'black', 
              size = 0.2,
              method = "lm") +
  scale_x_continuous(limits = c(0,100)) + scale_y_continuous(limits = c(0,100)) +
  scale_colour_manual(values = wes_palette("Rushmore1")) +
  theme(panel.background = element_rect(fill = "white"),
        panel.grid.major = element_line(linetype = "dotted",
                                        size = 0.2, 
                                        colour = "light gray")) +
  ggtitle("HSC Mathematics: Year 11 v Year 12 Marks")