/*
 * Class Name : ECM_AgreementApprovalTriggerHelper
 * @description: Helper Class for AgreementApprovalTrigger
 * @history
 * VERSION    AUTHOR                DATE              DETAIL
 * 1.1        Anuja && Saurav       13/08/2021		 Initial Developement 
*/

public class ECM_AgreementApprovalTriggerHelper {
    /*
	* @description : Throw error if creating duplicate 
	* @return : void
	* @param : trigger.new,trigger.OldMap
	*/
    public static void salesDriverItemExtraApprovalValidation(List<ECM_Agreement_Approval__c> newextrApprovalList,Map<Id,sObject> oldMap){
        //Variable
        Set<Id> extraApproverSet = new Set<Id>(); 
        Set<Id> agreementTypeSet = new Set<Id>(); 
        Map<Id,ECM_Agreement_Approval__c> newApprovalMap = new Map<Id,ECM_Agreement_Approval__c>();
        List<ECM_Extra_Approval__c> extraApprovalList = new List<ECM_Extra_Approval__c>();
        List<ECM_Extra_Approval__c> extraApprovalList1 = new List<ECM_Extra_Approval__c>();  
        Map<Id,ECM_Agreement_Approval__c> existingApprovalMap = new Map<Id,ECM_Agreement_Approval__c>();
        Map<Id,ECM_Agreement_Approval__c> oldApprovalMap;
        if(oldMap!= null){
             oldApprovalMap = (Map<Id,ECM_Agreement_Approval__c>)oldMap;//Need to check
        }
        for(ECM_Agreement_Approval__c aggAppobj : newextrApprovalList){
            if((oldMap == null && aggAppobj.ECM_Extra_Approval_Type__c =='Contract Sales Driver Item' )
               ||(oldApprovalMap!= null && oldApprovalMap.containsKey(aggAppobj.Id) && 
                  oldApprovalMap.get(aggAppobj.Id).ECM_Extra_Approval__c != aggAppobj.ECM_Extra_Approval__c
                  && aggAppobj.ECM_Extra_Approval_Type__c =='Contract Sales Driver Item')){
            	extraApproverSet.add(aggAppobj.ECM_Extra_Approval__c);
                agreementTypeSet.add(aggAppobj.ECM_Agreement_Type__c);
                newApprovalMap.put(aggAppobj.ECM_Agreement_Type__c,aggAppobj);
            }
        }
        if(!newApprovalMap.isEmpty()){
            for(ECM_Agreement_Approval__c agreementApprovalObj:[SELECT Id,Name,ECM_Extra_Approval__r.ECM_Type__c,ECM_Agreement_Type__c 
                                                                FROM ECM_Agreement_Approval__c 
                                                                WHERE ECM_Agreement_Type__c IN :agreementTypeSet 
                                                                AND ECM_Extra_Approval__c IN :extraApproverSet
                                                                AND ECM_Extra_Approval__r.ECM_Active__c = true
                                                                AND ECM_Extra_Approval__r.ECM_Type__c = 'Contract Sales Driver Item']){
                existingApprovalMap.put(agreementApprovalObj.ECM_Agreement_Type__c,agreementApprovalObj);
            }
            extraApproverSet.clear();
            agreementTypeSet.clear();
        }
        for(ECM_Agreement_Approval__c agreementApprovalObj : newApprovalMap.values()){
            if(existingApprovalMap!=null && existingApprovalMap.containsKey(agreementApprovalObj.ECM_Agreement_Type__c)){
                String errorMsg = Label.ECM_Duplicate_Extra_Approval_Error_Msg;
                errorMsg = errorMsg.replace('&&&&', existingApprovalMap.get(agreementApprovalObj.ECM_Agreement_Type__c).Name);
                agreementApprovalObj.addError(errorMsg);
            }
        }
    }
}