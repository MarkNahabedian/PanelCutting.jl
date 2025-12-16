# Scraping for Supplier Products

This directory contaiins code for scraping `AvailablePanel`s from the
web sites of those who provide them.  Each scraper is customized for a
specific supplier.

The only one implemented so far is for Miswest Products.

## How to Scrape

```
julia --project

include("generic.jl")

scrape_midwest_procucts()
```

