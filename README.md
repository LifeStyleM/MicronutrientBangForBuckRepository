# MicronutrientBangForBuckRepository

## Overview

- [Intentions](#intentions)
- [Notes](#notes)
- [Category of Micronutrients](#category-of-micronutrients)
- [Formatting of text file](#format-of-text-file)
- [Guide](#guide)
- [Real-world Constraints](#real-world-constraints)
- [Metrics](#metrics)

## Intentions

Intention: 
1. To make a program able to find the common foods between vitamins and elements, regarding micronutrients. (DONE)
2. To make sure our shopping cart adheres to most if not all of the micronutrients. (DONE)
3. To sort and display foods based on metrics such as monetary cost, micronutrient coverage, and health effects. (IN PROGRESS)

Note: The season/cultivation availability metric was removed. It was too broad to map meaningfully onto individual foods and has been replaced by the food category system and the effects metric.

DONE:
1. Currently making a text file that is formatted correctly to allow a script to store the foods in their respective micronutrient.
2. Making a script to identify the shared foods between one micronutrient to another. 
3. Making a script to sort out what the user wants, based on the metric of monetary cost, micronutrient information, and effect grouping. 

Next Iteration:
1. Making a database for populating the values within each food for each metric.

## Metrics
Monetary cost = money to buy that. Need to specify the unit
Micronutrient information = how much micronutrient some unit of food gives
Effect grouping = for what their effect is. 
    Note: Effect -> (Exercise vs. Energy): Energy is for stimulant for consciousness or for dopamine/serotonin. Any foods that has Pyridoxine is included within Energy. Exercise is things related to vitamin P and such. 

## Notes
Since we are going to have each food have their own traits (effects, monetary cost),
each food will be their own class. 

Furthermore, refer to the food_category.rb within FactoryData for details about the general category of foods.

*This was made public since I could not open this repository in Obsidian when it was private.*


## Category of Micronutrients


Fatty Acids (pseudo vitamin - used to be vitamin F)


Vitamins (A,B,C,D,E,K,P)

    A

        Preformed (retinol)

        Provitamin (beta-carotene)

    B 

        B1 Thiamine

        B2 Riboflavin

        B3 Niacin

        B5 Pantothenic acid

        B6 Pyridoxine

        B7 Biotin

        B9 Folic acid/ Folate

        B12 Colbalamin (methylcobalamin, cyanocobalamin)

    P <=> flavonoids

        Flavanoids (Flavanols, flavones, flavonones, isoflavones, antocyandins, flavonols)

        Flav"a"nols (quercetin, kaempferol, myricetin, fisetin)

        Flav"o"nols <=> Catechins (epicatechin, epigallocatechin gallate (EGCG))

        Flavones

        Flavonones (hesperitin, maringenin, eridictyal)

        Isoflavones (genistein, dridzein)

        Antocyandins (cyandin, delphinidin, pronidin)


Elements (Fe, Mg, Ca, Zn, Se, K, Na, Cu, P, I, Mn)

    Problems: 

    (Cu, Zn) => Zn intake reduces Cu intake

        * May need to display some warning when Zn or Cu is displayed as a side-option for users who are inquiring about the 
        individual micronutrient's foods.


Why we include elements: You can have a deficiency in Zn and such. We want to ensure that our body is healthy and functional enough for other tasks. 

## Format of text file
MN#: (Micronutrient name) (Class) 
Foods (String): (foods)
- Note: # is the ID of the individual micronutrient. We will have an option to list out all of the micronutrients and mark their
IDs. This is so that we don't have to type out the whole name of it. 

Contract: No plural words (e.g., apple instead of apples)


## Guide
Simply add stuff in the shopping.txt for your food, for that specific day. It will prompt you for the respective food's category (micronutrient and general category). 
You can add it and you can also delete it as well. 

This is a simple program for seeing if the shopping list fulfills the micronutrients (for now).

The next iteration will sort based on the metrics of each individual food, based on monetary cost and health effects (sleep, energy, exercise, anti-cancer potential). For metabolism, it is foods like oats that stabilize blood sugar processing/metabolism.

    => We have set up the metrics and sorting method but have not made any attempts into assigning values to the food. 
    
To run it on the web, do these:

1. Kill server (on terminal): lsof -ti :4567 | xargs kill -9, or just do ctrl-c

2. Start server (on terminal): .../MIcronutrientBangForBuck/MicronutrientBangForBuckRepository then bundle exec ruby web/app.rb

## Real-world Constraints

1. Typically, tart cherries are offered dried up in this area and online. Sweet cherries are not. Tart cherries like montmorency cherries aid in sleep, but the vendors are too unreliable in terms of chemicals and the correct cherry. 

    => Please check in your local store, like Costco or Sam's Club, to see if there are any foods that are not dried up. We are aiming for a healthy body, not to destroy it. 

2. Typically, you should buy spices and such online. However, Publix seems to be a great place for spices.

3. For herbs, it is best you cultivate them yourself. Currently, there are too many vendors selling it at a high price for one batch, like 3-5 herbs only for 1-3 dollars. Hence, to optimize costs, cultivating them and having an algorithm for cultivating them is optimal. I have already made it, but I will not disclose it. The only topics relevant would be: Nutrition, Gardening, and Shopping. 

4. For fruits, please refer to (1).

5. For vegetables, you may find them in Publix or Walmart. Stores offer more vegetables than fruits, probably due to supply.

    => In fact, there should be a cost comparison between them. Perhaps a program may be done for that in the next iteration.
