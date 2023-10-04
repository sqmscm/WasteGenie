import 'package:flutter/material.dart';

class ClassificationDict {
  static final Map<int, String> wasteReflections = {
    -1: 'No item detected',
    0: 'Shoe',
    1: 'Straw',
    2: 'Food waste',
    3: 'Lid',
    4: 'Styrofoam piece',
    5: 'Rope & strings',
    6: 'Plastic glooves',
    7: 'Carton',
    8: 'Bottle cap',
    9: 'Plastic bag & wrapper',
    10: 'Cup',
    11: 'Plastic container',
    12: 'Pop tab',
    13: 'Bottle',
    14: 'Squeezable tube',
    15: 'Unlabeled litter',
    16: 'Battery ',
    17: 'Scrap metal ',
    18: 'Glass jar',
    19: 'Broken glass',
    20: 'Can',
    21: 'Aluminium foil',
    22: 'Cigarette',
    23: "Plastic utensils",
    24: "Blister pack",
    25: "Other plastic",
    26: "Paper",
    27: "Paper bag"
  };

  static final Map<int, String> wasteClasses = {
    -1: "try again with another item or angle.",
    0: "try to donate",
    1: 'Landfill',
    2: 'Compost',
    3: 'Recycle',
    4: 'Landfill',
    5: 'Landfill',
    6: 'Landfill',
    7: 'Recycle',
    8: 'Recycle',
    9: 'Landfill',
    10: 'Landfill',
    11: 'Recycle',
    12: 'Recycle',
    13: 'Recycle',
    14: 'Landfill',
    15: 'Landfill',
    16: 'Hazardous Waste Disposal',
    17: 'Recycle',
    18: 'Recycle',
    19: 'Landfill',
    20: 'Recycle',
    21: 'Recycle',
    22: 'Landfill',
    23: 'Landfill',
    24: 'Landfill',
    25: 'Landfill',
    26: 'Recycle',
    27: 'Recycle',
  };

  static String getClassName(int id) {
    if (wasteReflections.containsKey(id)) {
      return wasteReflections[id]!;
    }
    return 'other';
  }

  static String getRecycleGuidelines(int id) {
    if (wasteClasses.containsKey(id)) {
      return wasteClasses[id]!;
    }
    return 'other';
  }

  static Widget getWasteLabelIcon(String category) {
    const double iconSize = 22;

    switch (category.toLowerCase()) {
      case 'recycle':
        return Image.asset('images/recycle_drag.png',
            width: iconSize, height: iconSize);
      case 'landfill':
        return Image.asset('images/landfill_drag.png',
            width: iconSize, height: iconSize);
      case 'compost':
        return Image.asset('images/compost_drag.png',
            width: iconSize, height: iconSize);
      default:
        return Icon(Icons.error_outline);
    }
  }

  static double computeCarbonCredits(int numOfObjects, int totalTrials) {
    /* 
    Based on https://www.epa.gov/facts-and-figures-about-materials-waste-and-recycling/national-overview-facts-and-figures-materials
    
    Type        Generation
    Recycling   68.12m tons      
    Composting  24.89m tons
    Combustion  33.12m tons
    Landfill    138.98m tons
    -------------------------
    Total       265.11m tons
    GHG benefits: 193.26 MMTCO2E (million metric tons of carbon dioxide equivalent)
    -------------------------
    Average per unit: 1.371
    */

    if (totalTrials == 0) {
      return 0;
    }

    return 1.371 * numOfObjects / totalTrials;
  }
}
