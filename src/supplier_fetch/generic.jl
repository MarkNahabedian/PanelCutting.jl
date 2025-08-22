using URIs
using HTTP
using Unitful
using UnitfulUS
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

function panel_dimensions_isless(p1, p2)
    field_ordering = (:thickness, :width, :length)
    function compare(fieldnum)
        if fieldnum > length(field_ordering)
            return false
        end
        field = field_ordering[fieldnum]
        c = cmp(getfield(p1, field), getfield(p2, field))
        @info("compare field", field, p1=getfield(p1, field), p2=getfield(p2, field))
        if c < 0
            return true
        end
        if c > 0
            return false
        end
        return compare(fieldnum + 1)
    end
    compare(1)
end


include("midwest_products.jl")

