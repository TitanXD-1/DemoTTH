/*
 * @Name: D1_CollectKegsController
 * @discription: Collect Keg Management
 * @History
 * VERSION     AUTHOR           DATE       DETAIL
 * 1.0         Ajay            12/01/20    Initial Development(NCP-1351)
 **/
public without sharing class D1_CollectKegsController {
    /**
     * @description Raise Keg Collect Request
     * @userStory NCP-4261
     * @param {Number} qunatity
     * @return {Exception} if failed to raise Collect keg Case. 
     **/
    @AuraEnabled
    public static void raiseKegCollectionRequest(Integer quantity, String sapShipToNumber) {
        final String recordTypeKeg = 'Diageo One Keg Return';
        final String recordTypeIdKeg = Schema.SObjectType.Case.getRecordTypeInfosByName().get(recordTypeKeg).getRecordTypeId();
        final String statusOpen= 'Open';
        final String type = 'Kegs Return';
        final String subject = 'Keg Collection Request';
        final String origin = 'Diageo One';

        List < AssignmentRule > assignmentRules = [SELECT id FROM AssignmentRule WHERE SobjectType = 'Case' AND Active = true LIMIT 1];
        if (assignmentRules.isEmpty()) {
            throw new AuraHandledException('Access Denied (AssignmentRule)');
        }
        List<User> loggedInUser = [SELECT Id, Effective_Account_Id__c, ContactId
                                        FROM User 
                                        WHERE Id =:userInfo.getUserId() LIMIT 1];
        try {
            Database.DMLOptions dmlOpts = new Database.DMLOptions();
            dmlOpts.assignmentRuleHeader.assignmentRuleId = assignmentRules[0].id;
			dmlOpts.EmailHeader.TriggerUserEmail = true;

            Case newCase = new Case();
            newCase.setOptions(dmlOpts);
            newCase.recordTypeId = recordTypeIdKeg;
            newCase.Status = statusOpen;
            newCase.Type = type;
            newCase.D1_Subject__c = subject;
            newCase.Origin = origin;
            newCase.AccountId = loggedInUser[0].Effective_Account_Id__c;
            newCase.ContactId = loggedInUser[0].ContactId;

            newCase.Number_of_Kegs_Requested__c = quantity;
            newCase.SAP_Ship_To_Customer_No__c = sapShipToNumber;
            insert newCase;

        } catch (Exception ex) {
            throw ex;
        }
    }

   
}