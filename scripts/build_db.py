"""Clean the raw Zomato CSV, load it into SQLite and export tables for Power BI.

Usage:  python scripts/build_db.py
Input:  data/raw/zomato.csv
Output: data/zomato.db, powerbi/*.csv
"""
import sqlite3
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "data" / "raw" / "zomato.csv"
DB = ROOT / "data" / "zomato.db"
PBI = ROOT / "powerbi"
PBI.mkdir(exist_ok=True)

# The file only has numeric country codes; this is the standard Zomato code list
# (confirmed against the cities in the file, e.g. 1 = New Delhi, 216 = Albany).
COUNTRIES = {
    1: "India", 14: "Australia", 30: "Brazil", 37: "Canada", 94: "Indonesia",
    148: "New Zealand", 162: "Philippines", 166: "Qatar", 184: "Singapore",
    189: "South Africa", 191: "Sri Lanka", 208: "Turkey", 214: "UAE",
    215: "United Kingdom", 216: "United States",
}

df = pd.read_csv(RAW, encoding="utf-8-sig")
n_raw = len(df)

df = df.rename(columns={
    "Restaurant ID": "restaurant_id", "Restaurant Name": "name", "Country Code": "country_code",
    "City": "city", "Locality": "locality", "Longitude": "longitude", "Latitude": "latitude",
    "Cuisines": "cuisines", "Average Cost for two": "cost_for_two", "Currency": "currency",
    "Has Table booking": "has_table_booking", "Has Online delivery": "has_online_delivery",
    "Is delivering now": "is_delivering_now", "Price range": "price_range",
    "Aggregate rating": "rating", "Rating text": "rating_text", "Votes": "votes",
})
df = df[["restaurant_id", "name", "country_code", "city", "locality", "longitude", "latitude",
         "cuisines", "cost_for_two", "currency", "has_table_booking", "has_online_delivery",
         "is_delivering_now", "price_range", "rating", "rating_text", "votes"]]

# --- cleaning decisions (also documented in docs/02-data-quality.md) ---
for c in ("name", "city", "locality", "cuisines", "currency"):
    df[c] = df[c].str.strip()
for c in ("has_table_booking", "has_online_delivery", "is_delivering_now"):
    df[c] = (df[c] == "Yes").astype(int)
df["is_rated"] = (df["rating"] > 0).astype(int)                      # 0.0 means "Not rated", not a bad score
df["rating"] = df["rating"].where(df["is_rated"] == 1)               # NULL instead of 0 so AVG() is not dragged down
df["cost_for_two"] = df["cost_for_two"].where(df["cost_for_two"] > 0)  # 0 = missing
df["name_encoding_issue"] = df["name"].str.contains("�").astype(int)  # kept, flagged
df["currency"] = df["currency"].str.replace(r"\(.*\)", "", regex=True).str.strip()
df["currency"] = df["currency"].str.replace("��", "GBP", regex=False).replace({"Pounds": "GBP"})
df["country"] = df["country_code"].map(COUNTRIES)
assert df["country"].notna().all()

# --- cuisines: one row per restaurant x cuisine (bridge table) ---
bridge = (df[["restaurant_id", "cuisines"]].dropna()
          .assign(cuisine=lambda x: x["cuisines"].str.split(","))
          .explode("cuisine"))
bridge["cuisine"] = bridge["cuisine"].str.strip()
bridge = bridge[bridge["cuisine"] != ""][["restaurant_id", "cuisine"]].drop_duplicates()

countries = pd.DataFrame({"country_code": list(COUNTRIES), "country": list(COUNTRIES.values())})
restaurants = df.drop(columns=["country"])

con = sqlite3.connect(DB)
for name, frame in {"restaurants": restaurants, "restaurant_cuisines": bridge, "countries": countries}.items():
    frame.to_sql(name, con, if_exists="replace", index=False)
con.executescript((ROOT / "sql" / "01_views.sql").read_text(encoding="utf-8"))
con.commit()

# --- Power BI exports (UTF-8 with BOM so Power BI reads accents correctly) ---
for name in ("vw_restaurants", "restaurant_cuisines", "countries"):
    pd.read_sql(f"SELECT * FROM {name}", con).to_csv(PBI / f"{name}.csv", index=False, encoding="utf-8-sig")
con.close()

print(f"raw rows: {n_raw}, restaurants: {len(restaurants)}, cuisine links: {len(bridge)}, "
      f"distinct cuisines: {bridge['cuisine'].nunique()}")
