/**********************************************************************
Name: EDGE_OutletSurveyManagementController
=======================================================================
Req: 
ES20-700
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR              DATE              DETAIL
1.0         Dipanjan Das        2/04/2019        
2.0         Manikant p          09/12/2019        Added logic to send survey start and end date through custom Api (ES20 - 6133)
2.1         Srutadeba C         02/12/2020        Defect ES20-7169 Put check to show Recuring Survey only once in outlet lifecycle.
3.0         Monalisa Halder     07/21/2020        Added logic to filter survey with Global Equivalent  through custom Api (ES20 - 8347)
4.0			Juned Khan			10/28/2020		  Added logic to include survey for Grid survey Recordtype along with Outlet survey.(ES20 - 8767)
5.0			Juned Khan			10/29/2020        Added logic to filter survey with Grouping through custom Api (ES20 - 8797)
***********************************************************************/

public with sharing class EDGE_OutletSurveyManagementController{
    
    
    public static List<EDGE_OutletSurveyWrapper> getOutletSurveys(Id userId){
        
        //List<EDGE_OutletSurveyWrapper> outletSurveyWrapList = new List<EDGE_OutletSurveyWrapper>();
        Map<string, EDGE_OutletSurveyWrapper> outletSurveyWrapMap = new Map<string, EDGE_OutletSurveyWrapper>();
        Set<Id> outletIds = new Set<Id>();
        Set<Id> surveyIds = new Set<Id>();
        Set<String> outletSurveyIds = new Set<String>();
        Set<String> businessRoleSet = new Set<String>();
        Set<String> bRoleGlobalEquivalentSet = new Set<String>();
		Map<Id,String> bRoleGroupingMap = new Map<Id,String>();
        Map<Id, Set<Id>> targetLstWithOutletMap = new Map<Id, Set<Id>>();
        Map<Id, List<Activity_Target_List__c>> targetLstWithSurveyMap = new Map<Id, List<Activity_Target_List__c>>();
        Set<String> surveyType = new Set<String>{'Recurring without previous responses','Recurring with previous response'}; 
            
        for(Outlet_Member__c outletMem : [SELECT Id, Outlet__c FROM Outlet_Member__c WHERE User__c = :userId]){
            outletIds.add(outletMem.Outlet__c);
        }
       
        User user = [SELECT Id,Business_Role__c,Business_Role_ID__c FROM User WHERE Id = :userId];
        if(user.Business_Role_ID__c != null){
         	businessRoleSet.add(user.Business_Role_ID__c);   
        }
        
        if(!businessRoleSet.isEmpty()){
            List<Business_Role__c> bRoleList = [SELECT Id,Name,Global_Equivalent__c,Business_Role_Grouping__c FROM Business_Role__c WHERE Id = :businessRoleSet];
            if(bRoleList != null && bRoleList.size()> 0 && String.isNotBlank(bRoleList[0].Global_Equivalent__c)){
                bRoleGlobalEquivalentSet.add(bRoleList[0].Global_Equivalent__c);
            }
            if(bRoleList != null && bRoleList.size()> 0 && String.isNotBlank(bRoleList[0].Business_Role_Grouping__c)){
                bRoleGroupingMap.put(bRoleList[0].Id,bRoleList[0].Business_Role_Grouping__c);
            }
        }
        
        
        if(outletIds != null && outletIds.size() > 0){
            //Create Target List & Target Outlet Id Set
            for(Target_List_Member__c targetListMem : [SELECT Id, Outlet__c, Target_List__c FROM Target_List_Member__c WHERE Outlet__c IN :outletIds AND Assignment_Status__c = 'Active']){
                if(targetLstWithOutletMap.containsKey(targetListMem.Target_List__c)){
                    targetLstWithOutletMap.get(targetListMem.Target_List__c).add(targetListMem.Outlet__c);
                }else{
                    targetLstWithOutletMap.put(targetListMem.Target_List__c, new Set<Id> { targetListMem.Outlet__c });
                }
            }
            
            //Create Target List & Survey Id Set
            String surveyRecordTypeId = Survey__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Survey').getRecordTypeId();
            //Create Grid Survey Id Set ES20-8767
            String gridSurveyRecordTypeId = Survey__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Grid Survey').getRecordTypeId();
 
            // Adding the global equivalent filter from survey-US 8347 and Grouping filter from survey US-8797
            if(targetLstWithOutletMap != null && targetLstWithOutletMap.keySet().size() > 0){
                for(Activity_Target_List__c actTargetLst : [SELECT Survey__c,Survey__r.Start_Date__c,Survey__r.End_Date__c,Survey__r.Global_Equivalent_Business_Roles__c,Survey__r.Grouping__c, Target_List__c FROM Activity_Target_List__c WHERE Target_List__c IN :targetLstWithOutletMap.keySet() AND Status__c = 'Active' 
                                                            AND Survey__c != null AND Survey__r.IsActive__c = true AND (Survey__r.RecordTypeId =: surveyRecordTypeId OR Survey__r.RecordTypeId =: gridSurveyRecordTypeId )])
                {   
                    String surveyGlobalEquivalent = actTargetLst.Survey__r.Global_Equivalent_Business_Roles__c;
                    String surveyGrouping = actTargetLst.Survey__r.Grouping__c;
                    Boolean result=false;
                    if(String.isNotBlank(surveyGlobalEquivalent)){
                        List<String> surveyGlobalEquivalentList = surveyGlobalEquivalent.split(';');
                        Set<String> surveyGlobalEquivalentSet = new Set<String>();
                        surveyGlobalEquivalentSet.addAll(surveyGlobalEquivalentList);
                        
                        if(bRoleGlobalEquivalentSet != null){
                            result=surveyGlobalEquivalentSet.containsAll(bRoleGlobalEquivalentSet);
                        }
                        
                    }// end of global equivalent filter
                    // if global equivalent is not present then we will check for grouping
                    else if(String.isNotBlank(surveyGrouping)){
                        List<String> surveyGroupingList = surveyGrouping.split(';');
                        List<String> bRoleGroupingList = new List<String>();
                        if(bRoleGroupingMap != null){
                            for(String strbRole :bRoleGroupingMap.values()){
                                if(strbRole != null){
                                    bRoleGroupingList = strbRole.split(';');
                                    for(String broleMatch :bRoleGroupingList){
                                        result = surveyGroupingList.contains(broleMatch);
                                        if(result == true){
                                            break;  
                                        }
                                    }
                                }
                                
                            }
                            
                            
                        }
                    }
                    if(result == true){
                        surveyIds.add(actTargetLst.Survey__c);
                        if(targetLstWithSurveyMap.containsKey(actTargetLst.Target_List__c)){
                            targetLstWithSurveyMap.get(actTargetLst.Target_List__c).add(actTargetLst);
                        }else{
                            targetLstWithSurveyMap.put(actTargetLst.Target_List__c, new List<Activity_Target_List__c> { actTargetLst});
                        }
                    }
                }
                
            }
            
            //Get Existing In Progress Outlet-Survey
            if(surveyIds != null && surveyIds.size()>0){
                for(Outlet_Survey__c outletSurvey : [SELECT Outlet__c, Survey__c,Survey__r.Reccuring_Type__c FROM Outlet_Survey__c WHERE Outlet__c IN :outletIds AND Survey__c IN:surveyIds AND
                                                     ((Achievement_status__c = 'In Progress' AND Survey__r.Reccuring_Type__c in :surveyType) OR
                                                      (Achievement_status__c = 'Complete' AND Survey__r.Reccuring_Type__c='Non Recurring')) ])
                
                {
                    outletSurveyIds.add(outletSurvey.Outlet__c + '_' + outletSurvey.Survey__c);
                   
                }
            }  
           
            //Send Outlet & Survey Reference to Mobile by ignoring those records for which outlet & survey outlet-survey exist
            //that data(outlet-survey record) is already get through standard api. No need to send them again
            
            for(Id targetListId : targetLstWithOutletMap.KeySet()){
                for(Id outletId : targetLstWithOutletMap.get(targetListId)){
                    if(targetLstWithSurveyMap.containsKey(targetListId)){
                        for(Activity_Target_List__c  actTarList : targetLstWithSurveyMap.get(targetListId)){                           
                            string key = outletId + '_' + actTarList.survey__c;
                            if(!outletSurveyIds.contains(key)){
                                EDGE_OutletSurveyWrapper outletSurveyWrap = new EDGE_OutletSurveyWrapper ();
                                outletSurveyWrap.outletId = outletId;
                                outletSurveyWrap.surveyId = actTarList.survey__c;
                                outletSurveyWrap.surveyStartDate = actTarList.survey__r.Start_Date__c;
                                outletSurveyWrap.surveyEndDate = actTarList.survey__r.End_Date__c;
                                //outletSurveyWrapList.add(outletSurveyWrap);
                                outletSurveyWrapMap.put(key, outletSurveyWrap);
                            }
                        }
                    }
                }
            }
        }
         system.debug('@@outletSurveyWrapMap' +outletSurveyWrapMap);
        return outletSurveyWrapMap.values();
    }
}