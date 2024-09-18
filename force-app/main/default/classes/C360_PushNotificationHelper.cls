/*
* @Name: C360_PushNotificationHelper
* @description: This class is to push notification for the cases created for C360 project from case management console/D1
* @History                                                            

VERSION         AUTHOR                  DATE                    DETAIL
1.0             Swagat Shaw            15/09/2023               Code Refinement(145716)
2.0             Joshraj Sen            15/02/2024               150716
*/ 

public without sharing class C360_PushNotificationHelper {
    Static MAP<String,MAP<String,Customer_360_Entitlement_Setting__mdt>> notificationConfigWithCountry = new MAP<String,MAP<String,Customer_360_Entitlement_Setting__mdt>>();
    Static Map<Id, String> accIdToNameMap = new Map<Id,String>();
    Static Map<String, String> accountWithPrimaryUser = new Map<String, String>();
    Static Map<String, List<String>> accountWithReps = new Map<String, List<String>>();
    Static Id diageoOneCasesRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Diageo One Cases').getRecordTypeId();    
    
    /* @description : sendPushNotification - Sends push notification to the applicable users for selected case type & sub-type
* @return : void
* @param : List<Case>
*/
    public static void sendPushNotification(List<Case> casesToUpdate){
        Set<String> filteredAccountId = new Set<String>();
        List<Case> filteredCase = new List<Case>();
        
        for(Case updatedCase : casesToUpdate){
            if(updatedCase.RecordTypeId == diageoOneCasesRecordTypeId && updatedCase.Origin != 'EDGE 365 Global'){
                filteredCase.add(updatedCase);
                filteredAccountId.add(updatedCase.AccountId);
            }
        }
        if(filteredCase.size() >0){
            filteredCaseToCountryMap(filteredCase,filteredAccountId);
        }
        for(Case caseObj : filteredCase){   
            validatingCaseReceipents(caseObj);
        }
    }
    public static void filteredCaseToCountryMap(List<Case> filteredCase,Set<String> filteredAccountId){
        List<String> listOfRoles = System.label.C360_RolesForCasePushNotification.split(';');
        if((Schema.sObjectType.Customer_360_Entitlement_Setting__mdt.isAccessible() || Schema.sObjectType.Outlet_Member__c.isAccessible())){ 
            for (Customer_360_Entitlement_Setting__mdt notificationSettings : [SELECT MasterLabel,C360_EnablePushNotificationForQR__c,C360_Country_Code__c,C360_Type_Sub_Type__c,C360_EnablePushNotificationForSR__c,C360_IsActive__c FROM Customer_360_Entitlement_Setting__mdt WHERE C360_IsActive__c = true]) {
                List<String> countries = notificationSettings.C360_Country_Code__c.split('_');
                for(String country : countries) {
                    if(notificationConfigWithCountry.containsKey(country)){
                        notificationConfigWithCountry.get(country).put(notificationSettings.C360_Type_Sub_Type__c, notificationSettings);
                    }
                    else{
                        notificationConfigWithCountry.put(country, new MAP<String, Customer_360_Entitlement_Setting__mdt>{notificationSettings.C360_Type_Sub_Type__c => notificationSettings}); 
                    } 
                }                                                                  
            }
            for(Outlet_Member__c om : [SELECT Id, User__c, Outlet_Role__c, Outlet__c, Outlet__r.Name FROM Outlet_Member__c WHERE Outlet_Role__c IN : listOfRoles AND Outlet__r.Account_Type__c INCLUDES ('Ship-To') AND Outlet__c IN :filteredAccountId LIMIT 50000]){
                accIdToNameMap.put(om.Outlet__c, om.Outlet__r.Name);
                populateAccountWithReps(om);
            }
        }
    }
    
    /**
* @description : populateAccountWithReps - Filter Outlet Members
* @return : void
* @param : Outlet Member
*/
    public static void populateAccountWithReps(Outlet_Member__c om){
        if(om.Outlet_Role__c == 'Primary'){
            accountWithPrimaryUser.put(om.Outlet__c, om.User__c);
        }else{
            if(!accountWithReps.containsKey(om.Outlet__c)){
                accountWithReps.put(om.Outlet__c, new List<String>());
            }
            accountWithReps.get(om.Outlet__c).add(om.User__c);
        }
    }
    
    /**
* @description : validatingCaseReceipents - Sends push notification to the applicable users
* @return : void
* @param : Case
*/
    public static void validatingCaseReceipents(Case caseObj){
        Set<String> caseReceipents =  new Set<String>()  ;
        String msgToPush;
        Map<String,Object> custom = new Map<String,Object>();//150716
        if(accIdToNameMap.containsKey(caseObj.AccountId) && notificationConfigWithCountry.containsKey(caseObj.Country__c)){
            Map<String, Customer_360_Entitlement_Setting__mdt> configMap = notificationConfigWithCountry.get(caseObj.Country__c);
            String typeSubType = caseObj.Type + '-' + caseObj.D1_Subject__c;
            msgToPush = System.label.C360_MsgForCasePushNotification.replace('@', caseObj.CaseNumber).replace('#', accIdToNameMap.get(caseObj.AccountId));
            custom=C360_CustomerServiceNotificationHelper.generateKeyValueParameters(caseObj);////150716
            if(configMap.containsKey(typeSubType) && configMap.get(typeSubType).C360_EnablePushNotificationForQR__c == true && !accountWithReps.isEmpty()){
                System.debug(LoggingLevel.Debug,'@@@ Quality Rep Notification is  '+configMap.get(typeSubType).C360_EnablePushNotificationForQR__c);
                caseReceipents.addAll(accountWithReps.get(caseObj.AccountId));
            }
            if(configMap.containsKey(typeSubType) && configMap.get(typeSubType).C360_EnablePushNotificationForSR__c == true){
                 System.debug(LoggingLevel.Debug,'@@@ Sales Rep Notification is  '+configMap.get(typeSubType).C360_EnablePushNotificationForSR__c);
                caseReceipents.add(accountWithPrimaryUser.get(caseObj.AccountId));
            }
            caseReceipents.remove(null);
        }
        
        if(caseReceipents.size()>0){
            C360_CustomerServiceNotificationHelper.pushNotificationMethodforCase(caseReceipents, msgToPush,custom);//150716
        }
    } 
}