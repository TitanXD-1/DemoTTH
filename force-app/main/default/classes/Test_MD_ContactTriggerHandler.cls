/**************************************************************************************
Apex Class Name  :  Test_MD_ContactTriggerHandler
Version          :  1.0
Created Date     :  30/04/2019
Release          :  R1
Function         :
Modification Log :
-----------------------------------------------------------------------------
* Developer                   Date                   Description
* ----------------------------------------------------------------------------
* Elena Schwarzbock         30/04/2019              Original Version
******************************************************************************/
@isTest
public class Test_MD_ContactTriggerHandler {
    
    /* 
    * @Author      :  Elena Schwarzbock     
    * @description :  Create an Account, Contact, AccountContactRelation and User used in the test method of the class               
    */
    @testSetup public static void createAccountContactAndRelation(){
        TestFactory_MD_Account.setupNoUser(true);
    }

    /* 
    * @Author      :  Elena Schwarzbock    
    * @description :  
    */  
    static testMethod void approveContact(){
        Contact con = [SELECT Id, MD_Approvalstatus__c FROM Contact LIMIT 1];
        con.MD_Approvalstatus__c = 'Approved';
        con.Contact_Type__c = 'Primary';
        update con;
    }

    /* 
    * @Author      :  Elena Schwarzbock    
    * @description :  
    */  
    static testMethod void changesOutlet(){
        RecordType rt = [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Outlet'];
        Map<String, Geography__c> geos = TestFactory_MD_Account.getGeographies();
        List<Account> ownerAccounts = TestFactory_MD_Account.createAccounts(rt, 'Test Aditional Account', 1, geos, true);
        Contact con = [SELECT Id, MD_CurrentOutlet__c FROM Contact LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name LIKE 'Test Aditional Account%'];
        con.MD_CurrentOutlet__c = acc.Id;
        update con;
    }    
    
}