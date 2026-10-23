# Soil sample provenance audit

Updated 22 October 2026. Original workbooks and numerical SOC outputs are unchanged.

## Verified identity results

All 188 rows in `rawdataSofia` match both fine dry bulk density and SOC in the AgricARBON results within 0.005001 (two-decimal rounding). Joint available-layer fingerprints resolve 96 distinct cores, with no duplicate core assignment. Some individual layer matches are ambiguous; identities use both layers when available. The crosswalk retains original location codes, potential_samplingID, analysis profile_id, permanent company core IDs and coordinates. The value audit retains original and company values and candidate counts.

48 profiles are in agroforestry Field 2: 24 Alley and 24 Tree row. Another 48 are in reference Field 1: the 47 Arable reference profiles plus workbook Tree row profile 25. Both layers of `1_tree_25` match `UOL001-A01-001.0-A-016`, at 53.873887, -1.333282. Existing SOC summaries and ESM references still use the original labels and need rebuilding from the raw company results with corrected location membership.

## Confirmed former treatment mapping

The user confirmed on 22 October 2026 that tree rows run approximately north to south, with row 6 furthest west. Together with the numbered original design and colleague's row/block/treatment account, this anchors the western, middle and eastern sampled bands to rows 6, 10 and 14 respectively:

| Spatial band | Alley potential_samplingID | Company core suffixes | Original row / block | Former treatment |
|---|---|---|---|---|
| Western | 1-8 | 024-031 | 6 / 1 | Continuous fallow |
| Middle | 9-16 | 033-040 | 10 / 2 | Continuous cropping |
| Eastern | 17-24 | 041-048 | 14 / 3 | Alternate cropping |

Company core prefix in this table: `UOL001-A01-002.0-A-`. Workbook IDs are not company core numbers. Core 032 belongs to workbook Tree row profile 12, in the middle band; do not assign location using core-number ranges alone. Every alley group contains eight profiles and sixteen depth records.

Alternate cropping is a rotation history: the screenshot says cropping and fallow sides changed annually from 1992 to 1998. It does not identify a permanently fallow versus permanently cropped alley on opposite sides. No exact hybrid assignments or year-specific crop-side labels have been made.

## Source conflicts and inference limits

- The user confirms Field 1 was arable. The open grassland description on page 4 of the field plan is an Agricarbon error; use Arable reference in methods and scenarios.
- The user confirms sampling occurred in 2024; the earlier 2023 statement was mistaken. Use 2024 as the SOC observation year in methods and scenarios. The company Date extracted values are 24-25 January 2024; exact dates should retain their source column label.
- Each former treatment in the sampled subset occurs in one block and sampled row band. Cores provide spatial subsampling, not independent block replication of treatment. Treatment and block/band cannot be separated in this subset.
- The plan is a proposed sampling layout, not an independent survey of historic treatment boundaries. Its embedded link points to a separate Agricarbon SharePoint file named `agroforestry_sampling_design.pdf`, which was not supplied. Row ordering is now anchored by the user's site-orientation confirmation.
- Geographic numbering was confirmed by the user on 22 October 2026; exact hybrid segment boundaries and year-specific cropping sides remain unassigned.

## Reproduction and outputs

Run `poplar_paper/scripts/trace_soil_provenance.py` with Python and openpyxl. It reads the two source workbooks and writes:

- `soil_profile_crosswalk.csv`: one row per workbook profile, including confirmed former-management columns and explicit status flags.
- `soil_value_match_audit.csv`: all 188 values and their matched source samples.
- `soil_exact_match_candidates.csv`: candidates before resolving identities across profile layers.

The Word SOC note has a provenance qualification at the front and a methods/results/hypotheses/open-decisions addendum. A dated copy of the prior note is preserved in its `_history` folder. No sequestration rates or revised treatment-effect tests were calculated in this audit.

## Source authority and remaining scenario inputs

The user confirms the scenario workbook may contain Excel handling errors. Treat company IDs, coordinates and measurements as the primary data; use the scenario workbook only to audit previous transformations. The tree-profile-25 finding means that the two rows labelled Tree row 25 reproduce an arable core, not that the company physically sampled an arable core in a tree row. Keep the original location label as an audit field. Record confirmed site facts in confirmed_site_metadata.json.

Before deriving annual sequestration scenarios, establish management after the original cropping-treatment period and whether the arable reference is a defensible counterfactual (management and comparability). Scenario upscaling also needs actual tree-row/alley area fractions and an explicit stock-to-time trajectory. These do not prevent use of the recovered sample identities.
