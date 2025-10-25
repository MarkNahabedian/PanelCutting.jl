export scrape_midwest_procucts

const MIDWEST_PRODUCTS_SUPPLIER_FILE =
    joinpath( @__DIR__, "MidwestProducts.json")

MIDWEST_PRODUCTS_URL_BASE = "https://midwest-products.myshopify.com"

# ISSUES:

#  There wre multiple pages.  There are page number buttons and next
#  and previous buttons at the bottom of the page but they all use the
#  same URL.  I don't see how it knows which page to show.

#  We're not getting all of the items from a page.  20 are displayed
#  in the browser but only 6 are scraped.  Some of the items are not
#  sheets but are blocks or glue.

#  Some items include multiple sheets.  Sheet count isn't available on
#  this page.

MIDWEST_PRODUCT_ITEMS = []

#=
include("generic.jl")

scrape_midwest_procucts()
=#

# An object that encapsulates the web pages and mediates data extraction.
# It''s handy to have the fetched pages available for testing and debugging.
mutable struct MidwestProductsItemElt
    # the page for this specific item:
    item_doc_href::URI
    item_doc::Gumbo.HTMLDocument
    # extracted values
    extracted

    MidwestProductsItemElt(item_doc_href::URI, item_doc::Gumbo.HTMLDocument) =
        new(item_doc_href, item_doc, Dict{Symbol, Any}())

    MidwestProductsItemElt(item_doc_href::String, item_doc::Gumbo.HTMLDocument) =
        MidwestProductsItemElt(URI(item_doc_href), item_doc)
end


############################################################
# Data extraction:

function extract_label(item::MidwestProductsItemElt)
    selector = Cascadia.Selector(join(["""[itemtype="http://schema.org/Product"]""",
                                       """[itemprop="name"]"""
                                       ], " "))
    elts = eachmatch(selector, item.item_doc.root)
    println(elts)
    if length(elts) != 1
        return false
    end
    item.extracted[:label] = Gumbo.text(elts[1])
    true
end

function extract_material(item::MidwestProductsItemElt)
end

# document.querySelectorAll('[itemtype="http://schema.org/Product"] [itemtype="http://schema.org/Offer"]')
function extract_price(item::MidwestProductsItemElt)
    offer_selector = Cascadia.Selector(join(["""[itemtype="http://schema.org/Product"]""",
                                             """[itemtype="http://schema.org/Offer"]"""
                                             ], " "))
    for offer in eachmatch(offer_selector, item.item_doc.root)
        currency_selector = Cascadia.Selector("""meta[itemprop="priceCurrency"]""")
        price_selector = Cascadia.Selector("""meta[itemprop="price"]""")
        currency_elts = eachmatch(currency_selector, offer)
        price_elts = eachmatch(price_selector, offer)
        if length(currency_elts) == 1 && length(price_elts) == 1
            item.extracted[:currency] = Gumbo.getattr(only(currency_elts), "content")
            item.extracted[:price] = parse(Float64, Gumbo.getattr(only(price_elts), "content"))
            return true
        end
    end
    return false
end

function extract_count(item::MidwestProductsItemElt)
    selector = Cascadia.Selector(join(["""[itemtype="http://schema.org/Product"]""",
                                       """[itemprop="description"] p"""
                                       ], " "))
    for p in eachmatch(selector, item.item_doc.root)
        m = match(r"(?<count>[0-9]+) piece", Gumbo.text(p))
        if !isa(m, RegexMatch)
            continue
        end
        item.extracted[:count] = parse(Int, m["count"])
        return true
    end
    return false
end

function extract_dimensions(item::MidwestProductsItemElt)
    selector = Cascadia.Selector(join(["""[itemtype="http://schema.org/Product"]""",
                                       """[itemprop="description"] p"""
                                       ], " "))
    for p in eachmatch(selector, item.item_doc.root)
        m = match(r"(?<thickness>[0-9/]+)\" x (?<width>[0-9]+)\" x (?<length>[0-9]+)\"",
                  Gumbo.text(p))
        if !isa(m, RegexMatch)
            continue
        end
        item.extracted[:thickness] = parse(Rational{Int}, m["thickness"]) * u"inch"
        item.extracted[:width] = parse(Int, m["width"]) * u"inch"
        item.extracted[:length] = parse(Int, m["length"]) * u"inch"  
        return true
    end
    return false
end

function makeAvailablePanel(item::MidwestProductsItemElt)
    AvailablePanel(
        label = item.extracted[:label],
	thickness =  item.extracted[:thickness],
        length = item.extracted[:width],
        width = item.extracted[:length],
        material = "Basswood",
        cost = item.extracted[:price] / item.extracted[:count])
end

function scrape_midwest_procucts()
    available = AvailablePanel[]
    item_selector = Cascadia.Selector("div.grid-item.search-result a")
    with_webdriver_session(FirefoxGeckodriverSession()) do session
        # First collect the URLs for each product page from the
        # catalog pages:
        item_pages = []
        page_number = 1
        any_items = true
        while any_items
            println("page $page_number.")
            catalog_page = fetch_page(session,
                                      join([MIDWEST_PRODUCTS_URL_BASE,
                                            "search?type=product&q=basswood&page=$page_number"],
                                           "/"))
            any_items = false
            for item_elt in eachmatch(item_selector, catalog_page.root)
                any_items = true
                href = Gumbo.getattr(item_elt, "href")
                href = resolvereference(MIDWEST_PRODUCTS_URL_BASE, href)
                println("PRODUCT HREF $href")
                push!(item_pages, href)
            end
            page_number += 1
        end
        println("$(length(item_pages)) product hrefs.")
        for href in item_pages
            item_page = fetch_page(session, href)
            item = MidwestProductsItemElt(href, item_page)
            push!(MIDWEST_PRODUCT_ITEMS, item)
            try
                if !(extract_label(item) &&
                    extract_price(item) &&
                    extract_count(item) &&
                    extract_dimensions(item))
                    continue
                end
            catch e
                @error e
                @info catch_backtrace()
                continue
            end
            push!(available, makeAvailablePanel(item))
        end
    end
    available = sort(available; lt = panel_dimensions_isless)
    supplier = Supplier(
        name = "Midwest Products",
        kerf = 0.036u"inch",      # the measured set of my Japanese pull saw
        cost_per_cut = 1,         # made up.
        available_stock = available)
    open(MIDWEST_PRODUCTS_SUPPLIER_FILE, "w") do io
        write(io, JSON.json(supplier; pretty=4))
    end
    MIDWEST_PRODUCTS_SUPPLIER_FILE
end

# JSON.parsefile(MIDWEST_PRODUCTS_SUPPLIER_FILE, Supplier)

