# Econ Journal Rankings

I created an interactive [shiny](https://shiny.posit.co/) app using R to determine what journals to send econ papers. You can find the app at [https://joshua-c-martin.shinyapps.io/EconJournalRankings/](https://joshua-c-martin.shinyapps.io/EconJournalRankings/) or the source code for web scraping the data and for the calculations [here](https://github.com/joshmartinecon/econ-journal-rankings/tree/main/journal%20rankings%20webscrape.R).

## Functionality

There are two primary types of interactivity: filtering and sorting. One can filter by the name of journal both in what names to include and exclude. The filtering it case insensitive. Commas must be added if one wishes to filter by multiple topics.  Additionally, one can filter based on the "overall score" (whose calculation is discussed further below).

For instance, if one were looking for a place to send a really cool paper investigating the [impact of basketball All Star "Magic" Johnson's disclosure of his HIV+ status on subsequent AIDS diagnoses and longevity of heterosexual men](https://doi.org/10.1002/hec.4712), one might type "Health, Sport" in the inclusion search bar given the subject material while typing "Europe, Transport" in the exclusion search bar as the setting of the paper is in the United States while "Sport" will bring in transportation journals.

## Data 

Data comes from two sources: [IDEAS/RePEc](https://ideas.repec.org/) impact ratings ([Simple](https://ideas.repec.org/top/top.journals.simple10.html), [Recursive](https://ideas.repec.org/top/top.series.recurse10.html), [Discount](https://ideas.repec.org/top/top.series.discount10.html), [Recursive Discount](https://ideas.repec.org/top/top.series.rdiscount10.html), [H-Index](https://ideas.repec.org/top/top.series.hindex10.html),
and [Euclian](https://ideas.repec.org/top/top.series.euclid10.html, measured both all time and the past 10 years)) and the [Australian Business Deans Counsel Journal Quality List](https://abdc.edu.au/abdc-journal-quality-list/).

## Methods

There are 12 primary data sources used to construct the journal ratings, all obtained from [IDEAS/RePEc](https://ideas.repec.org/). For each journal $j$, I standardize its score on each impact metric $m$ by converting the original value $y_{jm}$ to a z-score:

$$z_{jm} = \dfrac{y_{jm} - \bar{y_m}}{\sigma_m}$$

I then compute an overall impact score $i_j$ for each journal by taking the average of its z-scores across the $n$metrics in which it appears:

$$i_j = \dfrac{1}{n_j} \sum_{m=1}^{n_j} z_{jm}$$

where $n_j$ is the number of metrics for which journal $j$ has available data.
