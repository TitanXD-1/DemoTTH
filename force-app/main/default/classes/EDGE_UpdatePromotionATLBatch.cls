/**

* @Description: EDGE_UpdatePromotionATLBatch

* @Purpose : Batch Class to update Activity Target List status Waiting Activation to active
Create Outlet Promotion for existing Active Target List Member for an existing Target List

* @History:

* @Version     Developer		   	 Date			    Story/Purpose
*   1.0       Monalisa Halder       26/08/2022          ES20-13220
*   2.0       Prasanth T            09/09/2022          ES20-13287
*/

public class EDGE_UpdatePromotionATLBatch implements Database.Batchable<SObject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass {
    
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false;
    string exceptionMsg = '';
    Id marketBatchJobId; 
    List<Activity_Target_List__c> activityTargetLstMemListToUpdate = new List<Activity_Target_List__c>();
    Map<Id, Set<Id>> createOutletPromoActivityTargetListMap = new Map<Id, Set<Id>>();
    Map<Id,Map<Id,Double>> targetListPromoMasterIdLimitMap = new Map<Id,Map<Id,Double>>();
    Date todaysDate = system.today();
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    //Start Method
    public Database.QueryLocator start(Database.BatchableContext bc){
        // Upsert Market Batch Job Data
        string countryCode = batchSetting.Country_Code__c;
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());
        Set<Id> targetListIdSet = new Set<Id>();
        
        //Querying all the Activity_Target_List__c with Waiting Activation and Waiting Removal 
        for(Activity_Target_List__c actTL :[SELECT Id, Target_List__c,Promotion_Master__c,Promotion_Limit__c,Promotion_Master__r.End_Date__c, Status__c FROM Activity_Target_List__c  
                                            WHERE  Promotion_Master__c  != null AND (Status__c='Waiting Activation' AND
                                                                                     (Promotion_Master__r.End_Date__c = null OR Promotion_Master__r.End_Date__c >= TODAY)) AND Target_List__r.Country__r.Code__c=:countryCode]){
                                                                                         
                                                                                         targetListIdSet.add(actTL.Target_List__c);       
                                                                                         if(actTL.Status__c == 'Waiting Activation'){
                                                                                             //putting the waiting activation ones, in a list to update later
                                                                                             activityTargetLstMemListToUpdate.add(actTL);
                                                                                             // creating a map of target list id and promotion master Id   
                                                                                             if(createOutletPromoActivityTargetListMap.containsKey(actTL.Target_List__c)){
                                                                                                 createOutletPromoActivityTargetListMap.get(actTL.Target_List__c).add(actTL.Promotion_Master__c);
                                                                                             }else{
                                                                                                 createOutletPromoActivityTargetListMap.put(actTL.Target_List__c, new Set<Id>{actTL.Promotion_Master__c});
                                                                                             } 
                                                                                             //system.debug('@@createOutletPromoActivityTargetListMap' +createOutletPromoActivityTargetListMap); 
                                                                                             //creating a map of Target List Id with Map of Promotion Master Id and Promotion Limit
                                                                                             if(actTL.Promotion_Master__c!=null && actTL.Promotion_Limit__c!=null)//ES20-13287
                                                                                             {
                                                                                                 if(targetListPromoMasterIdLimitMap.containsKey(actTL.Target_List__c) && targetListPromoMasterIdLimitMap.get(actTL.Target_List__c)!=null)
                                                                                                 {//ES20-13287
                                                                                                     if(targetListPromoMasterIdLimitMap.get(actTL.Target_List__c) != null 
                                                                                                     && targetListPromoMasterIdLimitMap.get(actTL.Target_List__c).get(actTL.Promotion_Master__c)!=null
                                                                                                     && targetListPromoMasterIdLimitMap.get(actTL.Target_List__c).containsKey(actTL.Promotion_Master__c) )//ES20-13287 (We are adding the Promotion Limits in case the Promotion is present repeatedly in the Target List)
                                                                                                         targetListPromoMasterIdLimitMap.get(actTL.Target_List__c).put(actTL.Promotion_Master__c,actTL.Promotion_Limit__c+targetListPromoMasterIdLimitMap.get(actTL.Target_List__c).get(actTL.Promotion_Master__c));//ES20-13287 
                                                                                                     else //ES20-13287
                                                                                                         targetListPromoMasterIdLimitMap.get(actTL.Target_List__c).put(actTL.Promotion_Master__c,actTL.Promotion_Limit__c);//ES20-13287 
                                                                                                     //ES20-13287  
                                                                                                 }else
                                                                                                 {//ES20-13287
                                                                                                     Map<Id,Double> promoIdLimitMap = new Map<Id,Double>();//ES20-13287
                                                                                                     promoIdLimitMap.put(actTL.Promotion_Master__c,actTL.Promotion_Limit__c);//ES20-13287
                                                                                                     targetListPromoMasterIdLimitMap.put(actTL.Target_List__c,promoIdLimitMap);//ES20-13287
                                                                                                 }//ES20-13287
                                                                                                 
                                                                                             }
                                                                                             
                                                                                            // system.debug('@@targetListPromoMasterIdLimitMap' +targetListPromoMasterIdLimitMap);
                                                                                         }
                                                                                         
                                                                                     }
        
        string queryString='';
        if(targetListIdSet != null && targetListIdSet.size()>0){
            queryString = 'SELECT Id, Outlet__c, Target_List__c FROM Target_List_Member__c WHERE'+
                ' Target_List__c IN: targetListIdSet and Target_List__r.Country__r.Code__c=:countryCode ORDER BY Outlet__c';
            
        }else{
            queryString = 'SELECT Id, Outlet__c, Target_List__c FROM Target_List_Member__c LIMIT 0';
        }
        
        return Database.getQueryLocator(queryString);
        
    }
    
    //Execute Batch
    public void execute(Database.BatchableContext bc, List<Target_List_Member__c> targetListMemberList){
        List<Activity_Target_List__c> updateActTLList= new list<Activity_Target_List__c>();
        Map<Id, Set<Id>> createPromotionToOutletMap = new Map<Id, Set<Id>>();
        Map<String,Double> outletPromotionLimitMap = new Map<String,Double>();
        
        if(activityTargetLstMemListToUpdate != null && activityTargetLstMemListToUpdate.size() > 0){
            for(Activity_Target_List__c actTL :activityTargetLstMemListToUpdate){
                actTL.Status__c = 'Active';
                updateActTLList.add(actTL);
            }
        }
        
        try{
            if(createOutletPromoActivityTargetListMap !=null && !createOutletPromoActivityTargetListMap.isEmpty()){
                for(Target_List_Member__c targetLstMem :targetListMemberList){
                    //Creating a map of Outlet Id and Set of Promotion Master Id
                    if(createOutletPromoActivityTargetListMap.containsKey(targetLstMem.Target_List__c)){
                        if(createPromotionToOutletMap.containsKey(targetLstMem.Outlet__c)){
                            createPromotionToOutletMap.get(targetLstMem.Outlet__c).addAll(createOutletPromoActivityTargetListMap.get(targetLstMem.Target_List__c));
                        }
                        else {
                            Set<Id> promotionMasterIdSet = new Set<Id>();
                            promotionMasterIdSet.addAll(createOutletPromoActivityTargetListMap.get(targetLstMem.Target_List__c));
                            createPromotionToOutletMap.put(targetLstMem.Outlet__c,promotionMasterIdSet);
                        }
                        
                    } 
                   // system.debug('@@createPromotionToOutletMap' +createPromotionToOutletMap); 
                    // Creating a map of key 'OutletId_Promotion Master Id' and Promotion Limit using Target List Id
                    for(Id promotionId : createPromotionToOutletMap.get(targetLstMem.Outlet__c)){
                        String outletPromoKey = targetLstMem.Outlet__c + '_' + promotionId;
                        if(targetListPromoMasterIdLimitMap.get(targetLstMem.Target_List__c) != null && targetListPromoMasterIdLimitMap.get(targetLstMem.Target_List__c).get(promotionId) != null)//ES20-13287
                        {
                            if(outletPromotionLimitMap.containsKey(outletPromoKey) //ES20-13287
                               && outletPromotionLimitMap.get(outletPromoKey) != null) //ES20-13287
                               {//ES20-13287 (We are adding the Promotion Limits if the same Outlet and Promotion Pair exist in different Target Lists)
                                   outletPromotionLimitMap.put(outletPromoKey,outletPromotionLimitMap.get(outletPromoKey)+targetListPromoMasterIdLimitMap.get(targetLstMem.Target_List__c).get(promotionId));  //ES20-13287
                               }else//ES20-13287
                                outletPromotionLimitMap.put(outletPromoKey,targetListPromoMasterIdLimitMap.get(targetLstMem.Target_List__c).get(promotionId));  //ES20-13287
                               //ES20-13287
                        }
                    }
                   // system.debug('@@outletPromotionLimitMap' +outletPromotionLimitMap); 
                }
                
            }
            if(createPromotionToOutletMap != null && createPromotionToOutletMap.size()>0 
               && outletPromotionLimitMap != null && outletPromotionLimitMap.size()>0 ){
                   EDGE_TListOutletPromCreationHelper.processOutletPromotion(createPromotionToOutletMap,outletPromotionLimitMap); 
               }
            if(updateActTLList != null && updateActTLList.size()>0){
                update updateActTLList;
            }
            
        }catch(Exception ex) {
            hasError = true;
            exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';
        }       
    }   
    
    //Finish Method
    public void finish(Database.BatchableContext bc){
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_UpdatePromotionATLBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        if(!Test.isRunningTest()){
            //Schedule Next Batch from Batch Utility Class
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError);
        }
    }
}