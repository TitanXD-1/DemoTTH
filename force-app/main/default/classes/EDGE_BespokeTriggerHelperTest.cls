/**
* @Name: EDGE_BespokeTriggerHelperTest


* @History                                                            
                                                        
* @VERSION   AUTHOR            DATE              DETAIL
*  1.0       Sandeep Sahoo     07/08/2019        ES20-3468
*  2.0       Anand Uppalapati  28/04/2022        ES20-12607
*/
@isTest
public class EDGE_BespokeTriggerHelperTest {
    @isTest
    public static void updateUserFieldsTest(){
				
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
        EDGE_UtilityTestClass.createOrgSettings();
        //List<User> users = new List<User>();
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesMan','System Administrator');
        insert salesManager;  
        System.assert(salesManager.Id!=null,'Sales Manager should not be null');
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.ManagerId = salesManager.id;
        insert salesRep; 
        
        System.assert(salesRep.Id!=null,'Sales Rep should not be null');
        
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Local-Segment2');
        pickupOption.RecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId();
        pickupOption.Name = 'Segment[AU]';
        insert pickupOption;
        
        Pick_Up_Options__c pickupOption1 = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption1.Name = 'Gold[AU]';
        insert pickupOption1;
    test.startTest();
        Account operator = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        operator.Outlet_Visit_Prioritisation_Grade__c =  pickupOption1.Id;
        operator.IsOperator__c = true;
        operator.Person_Responsible__c=salesRep.Id;
        //insert operator;   
        
        Account owner = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        owner.Outlet_Visit_Prioritisation_Grade__c =  pickupOption1.Id;
		owner.IsOwner__c = true; 
        owner.Person_Responsible__c=salesRep.Id;
        //insert owner;
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption1.Id;
        outlet.Independent_of_Operator__c = true ;
        //outlet.Operator__c = operator.Id;
        outlet.Independent_of_Owner__c = true;
        //outlet.ParentId = owner.Id;
        //insert outlet;
        List<Account> accList = new List<Account>();
        accList.add(operator);
        accList.add(owner);
        accList.add(outlet);
        insert accList;
        System.runAs(salesManager){
            Group g1 = new Group(Name='AU_CFM', type='Queue');
            insert g1;
            Group g2 = new Group(Name='AU_CFM2', type='Queue');
            g2.DeveloperName='ClusterAUCT_Up';
            insert g2;
            
            
            QueueSObject q1 = new QueueSObject(QueueID = g1.id, SobjectType = 'Geography__c');
            insert q1; 
            QueueSObject q2 = new QueueSObject(QueueID = g2.id, SobjectType = 'Geography__c');
            insert q2; 
            GroupMember grpMem1 = new GroupMember();
            grpMem1.UserOrGroupId = salesManager.Id;
            grpMem1.GroupId = g1.Id;
            insert grpMem1;
            GroupMember grpMem2 = new GroupMember();
            grpMem2.UserOrGroupId = salesManager.Id;
            grpMem2.GroupId = g2.Id;
            insert grpMem2;
        } 
        
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
        Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
        insert objContract;
        
        String deliveryPartnerRecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
        Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
        deliveryPartner.RecordTypeId = deliveryPartnerRecordTypeId;
        insert deliveryPartner;
       
        Market_Setting__c mktSetting = EDGE_UtilityTestClass.getMarketSetting(countryId);
        mktSetting.Supplier_Bespoke_Activation__c = deliveryPartner.Id;
        mktSetting.Supplier_Bespoke_Promotion__c = deliveryPartner.Id;
        mktSetting.Threshold_Format__c = 'Percent';
        insert mktSetting;
        //List<Bespoke__c> bespokelistRec = new list<Bespoke__c>();
        String promotionRecordTypeId = Bespoke__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Bespoke Promotion').getRecordTypeId();
        Bespoke__c objBespoke = new Bespoke__c();
        objBespoke.RecordTypeId = promotionRecordTypeId;
        objBespoke.Account__c = outlet.id;
        objBespoke.Activity_Objectives__c = pickupOption.id;
        objBespoke.Contract__c = objContract.Id;
        objBespoke.Country__c = countryId;
        objBespoke.Sales_Rep__c = salesRep.id;        
        objBespoke.Start_Date__c = System.today();
        objBespoke.End_Date__c = System.today().addDays(10);
        List<Bespoke__c> bespokelist = new List<Bespoke__c>();
        bespokelist.add(objBespoke);
        
        //System.assert(objBespoke.id!=null);
        
        String activationRecordTypeId = Bespoke__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Bespoke Activation').getRecordTypeId();
        Bespoke__c objBespoke1 = new Bespoke__c();
        objBespoke1.Account__c = outlet.id;
        objBespoke1.RecordTypeId = activationRecordTypeId;
        objBespoke1.Activity_Objectives__c = pickupOption.id;
        objBespoke1.Contract__c = objContract.Id;
        objBespoke1.Country__c = countryId;
        objBespoke1.Sales_Rep__c = salesRep.id;
        objBespoke1.Start_Date__c = System.today();
        objBespoke1.Project_Name__c = 'Test';
        objBespoke1.Delivery_Partner__c = deliveryPartner.id;
        objBespoke1.End_Date__c = System.today().addDays(10);
        bespokelist.add(objBespoke1);
        
       
        insert bespokelist;
        test.stopTest();
        //System.assert(objBespoke1.id!=null);
		
        ContentVersion conVerRecPDF1 = EDGE_UtilityTestClass.gerConVerRec('Product12345.JPEG');
        conVerRecPDF1.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Bespoke').getRecordTypeId();
        conVerRecPDF1.Content_Type__c = 'Bespoke';
        conVerRecPDF1.Title = 'OutletRes.pdf';
        insert conVerRecPDF1;
        
        ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :conVerRecPDF1.Id];
        
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId= objBespoke1.id;
        contentlink.ShareType= 'V';
        contentlink.ContentDocumentId=testcontent.ContentDocumentId;
        contentlink.Visibility = 'AllUsers';
        insert contentlink;		
        
        objBespoke1.Status__c = 'Ready For Order';
        update objBespoke1;
		
		system.debug(LoggingLevel.Debug,'objBespoke1Id++ ' + objBespoke1.Id);
        system.assert(contentlink.id != null,'Content Link should not be null');
		
        delete objBespoke1;
        undelete objBespoke1;	
		
		
		
    }
    
}