
MIDWEST_PRODUCTS_URL = "https://midwest-products.myshopify.com/search?type=product&q=basswood"

function scrape_midwest_products(doc::Gumbo.HTMLDocument)
    item_selector = Cascadia.Selector("div.grid-item.search-result a")
    # "1/16 x 1 x 24 Basswood Sheets-SKU 4102"
    item_regexp = r"(?<thick>[0-9/]+) x (?<width>[0-9]+) x (?<length>[0-9]+) Basswood Sheet[s]?-SKU (?<SKU>[0-9]+)"
    available = AvailablePanel[]
    for item_elt in eachmatch(item_selector, doc.root)
        item_p = eachmatch(Cascadia.Selector("p"), item_elt)
        if length(item_p) < 1
            continue
        end
        item_p = only(item_p)
        item_desc = Gumbo.text(item_p)
        m = match(item_regexp, item_desc)
        if m isa Nothing
            continue
        end
        price = join(map(Gumbo.text,
                         eachmatch(Cascadia.Selector("div.product-item--price span"),
                                   item_elt)),
                     "|")
        push!(available,
              AvailablePanel(
                  label = item_desc,       
	          thickness = parse(Rational{Int}, m["thick"]) * u"inch",
                  length = parse(Int, m["length"]) * u"inch",
                  width = parse(Int, m["width"]) * u"inch",
                  material = "Basswood",
                  cost = 10))
    end
    Supplier(
        name = "Midwest Products",
        kerf = 0.036u"inch",    # the measured set of my Japanese pull saw
        cost_per_cut = 1,         # made up.
        available_stock = available
    )
end


#=
supplier = Supplier(
    name = "www.midwestproducts.com",
    kerf = 0.036u"inch",    # the measured set of my Japanese pull saw
    cost_per_cut=0.10,
    available_stock = [
	AvailablePanel(
	    label = """Basswood Sheets - 15 Pieces, 1/32" x 3" x 24" 33300-2003""",
	    thickness = (1/32) * u"inch",
	    length = 24u"inch",
	    width = 3u"inch",
	    cost = 29.02 / 15   # Price for 15 sheets
	),
        AvailablePanel(
            label = """Basswood Sheets - 15 Pieces, 1/32" x 4" x 24" 33300-2004""",
	    thickness = (1/32) * u"inch",
            length = 24u"inch",
            width = 4u"inch",
	    cost = 45.45 / 15   # Price for 15 sheets
        ),
        AvailablePanel(
            label = """Basswood Sheet - 10 Sheets, 1/32" x 6" x 36" 33300-7506""",
            thickness = (1/32) * u"inch",
            length = 36u"inch",
            width = 6u"inch",
            cost = 67.01 / 10   # Price for 10 sheets
        ),
        AvailablePanel(
            label = """15 Pieces, 1/16" x 1" x 24" 33300-2001""",
            thickness = (1/16) * u"inch",
            length = 24u"inch",
            width = 1u"inch",
            cost = 21.72 / 15   # Price for 15 sheets
        ),
    ])
=#

#=
Item Description Thickness Width Length Price


Midwest Products Basswood Sheets - 10 Pieces, 1/16" x 3" x 24"
33300-8161
Basswood, 10 Sheets
1/16"
3"
24"

20.52
16.20

California Proposition 65MSDSItems which include this icon have MSDS sheets available for download.
In stock online



Midwest Products Genuine Basswood Sheet - 20 Sheets, 1/16" x 3" x 36"
33300-7303
Basswood, 20 Sheets
1/16"
3"
36"
64.92

Or notify me when in stock
California Proposition 65WARNING: Drilling, sawing, sanding or machining wood products can expose you to wood dust, a substance known to the State of California to cause cancer. Avoid inhaling wood dust or use a dust mask or other safeguards for personal protection. For more information go to--www.P65Warnings.ca.gov




Midwest Products Basswood Sheets - 10 Pieces, 1/16" x 4" x 24"
33300-2601
Basswood, 10 Sheets
1/16"
4"
24"

30.32
23.94

California Proposition 65MSDSItems which include this icon have MSDS sheets available for download.
In stock online



Midwest Products Genuine Basswood Sheet -10 Sheets, 1/16" x 4" x 36"
33300-7304
Basswood,10 Sheets
1/16"
4"
36"

45.34
35.79

California Proposition 65WARNING: Drilling, sawing, sanding or machining wood products can expose you to wood dust, a substance known to the State of California to cause cancer. Avoid inhaling wood dust or use a dust mask or other safeguards for personal protection. For more information go to--www.P65Warnings.ca.gov
In stock online



Midwest Products Genuine Basswood Sheets - 1/16" x 6" x 24", 10 Pieces
33300-2530
Basswood, 10 Sheets
1/16"
6"
24"

78.98
62.35


In stock online



Midwest Products Genuine Basswood Sheet - 10 Sheets, 1/16" x 6" x 36"
33300-7306
Basswood, 10 Sheets
1/16"
6"
36"

84.47
66.68

California Proposition 65WARNING: Drilling, sawing, sanding or machining wood products can expose you to wood dust, a substance known to the State of California to cause cancer. Avoid inhaling wood dust or use a dust mask or other safeguards for personal protection. For more information go to--www.P65Warnings.ca.gov
In stock online



Midwest Products Genuine Basswood Sheets - 1/16" x 8" x 24", 10 Pieces
33300-1101
Basswood, 10 Sheets
1/16"
8"
24"

88.72
70.04


In stock online



Midwest Products Basswood Sheets - 10 Pieces, 3/32" x 3" x 24"
33300-8331
Basswood, 10 Sheets
3/32"
3"
24"

23.03
18.18

California Proposition 65MSDSItems which include this icon have MSDS sheets available for download.
In stock online



Midwest Products Genuine Basswood Sheet - 20 Sheets, 3/32" x 3" x 36"
33300-7203
Basswood, 20 Sheets
3/32"
3"
36"
87.72


In stock online



Midwest Products Basswood Sheets - 10 Pieces, 3/32" x 4" x 24"
33300-4011
Basswood, 10 Sheets
3/32"
4"
24"

32.72
25.83

California Proposition 65MSDSItems which include this icon have MSDS sheets available for download.
In stock online



Midwest Products Genuine Basswood Sheet - 5 Sheets, 3/32" x 4" x 36"
33300-7204
Basswood, 5 Sheets
3/32"
4"
36"
28.27


In stock online



Midwest Products Genuine Basswood Sheets - 3/32" x 6" x 24", 10 Pieces
33300-2540
Basswood, 10 Sheets
3/32"
6"
24"

85.06
67.15


In stock online



Midwest Products Genuine Basswood Sheet - 10 Sheets, 3/32" x 6" x 36"
33300-7206
Basswood, 10 Sheets
3/32"
6"
36"

88.81
70.11


In stock online



Midwest Products Genuine Basswood Sheets - 3/32" x 8" x 24", 10 pieces
33300-1102
Basswood, 10 Sheets
3/32"
8"
24"

96.02
75.80


In stock online



Midwest Products Basswood Sheets - 15 Pieces, 1/8" x 1" x 24"
33300-4001
Basswood, 15 Sheets
1/8"
1"
24"
30.85


In stock online



Midwest Products Genuine Basswood Sheets - 1/8" x 2" x 24", 15 Pieces
33300-9802
Basswood, 15 Sheets
1/8"
2"
24"
32.68


In stock online



Midwest Products Basswood Sheets - 10 Pieces, 1/8" x 3" x 24"
33300-8171
Basswood, 10 Sheets
1/8"
3"
24"

26.68
21.06

California Proposition 65MSDSItems which include this icon have MSDS sheets available for download.
In stock online



Midwest Products Genuine Basswood Sheets - 1/8" x 3" x 36", 10 Pieces
33300-5103
Basswood Sheets, 10 Pieces
1/8"
3"
36"

41.02
32.38

California Proposition 65
In stock online



Midwest Products Basswood Sheets - 10 Pieces, 1/8" x 4" x 24"
33300-5011
Basswood, 10 Sheets
1/8"
4"
24"

36.37
28.71

California Proposition 65MSDSItems which include this icon have MSDS sheets available for download.
In stock online



Midwest Products Genuine Basswood Sheet - 5 Sheets, 1/8" x 4" x 36"
33300-7804
Basswood, 5 Sheets
1/8"
4"
36"
25.48


In stock online



Midwest Products Genuine Basswood Sheets - 1/8" x 6" x 24", 10 Pieces
33300-2550
Basswood, 10 Sheets
1/8"
6"
24"

97.23
76.76


In stock online



Midwest Products Genuine Basswood Sheet - 10 Sheets, 1/8" x 6" x 36"
33300-7806
Basswood, 10 Sheets
1/8"
6"
36"

103.97
82.08


In stock online



Midwest Products Genuine Basswood Sheets, 1/8" x 8" x 24", 10 pieces
33300-1103
Basswood, 10 Sheets
1/8"
8"
24"

109.40
86.36


In stock online



Midwest Products Basswood Sheets - 10 Pieces, 3/16" x 1" x 24"
33300-5001
Basswood, 10 Sheets
3/16"
1"
24"

24.22
19.12


In stock online



Midwest Products Basswood Sheets - 5 Pieces, 3/16" x 3" x 24"
33300-8380
Basswood, 5 Sheets
3/16"
3"
24"
15.23

California Proposition 65MSDSItems which include this icon have MSDS sheets available for download.
In stock online



Midwest Products Basswood Sheets - 5 Pieces, 3/16" x 4" x 24"
33300-8390
Basswood, 5 Sheets
3/16"
4"
24"
19.80

California Proposition 65MSDSItems which include this icon have MSDS sheets available for download.
In stock online



Midwest Products Genuine Basswood Sheet - 5 Sheets, 3/16" x 4" x 36"
33300-7604
Basswood, 5 Sheets
3/16"
4"
36"
33.94


In stock online



Midwest Products Genuine Basswood Sheets - 3/16" x 6" x 24", 5 Pieces
33300-2560
Basswood, 5 Sheets
3/16"
6"
24"
48.11


In stock online



Midwest Products Genuine Basswood Sheet - 5 Sheets, 3/16" x 6" x 36"
33300-7606
Basswood, 5 Sheets
3/16"
6"
36"
50.42


In stock online



Midwest Products Basswood Sheets - 10 Pieces, 1/4" x 1" x 24"
33300-6001
Basswood, 10 Sheets
1/4"
1"
24"

27.87
22.00


In stock online



Midwest Products Basswood Sheets - 5 Pieces, 1/4" x 3" x 24"
33300-8150
Basswood, 5 Sheets
1/4"
3"
24"
18.10

California Proposition 65MSDSItems which include this icon have MSDS sheets available for download.
In stock online



Midwest Products Genuine Basswood Sheet -10 Sheets, 1/4" x 3" x 36"
33300-7103
Basswood, 10 Sheets
1/4"
3"
36"

62.64
49.45

Or notify me when in stock





Midwest Products Basswood Sheets - 5 Pieces, 1/4" x 4" x 24"
33300-3010
Basswood, 5 Sheets
1/4"
4"
24"
26.01

California Proposition 65MSDSItems which include this icon have MSDS sheets available for download.
In stock online



Midwest Products Genuine Basswood Sheet - 5 Sheets, 1/4" x 4" x 36"
33300-7104
Basswood, 5 Sheets
1/4"
4"
36"
37.10

Or notify me when in stock





Midwest Products Genuine Basswood Sheets - 1/4" x 6" x 24", 5 Pieces
33300-2570
Basswood, 5 Sheets
1/4"
6"
24"
56.61

Or notify me when in stock





Midwest Products Genuine Basswood Sheet - 5 Sheets, 1/4" x 6" x 36"
33300-7106
Basswood, 5 Sheets
1/4"
6"
36"
60.51


In stock online



Midwest Products Genuine Basswood Sheets - 1/4" x 8" x 24", 5 Pieces
33300-1105
Basswood, 5 Sheets
1/4"
8"
24"
63.97


In stock online



Midwest Products Basswood Sheets - 5 Pieces, 3/8" x 3" x 24"
33300-8003
Basswood, 5 Sheets
3/8"
3"
24"
24.87


In stock online



Midwest Products Basswood Sheets - 5 Pieces, 1/2" x 3" x 24"
33300-9003
Basswood, 5 Sheets
1/2"
3"
24"
35.64


In stock online



Reviews
Q & A
Related Products
You May Also Like
Americas best online shops plus best customer service. 2019-2025 Newsweek Powered by Statista
QUICK LINKS
My Account
My Orders
Gift Cards
My Lists
Find A Store
Store Pickup
Affiliate Program
Careers
About Blick
Join Our Email List
Custom Canvas — NEW
CUSTOMER SERVICE
General Help
Shipping Information
Sales Tax
Return Policy
Pricing Policy/FAQs
Donation Requests
Contact Us
Take Our Survey
RESOURCES
Product Information
Product Icon Key
Health & Safety
Paint Swatches
Product Reviews
Guides & How-Tos
Project Ideas
Request a Catalog
SCHOOL/BUSINESS
Shop School or Business
Quick Add to Cart
Bids, Quotes, Discounts
On-Account Ordering
Quick Quote
Blick U Course Supply Lists
Educator Resources
Lesson Plans
CONNECT WITH US





Security & Privacy - NEW
Notice at Collection
Your Privacy Choices
CA/Do Not Sell/Share My Personal Information
Discover
Visa
Mastercard
American Express
PayPal
Apple Pay
Gift card
$
check
This site is protected by VikingCloud's Trusted Commerce program
BLICK ART MATERIALS - P.O. BOX 1267 GALESBURG, IL 61402-1267
TOLL FREE PHONE (800) 828-4548 INTERNATIONAL PHONE +1-309-343-6181 EXT. 5402 FAX (800) 621-8293
CONNECT WITH US





Security & Privacy - NEWTerms of UseAccessibilityNotice at CollectionYour Privacy Choices
CA/Do Not Sell/Share My Personal InformationCA Supply Chain
Dick Blick Art Materials®, Blick®, Blick Studio®, And Artists Pick Blick® Are Registered Trademarks Of Blick Art Materials, LLC © Copyright 1999- 2025 Blick Art Materials, LLC All Rights Reserved.testingd20250820t134321

=#






#=

Midwest Products Genuine 
Basswood, 10 Sheets
1/32"
6"
36"

67.01
52.90


In stock online


Midwest Products Basswood Sheets - 15 Pieces, 1/16" x 1" x 24"
33300-2001
Basswood, 15 Sheets
1/16"
1"
24"
21.72


In stock online


Midwest Products Basswood Sheets - 10 Pieces, 1/16" x 3" x 24"
33300-8161
Basswood, 10 Sheets
1/16"
3"
24"

20.52
16.20

California Proposition 65MSDSItems which include this icon have MSDS sheets available for download.
In stock online


Midwest Products Genuine Basswood Sheet - 20 Sheets, 1/16" x 3" x 36"
33300-7303
Basswood, 20 Sheets
1/16"
3"
36"
64.92

Or notify me when in stock
California Proposition 65WARNING: Drilling, sawing, sanding or machining wood products can expose you to wood dust, a substance known to the State of California to cause cancer. Avoid inhaling wood dust or use a dust mask or other safeguards for personal protection. For more information go to--www.P65Warnings.ca.gov



Midwest Products Basswood Sheets - 10 Pieces, 1/16" x 4" x 24"
33300-2601
Basswood, 10 Sheets
1/16"
4"
24"

30.32
23.94

California Proposition 65MSDSItems which include this icon have MSDS sheets available for download.
In stock online


Midwest Products Genuine Basswood Sheet -10 Sheets, 1/16" x 4" x 36"
33300-7304
Basswood,10 Sheets
1/16"
4"
36"

45.34
35.79

California Proposition 65WARNING: Drilling, sawing, sanding or machining wood products can expose you to wood dust, a substance known to the State of California to cause cancer. Avoid inhaling wood dust or use a dust mask or other safeguards for personal protection. For more information go to--www.P65Warnings.ca.gov
In stock online


Midwest Products Genuine Basswood Sheets - 1/16" x 6" x 24", 10 Pieces
33300-2530
Basswood, 10 Sheets
1/16"
6"
24"

78.98
62.35


In stock online


Midwest Products Genuine Basswood Sheet - 10 Sheets, 1/16" x 6" x 36"
33300-7306
Basswood, 10 Sheets
1/16"
6"
36"

84.47
66.68

California Proposition 65WARNING: Drilling, sawing, sanding or machining wood products can expose you to wood dust, a substance known to the State of California to cause cancer. Avoid inhaling wood dust or use a dust mask or other safeguards for personal protection. For more information go to--www.P65Warnings.ca.gov
In stock online


Midwest Products Genuine Basswood Sheets - 1/16" x 8" x 24", 10 Pieces
33300-1101
Basswood, 10 Sheets
1/16"
8"
24"

88.72
70.04


In stock online


Midwest Products Basswood Sheets - 10 Pieces, 3/32" x 3" x 24"
33300-8331
Basswood, 10 Sheets
3/32"
3"
24"

23.03
18.18

California Proposition 65MSDSItems which include this icon have MSDS sheets available for download.
In stock online


Midwest Products Genuine Basswood Sheet - 20 Sheets, 3/32" x 3" x 36"
33300-7203
Basswood, 20 Sheets
3/32"
3"
36"
87.72


In stock online


Midwest Products Basswood Sheets - 10 Pieces, 3/32" x 4" x 24"
33300-4011
Basswood, 10 Sheets
3/32"
4"
24"

32.72
25.83

California Proposition 65MSDSItems which include this icon have MSDS sheets available for download.
In stock online


Midwest Products Genuine Basswood Sheet - 5 Sheets, 3/32" x 4" x 36"
33300-7204
Basswood, 5 Sheets
3/32"
4"
36"
28.27


In stock online


Midwest Products Genuine Basswood Sheets - 3/32" x 6" x 24", 10 Pieces
33300-2540
Basswood, 10 Sheets
3/32"
6"
24"

85.06
67.15


In stock online


Midwest Products Genuine Basswood Sheet - 10 Sheets, 3/32" x 6" x 36"
33300-7206
Basswood, 10 Sheets
3/32"
6"
36"

88.81
70.11


In stock online


Midwest Products Genuine Basswood Sheets - 3/32" x 8" x 24", 10 pieces
33300-1102
Basswood, 10 Sheets
3/32"
8"
24"

96.02
75.80


In stock online


Midwest Products Basswood Sheets - 15 Pieces, 1/8" x 1" x 24"
33300-4001
Basswood, 15 Sheets
1/8"
1"
24"
30.85


In stock online


Midwest Products Genuine Basswood Sheets - 1/8" x 2" x 24", 15 Pieces
33300-9802
Basswood, 15 Sheets
1/8"
2"
24"
32.68


In stock online


Midwest Products Basswood Sheets - 10 Pieces, 1/8" x 3" x 24"
33300-8171
Basswood, 10 Sheets
1/8"
3"
24"

26.68
21.06

California Proposition 65MSDSItems which include this icon have MSDS sheets available for download.
In stock online


Midwest Products Genuine Basswood Sheets - 1/8" x 3" x 36", 10 Pieces
33300-5103
Basswood Sheets, 10 Pieces
1/8"
3"
36"

41.02
32.38

California Proposition 65
In stock online


=#

        AvailablePanel(
            label="basswood 24 × 4 × 1/8",
            thickness = (1//8) * u"inch",
            length=24u"inch",
            width=4u"inch",
            cost=4)
#= 
Midwest Products Basswood Sheets - 10 Pieces, 1/8" x 4" x 24"
33300-5011
Basswood, 10 Sheets
1/8"
4"
24"

36.37
28.71

California Proposition 65MSDSItems which include this icon have MSDS sheets available for download.
In stock online


Midwest Products Genuine Basswood Sheet - 5 Sheets, 1/8" x 4" x 36"
33300-7804
Basswood, 5 Sheets
1/8"
4"
36"
25.48


In stock online


Midwest Products Genuine Basswood Sheets - 1/8" x 6" x 24", 10 Pieces
33300-2550
Basswood, 10 Sheets
1/8"
6"
24"

97.23
76.76


In stock online


Midwest Products Genuine Basswood Sheet - 10 Sheets, 1/8" x 6" x 36"
33300-7806
Basswood, 10 Sheets
1/8"
6"
36"

103.97
82.08


In stock online


Midwest Products Genuine Basswood Sheets, 1/8" x 8" x 24", 10 pieces
33300-1103
Basswood, 10 Sheets
1/8"
8"
24"

109.40
86.36


In stock online


Midwest Products Basswood Sheets - 10 Pieces, 3/16" x 1" x 24"
33300-5001
Basswood, 10 Sheets
3/16"
1"
24"

24.22
19.12


In stock online


Midwest Products Basswood Sheets - 5 Pieces, 3/16" x 3" x 24"
33300-8380
Basswood, 5 Sheets
3/16"
3"
24"
15.23

California Proposition 65MSDSItems which include this icon have MSDS sheets available for download.
In stock online


Midwest Products Basswood Sheets - 5 Pieces, 3/16" x 4" x 24"
33300-8390
Basswood, 5 Sheets
3/16"
4"
24"
19.80

California Proposition 65MSDSItems which include this icon have MSDS sheets available for download.
In stock online


Midwest Products Genuine Basswood Sheet - 5 Sheets, 3/16" x 4" x 36"
33300-7604
Basswood, 5 Sheets
3/16"
4"
36"
33.94


In stock online


Midwest Products Genuine Basswood Sheets - 3/16" x 6" x 24", 5 Pieces
33300-2560
Basswood, 5 Sheets
3/16"
6"
24"
48.11


In stock online


Midwest Products Genuine Basswood Sheet - 5 Sheets, 3/16" x 6" x 36"
33300-7606
Basswood, 5 Sheets
3/16"
6"
36"
50.42


In stock online


Midwest Products Basswood Sheets - 10 Pieces, 1/4" x 1" x 24"
33300-6001
Basswood, 10 Sheets
1/4"
1"
24"

27.87
22.00


In stock online


Midwest Products Basswood Sheets - 5 Pieces, 1/4" x 3" x 24"
33300-8150
Basswood, 5 Sheets
1/4"
3"
24"
18.10

California Proposition 65MSDSItems which include this icon have MSDS sheets available for download.
In stock online


Midwest Products Genuine Basswood Sheet -10 Sheets, 1/4" x 3" x 36"
33300-7103
Basswood, 10 Sheets
1/4"
3"
36"

62.64
49.45

Or notify me when in stock




Midwest Products Basswood Sheets - 5 Pieces, 1/4" x 4" x 24"
33300-3010
Basswood, 5 Sheets
1/4"
4"
24"
26.01

California Proposition 65MSDSItems which include this icon have MSDS sheets available for download.
In stock online


Midwest Products Genuine Basswood Sheet - 5 Sheets, 1/4" x 4" x 36"
33300-7104
Basswood, 5 Sheets
1/4"
4"
36"
37.10

Or notify me when in stock




Midwest Products Genuine Basswood Sheets - 1/4" x 6" x 24", 5 Pieces
33300-2570
Basswood, 5 Sheets
1/4"
6"
24"
56.61

Or notify me when in stock




Midwest Products Genuine Basswood Sheet - 5 Sheets, 1/4" x 6" x 36"
33300-7106
Basswood, 5 Sheets
1/4"
6"
36"
60.51


In stock online


Midwest Products Genuine Basswood Sheets - 1/4" x 8" x 24", 5 Pieces
33300-1105
Basswood, 5 Sheets
1/4"
8"
24"
63.97


In stock online


Midwest Products Basswood Sheets - 5 Pieces, 3/8" x 3" x 24"
33300-8003
Basswood, 5 Sheets
3/8"
3"
24"
24.87


In stock online


Midwest Products Basswood Sheets - 5 Pieces, 1/2" x 3" x 24"
33300-9003
Basswood, 5 Sheets
1/2"
3"
24"
35.64


In stock online




=#


