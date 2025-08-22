using URIs
using HTTP
import Cascadia
import Gumbo

function fetch_and_parse(url::String)
    resp = HTTP.request(:GET, MIDWEST_PRODUCTS_URL;
                            detect_content_type=true)
    if resp.status != 200
        # give up
        error("Failed to fetch web page",
              url=MIDWEST_PRODUCTS_URL,
              resp)
    end
    if HTTP.header(resp, "Content-Type") != "text/html; charset=utf-8"
        error("Unrecognozed Content-Type", resp)
    end
    Gumbo.parsehtml(String(resp.body))
end

include("midwest_products.jl")

