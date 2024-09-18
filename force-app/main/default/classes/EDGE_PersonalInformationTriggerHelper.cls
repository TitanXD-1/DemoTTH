/**********************************************************************
Name: EDGE_PersonalInformationTriggerHelper
=======================================================================
Purpose: Trigger Helper Class for Personal Information object 
=======================================================================
History                                                            
-------                                                            
VERSION  	  AUTHOR            DATE              DETAIL
1.0                          15/02/2020     Initial Development
***********************************************************************/

public without sharing class EDGE_PersonalInformationTriggerHelper {
    
     /*******************************************************************
    Method  : populateUserCountry
    Purpose : This method will populate the Geography and sales manager of the User tagged 
    ********************************************************************/
    public static void populateUserCountry(List<SObject> newItems){
        set<Id> userIdSet = new Set<Id>();
        Map<Id,String> userCountryMap = new Map<Id,String>();
        Map<Id,String> userManagerMap = new Map<Id,String>();
        Map<Id,Geography__c> userGeoMap = new Map<Id,Geography__c>(); 
        List<Personal_Information__c> personalInfoList = new List<Personal_Information__c>();
        
        if(newItems != null){
            for(Sobject obj : newItems){
                Personal_Information__c personalInfo = (Personal_Information__c)obj;                
                userIdSet.add(personalInfo.User__c);
                personalInfoList.add(personalInfo);
            } 
        }
        if(userIdSet != null){
            for(User usrId : [SELECT id, Available_Countries__c, ManagerId from user where id IN : userIdSet]){
                userCountryMap.put(usrId.id , usrId.Available_Countries__c);
                userManagerMap.put(usrId.id ,usrId.ManagerId);
            } 
        }
        if(userCountryMap != null){
            List<Geography__c> geoList = [Select id , Name from Geography__c where code__c IN : userCountryMap.values()];
            for(Id usrId : userCountryMap.keySet()){ 
                for(Geography__c geoRec : geoList ){
                    userGeoMap.put(usrId,geoRec);
                }   
            }
        }
        if(personalInfoList.size()>0){
            for(Personal_Information__c personalInfo :personalInfoList ){
                if(userGeoMap.size()>0 && userGeoMap.containsKey(personalInfo.User__c) && userManagerMap.containsKey(personalInfo.User__c)){
                    personalInfo.Geography__c = userGeoMap.get(personalInfo.User__c).id ;
                    personalInfo.Sales_Manager__c = userManagerMap.get(personalInfo.User__c);
                }
            } 
        }
    }
    
    public static Map<Id,Market_Setting__c> populateCarChangeApprovalMap(Map<Id,Id> personInfoCountryMap){
        Map<Id,Market_Setting__c> carChangeApprovalMap = new Map<Id,Market_Setting__c>();
        for(Market_Setting__c marketset : [SELECT Id,Car_Change_Approval__c,Display_in_Kilometer__c,Geography__c,Fleet_Manager__c, Last_Travel_Log_Date__c FROM Market_Setting__c WHERE Geography__c IN : personInfoCountryMap.values()]){
            carChangeApprovalMap.put(marketset.Geography__c,marketset);
        }
        return carChangeApprovalMap;
    }
    
    /*******************************************************************
    Method  : checkCarDetailsApprover
    Purpose : 
    ********************************************************************/
    
    public static void checkCarDetailsApprover(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        
        List<Personal_Information__c> personInfoList = new List<Personal_Information__c>();
        Map<Id,Id> personInfoCountryMap = new Map<Id,Id>();
        Map<Id,Personal_Information__c> oldItemsMap ;
        Set<Id> successEmailsTravelLogBooks = new Set<Id>();
    	Set<Id> failureEmailsTravelLogBooks = new Set<Id>();
        
        Map<Id,Market_Setting__c> carChangeApprovalMap = new Map<Id,Market_Setting__c>();
        List<Personal_Information__c> triggerProcessList = new List<Personal_Information__c>();
        List<Personal_Information__c> allApprovedList = new List<Personal_Information__c>();
        List<Personal_Information__c> personInfoListToUpdate = new List<Personal_Information__c>();
        
        Map<Id, Id> travlLogToTrvLogBookMap = new Map<Id, Id>();
        List<Travel_Logbook__c> traveLogBookList = new List<Travel_Logbook__c>();
        Map<Id, List<Travel_Log__c>> pInfoIdToTLMap = new Map<Id, List<Travel_Log__c>>();
        Set<Id> trvlLogBookIds = new Set<Id>();
        Map<Id, Personal_Information__c> personalInfoIdToRecMap = new Map<Id, Personal_Information__c>();
        Map<Id, Id> trvlIdToCountryIdMap = new Map<Id, Id>();
        
        if(oldItems != null){
            oldItemsMap = (Map<Id,Personal_Information__c>)oldItems;
        }
        
        //System.debug('oldItems = '+ oldItems);
        //System.debug('newItems = '+ newItems);
        
        for(Sobject obj : newItems.values()){
            Personal_Information__c personalInfo = (Personal_Information__c)obj;
            if((personalInfo.New_Registration_Number__c != null && oldItemsMap.get(personalInfo.Id).New_Registration_Number__c != personalInfo.New_Registration_Number__c) ||
               (personalInfo.New_Car_Model__c != null && oldItemsMap.get(personalInfo.Id).New_Car_Model__c != personalInfo.New_Car_Model__c)){
                   personInfoList.add(personalInfo);
                   personInfoCountryMap.put(personalInfo.Id,personalInfo.Geography__c);
               }else if(oldItemsMap.get(personalInfo.Id).Car_Approval_Status__c == 'Approval_In_Progress' && personalInfo.Car_Approval_Status__c =='Approved'){
                   allApprovedList.add(personalInfo);
                   personInfoCountryMap.put(personalInfo.Id,personalInfo.Geography__c);
               }            
        }
        System.debug('personInfoCountryMap '+personInfoCountryMap);
        
        If(personInfoCountryMap.size()>0){
            carChangeApprovalMap = populateCarChangeApprovalMap(personInfoCountryMap);
            System.debug('carChangeApprovalMap = '+ carChangeApprovalMap);
        }
        If(personInfoList.size()>0){
            for(Personal_Information__c personalInfo : personInfoList){
               Personal_Information__c newPersonalInfo = new Personal_Information__c(id=personalInfo.id,Car_Approval_Status__c=personalInfo.Car_Approval_Status__c);
                if(personInfoCountryMap.size()>0 && personInfoCountryMap.containsKey(personalInfo.Id)) {
                    if(newPersonalInfo.Car_Approval_Status__c == 'Pending'){
                        
                        if(carChangeApprovalMap.get(personInfoCountryMap.get(personalInfo.Id)).Car_Change_Approval__c == 'Sales Manager Approval Required'){
                            newPersonalInfo.Car_Approval_Status__c = 'Approval_In_Progress';  
                            personInfoListToUpdate.add(newPersonalInfo);
                        } else if(carChangeApprovalMap.get(personInfoCountryMap.get(personalInfo.Id)).Car_Change_Approval__c == 'No Approval Required'){
                            newPersonalInfo.Car_Approval_Status__c = 'Approved'; 
                            newPersonalInfo.Registration_Number__c = personalInfo.New_Registration_Number__c;
                            newPersonalInfo.Car_Model__c = personalInfo.New_Car_Model__c;
                            triggerProcessList.add(personalInfo);
                            personInfoListToUpdate.add(newPersonalInfo);
                        }
                    }
                }
            }
        }
        
        System.debug('personInfoListToUpdate '+personInfoListToUpdate);
        if(personInfoListToUpdate.size()>0){
         	update personInfoListToUpdate;   
        }
        
        allApprovedList.addAll(triggerProcessList);
        System.debug('allApprovedList '+ allApprovedList);
        for(Personal_Information__c pInfoRec : allApprovedList){ 
            personalInfoIdToRecMap.put(pInfoRec.Id,pInfoRec);
        } 
        
        if(allApprovedList != null && allApprovedList.size() > 0){
        	Map<Id, Boolean> travelLogBookIdsMap = EDGE_TravelLogBookGenBatchHelper.generateTravelLogBook(allApprovedList,true); //pInfoIdToTLMap, personalInfoIdToRecMap,carChangeApprovalMap
            
            if(travelLogBookIdsMap != null && travelLogBookIdsMap.keySet().size() > 0){
                for(Id travelLogBookId : travelLogBookIdsMap.keySet()){
                    if(travelLogBookIdsMap.get(travelLogBookId)){
                        failureEmailsTravelLogBooks.add(travelLogBookId);
                    }else{
                        successEmailsTravelLogBooks.add(travelLogBookId);
                    }
                }
            }
            EDGE_TravelLogBookGenBatchHelper.markTravelLogBooksEmailSent(successEmailsTravelLogBooks);
        }
        
    }
   /*********************************************************************************
      Method : createCustomShare 
      Purpose : This will be used to create custom sharing of personal information object 
    ************************************************************************************/
    public static void createCustomShare(Map<Id, SObject> newItems){
     
        List<personal_information__share> personInfoshareList = new list<personal_information__share>();
        
        for(sObject pInfoSobject : newItems.values()){
            personal_information__c pInfoRec = (personal_information__c)pInfoSobject ;
            if(pInfoRec.Sales_Manager__c != null){
                personal_information__share pInfoShareManger = new  personal_information__share();
                pInfoShareManger.ParentId = pInfoRec.ID;
                pInfoShareManger.UserOrGroupId =pInfoRec.Sales_Manager__c;
                pInfoShareManger.AccessLevel = 'Read';
                personInfoshareList.add(pInfoShareManger);
            }
        }
        if(personInfoshareList != null && personInfoshareList.size() > 0){
            Database.insert(personInfoshareList ,false);
        }
        
    }
}