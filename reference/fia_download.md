# Download zip files from FIA datamart

The zip files are smaller than just the \*\_TREE.csv, so this just
downloads the whole zip and extracts the required CSV files. Uses
[`curl::multi_download()`](https://jeroen.r-universe.dev/curl/reference/multi_download.html)
which resumes partial skips already completed downloads when run
subsequent times.

## Usage

``` r
fia_download(
  states,
  download_dir = "fia",
  extract = c("forestTIME", "rFIA", "all", "none"),
  keep_zip = TRUE
)
```

## Arguments

- states:

  Vector of state abbreviations; for all states use `state.abb`.

- download_dir:

  Where to save the zip files.

- extract:

  Which files to extract from the downloaded zip file—those needed by
  `forestTIME`, those needed by `rFIA` (in addition to all the tables
  `forestTIME` needs), all the files, or none.

- keep_zip:

  Logical; keep the .zip file after CSVs are extracted? Defaults to
  `TRUE`.

## Value

Returns nothing.

## Examples

``` r
if (FALSE) { # \dontrun{
# "Standard" download
fia_download(states = c("RI", "DE"))

# Extract enough tables so it works with rFIA::readFIA() also
fia_download(states = c("RI", "DE"), extract = "rFIA")
} # }
```
