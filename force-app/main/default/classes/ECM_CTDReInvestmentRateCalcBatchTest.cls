/*
@Name: ECM_CTDReInvestmentRateCalcBatchTest

@Purpose: This class is used to cover test data for the - ECM_CTDReInvestment_RateCalc_Batch

@History                                                          

VERSION    AUTHOR        DATE              DETAIL
1.0        Swagata     26/05/2022        Initial Development

*/
@isTest
public class ECM_CTDReInvestmentRateCalcBatchTest {
    @isTest
    public static void cTDReInvestmentcal(){
        
        Test.startTest();
        //try{  
        /*
        Geography__c  marketObj;
        List<Geography__c> marketList = [SELECT Id FROM Geography__c WHERE Name ='Global1'];
        if(!marketList.isEmpty()){
            marketObj = EDGE_UtilityTestClass.createGeography('Market');
            marketObj.Name = 'Asiapac';
            marketObj.Code__c = 'APAT';
            marketObj.Parent_Geography__c = marketList[0].Id;
            insert marketObj;
        }
        */
        createCTDReInvestmentcalTest();
        Market_Batch_Setting__mdt batchSetting = [SELECT MasterLabel, Batch_Class__c, Country_Code__c,Market_Order__c, 
                                                  Serial_Number__c, Scope__c, Job_Group__c, Region__c 
                                                  FROM Market_Batch_Setting__mdt 
                                                  WHERE Batch_Class__c = 'ECM_CTDReInvestmentRateCalcBatch'
                                                  AND Country_Code__c ='AU' ];
        
        String className = batchSetting.Batch_Class__c;
        system.assert(className != null,'className should not be null');
		Type t  = Type.forName(className);
		BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
		job.getBatchDetails(batchSetting);
		Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));		
        Test.stopTest();
        
    }
    
    public static void createCTDReInvestmentcalTest() {
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        
        
        
        //String PickupRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        //String Type='Local-Segment1';
        
        
        
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        System.debug(LoggingLevel.Debug,'CTDCal'+geographyId );
        List<Geography__c> marketList1 = [SELECT Id FROM Geography__c WHERE Name ='Global'];
        
        string recordTypeName = Schema.SObjectType.Geography__c.getRecordTypeInfosByDeveloperName().get('Market').getRecordTypeId();
        Geography__c region = new Geography__c();
        region.Name = 'Asiapac';
        region.Code__c = 'APAC';
        region.Parent_Geography__c = marketList1[0].Id;
        region.RecordTypeId = recordTypeName;
        insert region;
        System.debug(LoggingLevel.Debug,'CTDRegion'+region);
        
        
        
        
        
        //user rec
        user newuser = EDGE_UtilityTestClass.runAsUser('Testabc','System Administrator');
        insert newuser;
        
        //create territory rec
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        insert territory;
        
        
        //pickup option
        Pick_Up_Options__c pOption = EDGE_UtilityTestClass.getPickUpOption(geographyId, 'Outlet Visit Prioritization');
        /*pOption.Name = 'Gold[AUT]';
pOption.Geography__c = geographyId;
pOption.Type__c = 'Local-Segment1';
pOption.RecordTypeId = PickupRecordTypeId;
pOption.Days_between_visit__c = 5;
pOption.Status__c = 'Active';
*/
        insert pOption;
        
        
        //Setting up Required Item for EU Contract: Account - RecordType Outlet
        String accRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId(); 
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.RecordTypeId = accRecordTypeId;
        outlet.BillingCity = 'Ascot Vale';
        outlet.BillingState = 'Victoria';
        outlet.BillingCountry = 'Australia';
        outlet.BillingCountryCode = 'AU';
        insert outlet;
        
        //contract type rec
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.Volume_UoM_for_Spirits__c='BTL'; 
        contractType.ECM_Volume_UoM_for_Beer__c = 'Not Applicable';
        contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
        contractType.ECM_Volume_UoM_for_RTD__c = 'Not Applicable';
        contractType.ECM_Volume_UoM_for_Draught_Cocktails__c = 'Not Applicable';
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Volume Target;';
        contractType.ECM_Mandatory_Fields_Check__c ='Prior To Submitting Contract For Approval';
        contractType.ECM_Activation_Spend_Table_Configuration__c = 'Activation Spend Sub Group;Activity Type Description;Delivery Date;Must Do';
        insert contractType;
        
        
        //payment freq rec
        ECM_Payment_Frequency__c paymentFrequency=new ECM_Payment_Frequency__c();
        paymentFrequency.ECM_Geography__c=geographyId;
        paymentFrequency.ECM_Type__c='Equal Instalments';
        paymentFrequency.ECM_Other_Investment__c=true;
        insert paymentFrequency;
        
        
        //payment agreement rec
        ECM_Payment_Agreement__c paymentAgreement= new ECM_Payment_Agreement__c();
        paymentAgreement.ECM_Agreement_Type__c=contractType.Id;
        paymentAgreement.ECM_Payment_Frequency__c=paymentFrequency.id;
        
        insert paymentAgreement;
        
        //Setting Up Product Record : product to be included in multiple related items
        Product__c product = EDGE_UtilityTestClass.getProd();
        product.Name='JW black Tester';
        product.Country__c=geographyId;
        insert product;
        
        //map rec
        Market_Assortment_Product__c marketassort = new Market_Assortment_Product__c();
        marketassort.Product__c=product.Id;
        marketassort.Market_Assortment__c=geographyId;
        //marketassort.ECM_Strategy__c='2';
        insert marketassort;
        
        
        //pricelist rec
        ECM_Price_List__c priceListRecord = ECM_UtilityTestClass.createPriceList('Vodka',geographyId);
        Insert priceListRecord;
        
        //price list item rec
        //ECM_Price_List_Item__c priceItemRecord = ECM_UtilityTestClass.createPriceListItem(pOption.Id,product.Id,priceListRecord.Id);
        ECM_Price_List_Item__c priceItemRecord = new ECM_Price_List_Item__c();
        priceItemRecord.ECM_Price_List__c  = priceListRecord.Id;
        priceItemRecord.ECM_Product__c = product.Id;
        priceItemRecord.ECM_Base_Price__c = 10;
        priceItemRecord.ECM_Gross_Profit__c = 10;
        priceItemRecord.ECM_LUC_Conversion_Factor__c = 1;
        Insert priceItemRecord;
        
        //contract rec
        Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
        objContract.Status = 'Cancelled';
        objContract.ECM_Territory__c=territory.Id;
        objContract.ECM_Agreement_Type__c=contractType.Id;
        objContract.ECM_Payment_Frequency_Type__c = paymentFrequency.Id;
        objContract.ECM_Select_UoM__c = 'min UoM';
        objContract.StartDate = system.today().addmonths(-1).toStartOfMonth()-3;
        objContract.Contract_End_Date__c = system.today()+360;
        insert objContract;
        
        //contract item rec
        ECM_Contract_Item__c newcontractitem= new ECM_Contract_Item__c();
        newcontractitem.ECM_Contract__c=objContract.Id;
        newcontractitem.ECM_Price_List_ConItem__c = priceItemRecord.id;
        newcontractitem.ECM_Actual_Volume_YTD__c = 5;
        newcontractitem.ECM_Product__c=Marketassort.id;
        insert newcontractitem;
        //contractItemslist.add(newcontractitem)
        
        //payment summary rec       
        ECM_Payment_Summary__c paymemtSummary2 = new ECM_Payment_Summary__c();
        paymemtSummary2.ECM_Payment_Summary_Status__c = 'Approved';
        paymemtSummary2.ECM_Type__c = 'Volume-Based';
        paymemtSummary2.ECM_Contract__c = objContract.id;
        insert paymemtSummary2;
    }
}