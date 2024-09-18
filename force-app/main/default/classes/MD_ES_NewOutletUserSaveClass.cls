/******************************************************************************
Apex Class Name     :   MD_ES_NewOutletUserSaveClass.cls 
Version             :   1.0
Created Date        :   09/05/2018
Release             :   R1
Function            :   
Modification Log    :
-----------------------------------------------------------------------------
* Developer                   Date                   Description
* ----------------------------------------------------------------------------
* Hernan Arakaki              28/06/2019              Original Version
* Hernan Arakaki              30/08/2019              ECOM 3669 - EDGE - Registration Source and Suscription Source fields are not being filled for Sec. Users
* Hernan Arakaki              25/09/2019              ECOM-3737 - EDGE - MD Registration - Adjustment to populate "Products Enabled" field
******************************************************************************/
global class MD_ES_NewOutletUserSaveClass {
	
    global class SecondaryUser implements DiageoCMS.FormSaveInterface{
        
        global DiageoCMS.FormResponseWrapper execute(Map<String,SObject> formData){
            System.debug('CG - in MD_ES_NewOutletUserSaveClass.SecondaryUser execute() method.');

            if(formData.get('sObjectToRevert_0') == null){
                System.debug('CG - in MD_ES_NewOutletUserSaveClass.SecondaryUser execute() method. sObjectToRevert_0 is null');

                List<AccountContactRelation> listOfAccountUsers = new List<AccountContactRelation>();
                for(String key : formData.keySet()){
                    if(key.startsWith('AccountContactRelation')){
                        listOfAccountUsers.add((AccountContactRelation)formData.get(key));
                    }
                }
                Contact newContact = (Contact) formData.get('Contact');
                
                newContact.Mobile__c = newContact.Mobile__c.replace(newContact.MobilePrefix__c, '');
                
                List<AccountContactRelation> listSelectedAccContacts = new List<AccountContactRelation>();
                newContact.OwnerId = UserInfo.getUserId();
                newContact.MD_MyDiageoInitialInviteDate__c = Datetime.now();
                newContact.MD_Approvalstatus__c = 'Approved';
                newContact.Contact_Type__c = 'Secondary';

                /* ECOM 3669 - BEGIN */
                newContact.MD_SubscriptionSource__c = 'Frontend';
                newContact.Registration_Source__c = 'MyDiageo';
                /* ECOM 3669 - END   */

                for(AccountContactRelation accContact : listOfAccountUsers){
                    if(accContact.MD_Status__c == 'Active'){
                        if(listSelectedAccContacts.isEmpty()) {
                            newContact.AccountId = accContact.AccountId;
                            newContact.MD_CurrentOutlet__c = accContact.AccountId;
                        }
                        accContact.Contact_Type__c = 'Secondary';
                        accContact.MD_UserProfile__c = 'Secondary User';
                        listSelectedAccContacts.add(accContact);
                    }
                }

                Account acc = [SELECT Id, OwnerId, Products_Enabled__c FROM Account WHERE Id =: newContact.AccountId];
                
                System.debug('CG - MD_ES_NewOutletUserSaveClass.execute() method. newContact: ' + newContact);
                System.debug('CG - MD_ES_NewOutletUserSaveClass.execute() method. listOfAccountUsers: ' + listOfAccountUsers);

                MD_RegistrationUtil.ContactCreationResponse insertContactAndAccContactsResponse = (MD_RegistrationUtil.ContactCreationResponse)JSON.deserialize(MD_RegistrationUtil.insertContactAndAccContacts(newContact, listSelectedAccContacts, acc.OwnerId), MD_RegistrationUtil.ContactCreationResponse.class);

                System.debug('CG - in MD_ES_NewOutletUserSaveClass.SecondaryUser.execute() method. insertContactAndAccContactsResponse: ' + insertContactAndAccContactsResponse);
                
                if(insertContactAndAccContactsResponse.type == MD_JSONResponse.MD_JSONResponseType.ERROR) {
                    return new DiageoCMS.FormResponseWrapper('Error', insertContactAndAccContactsResponse.message);
                }else {
                    /* ECOM-3737 - BEGIN */
                    if(acc.Products_Enabled__c == null) {
                        acc.Products_Enabled__c = 'MyDiageo';
                    }else if(!acc.Products_Enabled__c.contains('MyDiageo')) {
                        acc.Products_Enabled__c = acc.Products_Enabled__c + ';MyDiageo';
                    }
                    /* ECOM-3737 -   END */

                    List<sObject> recordsToRevert = new List<sObject>();
                    recordsToRevert.addAll(listSelectedAccContacts);
                    recordsToRevert.add(newContact);
                    return new DiageoCMS.FormResponseWrapper('Success', JSON.serialize(new insertedRecordsWrapper(newContact, recordsToRevert)));
                }
                    
            }else {
                System.debug('CG - in MD_ES_NewOutletUserSaveClass.SecondaryUser execute() method. sObjectToRevert_0 is not null');

                Contact contact = (Contact) formData.get('Contact');
                contact.MD_Approvalstatus__c = 'Approved';

                List<SObject> listToRevert = new List<SObject>();
                for(String key : formData.keySet()){
                    if(key.startsWith('sObjectToRevert_')){
                        listToRevert.add(formData.get(key));
                    }
                }

                System.debug(contact);      
                String countryCode = MD_UserSessionUtil.getclusterLocationCode(contact.MailingCountry);
                
                /*
                if(!Test.isRunningTest()) {
                	MD_RegistrationUtil.createUser(contact.Id);
                }
                */

                return new DiageoCMS.FormResponseWrapper('Success', '');
            }   
        }
    }
    
    global class insertedRecordsWrapper{
        
        global Contact con;
        global List<sObject> recordsToRevert;
        
        global insertedRecordsWrapper(Contact con, List<sObject> recordsToRevert){
            this.con = con;
            this.recordsToRevert = recordsToRevert;
        }
    }
}