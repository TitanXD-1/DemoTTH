/**************************************************************************************
Apex Class Name  :  Test_MD_AccountContactUtil
Version      :  1.0  
Created Date     :  13/05/2018
Release        :  R1
Function     :  It test the functionality of the MD_AccountContactUtil class
Modification Log :
-----------------------------------------------------------------------------
* Developer                   Date                   Description
* ----------------------------------------------------------------------------                 
* Matias Novello          13/05/2018              Original Version
******************************************************************************/
@isTest
public class Test_MD_AccountContactUtil { 
    
    /* 
    * @Author      :  Matias Novello     
    * @description :  Create an Account, Contact, Account_Contact__c and User used in the test method of the class
    *                 
    *                 
    * @returns     :  void
    */
    @testSetup public static void createAccountContactAccountcontact(){
        System.debug('CG - a) UserRole size: ' + [SELECT Id FROM UserRole LIMIT 1].size());

        TestFactory_MD_Account.setup(true);

    }

    /* 
    * @Author      :  Matias Novello    
    * @description :  used for test the getExistingAccContactsDisplayed method in the 
    *                 CP_AccountContactUtil.
    * @returns     :  void
    */  
    static testMethod void testGetExistingAccContactsDisplayed(){
        
        List<AccountContactRelation> result = [select id, MD_Status__c from AccountContactRelation];
        result = MD_AccountContactUtil.getExistingAccContactsDisplayed(result);
    }

    /* 
    * @Author      :  Matias Novello    
    * @description :  used for test the getMemoryCreatedAccContacts method in the 
    *                 CP_AccountContactUtil.
    * @returns     :  void
    */
        
    static testMethod void testGetMemoryCreatedAccContacts(){
        
        MD_AccountContactUtil.getMemoryCreatedAccContacts([SELECT Id,ContactId,AccountId, MD_Status__c, MD_Role__c FROM AccountContactRelation ]);
    }

    /* 
    * @Author      :  Matias Novello    
    * @description :  used for test the addIdsOfExistingRecToNewAccContacts method in the 
    *                 CP_AccountContactUtil.
    * @returns     :  void
    */  
    static testMethod void testAddIdsOfExistingRecToNewAccContacts(){
        
        List<AccountContactRelation> listAccountContact = [SELECT Id,MD_Status__c,MD_ContactAccountIds__c from AccountContactRelation ];
        map<String, AccountContactRelation> mapStringAccCont = new map<String, AccountContactRelation>();
        mapStringAccCont.put(listAccountContact.get(0).MD_ContactAccountIds__c,listAccountContact.get(0));
        List<AccountContactRelation> result = new List<AccountContactRelation>();
        

        result = MD_AccountContactUtil.addIdsOfExistingRecToNewAccContacts(mapStringAccCont,listAccountContact);
    }

    /* 
    * @Author      :  Matias Novello    
    * @description :  used for test the getActiveAccountContactsFrom method in the 
    *                 CP_AccountContactUtil.
    * @returns     :  void
    */  
    static testMethod void testGetActiveAccountContactsFrom(){
        
        MD_AccountContactUtil.getActiveAccountContactsFrom([select ContactId, AccountId, MD_Status__c, MD_Role__c FROM AccountContactRelation]);

    }

    /* 
    * @Author      :  Matias Novello    
    * @description :  used for test the createNewAccountContactFrom method in the 
    *                 CP_AccountContactUtil.
    * @returns     :  void
    */  
 
    static testMethod void testCreateNewAccountContactFrom(){

        MD_AccountContactUtil.createNewAccountContactFrom([select id, AccountId from AccountContactRelation limit 1][0],[select id from contact limit 1][0].Id);
    }

    /* 
    * @Author      :  Matias Novello    
    * @description :  used for test the putAccContactForLoggedUserFirst method in the 
    *                 CP_AccountContactUtil.
    * @returns     :  void
    */  
    static testMethod void testPutAccContactForLoggedUserFirst(){
        
        MD_AccountContactUtil.putAccContactForLoggedUserFirst([select id,ContactId from AccountContactRelation]); 
    }
}