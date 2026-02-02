# shinyplanr Manuscript Outline

## Target Journal: Methods in Ecology and Evolution (Applications Section)

**Working Title:** *shinyplanr: An R Shiny application for interactive, stakeholder-driven systematic conservation planning*

---

## Abstract (Numbered format, 150-250 words)

1. Systematic conservation planning requires balancing biodiversity objectives with socioeconomic considerations, yet existing tools (e.g., Marxan, Zonation, prioritizr) require technical expertise that creates barriers between planners and stakeholders. This disconnect often leads to slow planning processes, reduced stakeholder buy-in, and lower implementation success.

2. We present shinyplanr, an open-source R Shiny application that provides an accessible, interactive interface to the prioritizr optimisation framework. shinyplanr enables non-technical users to explore conservation scenarios in real-time, adjusting targets, costs, and constraints while immediately visualising trade-offs.

3. The package features modular architecture supporting customisation for different planning contexts, climate-smart planning options (Conservation Planning for Adaptation, Feature-based, and Percentile approaches), interactive target controls, scenario comparison, and downloadable reports. We demonstrate shinyplanr's utility through deployments in Pacific Island marine spatial planning initiatives (Kosrae, Fiji, Vanuatu) through the Blue Prosperity Coalition partnerships.

4. shinyplanr is available as an R package on GitHub and can be deployed to shinyapps.io or institutional servers. By democratising access to systematic conservation planning, shinyplanr facilitates transparent, evidence-based stakeholder engagement and supports the participatory approaches increasingly required for effective conservation outcomes under the Global Biodiversity Framework.

---

## 1. Introduction

### Opening paragraphs (~400 words)
- Conservation planning increasingly complex: balancing biodiversity, climate resilience, human uses
- Global Biodiversity Framework targets require evidence-based spatial planning (Target 1, Target 3: 30x30)
- Systematic conservation planning (SCP) tools have evolved: Marxan, Zonation, prioritizr
- However, these tools require technical expertise (R/Python, command line, parameter tuning)
- Critical gap: stakeholders cannot directly engage with planning tools
  - Traditional approach: experts run analyses → present results → stakeholders react
  - Problems: slow iteration (weeks between scenarios), "black box" perception, limited ownership
  - Result: planning processes that fail to achieve buy-in or implementation

### The need for interactive, accessible planning tools
- Effective conservation requires local support and participation (cite stakeholder engagement literature)
- Participatory approaches lead to more durable outcomes
- Real-time feedback enables rapid exploration of trade-offs
- Web-based interfaces can remove software installation barriers

### Introducing shinyplanr
- Brief statement of what shinyplanr does
- Key innovation: brings prioritizr's power to non-technical users via interactive web interface
- Relationship to existing ecosystem (prioritizr, spatialplanr packages)
- Structure of paper: description → comparison → case study → conclusions

---

## 2. Description of shinyplanr

### 2.1 Overview and design philosophy
- Goals: accessibility, transparency, real-time feedback, customisability
- Built using golem framework for production-quality Shiny applications
- No coding required for end users; fully customisable by technical users
- Available on GitHub: https://github.com/spatialplanning/shinyplanr

### 2.2 Application modules

Present the five main modules with brief descriptions:

**Welcome Module**
- Context-setting and instructions for stakeholders
- Customisable text/images for each deployment
- Terminology and guidance for new users

**Scenario Module** (main planning interface)
- Target selection: individual feature sliders, category sliders, or master target
- Cost layer selection
- Lock-in/lock-out constraints for existing uses
- Climate-smart options (when enabled): CPA, Feature, Percentile approaches
- Real-time solution visualisation with Leaflet maps
- Feature representation plots showing target achievement


**Comparison Module**
- Side-by-side comparison of saved scenarios
- Visual and tabular differences in outcomes
- Supports evidence-based discussions about trade-offs

**Layer Information Module**
- Explore individual feature and cost layer distributions
- Interactive maps and histograms
- Understanding input data before running scenarios

**Help Module**
- FAQs, technical documentation, references
- Customisable for each deployment context

### 2.3 Technical implementation

**Core dependencies**
- prioritizr for optimisation engine
- CBC solver via rcbc for integer linear programming
- sf for spatial data handling
- leaflet for interactive mapping
- Quarto for downloadable reports

**Optimisation options**
- Objective functions: minimum set (`add_min_set_objective`), minimum shortfall (`add_min_shortfall_objective`)
- Gap-to-optimality settings for speed vs. precision trade-off
- Typical solve times: seconds to minutes depending on problem complexity

**Climate-smart planning** (when enabled)
- CPA: Conservation Planning for Adaptation approach
- Feature: feature-specific climate projections
- Percentile: planning unit-level climate risk percentiles

### 2.4 Customisation and deployment

**Data dictionary approach**
- `Dict_Feature.csv` defines features, targets, cost layers, groupings
- Separates data configuration from application code
- Example structure:

```
Feature,Category,Target,Cost,Description
Coral_reef,Habitat,0.3,FALSE,Coral reef extent
Mangrove,Habitat,0.3,FALSE,Mangrove forest
Fishing_effort,Human_use,NA,TRUE,Commercial fishing intensity
```

**Setup workflow**
- `setup-data.R`: Prepare raw spatial data → package format
- `setup-app.R`: Configure options, features, customisation
- Custom CSS and logos for branding
- Deployment to shinyapps.io or institutional servers

---

## 3. Comparison with other tools

### Comparison Table (Table 1)

Create a comprehensive comparison table similar to phylospatial paper Table 1, comparing shinyplanr to:

| Tool | Type | Optimisation | Interactive | Web-based | Real-time | Stakeholder focus | Climate-smart | Customisable | Open source |
|------|------|--------------|-------------|-----------|-----------|-------------------|---------------|--------------|-------------|
| **shinyplanr** | R Shiny | prioritizr (ILP) | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Marxan | Standalone | Simulated annealing | — | — | — | — | — | Config files | ✓ |
| Marxan Connect | R/standalone | SA | — | — | — | — | — | ✓ | ✓ |
| Zonation | Standalone | Cell removal | — | — | — | — | — | Config files | ✓ |
| prioritizr | R package | ILP/heuristic | — | — | — | — | ✓ | ✓ | ✓ |
| prioritizr Shiny (CRAN) | R Shiny | prioritizr | ✓ | ✓ | ✓ | — | — | Limited | ✓ |
| Marxan.io | Web app | SA | ✓ | ✓ | — | ✓ | — | Limited | — |
| NatureMap | Web app | Various | ✓ | ✓ | — | — | — | — | — |

### Discussion of comparison
- shinyplanr unique combination: prioritizr optimisation + real-time feedback + stakeholder focus
- Trade-offs: speed vs. problem complexity
- Complementary to rather than replacement for existing tools
- Role in workflow: stakeholder engagement phase of larger planning process

---

## 4. Application Example: Blue Prosperity Marine Spatial Planning

### 4.1 Context
- Blue Prosperity Coalition: partnership between governments and Waitt Institute
- Goal: sustainable ocean management with community engagement
- Deployments in Kosrae (FSM), Fiji, Vanuatu

### 4.2 Kosrae case study (primary example)

**Background**
- Government of Kosrae committed to marine spatial planning
- MOU signed for collaborative process
- 12-nautical-mile State waters as planning area

**Data preparation**
- Ocean Use Survey: mapped human activities and local knowledge
- Marine habitats: coral reefs, mangroves, seagrass
- Species distributions: target species for protection
- Cost layers: fishing activity intensity

**shinyplanr deployment**
- Customised welcome text explaining local context
- Features and costs configured via Dict_Feature.csv
- Climate-smart options enabled using regional projections


**Stakeholder engagement process**
- MSP Working Group workshops
- Real-time scenario exploration during meetings
- Stakeholders adjusted targets and compared outcomes
- Evidence-based discussions about protection scenarios

**Outcomes**
- Transparent, participatory process
- Multiple scenarios explored in single sessions (vs. weeks traditionally)
- Stakeholder ownership of planning outcomes
- [Add specific quantitative outcomes if available]

### 4.3 Additional deployments
- Brief mention of Fiji, Vanuatu deployments
- Common patterns and adaptations across contexts
- Evidence of generalisability

---

## 5. Conclusions

### Summary (~200 words)
- shinyplanr addresses critical gap: making systematic conservation planning accessible to stakeholders
- Combines rigorous optimisation (prioritizr) with interactive, real-time interface
- Supports climate-smart planning and scenario comparison
- Successfully deployed in Pacific Island marine spatial planning initiatives

### Advantages
- Democratises access to conservation planning tools
- Enables rapid, transparent exploration of trade-offs
- Customisable for diverse planning contexts
- Open-source and actively maintained

### Limitations and future directions
- Currently focused on single-zone planning (multi-zone planned)
- Problem size limitations for very large planning regions
- Solver options could be expanded
- Community contributions welcome

### Broader implications
- Supports implementation of Global Biodiversity Framework
- Model for participatory conservation planning tools
- Potential for adaptation beyond marine contexts (terrestrial, freshwater)

---

## Author Contributions
- [Following CRediT taxonomy as in MEE examples]

## Acknowledgements
- Waitt Institute
- University of Queensland
- Blue Prosperity Coalition partners
- Governments of Kosrae, Fiji, Vanuatu
- prioritizr development team
- Funding sources

## Conflict of Interest Statement
- [Standard statement]

## Peer Review
- [Standard MEE statement]

## Data Availability Statement
- R package shinyplanr is available via GitHub: https://github.com/spatialplanning/shinyplanr
- Documentation and examples: https://spatialplanning.github.io
- Code for case study examples available in Supporting Information

---

## References (key citations)

### Conservation planning methods
- Margules & Pressey (2000) - systematic conservation planning
- Ball et al. - Marxan
- Moilanen et al. - Zonation
- Hanson et al. - prioritizr

### Marine spatial planning
- Ehler & Douvere - MSP guide
- Arafeh-Dalmau et al. - climate-smart planning

### Stakeholder engagement
- Reed (2008) - stakeholder participation
- Sterling et al. - inclusive conservation

### Global policy
- CBD COP15 - Global Biodiversity Framework
- 30x30 targets

### Software/R packages
- Chang et al. - Shiny
- Fay et al. - golem
- Hijmans - terra
- Pebesma - sf

---

## Figures

### Figure 1: Workflow diagram
- Data inputs (features, costs, planning units) →
- Customisation (Dict_Feature.csv, setup-app.R) →
- shinyplanr deployment →
- Stakeholder interaction →
- Outputs (scenarios, reports, maps)

### Figure 2: Application interface
- Screenshots of main modules
- (a) Scenario module with target sliders and map
- (b) Comparison module with side-by-side scenarios
- (c) Layer information module

### Figure 3: Case study results
- Example output from Kosrae deployment
- Map showing conservation priorities
- Feature representation chart

---

## Tables

### Table 1: Comparison of conservation planning tools
- (As described in Section 3)

### Table 2: Summary of shinyplanr deployments
| Deployment | Region | Planning units | Features | Stakeholder events | Status |
|------------|--------|----------------|----------|-------------------|--------|
| Kosrae | FSM | ~X | ~X | X workshops | Active |
| Fiji | Fiji | ~X | ~X | X workshops | Active |
| Vanuatu | Vanuatu | ~X | ~X | X workshops | Active |

---

## Supporting Information

- **S1**: Technical documentation for deploying shinyplanr
- **S2**: Example Dict_Feature.csv template and configuration guide
- **S3**: Code and data for reproducing case study examples

---

## Notes for Authors

### MEE Applications format (based on published examples)
- **Length**: ~3500-5500 words (9-13 pages)
- **Abstract**: Numbered format (4-5 points)
- **Structure**: Introduction → Description → Comparison → Example → Conclusions
- **Code examples**: Include runnable code snippets
- **Comparison table**: Compare to similar tools
- **Figures**: 2-4 figures including workflow diagram

### Key differences from initial outline
1. Condensed stakeholder engagement section into description and case study
2. Added numbered abstract format
3. Created comparison table section
4. Reduced number of case studies (focus on one primary example)
5. Added code examples throughout
6. Streamlined overall structure

### Key messages to emphasise
1. **Accessibility**: Non-technical users can engage with complex optimisation
2. **Real-time**: Scenarios generated in seconds, enabling rapid iteration
3. **Transparency**: "Glass box" vs "black box" approach
4. **Customisable**: Adaptable to any spatial planning context
5. **Proven**: Successfully deployed in real-world marine spatial planning

### Potential reviewer concerns to address
- How does this differ from existing prioritizr Shiny interfaces?
- Evidence of actual stakeholder engagement improvements?
- Generalisability beyond Pacific Island marine contexts?
- Scalability for larger planning problems?