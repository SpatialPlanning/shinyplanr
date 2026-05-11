# Introduction to Spatial Planning

This chapter provides the conceptual foundation for understanding
spatial prioritisation for both conservation and multiple-use planning.
We begin with the rationale for spatial planning, introduce systematic
approaches, explain how mathematical optimisation is used, and explore
modern advances including climate-smart planning, multiple-use zoning,
and ecosystem services.

## Why Spatial Planning?

The world’s ecosystems face unprecedented pressures from competing human
demands. Habitat loss, overexploitation, pollution, invasive species,
and climate change threaten biodiversity and the ecosystem services upon
which human societies depend. Simultaneously, growing global demands for
food, energy, minerals, infrastructure and water intensify competition
for limited space ([Neubert et al. 2025](#ref-neubert2025multipleuse)).

Marine environments, in particular, face growing demands from fishing,
shipping, aquaculture, renewable energy, mining, and tourism—all
competing for the same ocean space. Spatial planning offers a pathway to
address these dual challenges by:

- **Protecting biodiversity**: Identifying and safeguarding areas
  critical for species survival, migration, reproduction, and genetic
  diversity
- **Maintaining ecosystem services**: Ensuring continued provision of
  services such as carbon sequestration, coastal protection, fisheries
  production, and water filtration
- **Supporting sustainable development**: Allocating space for fishing,
  aquaculture, renewable energy, and other economic activities in
  suitable locations
- **Managing multiple uses**: Balancing competing demands on limited
  space by allocating areas to different activities based on their
  compatibility, value, and sustainability
- **Minimising conflicts**: Reducing use-use conflicts by spatially
  separating incompatible activities or identifying areas where
  co-location is possible
- **Achieving policy commitments**: Meeting national and international
  targets such as the Kunming-Montreal Global Biodiversity Framework’s
  goal of protecting 30% of land and sea by 2030, while supporting
  Sustainable Development Goals for economic growth and food security
- **Building resilience**: Designing spatial plans that can withstand
  and adapt to climate change and evolving socioeconomic conditions

Without deliberate spatial planning, development and resource use tend
to follow economic opportunity rather than ecological need. The result
is often fragmented habitats, depleted populations, and degraded
ecosystem services. Spatial planning provides a framework for making
informed, transparent decisions about where to focus conservation
efforts and how to allocate space among competing uses.

### The Conservation Challenge

Protected areas remain a cornerstone of conservation strategy. However,
simply designating more protected areas is not sufficient. We must
ensure that protected areas:

- **Represent all ecosystems**: Not just spectacular or accessible
  areas, but the full range of habitats and species
- **Are large enough**: Providing sufficient area for viable populations
  and ecological processes
- **Are connected**: Allowing species movement, gene flow, and climate
  adaptation
- **Persist over time**: With adequate management and enforcement
- **Complement other management**: Working alongside sustainable use and
  restoration efforts
- **Consider multiple uses**: Acknowledge that there are a range of
  pressures on our ecosystems that require managed access.

Achieving these goals requires moving beyond ad hoc decisions to
systematic, evidence-based planning.

## What is Spatial Prioritisation?

Spatial prioritisation is the process of identifying where actions
should be located to most efficiently achieve specified objectives.
Given limited resources and competing demands for space, it is
impossible to do everything, everywhere. Spatial prioritisation tools
help decision-makers strategically allocate space and investments.

The fundamental questions in spatial prioritisation depend on the
planning context:

**For conservation planning:**

> *Which areas should be protected to achieve biodiversity targets at
> minimum cost?*

**For sector allocation in multiple-use planning:**

> *Where should fishing, aquaculture, energy infrastructure, and
> protected areas be located to balance ecological, economic, and social
> objectives?*

**For zoning:**

> *How do we allocate planning units to different management zones
> (e.g., no-take reserves, sustainable fishing areas, aquaculture zones)
> to achieve multiple objectives simultaneously?*

### The Need for Systematic Approaches

Traditional approaches to spatial planning often relied on:

- **Ad hoc decisions**: Reacting to immediate pressures rather than
  strategic allocation
- **Single-sector focus**: Optimising for one use without considering
  others
- **Expert opinion alone**: Lacking transparent, repeatable methods
- **Opportunistic selection**: Protecting or allocating areas based on
  availability rather than strategic value

**For conservation planning specifically**, ad hoc approaches led to:

- **Inefficient use of resources**: Protecting areas that contribute
  little to overall conservation goals
- **Gaps in representation**: Failing to include areas important for
  less well-known species or habitats
- **Conflict with other uses**: Not accounting for economic or social
  costs
- **Lack of transparency**: Difficulty explaining or justifying
  decisions to stakeholders

**For multiple-use planning**, ad hoc approaches resulted in:

- **Use-use conflicts**: Fishing gear damaged by energy infrastructure,
  shipping disrupting whale migration
- **Suboptimal economic returns**: High-value activities excluded from
  most suitable areas
- **Environmental degradation**: Cumulative, unmanaged impacts from
  overlapping uses
- **Social inequity**: Industrial uses displacing small-scale fishers
  and traditional users

Systematic conservation planning ([Margules and Pressey
2000](#ref-margules2000systematic)) and multiple-use spatial planning
([Neubert et al. 2025](#ref-neubert2025multipleuse)) address these
limitations by using quantitative methods to identify priority areas
based on explicit objectives and constraints.

## Key Concepts

### Planning Units

The planning region is divided into discrete spatial units called
**planning units**. These can be:

- Regular grids (squares or hexagons)
- Existing administrative boundaries
- Ecological units (e.g., watersheds, habitat patches)

Each planning unit can be either *selected* (included in the spatial
plan) or *not selected*. In zoning problems, planning units are
allocated to different management zones rather than simply selected or
not. The goal of prioritisation is to determine which planning units to
select (or which zone to allocate them to).

### Features

**Features** are the spatial elements of interest in the planning
region. Depending on planning objectives, features can include:

- Species distributions (e.g., coral reef fish, seabirds, threatened
  species)
- Habitat types (e.g., seagrass beds, mangroves, coral reefs, spawning
  grounds)
- Depth zones (e.g., continental shelf, bathyal, abyssal)
- Geomorphological features (e.g., seamounts, ridges, canyons)
- Fisheries productivity (catch per unit area, spawning grounds, nursery
  habitats)
- Aquaculture suitability (temperature, depth, water quality, suitable
  sites)
- Renewable energy potential (wind speed, wave energy, tidal currents,
  solar radiation)
- Tourism value (scenic beauty, dive sites, wildlife viewing areas)
- Accessibility (distance to ports, proximity to markets, shipping
  routes)
- Ecosystem services (carbon storage, coastal protection, fisheries
  production, water filtration)
- Traditional use areas (subsistence fishing, cultural sites, community
  resources)
- Conflict zones (areas where multiple uses overlap or compete)

Each feature has a spatial distribution across planning units. In
**conservation planning**, features are elements to protect, and high
feature values indicate high conservation priority. In **multiple-use
planning**, features can represent suitability for different
activities—high values might indicate where fishing, aquaculture, or
energy generation would be most productive.

### Targets

**Targets** specify how much of each feature should be represented in
the spatial plan. Targets can be expressed as:

- **Absolute targets**: A specific amount (e.g., 1000 km² of seagrass
  habitat, 500 MW of wind energy capacity)
- **Relative targets**: A percentage of the total (e.g., 30% of each
  habitat type, 20% of high-productivity fishing grounds allocated to
  no-take reserves)

Setting appropriate targets is a critical step that should be informed
by:

- **Science**: Population viability requirements, minimum patch sizes,
  ecosystem thresholds
- **Policy**: International commitments (e.g., 30x30), national
  legislation, regional agreements
- **Stakeholder input**: Sectoral needs, community priorities, equity
  considerations

### Cost

**Cost** represents the expense or difficulty of including each planning
unit in the spatial plan. Cost can include:

- **Financial costs**: Land/sea acquisition, management expenses
- **Opportunity costs**: Foregone economic benefits (e.g., fishing
  revenue, agricultural production)
- **Social costs**: Displacement of communities or livelihoods
- **Proxy costs**: Distance from shore (as a surrogate for enforcement
  difficulty)
- **Sectoral costs**: Lost revenue to fishing, aquaculture, or tourism
  from area restrictions
- **Infrastructure costs**: Installation expenses for renewable energy,
  cable laying, port development
- **Conflict costs**: Incompatibility between uses (e.g., bottom
  trawling damages aquaculture gear)
- **Environmental costs**: Habitat damage, bycatch, pollution, carbon
  emissions

When no specific cost data are available, **equal area cost** assigns
the same cost to each planning unit, effectively minimising the total
area selected. Note that in multiple-use planning with zoning, different
zones may have different cost structures, reflecting the varying
implications of allocating areas to different management regimes.

### Constraints

**Constraints** are rules that must be satisfied by any valid solution:

- **Locked-in constraints**: Planning units that *must* be selected
  (e.g., existing protected areas)
- **Locked-out constraints**: Planning units that *cannot* be selected
  (e.g., shipping lanes, urban areas)

## Objective Functions

The **objective function** defines what the prioritisation algorithm is
trying to achieve. Different objectives suit different planning
contexts:

### Minimum Set Objective

The classic conservation planning objective:

> *Find the smallest set of planning units (lowest total cost) that
> meets all representation targets.*

This is ideal when targets are well-established and the goal is to
minimise resources (cost) required to achieve them. This objective is
also applicable in multiple-use contexts—for example, identifying the
minimum area needed for aquaculture to meet food security targets while
minimising conflict with other sectors.

### Minimum Shortfall Objective

When budgets are fixed:

> *Given a fixed budget, find the set of planning units that minimises
> the total shortfall from achieving targets across all features.*

This is useful when resources are limited and you want to make progress
towards all targets rather than fully achieving some whilst ignoring
others. In multiple-use planning, the “budget” might represent the total
area available for a particular sector, or a financial constraint on
development.

### Other Objectives

The *prioritizr* package supports additional objectives including:

- **Maximum coverage**: Maximise representation of features within a
  fixed budget
  - *Use case*: Maximise biodiversity representation within 30% area
    budget
  - *Use case*: Maximise wind energy generation within 500 km²
    allocation
- **Maximum utility**: Maximise the weighted sum of features represented
  - *Use case*: Prioritise high-value species or high-productivity
    fishing areas
- **Minimum largest shortfall**: Minimise the worst-case shortfall for
  any single feature
  - *Use case*: Ensure no single species or sector is disproportionately
    impacted

## Mathematical Optimisation

### The Integer Linear Programming Approach

Modern spatial prioritisation uses **integer linear programming (ILP)**
to find optimal solutions. Unlike heuristic approaches (such as
simulated annealing used in *Marxan*), ILP solvers are guaranteed to
find the globally optimal solution.

The *prioritizr* R package ([Hanson et al.
2025](#ref-hanson2025prioritizr)) provides a flexible interface for
building and solving conservation planning problems using ILP. It
supports multiple commercial and open-source solvers including:

- **Gurobi** (commercial, fastest for large problems)
- **IBM CPLEX** (commercial)
- **HiGHS** (open-source, recommended default)
- **CBC** (open-source)

### Advantages Over Heuristic Methods

| Aspect          | ILP (*prioritizr*) | Heuristics (*Marxan*) |
|-----------------|--------------------|-----------------------|
| Optimality      | Guaranteed optimal | Near-optimal          |
| Speed           | Often faster       | Variable              |
| Reproducibility | Deterministic      | Stochastic            |
| Flexibility     | Highly flexible    | More constrained      |

## Climate-Smart Spatial Planning

Climate change poses fundamental challenges to both conservation and
multiple-use planning. Species distributions are shifting, habitats are
degrading, and historical baselines may no longer represent future
conditions. Simultaneously, climate change affects the productivity and
suitability of areas for human uses such as fisheries and aquaculture.
**Climate-smart spatial planning** explicitly incorporates climate
change considerations into prioritisation to ensure plans remain
effective under future conditions ([Buenafe et al.
2025](#ref-buenafe2025climatesmart)).

### Why Climate-Smart Planning Matters

Traditional spatial planning assumes that features remain static within
planning units. However:

**For biodiversity:**

- Species are shifting their ranges poleward and to deeper waters
- Coral reefs and other habitats are experiencing mass mortality events
- Ocean temperatures, chemistry, and currents are changing
- Protected area networks designed for today’s distributions may become
  ineffective as species move

**For economic activities:**

- Fisheries productivity is shifting with changing ocean conditions
- Aquaculture suitability is changing (temperature, oxygen, disease
  risk)
- Extreme weather events threaten infrastructure (ports, offshore
  installations)
- Traditional fishing grounds may become less productive or shift
  location

Climate-smart planning ensures that spatial allocations—whether for
conservation or economic use—remain viable and effective under future
climate scenarios. Climate-smart planning can be implemented through
several approaches but in *shinyplanr*, users can select climate layers
that preferentially weight refugia areas.

**Climate refugia** are areas that are expected to experience less
climate change impact and may serve as safe havens for biodiversity.
These can be identified using:

- Projected temperature anomalies
- Climate velocity (the speed at which conditions shift spatially)
- Habitat stability metrics
- Ensemble model projections

Given uncertainty in climate projections, robust planning aims to find
solutions that perform well across multiple climate scenarios rather
than optimising for a single projection.

## Multiple-Use Spatial Planning

Conservation does not occur in isolation. Marine and terrestrial
environments support multiple human activities including fishing,
shipping, tourism, renewable energy, aquaculture, and extractive
industries. Rather than viewing conservation and resource use as
competing objectives, **multiple-use spatial planning** seeks to balance
biodiversity protection with sustainable economic activities, creating
spatial plans where sectors coexist or are strategically separated based
on compatibility ([Neubert et al. 2025](#ref-neubert2025multipleuse)).

### The Marine Context

Marine environments are particularly suited to multiple-use planning due
to their three-dimensional structure and the potential for compatible
activities to co-locate. However, they also face intense competition for
space:

**Growing demands include:**

- **Food security**: Expanding commercial and artisanal fisheries,
  aquaculture development
- **Energy transition**: Offshore wind farms, wave energy, tidal energy
  installations
- **Economic development**: Shipping lanes, ports, submarine cables,
  potential seabed mining
- **Tourism and recreation**: Diving, whale watching, recreational
  fishing, coastal tourism
- **Conservation**: Marine protected areas, species recovery programs,
  ecosystem restoration
- **Traditional uses**: Subsistence fishing, cultural sites, indigenous
  rights and territories

### The Challenge of Multiple Objectives

Different stakeholder groups have competing but often legitimate
objectives:

- **Conservation sector**: Maximise biodiversity protection, achieve
  30x30 targets
- **Fishing industry**: Maintain access to productive fishing grounds,
  sustain catch levels
- **Aquaculture**: Secure suitable sites for expansion, disease
  management zones
- **Renewable energy**: Achieve climate targets through offshore wind
  and other installations
- **Tourism**: Provide access to attractive areas for wildlife viewing
  and recreational activities
- **Shipping**: Maintain efficient transport routes, minimise transit
  times and costs
- **Local communities**: Preserve cultural sites, subsistence uses,
  traditional rights

These objectives often conflict—an area optimal for conservation may
also be:

- The most productive fishing ground
- The best location for wind farms (high energy potential)
- A critical shipping route
- An important tourism destination

**Multiple-use planning addresses these conflicts** through systematic
allocation that balances ecological, economic, and social goals.

### Approaches to Multiple-Use Optimisation

Following Neubert et al. ([2025](#ref-neubert2025multipleuse)), there
are four main approaches to incorporating multiple uses in spatial
optimisation:

#### 1. Composite Costs

Aggregate multiple uses into a single cost metric that the optimisation
minimises while meeting conservation targets.

**Example**:
`Cost = 0.4 × fishing_effort + 0.4 × aquaculture_suitability + 0.2 × shipping_density`

**Advantages**: Simple, computationally efficient, easy to communicate

**Limitations**: Can obscure sector-specific impacts, sensitive to
weighting choices

#### 2. Constraints

Set sector-specific budget limits or exclude certain areas from
consideration.

**Example**: Meet conservation targets while ensuring fishing revenue
loss \< \$5M, and locking out shipping lanes

**Advantages**: Each sector considered separately, more control over
impacts

**Limitations**: Requires detailed sector-specific data, harder to
communicate

#### 3. Zoning

Allocate planning units to different management zones with distinct
objectives.

**Example zones:**

- **No-take marine reserve**: Biodiversity protection, research
- **Sustainable fishing zone**: Managed fishing, no bottom trawling
- **Aquaculture zone**: Fish farming, shellfish cultivation
- **Renewable energy zone**: Wind farms with compatible uses
- **General use zone**: Multiple compatible activities

**Advantages**: Sectoral clarity, reduces conflicts, widely used in
practice

**Limitations**: Requires substantial data, complex to configure, high
computational demands

#### 4. Multi-objective Optimisation

Simultaneously optimise multiple objective functions (e.g., maximise
conservation AND maximise fishing value).

**Advantages**: Comprehensive trade-off analysis, flexible

**Limitations**: Very complex, requires advanced expertise, not yet
widely accessible

*shinyplanr* primarily uses **approaches 1 and 2** (composite costs and
constraints), with **approach 3** (zoning) possible through custom
configuration of *prioritizr*. Approach 4 (multi-objective optimisation)
is not currently implemented but represents a future development
direction.

### Zoning in Detail

**Zoning** is one of the most accessible and widely-used methods for
multiple-use planning. Rather than binary selection (protect vs. don’t
protect), zoning assigns each planning unit to a management zone with
specific allowed and prohibited uses.

**Key benefits:**

- **Clarity**: Each sector knows where they can and cannot operate
- **Conflict reduction**: Incompatible uses are spatially separated
- **Flexibility**: Different levels of protection and use intensity
- **Stakeholder buy-in**: All sectors get designated areas

**Compatible uses** that can coexist in the same zone:

- Offshore wind + no-take marine reserves (turbine foundations can act
  as artificial reefs)
- Sustainable fishing + tourism (recreational diving, charter fishing)
- Aquaculture + some fishing methods (if spatially managed to avoid gear
  conflicts)

**Incompatible uses** that should be separated:

- Bottom trawling + aquaculture (gear conflicts, habitat disturbance)
- Shipping lanes + offshore wind farms (collision risk)
- No-take reserves + extractive fishing activities

The *prioritizr* package supports sophisticated zoning through its zones
functionality. Each zone can have distinct features, targets, costs, and
constraints, allowing simultaneous optimisation across all zones to find
the best overall allocation.

### Balancing Trade-offs

Multiple-use planning requires explicit consideration of trade-offs:

1.  **Identifying stakeholder objectives**: What does each sector want
    to achieve?
2.  **Mapping activities**: Where do different uses currently occur or
    could occur?
3.  **Quantifying impacts**: How do uses affect each other and
    biodiversity?
4.  **Assessing compatibility**: Which uses can coexist? Which conflict?
5.  **Exploring scenarios**: What happens under different allocation
    schemes?
6.  **Evaluating equity**: Who benefits? Who bears costs? Is the
    distribution fair?
7.  **Negotiating solutions**: Finding compromises acceptable to
    stakeholders

*shinyplanr* supports exploring these trade-offs by allowing users to:

- Use different cost layers representing sectoral impacts (fishing
  effort, aquaculture displacement, shipping density)
- Apply constraints limiting impacts on specific sectors (budget
  constraints, locked-out areas)
- Lock out areas with infrastructure or incompatible uses (shipping
  lanes, existing installations)
- Compare scenarios with different configurations side-by-side
- Visualise how parameter changes affect different stakeholder groups
- Download results for further analysis and stakeholder engagement

### Data for Multiple-Use Planning

Understanding current and potential ocean uses requires spatial data on
human activities:

- Fishing effort by gear type (trawl, longline, purse seine, artisanal)
- Catch and revenue per area
- Aquaculture sites and suitability maps
- Potential mining areas and mineral deposits
- Shipping vessel density and routes
- Ports and anchorage areas
- Submarine cables and pipelines
- Existing offshore structures
- Wind speed and consistency
- Wave energy potential
- Tidal currents
- Bathymetry and seabed conditions
- Dive sites and visitor numbers
- Whale watching areas and seasonality
- Recreational fishing effort
- Coastal access points
- Subsistence fishing areas
- Cultural heritage sites
- Indigenous marine territories
- Community resource use patterns

## Ecosystem Services

**Ecosystem services** are the benefits that humans derive from
ecosystems. Incorporating ecosystem services into spatial planning
allows conservation to contribute to human well-being alongside
biodiversity protection ([Dabalà et al.
2023](#ref-dabala2023mangroves)).

### Categories of Ecosystem Services

1.  **Provisioning services**: Products obtained from ecosystems
    - Fisheries production
    - Timber and fibre
    - Fresh water
    - Genetic resources
2.  **Regulating services**: Benefits from ecosystem processes
    - Carbon sequestration and storage
    - Coastal protection from storms and erosion
    - Water purification
    - Climate regulation
3.  **Cultural services**: Non-material benefits
    - Recreation and tourism
    - Spiritual and religious values
    - Aesthetic appreciation
    - Educational value
4.  **Supporting services**: Necessary for other services
    - Nutrient cycling
    - Primary production
    - Habitat provision

### Quantifying Ecosystem Services

Ecosystem services can be represented spatially through:

- **Biophysical models**: Carbon stocks, fish biomass, coastal
  protection capacity
- **Economic valuation**: Dollar value of services per area (e.g.,
  fisheries production value, carbon sequestration value, tourism
  revenue)
- **Indicator species**: Presence of species associated with services
  (e.g., commercial fish species, pollinator species)
- **Habitat proxies**: Area of habitat types known to provide services
  (e.g., mangroves for coastal protection and carbon storage, seagrass
  for fisheries nurseries, coral reefs for tourism and biodiversity)

By including ecosystem service layers in prioritisation, planners can
identify areas that simultaneously protect biodiversity and maximise
benefits to human communities. For example, protecting mangrove
ecosystems can deliver multiple services: carbon storage, coastal
protection from storms and erosion, critical nursery habitat for
fisheries, and biodiversity conservation ([Dabalà et al.
2023](#ref-dabala2023mangroves)). This multi-benefit approach
strengthens the case for conservation by demonstrating tangible value to
stakeholders.

## Summary

Modern spatial prioritisation for conservation and multiple-use planning
combines:

- **Systematic methods** that are transparent, repeatable, and efficient
- **Mathematical optimisation** that guarantees optimal solutions
- **Climate-smart approaches** that account for changing conditions and
  future uncertainty
- **Multiple-use perspectives** that balance conservation with
  sustainable economic activities
- **Ecosystem services** that connect ecological function to human
  well-being
- **Stakeholder engagement** that ensures equitable and legitimate
  planning processes

*shinyplanr* brings these capabilities to stakeholders through an
accessible web interface. Whether you are designing protected area
networks, planning marine spatial allocations, or exploring trade-offs
between conservation and development, *shinyplanr* provides the tools
for systematic, evidence-based spatial planning.

The [Using shinyplanr
vignette](https://spatialplanning.github.io/shinyplanr/articles/ab-using-shinyplanr.md)
explains how to use *shinyplanr* to explore spatial planning scenarios,
and the [Setting Up
vignette](https://spatialplanning.github.io/shinyplanr/articles/ac-setting-up.md)
explains how to set up *shinyplanr* for new regions.

## Further Reading

**Systematic conservation planning:**

- [*prioritizr* website](https://prioritizr.net): Comprehensive
  documentation and tutorials
- [*spatialplanr*
  package](https://spatialplanning.github.io/spatialplanr/): Tools for
  climate-smart planning
- Margules and Pressey ([2000](#ref-margules2000systematic)): The
  foundational paper on systematic conservation planning
- Jones et al. ([2016](#ref-jones2016incorporating)): Review of climate
  change in spatial prioritisation

**Multiple-use spatial planning:**

- Neubert et al. ([2025](#ref-neubert2025multipleuse)): Comprehensive
  review of multiple-use planning methods and challenges
- Watts et al. ([2009](#ref-watts2009marxan)): Marxan with Zones for
  multiple-use planning

Buenafe, Kristine Camille V, Daniel C Dunn, Anna Metaxas, David S
Schoeman, Jason D Everett, Alice Pidd, Jeffrey O Hanson, et al. 2025.
“Current Approaches and Future Opportunities for Climate-Smart Protected
Areas.” *Nature Reviews Earth and Environment*.
<https://doi.org/10.1038/s44358-025-00041-0>.

Dabalà, Alvise, Farid Dahdouh-Guebas, Daniel C Dunn, Jason D Everett,
Catherine E Lovelock, Jeffrey O Hanson, Kristine Camille V Buenafe,
Sandra Neubert, and Anthony J Richardson. 2023. “Priority Areas to
Protect Mangroves and Maximise Ecosystem Services.” *Nature
Communications* 14: 5863. <https://doi.org/10.1038/s41467-023-41333-3>.

Hanson, Jeffrey O, Richard Schuster, Matthew Strimas-Mackey, Nina
Morrell, Brandon PM Edwards, Peter Arcese, Joseph R Bennett, and Hugh P
Possingham. 2025. “Systematic Conservation Prioritization with the
Prioritizr r Package.” *Conservation Biology* 39: e14376.
<https://doi.org/10.1111/cobi.14376>.

Jones, Kendall R, James EM Watson, Hugh P Possingham, and Carissa J
Klein. 2016. “Incorporating Climate Change into Spatial Conservation
Prioritisation: A Review.” *Biological Conservation* 194: 121–30.

Margules, Christopher R, and Robert L Pressey. 2000. “Systematic
Conservation Planning.” *Nature* 405 (6783): 243–53.

Neubert, Sandra, Jennifer McGowan, Kristian Metcalfe, Jeffrey O Hanson,
Kristine Camille V Buenafe, Alvise Dabalà, Daniel C Dunn, et al. 2025.
“Multiple-Use Spatial Planning for Sustainable Development and
Conservation.” *Trends in Ecology and Evolution*.
<https://doi.org/10.1016/j.tree.2025.09.007>.

Watts, Matthew E, Ian R Ball, Romola S Stewart, Carissa J Klein, Kerrie
Wilson, Charles Steinback, Reinaldo Lourival, Lindsay Kircher, and Hugh
P Possingham. 2009. “Marxan with Zones: Software for Optimal
Conservation Based Land-and Sea-Use Zoning.” *Environmental Modelling &
Software* 24 (12): 1513–21.
