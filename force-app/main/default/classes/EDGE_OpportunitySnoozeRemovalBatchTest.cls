/*
Name: EDGE_OpportunitySnoozeRemovalBatchTest
Req: 
User Story : ES20-6969
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0     Sagar Barman        09/12/2019      
2.0     Swaraj Samanta      06/09/2022        Test Class Correction Due to Failure(ES20-13284)
*/
@isTest
public class EDGE_OpportunitySnoozeRemovalBatchTest {
    @isTest
    public static void testSnoozeDate(){
        
        
        Market_Batch_Setting__mdt batchSetting = [Select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c 
                                                  from Market_Batch_Setting__mdt 
                                                  where Batch_Class__c = 'EDGE_OpportunitySnoozeRemovalBatch'
                                                  and Country_Code__c ='AU'];
        system.assert(batchSetting.Id != null);
        String className = batchSetting.Batch_Class__c;         
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(200));
        
        
        
        
    } 
    @testSetup
    public static void createData(){
        // EDGE_UtilityTestClass.createOrgSettings();
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = True;
        orgSetting.Run_Process_Builders__c = True;
        insert orgSetting;       
        
        Id countryID = EDGE_UtilityTestClass.setupCountry('AU'); 
        
        
        
        
        //insert pickup option
        Pick_Up_Options__c pickUpVisit = EDGE_UtilityTestClass.getPickUpOption(countryID,'Outlet Visit Prioritization');
        pickUpVisit.Name = 'Gold[AU]';
        insert pickUpVisit;
        
        List<Opportunity> oppList = new List<Opportunity>();
        
        //create outlet record             
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Country__c = countryID;
        outletAccount.Outlet_Visit_Prioritisation_Grade__c =pickUpVisit.Id;
        
        Test.startTest();
        insert outletAccount;
        
        List<User> mdmUserList = new List<User>();
        User mdmUser1 = EDGE_UtilityTestClass.runAsUser('salesRep1','Master Data Manager');
        mdmUser1.Available_Countries__c = 'AU';
        mdmUserList.add(mdmUser1);
        
        User mdmUser2 = EDGE_UtilityTestClass.runAsUser('salesRep1','Master Data Manager');
        mdmUser2.Available_Countries__c = 'AU';
        mdmUserList.add(mdmUser2);
        
        User mdmUser3 = EDGE_UtilityTestClass.runAsUser('salesRep1','Master Data Manager');
        mdmUser3.Available_Countries__c = 'AU';
        mdmUserList.add(mdmUser3);
        insert  mdmUserList;
        //create Product             
        Product__c testProd = EDGE_UtilityTestClass.getProd();
        insert testProd; 
        
        for(Integer i=0; i<5; i++){
            Opportunity testOpp = new Opportunity();
            testOpp.CloseDate = Date.today().addDays(7);
            testOpp.Name = 'Test Opp'+ i;
            testopp.AccountId = outletAccount.Id;
            testopp.Snooze_Flag__c = true;
            testopp.Snooze_date__c = Date.today().addDays(-3);
            testopp.Snooze_Approval_Status__c = 'Pending'; 
            testopp.Snooze_reason__c = 'Test Comment';
            testopp.StageName ='Open';
            oppList.add(testopp);
        }
        
        
        for(Integer i=6; i<10; i++){
            Opportunity testOpp = new Opportunity();
            testOpp.CloseDate = Date.today().addDays(7);
            testOpp.Name = 'Test Opp'+ i;
            testopp.AccountId = outletAccount.Id;
            testopp.Snooze_Flag__c = true;
            testopp.Snooze_date__c = Date.today().addDays(-1);
            testopp.Snooze_Approval_Status__c = 'Approved'; 
            testopp.Snooze_reason__c = 'Test Comment';
            testopp.StageName ='Open';
            testopp.Current_Approval_Step__c = 'MDM Approval Required';
            testopp.Approver_1__c = mdmUser1.Id;
            testopp.Approver_2__c = mdmUser2.Id;
            testopp.Approver_3__c = mdmUser3.Id;
            oppList.add(testopp);
        }
        insert oppList;
        oppList[7].Snooze_date__c = Date.today().addDays(-2);
        update oppList[7];
        Test.stopTest();
        
    }   
}