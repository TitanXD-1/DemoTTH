/**************************************************************************************
Apex Class Name  :  Test_MD_ChangeOutletMenuController
Version          :  1.0
Created Date     :  17/12/2018
Release          :  R1
Function         :  Test class for MD_ChangeOutletMenuController
Modification Log :
-----------------------------------------------------------------------------
* Developer                   Date                   Description
* ----------------------------------------------------------------------------
* Elena Shwarzböck           17/12/2018              Original Version
******************************************************************************/
@isTest
public class Test_MD_ChangeOutletMenuController{
    
    @testSetup 
    public static void createAccountContactAccountcontact(){
        TestFactory_MD_Account.setup(true);  
    }
    
    static testMethod void testNavigateAsOutlet() {
        User user = [SELECT Id, Username, ContactId, ProfileId, Alias, Email, CommunityNickname,
                    LanguageLocaleKey, EmailEncodingKey, LastName, LocaleSidKey, TimeZoneSidKey,
                    Country/*, CountryCode__c*/ FROM User WHERE Alias = 'hola' LIMIT 1];

        AccountContactRelation accountContact = [SELECT Id, AccountId, ContactId FROM AccountContactRelation WHERE ContactId =:user.ContactId LIMIT 1];                                
        MD_SessionSettings__c settings = TestFactory_MD_Account.createSettingsForUser(user.Id, accountContact.Id);
        
        System.runAs(user) {
            MD_ChangeOutletMenuController.initChangeOutletMenu();
        }
    }
}