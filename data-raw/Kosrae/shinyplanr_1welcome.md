Welcome
-------

* * *

<img src="www/logo2.png" style="width:25%;float:right">
  
Welcome to our interactive visualization tool for marine spatial planning. This tool is part of [Blue Prosperity Micronesia (BPM)](https://www.blueprosperitymicronesia.org), a government-led program to support the sustainable growth of marine resources in the Federated States of Micronesia (FSM). This tool also supports the work underway to develop a Marine Spatial Plan (MSP) for the State of Kosrae, as called for in the Memorandum of Understanding signed by the Governor.   
  
In Kosrae and elsewhere in FSM where MSP efforts are underway, BPM brings a holistic approach to spatial planning based on the best available science and stakeholder participation to build a healthier marine environment that will benefit future generations. This approach is made operational through efforts such as this tool, which allows you to explore, discuss and identify potential spatial planning scenarios within the Kosrae planning area (i.e., all of State waters out to the 12 nautical mile State/National boundary).

The scenarios used in this tool are informed by the goals and objectives that the MSP Working Group has developed, as these objectives provide the instructions to the tool. The tool also incorporates best available science and data, including (for example) the results of the recently completed Ocean Use Survey which describe human activities, as well as other data sets describing marine habitats and species’ occurrence.    
  
We hope that this tool will aid discussions amongst stakeholders, providing a transparent and scientific evidence-based platform for development of the Kosrae MSP.   
  
For further information, please contact:
* General MSP queries: [Emily Stokes](https://www.waittinstitute.org/team)
* App-specific questions and issues: [Jason Everett](https://jaseeverett.github.io)

* * *


Some terminology to get you started
-------------------
(see https://marxansolutions.org/ for more information).

**Overall aim**: To design a cost-efficient spatial plan that meets conservation targets.

**Planning region**: The domain of interest. If planning units are the pieces of the jigsaw, the planning region is the entire jigsaw puzzle.

**Planning units**: Planning units are the building blocks of any spatial plan. They are smaller, more-manageable pieces within the planning region, similar to jigsaw puzzle pieces. They  are usually defined as a regular grid of squares or hexagons of equal areas.

**Features**: What you want to protect. Features can be species, habitats, biogeographic regions, topographic features, processes, activities or any discrete area you want to include in your planning process.
Targets: The minimum proportion of a feature in the planning region to be included in the prioritizaton (e.g., ensure 20% of each habitat type is included in protected areas).

**Cost layer**:  The cost layer in conservation planning includes data that shows us where important activities already happen in the ocean. Cost data can reflect socioeconomic factors, helping to highlight areas of high human use. Depending on the location, cost layers could include individual or combined layers for many industries, including fishing, aquaculture, shipping, mining, oil and gas, aggregate extraction, and tourism. By using this data, we can plan conservation efforts to minimize overlap with existing high-use areas. For example, instead of protecting a reef that fishermen heavily rely on for catching fish, a reef farther out that is equally important for biodiversity but less critical for fishing activities can be chosen when we have this information. When the “cost” of the spatial plan is minimized, this can reduce conflicts with ocean users and increase the likelihood the spatial plan is implemented. 

**Zones**: Ocean areas can be designated for specific uses on zones. For example, there are shipping channels, fishing areas, renewable energy areas, marinas, aggregate extraction areas, and protected areas, amongst others.The goal is to decide which planning units should be allocated to each zone.

**Climate-smart**: Climate change will impact some areas more than others. It is multi-faceted, and includes warming, ocean acidification, and sea level rise, amongst other variables. Climate-smart protected areas seek to place protection where biodiversity is most likely to be able to cope with climate change. One approach is to prioritize placing protected areas in climate refugia. These are areas exposed to the least warming, smallest pH change, smallest sea level rise, or least change in primary production. Another approach is to prioritize protected areas in adaptation hotspots. These are areas that could harbour strains that could be more resilient to climate change. Yet another approach is to ensure climate representation, which seeks to prioritize the placement of protected areas across a range of future climate exposures. By placing protected areas across a range of climate exposures, we are implicitly assuming that there is large uncertainty around climate projections, how organisms will respond, and we do not want to pick winners.

**Locked-in**: Ensure the areas are included in the final solution. For example, existing protected areas can be locked into the final solution.

**Locked out**: Ensure the areas are NOT included in the final solution. For example, it might be a restricted military area or an area already zoned (e.g., the area already has oil and gas platforms).

* * * 

How to use the Shiny App
-------------------
  
We provide a quick introduction here to run a planning scenario and to examine the results. See Help/Technical Information for more details.  
  

### The Scenario tab: running a scenario (see definitions above)

1.  **Select targets:** to achieve a planning solution, first set a target value for the percentage of each feature to protect. For example, a 20% target will ensure 20% of the area where the feature is found in the planning region will be included in the final solution.
2.  **Select Cost Layer:** select a cost layer in the planning scenario. When a cost layer is selected, the solution will try to avoid including grid cells that are too costly.
3.  **Select Climate resilience:** makes the spatial plan climate-resilient - i.e., try to ensure selected planning units are robust to impacts of climate change to 2100. We achieve this by calculating a climate-resilience metric that represents climate refugia, whereby higher values represent areas likely to warm less and where biodiversity is more likely to be retained. The planning scenario will then preferentially place protected areas where there are higher values of the climate-resilience metric, whilst still meeting the biodiversity objectives and minimizing overlap with high cost (fishing)areas.
4.  **Run the scenario:** once the different options have been selected, you select 'Run analysis' and the Shiny App will then produce a spatial planning scenario in real time (seconds to a minute) based on your inputs. Please note that it will take more time if you include ‘Climate-smart’ options'. The spatial planning problem is solved using an algorithm known as exact integer linear programming . This aims to find an optimal spatial plan.
5.  **Examine the results:** you can download a map of the spatial plan that will show how much and which areas would be included in the protected areas. Also shown are the amount and  areas available for other uses such as fishing.
6.  **Examine spatial plan in detail:** you can select the other tabs. This includes Targets, Costs, Climate, and Details. The Targets tab shows all the features with their representation. Note that the representation must be greater than or higher than the Target set for each feature.


### Other tabs

We have included a range of other tabs to assist in considering each spatial planning scenario (more detailed explanations are provided when you select them):

1.  **Comparison:** enables the user to compare two spatial plans;
2.  **Layer Information:** enables the user to examine each of the different features, climate and cost layers;
3.  **Help** (including Frequently Asked Questions, References, and Technical information): provides more detailed information and links to relevant information;
4.  **Credit**: provides acknowledgments to those whose work contributed to this Shiny App, and
5.  **Waitt Institute**: links to the website of the Waitt Institute.

* * *

The CARE principles that underpin conservation planning
-------------------

The four key principles that should be considered when designing a spatial plan are Connectivity, Adequacy, Representation, and Efficiency (CARE). The CARE principles are fundamental to conserving  biodiversity over the long term.
* **Connectivity**: Connectivity is the exchange of individuals (or genes, traits, energy or materials) among habitat patches, populations, communities or ecosystems. Ensuring connectivity could include protecting sources and sinks of coral or fish larvae, migration corridors for terrestrial and marine vertebrates, stopover sites for migratory birds, or keeping interdependent habitats that species need throughout their life cycle (e.g., nesting and feeding grounds).
* **Adequacy**: An adequate conservation area should contain enough of each species and habitat to ensure that they persist through time. This is achieved by ensuring that a minimum target amount of each habitat and species are conserved within the protected area network. Some species and habitats need more conservation than others.
* **Representation**: This principle is the foundation of area-based conservation approaches. It aims to ensure a sample of all biodiversity present in a region receives some form of protection. Species, habitats, ecosystems, and key ecological processes should all be represented and replicated throughout a spatial plan.
* **Efficiency**: This principle seeks to deliver conservation outcomes whilst minimizing impacts on people, industries and communities that also rely on natural resources. Conservation plans that have less impact on people and their livelihoods are likely to find broader support. However, efficiency can also lead to residual protected areas. These are areas with low human use that can be preferentially selected in the solution because they are cheap (low cost), but sometimes have little conservation benefit.
