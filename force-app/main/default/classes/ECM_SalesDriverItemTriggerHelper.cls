/*
* Class Name : ECM_SalesDriverItemTriggerHelper
* @description: Helper Class for ECM_SalesDriverItemTriggerHandler
* @history
* VERSION    AUTHOR               DATE             DETAIL
* 1.0        Keshava Murthy M     27/01/2022      	ECM-5127 : Disable Edit for related objects of Contract_SFDC_GLO

* 1.1        Pratap Sen           11/02/2022        ECM-5218 : Fix for the Bug - Enable Profile Check

*/

public without sharing class ECM_SalesDriverItemTriggerHelper {
    /*


    * @description : Checking profiles to edit/delete SD Item when Contract status is not draft..
    * @return : void
    * @param : trigger.newMap,trigger.oldMap
    */
    public static void disableSdItem(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        String userProfile = [SELECT Name FROM Profile WHERE id = :UserInfo.getProfileId()].Name;
        List<String> allowedProfiles = System.Label.ECM_Profiles_for_ContractRelatedRecordEdit.split(',');//system admin,EDGE BAU user,Int Dataloader
        if(userProfile != NULL && !allowedProfiles.contains(userProfile)){
            if(newItems != NULL){
                disableSdItemEdit(newItems.Values());
            }
            else{
                disableSdItemDelete(oldItems.Values());          
            }
        }
    }
    /*


    * @description : Not allow any profiles to edit Sales Driver Item when Contract status is In Approval, Approved, Inactive, Active, Legal Review, Cancelled.
    * @return : void
    * @param : trigger.New
    */
    public static void disableSdItemEdit(List <ECM_Sales_Driver_Item__c> newSdItems){


        Map<id,String> conMap = new Map<id,String>();
        try{
            for (ECM_Sales_Driver_Item__c sdItemRecord: [select id, Contract__c,Contract__r.Status from ECM_Sales_Driver_Item__c where Id in:newSdItems]) {         
                if (sdItemRecord.Contract__c != null) {
                    conMap.put(sdItemRecord.Contract__c,sdItemRecord.Contract__r.Status);                    


                }                 
            }
            List<String> conStatus = Label.ECM_Contract_Status_Check.split(',');//In Approval Process,Approved,InActive,Active,Legal Review,Cancelled
            if(!conMap.isEmpty() && conStatus.size()>0){
                for (ECM_Sales_Driver_Item__c sdItemObj: newSdItems) {         
                    if (sdItemObj.Contract__c != null && conMap.containsKey(sdItemObj.Contract__c)) { 
                        if(conStatus.contains(conMap.get(sdItemObj.Contract__c))){
                            sdItemObj.addError(Label.ECM_Disable_Edit_Error);//Edit disabled. You can only edit when associated contract is in draft status.
                            
                        }
                    }
                }
            }
        }catch(Exception e){
            System.debug('Exception Caught in disableSdItemEdit method of ECM_SalesDriverItemTriggerHelper at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
        }
        
    }


	/*
	* @description : Not allow any profiles to delete Sales Driver when Contract status is In Approval, Approved, Inactive, Active, Legal Review, Cancelled.
	* @return : void
	* @param : trigger.old
	*/
    public static void disableSdItemDelete(List <ECM_Sales_Driver_Item__c> oldSdItems){
        Map<id,String> conStatMap = new Map<id,String>();
        try{
            for (ECM_Sales_Driver_Item__c sdItem: [select id, Contract__c,Contract__r.Status from ECM_Sales_Driver_Item__c where Id in:oldSdItems]) {
                if (sdItem.Contract__c != null) {   
                    conStatMap.put(sdItem.Contract__c,sdItem.Contract__r.Status);                    
                }                 
            }
            List<String> conStatusLab = Label.ECM_Contract_Status_Check.split(',');//In Approval Process,Approved,InActive,Active,Legal Review,Cancelled
            if(!conStatMap.isEmpty() && conStatusLab.size()>0){
                for (ECM_Sales_Driver_Item__c sdItemsObj: oldSdItems) {         
                    if (sdItemsObj.Contract__c != null && conStatMap.containsKey(sdItemsObj.Contract__c)) { 
                        if(conStatusLab.contains(conStatMap.get(sdItemsObj.Contract__c))){
                            sdItemsObj.addError(Label.ECM_Disable_Delete_Error);//Delete disabled. You can only delete when associated contract is in draft status.                       
                        }
                    }
                }
            }
        }catch(Exception e){
            System.debug('Exception Caught in disableSdItemDelete method of ECM_ContractItemTriggerHelper at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
        }
        
    }


}