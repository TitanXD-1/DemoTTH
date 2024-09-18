/**
* @Name EDGE_TListOutletPromCreationHelper
* @Description Helper class to create Outlet Promotion when Target List Member is made Active
* @History
VERSION     	AUTHOR           DATE           DETAIL
1.0         	Saranya L    	21/06/2022		ES20-10238
2.0				Swaraj Samanta	02/08/2022		ES20-12952
3.0			    Sudipta Nandi	02/08/2022		ES20-13090
4.0			 	Swaraj Samanta	02/08/2022		ES20-12952 
5.0             Prasanth T      09/09/2022      ES20-13287
6.0             Monalisa Halder 22/12/2022      ES20-13673
**/

public with sharing class EDGE_TListOutletPromCreationHelper {
    
    /**
* @description : This method is used to create Outlet promotion
* @return : void
* @param : Map<Id,Set<Id>>
*/
    public static void processOutletPromotion(Map<Id,Set<Id>> outletIdPromMasterIdMap,Map<String,Double>outletPromotionLimitMap){
        
        Map<Id, Promotion_Master__c> promoMasterMap;
        Set<Id> allPromoMasterIdSet = new Set<Id>();
        for(Id outletId :outletIdPromMasterIdMap.keyset()){
            Set<Id> promoMasterIdSet = outletIdPromMasterIdMap.get(outletId);
            allPromoMasterIdSet.addAll(promoMasterIdSet);
        }
        
        //Create promotion master map
        promoMasterMap = new Map<Id,Promotion_Master__c>([SELECT Id,End_Date__c
                                                          FROM Promotion_Master__c WHERE Id IN :allPromoMasterIdSet and End_Date__c >= TODAY]);//ES20-13287 To Consider Only Those Promotion Masters which are active
        
        List<Outlet_Promotion__c> outletPromotionListToUpsert = createOutletPromotion(outletIdPromMasterIdMap,promoMasterMap,outletPromotionLimitMap); 
        
       
       //ES20-13090
        
        if(outletPromotionListToUpsert != null && outletPromotionListToUpsert.size()>0 && Schema.sObjectType.Outlet_Promotion__c.IsCreateable() && Schema.sObjectType.Outlet_Promotion__c.IsUpdateable())//ES20-13287
        {
            Database.upsert(outletPromotionListToUpsert,false);// ES20-13287
        }
        
        
    }
    /**
* @description : This method is used to return list of Outlet Promotion to be created
* @return : List<Outlet_Promotion__c>
* @param : Map<Id,Set<<Id>> outletIdPromMasterIdMap,Map<Id, Promotion_Master__c> promoMasterMap
*/
    Private static List<Outlet_Promotion__c> createOutletPromotion(Map<Id,Set<Id>> outletIdPromMasterIdMap,Map<Id, Promotion_Master__c> promoMasterMap, Map<String,Double>outletPromotionLimitMap){
        List<Outlet_Promotion__c> outletPromotionListToUpsert = new List<Outlet_Promotion__c>();//ES20-13287
        Map<String,Outlet_Promotion__c> alreadyPresentOutletPromotionIds=new Map<String,Outlet_Promotion__c>();//ES20-13287
        for(Outlet_Promotion__c outletPromotion:[Select Id,Promotion_Limit__c,Outlet__c,Promotion__c From Outlet_Promotion__c where Outlet__c in :outletIdPromMasterIdMap.keySet() and Promotion__c in :promoMasterMap.keySet()])//ES20-13287 To Check if the Outlet Promotions containing the Outlet and Promotion Pairs already exist 
        {
            alreadyPresentOutletPromotionIds.put(outletPromotion.Outlet__c+'_'+ outletPromotion.Promotion__c,outletPromotion);//ES20-13287
        } //ES20-13287
        
        
        for(Id outletId :outletIdPromMasterIdMap.keySet()){
            Set<Id> promoMasterIdSet = outletIdPromMasterIdMap.get(outletId);
            if(promoMasterIdSet != null){
                for(Id promoMasterId :promoMasterIdSet){
                    if(promoMasterMap.containsKey(promoMasterId)){
                        Outlet_Promotion__c outProm=new Outlet_Promotion__c();
                        if(alreadyPresentOutletPromotionIds.containsKey(outletId+'_'+promoMasterId) && alreadyPresentOutletPromotionIds.get(outletId+'_'+promoMasterId)!=null)//ES20-13287
                        {
                            outProm = alreadyPresentOutletPromotionIds.get(outletId+'_'+promoMasterId);//ES20-13287 //We shall update the Outlet Promotion in case it already exists
                            outProm.Promotion_Limit__c+=outletPromotionLimitMap.containsKey(outletId +'_'+promoMasterId)?outletPromotionLimitMap.get(outletId +'_'+promoMasterId):0;//ES20-13287 //Adding the New Value of Promotion Limit to the previous value
                        }
                        
                        else{//ES20-13287
                            outProm.Outlet__c = outletId;//ES20-13287
                            outProm.Promotion__c = promoMasterId;//ES20-13287
                            outProm.Promotion_Limit__c =  outletPromotionLimitMap.containsKey(outletId +'_'+promoMasterId)?outletPromotionLimitMap.get(outletId +'_'+promoMasterId):0;//ES20-13287
                        }
                        outProm.Status__c = 'Active';//ES20-13287
                        
                        outletPromotionListToUpsert.add(outProm);//ES20-13287
                    }
                }
            }
        }
        return outletPromotionListToUpsert;
    }
    
    /**
* ES20-12952
* @description : This method is used to update list of Outlet Promotion which needs to be deactivated
* @return : void
* @param : set<string>  outletPromoMasterSet,set<Id> promoMasterIdSet
*/
    public static void removeOutletPromotions(set<string> outletPromoMasterSet, set<Id> promoMasterIdSet){
        Map<Id, Set<Id>> targetListWithActivePromoMap = new Map<Id, Set<Id>>();
        List<Outlet_Promotion__c > inactiveOutletpromoList = new List<Outlet_Promotion__c >();
        Set<Id> outletSetId = new Set<Id>(); 
        
        if (Schema.sObjectType.Activity_Target_List__c.IsAccessible()){
            //Get Existing Target List for same Promo master having activity target list status = Active to remove them from combination
            for(Activity_Target_List__c actTargetLst : [SELECT Id, Target_List__c, Promotion_Master__c FROM Activity_Target_List__c 
                                                        WHERE Promotion_Master__c IN :promoMasterIdSet AND Status__c = 'Active']){
                                                            if(targetListWithActivePromoMap.containsKey(actTargetLst.Target_List__c)){
                                                                targetListWithActivePromoMap.get(actTargetLst.Target_List__c).add(actTargetLst.Promotion_Master__c);
                                                            }else{
                                                                targetListWithActivePromoMap.put(actTargetLst.Target_List__c , new Set<Id> {actTargetLst.Promotion_Master__c});
                                                            }
                                                        }  
        }
        
        //for getting the Outlet Ids associated with the Opportunity 
        for(String key : outletPromoMasterSet){
            String outletId = key.substringBefore('-');
            outletSetId.add(outletId);
        }
        //Get Target List Member for Target List which we got above
        if (Schema.sObjectType.Target_List_Member__c.IsAccessible()){
            for(Target_List_Member__c targetLstMem : [SELECT Id, Outlet__c, Target_List__c FROM Target_List_Member__c 
                                                      WHERE Target_List__c IN :targetListWithActivePromoMap.keySet() AND
                                                      Assignment_Status__c ='Active' and Outlet__c IN :outletSetId]){ 
                                                          //This gives me combination of outlet & template which are linked with another Target List for which ATL is not marked as Waiting Removal. We dont need bypass this combination from deletion            
                                                          if(targetListWithActivePromoMap != null && targetListWithActivePromoMap.containsKey(targetLstMem.Target_List__c)){
                                                              for(Id promoId : targetListWithActivePromoMap.get(targetLstMem.Target_List__c)){
                                                                  string key = targetLstMem.Outlet__c + '-' + promoId;
                                                                  outletPromoMasterSet.remove(key);
                                                              }
                                                          }
                                                      }
        }
        System.debug(LoggingLevel.ERROR,'outletPromoMasterSet'+outletPromoMasterSet);
        //Get All Outlet promotions that needs to be deactivate from system
        if(Schema.sObjectType.Outlet_Promotion__c.isAccessible()){
            for(Outlet_Promotion__c outletPromo :[SELECT Id,Status__c FROM Outlet_Promotion__c  
                                                  WHERE OutletWithPromotionId__c  IN :outletPromoMasterSet AND Status__c = 'Active']){
                                                      outletPromo.Status__c = 'Inactive';
                                                      inactiveOutletpromoList.add(outletPromo);    
                                                  }
        }
        
        if(inactiveOutletpromoList != null && inactiveOutletpromoList.size()>0 && Schema.sObjectType.Outlet_Promotion__c.isUpdateable()){
            // ES20-13673
            Database.update(inactiveOutletpromoList,false);
            //update inactiveOutletpromoList;
        }
    }
}