# When making a release, remember to increment the version in CITATION.cff to
# match that in DESCRIPTION!
# Update inst/CITATION from CITATION.cff
library(cffr)
cff <- cff_read("CITATION.cff")
cff_write_citation(cff, "inst/CITATION", what = "all")
