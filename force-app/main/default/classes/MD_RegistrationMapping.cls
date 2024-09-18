public class MD_RegistrationMapping {
    
    static Account accountData;
    static Contact contactData;
    static Geography__c countryData;
    
    public static MD_JSONResponse submitRequestForApproval(Map<String, SObject> formData) {
        accountData = (Account) formData.get('Account');
        contactData = (Contact) formData.get('Contact');
        countryData = (Geography__c) formData.get('Geography__c');
        Contact contact = generateContactForApproval();        
        String currentUserId = UserInfo.getUserId();        
        Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
        request.setComments(Label.MD_SubmittingForApproval);
        request.setObjectId(contact.id);
        request.setSubmitterId(currentUserId);
        request.setProcessDefinitionNameOrId('MD_ContactApproval');
        request.setSkipEntryCriteria(true);
        Approval.ProcessResult result = Approval.process(request);        
        if(result.isSuccess()){
            return new MD_JSONResponse(true, Label.MD_SuccessfullySubmitted, MD_JSONResponse.MD_JSONResponseType.SUCCESS);            
        } else {
            return new MD_JSONResponse(false, Label.MD_FailedSubmitting, MD_JSONResponse.MD_JSONResponseType.ERROR);
        }
    }
    
    private static Contact generateContactForApproval(){ 
        Geography__c geography = [SELECT Id, Name, Code__c, 
                                  Parent_Geography__c, 
                                  Parent_Geography__r.Parent_Geography__c, 
                                  Parent_Geography__r.Parent_Geography__r.Parent_Geography__c,
                                  Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Parent_Geography__c,
                                  Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Parent_Geography__c 
                                  FROM Geography__c 
                                  WHERE Parent_Geography__r.Parent_Geography__r.Code__c =: countryData.Code__c LIMIT 1];
        
        Map<String, Id> accountRecordTypes = new Map<String, Id>();
        for(RecordType accountRecordType : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Account']) {
            accountRecordTypes.put(accountRecordType.DeveloperName, accountRecordType.Id);
        }
        
        String ownerRecordTypeId = accountRecordTypes.get('Owner');
        String prospectRecordTypeId = accountRecordTypes.get('Prospect');
        
        Account owner = createOwner(ownerRecordTypeId, geography); 
        insert owner;
        Account prospect = createProspect(prospectRecordTypeId, geography, owner.Id);
        insert prospect;
        Contact contact = createContact(prospect.Id);
        insert contact;
        
        return contact;
    }
    
    private static Account createOwner(String recordTypeId, Geography__c geography){
        return new Account(Name = accountData.Name
                            , VAT_Number__c = accountData.VAT_Number__c
                            , BillingStreet = accountData.BillingStreet
                            , Phone = contactData.mobilePhone
                            , Global_Channel__c = 'On Trade'
                            , Global_Sub_Channel__c = 'On trade'
                            , Global_Segment__c = 'Bars'
                            , Global_Sub_Segment__c = 'Modern Bars'
                            , Region__c = geography.Id
                            , Area__c = geography.Parent_Geography__c
                            , Country__c = geography.Parent_Geography__r.Parent_Geography__c
                            , Cluster__c = geography.Parent_Geography__r.Parent_Geography__r.Parent_Geography__c
                            , Hub__c = geography.Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Parent_Geography__c
                            , Market__c = geography.Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Parent_Geography__c
                            , RecordTypeId = recordTypeId
                          );
    }
    
    private static Account createProspect(String recordTypeId, Geography__c geography, String ownerId){
        Pick_Up_Options__c option = [SELECT Id FROM Pick_Up_Options__c 
                                     WHERE Name = 'N0[ES]' 
                                     AND Geography__r.Code__c =: countryData.Code__c 
                                     AND Type__c = 'Outlet Visit Prioritization' LIMIT 1];
        return new Account(Name = accountData.Name
                            , Operator__c = accountData.OwnerId
                            , BillingStreet = accountData.BillingStreet
                            , Phone = contactData.mobilePhone
                            , Outlet_Visit_Prioritisation_Grade__c = option.Id
                            , BillingState = 'España'
                            , Region__c = geography.Id
                            , Area__c = geography.Parent_Geography__c
                            , Country__c = geography.Parent_Geography__r.Parent_Geography__c
                            , Cluster__c = geography.Parent_Geography__r.Parent_Geography__r.Parent_Geography__c
                            , Hub__c = geography.Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Parent_Geography__c
                            , Market__c = geography.Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Parent_Geography__c
                            , Global_Channel__c = 'On Trade'
                            , Global_Sub_Channel__c = 'On trade'
                            , Global_Segment__c = 'Bars'
                            , Global_Sub_Segment__c = 'Modern Bars'

                            , BillingPostalCode = accountData.BillingPostalCode
                            , RecordTypeId = recordTypeId
                          );
    }
    
    private static Contact createContact(String prospectId){
        return new Contact(FirstName = contactData.FirstName,
                           LastName = contactData.LastName,
                           mobilePhone = contactData.mobilePhone,
                           Email = contactData.Email,
                           Contact_Type__c = 'Primary',
                           Registration_Source__c = 'MyDiageo',
                           AccountId = prospectId
                          );
    }
    
}