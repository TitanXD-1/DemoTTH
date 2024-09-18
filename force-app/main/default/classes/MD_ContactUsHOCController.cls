public without sharing class MD_ContactUsHOCController  {

    @AuraEnabled
    public static String initialize() {
        System.debug('CG - in MD_ContactUsHOCController.init() method. ');
        List<RecordType> myDiageoCaseRecordTypes = [SELECT Id 
                                                        FROM RecordType 
                                                        WHERE SObjectType = 'Case' 
                                                            AND DeveloperName = 'MD_MyDiageoCases'
                                                        LIMIT 1];

        Case newCase = new Case();   
        newCase.RecordTypeId = myDiageoCaseRecordTypes.get(0).Id;
        
        MD_ContactUsHOCController.ContactUsWrapper response = new MD_ContactUsHOCController.ContactUsWrapper();
        response.newCase = newCase;
        response.hasSalesRep = hasSalesRep();

        return JSON.serialize(response);
    }

    /**
    * Validates if the Contact has an Sales Representative associated
    */
    private static Boolean hasSalesRep() {

        Id currentOutlet = MD_UserSessionUtil.getUser().Contact.MD_CurrentOutlet__c;
        Set<Id> primaryTerritories = new Set<Id>();
        for(Outlet_Territory__c outletTeritory: [SELECT Id, Territory__c FROM Outlet_Territory__c WHERE Outlet__c =: currentOutlet AND Territory__r.Territory_Type__c = 'Primary']){
            primaryTerritories.add(outletTeritory.Territory__c);
        }

        if(!primaryTerritories.isEmpty()){
            List<Territory_Member__c> terrMembers = [SELECT User__c FROM Territory_Member__c WHERE Type__c = 'Primary' AND User__r.IsActive = true LIMIT 1];
            if(!terrMembers.isEmpty()){
                return true;
            }
        }

        return false;
    }

    @AuraEnabled
    public static String doSave(String newCase) {
        MD_JSONResponse response = new MD_JSONResponse();

        System.debug('doSave: ' + newCase);

        try {
            Case caseRecord = (Case)JSON.deserialize(newCase, Case.class);
            caseRecord.RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'MD_MyDiageoCases'].get(0).Id;
            System.debug('doSaveObject: ' + caseRecord);
            System.debug('CG - in MD_ContactUsHOCController.doSave() method. currentOutletId: ' + MD_UserSessionUtil.getUser().Contact.MD_CurrentOutlet__c);
            caseRecord.AccountId = MD_UserSessionUtil.getUser().Contact.MD_CurrentOutlet__c;

            //Fetching the assignment rules on case
            AssignmentRule AR = new AssignmentRule();
            AR = [SELECT Id FROM AssignmentRule WHERE SobjectType = 'Case' AND Active = true LIMIT 1];

            //Creating the DMLOptions for "Assign using active assignment rules" checkbox
            Database.DMLOptions dmlOpts = new Database.DMLOptions();
            dmlOpts.assignmentRuleHeader.assignmentRuleId= AR.id;
            dmlOpts.EmailHeader.TriggerUserEmail = true;

            //Setting the DMLOption on Case instance
            caseRecord.setOptions(dmlOpts);

            insert caseRecord;

            response.status = true;
            response.message = 'Case created|' + caseRecord.Type + '|' + caseRecord.MD_Subject__c;
            response.type = MD_JSONResponse.MD_JSONResponseType.SUCCESS;
        }catch(Exception e) {
            response.status = true;
            response.message = 'Case creation failed';
            response.type = MD_JSONResponse.MD_JSONResponseType.ERROR;
        }

        return JSON.serialize(response);
    }

    public class ContactUsWrapper {
        public Case newCase {get;set;}
        public Boolean hasSalesRep {get;set;}
        public Map<String, String> typeOptions {get;set;}
    }
}