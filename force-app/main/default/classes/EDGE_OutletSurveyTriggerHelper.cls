/**********************************************************************
Name: EDGE_OutletSurveyTriggerHelper
=======================================================================
Req: 
ES20-704 - Setting up Recurring surveys- With Prepopulated Responses
ES20-738 - Setting up Recurring surveys- Without Prepopulated Responses
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1  .0    Monalisa Halder   02/004/2019        ES20-704,ES20-738
1.1		 Shahbaz Khan	   22/12/2020		  ES20-9069
***********************************************************************/

public with sharing class EDGE_OutletSurveyTriggerHelper {
    
    /*******************************************************************
    Method  : createOutletSurveys
    Purpose : This methods is to create outlet survey records and outlet survey response 
    records for surveys with Reccuring_Type__c 'Recurring with previous response'
    ********************************************************************/  
    public static void createOutletSurveys(Map<Id, SObject> newItems){
        System.debug('method invoked@@ createOutletSurveys');
        List<Outlet_Survey__c> outletSurveyList = new List<Outlet_Survey__c>();
        List<Outlet_Survey_Response__c> outletSurveyResList = new List<Outlet_Survey_Response__c>();
        Set<Id> outletSurveyIds = new Set<Id>();
        Set<Id> surveyIdset = new Set<Id>();
        Set<Id> outletIdset = new Set<Id>();
        Map<String,Outlet_Survey__c> newoltSurvMap = new Map<String,Outlet_Survey__c>();
        Map<Id,Outlet_Survey__c> newOutletSurveyMap = (Map<Id,Outlet_Survey__c>)newItems;
        Map<Id,List<Id>> inProgressOutletSurveyMap = new Map<Id,List<Id>>();
        Integer freq;
        
        system.debug(LoggingLevel.Debug,'newOutletSurveyMap @'+newOutletSurveyMap);
        
        //Putting the outlet and survey Ids in set
        for(Outlet_Survey__c osRecord :newOutletSurveyMap.Values()){
            surveyIdset.add(newOutletSurveyMap.get(osRecord.id).Survey__c);
            outletIdset.add(newOutletSurveyMap.get(osRecord.id).Outlet__c);
            
        }
        // Putting the existing in  progress outlet surveys in a map
        for(Outlet_Survey__c existInProgressOS :[Select Id,Outlet__c,Survey__c,Completion_Date__c,Survey_Valid_From__c,Survey__r.Frequency__c,Survey__r.Reccuring_Type__c,Survey__r.End_Date__c,
                                                Achievement_status__c from Outlet_Survey__c where Outlet__c IN :outletIdset and Survey__c IN :surveyIdset  and Achievement_status__c = 'In Progress']){
            
            if(inProgressOutletSurveyMap.get(existInProgressOS.Outlet__c) != null){
                inProgressOutletSurveyMap.get(existInProgressOS.Outlet__c).add(existInProgressOS.Survey__c);
                system.debug(LoggingLevel.Debug,'inProgressOutletSurveyMap @'+inProgressOutletSurveyMap);
            }
            else{
                List<Id> surveyIdList = new List<Id>();
                surveyIdList.add(existInProgressOS.Survey__c);
                inProgressOutletSurveyMap.put(existInProgressOS.Outlet__c,surveyIdList);
                system.debug(LoggingLevel.Debug,'inProgressOutletSurveyMap @'+inProgressOutletSurveyMap);
            }
            system.debug('@@inProgressOutletSurveyMap' +inProgressOutletSurveyMap);                                        
         }
        
        //Creating a map of Outlet Survey Records where Achievement_status__c is 'Complete'
        // Putting the survey ids and outlet ids in a set
        for(Outlet_Survey__c oltSurvObj :[Select Id,Outlet__c,Survey__c,Completion_Date__c,Survey_Valid_From__c,Survey__r.Frequency__c,Survey__r.Reccuring_Type__c,Survey__r.End_Date__c,
                                          Achievement_status__c from Outlet_Survey__c where Id IN :newItems.keyset() and Achievement_status__c = 'Complete' 
                                          and (Survey__r.Reccuring_Type__c = 'Recurring without previous responses' OR Survey__r.Reccuring_Type__c = 'Recurring with previous response')]){ 
               System.debug('oltSurvObj query@@@@ '+ oltSurvObj);
               System.debug('inProgressOutletSurveyMap query@@@@ '+inProgressOutletSurveyMap);
               if(!(inProgressOutletSurveyMap.containsKey(oltSurvObj.Outlet__c) &&  inProgressOutletSurveyMap.get(oltSurvObj.Outlet__c).contains(oltSurvObj.Survey__c) )) {                      
                system.debug('inside if loop'); 
                   if(oltSurvObj.Survey__r.Reccuring_Type__c == 'Recurring with previous response'){
                    outletSurveyIds.add(oltSurvObj.Id);
                }
                                                  
                if(oltSurvObj.Survey__r.Frequency__c !=null){
                    freq = Integer.valueOf(oltSurvObj.Survey__r.Frequency__c);
                }   
                System.debug('checking the data@@@ ');
                //Creating outlet survey records for surveys with Reccuring_Type__c -Recurring without previous responses and Recurring with previous response
                Outlet_Survey__c newOutletSurvey = new Outlet_Survey__c (Achievement_status__c = 'In Progress',
                                                                         Outlet__c = oltSurvObj.Outlet__c,
                                                                         Survey__c = oltSurvObj.Survey__c ,
                                                                         Survey_Valid_From__c = oltSurvObj.Completion_Date__c.addDays(freq)
                                                                        );
                if(oltSurvObj.Survey__r.End_Date__c == null || (oltSurvObj.Survey__r.End_Date__c != null && newOutletSurvey.Survey_Valid_From__c < oltSurvObj.Survey__r.End_Date__c )) {                                 
                    outletSurveyList.add(newOutletSurvey); 
                } 
                   System.debug('checking the data@@@ outletSurveyList '+ outletSurveyList);
            } 
        }
        
        // if the new outlet survey list is not empty, insert the outlet survey records
        if(!outletSurveyList.isEmpty() && outletSurveyList.size()>0 ){
            if(Schema.sObjectType.Outlet_Survey__c.isCreateable() ) {
                System.debug('ready to insert@@@ outletSurveyList '+ outletSurveyList);
                insert outletSurveyList;  
            }
            
            //Creating a map of composite key and new outlet survey records
            for(Outlet_Survey__c newOSRec :outletSurveyList){
                string newotSyCompositeKey = newOSRec.Outlet__c+'_'+newOSRec.Survey__c;
                newoltSurvMap.put(newotSyCompositeKey,newOSRec);
            }
            
            //Creating Outlet Survey Response records & included Option_Name__c,Option_ID__c fields for ES20-9069
            //Kept a filter on survey question in line 98 for ES20-9712 by saranya
            for(Outlet_Survey_Response__c osrespRec :[Select Id, Outlet_Survey__c, Outlet_Survey__r.Outlet__c, Outlet_Survey__r.Survey__c,
                                                      Response__c, Survey_Question__c,Survey_Question__r.Active__c,Option_Name__c,Option_ID__c from Outlet_Survey_Response__c where Outlet_Survey__c 
                                                      IN :outletSurveyIds and Survey_Question__r.Active__c=True]){
                system.debug(LoggingLevel.Debug,'osrespRec @'+osrespRec);                                         
                Outlet_Survey_Response__c newOutletSurveyRes = new Outlet_Survey_Response__c(Outlet_Survey__c = newoltSurvMap.get(osrespRec.Outlet_Survey__r.Outlet__c+'_'+osrespRec.Outlet_Survey__r.Survey__c).Id,
                                                                                             Response__c = osrespRec.Response__c,
                                                                                             Survey_Question__c = osrespRec.Survey_Question__c,
                                                                                             Option_Name__c = osrespRec.Option_Name__c,//populated values in Option_Name__c,Option_ID__c for ES20-9069 
                                                                                             Option_ID__c = osrespRec.Option_ID__c);
                                                          
                system.debug(LoggingLevel.Debug,'newOutletSurveyRes @'+newOutletSurveyRes);                                                                            
                outletSurveyResList.add(newOutletSurveyRes);
                system.debug(LoggingLevel.Debug,'outletSurveyResList @'+outletSurveyResList);                                         
            }
            
            // if the new outlet survey response list is not empty, insert the outlet survey response records
            if(!outletSurveyResList.isEmpty() && outletSurveyResList.size()>0){
                if(Schema.sObjectType.Outlet_Survey_Response__c.isCreateable() ) {
                    
                    insert outletSurveyResList;
                }
            }
        }
    }
}