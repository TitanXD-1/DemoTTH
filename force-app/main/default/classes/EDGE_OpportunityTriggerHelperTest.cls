/*
Name: EDGE_OpportunityTriggerHelperTest

@History                                                            

@VERSION   AUTHOR            DATE              DETAIL
@1.0     Amar Deep         12/12/2019        ES20-3967    
@2.0     Swaraj Samanta    05/09/2022        ES20-13284
@3.0	Shivam Chauhan	   08/06/2024		 155299	
*/
@isTest
public class EDGE_OpportunityTriggerHelperTest {
    @isTest
    public static void updateUserFieldsTest(){
        Id countryId= EDGE_UtilityTestClass.setupCountry('AUT');
        EDGE_UtilityTestClass.createOrgSettings();
        
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;  
        System.assert(salesManager.Id!=null,'Sales Manager Id should not be null');
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.id;
        insert salesRep; 
        System.assert(salesRep.Id!=null,'salesRep Id should not be null');
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();                                     
        Pick_Up_Options__c pickupOption1 = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption1.Name = 'Gold[AUT]';
        pickupOption1.RecordTypeId = pickupRecordType;                                     
        insert pickupOption1;
        
        Territory__c primaryTerr = EDGE_UtilityTestClass.getTerritoryRec();//155299
        primaryTerr.Territory_Type__c ='Service';
        insert primaryTerr;
        
        List<Account> operatorOwnerAccountList=new List<Account>();
        Account operator = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        operator.Outlet_Visit_Prioritisation_Grade__c =  pickupOption1.Id;   
        operator.IsOperator__c=true;                                       
        operatorOwnerAccountList.add(operator);                                      
        Account owner = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        owner.Outlet_Visit_Prioritisation_Grade__c =  pickupOption1.Id;
        owner.IsOwner__c=true;
        operatorOwnerAccountList.add(owner);                                                 
        insert operatorOwnerAccountList;
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption1.Id;
        outlet.Independent_of_Operator__c = false ;
        outlet.Operator__c = operator.Id;
        outlet.Independent_of_Owner__c = false;
        outlet.ParentId = owner.Id;
        outlet.Primary_Sales_Rep__c = salesRep.Id;
        insert outlet;
        
        Opportunity oppNotif = new Opportunity();
        oppNotif.Name = 'TestNotifOpp1';
        oppNotif.StageName = 'Open';
        oppNotif.CloseDate =  System.today().addDays(10);
        oppNotif.AccountId = outlet.Id;
        oppNotif.Hot_Lead__c = true;
        insert oppNotif;
        
        System.runAs(salesManager){
            Group g1 = new Group(Name='AUT_MDM', type='Queue');
            insert g1;
            QueueSObject q1 = new QueueSObject(QueueID = g1.id, SobjectType = 'Geography__c');
            insert q1; 
            GroupMember grpMem1 = new GroupMember();
            grpMem1.UserOrGroupId = salesRep.Id;
            grpMem1.GroupId = g1.Id;
            insert grpMem1;            
        } 
        
        Test.startTest();
        
        String deliveryPartnerRecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
        Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
        deliveryPartner.RecordTypeId = deliveryPartnerRecordTypeId;
        insert deliveryPartner;
        
        Market_Setting__c mktSetting = EDGE_UtilityTestClass.getMarketSetting(countryId);
        mktSetting.Snooze_Opportunity_Request_Approval__c = 'MDM Approval Required';
        mktSetting.Threshold_Format__c = 'Percent';
        insert mktSetting;
        
        Product__c objProduct = EDGE_UtilityTestClass.getProd();
        objProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
        objProduct.Supplier_Partner__c = deliveryPartner.Id;
        objProduct.Pricing_Type__c = 'By Unit';
        objProduct.Units_per_POS__c = 10.0;
        objProduct.Diageo_Cost__c = 40;
        objProduct.Outlet_Cost__c = 50;
        objProduct.Start_Date__c = Date.Today();
        objProduct.POS_Item_Short_Description__c = 'Good';
        insert objProduct;
        
        Opportunity_Template__c oppTemp1 =  EDGE_UtilityTestClass.getOpportunityTemplate(objProduct.Id, primaryTerr.Id, countryId);//155299
        oppTemp1.Opportunity_Type__c = 'MAS';
        oppTemp1.Source__c = 'Advanced Analytics';
        oppTemp1.Closing_Method__c = 'Trax';
        oppTemp1.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp1.Start_Date__c = System.today().addDays(1);
        oppTemp1.Action__c = 'TestAction';
        oppTemp1.Segment__c = 'Nightclub';
        oppTemp1.Sub_Segment__c = 'Modern Nightclub';
        oppTemp1.Territory__c = primaryTerr.Id;
        oppTemp1.Channel__c = '';
        oppTemp1.End_Date__c = System.today().addDays(10);
        oppTemp1.Activation__c = null;
        insert oppTemp1;
        
        List<Opportunity> opportunities=new List<Opportunity>();
        Opportunity opp = new Opportunity();
        opp.Name = 'TestOpp240';
        opp.StageName = 'Open';
        opp.Source__c = 'Advanced Analytics';//155299
        opp.Type = 'MPA';//155299
        opp.Opportunity_Template__c = oppTemp1.Id;
        opp.CloseDate =  System.today().addDays(10);
        opp.AccountId = outlet.Id;
        opp.Product__c = objProduct.Id;
        opp.Snooze_reason__c = 'reason';
        opp.Snooze_date__c = System.today().addDays(5);
        opp.Snooze_Approval_Status__c = 'Pending';
        opportunities.add(opp);                                      
        
        Opportunity opp1 = new Opportunity();
        opp1.Name = 'TestOpp240';
        opp1.StageName = 'Open';
        opp.Source__c = 'Advanced Analytics';//155299
        opp.Type = 'Cycle Brief';//155299
        opp1.CloseDate =  System.today().addDays(10);
        opp1.AccountId = outlet.Id;
        opp1.Product__c = objProduct.Id;
        opp1.Snooze_reason__c = 'reason';
        opp1.Snooze_date__c = system.today().addDays(3);                                    
        opp1.Snooze_Approval_Status__c = 'Pending';
        opportunities.add(opp1);   
        insert opportunities;
        
        mktSetting.Snooze_Opportunity_Request_Approval__c=Label.Opportunity_Sales_Manager_Approval;
        update mktSetting;
        
        opp1.CloseDate = system.today().addDays(30);                                    
        update opp1;
        delete opp1;
        undelete opp1;                                      
        
    }
    
}