### About Spatial Planning

A spatial planning problem There are many different types of spatial planning problems that can be formulated, but here we use the minimum set objective (Rodrigues et al., 2000). This is the most common spatial planning problem, whereby we identify areas of higher conservation priority (i.e., areas with unique or multiple species) whilst minimizing the cost to people (Micheli et al., 2013). On land, the cost could be avoiding urban or agricultural areas, and in the ocean it is commonly avoiding valuable fishing areas. Spatial prioritization selects areas for protection based on a range of input information: the conservation objectives; a suite of area-based features to be conserved - such as species and habitats - and informed by the conservation objectives; targets (i.e. the % of the distribution of each species/habitats) that need to be met for each and are also informed by the conservation objectives; and a representation of the cost of protecting an area (Serra et al., 2020). By using spatial prioritization, informed conservation decisions can be made whilst considering the different needs, including economic ones, of all stakeholders involved. Alternative designs can be generated based on selection of different conservation features, modifying the targets, and choosing different cost layers (e.g., different fished species). From the range of possible spatial plans, sites can be selected for protection (Ardron et al. 2010).  

### The CARE principles that underpin conservation planning

The four key principles that should be considered when designing a spatial plan are Connectivity, Adequacy, Representation, and Efficiency (CARE). The CARE principles are fundamental to conserving  biodiversity over the long term.

**Connectivity:** Connectivity is the exchange of individuals (or genes, traits, energy or materials) among habitat patches, populations, communities or ecosystems. Ensuring connectivity could include protecting sources and sinks of coral or fish larvae, migration corridors for terrestrial and marine vertebrates, stopover sites for migratory birds, or keeping interdependent habitats that species need throughout their life cycle (e.g., nesting and feeding grounds).

**Adequacy:** An adequate conservation area should contain enough of each species and habitat to ensure that they persist through time. This is achieved by ensuring that a minimum target amount of each habitat and species are conserved within the protected area network. Some species and habitats need more conservation than others.

**Representation:** This principle is the foundation of area-based conservation approaches. It aims to ensure a sample of all biodiversity present in a region receives some form of protection. Species, habitats, ecosystems, and key ecological processes should all be represented and replicated throughout a spatial plan.

**Efficiency:** This principle seeks to deliver conservation outcomes whilst minimizing impacts on people, industries and communities that also rely on natural resources. Conservation plans that have less impact on people and their livelihoods are likely to find broader support. However, efficiency can also lead to residual protected areas. These are areas with low human use that can be preferentially selected in the solution because they are cheap (low cost), but sometimes have little conservation benefit.

  
### Solving the spatial planning problem

There are a number of decision-support tools that can be used to solve spatial planning problems (Moilanen et al., 2009). We use the R package prioritizr (Hanson et al., 2021) because it: 1) solves large spatial planning problems faster than other approaches; 2) determines the optimal planning solution for the given inputs; 3) produces a reproducible workflow in R (Beyer et al., 2016); and 4) allows us to produce a Shiny App for engagement with stakeholders and communication of outputs. These benefits of prioritizr are especially useful for the numerous spatial planning iterations needed to reach an informed decision.
  
Different decision-support tools share several characteristics, including: 1) the planning region; 2) a cost layer; 3) conservation features with representation targets; and 4) an objective function (Moilanen et al., 2009). We used the _minimum set objective_ function (Rodrigues et al., 2000) to design spatial plans that meet targets while minimizing the opportunity cost (i.e., minimizing overall conflict with the costlayer). This objective function is by far the most commonly used in spatial prioritization.  
  

### Creating the feature layers

Detailed benthic habitat data is only available for the shallow water reefs around Kosrae. The rest of the planning area was classified into habitat type according to depth.

Shallow water reef features: The Allen Coral Atlas has global maps of reefs classified into 12 geomorphic and six benthic classes. In the Kosrae planning area, there are 9 geomorphic classes and five benthic classes present. The benthic classes are coral/algae (these cannot be separated in the classification methods used), rock, rubble, sand and seagrass. The primary interest for conservation is habitat that is high biodiversity and that can be impacted by human use, i.e. coral and seagrass. To ensure that biodiversity in these habitats is fully represented, the coral/algae and seagrass classes were intersected with the 9 geomorphic zones, creating a total of 15 key habitats for protection (seagrass is not present in all geomorphic zones). These habitats could be assigned higher protection targets than the remaining benthic classes, geomorphic zone areas, or reef extent could have a lower target, e.g. 10%.

Deep water depth classification: Outside the shallow water reef features, the ocean was classified into depth zones (Ceccarelli et al. 2021):
Epipelagic Zone: 0-200 m depth
Mesopelagic Zone: 200-1000 m depth
Bathypelagic Zone: 1000-4000 m depth
Abyssopelagic Zone: 4000-6000 m depth

Bathymetry data for Kosrae was sourced from most recent General Bathymetric Chart of the Oceans (GEBCO 2024 grid) and classified using the get_bathymetry() function from the oceandatr R package."




### Climate-smart spatial planning

Climate-smart spatial plans try to ensure that MPAs are robust to future impacts of climate change (Morelli et al., 2017; Pacifici et al., 2015). One way to do this is by preferentially placing MPAs in areas that retain their climates over long periods- i.e., in climate refugia (Arafeh-Dalmau et al., 2021). We represent climate refugia here by a climate-smart metric characterized by areas of low exposure to warming and slow climate velocity. We define the climate exposure that biodiversity could experience as the rate of climate warming in a planning unit (Δ ℃ yr\-1). We also define climate velocity as the speed of isotherm movement with warming (km yr\-1); the faster the velocity, the further biodiversity moves to cooler locations (Pinsky et al., 2013). Thus, planning units with slower velocity are more likely to retain biodiversity (Arafeh-Dalmau et al., 2021; Brito-Morales et al., 2022).  
  
Climate exposure and climate velocity are calculated from the ensemble median of depth-resolved model outputs from 17 Earth System Models for the planning region (Hausfather et al., 2022) forced under the most pessimistic emission scenario (SSP5-8.5; O'Neill et al., 2017). These two measures are then combined into a single climate-resilience metric, with higher metric values indicating greater climate resilience. Therefore, climate-resilient areas are likely to warm less and their biodiversity is more likely to be retained (see Buenafe et al. for more details; Brito-Morales et al., 2022).  
  
The climate-smart metric for each planning unit was then used in the Climate Priority Area Approach (see Buenafe et al., in review for more details). This approach separates the distribution of each feature into: 1) climate-priority areas (i.e., the highest values of the climate-resilience metric) and 2) non-climate-priority areas (i.e., the remainder). The Climate Priority Area Approach prioritizes the protection of core climate-resilient areas, while still affording some protection to the rest of the distribution (see Buenafe et al., in review for more details). We set a 100% target for the highest 5% of the climate-resilient metric values (climate-priority areas), and a lower target for the remaining 95% of the distribution (non-climate-priority areas) so that user-specified target for the whole species distribution is maintained (Buenafe et al., 2023). This approach is applied to each Important and Representative features. Thus, the prioritization preferentially places protected areas where there are higher values of the climate-resilience metric, whilst still meeting the biodiversity objectives and minimizing overlap with high cost areas.  
  
Note the climate-smart spatial plans are based on temperature change and did not consider future changes in pH or O2 concentration. This is because temperature is usually the main driver of biodiversity patterns (Chawarski et al. 2022), projections of temperature from Earth system models are more reliable than for other variables (Raäisaänen, 2007), and temperature-derived metrics are strongly related to changes in biodiversity under climate change (Burrows et al., 2014; Molinos et al. 2016).  
  

### Deriving cost layers

The minimum set objective function we used in the prioritization aims to meet the given targets whilst minimizing the impact on human use (fishing) by selecting particular planning units. We provide different cost layers, each of which provides an estimate of the plausible lost fishing (i.e., the opportunity cost) of locking up a planning unit in an MPA. The higher the cost  of a planning unit, the more the spatial plan will avoid it when selecting planning units for protection.
