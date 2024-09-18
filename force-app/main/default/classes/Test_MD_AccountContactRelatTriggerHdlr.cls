/**************************************************************************************
Apex Class Name  :  Test_MD_AccountContactRelatTriggerHdlr
Version          :  1.0
Created Date     :  14/05/2019
Release          :  R1
Function         :
Modification Log :
-----------------------------------------------------------------------------
* Developer                       Date                   Description
* ----------------------------------------------------------------------------
* Elena Schwarzbock              14/05/2019              Original Version
******************************************************************************/
@isTest
public class Test_MD_AccountContactRelatTriggerHdlr {

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
        Account acc = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Outlet'];
        AccountContactRelation accContactRel = [SELECT Id, MD_Role__c FROM AccountContactRelation WHERE AccountId =: acc.Id AND ContactId =: con.Id];
        con.MD_CurrentOutlet__c = acc.id;
        update con;
        accContactRel.MD_Role__c = 'Owner';
        update accContactRel;
    }
    

    static testMethod void approveContact2(){
        Contact con = [SELECT Id, MD_Approvalstatus__c FROM Contact LIMIT 1];
        Account acc = [SELECT Id, Cluster__c, Country__c, Area__c, Hub__c, Market__c, Region__c FROM Account WHERE RecordType.DeveloperName = 'Outlet'];
        AccountContactRelation accContactRel = [SELECT Id, MD_Role__c FROM AccountContactRelation WHERE AccountId =: acc.Id AND ContactId =: con.Id];
        con.MD_CurrentOutlet__c = acc.id;
        update con;
        
        acc.id = null;
        acc.name= 'NewAccount';
        Account acc2 = acc;
        insert acc2;
        AccountContactRelation accConRel2 = new ACcountContactRelation(accountid = acc2.id, contactid = con.id, MD_AssignedPermissions__c='Access');
        insert accConRel2;
        
        
        accContactRel.MD_Role__c = 'Owner';
        update accContactRel;
    }
    

    static testMethod void approveContact3(){
        Contact con = [SELECT Id, MD_Approvalstatus__c FROM Contact LIMIT 1];
        Account acc = [SELECT Id, Cluster__c, Country__c, Area__c, Hub__c, Market__c, Region__c FROM Account WHERE RecordType.DeveloperName = 'Outlet'];
        AccountContactRelation accContactRel = [SELECT Id, MD_Role__c, MD_AssignedPermissions__c FROM AccountContactRelation WHERE AccountId =: acc.Id AND ContactId =: con.Id];
        accContactRel.MD_AssignedPermissions__c = 'Access';
        update accContactRel;
        accContactRel.MD_AssignedPermissions__c = '';
        update accContactRel;

    }
    
}