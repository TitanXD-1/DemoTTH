/**
@description: This is Class to create opp,survey,case,promotion for certain outlets 
@name EDGE_UpdateTargetListMemberBatch
@history
Version              Author                   Date            Detail
1.0              Srutadeba Chanda            27/02/2019       ES20-          update Target List Member status Waiting Activation to active delete Target List meber where status is Waiting Removal 
2.0              Monalisa Halder             03/04/2019       ES20-704,738 - Delete the outlet surveys,outlet survey reponses ,once the target list members are deleted
3.0              Manikant Prasad             12/12/2019       ES20-6143 -    Modified the existing logic of Hard deletion of Outlet Survey to soft deletion . 
4.0	  	 		 Kapil Baliyan				 30/12/2019		  Updated Error Handling to implement Database.RaisesPlatformEvents (ES20-6594)
5.0              Dinesh Sharma               30/03/2021       ES20-9885 - Modified the existing logic for undeletion Outlet Survey record based on addition of target list member.
6.0              Monalisa Halder             12/01/2022       ES20-11865
7.0              Prasanth T		             12/01/2022       ES20-11866 - Updating Case Task Status to Cancelled if the outlet from Target Member List is WAITING REMOVAL
8.0              Monalisa Halder             08/02/2022       ES20-11870
9.0              Monalisa Halder             15/02/2022       ES20-12052
10.0			 Saranya L					 24/06/2022		  ES20-10238 - creating outlet promotion records and making activity target list and target list mem status from 'Wating Activation' to 'Active'
11.0			 Sudipta Nandi			     02/08/2022		  ES20-13090
12.0			 Swaraj Samanta				 02/08/2022		  ES20-12952 - To make the Outlet Promotion as Inactive if the Outlet is removed from the target list_ SFDC_ Promo Transfer Order
13.0             Prasanth T                  09/09/2022       ES20-13287 - To combine the Promotion Limits of Outlet Promotions that have the same Outlet ID and Promotion Master ID
14.0             Monalisa Halder             22/12/2022       ES20-13673
15.0			 Saurav Prasad				 05/08/2024		  155306 : GB Opportunity Scoring: Generate Cycle Brief Opportunity in EDGE when template source is set to 'EDGE'

**/
/*
@description: This is Class to create opp,survey,case,promotion for certain outlets 
*/
public class EDGE_UpdateTargetListMemberBatch implements Database.Batchable<sobject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass {
    
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false;
    string exceptionMsg = '';
    Id marketBatchJobId; //Update ES20-6594
    
    /*
@description: to get batch details
*/
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting=batchSetting;
    }
    
    /*
@description: Start Method
*/
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594
        
        string queryString='';
        String countryCode='';
        countryCode = batchSetting.Country_Code__c;
        queryString = 'SELECT Id, Outlet__c, Target_List__c, Assignment_Status__c FROM Target_List_Member__c WHERE (Assignment_Status__c=\'Waiting Activation\' or Assignment_Status__c=\'Waiting Removal\' ) and Target_List__r.Country__r.Code__c=:countryCode' ;
        system.debug(LoggingLevel.ERROR,'@@queryString :::'+queryString);
        return Database.getQueryLocator(queryString);
    }
    
    /*
@description: Execute Batch
*/
    public void execute(Database.BatchableContext bc, List<Target_List_Member__c> targetListMemberList){
        List<Target_List_Member__c> updateTargetListMemberLst= new list<Target_List_Member__c>();
        List<Target_List_Member__c> deleteTargetListMemberLst= new list<Target_List_Member__c>();
        List<Activity_Target_List__c> updateCaseTemplateActTL = new List<Activity_Target_List__c>();
        List<Activity_Target_List__c> updatePromMasterActTL = new List<Activity_Target_List__c>();
        Map<Id, Set<Id>> createTargetListOutletMap = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> deleteTargetListOutletMap = new Map<Id, Set<Id>>();
        List<Outlet_Survey__c> deleteOutletSurveyLst = new List<Outlet_Survey__c>();
        List<Outlet_Survey__c> updateOutletSurveyLst = new List<Outlet_Survey__c>();
        Set<Id> outletIdSet = new Set<Id>();
        set<string> createOutletOppTemplateSet = new set<string>();
        set<string> deleteOutletOppTemplateSet = new set<string>();
        Set<Id> createOutletIdSet = new Set<Id>(); 
        Set<Id> deleteOutletIdSet = new Set<Id>();
        set<Id> createOppTemplateIdSet = new set<Id>();
        set<Id> deleteOppTemplateIdSet = new set<Id>(); 
        set<Id> deletePromoMasterIdSet = new set<Id>();//ES20-12952
        set<string> deleteOutletPromoMasterSet = new set<string>();
        Set<Id> targetListSet = new Set<Id>();
        Set<Id> targetListSetforActivation = new Set<Id>();
        Set<Id> surveyIdSet = new Set<Id>();
        Set<Id> surveyIdSetforActivation = new Set<Id>();
        List<Activity_Target_List__c> acttargList = new List<Activity_Target_List__c>();
        List<Activity_Target_List__c> acttargListForActivation = new List<Activity_Target_List__c>();
        Map<Id,Set<Id>> outletIdCaseTemplateIdMap = new Map<Id,Set<Id>>();
        Map<Id,Set<Id>> outletIdPromMasterIdMap = new Map<Id,Set<Id>>();
        Map<String,Double> outletPromotionLimitMap = new Map<String,Double>();
        String outletRecTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        
        if(targetListMemberList != null && targetListMemberList.size() > 0){
            for(Target_List_Member__c tml:targetListMemberList){
                if(tml.Assignment_Status__c == 'Waiting Activation'){
                    tml.Assignment_Status__c='Active';
                    updateTargetListMemberLst.add(tml);
                    createOutletIdSet.add(tml.Outlet__c);
                    targetListSetforActivation.add(tml.Target_List__c);//ES20-9885
                    
                    if(createTargetListOutletMap.containsKey(tml.Target_List__c)){
                        createTargetListOutletMap.get(tml.Target_List__c).add(tml.Outlet__c);
                    }else{
                        createTargetListOutletMap.put(tml.Target_List__c, new Set<Id>{tml.Outlet__c});
                    }                   
                    
                }
                else{
                    deleteTargetListMemberLst.add(tml);
                    
                    //Adding the outlet ids, target list ids to  set to find the outlet survey records to deleted
                    outletIdSet.add(tml.Outlet__c);
                    targetListSet.add(tml.Target_List__c);
                    deleteOutletIdSet.add(tml.Outlet__c);
                    
                    if(deleteTargetListOutletMap.containsKey(tml.Target_List__c)){
                        deleteTargetListOutletMap.get(tml.Target_List__c).add(tml.Outlet__c);
                    }else{
                        deleteTargetListOutletMap.put(tml.Target_List__c, new Set<Id>{tml.Outlet__c});
                    }                   
                    
                }
            }
            
            //Querying the activity target list to get survey ids for Waiting Removal Target List
            if(targetListSet != null && targetListSet.size()>0){
                acttargList = [Select Id,Target_List__c,Survey__c from Activity_Target_List__c where Target_List__c IN :targetListSet AND Survey__c != null];
                //Adding Survey Ids to a set
                for(Activity_Target_List__c atlRec :acttargList){
                    surveyIdSet.add(atlRec.Survey__c); 
                }
            }
            
            //Querying the activity target list to get survey ids for Waiting Activation Target List (ES20-9885)
            if(targetListSetforActivation != null && targetListSetforActivation.size()>0){
                acttargListForActivation = 
                    [Select Id,Target_List__c,Survey__c 
                     from Activity_Target_List__c 
                     where Target_List__c IN :targetListSetforActivation 
                     AND Survey__c != null];
                //Adding Survey Ids to a set
                for(Activity_Target_List__c atlRecNew :acttargListForActivation){
                    surveyIdSetforActivation.add(atlRecNew.Survey__c); 
                }
            }
            
            //If outletIdSet is not null , query the related Outlet Survey records , put it in a list to be deleted
            if(outletIdSet != null && outletIdSet.size()>0 && surveyIdSet != null && surveyIdSet.size()>0){
                //Adding outlet surveys records in a list 
                //ES20-13673 - Added the field - RecordTypeId in Query
                for(Outlet_Survey__c outletSurveyRec :
                    [Select Id,Outlet__c,To_be_deleted__c,Survey__c, Achievement_status__c,Outlet__r.RecordTypeId 
                     from Outlet_Survey__c 
                     where Outlet__c IN:outletIdSet 
                     and Survey__c IN:surveyIdSet 
                     and Achievement_status__c = 'In Progress']){
                         deleteOutletSurveyLst.add(outletSurveyRec);
                     }
            }
            
            //If createOutletIdSet is not null , query the related Outlet Survey records , put it in a list to be updated(ES20-9885)
            if(createOutletIdSet != null && createOutletIdSet.size()>0 && surveyIdSetforActivation != null && surveyIdSetforActivation.size()>0){
                //Adding outlet surveys records in a list 
                //ES20-13673 - Added the field - RecordTypeId in Query and Added outletIdSet for Active ATL
                for(Outlet_Survey__c outletSurveyRecUpdate :
                    [Select Id,Outlet__c,To_be_deleted__c,Survey__c, Achievement_status__c,Outlet__r.RecordTypeId 
                     from Outlet_Survey__c 
                     where (Outlet__c IN:createOutletIdSet or Outlet__c IN:outletIdSet) 
                     and Survey__c IN:surveyIdSetforActivation and Achievement_status__c = 'In Progress']){
                         updateOutletSurveyLst.add(outletSurveyRecUpdate);
                     }
            }
            
            try{
                if(updateTargetListMemberLst!=null && !updateTargetListMemberLst.isEmpty()){
                    //155306 - added source = Edge
                    for(Activity_Target_List__c acttarget : 
                        [SELECT Id, Target_List__c, Opportunity_Template__c 
                         FROM Activity_Target_List__c 
                         WHERE Target_List__c IN :createTargetListOutletMap.keySet() 
                         AND Opportunity_Template__c != null 
                         AND Opportunity_Template__r.Opportunity_Type__c = 'Cycle Brief' 
                         AND Status__c = 'Active' 
                         AND Opportunity_Template__r.Source__c = 'EDGE' 
                         WITH SECURITY_ENFORCED]){
                             createOppTemplateIdSet.add(acttarget.Opportunity_Template__c);
                             if(createTargetListOutletMap.containsKey(acttarget.Target_List__c)){
                                 for(Id outletId : createTargetListOutletMap.get(acttarget.Target_List__c)){
                                     string key = outletId + '-' + acttarget.Opportunity_Template__c ;
                                     createOutletOppTemplateSet.add(key);                                
                                 }
                             }
                         }
                    /*11865- start, changed for the defect ES20-11972*/
                    /* Added the case template end date check ES20-11870*/
                    for(Activity_Target_List__c acttargetCaseTemp : [SELECT Id, Target_List__c, Case_Template__c,Case_Template__r.End_Date__c, Status__c  
                                                                     FROM Activity_Target_List__c WHERE Target_List__c IN :createTargetListOutletMap.keySet() AND Case_Template__c != null 
                                                                     
                                                                     AND (Case_Template__r.End_Date__c = null OR Case_Template__r.End_Date__c >= TODAY) AND (Status__c = 'Active' OR Status__c = 'Waiting Activation')]){
                                                                         
                                                                         
                                                                         if(createTargetListOutletMap.containsKey(acttargetCaseTemp.Target_List__c)){
                                                                             for(Id outletId : createTargetListOutletMap.get(acttargetCaseTemp.Target_List__c)){
                                                                                 if(outletIdCaseTemplateIdMap.get(outletId) != null){
                                                                                     outletIdCaseTemplateIdMap.get(outletId).add(acttargetCaseTemp.Case_Template__c);
                                                                                 }
                                                                                 else{
                                                                                     Set<Id> caseTemplateIdSet = new Set<Id>();
                                                                                     caseTemplateIdSet.add(acttargetCaseTemp.Case_Template__c);
                                                                                     outletIdCaseTemplateIdMap.put(outletId,caseTemplateIdSet);
                                                                                 }
                                                                             }
                                                                         }
                                                                         
                                                                         if(acttargetCaseTemp.Status__c == 'Waiting Activation'){
                                                                             acttargetCaseTemp.Status__c = 'Active';
                                                                             updateCaseTemplateActTL.add(acttargetCaseTemp);
                                                                             
                                                                         }
                                                                         
                                                                         
                                                                     }
                    
                    if(outletIdCaseTemplateIdMap != null && outletIdCaseTemplateIdMap.size()>0){
                        EDGE_DynamicTLCaseTaskCreationHelper.processCaseAndCaseTask(outletIdCaseTemplateIdMap);
                        
                    }
                    
                    if(updateCaseTemplateActTL != null && updateCaseTemplateActTL.size()>0){
                        //ES20-13673
                        Database.update(updateCaseTemplateActTL,false);
                        //update updateCaseTemplateActTL;
                    }
                    /*11865- end changed for the defect ES20-11972*/
                    
                    //start ES20-10238
                    
                    for(Activity_Target_List__c acttargetPromMastr : [SELECT Id, Target_List__c, Promotion_Master__c,Promotion_Master__r.End_Date__c, Status__c,Promotion_Limit__c  
                                                                      FROM Activity_Target_List__c WHERE Target_List__c IN :createTargetListOutletMap.keySet() AND Promotion_Master__c != null 
                                                                      
                                                                      AND (Promotion_Master__r.Start_Date__c <=TODAY AND Promotion_Master__r.End_Date__c >= TODAY) AND (Status__c = 'Active' OR Status__c = 'Waiting Activation')]){
                                                                          
                                                                          
                                                                          if(createTargetListOutletMap.containsKey(acttargetPromMastr.Target_List__c) && createTargetListOutletMap.get(acttargetPromMastr.Target_List__c)!=null){
                                                                              for(Id outletId : createTargetListOutletMap.get(acttargetPromMastr.Target_List__c)){
                                                                                  String key = outletId +'_'+ acttargetPromMastr.Promotion_Master__c; //ES20-13090
                                                                                  if(outletIdPromMasterIdMap.get(outletId) != null){
                                                                                      outletIdPromMasterIdMap.get(outletId).add(acttargetPromMastr.Promotion_Master__c);
                                                                                  }
                                                                                  else{
                                                                                      Set<Id> promMasterIdSet = new Set<Id>();
                                                                                      promMasterIdSet.add(acttargetPromMastr.Promotion_Master__c);
                                                                                      outletIdPromMasterIdMap.put(outletId,promMasterIdSet);
                                                                                  }
                                                                                  if(acttargetPromMastr.Promotion_Limit__c!=null)//ES20-13287
                                                                                  {
                                                                                      if(outletPromotionLimitMap.containsKey(key) &&outletPromotionLimitMap.get(key)!=null){//ES20-13287 (We are adding the Promotion Limits if the same Outlet and Promotion Pair exist in different Target Lists)
                                                                                          outletPromotionLimitMap.put(key,acttargetPromMastr.Promotion_Limit__c+outletPromotionLimitMap.get(key));//ES20-13287
                                                                                      }
                                                                                      else{//ES20-13287
                                                                                          outletPromotionLimitMap.put(key,acttargetPromMastr.Promotion_Limit__c);//ES20-13287
                                                                                      }
                                                                                      
                                                                                  }
                                                                                  
                                                                              }
                                                                          }
                                                                          
                                                                          if(acttargetPromMastr.Status__c == 'Waiting Activation'){
                                                                              acttargetPromMastr.Status__c = 'Active';
                                                                              updatePromMasterActTL.add(acttargetPromMastr);
                                                                          }
                                                                      }
                    //Method call to create outlet promotion records
                    if(outletIdPromMasterIdMap != null && outletIdPromMasterIdMap.size()>0){
                        EDGE_TListOutletPromCreationHelper.processOutletPromotion(outletIdPromMasterIdMap,outletPromotionLimitMap); //ES20-13090
                        
                    }
                    //Update Activity target list status
                    if(updatePromMasterActTL != null && updatePromMasterActTL.size()>0){
                        //ES20-13673
                        Database.update(updatePromMasterActTL, false);
                        //update updatePromMasterActTL;
                    }
                    
                    //end ES20-10238
                    //ES20-13673
                    Database.update(updateTargetListMemberLst, false);
                    //update updateTargetListMemberLst;
                    
                    //EDGE_OpportunityOperations.createOpportunities(updateTargetListMemberLst);
                    EDGE_OpportunityOperations.createOpportunities(createOutletOppTemplateSet, createOutletIdSet, createOppTemplateIdSet);
                }              
                if(deleteTargetListMemberLst!=null && !deleteTargetListMemberLst.isEmpty()){
                    for(Activity_Target_List__c acttarget : [SELECT Id, Target_List__c, Opportunity_Template__c,Promotion_Master__c FROM Activity_Target_List__c 
                                                             WHERE Target_List__c IN :deleteTargetListOutletMap.keySet() AND Status__c = 'Active' AND
                                                             ((Opportunity_Template__c != null AND Opportunity_Template__r.Opportunity_Type__c = 'Cycle Brief')
                                                              OR (Promotion_Master__c != null))]){//ES20-12952
                                                                  if (acttarget.Opportunity_Template__c != null){
                                                                      deleteOppTemplateIdSet.add(acttarget.Opportunity_Template__c);
                                                                  }else if(acttarget.Promotion_Master__c != null){
                                                                      deletePromoMasterIdSet.add(acttarget.Promotion_Master__c);
                                                                  } 
                                                                  if(deleteTargetListOutletMap.containsKey(acttarget.Target_List__c)){
                                                                      for(Id outletId : deleteTargetListOutletMap.get(acttarget.Target_List__c)){
                                                                          if (acttarget.Opportunity_Template__c != null){
                                                                              string key = outletId + '-' + acttarget.Opportunity_Template__c ;
                                                                              deleteOutletOppTemplateSet.add(key);                                                                  
                                                                          }else if(acttarget.Promotion_Master__c != null){
                                                                              string key = outletId + '-' + acttarget.Promotion_Master__c ;
                                                                              deleteOutletPromoMasterSet.add(key); 
                                                                          }
                                                                      }
                                                                  }
                                                              }
                    //ES20-12952 - Method call to deactivate outlet promotion records
                    if(deleteOutletPromoMasterSet != null && deleteOutletPromoMasterSet.size()>0){
                        EDGE_TListOutletPromCreationHelper.removeOutletPromotions(deleteOutletPromoMasterSet,deletePromoMasterIdSet);
                        
                    }
                    EDGE_OpportunityOperations.deleteOpportunities(deleteOutletOppTemplateSet, deleteOppTemplateIdSet);
                    //EDGE_OpportunityOperations.deleteOpportunities(deleteTargetListMemberLst);
                    //ES20-13673
                    Database.delete(deleteTargetListMemberLst, false);
                    //delete deleteTargetListMemberLst;
                }
                
                
                // Added by Manikant for soft deletion of outlet Survey (ES20-6143)
                if(deleteOutletSurveyLst !=null && !deleteOutletSurveyLst.isEmpty()){
                    for(Outlet_Survey__c outSurRec :deleteOutletSurveyLst){
                        if(outSurRec.Outlet__r.RecordTypeId  == outletRecTypeId){ //ES20-13673
                            outSurRec.To_be_deleted__c = True ;
						}
                     }
                    //ES20-13673
                    Database.update(deleteOutletSurveyLst, false);
                    //update deleteOutletSurveyLst;                     
                }
                
                //Added for undeleting the outlet Survey(ES20-9885)
                if(updateOutletSurveyLst !=null && !updateOutletSurveyLst.isEmpty()){
                    for(Outlet_Survey__c outSurRec :updateOutletSurveyLst){
                        if(outSurRec.Outlet__r.RecordTypeId  == outletRecTypeId){ //ES20-13673
                            outSurRec.To_be_deleted__c = False ; 
                        }
                    }
                    //ES20-13673
                    Database.update(updateOutletSurveyLst, false);
                    //update updateOutletSurveyLst; 
                    
                }
                
            }
            catch(DmlException de){
                hasError = true;
                Integer numErrors = de.getNumDml();
                for(Integer i=0; i<numErrors; i++) {
                    exceptionMsg += 'Record Id : ' + de.getDmlId(i) + ' Line# ' + de.getLineNumber() + ' Message : ' + de.getDmlMessage(i) + '\n';
                }
            }
            catch(Exception ex) {
                hasError = true;
                exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';
            }
        }       
    }
    
    /*
@description: Finish Method Update ES20-6594
*/
    public void finish(Database.BatchableContext bc){
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_UpdateTargetListMemberBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', '');
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
        }
    }
}