##### prep #####
library(rvest)
rm(list = ls())
'%ni%' = Negate('%in%')
setwd("C:/Users/jmart/OneDrive/Desktop/GitHub/econ-journal-rankings/code and data")

##### REPEC #####
typez = c("simple", "recurse", "discount", "rdiscount", "hindex", "euclid")

# scrape rankings by type
paste0("https://ideas.repec.org/top/top.journals.", typez[1] ,"10.html") %>%
  read_html() %>%
  html_table() -> x
x = as.data.frame(x[[2]])

# clean
colnames(x) = x[1,]
x = x[-1,]
x[,3:6] = apply(x[,3:6], 2, as.numeric)

# log standardize variable of interest
x$Factor = log(x$Factor + 1/100)
colnames(x)[ncol(x)] = typez[1]
y <- data.frame(
  Journal = x$Journal,
  Simple = x$simple
)

# repeat
for(i in 2:length(typez)){
  paste0("https://ideas.repec.org/top/top.journals.", typez[i] ,".html") %>%
    read_html() %>%
    html_table() -> x
  x = as.data.frame(x[[2]])
  
  # clean
  colnames(x) = x[1,]
  x = x[-1,]
  x[,3:6] = apply(x[,3:6], 2, as.numeric)
  
  # standardized variable of interest
  x$score = log(x$Factor + 1/100)
  colnames(x)[ncol(x)] = typez[i]
  
  # match in
  y$new = NA
  colnames(y)[ncol(y)] = typez[i]
  y[,ncol(y)] = x[match(y$Journal, x$Journal) ,ncol(x)]
}

##### clean up journal names #####
x <- y

# causing problems
badz = c("\\(R\\)", ", Cambridge Political Economy Society", "FinanzArchiv:",
         "Studia z Polityki Publicznej / ", 
         " for the Society for Economic Dynamics",
         "Logos Universalitate Mentalitate Educatie Noutate - Sectiunea Stiinte Politice si Studii Europene/ Logos Universality Mentality Education Novelty - Section:")
for(i in badz){
  x$Journal = gsub(i, "", x$Journal)
}
x$Journal = gsub("&", "and", x$Journal)

# get rid of () and ; in journal names
y = as.data.frame(do.call(rbind, strsplit(x$Journal, "\\(")))
x$Journal = y$V1
y = as.data.frame(do.call(rbind, strsplit(x$Journal, ";")))
x$Journal = y$V1

# clean up commas in journal names
y = as.data.frame(do.call(rbind, strsplit(x$Journal, ",")))
z = as.data.frame(table(y$V2))
z = z[z$Freq > 1,]
z = z[order(-z$Freq),]
for(i in 1:nrow(z)){
  x$Journal = gsub(paste0(",", z$Var1[i]), "", x$Journal)
}
termz = c("University", "College", "School", "Department", "Ltd.", "Center",
          "Program", "Institution", "Society", "Corporation", "Association",
          "Council", "Organization", "CEPR", "Universidade", "Foundation for",
          "Federal Reserve", "Bank for", "Borsa Istanbul", "Institute", "CEPR",
          "Stata", "Istituto", "Centre", "Platform", "Journal", "Mohr")
for(i in 1:length(termz)){
  y = as.data.frame(do.call(rbind, strsplit(x$Journal, ",")))
  if(termz[i] == "Society"){
    x$Journal = ifelse(grepl(termz[i], y$V2) & grepl("and Society", y$V2) == FALSE, 
                       y$V1, x$Journal)
  } else{
    x$Journal = ifelse(grepl(termz[i], y$V2), y$V1, x$Journal)
  }
}
y = as.data.frame(do.call(rbind, strsplit(x$Journal, ",")))
y = as.data.frame(apply(y, 2, trimws))
x$Journal = ifelse(y$V1 == y$V2, y$V1, x$Journal)
colnames(x) = c("Journal", "Simple", "Recurse", "Discount", "rDiscount",
                "hIndex", "Euclid")

# get rid of the first "The" in journal titles
x$Journal = sub("^the ", "", x$Journal, ignore.case = TRUE)

# trim white space
x$Journal = trimws(x$Journal)

##### ADBC #####
y = openxlsx::read.xlsx("https://abdc.edu.au/wp-content/uploads/2023/05/ABDC-JQL-2022-v3-100523.xlsx")
colnames(y) = y[2,]
y = y[-1:-2,]
y$`2022 rating` = trimws(y$`2022 rating`)
# y$ADBC = ifelse(y$`2022 rating` == "A*", 100,
#                   ifelse(y$`2022 rating` == "A", 90,
#                          ifelse(y$`2022 rating` == "B", 80, 70)))
# y$ADBC = log(y$ADBC)
y$ISSN = gsub("\t", "", y$ISSN)
y$`ISSN Online` = gsub("\t", "", y$`ISSN Online`)

###### SJR #####
z = read.csv("https://www.scimagojr.com/journalrank.php?out=xls", sep = ";")
# z$SJR = as.numeric(gsub(",", "", z$SJR))
# z = z[!is.na(z$SJR),]
# z$SJR = log(z$SJR + 1/100)
# z$H.index = log(z$H.index + 1/100)
z1 = as.data.frame(do.call(rbind, strsplit(z$Issn, ", ")))
z1 = z1[,1:2]
for(i in 1:2){
  z1[,i] = trimws(z1[,i])
  z1[,i] = paste(substring(z1[,i], 1, 4), substring(z1[,i], 5), sep = "-")
}
z1$journal = z$Title

##### SJR -> ABDC #####
# numz = c(3, 6, 8)
numz = 3
for(i in numz){
  y = cbind(y, NA)
  colnames(y)[ncol(y)] = colnames(z)[i]
  y[,ncol(y)] = z[match(y$ISSN, z1$V1), i]
  
  y[,ncol(y)] = ifelse(is.na(y[,ncol(y)]), z[match(y$ISSN, z1$V2), i], 
                       y[,ncol(y)])
  
  y[,ncol(y)] = ifelse(is.na(y[,ncol(y)]), z[match(y$`ISSN Online`, z1$V2), i], 
                       y[,ncol(y)])
  
  y[,ncol(y)] = ifelse(is.na(y[,ncol(y)]), z[match(y$`ISSN Online`, z1$V2), i], 
                       y[,ncol(y)])
}

##### IF #####
setwd("C:/Users/jmart/OneDrive/Desktop/GitHub/econ-journal-rankings/code and data")
j = openxlsx::read.xlsx("JCR-Impact-Factor-Journals-2022.xlsx")
j$IF_2022 = as.numeric(j$IF_2022)
j$IF_2022 = log(j$IF_2022 + 1/100)

##### IF -> ABDC #####
y$Journal.Name = j$Journal.Name[match(y$ISSN, j$ISSN)]
y$Journal.Name = ifelse(is.na(y$Journal.Name), 
                        j$Journal.Name[match(y$`ISSN Online`, j$ISSN)],
                        y$Journal.Name)
y$Journal.Name = ifelse(is.na(y$Journal.Name), 
                        j$Journal.Name[match(y$ISSN, j$EISSN)],
                        y$Journal.Name)
y$Journal.Name = ifelse(is.na(y$Journal.Name), 
                        j$Journal.Name[match(y$`ISSN Online`, j$EISSN)],
                        y$Journal.Name)
y$Journal.Name = ifelse(is.na(y$Journal.Name), 
                        j$Journal.Name[match(tolower(y$`Journal Title`), tolower(j$Journal.Name))],
                        y$Journal.Name)
y$Journal.Name = ifelse(is.na(y$Journal.Name), 
                        j$Journal.Name[match(tolower(y$Title), tolower(j$Journal.Name))],
                        y$Journal.Name)
y$IF = j$IF_2022[match(y$Journal.Name, j$Journal.Name)]

##### ABDC -> main df #####
# numz = c(8, 10, 11)
numz = c(10, 7)
for(i in numz){
  x = cbind(x, NA)
  colnames(x)[ncol(x)] = colnames(y)[i]
  x[,ncol(x)] = y[match(tolower(x$Journal), tolower(y$`Journal Title`)), i]
  x[,ncol(x)] = ifelse(is.na(x[,ncol(x)]), 
                       y[match(tolower(x$Journal), tolower(y$Title)), i],
                       x[,ncol(x)])
  x[,ncol(x)] = ifelse(is.na(x[,ncol(x)]), 
                       y[match(tolower(x$Journal), tolower(y$Title)), i],
                       x[,ncol(x)])
}
x$`2022 rating` = ifelse(x$`2022 rating` == "A*", "A",
                         ifelse(x$`2022 rating` == "A", "B",
                                ifelse(x$`2022 rating` == "B", "C", "D")))
colnames(x)[9] = "ADBC"

##### missingness #####
z = data.frame(
  column = names(x),
  missing_count = colSums(is.na(x))
)
z = z[z$missing_count > 0,]
z = z[z$column != "ADBC",]
z = z[order(z$missing_count),]

for(i in 1:nrow(z)){
  y = data.frame(
    rows = 1:nrow(x),
    var = x[,colnames(x) %in% z$column[i]]
  )
  numz = y$rows[is.na(y$var)]
  y = x[numz,]
  z1 = data.frame(
    column = names(y),
    missing_count = colSums(is.na(y))
  )
  z1 = z1$column[z1$missing_count == 0]
  z1 = z1[-which(z1 == "Journal")]
  y = x[,colnames(x) %in% z1]
  y = cbind(x[,colnames(x) == z$column[i]], y)
  colnames(y)[1] = z$column[i]
  
  numz = is.na(x[,colnames(x) == z$column[i]])
  lm1 = lm(y[!numz, 1] ~ ., y[!numz, 2:ncol(y)])
  x[numz ,colnames(x) == z$column[i]] = predict(lm1, newdata = y[numz,])
}

##### index #####

for(i in 2:(ncol(x)-1)){
  x[,i] = (x[,i] - mean(x[,i]))/sd(x[,i])
}
x$Overall = apply(x[2:(ncol(x)-1)], 1, mean)
x$Overall = (x$Overall - mean(x$Overall))/sd(x$Overall)
numz = c(2:(ncol(x)-2), ncol(x))
for(i in numz){
  x[,i] = round(x[,i], 2)
}
x = x[order(-x$Overall),]

# saveRDS(x, "Journal Rankings.RDS")
