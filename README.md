# MicronutrientBangForBuckRepository

## Overview

- [Intentions](#intentions)
- [Notes](#notes)
- [Category of Micronutrients](#category-of-micronutrients)
- [Formatting of text file](#format-of-text-file)
- [Guide](#guide)

## Intentions

Intention: 
1. To make a program able to find the common foods between vitamins and elements, regarding micronutrients. (DONE)
2. To sort out which ones are more versatile across seasons, to form a platform/baseline of what foods able to relied on for any season. (TO DO)
3. To make sure our shopping cart adheres to most if not all of the micronutrients. (DONE)

Current Constraint: There is no criteria to identify which food is more intense/plenty in one micronutrient compared to another.

DONE:
1. Currently making a text file that is formatted correctly to allow a script to store the foods in their respective micronutrient.
2. Making a script to identify the shared foods between one micronutrient to another. 

Next Iteration:
1. Making a script to sort out what the user wants, based on the metric of monetary cost, season/availiability grouping, and effect grouping. 

## Notes
Since we are going to have each food have their own traits (season/availability, effects, monetary cost),
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

The next iteration will sort based on the metrics of each individual food, based on the season/cultivation availability, monetary cost, and/or effect (cancer, energy, sleep, metabolism). For metabolism, it is foods like oats that stabilize blood sugar processing/metabolism.