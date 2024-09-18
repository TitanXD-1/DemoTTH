/**
* @Class Name : EDGE_OperatorCBOppDetailsBatchTest
* @Description :   Test class for EDGE_OperatorCBOpportunityDetailsBatch  
 
* @History                                                            
                                                          
* @VERSION     AUTHOR                  DATE              DETAIL
*  1.0                             06/04/2019        Initial Development 
**/
@isTest
public class EDGE_OperatorCBOppDetailsBatchTest {
    
    
    @testSetup
    public static void createTestData(){
        List<User> users = new List<User>();
        
        //Creating Sales Manager
        User salesManager=EDGE_UtilityTestClass.runAsUser('salesRep1','Sales Manager');
        salesManager.Available_Countries__c = 'CO';
        insert salesManager;
        System.assert(salesManager.Id!=null,'sales Manager Id should not be null');
        
        //Creating Sales Rep 1
        User salesRep1 = EDGE_UtilityTestClass.runAsUser('salesRep1','Sales Representative');
        salesRep1.FirstName = 'SalesRep001';
        salesRep1.Available_Countries__c = 'CO';
        salesRep1.ManagerId = salesManager.Id;
        users.add(salesRep1);
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'CO';
        testAdminUser.FirstName = 'SalesAdmin001';
        //insert testAdminUser;
        users.add(testAdminUser);
        
        Database.insert(users);
        
        List<Account> accountListNew = new List<Account>();  
        List<Opportunity> oppList = new List<Opportunity>();  
       // Map<Id,Account> accountMapOld = new  Map<Id,Account>();
        
        EDGE_UtilityTestClass.createOrgSettings();
        // added setupCountryCO by Anamika
        Id countryId = EDGE_UtilityTestClass.setupCountryCO('CO');
        Territory__c territory = EDGE_UtilityTestClass.getTerritoryRec();
        territory.Territory_Type__c = 'Service';
        insert territory;
        List<Product__c> productlst = new List<Product__c> ();
        Product__c p1 = new Product__c ();
        p1.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('SKU').getRecordTypeId();
        p1.Name = 'Product1';
        p1.Product_Full_Name__c = 'Product1';

        productlst.add (p1);
        
        Product__c p2 = new Product__c ();
        p2.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('SKU').getRecordTypeId();
        p2.Name = 'Product2';
        p2.Product_Full_Name__c = 'Product2';
        productlst.add (p2);
        
        insert productlst;
        
        List<Opportunity_Template__c> tempList = new List<Opportunity_Template__c>();
        Opportunity_Template__c oppTemp = EDGE_UtilityTestClass.getOpportunityTemplate(p1.Id, territory.Id, countryId);
        oppTemp.End_Date__c = System.today()+1;
        tempList.add (oppTemp);
        
        Opportunity_Template__c oppTemp2 = EDGE_UtilityTestClass.getOpportunityTemplate(p2.Id, territory.Id, countryId);
        oppTemp2.End_Date__c = System.today()+1;
        tempList.add (oppTemp2);
        insert tempList;
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[CO]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        Test.startTest();
        Market_Cycle__c marCycle = EDGE_UtilityTestClass.getMarketCycle(countryId);
        marCycle.Number_of_Week__c = 52;
        marCycle.Start_Date__c = Date.Today();
        marCycle.End_Date__c = Date.Today().addDays(360);
        insert marCycle;
        
       
        Account operator = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        operator.Person_Responsible__c = salesRep1.Id;
        operator.IsOperator__c = true;
        insert operator;
        
        for(Integer count = 1; count <= 10; count++){//50
            Account testoutlet=EDGE_UtilityTestClass.getOutletRecord();
            testoutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            testoutlet.Independent_of_Operator__c = false;
            testoutlet.Operator__c = operator.Id;
            testoutlet.Name = 'Outlet-00' + count;
            testoutlet.MobilePrefix__c ='+61';
            testoutlet.Mobile__c = '512 123 123';
            testoutlet.PhonePrefix__c = '+61';
            testoutlet.Phone__c = '1 2222 3333';
            accountListNew.add(testoutlet);
        }
        
        Database.insert(accountListNew); 
        
        
        for(Account outlet : accountListNew){
           
            
                Opportunity opp = EDGE_UtilityTestClass.getOpportunity(outlet.Id, 'Opp-Name-00'+p1.Id);
                opp.StageName = 'Open';
                opp.Type = 'Cycle Brief';
                opp.Start_Date__c = Date.Today();
                opp.Opportunity_Template__c = oppTemp.Id;
                opp.product__c = p1.Id;
                oppList.add(opp);
           
           
                Opportunity opp2 = EDGE_UtilityTestClass.getOpportunity(outlet.Id, 'Opp-Name-01'+ p2.Id);
                opp2.StageName = 'Closed';
                opp2.Type = 'Cycle Brief';
                opp2.Start_Date__c = Date.Today();
                opp2.Opportunity_Template__c = oppTemp2.Id;
                opp2.product__c = p2.Id;
                oppList.add(opp2);
           
        }
        EDGE_UtilityClass.printGovLimits(94);
        System.debug(LoggingLevel.Debug,('oppList = '+ oppList));
        Database.insert(oppList);
        
        
        
        
        EDGE_UtilityClass.printGovLimits(98);
        System.runAs(testAdminUser){
            testOperatorCBOpportunityDetailsBatch();
            
        }
        
        EDGE_UtilityClass.printGovLimits(113);
        Test.stopTest();
    }

    @isTest
    public static void testOperatorCBOpportunityDetailsBatch(){
        Market_Batch_Setting__mdt batchSetting = [Select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c 
                                                  from Market_Batch_Setting__mdt 
                                                  where Batch_Class__c = 'EDGE_OperatorCBOpportunityDetailsBatch'
                                                  and Country_Code__c ='CO'];
        system.assert(batchSetting.Id != null,'batch Setting Id should not be null');
        String className = batchSetting.Batch_Class__c;         
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,10000);
        
    }
}