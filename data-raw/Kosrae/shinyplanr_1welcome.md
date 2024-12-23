Welcome
-------

* * *

<img src="www/logo2.png" style="width:25%;float:right">

Dear Valued Stakeholders,  
  
Welcome to our interactive visualization tool for marine spatial planning. This tool is part of Blue Prosperity Micronesia (BPM), a government-led program to support the sustainable growth of marine resources in the Federated States of Micronesia (FSM).  
  
The aim of this tool is to allow you to explore, discuss and identify potential spatial planning scenarios within Kosrae, FSM. BPM brings a holistic approach to spatial planning based on the best available science and stakeholder participation to build a healthier marine environment that will benefit future generations.  
  
We hope that this tool will aid discussions amongst stakeholders, providing a transparent and scientific evidence-based platform for marine zoning. The tool uses map layers of scientific data to help identify areas that are most relevant to one or more of your objectives. The map layers have been created from a range of observational data and models.  
  
Regards,  
  
TITLE AND NAME  
POSITION  
Waitt Institute
  

* * *


Some terminology to get you started
-------------------

**Overall aim:** To design a cost-efficient spatial plan that meets conservation targets.

**Planning region:** The domain of interest. If planning units are the pieces of the jigsaw, the planning region is the entire jigsaw puzzle.

**Planning units:** Planning units are the building blocks of any spatial plan. They are smaller, more-manageable pieces within the planning region, similar to jigsaw puzzle pieces. They  are usually defined as a regular grid of squares or hexagons of equal areas.

**Features:** What you want to protect. Features can be species, habitats, biogeographic regions, topographic features, processes, activities or any discrete area you want to include in your planning process.
Targets: The minimum proportion of a feature in the planning region to be included in the prioritizaton (e.g., ensure 20% of each habitat type is included in protected areas).

**Cost layer:**  Cost data can reflect socioeconomic factors. When the cost of the spatial plan is minimized, this can reduce conflicts with ocean users and increase the likelihood the spatial plan is implemented. On land, cost is commonly the cost of purchase of the area (and sometimes the enforcement needed) to make it a protected area. In the ocean, however, opportunity cost is usually used. The opportunity cost is an estimate of foregone revenue or economic livelihood from conserving an area (for example, the revenue lost by a fisher or fishing fleet if they can no longer fish in an area). Depending on the location, cost layers could include individual or combined layers for many industries, including fishing, aquaculture, shipping, mining, oil and gas, aggregate extraction, and tourism.

**Zones:** Ocean areas can be designated for specific uses on zones. For example, there are shipping channels, fishing areas, renewable energy areas, marinas, aggregate extraction areas, and protected areas, amongst others.The goal is to decide which planning units should be allocated to each zone.

**Climate-smart:** Climate change will impact some areas more than others. It is multi-faceted, and includes warming, ocean acidification, and sea level rise, amongst other variables. Climate-smart protected areas seek to place protection where biodiversity is most likely to be able to cope with climate change. One approach is to prioritize placing protected areas in climate refugia. These are areas exposed to the least warming, smallest pH change, smallest sea level rise, or least change in primary production. Another approach is to prioritize protected areas in adaptation hotspots. These are areas that could harbour strains that could be more resilient to climate change. Yet another approach is to ensure climate representation, which seeks to prioritize the placement of protected areas across a range of future climate exposures. By placing protected areas across a range of climate exposures, we are implicitly assuming that there is large uncertainty around climate projections, how organisms will respond, and we do not want to pick winners.

**Locked-in:** Ensure the areas are included in the final solution. For example, existing protected areas can be locked into the final solution.

**Locked out:** Ensure the areas are NOT included in the final solution. For example, it might be a restricted military area or an area already zoned (e.g., the area already has oil and gas platforms).

For further details, have a look at the Techincal Information under the Help Tab in this Shiny App or see https://marxansolutions.org/.

* * *


How to use the Shiny App
-------------------
  
We provide a quick introduction here to run a planning scenario and to examine the results. See Help/Technical Information for more details.  
  

#### The Scenario tab: running a scenario (see definitions above)

1.  **Select targets:** to achieve a planning solution, first set a target value for the percentage of each feature to protect. For example, a 20% target will ensure 20% of the area where the feature is found in the planning region will be included in the final solution.
2.  **Select Cost Layer:** select a cost layer in the planning scenario. When a cost layer is selected, the solution will try to avoid including grid cells that are too costly.
3.  **Select Climate resilience:** makes the spatial plan climate-resilient - i.e., try to ensure selected planning units are robust to impacts of climate change to 2100. We achieve this by calculating a climate-resilience metric that represents climate refugia, whereby higher values represent areas likely to warm less and where biodiversity is more likely to be retained. The planning scenario will then preferentially place protected areas where there are higher values of the climate-resilience metric, whilst still meeting the biodiversity objectives and minimizing overlap with high cost (fishing)areas.
4.  **Run the scenario:** Once the different options have been selected, you select 'Run analysis' and the Shiny App will then produce a spatial planning scenario in real time (seconds to a minute) based on your inputs. Please note that it will take more time if you include ‘Climate-smart’ options'. The spatial planning problem is solved using an algorithm known as exact integer linear programming . This aims to find an optimal spatial plan.
5.  **Examine the results:** You can download a map of the spatial plan that will show how much and which areas would be included in the protected areas. Also shown are the amount and areas available for other uses such as fishing.
6.  **Examine spatial plan in detail:** You can select the other tabs. This includes Targets, Costs, Climate, and Details. The Targets tab shows all the features with their representation. Note that the representation must be greater than or higher than the Target set for each feature.


#### Other tabs

We have included a range of other tabs to assist in considering each spatial planning scenario (more detailed explanations are provided when you select them):

1.  **Comparison:** enables the user to compare two spatial plans;
2.  **Layer Information:** enables the user to examine each of the different features, climate and cost layers;
3.  **Help** (including Frequently Asked Questions, References, and Technical information): provides more detailed information and links to relevant information;
4.  **Credit**: provides acknowledgments to those whose work contributed to this Shiny App, and
5.  **Waitt Institute**: links to the website of the Waitt Institute.
