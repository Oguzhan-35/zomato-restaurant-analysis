# Data quality notes

Raw file: 9,551 rows, 21 columns, one row per restaurant. No duplicate restaurant IDs.

| Issue | Count | What I did |
|---|---|---|
| Rating = 0.0 with label "Not rated" | 2,148 (22%) | Rating set to NULL, `is_rated` flag added. Reported separately instead of averaged in. |
| Cost for two = 0 | 18 | Set to NULL |
| Cuisines missing | 9 | Kept in restaurants, left out of the cuisine table |
| Broken characters in restaurant name | 103 | Kept as is, flagged in `name_encoding_issue` |
| Country given only as a number | all rows | Mapped with the standard Zomato list; each code checked against its cities (1 = New Delhi, 216 = Albany, 208 = Ankara ...) |
| Inconsistent currency labels ("Dollar($)", "NewZealand($)", "Pounds(??)") | 12 labels | Cleaned labels, no conversion |
| Philippines restaurants labelled "Botswana Pula" | 22 | Left as in the source and not used. I don't compare prices across countries. |
| Yes/No text columns | 3 columns | Converted to 1/0 |
| One cell with several cuisines ("French, Japanese, Desserts") | 9,542 | Split into a restaurant-cuisine table (19,705 links, 145 cuisines) |

## Coverage problems that matter more than the cleaning
- **91% India.** Any "global" statement from this data is really a statement about India.
- **Delivery flag.** 0 for every restaurant outside India except 28 in the UAE. Most likely not collected there.
- **City sizes.** Delhi NCR cities have 25 to 5,473 restaurants. Every other Indian city has about 20, so city averages outside the NCR are noisy.
- **No dates.** Ratings and votes are cumulative and cannot show trends.
