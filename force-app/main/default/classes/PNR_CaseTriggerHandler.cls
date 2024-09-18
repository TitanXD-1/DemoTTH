/****
Name: PNR_CaseTriggerHandler
----
Purpose: Trigger Handler Class for Case for Pioneer
-------
History                                                            
-------                                                            
VERSION     AUTHOR             DATE              DETAIL
1.0      Saurav Prasad       12/06/2020       Initial Development for PION-1554
2.0      Pratik Kumar        21/12/2021       added method validateOwnerChange() for PION-1586
****/
public class PNR_CaseTriggerHandler {
    
    
/****
Method  : updateEntitlementName
Purpose : This methods used to update Entitlement for Pioneer Cases Only
****/
    public static void updateEntitlementName(List<SObject> newItems){
        try{
            //adding all Pioneer related Recordtype IDs
            set<id> pioneerRecordTypeIds= new set<id>();
            pioneerRecordTypeIds.add(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('AR_Disputes').getRecordTypeId());
            pioneerRecordTypeIds.add(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Customer_Enquiry_Complaint').getRecordTypeId());
            pioneerRecordTypeIds.add(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Direct_Disputes').getRecordTypeId());
            pioneerRecordTypeIds.add(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Order_Management_Case').getRecordTypeId());
            pioneerRecordTypeIds.add(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Other').getRecordTypeId());
            
            //Get Entitlement process SLA Process 
            List<SlaProcess> Pioneer_Sla=new List<SlaProcess>([SELECT Id From SlaProcess where Name ='Pioneer Entitlement Process' AND IsActive = True Limit 1]);
            
            //Get Entitlement Record
            List<Entitlement> Pioneer_Entitlement=new List<Entitlement>();
            if(Pioneer_Sla.size()>0){
                Pioneer_Entitlement=[SELECT id from Entitlement where SlaProcessId IN:Pioneer_Sla Limit 1];
            }
            
            for(SObject obj :newItems){ 
                Case caseObj = (Case)obj;
                if(pioneerRecordTypeIds.contains(caseObj.RecordTypeId) && Pioneer_Entitlement.size()>0){
                    caseObj.EntitlementId=Pioneer_Entitlement[0].Id;
                }
            }
        }catch(Exception e){
            System.debug('Exception Caught in Before Update of PNR_CaseTriggerHandler in method:updateEntitlementName at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
        }
    }

    /****
    Method added to validate if the new owner of Case is Active and current owner is inactive
    ****/
    public static void validateOwnerChange(Map<Id,SObject> newItems,Map<Id,SObject> oldItems){
        try{
            User currUser = [SELECT Id, Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            if(currUser.Profile.Name == 'PNR_TeamLead')
            {
                Map<Id,Case> caseRecordMap = (Map<Id,Case>)newItems;
                Map<Id,Case> caseOldRecordMap = (Map<Id,Case>)oldItems;
                Set<Id> newOwnerIds = new Set<Id>();
                Set<Id> oldOwnerIds = new Set<Id>();

                for(Id caseId : caseRecordMap.keyset())
                {
                    newOwnerIds.add(caseRecordMap.get(caseId).OwnerId);
                    oldOwnerIds.add(caseOldRecordMap.get(caseId).OwnerId);
                }
                
                Map<Id, User> userRecMap = new Map<Id, User>([SELECT Id, IsActive, Profile.Name FROM User WHERE Id IN :newOwnerIds OR Id IN :oldOwnerIds]);
                
                Map<Id, RecordType> pnrCaseRecTypeMap = new Map<Id, RecordType>([SELECT Id, DeveloperName FROM RecordType WHERE DeveloperName IN :System.Label.PNR_Case_RecordTypes.split(';')]);
                for(Id caseId : caseRecordMap.keyset())
                {
                                        
                    if((caseRecordMap.get(caseId).OwnerId != caseOldRecordMap.get(caseId).OwnerId && pnrCaseRecTypeMap.keyset().contains(caseRecordMap.get(caseId).RecordTypeId)) 
                        && userRecMap.keyset().contains(caseOldRecordMap.get(caseId).OwnerId) && userRecMap.keyset().contains(caseRecordMap.get(caseId).OwnerId) 
                        &&
                        (
                            userRecMap.get(caseOldRecordMap.get(caseId).OwnerId).IsActive == TRUE 
                            ||
                            userRecMap.get(caseRecordMap.get(caseId).OwnerId).IsActive == FALSE 
                        ))
                        
                    {                        
                        caseRecordMap.get(caseId).addError(System.Label.PNR_Case_Owner_Validation_Error);
                    }
                    
                }
            }
        }catch(Exception e){
            System.debug('Exception Caught in Before Update of PNR_CaseTriggerHandler in method:validateOwnerChange at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
        }
    }

    public static void shareCasesWithoutAccount(Map<id, SObject> newObjectMap, Map<Id, SObject> oldObjectMap, String operation){
        try{
            if(operation == 'insert'){
                PNR_SharingUtil.generateSharingFromSalesOrg(newObjectMap.values(), 'Sales_Org__c', 'add');
            }
            if(operation == 'update'){
                List<SObject> listToRemove = new List<SObject>();
                List<SObject> listToAdd = new List<SObject>();
                for(Id recId: newObjectMap.keyset()){
                    if(newObjectMap.get(recId).get('Sales_Org__c') != oldObjectMap.get(recId).get('Sales_Org__c')){
                        if(oldObjectMap.get(recId).get('Sales_Org__c') != null)
                        {
                            listToRemove.add(oldObjectMap.get(recId));
                        }
                        if(newObjectMap.get(recId).get('Sales_Org__c') != null){
                            listToAdd.add(newObjectMap.get(recId));
                        }
                    }
                    //PION-2636: below if block added to handle the standard functionality wherein
                    //share records(RowCause: Manual) are deleted if the owner changes
                    if(newObjectMap.get(recId).get('OwnerId') != oldObjectMap.get(recId).get('OwnerId') && newObjectMap.get(recId).get('Sales_Org__c') != null){
                        listToAdd.add(newObjectMap.get(recId));
                    }
                }
                if(!listToRemove.isEmpty()){
                    PNR_SharingUtil.generateSharingFromSalesOrg(listToRemove, 'Sales_Org__c', 'remove');
                }
                if(!listToAdd.isEmpty()){
                    PNR_SharingUtil.generateSharingFromSalesOrg(listToAdd, 'Sales_Org__c', 'add');
                }

            }
        }catch(Exception e){
            System.debug('Exception Caught in Before Update of PNR_CaseTriggerHandler in method:shareCasesWithoutAccount at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
        }
    }

    public static void addSoToCase(List<SObject> newItems, Map<Id, SObject> oldItemsMap){
        /*List<Id> pnrCaseRecTypeId = new List<Id>();
        for(String recType: System.Label.PNR_Case_RecordTypes.split(';')){
            pnrCaseRecTypeId.add(Schema.SObjectType.Case.getRecordTypeInfosByDevelopername().get(recType).getRecordTypeId());
        }
        
        Map<Id, Id> caseIdAccIdMap = new Map<Id, Id>();
        for(SObject cs: newItems){
            if(cs.get('AccountId') != null && pnrCaseRecTypeId.contains((Id) cs.get('RecordTypeId'))){
                if((oldItemsMap != null && !oldItemsMap.keySet().isEmpty() && (Id)cs.get('AccountId') != oldItemsMap.get((Id)cs.get('Id')).get('AccountId')) || (oldItemsMap != null && (String)cs.get('Sales_Org__c') == null)){
                    caseIdAccIdMap.put((Id)cs.get('Id'), (Id) cs.get('AccountId'));
                }else{
                    caseIdAccIdMap.put((Id)cs.get('Id'), (Id) cs.get('AccountId'));
                }
            }
        }
        
        Map<Id, String> accIdSoMap = new Map<Id, String>();
        for(Account acc: [SELECT Id, Sales_Org__c FROM Account WHERE Id IN :caseIdAccIdMap.values()]){
            accIdSoMap.put(acc.Id, acc.Sales_Org__c);
        }
        
        for(SObject cs: newItems){
            if(caseIdAccIdMap.containsKey((Id)cs.get('Id'))){
                cs.put('Sales_Org__c', accIdSoMap.get((Id) cs.get('AccountId')));
            }
        }*/
    }
    
    /*
     * @description: This method will send email alert to CSE and CCC associated to a case. When a case is created from CC.
     * this is for PION-2494
     * PION-2492 change: Method added to send the email notification to CCC team
     * */
    public static void sendEmailToCCCTeam(map<id,Sobject> newItems, map<id,Sobject> oldItems, Boolean isUpdate){
        //Variable declaration start
        List<id> caseIds=new list<id>();
        list<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
        String templateName;
        string ccAddress= system.label.CC_Address_for_CCC_Team;
        string ccAddressForCCTeam = system.label.PNR_CC_Address;
		//Variable declaration end
		//for loop start
        for(Sobject obj: newItems.values()){
            case caseobj	= (case)Obj;
            if(isUpdate){//PION-2492 - this will called when update is happening on case
                case oldCaseobj	= (case)oldItems.get(caseobj.Id);
                if(!String.isBlank(caseobj.CC_Market__c) && caseobj.CC_Share_with_Customer_Concerns__c ==true && caseobj.CC_Share_with_Customer_Concerns__c != oldCaseobj.CC_Share_with_Customer_Concerns__c){
                    caseIds.add(caseobj.id);
                } 
                
                templateName = 'Email_Notification_to_CCC_team';
            }
            else{//PION-2494 - this will be called when insert is happening on the case
                if(caseobj.CC_Is_Customer_Concern_Created__c ==true && (caseobj.Type =='Dispute – Delivery' || caseobj.Type =='Dispute – Pricing' || caseobj.Type =='Dispute – Unknown')){
                    caseIds.add(caseobj.id);
                } 
                //templateName = 'PNR_VFTemplate_DDCase';
                templateName = 'PNR_DDCaseToCSETemplate';
            }
        }//for loop ends
        
        List<Case> caseList=[Select id,casenumber, type, CC_Market__r.CC_CSE__r.Email,CC_Market__r.CC_CCC__r.Email  from case where id IN: caseIds];
        //Get Emailtemplate Record
        EmailTemplate emailTemplate =[Select Id,Subject,Description,HtmlValue,DeveloperName,Body from EmailTemplate 
                                      where DeveloperName =: templateName];
        
        
        for(Case c: caseList){
            List<String> sendTo = new List<String>();
            List<String> ccTo = new List<String>();
            String templateId = emailTemplate.Id;
            String userId = userinfo.getUserId();
            String whatId = c.Id;
            // To create the emailmessage for emailnotification
            Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(templateId, userId, whatId);
            mail.setTemplateID(templateId); 
            mail.setWhatId(whatId);
            mail.setTargetObjectId(userId); 
            if(isUpdate){
            sendTo.add(c.CC_Market__r.CC_CCC__r.Email);
            ccTo.add(ccAddress);
            }
            else{
                if(c.Type == 'Dispute – Delivery' || c.Type == 'Dispute – Pricing'){
                     sendTo.add(c.CC_Market__r.CC_CSE__r.Email);   
                     ccTo.add(ccAddressForCCTeam);
                }else if(c.Type == 'Dispute – Unknown'){
                    sendTo.add(c.CC_Market__r.CC_CCC__r.Email);
                    ccTo.add(ccAddressForCCTeam);
                }
            }
            mail.setToAddresses(sendTo);
            mail.setCcAddresses(ccTo);
            mail.setSaveAsActivity(false);
            mail.setTreatTargetObjectAsRecipient(false);
            mailList.add(mail);
        }
        if(mailList.size() !=null){
            Messaging.sendEmail(mailList);
        }
    }
    

}