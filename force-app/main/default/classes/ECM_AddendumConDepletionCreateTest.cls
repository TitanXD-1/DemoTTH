/*
* @Name: ECM_AddendumConDepletionCreateTest
* @Description: This is the Test class for ECM_AddendumConDepletionCreateBatch
* @History                                                            

VERSION    AUTHOR                     DATE              DETAIL
1.0        Suvendu Roy	        	  25/10/2022        Initial Development (ECM-6220)
*/ 
@isTest
public class ECM_AddendumConDepletionCreateTest {
    @isTest
    public static void ranTest(){
        Test.startTest();
        insertDepletionTest();
        Market_Batch_Setting__mdt batchSetting = [SELECT MasterLabel, Batch_Class__c, Country_Code__c,Market_Order__c, 
                                                  Serial_Number__c, Scope__c, Job_Group__c, Region__c 
                                                  FROM Market_Batch_Setting__mdt 
                                                  WHERE Batch_Class__c = 'ECM_AddendumConDepletionCreateBatch'
                                                  AND Country_Code__c ='ES' ];
        system.debug(loggingLevel.debug,'->'+batchSetting.Region__c);
        String className = batchSetting.Batch_Class__c;
        System.assert(className!=null,'className should not be null');
        Type t  = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));	
        Test.stopTest();
    }
    static void insertDepletionTest(){
        
        Profile prof = [select id from profile where name=: 'Sales Representative'];
        User usrmngr = new User();
        usrmngr.firstName = 'testManager';
        usrmngr.lastName = 't2';
        usrmngr.profileId = prof.id;        
        usrmngr.email = 'test.MamagerSfdc@test.com';
        usrmngr.Username ='test.MamagerSfdc@test.com';
        usrmngr.Alias='test';
        usrmngr.Timezonesidkey='America/Los_Angeles';
        usrmngr.LocaleSidKey='en_US';
        usrmngr.LanguageLocaleKey='en_US';
        usrmngr.EmailEncodingKey='UTF-8';
        usrmngr.Available_Countries__c='ES';
        insert usrmngr;
        
        User usr = new User();
        usr.firstName = 'test1';
        usr.lastName = 'test2';
        usr.profileId = prof.id;        
        usr.email = 'test.MamagerSfdc1@test.com';
        usr.Username ='test.MamagerSfdc1@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='ES';
        usr.ManagerId = usrmngr.Id;
        usr.DelegatedApproverId = usrmngr.Id;
        insert usr;
        
        Id geographyId = EDGE_UtilityTestClass.setupCountry('ES');
        Geography__c  marketObj;
        List<Geography__c> marketList = [SELECT Id FROM Geography__c WHERE Name ='Global'];
        if(!marketList.isEmpty()){
            marketObj = EDGE_UtilityTestClass.createGeography('Market');
            marketObj.Name = 'Europe and Turkey';
            marketObj.Code__c = 'EAT2';
            marketObj.Parent_Geography__c = marketList[0].Id;
            insert marketObj;
        }
        
        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        contractType.ECM_Activation_Spend_Table_Configuration__c = 'Activation Spend Sub Group;Activity Type Description;Delivery Date;Must Do';
        contractType.ECM_Contract_Approval_mail_to_Customer__c = true;
        insert contractType;

        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Person_Responsible__c= usr.Id;
        outletAccount.OwnerId = usr.Id;
        outletAccount.SAP_Sold_to__c='3984021';
        outletAccount.VAT_Number__c='TAXID123';
        outletAccount.ECM_Legal_Name__c='Legal';
        outletAccount.Email_for_contracts_payments__c='manikandan.t@diageo.com.test';
        outletAccount.Country__c = geographyId;
        outletAccount.IsOperator__c=true;
        outletAccount.SAP_Ship_to__c = 'sap1234';
        outletAccount.Sales_Org__c = 'sap0987';
        insert outletAccount;
        


        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        
        Contract objContract = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract.Status = 'Draft';
        objContract.Contract_End_Date__c = System.today()+29;
        objContract.AccountId=outletAccount.Id;
        objContract.ECM_Agreement_Type__c=contractType.Id;
        objContract.recordTypeId=contractRecordTypeId;
        objContract.ECM_Channel__c='On-Premise';
        objContract.StartDate = system.today();
        objContract.Contract_End_Date__c = system.today()+360;
        objContract.OwnerId = usr.id;
        insert objContract;
        objContract.Status = 'Amended';
        update objContract;
        
        Contract objContract2 = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract2.Status = 'Draft';
        objContract2.Contract_End_Date__c = System.today()+29;
        objContract2.AccountId=outletAccount.Id;
        objContract2.recordTypeId=contractRecordTypeId;
        objContract2.ECM_Channel__c='On-Premise';
        objContract2.StartDate = system.today()+150;
        objContract2.Contract_End_Date__c = system.today()+360;
        objContract2.ECM_Agreement_Type__c=contractType.Id;
        objContract2.ECM_Parent_Contract__c = objContract.Id;
        objContract2.ECM_Amended__c = true;
        objContract2.ECM_Parent_Contract__c= objContract.Id;
        insert objContract2;
        objContract2.Status = 'Active';
        update objContract2;
        // products 
        Product__c product = new Product__c();
        product.Name='product';
        product.Product_Full_Name__c='Test';
        product.Country__c=geographyId;
        insert product;
        Product__c product1 = new Product__c();
        product1.Name='product1';
        product1.Product_Full_Name__c='product1';
        product1.Country__c=geographyId;
        insert product1;
        
        //Depletions for parents
        Depletions__c dep = new Depletions__c();
        dep.ECM_Volume__c = 100.00;
        dep.ECM_Outlet__c = outletAccount.id;
        dep.ECM_Start_Period__c = system.today()+360;
        dep.ECM_End_Period__c = system.today()+29;
        dep.ECM_Product__c = product.id;
        dep.Contract__c = objContract.Id;
        dep.Unique_ID__c= objContract.Id+'_SampleText';
        insert dep;

        Depletions__c dep1 = new Depletions__c();
        dep1.ECM_Volume__c = 90.00;
        dep1.ECM_Outlet__c = outletAccount.id;
        dep1.ECM_Start_Period__c = system.today()+361;
        dep1.ECM_End_Period__c = system.today()+29;
        dep1.ECM_Product__c = product1.id;
        dep1.Contract__c = objContract.Id;
        dep1.Unique_ID__c= objContract.Id+'_SampleText2';
        insert dep1;        
        
        
        
        //con Items for parent
        Market_Assortment_Product__c marketassort1 = new Market_Assortment_Product__c();
        marketassort1.Product__c=product.Id;
        marketassort1.Market_Assortment__c=geographyId;
        marketassort1.OwnerId=usrmngr.Id;
        insert marketassort1;
        Market_Assortment_Product__c marketassort2 = new Market_Assortment_Product__c();
        marketassort2.Product__c=product1.Id;
        marketassort2.Market_Assortment__c=geographyId;
        marketassort2.OwnerId=usrmngr.Id;
        insert marketassort2;
        
        ECM_Contract_Item__c newcontractitem1= new ECM_Contract_Item__c();
        newcontractitem1.ECM_Contract__c=objContract.Id;
        newcontractitem1.ECM_Product__c=marketassort1.id;
        newcontractitem1.ECM_Product_Growth_Driver__c = 'Test PGD/TestPdf';
        insert newcontractitem1;
        ECM_Contract_Item__c newcontractitem2= new ECM_Contract_Item__c();
        newcontractitem2.ECM_Contract__c=objContract.Id;
        newcontractitem2.ECM_Product__c=marketassort2.id;
        newcontractitem2.ECM_Product_Growth_Driver__c = 'Test PGD/TestPdf';
        insert newcontractitem2;
        
        
        //con Items for child
        /*
        Market_Assortment_Product__c marketassort3 = new Market_Assortment_Product__c();
        marketassort3.Product__c=product.Id;
        marketassort3.Market_Assortment__c=geographyId;
        marketassort2.OwnerId=usr.id;
        insert marketassort3;
        Market_Assortment_Product__c marketassort4 = new Market_Assortment_Product__c();
        marketassort4.Product__c=product1.Id;
        marketassort4.Market_Assortment__c=geographyId;
        marketassort4.OwnerId=usr.id;
        insert marketassort4; 

		*/
        
        ECM_Contract_Item__c newcontractitem3= new ECM_Contract_Item__c();
        newcontractitem3.ECM_Contract__c=objContract2.Id;
        newcontractitem3.ECM_Product__c=marketassort1.id;
        newcontractitem3.ECM_Product_Growth_Driver__c = 'Test PGD/TestPdf';
        insert newcontractitem3;
        ECM_Contract_Item__c newcontractitem4= new ECM_Contract_Item__c();
        newcontractitem4.ECM_Contract__c=objContract2.Id;
        newcontractitem4.ECM_Product__c=marketassort2.id;
        newcontractitem4.ECM_Product_Growth_Driver__c = 'Test PGD/TestPdf';
        insert newcontractitem4;
        
        /*
        Map<Id,ID> parentChildIdMap = new Map<Id,ID>();
        parentChildIdMap.put(objContract.id,objContract2.Id);

        Map<ID,Contract> idMapWithChildCon = new Map<ID,Contract>();
        idMapWithChildCon.put(objContract2.id, objContract2);
        
        ECM_AddendumConDepletionCreateHelper.addendumCreate(parentChildIdMap);
		*/
    }
    
}