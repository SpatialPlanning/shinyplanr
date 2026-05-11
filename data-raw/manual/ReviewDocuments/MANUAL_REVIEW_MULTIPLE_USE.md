# shinyplanr Manual: Multiple-Use Spatial Planning Gap Analysis

**Supplementary Review**  
**Focus**: Addressing conservation bias and incorporating multiple-use planning perspectives  
**Reference**: Neubert et al. (2025) "Multiple-use spatial planning for sustainable development and conservation" *Trends in Ecology & Evolution*

---

## Executive Summary

The current shinyplanr manual has a **significant conservation bias** that does not reflect the tool's full capability for multiple-use spatial planning. While the manual mentions multiple-use planning (particularly in §1.6), it treats it as a secondary consideration rather than a co-equal application alongside conservation planning.

**Critical Issue**: The marine environment is increasingly characterized by competing demands for space (fishing, aquaculture, renewable energy, shipping, tourism, conservation), yet the manual predominantly frames shinyplanr as a "conservation prioritisation" tool rather than a "spatial planning" tool for balancing multiple objectives.

**Impact**: This framing may:
- Limit adoption by marine spatial planning practitioners
- Discourage use in blue economy contexts
- Miss opportunities for stakeholder engagement across sectors
- Underrepresent prioritizr's zones functionality

---

## Key Insights from Neubert et al. (2025)

### 1. Multiple-Use is the Norm in Marine Planning

The paper emphasizes that **marine spatial planning predominantly employs multiple-use planning**, not just conservation:

> "Marine research predominantly employs multiple-use planning, using zoning approaches to minimize conflicts and promote coexistence"

This contrasts with terrestrial planning which focuses more on trade-offs between protected areas and other land uses.

### 2. Terminology Matters

The paper highlights inconsistent terminology across fields:
- **Multiple-use (spatial) planning**: Including multiple sectors (not just conservation)
- **Multi-objective planning**: Multiple goals/objectives (could be conservation-focused OR multi-sectoral)
- **Zoning**: Management zones with different allowed uses
- **Co-location**: Multiple activities in same space/time

The manual should adopt this clearer terminology.

### 3. Four Optimization Approaches for Multiple Uses

The paper describes four approaches (all supported by prioritizr):

1. **Composite costs**: Aggregate multiple uses into single cost metric
2. **Constraints**: Set sector-specific budget limits or lock-in/lock-out areas
3. **Zones**: Allocate different management actions to different zones
4. **Multi-objective optimization**: Multiple objective functions simultaneously

The manual barely touches on approaches 3 and 4, despite prioritizr having strong zones support.

### 4. Conservation AND Development

Key quote:
> "Growing global demands for food, energy, and resources drive competition for space while increasing pressure on natural systems, highlighting the need to balance sustainable resource use with biodiversity conservation."

The manual should frame shinyplanr as supporting this balance, not just conservation.

---

## Current Manual Gaps - Section by Section

### Index.qmd (Preface)

**Current Language:**
- "systematic conservation planning"
- "conservation prioritisation"
- "biodiversity features"
- "protected areas"

**Missing:**
- Multiple-use spatial planning context
- Blue economy applications
- Sector balancing (fishing, aquaculture, energy)
- Economic development alongside conservation

**Recommendation:**
```markdown
## What is shinyplanr? {.unnumbered}

*shinyplanr* is a Shiny application designed to make **spatial planning** accessible 
to stakeholders, managers, and researchers. Built on the *prioritizr* optimization 
engine, it supports both **conservation prioritisation** and **multiple-use spatial 
planning** for terrestrial and marine environments.

The tool allows users to:

- **Balance multiple objectives** including biodiversity conservation, sustainable 
  fisheries, renewable energy development, and economic activities
- **Design zoning schemes** that allocate space among compatible uses while 
  minimizing conflicts
- **Explore trade-offs** between conservation and development scenarios
- **Incorporate real-world constraints** such as existing protected areas, fishing 
  grounds, shipping lanes, and areas designated for development
- **Consider economic costs** to find efficient solutions that balance ecological 
  and economic goals
- **Evaluate climate-smart options** for robust, future-proof planning
```

### Chapter 1: Introduction

**Current Problem:**

The chapter is titled "Introduction to Spatial Planning" but immediately pivots to conservation:

Line 6-9:
> "Spatial planning offers a pathway to address these challenges by:
> - **Protecting biodiversity**..."

All bullet points are conservation-framed. No mention of:
- Sustainable fisheries management
- Aquaculture site selection
- Offshore wind farm placement
- Shipping lane optimization
- Tourism development

**Section 1.6 "Multiple-Use Spatial Planning" (lines 206-261)**

While this section exists, it:
1. Appears AFTER 200 lines of pure conservation framing
2. Is only 55 lines (10% of chapter)
3. Treats multiple-use as "addition" to conservation rather than co-equal application
4. Doesn't provide concrete examples of shinyplanr being used this way

**Recommendation: Major Restructuring Required**

#### Option A: Reframe Entire Chapter (Preferred)

Change chapter structure to:
1. Why Spatial Planning? (NEUTRAL - conservation AND development pressures)
2. What is Spatial Prioritisation? (NEUTRAL - multiple objectives)
3. Key Concepts (NEUTRAL)
4. **Applications**:
   - a. Conservation Planning (30x30, protected areas)
   - b. Multiple-Use Planning (fisheries, aquaculture, renewable energy)
   - c. Climate-Smart Planning (both conservation and development)
   - d. Ecosystem Services (benefits for people and nature)

#### Option B: Add Multiple-Use Examples Throughout (Minimum Change)

Insert multiple-use examples in parallel with conservation examples:

**Current (Line 66-75):**
```markdown
### Features

**Features** are the elements of biodiversity or ecosystem values that we wish 
to conserve. Examples include:

- Species distributions (e.g., coral reef fish, seabirds)
- Habitat types (e.g., seagrass beds, mangroves, coral reefs)
- Depth zones (e.g., continental shelf, bathyal, abyssal)
```

**Revised:**
```markdown
### Features

**Features** are the spatial elements of interest in the planning region. 
Depending on planning objectives, features can include:

**Conservation Features:**
- Species distributions (e.g., coral reef fish, seabirds, threatened species)
- Critical habitats (e.g., seagrass beds, mangroves, coral reefs, spawning grounds)
- Ecosystem types (e.g., depth zones, geomorphological features)

**Economic/Development Features:**
- Fisheries productivity (catch per unit area, key fishing grounds)
- Aquaculture suitability (temperature, depth, water quality)
- Renewable energy potential (wind speed, wave energy, tidal currents)
- Tourism value (scenic beauty, dive sites, whale watching areas)
- Shipping efficiency (proximity to ports, vessel traffic density)

**Social/Cultural Features:**
- Traditional fishing areas
- Cultural heritage sites
- Recreational use areas
- Community subsistence zones

In **conservation planning**, features are elements to protect. In **multiple-use 
planning**, features can represent areas to protect, develop, OR allocate to 
specific uses through zoning.
```

### Chapter 2: Using the Application

**Current Problem:**

The walkthrough assumes pure conservation workflow:
- "Set conservation targets"
- "Minimize cost to fisheries" (fisheries as CONSTRAINT only, never as objective)
- No examples of planning FOR fishing zones or aquaculture sites

**Missing Use Cases:**

1. **Fisheries Management Scenario**: Identify sustainable fishing zones that:
   - Protect spawning areas (locked out)
   - Maintain viable fishing grounds (feature = fisheries value)
   - Connect to processing facilities (cost = distance to ports)
   - Avoid marine mammal feeding areas

2. **Offshore Renewable Energy**: Select wind farm sites that:
   - Maximize energy generation (feature = wind speed/capacity)
   - Minimize impact on fishing (cost = fishing effort)
   - Avoid shipping lanes (locked out)
   - Consider distance to grid connection (cost)

3. **Aquaculture Zoning**: Allocate space for aquaculture that:
   - Has suitable environmental conditions (features = depth, temperature, currents)
   - Minimizes conflict with conservation areas (constraints)
   - Maintains access for traditional fishing (zoning)
   - Considers disease management (spatial separation requirements)

4. **Integrated Zoning Plan**: Create multi-zone plan with:
   - No-take marine reserves (Zone 1)
   - Sustainable fishing areas (Zone 2)
   - Aquaculture development zones (Zone 3)
   - Multiple-use/general use areas (Zone 4)

**Recommendation:**

Add a new section: **§2.8 Multiple-Use Planning Workflows**

Include 2-3 complete examples showing how to:
- Set up zoning problems in the app
- Interpret results when balancing multiple sectors
- Use cost layers to represent sector conflicts (not just minimize impact)
- Explain trade-offs to stakeholders

### Chapter 3: Setting Up

**Current Problem:**

The setup chapter assumes you're building conservation-focused apps:
- Features are "biodiversity features"
- Costs are "opportunity costs to be minimized"
- No guidance on setting up multiple-objective or zoned planning problems

**Missing:**

1. **How to set up prioritizr zones** in the app configuration
2. **How to structure data** for multiple-use planning
3. **How to define features** that represent development potential (not just conservation value)
4. **How to frame objectives** beyond conservation targets

**Recommendation:**

Add new subsection: **§3.7 Configuring for Multiple-Use Planning**

```markdown
## Configuring for Multiple-Use Planning {#sec-config-multiuse}

### When to Use Zoning vs. Single-Zone Planning

**Single-zone planning** (current default):
- One management action (e.g., "protect" or "don't protect")
- Best for: Pure conservation planning, simple yes/no decisions
- Example: Identifying marine protected area network

**Multi-zone planning** (requires prioritizr zones):
- Multiple management zones with different allowed uses
- Best for: Marine spatial planning, balancing multiple sectors
- Example: Allocating space among no-take reserves, fishing zones, 
  aquaculture areas, and shipping lanes

### Setting Up Zoned Planning

Currently, shinyplanr does not have built-in UI support for prioritizr's 
zones functionality. However, you can modify the underlying code to enable 
zoning. Future versions will include zone configuration in the UI.

**Data Structure for Zones:**

```r
# Define zones
zones_definition <- zones(
  "No-Take MPA",
  "Sustainable Fishing", 
  "Aquaculture",
  "General Use"
)

# Zone-specific costs
# Each zone needs its own cost column
dat_sf$Cost_NoTake <- ... # Cost of designating as MPA
dat_sf$Cost_Fishing <- ... # Cost to fishing sector
dat_sf$Cost_Aquaculture <- ... # Aquaculture development cost
dat_sf$Cost_GeneralUse <- 0 # No restrictions

# Zone-specific targets
# Rows = features, Columns = zones
# Example: Coral reefs should be in no-take or general use, not fishing/aquaculture
targets_matrix <- matrix(...)
```

### Framing Features for Different Objectives

**Conservation objective**: Features are biodiversity elements to protect
- High feature value = high conservation priority
- Target = % to protect

**Development objective**: Features are suitability/potential
- High feature value = high development potential
- Target = amount to allocate for development

**Example: Aquaculture Suitability**

```r
# Aquaculture suitability as a feature
dat_sf$aqua_suitability <- calculate_aqua_suitability(
  depth = dat_sf$bathymetry,
  temperature = dat_sf$sst,
  currents = dat_sf$current_speed,
  conflicts = dat_sf$conservation_value
)

# In Dict_Feature.csv
# nameCommon: "Aquaculture Suitable Areas"
# type: "Feature"
# targetInitial: 20  # Allocate 20% of suitable areas for aquaculture
```

This represents "where should we allow/promote aquaculture" rather than 
"where should we exclude aquaculture."
```

---

## Specific Language Changes Required

### Replace Conservation-Centric Language

| **Current Language** | **Replacement** | **Rationale** |
|---------------------|-----------------|---------------|
| "conservation prioritisation" | "spatial prioritisation" or "spatial planning" | Broader applicability |
| "biodiversity features" | "features" or "spatial features" | Can include economic features |
| "protected area network" | "spatial plan" or "management zones" | Not always about protection |
| "minimize cost" | "optimize objective" | Can be maximize OR minimize |
| "conservation targets" | "targets" or "objectives" | Can be for any sector |
| "opportunity cost" | "cost" | Can be direct costs too |
| "species to protect" | "species of interest" | Might want to manage, not just protect |

### Add Multiple-Use Terminology

Throughout manual, introduce and use:
- **Multiple-use planning**: Planning that includes multiple sectors
- **Zoning**: Allocating different areas to different uses
- **Co-location**: Compatible activities in same space
- **Trade-offs**: Balancing competing objectives
- **Sectoral objectives**: Goals specific to fishing, aquaculture, energy, etc.
- **Blue economy**: Sustainable ocean economic development

---

## Recommended New Content Sections

### Addition 1: Multiple-Use Planning Primer (Chapter 1)

Add after current §1.2:

```markdown
## Conservation and Development in Spatial Planning {#sec-conservation-development}

Modern spatial planning addresses the dual challenge of conserving nature while 
supporting sustainable development. This is particularly critical in marine 
environments, where space is contested by multiple sectors:

### Competing Ocean Uses

**Extractive Uses:**
- **Commercial fishing**: Industrial fleets, trawling, longlining
- **Small-scale fishing**: Artisanal, subsistence, recreational
- **Aquaculture**: Finfish farms, shellfish cultivation, seaweed farming
- **Mining**: Seabed minerals, oil & gas extraction
- **Aggregate extraction**: Sand and gravel for construction

**Infrastructure & Transport:**
- **Shipping lanes**: Cargo vessels, tankers, cruise ships
- **Ports & harbors**: Loading facilities, anchorages
- **Cables & pipelines**: Telecommunications, energy transport
- **Offshore renewable energy**: Wind farms, wave energy, tidal energy

**Recreation & Tourism:**
- **Wildlife tourism**: Whale watching, diving, snorkeling
- **Recreational fishing**: Charter boats, shore-based
- **Water sports**: Sailing, surfing, kite surfing

**Conservation & Protection:**
- **Marine protected areas**: No-take reserves, sanctuaries
- **Species protection**: Critical habitats, migration corridors
- **Ecosystem restoration**: Reef restoration, seagrass replanting

### The Role of Spatial Optimization

Without spatial planning, these uses compete for space leading to:
- **Use-use conflicts**: Fishing vs. wind farms, shipping vs. whale migration
- **Environmental degradation**: Overfishing, habitat destruction, pollution
- **Inefficient allocation**: High-value uses excluded from suitable areas
- **Social inequity**: Industrial uses displacing small-scale users

**Spatial optimization helps by:**
1. **Identifying compatible uses** that can co-locate (e.g., aquaculture with marine 
   tourism, fishing with some renewable energy)
2. **Minimizing conflicts** by spatially separating incompatible activities
3. **Maximizing benefits** for multiple sectors simultaneously
4. **Ensuring sustainability** by maintaining ecological function
5. **Promoting equity** by considering all stakeholders

### Two Paradigms of Use

**Conservation Planning Paradigm:**
- Primary objective: Protect biodiversity
- Other uses: Constraints to minimize impact
- Question: "Where should we protect, given economic constraints?"

**Multiple-Use Planning Paradigm:**
- Primary objective: Optimize allocation across all sectors
- Conservation: One of several objectives
- Question: "How do we share space among fishing, energy, tourism, AND conservation?"

**shinyplanr supports both paradigms** through different problem formulations.
```

### Addition 2: Zoning Explained (Chapter 2)

Add new section in Chapter 2:

```markdown
## Understanding Zoning in Marine Spatial Planning {#sec-zoning-explained}

When enabled in the application, **zoning functionality** allows you to create 
plans with multiple management zones, each with different allowed uses and 
objectives.

### How Zones Work

Instead of binary selection (select/don't select), zoning assigns each planning 
unit to one of several management zones:

**Example: Four-Zone Marine Plan**

| Zone | Allowed Uses | Not Allowed | Example Areas |
|------|-------------|-------------|---------------|
| **No-Take MPA** | Research, tourism (non-extractive) | Fishing, development | Coral spawning aggregations |
| **Sustainable Fishing** | Fishing (managed), tourism | Bottom trawling, aquaculture | Historical fishing grounds |
| **Aquaculture Development** | Fish farming, shellfish cultivation | Fishing (exclusion zone) | Sheltered bays with suitable conditions |
| **General Use** | Most activities with regulation | Destructive practices | Deeper waters, transit areas |

### Benefits of Zoning

1. **Sectoral clarity**: Each sector knows where they can operate
2. **Reduced conflict**: Incompatible uses spatially separated
3. **Flexibility**: Different levels of protection/use
4. **Stakeholder buy-in**: Each sector gets designated areas

### Zoning in prioritizr

The prioritizr package supports sophisticated zoning through:
- Zone-specific features and targets
- Zone-specific costs
- Constraints on zone allocation
- Optimization across all zones simultaneously

**Current shinyplanr limitation**: Full zoning UI not yet implemented. Contact 
developers if you need multi-zone capability.
```

### Addition 3: Use Case Examples (Chapter 2)

Replace or supplement current "Your First Analysis" tutorial with multiple examples:

```markdown
## Use Case: Offshore Wind Farm Siting {#sec-usecase-wind}

**Scenario**: Government seeks to allocate 500 km² for offshore wind development 
while minimizing environmental and fisheries impacts.

**Approach**: Use maximum coverage objective with budget constraint.

**Features** (areas to INCLUDE in wind zones):
- High wind speed areas
- Suitable depth (< 50m for fixed turbines)
- Proximity to grid connection points

**Costs** (to minimize):
- Fishing effort (minimize displacement of fishers)
- Seabird foraging areas (minimize turbine collision risk)
- Distance to shore (minimize cable costs)

**Constraints**:
- Lock out: Marine mammal migration corridors, shipping lanes
- Lock in: None (identify new sites)

**Objective**: Maximize wind energy potential within 500 km² budget while 
minimizing fisheries and environmental costs.

**Analysis Steps**:
1. Set targets high for wind suitability features (maximize coverage)
2. Select composite cost: (0.4 × fishing_effort + 0.4 × seabird_density + 0.2 × distance)
3. Set budget = 500 km² (or equivalent cost units)
4. Lock out sensitive areas
5. Run analysis
6. Interpret: Where can we site wind farms with least conflict?
```

---

## Critical Missing: Real-World Examples

The manual needs at least 2-3 detailed case studies showing:

### Case Study 1: Balancing Fishing and Conservation in Fiji

**Context**: Fiji's inshore fisheries are declining. Government wants to:
- Establish 30% no-take MPAs for reef recovery
- Maintain access to traditional fishing grounds
- Protect spawning aggregation sites absolutely
- Consider tourism value (reef diving)

**Approach**: Zoning with trade-off analysis

**Zones**:
1. No-take MPA (30% target across habitats)
2. Traditional fishing (minimize displacement of small-scale fishers)
3. Commercial fishing (industrial fleet areas)
4. General use

**Features**: Coral cover, fish diversity, spawning sites, mangroves

**Costs**: 
- Zone 1 (MPA): Foregone fishing revenue
- Zone 2: Low (maintain traditional access)
- Zone 3: Moderate (some fishing maintained)

**Results**: Map showing how to achieve 30% protection while:
- Minimizing impact on subsistence fishing
- Creating spatial management framework
- Identifying areas for different fishing sectors

### Case Study 2: Southeast Australia Multi-Sector Planning

**Context**: Multiple competing uses in same ocean space:
- Offshore wind energy targets (climate goals)
- Commercial fishing (multi-billion dollar industry)
- Aquaculture expansion (food security)
- Tourism (whale migration, diving)
- Conservation (threatened species, ecosystems)

**Approach**: Multi-objective optimization with constraints

**Objectives**:
1. Meet renewable energy targets (15 GW offshore wind)
2. Maintain >80% of current fisheries value
3. Protect 30% of each ecosystem type
4. Enable aquaculture growth (20,000 ha)

**Solution**: Pareto front showing trade-offs, with scenario comparison

**Insights**:
- Which objectives are most compatible?
- What's the cost of increasing conservation from 20% to 30%?
- Where can sectors co-locate?
- Which areas are irreplaceable for which sectors?

---

## Implementation Priority

Given your request for this "not to be a large focus, but to be mentioned/considered," I recommend:

### Minimal Changes (Quick Implementation)

1. **Index.qmd**: Add 1-2 sentences in "What is shinyplanr?" about multiple-use applications
2. **Chapter 1**: 
   - Change section title to "Conservation and Multiple-Use Planning"
   - Add 2-3 paragraphs before diving into conservation specifics
   - Add examples of economic features alongside biodiversity features
3. **Chapter 2**: 
   - Add 1 callout box about multiple-use scenarios
   - Modify 1-2 examples to show fisheries/aquaculture perspective
4. **Chapter 3**:
   - Add 1 paragraph about framing features for development objectives

**Estimated effort**: 2-4 hours of writing/editing

### Moderate Changes (Balanced Approach)

All minimal changes PLUS:
5. **Chapter 1**: Expand multiple-use section with zoning explanation
6. **Chapter 2**: Add 1 complete multiple-use workflow example
7. **Chapter 5**: Add example of setting up zones in prioritizr code
8. **Glossary**: Add multiple-use terminology

**Estimated effort**: 1-2 days of writing

### Comprehensive Changes (Full Reframe)

All moderate changes PLUS:
9. Restructure Chapter 1 to present conservation and multiple-use as co-equal
10. Add 2-3 detailed case studies
11. Add section on trade-off analysis and interpretation
12. Update all screenshots to show multi-use examples
13. Add troubleshooting for zoning configurations

**Estimated effort**: 1 week of writing and redesign

---

## Recommended Language Additions - Copy-Paste Ready

### For Index.qmd (lines 15-22)

**Replace:**
```markdown
*shinyplanr* is a [*golem*](https://thinkr-open.github.io/golem/)-based Shiny 
application designed to make systematic conservation planning accessible to 
stakeholders, managers, and researchers. It allows users to:
```

**With:**
```markdown
*shinyplanr* is a [*golem*](https://thinkr-open.github.io/golem/)-based Shiny 
application designed to make spatial planning accessible to stakeholders, 
managers, and researchers. Built on the [*prioritizr*](https://prioritizr.net) 
optimization engine, it supports both systematic conservation planning and 
multiple-use spatial planning for marine and terrestrial environments.

**Conservation planning applications:**
- Design marine protected area networks meeting 30x30 targets
- Identify critical habitats for threatened species
- Optimize connectivity corridors for climate adaptation

**Multiple-use planning applications:**
- Balance fisheries, aquaculture, and renewable energy with conservation
- Create zoning schemes allocating space among compatible uses
- Support marine spatial planning and blue economy development

The tool allows users to:
```

### For Chapter 1 - After Line 17 (New Paragraph)

```markdown
Spatial planning is equally critical for **managing multiple uses** of marine and 
terrestrial space. Oceans face growing demands from fishing, aquaculture, renewable 
energy development, shipping, mining, and tourism [@neubert2025multipleuse]. Rather 
than viewing these uses as solely threats to conservation, spatial planning can 
identify win-win solutions where sectors coexist or complement each other. For 
example, aquaculture can be sited in areas unsuitable for bottom trawling, 
offshore wind farms can include no-take zones that benefit fish stocks, and 
tourism can generate revenue for conservation management.

**Multiple-use spatial planning addresses:**

- **Sectoral competition**: Allocating limited ocean space among fishing, energy, 
  conservation, and other uses
- **Trade-off transparency**: Making explicit what is gained/lost under different 
  allocation scenarios
- **Zoning for compatibility**: Designating areas where specific uses are 
  encouraged, restricted, or prohibited
- **Economic sustainability**: Supporting blue economy growth while maintaining 
  ecological function
- **Stakeholder equity**: Ensuring all sectors, including small-scale users, 
  have voice in planning
```

### For Chapter 1 §1.2 - Rewrite Opening (Lines 36-48)

**Current** focuses entirely on "conservation goals." **Rewrite:**

```markdown
### The Need for Systematic Approaches

Traditional approaches to spatial planning often relied on:
- **Ad hoc decisions**: Reacting to immediate pressures rather than strategic 
  allocation
- **Single-sector focus**: Optimizing for one use (e.g., fishing OR conservation) 
  without considering others
- **Expert opinion alone**: Lacking transparent, repeatable methods
- **Opportunistic selection**: Protecting/allocating areas based on availability 
  rather than strategic value

For conservation planning specifically, this led to:
- Gaps in representation of rare species or habitats
- Protected areas in "leftover" locations with low economic value
- Conflicts with resource users due to lack of consultation
- Inefficient use of limited conservation budgets

For multiple-use planning, ad hoc approaches resulted in:
- Use-use conflicts (fishing gear damaged by energy infrastructure)
- Suboptimal economic returns (high-value uses excluded from suitable areas)
- Environmental degradation from cumulative, unmanaged impacts
- Social inequity (industrial uses displacing small-scale users)

Systematic spatial planning [@margules2000systematic; @neubert2025multipleuse] 
addresses these limitations by using quantitative methods to identify priority 
areas based on explicit objectives and constraints, whether for conservation, 
development, or balanced multiple-use scenarios.
```

---

## Conclusion

The manual is well-written and comprehensive for conservation applications. However, 
**it significantly undersells shinyplanr's utility for multiple-use marine spatial 
planning**, which is arguably equally important given global trends toward blue 
economy development and integrated ocean management.

**Recommended actions:**

1. **Immediate**: Add clarifying language in Index and Chapter 1 (~2 hours)
2. **Short-term**: Add 1 multiple-use workflow example in Chapter 2 (~4 hours)
3. **Medium-term**: Add comprehensive zoning section and case studies (~2-3 days)
4. **Long-term**: Consider separate "Multiple-Use Planning with shinyplanr" guide 
   or chapter to complement the conservation-focused content

This would position shinyplanr as the go-to tool for marine spatial planning 
practitioners working on integrated ocean management, not just conservation planners.

**Key principle from Neubert et al. (2025):**

> "Growing global demands for food, energy, and resources drive competition for 
> space while increasing pressure on natural systems, highlighting the need to 
> **balance sustainable resource use with biodiversity conservation**."

Your manual should reflect this balance.

---

**Document Ends**
