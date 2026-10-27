# Belowground biomass and upscaling: discussion notes

Source check: 26 October 2026. These are proposed discussion notes, not changes to analysis parameters.

## Root:shoot assumption

The assumed root:shoot dry-biomass ratio of 0.26 lies near the lower end of the values reported by Schulz-Nielsen et al. (2026). Direct transfer is uncertain because their stands differed in age, density and harvest history. Retaining 0.26 as an explicit modelling assumption is reasonable, with sensitivity analysis; agreement with this study does not validate it for mature silvoarable poplar.

Their roots were six and seven years old, rather than one and two. The latter ages describe post-coppice shoots. A decline between campaigns should not be presented as a universal age trajectory. The study lacks a replicated factorial design separating density, cultivar and harvest history, so causal density claims require caution.

Source: Schulz-Nielsen et al. (2026), Tables 1–3, sections 2.3.3, 4.1 and 5: https://www.mdpi.com/1999-4907/17/3/395

## Planting density and the CCC scenario

Schulz-Nielsen et al. (2026, section 4.1.3) discuss evidence that higher planting density can reduce root biomass relative to shoot biomass, whereas lower density may favour greater belowground investment and more extensive coarse-root development. Over longer rotations, this could support belowground carbon storage and potentially enhance SOC through root-derived inputs. Their discussion therefore highlights potential trade-offs of increasing tree density when estimating the carbon benefits of agroforestry, rather than assuming that additional trees necessarily increase all carbon pools. These are potential effects: the study does not establish a consistent density response in belowground biomass or demonstrate SOC gains from lower density.

This is relevant context for our upscaling choices. The CCC Sixth Carbon Budget assumes 400 broadleaf trees per hectare for silvopastoral systems, equivalent to 5 × 5 m spacing under a uniform layout. We consider this too dense for the agroforestry systems envisaged in our scenarios and will not adopt it. The potential consequences for belowground allocation and SOC provide an additional reason to discuss planting density explicitly; they are not evidence that 400 trees per hectare necessarily reduces belowground carbon or SOC.

Source for the allocation and coarse-root discussion: Schulz-Nielsen et al. (2026), section 4.1.3: https://www.mdpi.com/1999-4907/17/3/395

Source: CCC (2020), Agriculture and land use sector summary, agroforestry section: https://www.theccc.org.uk/wp-content/uploads/2020/12/Sector-summary-Agriculture-land-use-land-use-change-forestry.pdf

## Where the thesis's 0.26 comes from

- Submitted thesis, printed p. 81 (PDF p. 101): cites FAO (2004), applies 0.26 directly to AGB carbon increment, and calls it a shoot-to-root ratio. The direction should be root:shoot.
- Printed p. 174 (PDF p. 194) correctly gives BGB = 0.26 × AGB as a fixed root:shoot assumption.
- No matching FAO (2004) bibliography entry was found in the extracted thesis text. Its exact intended source remains unconfirmed.
- A plausible FAO report, Ponce-Hernandez (2004), *Assessing carbon stocks and modelling win-win scenarios of carbon sequestration through land-use changes*, Chapter 3, recommends 0.20, not 0.26: https://www.fao.org/4/y5490e/y5490e07.htm
- UNFCCC guidance explicitly attributes a global mean of 0.26 to Cairns et al. (1997): https://cdm.unfccc.int/Reference/catalogue/document?doc_id=000000951
- Original reference: Cairns, M.A., Brown, S., Helmer, E.H. and Baumgardner, G.A. (1997). Root biomass allocation in the world's upland forests. Oecologia 111, 1–11. https://doi.org/10.1007/s004420050201

Use Cairns as the generic assumption's source after checking the original study's population and root definitions against our application; do not describe it as a poplar-specific estimate. A fixed stock ratio applied to annual increments additionally assumes the ratio remains constant through time.

## Carbon concentration

Table 2 reports shoot C of 48.46–49.30% and root C of 45.28–49.72% dry mass. Simple unweighted means of the eight plot-year values are 48.84% and 46.90%, respectively. These are calculated summaries, not pooled estimates reported by the authors; borrowing them requires an explicit transfer assumption.

If adopted, use separate fractions:

AGB_C = AGB_dry × 0.4884`

`BGB_C = AGB_dry × 0.26 × 0.4690`

Consequently, `BGB_C / AGB_C = 0.26 × 0.4690 / 0.4884 ≈ 0.250`.

If starting from carbon values already calculated with the thesis's 0.50 shoot fraction, first recover dry biomass by dividing by 0.50. Do not multiply existing AGB carbon directly by 0.26 after introducing different root and shoot C fractions. Keep living-root carbon separate from SOC to avoid double counting.

No parameter changes or inferential analyses were performed for these notes.
