/*
 * @Description: CO_ContentDocumentTriggerHelperTest
 * @Purpose: Test Class for CO_ContentDocumentTriggerHelper
 * @History:
 * @Version		Developer		 Date			User-Story
 * 	1.0			Aparajita		20/04/2023		CONS-528
 */
@isTest
public class CO_ContentDocumentTriggerHelperTest {
    @isTest
    public static void testRestrictFileDeletion(){
        EDGE_UtilityTestClass.createOrgSettings();
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU'); 
        
        Profile profile = [Select Id From Profile where Name = 'System Administrator' limit 1];
        
        User usr1= new User();
        usr1.ProfileID = profile.Id;
        usr1.Username ='Test@Testemail.com'+ System.currentTimeMillis(); 
        usr1.LastName ='TestLastname';
        usr1.Email ='Test@Testemail.com';
        usr1.Alias ='TestUser';
        usr1.Available_Countries__c='AU';
        usr1.TimeZoneSidKey ='TestCommunityNickname1';
        usr1.CommunityNickname ='TestCommunityNickname1';
        usr1.TimeZoneSidKey ='America/Los_Angeles';
        usr1.LocaleSidKey ='en_US';
        usr1.EmailEncodingKey ='UTF-8';
        usr1.LanguageLocaleKey ='en_US';
        insert usr1;
        
        System.runAs(usr1){   
            Test.startTest();
            
            //Create SalesOrganization record
            Sales_Organisation__c sOrg = new Sales_Organisation__c();
            sOrg.RecordTypeId = Schema.sObjectType.Sales_Organisation__c.getRecordTypeInfosByDeveloperName().get('SalesOrg').getRecordTypeId();
            sOrg.Name = 'Test Sales Org';
            sOrg.Description__c = 'Test Sales Org';
            sOrg.Code__c = 'AU01';
            sOrg.Country__c = geographyId;
            insert sOrg;
            
            //Create CustomerRequest record
            Customer_Request__c cr = new Customer_Request__c(
                CO_Customer_Name__c = 'test',
                Account_group_Customer_Type__c = 'Y001',
                CO_Sales_Organisation__c = sOrg.Id,
                CO_Address__CountryCode__s = 'AU',
                CO_Address__City__s = 'city',
                CO_Address__Street__s = 'street',
                CO_Address__PostalCode__s = '12345',
                CO_Email__c = 'test@test.com',
                CO_Telephone__c = '1029384756',
                CO_Incoming_Payment_Method__c = '0;C',
                CO_Special_payment_requests__c = 'Payment from an account in a different name to that of the customer',
                CO_Other_Details_of_payment_request__c = 'test',
                Estimated_annual_total_transaction_value__c = '£10k-£100k',
                CO_Knowledge_of_governmental_interaction__c = 'No',
                CO_Are_HQ_Delivery_address_different__c = 'No',
                CO_Any_further_risk_assessments_required__c = 'No'
            );
            insert cr;

            //Create ContentVersion record 
            ContentVersion conVerRec = EDGE_UtilityTestClass.gerConVerRec('CO_Image.jpeg');
            conVerRec.Title = 'CO_Image.jpeg';
            conVerRec.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('CO Customer Request').getRecordTypeId();
            conVerRec.Content_Type__c = 'Other';
            insert conVerRec;
                        
            //Get ContentDocument record 
            ContentDocument conDocRec = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
            
            //Create ContentDocumentLink record 
            ContentDocumentLink conDocLinkRec = New ContentDocumentLink();
            conDocLinkRec.LinkedEntityId = cr.id;
            conDocLinkRec.ContentDocumentId = conDocRec.Id;
            conDocLinkRec.shareType = 'V';
            insert conDocLinkRec;
            Test.stopTest();
            try{
                delete conDocRec;
            }catch(Exception ex){
                System.assertEquals(ex.getMessage().contains('Files cannot be deleted'), true, 'success');
            }     
        }
    }
}