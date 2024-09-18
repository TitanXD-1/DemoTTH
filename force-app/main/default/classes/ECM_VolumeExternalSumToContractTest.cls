/*
* Name: ECM_VolumeExternalSumToContractTest
* Purpose: This is the test Class for ECM_VolumeExternalSumToContract
* History                                                            
*              	                                             
*VERSION		AUTHOR						DATE				DETAIL
*1.0		    Suvendu			        	12/10/2023			Initial Development : 146142
*
*/
@isTest
public class ECM_VolumeExternalSumToContractTest {

    
    @isTest
    public static void testDepletionDataIE(){
        
        setupDataIE();
        
        Market_Batch_Setting__mdt batchSetting = [SELECT Id, DeveloperName, MasterLabel, Language, NamespacePrefix, 
                                                  Label, QualifiedApiName, SystemModstamp, Batch_Class__c, Country_Code__c,
                                                  Job_Group__c, Market_Order__c, Region__c, Scope__c, Serial_Number__c, 
                                                  Frequency__c, Day_of_Month__c, Day_of_Week__c  
                                                  FROM Market_Batch_Setting__mdt 
                                                  WHERE  Region__c = 'Europe and Turkey' AND
                                                  Country_Code__c = 'IE' AND Job_Group__c = 'Miscellaneous' AND
                                                  Batch_Class__c = 'ECM_VolumeExternalSumToContract'
                                                  Order by Serial_Number__c LIMIT 1];
        String className = batchSetting.Batch_Class__c;
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        System.assertEquals('IE', batchSetting.Country_Code__c, 'IE');
    }
    @isTest
    public static void testDepletionDataNIR(){
        
        setupDataNIR();
        
        Market_Batch_Setting__mdt batchSetting = [SELECT Id, DeveloperName, MasterLabel, Language, NamespacePrefix, 
                                                  Label, QualifiedApiName, SystemModstamp, Batch_Class__c, Country_Code__c,
                                                  Job_Group__c, Market_Order__c, Region__c, Scope__c, Serial_Number__c, 
                                                  Frequency__c, Day_of_Month__c, Day_of_Week__c  
                                                  FROM Market_Batch_Setting__mdt 
                                                  WHERE  Region__c = 'Europe and Turkey' AND
                                                  Country_Code__c = 'NIR' AND Job_Group__c = 'Miscellaneous' AND
                                                  Batch_Class__c = 'ECM_VolumeExternalSumToContract'
                                                  Order by Serial_Number__c LIMIT 1];
        String className = batchSetting.Batch_Class__c;
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        System.assertEquals('NIR', batchSetting.Country_Code__c, 'NIR');
    }
    
    @isTest
    public static void setupDataIE() {
        
        Id geographyId = EDGE_UtilityTestClass.setupCountryPL('IE');

		//Territory for outlet        
        Territory__c  testTerritory = EDGE_UtilityTestClass.getTerritoryRec();
        insert testTerritory;
     
        //Setting up Required Item for EU Contract: Agreement Type
        ECM_Contract_Type__c contractType= ECM_UtilityTestClass.createContractType(geographyId);
        contractType.ECM_Volume_UoM_for_Beer__c = 'EU';
        contractType.ECM_Enable_Volume_External_Source__c = true;
        contractType.ECM_Screen_3_field_configuration__c = 'Product Name;Brand;Category;Volume Target;Rate Per UoM;Investment;Product Growth Strategy';
        insert contractType;
        
        //Setting up Required Item for EU Contract: Account - RecordType Outlet
        String accRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId(); 
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.RecordTypeId = accRecordTypeId;
        insert outlet;
        
        //Setting up Required Item for EU Contract: Payment Frequency : Two Records to test two different scenarios based upon Payment Frequency
        ECM_Payment_Frequency__c paymentFreq = ECM_UtilityTestClass.getPayFre(geographyId);
        paymentFreq.ECM_Type__c = 'Yearly';
        paymentFreq.ECM_Number_of_months_for_recurrence__c = '12';
        List<ECM_Payment_Frequency__c> paymentFreqList = new List<ECM_Payment_Frequency__c>{paymentFreq};
        ECM_Payment_Frequency__c paymentFreq1 = paymentFreq.clone(false,false,false,false);
        paymentFreq.ECM_Type__c = 'Monthly Retrospective';
        paymentFreq.ECM_Number_of_months_for_recurrence__c = '1';
        paymentFreqList.add(paymentFreq1);
        insert paymentFreqList;
        
        //Setting up  Contract Records : Two contracts to test 'Selected UoM' and 'Payment Frequency' dependent two scenarios
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
        objContract.Status = 'Draft';
        objContract.ECM_Territory__c=testTerritory.Id;
        objContract.ECM_Agreement_Type__c=contractType.Id;
        objContract.ECM_Payment_Frequency_Type__c = paymentFreq.Id;
        objContract.ECM_Select_UoM__c = 'min UoM';
        objContract.StartDate = system.today().addmonths(-1).toStartOfMonth();
        objContract.Contract_End_Date__c = system.today().addmonths(10).toStartOfMonth().addDays(-1);
        objContract.ECM_Duration__c =10;
        insert objContract; 
        
        Outlet_Contract__c outletcontract=New Outlet_Contract__c();
        outletcontract.Contract__c=objContract.Id;
        outletcontract.Outlet__c=outlet.Id;
        outletcontract.Status__c='Active';
        outletcontract.Activation_Date__c=system.today();
        insert outletcontract;

        //Setting Up Product Record : a single product to be included in multiple related items
        Product__c product = EDGE_UtilityTestClass.getProd();
        product.Name='JW black Tester';
        product.Country__c=geographyId;
        insert product;
        
        //Setting Up Product UoM to fetch the conversion factors
        List<Product_UOM__c> prodUOM = new List<Product_UOM__c>{new Product_UOM__c(Product__c = product.Id,Conversion_Factor__c = 2,
                                                                                   Type__c ='CEQ',Unique_ID__c = '1515'),
            													new Product_UOM__c(Product__c = product.Id,Conversion_Factor__c = 3,
                                                                                   Type__c ='BTL',Unique_ID__c = '1616')};
        insert prodUOM;
        
        
        //Setting up MAP and two contract Items to map with contracts
        Market_Assortment_Product__c marketAssortment = ECM_UtilityTestClass.createMarketAssortmentProduct(product.Id,geographyId);
        insert marketAssortment;
        ECM_Contract_Item__c conItem = ECM_UtilityTestClass.createcontractitem(objContract.Id,marketAssortment.Id);
        conItem.ECM_Actual_Volume_CTD_External_Source__c = 10.5;
        List<ECM_Contract_Item__c> conItemList = new List<ECM_Contract_Item__c>();
        conItemList.add(conItem);
        insert conItemList;
        
        //Updating contract status to Update before mapping Depletions & Payment Summaries
        objContract.Status = 'Active';
        update objContract;
        System.assertEquals('Active', objContract.Status, 'Active');

    }

    @isTest
    public static void setupDataNIR() {

        Id geographyId = EDGE_UtilityTestClass.setupCountryPL('NIR');

		//Territory for outlet        
        Territory__c  testTerritory = EDGE_UtilityTestClass.getTerritoryRec();
        insert testTerritory;
     
        //Setting up Required Item for EU Contract: Agreement Type
        ECM_Contract_Type__c contractType= ECM_UtilityTestClass.createContractType(geographyId);
        contractType.ECM_Volume_UoM_for_Beer__c = 'EU';
        contractType.ECM_Enable_Volume_External_Source__c = true;
        contractType.ECM_Screen_3_field_configuration__c = 'Product Name;Brand;Category;Volume Target;Rate Per UoM;Investment;Product Growth Strategy';
        insert contractType;
        
        //Setting up Required Item for EU Contract: Account - RecordType Outlet
        String accRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId(); 
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.RecordTypeId = accRecordTypeId;
        insert outlet;
        
        //Setting up Required Item for EU Contract: Payment Frequency : Two Records to test two different scenarios based upon Payment Frequency
        ECM_Payment_Frequency__c paymentFreq = ECM_UtilityTestClass.getPayFre(geographyId);
        paymentFreq.ECM_Type__c = 'Yearly';
        paymentFreq.ECM_Number_of_months_for_recurrence__c = '12';
        List<ECM_Payment_Frequency__c> paymentFreqList = new List<ECM_Payment_Frequency__c>{paymentFreq};
        ECM_Payment_Frequency__c paymentFreq1 = paymentFreq.clone(false,false,false,false);
        paymentFreq.ECM_Type__c = 'Monthly Retrospective';
        paymentFreq.ECM_Number_of_months_for_recurrence__c = '1';
        paymentFreqList.add(paymentFreq1);
        insert paymentFreqList;
        
        //Setting up  Contract Records : Two contracts to test 'Selected UoM' and 'Payment Frequency' dependent two scenarios
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
        objContract.Status = 'Draft';
        objContract.ECM_Territory__c=testTerritory.Id;
        objContract.ECM_Agreement_Type__c=contractType.Id;
        objContract.ECM_Payment_Frequency_Type__c = paymentFreq.Id;
        objContract.ECM_Select_UoM__c = 'min UoM';
        objContract.StartDate = system.today().addmonths(-1).toStartOfMonth();
        objContract.Contract_End_Date__c = system.today().addmonths(10).toStartOfMonth().addDays(-1);
        objContract.ECM_Duration__c =10;
        insert objContract; 
        
        Outlet_Contract__c outletcontract=New Outlet_Contract__c();
        outletcontract.Contract__c=objContract.Id;
        outletcontract.Outlet__c=outlet.Id;
        outletcontract.Status__c='Active';
        outletcontract.Activation_Date__c=system.today();
        insert outletcontract;

        //Setting Up Product Record : a single product to be included in multiple related items
        Product__c product = EDGE_UtilityTestClass.getProd();
        product.Name='JW black Tester';
        product.Country__c=geographyId;
        insert product;

        //Setting Up Product UoM to fetch the conversion factors
        List<Product_UOM__c> prodUOM = new List<Product_UOM__c>{new Product_UOM__c(Product__c = product.Id,Conversion_Factor__c = 2,
                                                                                   Type__c ='CEQ',Unique_ID__c = '1515'),
            													new Product_UOM__c(Product__c = product.Id,Conversion_Factor__c = 3,
                                                                                   Type__c ='BTL',Unique_ID__c = '1616')};
        insert prodUOM;
        
        
        //Setting up MAP and two contract Items to map with contracts
        Market_Assortment_Product__c marketAssortment = ECM_UtilityTestClass.createMarketAssortmentProduct(product.Id,geographyId);
        insert marketAssortment;
        ECM_Contract_Item__c conItem = ECM_UtilityTestClass.createcontractitem(objContract.Id,marketAssortment.Id);
        conItem.ECM_Actual_Volume_CTD_External_Source__c = 10.5;
        List<ECM_Contract_Item__c> conItemList = new List<ECM_Contract_Item__c>();
        conItemList.add(conItem);
        insert conItemList;
        
        //Updating contract status to Update before mapping Depletions & Payment Summaries
        objContract.Status = 'Active';
        update objContract;
        System.assertEquals('Active', objContract.Status, 'Active');
    }
}