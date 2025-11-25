# Read in needed tables

Wrapper for
[rFIA::readFIA](https://www.doserlab.com/files/rFIA/reference/readFIA.html)
that reads in the necessary tables

## Usage

``` r
fia_load(states, dir = "fia")
```

## Arguments

- states:

  character; state/ US territory abbreviations (e.g. 'AL', 'MI', etc.)
  indicating which state subsets to read. Data for each state must be in
  `dir`. Choose to read multiple states by passing character vector of
  state abbreviations (e.g. `states = c('RI', 'CT', 'MA')`). If
  `states = NULL`, data for all states within `dir` will be read in and
  merged into a regional database.

- dir:

  directory where .csv files of FIA tables are stored.

## Value

a list of data frames
