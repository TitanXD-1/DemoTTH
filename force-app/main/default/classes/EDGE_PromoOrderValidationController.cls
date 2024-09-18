/**

* @Description: EDGE_PromoOrderValidationController

* @Purpose: Service to detect available and unavailable promotions 

* @VERSION     AUTHOR         		 DATE            DETAIL

* 	1.0		  Swaraj Samanta 	 15/07/2022       ES20-12823
*	2.0		  Rajarshi Lahiri	 31/08/2022		  ES20-13264(Added method isPromoOrderValid)

*/ 

public inherited sharing class EDGE_PromoOrderValidationController {
    static EDGE_PromoOutletOutputWrapper promoOutletOutput = new EDGE_PromoOutletOutputWrapper();
    
    public static EDGE_PromoOutletOutputWrapper getPromotionDetails(EDGE_PromoOutletInputWrapper inputData){
        String terrType = '';
        List<EDGE_PromoAvailabilityWrapper> promoAvailabilityList = new List<EDGE_PromoAvailabilityWrapper>();
        Map<Id,double> outletPromoMap = new Map<Id, double>();
        Map<Id,double> terrPromoMap = new Map<Id, double>();
        Id outletId = inputData.Outlet_Id;
        Id userId = inputData.User_Id;
        promoOutletOutput.Outlet_Id = outletId;
        
        if(userId != null){
            User usr = [SELECT Id, Profile.Name, IsActive FROM User WHERE Id = :userId];
            if(usr.Profile.Name.Contains(Label.EDGE_SalesRep)){//To accomodate SR and DSR
                terrType = 'Sales Territory';
            }
        }
        if(terrType!=null && terrType!='' && inputData.Promotion_List != null && outletId != null){
            //Fetch Outlet Promotion Using OutletId and promotion Ids
            for(Outlet_Promotion__c outletPromo : [SELECT Id, Promotion__c, Promotion_Limit__c, Promotion_Used__c 
                                                   FROM Outlet_Promotion__c WHERE  Status__c  = 'Active' 
                                                   AND Outlet__c = :outletId AND 
                                                   Promotion__c IN :inputData.Promotion_List])
            {
                
                double promoUsed = outletPromo.Promotion_Used__c != null ? outletPromo.Promotion_Used__c : 0;
                double promoLimit = outletPromo.Promotion_Limit__c != null ? outletPromo.Promotion_Limit__c : null;
                double unusedOP = (promoLimit == null ? 0 : ((promoLimit >= promoUsed) ? (promoLimit - promoUsed) : 0));                   
                outletPromoMap.put(outletPromo.Promotion__c, unusedOP > 0 ? unusedOP : 0);
            }
            //Fetch Outlet Promotion Using TerritoryId and promotion Ids
            for(Territory_Promotion__c terrPromo:[SELECT Id, Promotion__c, Promotion_Limit__c, 
                                                  Promotion_Used__c FROM Territory_Promotion__c 
                                                  WHERE Status__c  = 'Active' AND 
                                                  Territory__r.RecordType.Name = :terrType 
                                                  AND Territory__c IN (SELECT Territory__c FROM Outlet_Territory__c WHERE Outlet__c = :outletId) 
                                                  AND Territory__c IN (SELECT Territory__c FROM Territory_Member__c WHERE User__c = :userId AND Start_Date__c <= Today AND (End_Date__c = null OR End_Date__c >= Today))
                                                  AND Promotion__c IN :inputData.Promotion_List])
            {
                double promoUsed = terrPromo.Promotion_Used__c != null ? terrPromo.Promotion_Used__c : 0;
                double promoLimit = terrPromo.Promotion_Limit__c != null ? terrPromo.Promotion_Limit__c : null;
                //if promo limit is null then unused will be null and if it is not null then unused will be difference between limit - used 
                double unusedTP = (promolimit == null ?  null : ((promoLimit >= promoUsed) ? (promoLimit - promoUsed) : 0));
                terrPromoMap.put(terrPromo.Promotion__c, unusedTP == null ? null : (unusedTP > 0 ? unusedTP : 0));
            }
            
            //Looping over input Promotion List to find out it is available for order or not
            for(Id promoId : inputData.Promotion_List){
                
                //new variable within loop to check allow for order true or not .default is true
                Boolean allowForOrdering = false;
                double outletPromoUnused = outletPromoMap.get(promoId);
                double terrPromoUnused = 0.0;
                 if ((terrPromoMap.get(promoId) == null) && (outletPromoMap.get(promoId) == null)){
                    promoAvailabilityList.add(createPromoAvilabilityWrapper(promoId,false,null,null));
					continue;
                }
                
                //If territory limit. is null
                if (terrPromoMap.get(promoId) == null){
                    if (outletPromoUnused > 0){
                        //when terr limit is null and outlet promo limit is not crossed
                        promoAvailabilityList.add(createPromoAvilabilityWrapper(promoId,true,outletPromoUnused,0 ));
                    }else if (outletPromoUnused == null){
                        //when terr limit is null and outlet promo not present
                        promoAvailabilityList.add(createPromoAvilabilityWrapper(promoId,true,null,0));
                    }else{
                        //when terr limit is null and outlet promo limit is crossed
                        promoAvailabilityList.add(createPromoAvilabilityWrapper(promoId,false,null,0));
                    }
                    continue;
                }else{
                    terrPromoUnused = terrPromoMap.get(promoId);
                    //Limit check logic for territory promotion
                    if (terrPromoUnused > 0){
                        //if it is true need to check territory promotion
                        allowForOrdering = true;
                    }else{
                        //if territory limit is crossed then no need to check anymore
                        allowForOrdering = false;
                        promoAvailabilityList.add(createPromoAvilabilityWrapper(promoId,false,outletPromoUnused,0));
                        continue;
                    }
                }
                //second check outlet promotion list - is it available or not
                if (outletPromoUnused != null){
                    //Limit check logic for outlet promotion
                    if (outletPromoUnused > 0){
                        if (allowForOrdering == true){
                            //if outlet promotionlimit is not crossed and terr promo limit also not crossed 
                            promoAvailabilityList.add(createPromoAvilabilityWrapper(promoId,true,outletPromoUnused,terrPromoUnused));
                        }else{
                            //if outlet promotionlimit is not crossed and terr promo not present
                            promoAvailabilityList.add(createPromoAvilabilityWrapper(promoId,true,outletPromoUnused,0 ));
                        }
                    }else{
                        //if outlet promotionlimit is crossed
                        allowForOrdering = false;
                        promoAvailabilityList.add(createPromoAvilabilityWrapper(promoId,false,0,terrPromoUnused));
                    } 
                }else{
                    //when only territory promotion present-> it should be false
                    promoAvailabilityList.add(createPromoAvilabilityWrapper(promoId,false,0,terrPromoUnused));
                }
            }
            //asssigning output list 
            promoOutletOutput.Available_Promotion_List = promoAvailabilityList;
        }
        return promoOutletOutput;
    }
    
    //creation of EDGE_PromoAvailabilityWrapper
    private static EDGE_PromoAvailabilityWrapper createPromoAvilabilityWrapper(String promoId,Boolean availability,double unusedOP ,double unusedTP){
        EDGE_PromoAvailabilityWrapper promoAvailWrapper = new EDGE_PromoAvailabilityWrapper();promoAvailWrapper.Promotion_Id = promoId;
        promoAvailWrapper.Available_for_Ordering = availability;
        promoAvailWrapper.Unused_Outlet_Promotion = (Integer)unusedOP ;
        promoAvailWrapper.Unused_Territory_Promotion = (Integer)unusedTP;
        return promoAvailWrapper;
    }
    
    //ES20-13264
    public static Boolean isPromoOrderValid(Id outlet,Id user,List<Id> PromotionIdsList,
                                            Map<Id,String> salesRepTerritoryTypeMap,
                                            Map<String, Outlet_Promotion__c> allOutletPromoMap,
                                            Map<String, Territory_Promotion__c> allTerrPromoMap,
                                            Map<Id, Id> allOutletToTerrMap){
        String terrType = '';

        Map<Id,double> outletPromoMap = new Map<Id, double>();
        Map<Id,double> terrPromoMap = new Map<Id, double>();
        Id outletId = outlet;
        Id userId = user;
        Boolean allowForOrdering = false;
        
        if(userId != null){

            terrType = salesRepTerritoryTypeMap.get(userId);
        }
        if(terrType!=null && terrType!='' && PromotionIdsList != null && outletId != null){

            for(Id promotionId : PromotionIdsList) 
            {
                String key = outletId+'_'+promotionId;
                Outlet_Promotion__c outletPromo = allOutletPromoMap.get(key);
                
                if(outletPromo != null){
                    double promoUsed = outletPromo.Promotion_Used__c != null ? outletPromo.Promotion_Used__c : 0;
                    double promoLimit = outletPromo.Promotion_Limit__c != null ? outletPromo.Promotion_Limit__c : null;
                    double unusedOP = (promoLimit == null ? 0 : ((promoLimit >= promoUsed) ? (promoLimit - promoUsed) : 0));                   
                    outletPromoMap.put(outletPromo.Promotion__c, unusedOP > 0 ? unusedOP : 0);
                    System.debug('Promo Details'+promoUsed+' '+promoLimit+' '+unusedOP);
                }
                Id territoryId = allOutletToTerrMap.get(outletId);
                System.debug('@@territoryId'+territoryId);
                System.debug('@@allTerrPromoMap'+allTerrPromoMap);
                if(territoryId != null){
                    String terrPromKey = territoryId+'_'+promotionId;
                    Territory_Promotion__c terrPromo = allTerrPromoMap.get(terrPromKey);
                    if(terrPromo != null){
                        double promoUsed = terrPromo.Promotion_Used__c != null ? terrPromo.Promotion_Used__c : 0;
                        double promoLimit = terrPromo.Promotion_Limit__c != null ? terrPromo.Promotion_Limit__c : null;
                        //if promo limit is null then unused will be null and if it is not null then unused will be difference between limit - used 
                        double unusedTP = (promolimit == null ?  null : ((promoLimit >= promoUsed) ? (promoLimit - promoUsed) : 0));
                        terrPromoMap.put(terrPromo.Promotion__c, unusedTP == null ? null : (unusedTP > 0 ? unusedTP : 0));
                    }
                }
            }

            
            //Looping over input Promotion List to find out it is available for order or not
            for(Id promoId : PromotionIdsList){
                
                //new variable within loop to check allow for order true or not .default is true
                double outletPromoUnused = outletPromoMap.get(promoId);
                System.debug('@@outletPromoUnused'+outletPromoUnused);
                double terrPromoUnused = 0.0;
                 if ((terrPromoMap.get(promoId) == null) && (outletPromoMap.get(promoId) == null)){
                    allowForOrdering=false;
                    break;
					
                }
                
                //If territory limit. is null
                if (terrPromoMap.get(promoId) == null){
                    if (outletPromoUnused > 0){
                        //when terr limit is null and outlet promo limit is not crossed
                        allowForOrdering=true;
                    }else if (outletPromoUnused == null){
                        //when terr limit is null and outlet promo not present
                        allowForOrdering=true;
                    }else{
                        //when terr limit is null and outlet promo limit is crossed
                        allowForOrdering=false;
                        break;
                    }
                    continue;
                }else{
                    terrPromoUnused = terrPromoMap.get(promoId);
                    //Limit check logic for territory promotion
                    if (terrPromoUnused > 0){
                        //if it is true need to check territory promotion
                        allowForOrdering = true;
                    }else{
                        //if territory limit is crossed then no need to check anymore
                        allowForOrdering=false;
                        break;
                    }
                }
                //second check outlet promotion list - is it available or not
                if (outletPromoUnused != null){
                    //Limit check logic for outlet promotion
                    if (outletPromoUnused > 0){
                        if (allowForOrdering == true){
                            //if outlet promotionlimit is not crossed and terr promo limit also not crossed 
                            allowForOrdering=true;
                        }else{
                            //if outlet promotionlimit is not crossed and terr promo not present
                            allowForOrdering=true;
                        }
                    }else{
                        //if outlet promotionlimit is crossed
                        allowForOrdering = false;
                        break;
                    } 
                }else{
                    //when only territory promotion present
                    allowForOrdering=false;
                    break;
                }
                System.debug('@@allowForOrdering'+allowForOrdering);
            }
           
        }
		 return allowForOrdering;       
    }
}