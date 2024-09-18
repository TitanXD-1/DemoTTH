/*
* @name: D1_FooterCtrlTest
* @discription: Test class for D1_FooterCtrl 
* @history
* --
* VERSION     AUTHOR           DATE       DETAIL
* 1.0         Sai Kumar       31/08/2020   NCP-
* 2.0         Narayana        12/07/2021    NCP-3785(Refactor)
* */
@istest
public with sharing class D1_FooterCtrlTest 
{
    @testsetup
    public static void setup()
    {
        Account account = D1_TestDataUtility.getDirectCustomer();
        account.D1_Registration_Status__c = '';
        account.Current_Approval_Step__c ='';
        account.Status__c='';
        System.assert(account != null,'account not method'); 
        insert account;

        D1_TestDataUtility.setUpExternalUser(account,'Direct Buyer');     
        
    }
    @istest
    public static void getD1SettingDetailTest() 
	{ 
        User portalUser = [select id from user where usertype='Guest'  and IsActive = true limit 1];
        System.assert(portalUser != null, 'portal user not found');
        system.runAs(portalUser)
        {
            D1_FooterCtrl.D1SettingWithUserTypeWrapper d1Foovar = D1_FooterCtrl.getD1SettingDetail('GB','en_GB');
          	System.assert(d1Foovar != null,'d1 setting details not found');
            D1_FooterCtrl.D1SettingWithUserTypeWrapper d1FooterObj =D1_FooterCtrl.getD1SettingDetail(null,null);
            System.assert(d1FooterObj != null, 'd1 setting details not found');
        }         
    } 
    
    @isTest
    public static void getD1UserTypeTest()
    {
        User extUser = [Select id,Available_Countries__c,D1_User_Type__c,D1_User_Type_Id__c from User where Profile.Name = 'DiageoOne External User' and UserName = 'testclassextuser1@testdomain.com' limit 1];
        system.runAs(extUser)
        {	
            
        	D1_User_Type__c userType = D1_FooterCtrl.getD1UserType(extUser);
            System.assertEquals(userType.Id,extuser.D1_User_Type_Id__c, 'd1 user type not equal');
            
            D1_FooterCtrl.D1SettingWithUserTypeWrapper d1footerObj =D1_FooterCtrl.getD1SettingDetail(null,null);
            System.assert(d1footerObj!=null, 'd1 footer object not found');
        }
    }
}