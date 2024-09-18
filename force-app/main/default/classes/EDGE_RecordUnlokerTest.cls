/**********************************************************************
Name:EDGE_RecordUnlokerTest

=======================================================================
Req: This is the test class for EDGE_BespokeHistoryService,EDGE_BespokeHistoryController

=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
2.0     Prasanth T          23/09/2022      ES20-13324(Test Class Correction Due to Failure)
***********************************************************************/
@istest
public class EDGE_RecordUnlokerTest {
    @istest
    public static void testRecordUnlock(){ 
        
        String prospectRecTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        EDGE_UtilityTestClass.createOrgSettings();
        
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AUT');
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AUT]';
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesMngr','Sales Manager');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.ManagerId = testAdminUser.id;
        testAdminUser.ManagerId = salesManager.id;
        insert testAdminUser; 
        test.startTest();
        Market_setting__c marketRec = new Market_setting__c();
        marketRec.name = 'Test market setting';
        marketRec.Geography__c = geographyId;
        marketRec.Prospect_Approver__c = 'Sales Manager Approval Required';
        insert marketRec;
        System.runAs(testAdminUser){
            Account testAccount = EDGE_UtilityTestClass.getProspectRecord(pickupOption.Id);
            testAccount.RecordTypeId =prospectRecTypeId;
            testAccount.Status__c='Draft';
            testAccount.BillingStreet = 'testStreet';
            testAccount.Global_Channel__c = 'off Trade';
            testAccount.Global_Sub_Channel__c = 'Retailer';
            testAccount.Global_Segment__c = 'Hypermarket';
            testAccount.Global_Sub_Segment__c = 'Modern Hypermarket';
            testAccount.BillingCity = 'Tasmania';
            testAccount.BillingCountry = 'Australia';
            testAccount.Independent_of_Operator__c = True;
            testAccount.Independent_of_Owner__c = True;
            insert testAccount;
            system.assert(testAccount.id != null);
        
            testAccount.Status__c='Submitted'; 
            update testAccount;
            
            Map<Id,Account> newItems = new Map<Id,Account>();
            newItems.put(testAccount.Id,testAccount);
            
            Map<Id,Account> oldItems = new Map<Id,Account>();
            oldItems.put(testAccount.Id,testAccount);
     
        }
        test.stopTest();
        
    }
}