/*
*@Name: ECM_AnP_PlanningCalcBatchTest
*@Description: This is the Test class for ECM_AnP_PlanningCalcBatch
*@History                                                            
*                                                       
*VERSION		AUTHOR				DATE					DETAIL
*1.0		Saurav Prasad		24-07-2023			Initial Development - 143389 : Creation of A&P screen records for Active/Expired contract and equal split of A&P
*/ 
@isTest
public class ECM_AnP_PlanningCalcBatchTest {
    
    @isTest
	public static void validateContractStatusChangeBatchGB(){
		Id countryId = EDGE_UtilityTestClass.setupCountrySpain('GB');
		system.assert(countryId!= null,'countryId should not be null');
		String conOutletRecTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
		
		Geography__c  marketObj;
        List<Geography__c> marketList = [SELECT Id FROM Geography__c WHERE Name ='Global1'];
        if(!marketList.isEmpty()){
            marketObj = EDGE_UtilityTestClass.createGeography('Market');
            marketObj.Name = 'Europe and Turkey';
            marketObj.Code__c = 'EAT2';
            marketObj.Parent_Geography__c = marketList[0].Id;
            insert marketObj;
        }
        
		User salesRep = ECM_UtilityTestClass.createUser('srp',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
		salesRep.Username= 'sRep134@test.com';
		insert salesRep;
        
		
		Account acc = EDGE_UtilityTestClass.getOutletRecord();
		acc.country__c = countryId;
		acc.Sales_Org__c='sale';
		acc.SAP_Sold_to__c='sapsold';
		acc.Independent_of_Operator__c=true;
		acc.Independent_of_Owner__c=true;
		insert acc;
		
		ECM_Contract_Type__c aggType = ECM_UtilityTestClass.createContractType(countryId);
        aggType.ECM_Volume_UoM_for_Beer__c = 'EU';
        aggType.ECM_Screen_3_field_configuration__c = 'Product Name;Brand;Category;Volume Target;Rate Per UoM;Investment;Product Growth Strategy';
        aggType.ECM_Enable_A_P_screen__c = true;
		insert aggType;
		
		Contract contr = ECM_UtilityTestClass.createContract(acc.Id,conOutletRecTypeId);
		contr.ECM_Agreement_Type__c= aggType.Id;
		contr.ownerId=salesRep.Id;
		contr.StartDate = System.today().toStartOfMonth();
		contr.Contract_End_Date__c = System.today().toStartOfMonth().addMonths(61).addDays(-1);
        contr.ECM_Duration__c = 60;
        contr.ECM_A_P_Records_Created__c = false;
		contr.Status='Draft';
		insert contr;
		contr.Status='Active';
		update contr;
		
		ECM_Payment_Summary__c ps1 = ECM_UtilityTestClass.getPaymentSummary(contr.Id);
		ps1.ECM_Payment_Summary_Status__c='Completed';
		ps1.ECM_Type__c='Volume-Based';
		insert ps1;
		
		Contract contr1 = ECM_UtilityTestClass.createContract(acc.Id,conOutletRecTypeId);
		contr1.ECM_Agreement_Type__c= aggType.Id;
		contr1.ownerId=salesRep.Id;
		contr1.StartDate = System.today() - 7;
		contr1.Contract_End_Date__c = System.today() - 1;
		contr1.Status='Draft';
		insert contr1;
		contr1.Status='Active';
		update contr1;
        
        Product__c product = new Product__c();
        product.Name='Test';
        product.Product_Full_Name__c='Test';
        product.Country__c=countryId;
        insert product;
        
        Product_UOM__c prdtUOM = new Product_UOM__c();
        prdtUOM.Product__c = product.Id;
        prdtUOM.Conversion_Factor__c = 2;
        prdtUOM.Type__c='BTL';
        prdtUOM.Unique_ID__c= product.id +'BTL';
        insert prdtUOM;
        
        Product__c product1 = new Product__c();
        product1.Name='Test 1';
        product1.Product_Full_Name__c='Test 1';
        product1.Country__c=countryId;
        insert product1;
        
        Product_UOM__c prdtUOM1 = new Product_UOM__c();
        prdtUOM1.Product__c = product.Id;
        prdtUOM1.Conversion_Factor__c = 2;
        prdtUOM1.Type__c='BTL';
        prdtUOM1.Unique_ID__c= product.id +'BTL';
        insert prdtUOM1;
        
        Market_Assortment_Product__c marketassort = new Market_Assortment_Product__c();
        marketassort.Product__c=product.Id;
        marketassort.Market_Assortment__c=countryId;
        insert marketassort;
        ECM_Product_Agreement__c productagg = new ECM_Product_Agreement__c();
        productagg.ECM_Market_Assortment_Product__c=marketassort.Id;
        productagg.ECM_Contract_Type__c=aggType.Id;
        insert productagg;
        
        ECM_Contract_Item__c newcontractitem= new ECM_Contract_Item__c();
        newcontractitem.ECM_Contract__c=contr.Id;
        newcontractitem.ECM_Product__c=marketassort.id;
        newcontractitem.ECM_TotalAnP_incl_Indirect__c= 200;
        insert newcontractitem;
        
        Market_Assortment_Product__c marketassort1 = new Market_Assortment_Product__c();
        marketassort1.Product__c=product1.Id;
        marketassort1.Market_Assortment__c=countryId;
        insert marketassort1;
        ECM_Product_Agreement__c productagg1 = new ECM_Product_Agreement__c();
        productagg1.ECM_Market_Assortment_Product__c=marketassort1.Id;
        productagg1.ECM_Contract_Type__c=aggType.Id;
        insert productagg1;
        
        ECM_Contract_Item__c newcontractitem1= new ECM_Contract_Item__c();
        newcontractitem1.ECM_Contract__c=contr.Id;
        newcontractitem1.ECM_Product__c=marketassort1.id;
        newcontractitem1.ECM_TotalAnP_incl_Indirect__c= 0;
        insert newcontractitem1;
		
		ECM_Payment_Summary__c ps2 = ECM_UtilityTestClass.getPaymentSummary(contr1.Id);
		ps2.ECM_Payment_Summary_Status__c='Open';
		ps2.ECM_Type__c='Volume-Based';
		insert ps2;
		Test.startTest();
		Market_Batch_Setting__mdt batchSetting = [SELECT MasterLabel, Batch_Class__c, Country_Code__c, Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c,
												  Region__c FROM Market_Batch_Setting__mdt WHERE Batch_Class__c = 'ECM_AnP_PlanningCalcBatch' AND 
												  Country_Code__c = 'GB'];
        String className = batchSetting.Batch_Class__c;
		Type t  = Type.forName(className);
		BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
		job.getBatchDetails(batchSetting);
		Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
		Test.stopTest();		
	}
	@isTest
	public static void validateContractStatusChangeBatchGB1(){
		Id countryId = EDGE_UtilityTestClass.setupCountrySpain('GB');
		system.assert(countryId!= null,'countryId should not be null');
		String conOutletRecTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
		
		Geography__c  marketObj;
        List<Geography__c> marketList = [SELECT Id FROM Geography__c WHERE Name ='Global1'];
        if(!marketList.isEmpty()){
            marketObj = EDGE_UtilityTestClass.createGeography('Market');
            marketObj.Name = 'Europe and Turkey';
            marketObj.Code__c = 'EAT2';
            marketObj.Parent_Geography__c = marketList[0].Id;
            insert marketObj;
        }
        
		User salesRep = ECM_UtilityTestClass.createUser('srp',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
		salesRep.Username= 'sRep134@test.com';
		insert salesRep;
        
		
		Account acc = EDGE_UtilityTestClass.getOutletRecord();
		acc.country__c = countryId;
		acc.Sales_Org__c='sale';
		acc.SAP_Sold_to__c='sapsold';
		acc.Independent_of_Operator__c=true;
		acc.Independent_of_Owner__c=true;
		insert acc;
		
		ECM_Contract_Type__c aggType = ECM_UtilityTestClass.createContractType(countryId);
        aggType.ECM_Volume_UoM_for_Beer__c = 'EU';
        aggType.ECM_Screen_3_field_configuration__c = 'Product Name;Brand;Category;Volume Target;Rate Per UoM;Investment;Product Growth Strategy';
        aggType.ECM_Enable_A_P_screen__c = true;
		insert aggType;
		
		Contract contr = ECM_UtilityTestClass.createContract(acc.Id,conOutletRecTypeId);
		contr.ECM_Agreement_Type__c= aggType.Id;
		contr.ownerId=salesRep.Id;
		contr.StartDate = System.today().toStartOfMonth();
		contr.Contract_End_Date__c = System.today().toStartOfMonth().addMonths(13).addDays(-1);
        contr.ECM_Duration__c = 12;
        contr.ECM_A_P_Records_Created__c = false;
		contr.Status='Draft';
		insert contr;
		contr.Status='Active';
		update contr;
		
		ECM_Payment_Summary__c ps1 = ECM_UtilityTestClass.getPaymentSummary(contr.Id);
		ps1.ECM_Payment_Summary_Status__c='Completed';
		ps1.ECM_Type__c='Volume-Based';
		insert ps1;
		
		Contract contr1 = ECM_UtilityTestClass.createContract(acc.Id,conOutletRecTypeId);
		contr1.ECM_Agreement_Type__c= aggType.Id;
		contr1.ownerId=salesRep.Id;
		contr1.StartDate = System.today() - 7;
        contr1.ECM_A_P_Records_Created__c = false;
		contr1.Contract_End_Date__c = System.today() - 1;
		contr1.Status='Draft';
		insert contr1;
		contr1.Status='Active';
		update contr1;
        
        Product__c product = new Product__c();
        product.Name='Test';
        product.Product_Full_Name__c='Test';
        product.Country__c=countryId;
        insert product;
        
        Product_UOM__c prdtUOM = new Product_UOM__c();
        prdtUOM.Product__c = product.Id;
        prdtUOM.Conversion_Factor__c = 2;
        prdtUOM.Type__c='BTL';
        prdtUOM.Unique_ID__c= product.id +'BTL';
        insert prdtUOM;
        
        Product__c product1 = new Product__c();
        product1.Name='Test 1';
        product1.Product_Full_Name__c='Test 1';
        product1.Country__c=countryId;
        insert product1;
        
        Product_UOM__c prdtUOM1 = new Product_UOM__c();
        prdtUOM1.Product__c = product.Id;
        prdtUOM1.Conversion_Factor__c = 2;
        prdtUOM1.Type__c='BTL';
        prdtUOM1.Unique_ID__c= product.id +'BTL';
        insert prdtUOM1;
        
        Market_Assortment_Product__c marketassort = new Market_Assortment_Product__c();
        marketassort.Product__c=product.Id;
        marketassort.Market_Assortment__c=countryId;
        insert marketassort;
        ECM_Product_Agreement__c productagg = new ECM_Product_Agreement__c();
        productagg.ECM_Market_Assortment_Product__c=marketassort.Id;
        productagg.ECM_Contract_Type__c=aggType.Id;
        insert productagg;
        
        ECM_Contract_Item__c newcontractitem= new ECM_Contract_Item__c();
        newcontractitem.ECM_Contract__c=contr.Id;
        newcontractitem.ECM_Product__c=marketassort.id;
        newcontractitem.ECM_TotalAnP_incl_Indirect__c= 200;
        insert newcontractitem;
        
        Market_Assortment_Product__c marketassort1 = new Market_Assortment_Product__c();
        marketassort1.Product__c=product1.Id;
        marketassort1.Market_Assortment__c=countryId;
        insert marketassort1;
        ECM_Product_Agreement__c productagg1 = new ECM_Product_Agreement__c();
        productagg1.ECM_Market_Assortment_Product__c=marketassort1.Id;
        productagg1.ECM_Contract_Type__c=aggType.Id;
        insert productagg1;
        
        ECM_Contract_Item__c newcontractitem1= new ECM_Contract_Item__c();
        newcontractitem1.ECM_Contract__c=contr1.Id;
        newcontractitem1.ECM_Product__c=marketassort1.id;
        newcontractitem1.ECM_TotalAnP_incl_Indirect__c= 0;
        insert newcontractitem1;
		
		ECM_Payment_Summary__c ps2 = ECM_UtilityTestClass.getPaymentSummary(contr1.Id);
		ps2.ECM_Payment_Summary_Status__c='Open';
		ps2.ECM_Type__c='Volume-Based';
		insert ps2;
		Test.startTest();
		Market_Batch_Setting__mdt batchSetting = [SELECT MasterLabel, Batch_Class__c, Country_Code__c, Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c,
												  Region__c FROM Market_Batch_Setting__mdt WHERE Batch_Class__c = 'ECM_AnP_PlanningCalcBatch' AND 
												  Country_Code__c = 'GB'];
        String className = batchSetting.Batch_Class__c;
		Type t  = Type.forName(className);
		BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
		job.getBatchDetails(batchSetting);
		Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
		Test.stopTest();		
	}
	
	
}