
##### prep #####

library(rvest)
library(fuzzyjoin)
rm(list = ls())
'%ni%' = Negate('%in%')
setwd("C:/Users/jmart/OneDrive/Desktop/GitHub/econ-journal-rankings/data")

##### webscrape REPEC journal ranking lists (12) #####

# set up
typez <- c("simple", "recurse", "discount", "rdiscount", "hindex", "euclid")
typez <- c(paste0(typez, "10"), typez)
y <- list()

# loop 12 times; store ratings
for(i in 1:length(typez)){
  paste0("https://ideas.repec.org/top/top.journals.", typez[i] ,".html") %>%
    read_html() %>%
    html_table() -> x
  x <- as.data.frame(x[[2]])
  colnames(x) <- x[1,]
  x <- x[-1,]
  x <- data.frame(
    journal = x[,2],
    rating = log(as.numeric(x[,3]) + 0.001)
  )
  x[,2] <- (x[,2] - mean(x[,2])) / sd(x[,2])
  x$type <- typez[i]
  
  y[[length(y)+1]] <- x
  
  Sys.sleep(5)
}
x <- as.data.frame(do.call(rbind, y))

##### calculate mean value of the journal rankings ####

x <- aggregate(rating ~ journal, x, mean, na.rm = T)
x <- x[order(-x$rating),]
x$rating <- round(x$rating, 2)

##### clean the journal titles ####

clean_journal <- function(title) {
  if (is.na(title)) return(NA)
  
  # Step 1: Remove all parentheticals
  title <- stringr::str_remove_all(title, "\\s*\\(.*?\\)")
  
  # Step 2: Split only on commas and trim whitespace
  parts <- strsplit(title, "\\s*,\\s*")[[1]]
  parts <- trimws(parts)
  
  # Step 3: Deduplicate exact matches (case-insensitive)
  parts <- parts[!duplicated(tolower(parts))]
  
  # Step 4: Remove last part if it looks like a publisher
  if (length(parts) > 1 && !grepl("\\b(and|&|Review|Journal)\\b", parts[length(parts)], ignore.case = TRUE)) {
    parts <- parts[-length(parts)]
  }
  
  # Step 5: Remove any parts (after the first) with publisher-like keywords
  keywords <- "\\b(Ltd|Limited|Association|University|Department|College|Institute|Center|Centre|Publish|Academy|Research|Springer|School|Organization)\\b"
  if (length(parts) > 1) {
    keep <- c(TRUE, !grepl(keywords, parts[-1], ignore.case = TRUE))
    parts <- parts[keep]
  }
  
  # Step 6: Return cleaned title (preserving colons)
  stringr::str_trim(paste(parts, collapse = ", "))
}
x$cleaned_journal <- sapply(x$journal, clean_journal)
x$cleaned_journal <- sapply(x$cleaned_journal, clean_journal)
x$cleaned_journal2 <- gsub("The ", "", x$cleaned_journal)

##### match in the Australian Business Deans Council Ratings ####

y <- openxlsx::read.xlsx("https://abdc.edu.au/wp-content/uploads/2023/05/ABDC-JQL-2022-v3-100523.xlsx")
colnames(y) <- y[2,]
y <- y[-1:-2,]
y$`2022 rating` <- trimws(y$`2022 rating`)
colnames(y)[1] <- "journal_title"
y$journal_title2 <- gsub("The ", "", y$journal_title)
y$journal_title2 <- sapply(y$journal_title2, clean_journal)

y$journal_title2 <- str_remove(y$journal_title2, "\\s*\\(.*?\\)")

matched <- stringdist_left_join(x, y,
                                by = c("cleaned_journal2" = "journal_title2"),
                                method = "jw", # Jaro-Winkler for short strings
                                max_dist = 0.1, # Adjust for strictness
                                distance_col = "dist")

matched_best <- matched %>%
  group_by(cleaned_journal2) %>%
  slice_min(order_by = dist, with_ties = TRUE) %>%
  ungroup()

x$abdc <- matched_best$`2022 rating`[match(x$cleaned_journal2, 
                                           matched_best$cleaned_journal2)]


##### save work #####

x <- data.frame(
  Full_Journal_Title = x$journal,
  Journal = x$cleaned_journal2,
  Rating = x$rating,
  ABDC = x$abdc
)

# saveRDS(x, "Journal Rankings.RDS")
