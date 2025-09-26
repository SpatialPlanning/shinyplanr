-------------------
How to use the Shiny App
-------------------
* * *   


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
