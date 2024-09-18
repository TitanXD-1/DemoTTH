/**********************************************************************
Name: EDGE_BespokeHistoryController
=======================================================================
Req: 
ES20-4063
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR              DATE            DETAIL
1.0       Amar Deep          03/09/2019      Initial Development 
2.0       Preyanka Ghosh	 03/12/2019		 ES20-6298 
***********************************************************************/

public inherited sharing class EDGE_BespokeHistoryController {
        
    /*******************************************************************
    Purpose: To fetch Bespoke Details for the user passed from mobile                                                       
    ********************************************************************/    
    public static List<EDGE_BespokeWrapper> getBespokeOrderDetails(Id userId){
        
        //Variables
        Set<Id> accountIdSet = new Set<Id>();
        Set<Id> allaccountIdSet = new Set<Id>();
        List<Account> accountList = new List<Account>();
        List<EDGE_BespokeWrapper> bespokeorderList = new List<EDGE_BespokeWrapper>();
        Integer recordLimit = 0;
        String countryCode = '';
        List<Market_Setting__c> marketSetting;
        List<EDGE_BespokeWrapper> bespokeList = new List<EDGE_BespokeWrapper>();
        
        if(userid!=null){
            //Fetching all the outlets of the user by querying outlet members
            for(Outlet_Member__c outletMemObj : [Select Id, Outlet__c, Outlet__r.Country_Code__c 
                                                 from Outlet_Member__c where User__c =:userid])
            {
                accountIdSet.add(outletMemObj.Outlet__c);
                countryCode = outletMemObj.Outlet__r.Country_Code__c;
            }
        }
        
        //Fetching the no of bespoke records need to be displayed for user's market
        if(String.isNotBlank(countryCode) && Schema.SObjectType.Market_Setting__c.isAccessible() && Schema.SObjectType.Geography__c.isAccessible()){
            marketSetting = [Select Id, Bespoke_History_Number__c, Geography__r.Code__c 
                             from Market_Setting__c where Geography__r.Code__c =:countryCode AND 
                             Bespoke_History_Number__c != NULL LIMIT 1];
            if(marketSetting!=null && marketSetting.size()>0){
                recordLimit = (Integer)marketSetting[0].Bespoke_History_Number__c;
            }
        }
        
        //Fetching all the outlet which is related to Bespoke record 
        if(accountIdSet!=null && accountIdSet.size()>0 && recordLimit!=null && Schema.SObjectType.Account.isAccessible() && Schema.SObjectType.Bespoke__c.isAccessible() && Schema.SObjectType.Delivery_Partner__c.isAccessible()){
            
            accountList = [Select Id, (Select Id,Name,Account__c,Delivery_Partner__c,Status__c,LastModifiedDate, RecordTypeId,Budget__c,
                                       Contract__c,Customer_Contact_Email__c,Customer_Contact_Phone__c,Customer_Preferred_Contact__c,
                                       Diageo_Contact__c,Diageo_Contact_Email__c,Diageo_Contact_Phone_Number__c,End_Date__c,
                                       Start_Date__c,Incremental_NSV__c,Incremental_Volume__c,ROI__c,Project_Name__c,CreatedDate,
                                       Segment_Activation__c,Activity_Objectives__c,Product_Focus__c,Site_Visit_Date__c,Site_Visit_Time__c,
                                       Venue_Notes__c,Bump_In__c,Bump_Out__c,CreatedById 	
                                       FROM Bespokes__r WHERE Status__c = 'Order Placed'  
                                       Order by LastModifiedDate Desc limit :recordLimit) 
                           from Account WHERE Id in :accountIdSet];
        }
        
        if(accountList!=null && accountList.size()>0){
            for(Account acctObj : accountList){
                if(acctObj.Bespokes__r!=null && acctObj.Bespokes__r.size()>0){
                    for(Bespoke__c bespoke : acctObj.Bespokes__r){
                        EDGE_BespokeWrapper bespokeWrapper = new EDGE_BespokeWrapper();
                        bespokeWrapper.bespokeId = bespoke.Id;
                        bespokeWrapper.bespokeName = bespoke.Name;
                        bespokeWrapper.outletId = bespoke.Account__c;
                        bespokeWrapper.deliveryPartnerId = bespoke.Delivery_Partner__c;
                        bespokeWrapper.bespokeStatus = bespoke.Status__c;
                        bespokeWrapper.lastModifiedDate = bespoke.LastModifiedDate;
                        bespokeWrapper.recordTypeId = bespoke.RecordTypeId;
                        bespokeWrapper.bespokeBudget = bespoke.Budget__c;
                        bespokeWrapper.bespokeContractId = bespoke.Contract__c;
                        bespokeWrapper.customerContactEmail = bespoke.Customer_Contact_Email__c;
                        bespokeWrapper.customerContactPhone = bespoke.Customer_Contact_Phone__c;
                        bespokeWrapper.customerPreferredContact = bespoke.Customer_Preferred_Contact__c;
                        bespokeWrapper.diageoContact = bespoke.Diageo_Contact__c;
                        bespokeWrapper.diageoContactEmail = bespoke.Diageo_Contact_Email__c;
                        bespokeWrapper.diageoContactPhoneNumber = bespoke.Diageo_Contact_Phone_Number__c;
                        bespokeWrapper.bespokeEndDate = bespoke.End_Date__c;
                        bespokeWrapper.bespokeStartDate = bespoke.Start_Date__c;
                        bespokeWrapper.incrementalNSV = bespoke.Incremental_NSV__c;
                        bespokeWrapper.incrementalVolume = bespoke.Incremental_Volume__c;
                        bespokeWrapper.bespokeROI = bespoke.ROI__c;
                        bespokeWrapper.bespokeProjectName = bespoke.Project_Name__c;
                        bespokeWrapper.createdDate = bespoke.CreatedDate;
                        bespokeWrapper.segmentActivation = bespoke.Segment_Activation__c;
                        bespokeWrapper.activityObjectives = bespoke.Activity_Objectives__c;
                        bespokeWrapper.productFocus = bespoke.Product_Focus__c;
                        bespokeWrapper.siteVisitDate = bespoke.Site_Visit_Date__c;
                        bespokeWrapper.siteVisitTime = bespoke.Site_Visit_Time__c;
                        bespokeWrapper.venueNotes = bespoke.Venue_Notes__c;
                        bespokeWrapper.bumpIn = bespoke.Bump_In__c;
                        bespokeWrapper.bumpOut = bespoke.Bump_Out__c;
                        bespokeWrapper.userId = userid;
                    	bespokeList.add(bespokeWrapper);                        
                    }                    
                }
            }
        }
        
        return bespokeList;
    }
}