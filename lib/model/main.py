"""
MediCompare Backend — Reverse-Engineered Pharmacy APIs
=========================================================
Built directly from real DevTools Network-tab captures of hidden APIs.

THREE TIERS OF SITES:
  TIER 1 (instant, no setup): DVAGO, MeriPharmacy, MarhamPharmacy, HPharmacy,
      ChemistCart, MedSpot, Pillbox
      -> these APIs are open, just need correct headers (ChemistCart needs a
         nonce harvested from the homepage first, but no CSRF/session cookie)

  TIER 2 (warm-up required / session cookies needed): HealthWire, Sehat, D-Watson
      -> we GET the homepage first to harvest a fresh nonce/CSRF/session token,
         then call the real search API with that token. D-Watson additionally
         returned a cf_clearance cookie when captured — see TIER 3 note below,
         it may degrade over time without a real browser to refresh it.

  TIER 3 (Cloudflare-protected, needs Playwright): MedLife, MedicalStore
      -> these require a `cf_clearance` cookie which only a real browser can
         generate by solving Cloudflare's JS challenge. MedLife is wired up
         below using a captured cf_clearance cookie as a stopgap — it WILL
         eventually expire/rotate and the scraper will start failing again
         until replaced via Playwright in playwright_scrapers.py.

RUN:
  pip install -r requirements.txt
  uvicorn main:app --host 0.0.0.0 --port 8000

DEPLOY: Railway / Render — see SETUP_GUIDE.md
"""

import asyncio
import re
import json
from typing import Optional
import httpx
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="MediCompare Reverse-Engineered API", version="4.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

COMMON_HEADERS = {
    "user-agent": UA,
    "accept-language": "en-US,en;q=0.9",
}


def clean_price(raw) -> Optional[float]:
    """Extract a numeric PKR price from messy strings/numbers."""
    if raw is None:
        return None
    if isinstance(raw, (int, float)):
        return float(raw) if 1 < raw < 1_000_000 else None
    text = str(raw)
    digits = re.sub(r"[^\d.]", "", text)
    try:
        val = float(digits)
        return val if 1 < val < 1_000_000 else None
    except ValueError:
        return None


def strip_html(text: Optional[str]) -> Optional[str]:
    """Remove HTML tags and collapse whitespace from a fragment."""
    if not text:
        return None
    no_tags = re.sub(r"<[^>]+>", " ", text)
    return re.sub(r"\s+", " ", no_tags).strip()


def parse_currency_symbol_price(price_html: Optional[str]) -> Optional[float]:
    """
    Parse a WooCommerce-style price fragment using the &#8360; (₨) HTML
    entity as an anchor, e.g.:
        <span class="woocommerce-Price-currencySymbol">&#8360;</span>&nbsp;148
    Takes the LAST matching amount in the raw (un-stripped) HTML — when a
    sale is active, WooCommerce emits BOTH the original price (inside <del>)
    and the current price (inside <ins>) in that order, so the last match is
    always the actual current price. For a simple non-sale price there's
    only one match anyway. Must run on raw HTML, since stripping tags first
    destroys the &#8360; entity boundary we're anchoring on.
    """
    if not price_html:
        return None
    matches = re.findall(r'&#8360;\s*(?:</span>)?\s*(?:&nbsp;)?\s*([\d,]+(?:\.\d+)?)', price_html)
    return clean_price(matches[-1]) if matches else None


def empty_result(site: str, medicine: str, search_url: str) -> dict:
    return {
        "site": site,
        "product_name": medicine,
        "price": None,
        "product_url": None,
        "image_url": None,
        "search_url": search_url,
    }


# ════════════════════════════════════════════════════════════════════════════
# TIER 1 — OPEN APIs (no token needed)
# ════════════════════════════════════════════════════════════════════════════

async def scrape_dvago(client: httpx.AsyncClient, medicine: str) -> dict:
    """
    DVAGO custom REST API.
    REAL response shape (confirmed):
    {
      "Data": [
        {"Name": "Matching Searches", "Type": "Search", "Data": [...]},
        {"Name": "Matching Products", "Type": "Product", "Data": [
            {"id": "2780", "Slug": "...", "Title": "...", "ImageURL": "...",
             "SalePrice": "148", "DiscountPrice": "141", "AvailableQty": "54"}
        ]}
      ]
    }
    """
    site = "DVAGO"
    search_url = f"https://www.dvago.pk/catalogsearch/result/?q={medicine.replace(' ', '+')}"
    result = empty_result(site, medicine, search_url)

    api_url = (
        f"https://apidb.dvago.pk/AppAPIV3/SearchinginBox"
        f"&ProductName={medicine}&limit=0,20&BranchCode=32"
    )
    try:
        r = await client.get(
            api_url,
            headers={
                **COMMON_HEADERS,
                "accept": "application/json, text/plain, */*",
                "origin": "https://www.dvago.pk",
                "referer": "https://www.dvago.pk/",
            },
            timeout=10,
        )
        if r.status_code != 200:
            return result

        data = r.json()
        groups = data.get("Data", [])

        # Find the "Matching Products" group specifically (not "Matching Searches")
        products_group = next((g for g in groups if g.get("Type") == "Product"), None)
        if not products_group:
            return result

        items = products_group.get("Data", [])
        if not items:
            return result

        first = items[0]
        result["product_name"] = first.get("Title", medicine)
        # Prefer DiscountPrice (actual selling price) over SalePrice (list price)
        price = first.get("DiscountPrice") or first.get("SalePrice")
        result["price"] = clean_price(price)
        result["image_url"] = first.get("ImageURL")
        slug = first.get("Slug")
        if slug:
            result["product_url"] = f"https://www.dvago.pk/product/{slug}"

    except Exception as e:
        print(f"[{site}] Error: {e}")
    return result


async def scrape_meripharmacy(client: httpx.AsyncClient, medicine: str) -> dict:
    """
    MeriPharmacy — Shopify native search.
    REAL response shape (confirmed):
    {
      "products": [
        {
          "title": "<strong class=\"highlight\">PANADOL</strong> EXTRA TABLET 10X10S",
          "handle": "panadol-extra-tablet-10x10s",
          "price": {"price": 60000, ...},   <- price is in PAISA (÷100 for rupees)
          "image": "<img src=\"//meripharmacy.pk/cdn/shop/...\" ...>",
          "url": "/products/panadol-extra-tablet-10x10s?_pos=1..."
        }
      ]
    }
    """
    site = "MeriPharmacy"
    encoded = medicine.replace(" ", "+")
    search_url = f"https://meripharmacy.pk/search?q={encoded}&type=product"
    result = empty_result(site, medicine, search_url)

    api_url = f"https://meripharmacy.pk/search?q={encoded}*&type=article%2Cpage%2Cproduct&view=header"
    try:
        r = await client.get(
            api_url,
            headers={**COMMON_HEADERS, "accept": "application/json"},
            timeout=10,
        )
        if r.status_code != 200:
            return result

        data = r.json()
        products = data.get("products", [])
        if not products:
            return result

        first = products[0]

        # Strip HTML tags like <strong class="highlight"> from the title
        raw_title = first.get("title", medicine)
        result["product_name"] = re.sub(r"<[^>]+>", "", raw_title).strip()

        # Shopify prices are in paisa/cents — divide by 100
        price_obj = first.get("price", {})
        price_raw = price_obj.get("price")
        if price_raw is not None:
            result["price"] = clean_price(price_raw / 100)

        handle = first.get("handle")
        if handle:
            result["product_url"] = f"https://meripharmacy.pk/products/{handle}"

        # Extract src="..." from the <img> HTML string
        image_html = first.get("image", "")
        img_match = re.search(r'src="([^"]+)"', image_html)
        if img_match:
            src = img_match.group(1)
            result["image_url"] = f"https:{src}" if src.startswith("//") else src

    except Exception as e:
        print(f"[{site}] Error: {e}")
    return result


async def scrape_marhampharmacy(client: httpx.AsyncClient, medicine: str) -> dict:
    """
    MarhamPharmacy — WordPress/Woodmart AJAX search.
    REAL response shape (confirmed) — clean JSON, not HTML:
    {
      "suggestions": [
        {
          "value": "Panadol Paracetamol 500mg",
          "permalink": "https://www.marhampharmacy.pk/shop-now/panadol-paracetamol-500mg/",
          "price": "<span class=\"woocommerce-Price-amount amount\">...800.00...</span>",
          "thumbnail": "<img ... src=\"https://...430x323.jpg\" .../>"
        }
      ]
    }
    """
    site = "Marham Pharmacy"
    encoded = medicine.replace(" ", "+")
    search_url = f"https://www.marhampharmacy.pk/?s={encoded}&post_type=product"
    result = empty_result(site, medicine, search_url)

    api_url = (
        f"https://www.marhampharmacy.pk/wp-admin/admin-ajax.php"
        f"?action=woodmart_ajax_search&number=20&post_type=product&query={encoded}"
    )
    try:
        r = await client.get(
            api_url,
            headers={**COMMON_HEADERS, "x-requested-with": "XMLHttpRequest"},
            timeout=10,
        )
        if r.status_code != 200 or not r.text.strip():
            return result

        data = r.json()
        suggestions = data.get("suggestions", [])
        if not suggestions:
            return result

        first = suggestions[0]
        result["product_name"] = first.get("value", medicine)
        result["product_url"] = first.get("permalink")

        # Price is HTML like: <bdi><span>&#8360;</span>800.00</bdi>
        price_html = first.get("price", "")
        price_match = re.search(r'([\d,]+\.\d{2})', price_html)
        if price_match:
            result["price"] = clean_price(price_match.group(1))

        # Thumbnail is HTML like: <img ... src="https://...jpg" .../>
        thumb_html = first.get("thumbnail", "")
        img_match = re.search(r'src="([^"]+)"', thumb_html)
        if img_match:
            result["image_url"] = img_match.group(1)

    except Exception as e:
        print(f"[{site}] Error: {e}")
    return result


async def scrape_hpharmacy(client: httpx.AsyncClient, medicine: str) -> dict:
    """
    HPharmacy — WordPress custom AJAX search (POST, form-encoded).
    Captured: hpharmacy.pk/wp-admin/admin-ajax.php
              data: action=search_data_fetch&keyword=X&category=0
    REAL response shape (confirmed) — HTML fragment of repeated blocks:
      <div class="tmc-suggestion tmc-selectable">
        <div class="tmc-product-search-item">
          ...
          <h5 class="tmc-product-search-title"><a href="...">NAME</a></h5>
          <div class="tmc-product-search-price">
            <span class="price"><span class="woocommerce-Price-amount amount">
              <bdi><span class="woocommerce-Price-currencySymbol">&#8360;</span>148</bdi>
            </span></span>
          </div>
          ...
    Note: price uses the &#8360; (₨) HTML entity, not literal "Rs" text — that's
    why the old regex (`Rs\\.?\\s*([\\d,]+)`) was failing here.
    """
    site = "HPharmacy"
    search_url = f"https://hpharmacy.pk/?s={medicine.replace(' ', '+')}"
    result = empty_result(site, medicine, search_url)

    api_url = "https://hpharmacy.pk/wp-admin/admin-ajax.php"
    try:
        r = await client.post(
            api_url,
            headers={
                **COMMON_HEADERS,
                "content-type": "application/x-www-form-urlencoded; charset=UTF-8",
                "x-requested-with": "XMLHttpRequest",
                "origin": "https://hpharmacy.pk",
                "referer": "https://hpharmacy.pk/",
            },
            data={"action": "search_data_fetch", "keyword": medicine, "category": "0"},
            timeout=10,
        )
        if r.status_code != 200 or not r.text.strip():
            return result

        # Response could be JSON or HTML fragment — try JSON first
        try:
            data = r.json()
            items = data if isinstance(data, list) else data.get("data", [])
            if items:
                first = items[0]
                result["product_name"] = first.get("name") or first.get("title", medicine)
                result["price"] = clean_price(first.get("price"))
                result["product_url"] = first.get("url") or first.get("link")
                result["image_url"] = first.get("image") or first.get("thumbnail")
                return result
        except (json.JSONDecodeError, ValueError):
            pass

        # Fallback: parse the real HTML fragment shape
        html = r.text

        # Grab the first product block so name/price/image stay paired correctly
        block_match = re.search(
            r'<div class="tmc-product-search-item">(.*?)</div>\s*</div>\s*</div>',
            html,
            re.DOTALL,
        )
        block = block_match.group(1) if block_match else html

        link_match = re.search(
            r'<h5 class="tmc-product-search-title"><a href="([^"]+)">([^<]+)</a></h5>',
            block,
        )
        if link_match:
            result["product_url"] = link_match.group(1)
            result["product_name"] = link_match.group(2).strip()

        # Price after the ₨ entity, e.g. ...currencySymbol">&#8360;</span>148</bdi>
        price_match = re.search(r'currencySymbol">[^<]*</span>\s*([\d,]+(?:\.\d+)?)', block)
        if price_match:
            result["price"] = clean_price(price_match.group(1))

        img_match = re.search(r'<img src="([^"]+)"', block)
        if img_match:
            result["image_url"] = img_match.group(1)

    except Exception as e:
        print(f"[{site}] Error: {e}")
    return result


# ════════════════════════════════════════════════════════════════════════════
# TIER 2 — WARM-UP REQUIRED (fetch homepage first to harvest a fresh token)
# ════════════════════════════════════════════════════════════════════════════

async def scrape_sehat(client: httpx.AsyncClient, medicine: str) -> dict:
    """
    Sehat.com.pk — AJAX search returning XML with HTML <tr> rows inside CDATA.
    REAL response shape (confirmed):
    <response>
      <result><![CDATA[
        <tr class="QuickSearchResult">
          <td class="QuickSearchResultImage"><img src="https://cdn.../x.jpg" .../></td>
          <td class="QuickSearchResultMeta">
            <div class="QuickSearchResultName">
              <a href="https://sehat.com.pk/products/X.html" title="...">Name</a>
            </div>
            <!--<span class="Price">Rs.40.00</span>-->   <- price is COMMENTED OUT, often empty
          </td>
        </tr>
      ]]></result>
      ...more <result> blocks...
    </response>
    Note: Sehat's price field is inside an HTML comment and frequently blank,
    so price will often be null for this site — that's expected, not a bug.
    """
    site = "Sehat.com.pk"
    encoded = medicine.replace(" ", "+")
    search_url = f"https://sehat.com.pk/index.php?route=product/search&search={encoded}"
    result = empty_result(site, medicine, search_url)

    try:
        # Warm-up: visit homepage to receive a session cookie
        await client.get("https://sehat.com.pk/", headers=COMMON_HEADERS, timeout=10)

        api_url = f"https://sehat.com.pk/search.php?action=AjaxSearch&search_query={encoded}"
        r = await client.get(
            api_url,
            headers={
                **COMMON_HEADERS,
                "accept": "application/xml, text/xml, */*; q=0.01",
                "x-requested-with": "XMLHttpRequest",
                "referer": "https://sehat.com.pk/",
            },
            timeout=10,
        )
        if r.status_code != 200 or not r.text.strip():
            return result

        xml = r.text

        # Get the FIRST <result>...</result> block only
        first_result_match = re.search(r'<result>(.*?)</result>', xml, re.DOTALL)
        if not first_result_match:
            return result
        block = first_result_match.group(1)

        # Product name + URL from <a href="...">Name</a>
        link_match = re.search(r'<a href="([^"]+)"[^>]*>([^<]+)</a>', block)
        if link_match:
            result["product_url"] = link_match.group(1)
            result["product_name"] = link_match.group(2).strip()

        # Image src
        img_match = re.search(r'<img src="([^"]+)"', block)
        if img_match:
            result["image_url"] = img_match.group(1)

        # Price — often inside an HTML comment and may be blank (Sehat limitation)
        price_match = re.search(r'Rs\.?\s*([\d,]+\.\d{2})', block)
        if price_match:
            result["price"] = clean_price(price_match.group(1))

    except Exception as e:
        print(f"[{site}] Error: {e}")
    return result


async def scrape_chemistcart(client: httpx.AsyncClient, medicine: str) -> dict:
    """
    ChemistCart — custom "nika" theme AJAX search.

    CONFIRMED from real DevTools capture:
      GET https://chemistcart.pk/wp-admin/admin-ajax.php
          ?action=nika_autocomplete_search
          &security=<token>      <- query param is named "security", even
                                      though the token is sourced from the
                                      page's `wp_searchnonce` JS value
          &number=5
          &post_type=product
          &query=<term>          <- param name is "query", not "s"

    REAL response shape (confirmed) — JSON array of suggestion objects:
      [
        {
          "value": "PANADOL ULTRA TAB 20`S",
          "subtitle": "",
          "link": "https://chemistcart.pk/product/panadol-ultra-tab-20s/",
          "price": "<span class=\"woocommerce-Price-amount amount\">
                      <bdi><span class=\"woocommerce-Price-currencySymbol\">
                      &#8360;</span>&nbsp;8</bdi></span> / per unit",
          "sku": "",
          "image": "<img ... src=\"https://chemistcart.pk/.../Panadol-...310x310.webp\" ... />",
          "result": "<span class=\"count\">10</span> results found with <span class=\"keywork\">\"panadol\"</span>",
          "view_all": true
        },
        ...
      ]
    Note: price has a trailing "/ per unit" and uses the &#8360; entity +
    &nbsp; before the number, e.g. "&nbsp;8" — that's why we pull the LAST
    number in the price string rather than the first.
    """
    site = "ChemistCart"
    encoded = medicine.replace(" ", "+")
    search_url = f"https://chemistcart.pk/?s={encoded}"
    result = empty_result(site, medicine, search_url)

    try:
        home = await client.get("https://chemistcart.pk/", headers=COMMON_HEADERS, timeout=10)
        html = home.text

        nonce_match = re.search(r'"wp_searchnonce"\s*:\s*"([a-f0-9]+)"', html)
        nonce = nonce_match.group(1) if nonce_match else None
        if not nonce:
            return result

        api_url = (
            f"https://chemistcart.pk/wp-admin/admin-ajax.php"
            f"?action=nika_autocomplete_search&security={nonce}"
            f"&number=5&post_type=product&query={encoded}"
        )
        r = await client.get(
            api_url,
            headers={
                **COMMON_HEADERS,
                "accept": "text/plain, */*; q=0.01",
                "x-requested-with": "XMLHttpRequest",
                "referer": "https://chemistcart.pk/",
            },
            timeout=10,
        )
        if r.status_code != 200 or not r.text.strip():
            return result

        items = r.json()
        if not isinstance(items, list) or not items:
            return result

        first = items[0]
        result["product_name"] = strip_html(first.get("value")) or medicine
        result["product_url"] = first.get("link")

        # Price string ends like "...&nbsp;8</bdi>...  / per unit" — take the
        # last standalone number, which is the actual amount.
        price_html = first.get("price", "")
        price_matches = re.findall(r'([\d,]+(?:\.\d+)?)', strip_html(price_html) or "")
        if price_matches:
            result["price"] = clean_price(price_matches[-1])

        image_html = first.get("image", "")
        img_match = re.search(r'src="([^"]+)"', image_html)
        if img_match:
            result["image_url"] = img_match.group(1)

    except Exception as e:
        print(f"[{site}] Error: {e}")
    return result


async def scrape_medspot(client: httpx.AsyncClient, medicine: str) -> dict:
    """
    MedSpot — WordPress/Woodmart AJAX search, same shape as MarhamPharmacy.
    REAL response shape (confirmed) — clean JSON:
    {
      "suggestions": [
        {
          "value": "Panadol",
          "permalink": "https://medspot.pk/product/panadol/",
          "price": "<span class=\"wcpbc-price wcpbc-price-11738\" ...></span>",
          "thumbnail": "<img ... src=\"https://medspot.pk/...jpg\" .../>"
        }
      ]
    }
    Note: price wrapper is "wcpbc-price" (a currency-switcher plugin) instead
    of plain "price", and can be genuinely EMPTY (no price loaded yet) for
    some items — that's a real site quirk, not a parsing bug, so price may
    be null for the top suggestion. We use parse_currency_symbol_price which
    returns None cleanly in that case.
    """
    site = "MedSpot"
    encoded = medicine.replace(" ", "+")
    search_url = f"https://medspot.pk/?s={encoded}&post_type=product"
    result = empty_result(site, medicine, search_url)

    api_url = (
        f"https://medspot.pk/wp-admin/admin-ajax.php"
        f"?action=woodmart_ajax_search&number=20&post_type=product&query={encoded}"
    )
    try:
        r = await client.get(
            api_url,
            headers={**COMMON_HEADERS, "x-requested-with": "XMLHttpRequest"},
            timeout=10,
        )
        if r.status_code != 200 or not r.text.strip():
            return result

        data = r.json()
        suggestions = data.get("suggestions", [])
        if not suggestions:
            return result

        # Some suggestions have no price loaded yet — prefer the first one
        # that actually has a parseable price, falling back to the very
        # first suggestion (with a null price) if none do.
        chosen = None
        for s in suggestions:
            if parse_currency_symbol_price(s.get("price", "")) is not None:
                chosen = s
                break
        if chosen is None:
            chosen = suggestions[0]

        result["product_name"] = chosen.get("value", medicine)
        result["product_url"] = chosen.get("permalink")
        result["price"] = parse_currency_symbol_price(chosen.get("price", ""))

        thumb_html = chosen.get("thumbnail", "")
        img_match = re.search(r'src="([^"]+)"', thumb_html)
        if img_match:
            result["image_url"] = img_match.group(1)

    except Exception as e:
        print(f"[{site}] Error: {e}")
    return result


async def scrape_pillbox(client: httpx.AsyncClient, medicine: str) -> dict:
    """
    Pillbox+ — Shopify storefront, but unlike MeriPharmacy this theme does
    NOT have a working `view=json` search template (confirmed: requesting
    `&view=json` still returns a full rendered HTML page, not JSON). So we
    parse the product grid directly out of the search results HTML page.

    REAL response shape (confirmed) — repeated card blocks like:
      <a href="/products/panadol-night-tab-20s?_pos=1..."
         id="CardLink-...-9099693949164" class="full-unstyled-link" ...>
        PANADOL NIGHT TAB 20S
      </a>
      ...
      <span class="price-item price-item--regular">
        Rs.230.00 PKR
      </span>
    """
    site = "Pillbox+"
    encoded = medicine.replace(" ", "+")
    search_url = f"https://pillbox.pk/search?q={encoded}&type=product"
    result = empty_result(site, medicine, search_url)

    try:
        r = await client.get(
            search_url,
            headers={**COMMON_HEADERS, "accept": "text/html"},
            timeout=15,
        )
        if r.status_code != 200 or not r.text.strip():
            return result

        html = r.text

        # First product card: name + url from the first CardLink anchor
        link_match = re.search(
            r'href="(/products/[^"?]+)[^"]*"[^>]*id="CardLink-[^"]*"[^>]*>\s*([^<]+?)\s*</a>',
            html,
        )
        if not link_match:
            return result

        result["product_url"] = "https://pillbox.pk" + link_match.group(1)
        result["product_name"] = link_match.group(2).strip()

        # Search forward from the matched link for the first price block
        # that follows it, so we get the price for THIS product card, not
        # some other one further down the page.
        remainder = html[link_match.end():]
        price_match = re.search(r'Rs\.([\d,]+\.\d{2})\s*PKR', remainder)
        if price_match:
            result["price"] = clean_price(price_match.group(1))

        # Product image: find an <img> with this product's handle in its alt
        # text isn't reliable across cards, so just grab the first product
        # image after the matched link as a best-effort.
        img_match = re.search(r'<img\s+[^>]*srcset="([^"]+)"', remainder)
        if img_match:
            first_src = img_match.group(1).split(",")[0].strip().split(" ")[0]
            result["image_url"] = "https:" + first_src if first_src.startswith("//") else first_src

    except Exception as e:
        print(f"[{site}] Error: {e}")
    return result


async def scrape_dwatson(client: httpx.AsyncClient, medicine: str) -> dict:
    """
    D-Watson — Magento 2 search-suite autocomplete AJAX endpoint.
    REAL response shape (confirmed):
    {
      "result": [
        {"code": "suggest", "data": [...]},
        {
          "code": "product",
          "data": [
            {
              "name": "Panadol Drops 30ml",
              "image": "https://dwatson.pk/media/.../Panadol_Drops_30ml.png",
              "price": "<div class=\"price-box ...\" data-product-id=\"7602\">
                          <span ... data-price-amount=\"96\" ...>
                            <span class=\"price\">Rs.&nbsp;96.00</span>
                          </span></div>",
              "url": "https://dwatson.pk/panadol-drops-30ml.html"
            }
          ]
        }
      ]
    }
    Note: price is most reliably pulled from the `data-price-amount="96"`
    attribute rather than parsing the rendered "Rs. 96.00" text.

    IMPORTANT — Cloudflare: the captured request included a `cf_clearance`
    cookie. D-Watson's JSON endpoint responded successfully when captured,
    suggesting Cloudflare may not be in full-block mode for this specific
    endpoint, but this is NOT guaranteed long-term. If this scraper starts
    silently returning empty results, that's the most likely cause — see
    the Tier 3 / Playwright note at the top of this file.
    """
    site = "D-Watson"
    encoded = medicine.replace(" ", "+")
    search_url = f"https://dwatson.pk/catalogsearch/result/?q={encoded}"
    result = empty_result(site, medicine, search_url)

    api_url = f"https://dwatson.pk/dwatson_searchsuiteautocomplete/ajax/index/?q={encoded}"
    try:
        r = await client.get(
            api_url,
            headers={
                **COMMON_HEADERS,
                "accept": "application/json, text/javascript, */*; q=0.01",
                "x-requested-with": "XMLHttpRequest",
                "referer": "https://dwatson.pk/",
            },
            timeout=10,
        )
        if r.status_code != 200 or not r.text.strip():
            return result

        data = r.json()
        blocks = data.get("result", [])
        product_block = next((b for b in blocks if b.get("code") == "product"), None)
        if not product_block:
            return result

        items = product_block.get("data", [])
        if not items:
            return result

        first = items[0]
        result["product_name"] = first.get("name", medicine)
        result["product_url"] = first.get("url")
        result["image_url"] = first.get("image")

        price_html = first.get("price", "")
        price_match = re.search(r'data-price-amount="([\d.]+)"', price_html)
        if price_match:
            result["price"] = clean_price(price_match.group(1))

    except Exception as e:
        print(f"[{site}] Error: {e}")
    return result


async def scrape_medlife(client: httpx.AsyncClient, medicine: str) -> dict:
    """
    MedLife — WordPress/Woodmart AJAX search, same shape as MarhamPharmacy
    and MedSpot, BUT this site sits behind Cloudflare's JS challenge.

    REAL response shape (confirmed) — clean JSON, identical structure to
    MarhamPharmacy/MedSpot's "suggestions" array, with prices that can have
    plain WooCommerce price markup OR a sale (del/ins) variant — see
    parse_currency_symbol_price for how the sale case is handled.

    *** TIER 3 / CLOUDFLARE WARNING ***
    The only reason this request succeeded during capture is the presence
    of a `cf_clearance` cookie, generated by a real browser solving
    Cloudflare's JS challenge. That cookie is time-limited and will expire
    or rotate — once it does, this scraper will start failing (likely with
    a 403 or a JS-challenge HTML page instead of JSON) until refreshed.
    There is no way to generate a fresh cf_clearance from plain httpx; that
    requires a real (or headless) browser, e.g. via Playwright — see
    playwright_scrapers.py. For now this is wired up with a placeholder so
    the endpoint exists, but expect it to need replacing with a Playwright-
    based version for reliable long-term operation.
    """
    site = "MedLife"
    encoded = medicine.replace(" ", "+")
    search_url = f"https://medlife.pk/?s={encoded}&post_type=product"
    result = empty_result(site, medicine, search_url)

    # NOTE: cf_clearance is a placeholder captured at build time and WILL
    # go stale. Replace via Playwright once this starts failing.
    CF_CLEARANCE_PLACEHOLDER = (
        "Vv7G3GRef5f_3ULNKf5Fc3gIuZRuUPp6fYnlzdRw70Q-1781955955-1.2.1.1-"
        "OymY6GQaKfB5tJz_tLakLS5U2l8zp4YjHDebvzhVExD8xF1.kQOV3pY.NCeUexh4Q9"
        "wJ6Xw9J0F5KR..CYFcQLeK9DsW2nd_619rj4a7rXwQRv.vQqrSY.XluimX1OGdOZ3F"
        "CiqgZXcPyVUigow0YOAf2FrtA0pmFafw28jz6iI9WNZg582DZb0U2HHG1MaoK5Jn6x"
        "4yZjugSnjyHoFUIX1_x3QSvdSXO94clciLvdJ3XGSGws2uw0no.HIRjuNosYnYA94u"
        "d5eFszR2yO_44m8TkkJISDy6J.8n3uNXW5x5wQNdspROfY0YH5LAHo63sl5LNdn.O5"
        "H4aloEQQ0oFQ"
    )

    api_url = (
        f"https://medlife.pk/wp-admin/admin-ajax.php"
        f"?action=woodmart_ajax_search&number=20&post_type=product&query={encoded}"
    )
    try:
        r = await client.get(
            api_url,
            headers={**COMMON_HEADERS, "x-requested-with": "XMLHttpRequest"},
            cookies={"cf_clearance": CF_CLEARANCE_PLACEHOLDER},
            timeout=10,
        )
        if r.status_code != 200 or not r.text.strip():
            return result

        try:
            data = r.json()
        except (json.JSONDecodeError, ValueError):
            # Most likely Cloudflare intercepted with a challenge page
            # instead of returning JSON — the cf_clearance cookie is stale.
            return result

        suggestions = data.get("suggestions", [])
        if not suggestions:
            return result

        first = suggestions[0]
        result["product_name"] = first.get("value", medicine)
        result["product_url"] = first.get("permalink")
        result["price"] = parse_currency_symbol_price(first.get("price", ""))

        thumb_html = first.get("thumbnail", "")
        img_match = re.search(r'src="([^"]+)"', thumb_html)
        if img_match:
            result["image_url"] = img_match.group(1)

    except Exception as e:
        print(f"[{site}] Error: {e}")
    return result


async def scrape_onyxcare(client: httpx.AsyncClient, medicine: str) -> dict:
    """
    Onyxcare — Shopify native predictive search (section_id renders HTML,
    not JSON, unlike MeriPharmacy's plain search/suggest without section_id).

    REAL response shape (confirmed) — HTML fragment, product items like:
      <li id="predictive-search-option-product-1" ...>
        <a href="/products/acsolve-lotion-1-30ml-1?_pos=1..."
           class="predictive-search__item predictive-search__item--link-with-thumbnail ...">
          <img class="predictive-search__image" src="//onyxcare.pk/cdn/shop/files/....jpg" .../>
          <div class="predictive-search__item-content">
            <p class="predictive-search__item-heading h5">Acsolve Lotion 1% 30ml</p>
            <div class="price">...<span class="price-item price-item--regular">Rs.217.00 PKR</span>...
          </div>
        </a>
      </li>
    """
    site = "Onyxcare"
    encoded = medicine.replace(" ", "+")
    search_url = f"https://onyxcare.pk/search?q={encoded}&type=product"
    result = empty_result(site, medicine, search_url)

    api_url = "https://onyxcare.pk/search/suggest"
    try:
        r = await client.get(
            api_url,
            params={"q": medicine, "section_id": "predictive-search"},
            headers={**COMMON_HEADERS, "accept": "*/*", "x-requested-with": "XMLHttpRequest"},
            timeout=10,
        )
        if r.status_code != 200 or not r.text.strip():
            return result

        html = r.text

        link_match = re.search(
            r'href="(/products/[^"?]+)[^"]*"[^>]*class="predictive-search__item[^"]*"[^>]*>'
            r'.*?<p class="predictive-search__item-heading[^"]*">([^<]+)</p>',
            html,
            re.DOTALL,
        )
        if not link_match:
            return result

        result["product_url"] = "https://onyxcare.pk" + link_match.group(1)
        result["product_name"] = link_match.group(2).strip()

        img_match = re.search(r'<img class="predictive-search__image" src="([^"]+)"', html)
        if img_match:
            src = img_match.group(1)
            result["image_url"] = f"https:{src}" if src.startswith("//") else src

        # Search forward from the matched product for its price block so we
        # don't accidentally grab a price belonging to a later result.
        remainder = html[link_match.end():]
        price_match = re.search(r'Rs\.([\d,]+\.\d{2})\s*PKR', remainder)
        if price_match:
            result["price"] = clean_price(price_match.group(1))

    except Exception as e:
        print(f"[{site}] Error: {e}")
    return result


async def scrape_healthwire(client: httpx.AsyncClient, medicine: str) -> dict:
    """
    HealthWire — Elasticsearch-backed search API, needs x-csrf-token header.
    REAL response shape (confirmed) — array of search blocks, each with hits:
    [
      {
        "total": 17,
        "hits": [
          {
            "_source": {
              "image": "https://...jpg" or null,
              "actual_price": 800.0,
              "discounted_price": 800.0,
              "name": "Panadol (500Mg) 200 Tablets",
              "url": "/pharmacy/medicine/panadol-tablet"
            }
          },
          ...
        ]
      },
      { ... lab_tests block ... }
    ]
    """
    site = "HealthWire"
    encoded = medicine.replace(" ", "+")
    search_url = f"https://healthwire.pk/medicines/search?q={encoded}"
    result = empty_result(site, medicine, search_url)

    try:
        home = await client.get("https://healthwire.pk/", headers=COMMON_HEADERS, timeout=10)
        token_match = re.search(r'<meta name="csrf-token" content="([^"]+)"', home.text)
        token = token_match.group(1) if token_match else None
        if not token:
            return result

        params = {
            "searches[0][q]": medicine,
            "searches[0][model]": "items",
            "searches[0][attributes][]": ["id", "name", "image", "actual_price", "discounted_price", "url"],
        }
        r = await client.get(
            "https://healthwire.pk/searches",
            params=params,
            headers={
                **COMMON_HEADERS,
                "accept": "application/json, text/javascript, */*; q=0.01",
                "content-type": "application/json; charset=UTF-8",
                "x-csrf-token": token,
                "x-requested-with": "XMLHttpRequest",
                "referer": "https://healthwire.pk/",
            },
            timeout=10,
        )
        if r.status_code != 200:
            return result

        data = r.json()
        # data is a LIST — first element is the "items" (medicines) search block
        if not isinstance(data, list) or not data:
            return result

        items_block = data[0]
        hits = items_block.get("hits", [])
        if not hits:
            return result

        first_source = hits[0].get("_source", {})
        result["product_name"] = first_source.get("name", medicine)

        price = first_source.get("discounted_price") or first_source.get("actual_price")
        result["price"] = clean_price(price)

        url_path = first_source.get("url")
        if url_path:
            result["product_url"] = (
                url_path if url_path.startswith("http") else f"https://healthwire.pk{url_path}"
            )

        image = first_source.get("image")
        if image:
            result["image_url"] = image if str(image).startswith("http") else None

    except Exception as e:
        print(f"[{site}] Error: {e}")
    return result


# ════════════════════════════════════════════════════════════════════════════
# REGISTRY — Tier 1 + Tier 2 only (HTTP-only, fast, free, no browser)
# Tier 3 (Cloudflare sites) lives in playwright_scrapers.py — see note at bottom
# ════════════════════════════════════════════════════════════════════════════

SCRAPERS = [
    scrape_dvago,
    scrape_meripharmacy,
    scrape_marhampharmacy,
    scrape_hpharmacy,
    scrape_sehat,
    scrape_chemistcart,
    scrape_healthwire,
    scrape_medspot,
    scrape_pillbox,
    scrape_dwatson,
    scrape_medlife,
    scrape_onyxcare,
]


@app.get("/scrape")
async def scrape(q: str):
    medicine = q.strip()
    if not medicine:
        return []

    async with httpx.AsyncClient(follow_redirects=True) as client:
        tasks = [fn(client, medicine) for fn in SCRAPERS]
        results = await asyncio.gather(*tasks, return_exceptions=True)

    clean = []
    for r in results:
        if isinstance(r, Exception):
            print(f"Scraper task error: {r}")
            continue
        clean.append(r)

    clean.sort(key=lambda x: (x["price"] is None, x["price"] or 0))
    return clean


@app.get("/health")
async def health():
    return {"status": "ok", "tier1_tier2_sites": len(SCRAPERS)}


# ════════════════════════════════════════════════════════════════════════════
# DEBUG ENDPOINT — shows the RAW, unparsed response from one site.
# Use this to see the real JSON/HTML shape so we can fix field-name guesses.
# Example: http://127.0.0.1:8000/debug/dvago?q=Panadol
# ════════════════════════════════════════════════════════════════════════════

@app.get("/debug/dvago")
async def debug_dvago(q: str):
    api_url = f"https://apidb.dvago.pk/AppAPIV3/SearchinginBox&ProductName={q}&limit=0,20&BranchCode=32"
    async with httpx.AsyncClient(follow_redirects=True) as client:
        r = await client.get(
            api_url,
            headers={**COMMON_HEADERS, "accept": "application/json, text/plain, */*",
                     "origin": "https://www.dvago.pk", "referer": "https://www.dvago.pk/"},
            timeout=10,
        )
    return {"status_code": r.status_code, "raw_text": r.text[:3000]}


@app.get("/debug/meripharmacy")
async def debug_meripharmacy(q: str):
    api_url = f"https://meripharmacy.pk/search?q={q}*&type=article%2Cpage%2Cproduct&view=header"
    async with httpx.AsyncClient(follow_redirects=True) as client:
        r = await client.get(api_url, headers={**COMMON_HEADERS, "accept": "application/json"}, timeout=10)
    return {"status_code": r.status_code, "raw_text": r.text[:3000]}


@app.get("/debug/marham")
async def debug_marham(q: str):
    api_url = (f"https://www.marhampharmacy.pk/wp-admin/admin-ajax.php"
               f"?action=woodmart_ajax_search&number=20&post_type=product&query={q}")
    async with httpx.AsyncClient(follow_redirects=True) as client:
        r = await client.get(api_url, headers={**COMMON_HEADERS, "x-requested-with": "XMLHttpRequest"}, timeout=10)
    return {"status_code": r.status_code, "raw_text": r.text[:3000]}


@app.get("/debug/sehat")
async def debug_sehat(q: str):
    async with httpx.AsyncClient(follow_redirects=True) as client:
        await client.get("https://sehat.com.pk/", headers=COMMON_HEADERS, timeout=10)
        api_url = f"https://sehat.com.pk/search.php?action=AjaxSearch&search_query={q}"
        r = await client.get(
            api_url,
            headers={**COMMON_HEADERS, "accept": "application/xml, text/xml, */*; q=0.01",
                     "x-requested-with": "XMLHttpRequest", "referer": "https://sehat.com.pk/"},
            timeout=10,
        )
    return {"status_code": r.status_code, "raw_text": r.text[:3000]}


@app.get("/debug/chemistcart")
async def debug_chemistcart(q: str):
    """
    Calls the CONFIRMED real endpoint (action=nika_autocomplete_search,
    param names "security" + "query") and returns the raw response so we
    can verify it still matches the captured shape if the site changes.
    """
    async with httpx.AsyncClient(follow_redirects=True) as client:
        home = await client.get("https://chemistcart.pk/", headers=COMMON_HEADERS, timeout=10)
        nonce_match = re.search(r'"wp_searchnonce"\s*:\s*"([a-f0-9]+)"', home.text)
        nonce = nonce_match.group(1) if nonce_match else None
        if not nonce:
            return {"error": "wp_searchnonce not found on homepage", "home_snippet": home.text[:1000]}

        api_url = (
            f"https://chemistcart.pk/wp-admin/admin-ajax.php"
            f"?action=nika_autocomplete_search&security={nonce}"
            f"&number=5&post_type=product&query={q}"
        )
        try:
            r = await client.get(
                api_url,
                headers={**COMMON_HEADERS, "accept": "text/plain, */*; q=0.01",
                         "x-requested-with": "XMLHttpRequest", "referer": "https://chemistcart.pk/"},
                timeout=10,
            )
            result = {"status_code": r.status_code, "raw_text": r.text[:3000]}
        except Exception as e:
            result = {"error": str(e)}

    return {"nonce": nonce, "attempt": result}


@app.get("/debug/healthwire")
async def debug_healthwire(q: str):
    async with httpx.AsyncClient(follow_redirects=True) as client:
        home = await client.get("https://healthwire.pk/", headers=COMMON_HEADERS, timeout=10)
        token_match = re.search(r'<meta name="csrf-token" content="([^"]+)"', home.text)
        token = token_match.group(1) if token_match else None
        if not token:
            return {"error": "no csrf token found", "home_snippet": home.text[:1000]}
        params = {
            "searches[0][q]": q, "searches[0][model]": "items",
            "searches[0][attributes][]": ["id", "name", "image", "actual_price", "discounted_price", "url"],
        }
        r = await client.get(
            "https://healthwire.pk/searches", params=params,
            headers={**COMMON_HEADERS, "accept": "application/json, text/javascript, */*; q=0.01",
                     "content-type": "application/json; charset=UTF-8", "x-csrf-token": token,
                     "x-requested-with": "XMLHttpRequest", "referer": "https://healthwire.pk/"},
            timeout=10,
        )
    return {"status_code": r.status_code, "token_found": token, "raw_text": r.text[:3000]}


@app.get("/debug/hpharmacy")
async def debug_hpharmacy(q: str):
    async with httpx.AsyncClient(follow_redirects=True) as client:
        r = await client.post(
            "https://hpharmacy.pk/wp-admin/admin-ajax.php",
            headers={
                **COMMON_HEADERS,
                "content-type": "application/x-www-form-urlencoded; charset=UTF-8",
                "x-requested-with": "XMLHttpRequest",
                "origin": "https://hpharmacy.pk",
                "referer": "https://hpharmacy.pk/",
            },
            data={"action": "search_data_fetch", "keyword": q, "category": "0"},
            timeout=10,
        )
    return {"status_code": r.status_code, "raw_text": r.text[:3000]}


@app.get("/debug/medspot")
async def debug_medspot(q: str):
    api_url = (f"https://medspot.pk/wp-admin/admin-ajax.php"
               f"?action=woodmart_ajax_search&number=20&post_type=product&query={q}")
    async with httpx.AsyncClient(follow_redirects=True) as client:
        r = await client.get(api_url, headers={**COMMON_HEADERS, "x-requested-with": "XMLHttpRequest"}, timeout=10)
    return {"status_code": r.status_code, "raw_text": r.text[:3000]}


@app.get("/debug/pillbox")
async def debug_pillbox(q: str):
    search_url = f"https://pillbox.pk/search?q={q}&type=product"
    async with httpx.AsyncClient(follow_redirects=True) as client:
        r = await client.get(search_url, headers={**COMMON_HEADERS, "accept": "text/html"}, timeout=15)
    return {"status_code": r.status_code, "raw_text_length": len(r.text), "raw_text_sample": r.text[:3000]}


@app.get("/debug/dwatson")
async def debug_dwatson(q: str):
    api_url = f"https://dwatson.pk/dwatson_searchsuiteautocomplete/ajax/index/?q={q}"
    async with httpx.AsyncClient(follow_redirects=True) as client:
        r = await client.get(
            api_url,
            headers={**COMMON_HEADERS, "accept": "application/json, text/javascript, */*; q=0.01",
                     "x-requested-with": "XMLHttpRequest", "referer": "https://dwatson.pk/"},
            timeout=10,
        )
    return {"status_code": r.status_code, "raw_text": r.text[:3000]}


@app.get("/debug/medlife")
async def debug_medlife(q: str):
    """
    NOTE: this will likely start failing once the placeholder cf_clearance
    cookie (captured at build time) expires or rotates — see the warning in
    scrape_medlife's docstring. A non-200 status, an empty body, or a body
    that isn't valid JSON (e.g. an HTML challenge page) all indicate the
    cookie needs replacing via a real browser / Playwright capture.
    """
    CF_CLEARANCE_PLACEHOLDER = (
        "Vv7G3GRef5f_3ULNKf5Fc3gIuZRuUPp6fYnlzdRw70Q-1781955955-1.2.1.1-"
        "OymY6GQaKfB5tJz_tLakLS5U2l8zp4YjHDebvzhVExD8xF1.kQOV3pY.NCeUexh4Q9"
        "wJ6Xw9J0F5KR..CYFcQLeK9DsW2nd_619rj4a7rXwQRv.vQqrSY.XluimX1OGdOZ3F"
        "CiqgZXcPyVUigow0YOAf2FrtA0pmFafw28jz6iI9WNZg582DZb0U2HHG1MaoK5Jn6x"
        "4yZjugSnjyHoFUIX1_x3QSvdSXO94clciLvdJ3XGSGws2uw0no.HIRjuNosYnYA94u"
        "d5eFszR2yO_44m8TkkJISDy6J.8n3uNXW5x5wQNdspROfY0YH5LAHo63sl5LNdn.O5"
        "H4aloEQQ0oFQ"
    )
    api_url = (f"https://medlife.pk/wp-admin/admin-ajax.php"
               f"?action=woodmart_ajax_search&number=20&post_type=product&query={q}")
    async with httpx.AsyncClient(follow_redirects=True) as client:
        r = await client.get(
            api_url,
            headers={**COMMON_HEADERS, "x-requested-with": "XMLHttpRequest"},
            cookies={"cf_clearance": CF_CLEARANCE_PLACEHOLDER},
            timeout=10,
        )
    return {"status_code": r.status_code, "raw_text": r.text[:3000]}


@app.get("/debug/onyxcare")
async def debug_onyxcare(q: str):
    async with httpx.AsyncClient(follow_redirects=True) as client:
        r = await client.get(
            "https://onyxcare.pk/search/suggest",
            params={"q": q, "section_id": "predictive-search"},
            headers={**COMMON_HEADERS, "accept": "*/*", "x-requested-with": "XMLHttpRequest"},
            timeout=10,
        )
    return {"status_code": r.status_code, "raw_text": r.text[:3000]}