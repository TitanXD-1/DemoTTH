/*
 * @Name: ECM_RoleAgreementTriggerHelper
 * @Description: This is the Helper class for RoleAgreementTrigger
 * @History                                                            
 *                                                       
 * VERSION    AUTHOR       DATE                 DETAIL
 *   1.0     Pratap Sen  13-09-2021  Initial Development for ECM-4416
*/ 

public class ECM_RoleAgreementTriggerHelper {
	/*
    * @Name : RoleAgreementDuplicateCheck (ECM-4416)
	* @description : This method is used to check duplicate Role Agreement
	* @return : void
	* @param : List of Role Agreement - Trigger.New , Map of Old Role Agreement - Trigger.oldMap
	*/
    public static void RoleAgreementDuplicateCheck(List<ECM_Role_Agreement__c> newRoleAgreementList,Map<Id, SObject> oldRoleAgreementMap)
    {
        Set<Id> newRolesSet = new Set<Id>();
        Set<Id> newAgrmntSet = new Set<Id>();
        Map<String,ECM_Role_Agreement__c> mapOfNewRA = new Map<String,ECM_Role_Agreement__c>();
        Map<Id,ECM_Role_Agreement__c> mapOfOldRA;
        Boolean isUpdateCall = false;
        
        if(oldRoleAgreementMap!=null)//Check the trigger is called on Insert or Update
        {
            isUpdateCall = true;
            mapOfOldRA = (Map<Id,ECM_Role_Agreement__c>)oldRoleAgreementMap;
        }
        
        //Fetch BR & AT from only new Role Agreements 
        for(ECM_Role_Agreement__c newRA : newRoleAgreementList)
        {
            if(!isUpdateCall ||
               (isUpdateCall && mapOfOldRA.containsKey(newRA.Id) && 
               ( mapOfOldRA.get(newRA.Id).Business_Role__c != newRA.Business_Role__c || mapOfOldRA.get(newRA.Id).Agreement_Type__c != newRA.Agreement_Type__c)))
            {
                newRolesSet.add(newRA.Business_Role__c);
                newAgrmntSet.add(newRA.Agreement_Type__c);
                string new_Role_Agrmnt = String.valueOf(newRA.Business_Role__c)+'_'+String.Valueof(newRA.Agreement_Type__c);//Key to Identify New BR & AT Pair
                mapOfNewRA.put(new_Role_Agrmnt,newRA);
            }
        }
        
        if(!newRolesSet.isEmpty() && !newAgrmntSet.isEmpty())
        {
            //Fetch List of Existing Role Agreement with the same BR & AT that new records are having to compare 
            List<ECM_Role_Agreement__c> existingRAList = [SELECT Name,Business_Role__c,Business_Role__r.Name,Agreement_Type__c,Agreement_Type__r.Name 
                                                          FROM ECM_Role_Agreement__c
                                                          WHERE Business_Role__c IN : newRolesSet AND Agreement_Type__c IN : newAgrmntSet ];
            
            if(existingRAList!=null && !mapOfNewRA.keySet().isEmpty())
            {
                for(ECM_Role_Agreement__c exstRA : existingRAList)
                {
                    String exst_Role_Agrmnt = String.Valueof(exstRA.Business_Role__c)+'_'+String.Valueof(exstRA.Agreement_Type__c);//Key to Identify existing BR & AT Pair
                    if(mapOfNewRA.containsKey(exst_Role_Agrmnt))//if same key present in new version/record, duplicate exists
                    {
                            String ErrorMsg = Label.ECM_Duplicate_Role_Agreement_Error_Msg;
                        	ErrorMsg = ErrorMsg.replace('@RA@', exstRA.Name);
                        	ErrorMsg = ErrorMsg.replace('@BR@', exstRA.Business_Role__r.Name);
                        	ErrorMsg = ErrorMsg.replace('@AT@', exstRA.Agreement_Type__r.Name);
                            mapOfNewRA.get(exst_Role_Agrmnt).addError(ErrorMsg);
                    }
                    
                }
            }
           
        }
	}
}