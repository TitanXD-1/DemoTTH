/**
*@ Name: EDGE_BriefcaseController

*@Req: 
*@ES20-927

*@History                                                            
                                               
*@ VERSION   AUTHOR            DATE              DETAIL
*@1.0    Preyanka Ghosh     17/04/2019      Initial Development  
*@2.0    Monalisa Halder    18/04/2019
*@3.0    Preyanka Ghosh     19/04/2019      To get data for feed item removed with sharing 
*@4.0    Monalisa Halder    02/05/2019      ES20-1208 
*@5.0	   Preyanka Ghosh	  27/11/2019	  ES20-6298 - Add User Id in custom API
*@6.0    Anamika Shukla     12/03/2021      ES20-9899 - Enhancement_To Stop sending Outlet Notes_SFDC
*@7.0    Monalisa Halder    23/04/2021      ES20-10062- change in getLastSurveys method
*@8.0	Shivam Chauhan	 	18/07/2023		142554 - EDGE static code violation for the classes_SFDC_Tech Debt
**/
public inherited sharing class EDGE_BriefcaseController {
    static List<EDGE_BriefcaseWrapper> briefcaseWrapper = new List<EDGE_BriefcaseWrapper>();
    static List<EDGE_SurveyHistoryWrapper> surveyHistoryWrapper = new List<EDGE_SurveyHistoryWrapper>();
    static List<Account> lstAccountWithCall = new List<Account>();   
    
/**
 * @ Method :getVisitDetails
 * @ Purpose: To fetch Last x visits depend on market settings                                                        
**/
    public static void getVisitDetails(Id userId, String tabName){

        Set<Id> setAccountId = new Set<Id>();
        String countryCode;
        List<Market_Setting__c> marketSetting;
        Integer rowLimit =0;
        
        try{            
            //To fetch the account first we need to query Oulet member where is user is a member. There will be only one country per SalesRep            
            for(Outlet_Member__c outletMember : [SELECT Outlet__c, Outlet__r.Country_Code__c FROM Outlet_Member__c WHERE User__c =:userId with SECURITY_ENFORCED]){
                setAccountId.add(outletMember.Outlet__c);
                countryCode = outletMember.Outlet__r.Country_Code__c;
            }
            
            
            
            if(setAccountId != null && setAccountId.size()>0){
                
                /*Depending on Tab we need to fetch data from different field of Market settings to set the limit of Call object, 
                as the limit set on differnt field of market setting hence need to write if else*/
                if(Schema.sObjectType.Market_Setting__c.isAccessible()){
                    if(String.isNotBlank(tabName) && tabName.equalsIgnoreCase('Notes')){
                        marketSetting = [SELECT Notes_History_Last_Visits__c, Geography__c, Geography__r.Code__c FROM Market_Setting__c WHERE Geography__r.Code__c =:countryCode and Notes_History_Last_Visits__c != null LIMIT 1];                    
                        if(marketSetting != null && marketSetting.size()>0){
                            rowLimit = (Integer)marketSetting[0].Notes_History_Last_Visits__c;
                        }
                    } else if(String.isNotBlank(tabName) && tabName.equalsIgnoreCase('Call')){
                        marketSetting = [SELECT Call_History_Last_Visits__c, Geography__c, Geography__r.Code__c FROM Market_Setting__c WHERE Geography__r.Code__c =:countryCode and Call_History_Last_Visits__c != null LIMIT 1];
                        if(marketSetting != null && marketSetting.size()>0){
                            rowLimit = (Integer)marketSetting[0].Call_History_Last_Visits__c;
                        }
                    } else if(String.isNotBlank(tabName) && tabName.equalsIgnoreCase('Survey')){
                        marketSetting = [SELECT Survey_Last_Visit__c, Geography__c, Geography__r.Code__c FROM Market_Setting__c WHERE Geography__r.Code__c =:countryCode and Call_History_Last_Visits__c != null LIMIT 1];
                        if(marketSetting != null && marketSetting.size()>0){
                            rowLimit = (Integer)marketSetting[0].Survey_Last_Visit__c;
                        }
                    }
                }
                
                
                //Need to retrieve Account and fetch number of call record mentioned in rowlimit
                if(rowLimit != null && rowLimit != 0){
                    lstAccountWithCall = [SELECT Id,
                                          (SELECT ID, Status__c, Type_of_Call__r.Name,End_Date__c, Call_Performed_By__r.Name 
                                           FROM Calls__r  WHERE Status__c='Completed' AND End_Date__c != null 
                                           Order by End_Date__c Desc limit :rowLimit 
                                          ) 
                                          FROM Account 
                                          WHERE Id in :setAccountId
                                         
                                         ];
                    
                }
            }
        } catch (Exception excption){
            System.debug(LoggingLevel.Debug,'excption:::'+excption.getCause()+excption.getMessage()+excption.getLineNumber());
        }
    }
    
/**
 * @ Method : createWrapper
 * @ Purpose: To create the wrapper for Notes                                                
**/
    public static void createWrapper(Id accountId, FeedItem objFeedItem, Id contentDocumentId, String userId){
        EDGE_BriefcaseWrapper edgeBrief = new EDGE_BriefcaseWrapper();
        edgeBrief.noteId = objFeedItem.ID;
        edgeBrief.noteBody = objFeedItem.Body;
        edgeBrief.noteCreatedBy = objFeedItem.CreatedBy.Name;
        edgeBrief.noteCreatedById = objFeedItem.CreatedById;
        edgeBrief.noteCreatedDate = objFeedItem.CreatedDate;
        edgeBrief.noteLastModDate = objFeedItem.LastModifiedDate;
        edgeBrief.conDocumentId = contentDocumentId;
        edgeBrief.noteParentId = objFeedItem.ParentId;
        edgeBrief.conVersionId = objFeedItem.RelatedRecordId;
        edgeBrief.outletId = accountId;
        edgeBrief.userId = userId;
        briefcaseWrapper.add(edgeBrief);
    }
    
/**
 * @ Method : getNotesHistory
 * @ Purpose: To fetch all Notes for Last x visits                                                        
**/
    public static List<EDGE_BriefcaseWrapper> getNotesHistory(Id userId){
        Map<Id,Id> mapCallDetails = new Map<Id,Id>();
        Map<Id,DateTime> mapStartCall = new Map<Id,DateTime>();
        Map<Id,DateTime> mapStartAccount = new Map<Id,DateTime>();
        List<DateTime> startDateList = new List<DateTime>();
        Map<Id,List<FeedItem>> mapFeedItemWithAttach = new Map<Id,List<FeedItem>>();
        try{
            if(String.isNotBlank(userId)){
                //Calling the common method and passing tabName as 'Note' to fetch the number of last calls from Market Setting from specific field
                getVisitDetails(userId, 'Notes');  
                
                //Create Map for Account and Call with oldest date as value, so that it can be used in comparison later.  
                if(lstAccountWithCall != null && lstAccountWithCall.size()>0){
                    for(Account accountWithCall : lstAccountWithCall) {
                        if(accountWithCall.Calls__r != null && accountWithCall.Calls__r.size()>0){
                            List<Call__c> lstCall = accountWithCall.Calls__r;
                            for(Call__c objCall : lstCall){
                                mapCallDetails.put(objCall.Id, accountWithCall.Id); 
                                mapStartCall.put(objCall.Id,lstCall[lstCall.size()-1].End_Date__c);
                               
                            }
                            mapStartAccount.put(accountWithCall.Id,lstCall[lstCall.size()-1].End_Date__c);
                            //endDateList.add(lstCall[0].End_Date__c);
                        }
                    }
                    //endDateList.sort();
                    
                    if(mapStartAccount != null && mapStartAccount.size()>0 && mapStartCall != null && mapStartCall.size()>0){
                        startDateList = mapStartAccount.values();
                        startDateList.sort();
                        DateTime currentTime = System.now();
                        //Query FeedItem to get all the feed data with in the timespan
                        //for ES20-9899
                        for(FeedItem objFeedItem : [SELECT Id, Body, RelatedRecordId, CreatedById, CreatedBy.Name, ParentId, CreatedDate, 
                                                    LastModifiedDate 
                                                    FROM FeedItem 
                                                    WHERE (ParentId IN :mapCallDetails.keySet()) AND 
                                                    (Type = 'TextPost' OR Type = 'ContentPost') AND 
                                                    CreatedDate >= :startDateList[0] AND CreatedDate <= :currentTime ORDER BY CreatedDate DESC LIMIT 40000
                                                   ]
                          
                           ) {                               
                               //If Parent ID is Account then we need to get the data from mapStartAccount Map, if parent is Call go to else if
                               if(mapStartAccount.containsKey(objFeedItem.ParentId)){                                
                                   if(objFeedItem.CreatedDate >= mapStartAccount.get(objFeedItem.ParentId) && objFeedItem.CreatedDate <= System.now()){
                                       //If Related record is present then we need to query ContentDocumentlink object to get the ContentDocument ID, else put in wrapper
                                       if(objFeedItem.RelatedRecordId != null){
                                           if(mapFeedItemWithAttach.containsKey(objFeedItem.ParentId)){
                                               mapFeedItemWithAttach.get(objFeedItem.ParentId).add(objFeedItem); 
                                           } else {
                                               mapFeedItemWithAttach.put(objFeedItem.ParentId, new List<FeedItem>{objFeedItem}); 
                                           }
                                           
                                       } else {
                                           createWrapper(objFeedItem.ParentId, objFeedItem, null, userId);
                                       }
                                   }                                                                   
                               } else if(mapCallDetails.containsKey(objFeedItem.ParentId)){
                                   if(objFeedItem.CreatedDate >= mapStartCall.get(objFeedItem.ParentId) && objFeedItem.CreatedDate <= System.now()){
                                       //If Related record is present then we need to query ContentDocumentlink object to get the ContentDocument ID, else put in wrapper
                                       if(objFeedItem.RelatedRecordId != null){
                                           if(mapFeedItemWithAttach.containsKey(objFeedItem.ParentId)){
                                               mapFeedItemWithAttach.get(objFeedItem.ParentId).add(objFeedItem); 
                                           }else{
                                               mapFeedItemWithAttach.put(objFeedItem.ParentId, new List<FeedItem>{objFeedItem});
                                           }
                                            
                                       } else {
                                           createWrapper(mapCallDetails.get(objFeedItem.ParentId), objFeedItem, null, userId);
                                       }
                                   }                                
                               }
                           }
                        //If feed item map contain data then need to query content document link to get the Document ID
                        if(mapFeedItemWithAttach != null && mapFeedItemWithAttach.size()>0){
                            Set<Id> setDocumentId = mapFeedItemWithAttach.keySet();
                            
                            //It will query all the content present for that account or call
                            for(ContentDocumentLink objConDoc : [SELECT Id, ContentDocumentId, ContentDocument.LatestPublishedVersionId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :setDocumentId with SECURITY_ENFORCED]){
                                List<FeedItem> lstFeedItem = mapFeedItemWithAttach.get(objConDoc.LinkedEntityId);
                                //To put data for that particular Content version in wrapper
                                for(FeedItem objFeedItem : lstFeedItem){
                                    if(objFeedItem.RelatedRecordId == objConDoc.ContentDocument.LatestPublishedVersionId){
                                        if(objFeedItem.ParentId != null && objFeedItem.ParentId.getSObjectType() == Account.sObjectType) {                
                                            createWrapper(objFeedItem.ParentId, objFeedItem, objConDoc.ContentDocumentID, userId);
                                        } else if(objFeedItem.ParentId != null && objFeedItem.ParentId.getSObjectType() == Call__c.sObjectType){
                                            createWrapper(mapCallDetails.get(objFeedItem.ParentId), objFeedItem, objConDoc.ContentDocumentID, userId);
                                        }                                    
                                    }                                    
                                }                                                                
                            }
                        }
                    }
                }
            }     
           
        } catch(Exception excption){
            System.debug(LoggingLevel.Debug,'With Exception:::'+excption.getLineNumber()+excption.getCause()+excption.getMessage());
        }
        
        return briefcaseWrapper;        
    }   
    
     
    
    
/**
 *@ Method : getLastSurveys
 *@ Purpose: To fetch all outlet survey for Last visits                                                        
**/
    public static List<EDGE_SurveyHistoryWrapper> getLastSurveys(Id userId){
        Map<Id, Date> endDateMap = new Map<Id, Date> ();
        Set<Id> callIdSet = new Set<Id>();
        List<Date> lstStartDate = new List<Date>();
        try{
            // Putting the account Id and end date of the latest call in a map
            if(String.isNotBlank(userId)){
                getVisitDetails(userId,'Survey');
                if(lstAccountWithCall != null && lstAccountWithCall.size() > 0){
                    for(Account objAccount : lstAccountWithCall){
                        if(objAccount.Calls__r != null && objAccount.Calls__r.size()>0){
                            DateTime dT = objAccount.Calls__r[0].End_Date__c;
                            endDateMap.put(objAccount.Id,date.newinstance(dT.year(), dT.month(), dT.day()));
                            List<Call__c> callList = objAccount.Calls__r;
                            for(Call__c callRec :callList){
                                callIdSet.add(callRec.Id);                                
                            }
                        }                        
                    }
                   
                    //Quering the outlet surveys 
                    if(callIdSet != null && callIdSet.size()>0){
                        lstStartDate = endDateMap.values();
                        lstStartDate.sort();
                        Date startDate = lstStartDate[0];
                        //Querying outlet survey records in the callIdSet and within the timeframe
                       
                        for(Outlet_Survey__c osRec : [SELECT ID, Outlet__c,Call__c,Call__r.Call_Performed_By__r.Name,
                                                      Achievement_status__c, Survey__c,Survey__r.Name,Survey__r.RecordType.Name,Completion_Date__c FROM Outlet_Survey__c 
                                                      WHERE Achievement_status__c='Complete' AND 
                                                      Outlet__c IN :endDateMap.keySet() AND 
                                                      Call__c IN :callIdSet and Completion_Date__c >= :startDate AND Completion_Date__c<=Today with SECURITY_ENFORCED])
                        { 
                            
                            EDGE_SurveyHistoryWrapper edgeSurveyHistory = new EDGE_SurveyHistoryWrapper();
                            edgeSurveyHistory.outletSurveyId = osRec.Id;  
                            edgeSurveyHistory.outletSurveyName = osRec.Survey__r.Name; 
                            edgeSurveyHistory.oSurveyCompDate = osRec.Completion_Date__c; 
                            edgeSurveyHistory.outletId = osRec.Outlet__c; 
                            edgeSurveyHistory.surveyRecordTypeName = osRec.Survey__r.RecordType.Name; 
                            edgeSurveyHistory.surveyId = osRec.Survey__c;
                            edgeSurveyHistory.callPerformedByName = osRec.Call__r.Call_Performed_By__r.Name;
                            surveyHistoryWrapper.add(edgeSurveyHistory); 
                        }
                        
                    }
                }
            }
        }catch(Exception excption){
            system.debug(LoggingLevel.Debug,'excption' +excption+excption.getLineNumber());            
        }
        return surveyHistoryWrapper;
    }
    
/**
 * @ Method :getCallHistory
 * @ Purpose: To fetch call history for Last visits                                                        
**/
 
    public static List<EDGE_BriefcaseWrapper> getCallHistory(Id userId){
        try{
            if(String.isNotBlank(userId)){
                getVisitDetails(userId, 'Call');
                if(lstAccountWithCall != null && lstAccountWithCall.size()>0){
                    for(Account objAccount : lstAccountWithCall){
                        if(objAccount.Calls__r != null && objAccount.Calls__r.size()>0){
                            List<Call__c> callList = objAccount.Calls__r;
                            
                            for(Call__c call :callList){
                                EDGE_BriefcaseWrapper edgeBrief = new EDGE_BriefcaseWrapper();
                                edgeBrief.callId = call.Id;
                                edgeBrief.callType = call.Type_of_Call__r.Name;
                                edgeBrief.callClosedDate = call.End_Date__c;
                                edgeBrief.callSalesRepName = call.Call_Performed_By__r.Name;
                                edgeBrief.callSalesRepId = call.Call_Performed_By__r.Id; 
                                edgeBrief.outletId = objAccount.Id;
                                edgeBrief.userId = userId;
                                briefcaseWrapper.add(edgeBrief);
                            }
                        }                        
                    }
                }
            }    
        } catch(Exception excption){
            System.debug(LoggingLevel.Debug,'excption::::'+excption.getLineNumber());
        }
        
        return briefcaseWrapper;
    }
/**
 * @ Method : getOpportunitiesClosed
 * @ Purpose: To fetch closed opportunities for Last visits                                                        
**/
    public static List<EDGE_BriefcaseWrapper> getOpportunitiesClosed(Id userId){ 
        Map<Id,Account> mapAccountCall = new Map<Id,Account>();
        Map<Id,DateTime> mapStartCall = new Map<Id,DateTime>();
        List<Date> startDateList = new List<Date>();
        Date startDate;
        
        try{
            if(String.isNotBlank(userId)){
                //Calling the common method and passing tabName as 'Call' to fetch the number of last calls from Market Setting
                //Based which querying the closed opportorunities for each account
                getVisitDetails(userId, 'Call');
                if(lstAccountWithCall != null && lstAccountWithCall.size()>0){
                    for(Account accountWithCall : lstAccountWithCall) {
                        mapAccountCall.put(accountWithCall.Id, accountWithCall); 
                        if(accountWithCall.Calls__r != null && accountWithCall.Calls__r.size()>0){
                            List<Call__c> lstCall = accountWithCall.Calls__r;
                            DateTime dT = lstCall[lstCall.size()-1].End_Date__c;
                            startDate = date.newinstance(dT.year(), dT.month(), dT.day());
                            // Putting the account id and oldest call's End Date in a map    
                            mapStartCall.put(accountWithCall.Id,startDate);     
                            startDateList.add(startDate);
                        }
                    }
                    
                    // Sorting the startDate List to get the oldest start Date
                    startDateList.sort();
                    startDate = startDateList[0];
                    for(Opportunity oppRec : [Select ID,AccountId,Name,StageName,CloseDate,Opportunity_Template__c,Opportunity_Template__r.Thumbnail_Document_Id__c,Opportunity_Template__r.Thumbnail_Version_Id__c 
                                              FROM Opportunity where AccountId IN :mapStartCall.keySet() and StageName = 'Closed' and (CloseDate >= :startDate OR CloseDate <= Today) with SECURITY_ENFORCED])
                    {
                        
                        if(mapStartCall.containsKey(oppRec.AccountId) && oppRec.CloseDate >= mapStartCall.get(oppRec.AccountId) && oppRec.CloseDate <= system.today()){                       
                            
                            EDGE_BriefcaseWrapper edgeBrief = new EDGE_BriefcaseWrapper();
                            edgeBrief.opportunityId = oppRec.Id;
                            edgeBrief.opportunityName = oppRec.Name;
                            edgeBrief.oppClosedDate = oppRec.CloseDate;
                            edgeBrief.outletId = oppRec.AccountId;
                            edgeBrief.conDocumentId = oppRec.Opportunity_Template__r.Thumbnail_Document_Id__c;
                            edgeBrief.conVersionId = oppRec.Opportunity_Template__r.Thumbnail_Version_Id__c;
                            edgeBrief.userId = userId;
                            briefcaseWrapper.add(edgeBrief);
                        }    
                    }
                }
            }
        }catch(Exception excption){
            System.debug(LoggingLevel.Debug,'excption::::'+excption +excption.getLineNumber()); 
        }
        
        return briefcaseWrapper;    
    }
    
   
}