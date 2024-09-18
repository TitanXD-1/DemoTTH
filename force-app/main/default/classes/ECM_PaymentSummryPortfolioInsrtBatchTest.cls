/*
*@Name: ECM_PaymentSummryPortfolioInsrtBatchTest
*@Purpose: This Class is used to schedule ECM_PaymentSummaryPortfolioInsertBatch based on the Rebate calender.
*@History                                                            
*                                                   
*VERSION		AUTHOR					DATE				DETAIL
*1.0		Anivesh Muppa			05/02/2021			Initial Development
*2.0		Saurav Prasad			10/07/2023			142555	:	CM static code violation for the classes_SFDC_Technical Debt
*
*/
@isTest 
public class ECM_PaymentSummryPortfolioInsrtBatchTest {
	 @isTest
    public static void testPaymentBatch(){
      
        createData();

        try{ 
            Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                      Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'ECM_PaymentSummaryPortfolioInsertBatch'
                                                      and Country_Code__c ='AU' ];
            Assert.areNotEqual(null, batchSetting, 'batchSetting should not be null');
            System.assertNotEquals(null, batchSetting, 'batchSetting should not be null');
           // List<Promotion__c> promList = [Select id , name from Promotion__c];
          //  System.assert(promList.size()!=null);
            
            String className = batchSetting.Batch_Class__c;
            Type t = Type.forName(className);
            //Test.startTest();
            BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
            job.getBatchDetails(batchSetting);
            Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
           // Test.stopTest();
           // system.debug('++'+[Select Id from ECM_Payment_Summary_Item__c].size());
         }catch(Exception ex){
          System.debug(LoggingLevel.DEBUG,'Exception Caught at Line: '+Ex.getLineNumber()+'\n Error: '+Ex.getMessage());
        }
    }
    
 /*
*Method  : createData
*Purpose : To create test data
*/   
    static void createData(){
          
        Id uid = userinfo.getUserId();
        Date myDate1 = Date.newInstance(2020, 5, 17); //NOPMD
       //  Profile prof = [select id from profile where name=: 'Sales Representative'];
        User usr = new User();
         usr.firstName = 'test1';
       // usr.lastName = 'test2';
       // usr.profileId = prof.id;        
        usr.email = 'test@test.com';
        usr.Username ='testcm123@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='ES';
        usr.Title='Legal';
        usr.ManagerId = uid;
       // insert usr;
        //Creating Org setting
        //EDGE_UtilityTestClass.createOrgSettings();
        
        Id countryId1 = EDGE_UtilityTestClass.setupCountry('AU');
        
        Geography__c country = [SELECT Id, Code__c, Parent_Geography__c FROM Geography__c WHERE Id = :countryId1];
        Geography__c secCountry = EDGE_UtilityTestClass.createGeography('Country');
        secCountry.Name = 'Australia Country1';
        secCountry.Code__c = 'AU1';
        secCountry.Extended_Country_Code__c = 'AU-AU1';
        secCountry.Parent_Geography__c = country.Parent_Geography__c;
        insert secCountry;

        string strValue = '2023';
        ECM_Rebates_Calendar__mdt rebateCalendarMap = [SELECT ECM_Rebate_Calculation_Date__c, ECM_Rebate_Period_Start__c, ECM_Rebate_Period_End__c,
                                                       ECM_Region__c, ECM_Financial_Year__c, ECM_Quarter__c, Id FROM ECM_Rebates_Calendar__mdt
                                                       Where ECM_Financial_Year__c =: strValue 
                                                       Limit 1];
      
        Id countryId = secCountry.Id;
        //Creating Pickup Option Record 
        String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        List<Pick_Up_Options__c> lstPick = new List<Pick_Up_Options__c>();
        Pick_Up_Options__c banner= new Pick_Up_Options__c();
        banner.Name='Range[AU]';
        banner.Geography__c=countryId1;
        banner.RecordTypeId=BannerRecordTypeId;
        lstPick.add(banner);
        
        String bannerRecordTypeId1 = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();  
        
        Pick_Up_Options__c budgetTypeObj1= new Pick_Up_Options__c();
        budgetTypeObj1.Name = 'Portfolio Rebates [AU]';
        budgetTypeObj1.Geography__c = countryId1;
        budgetTypeObj1.RecordTypeId = BannerRecordTypeId1;
        budgetTypeObj1.ECM_SAP_Order_reason__c = 'Y10'; 
        budgetTypeObj1.ECM_SAP_Pricing_condition__c = 'O25';
        budgetTypeObj1.Status__c = 'Active';
        lstPick.add(budgetTypeObj1);
        
        Pick_Up_Options__c budgetTypeObj2= new Pick_Up_Options__c();
        budgetTypeObj2.Name='On-Premise[AU1]';
        budgetTypeObj2.Geography__c=secCountry.Id;
        budgetTypeObj2.RecordTypeId=Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        budgetTypeObj2.ECM_SAP_Order_reason__c = 'Y10'; 
        budgetTypeObj2.ECM_SAP_Pricing_condition__c = 'O25';
        lstPick.add(budgetTypeObj2);
        
        Pick_Up_Options__c  pickUpOption1= EDGE_UtilityTestClass.getPickUpOption(countryId1,'Outlet Visit Prioritization');
        pickUpOption1.Name = 'Outlet Visit Prioritization [AU]';
        lstPick.add(pickUpOption1);
        insert lstPick;
       
        List<Account> lstAcc = new List<Account>();
        /*Account acc1 = EDGE_UtilityTestClass.getOutletRecord();
        acc1.country__c = countryId1;
        acc1.Outlet_Visit_Prioritisation_Grade__c = pickUpOption1.Id;
        //acc1.country__c = secCountry.Id;
        acc1.Sales_Org__c ='sale';
        acc1.SAP_Sold_to__c ='sapsold';        
        lstAcc.add(acc1);*/
        
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
       // outletAccount.Person_Responsible__c= usr.Id;
        //outletAccount.OwnerId = usr.Id;
        outletAccount.country__c = countryId1;
        outletAccount.Sales_Org__c ='salesOrg';
        outletAccount.Outlet_Visit_Prioritisation_Grade__c = pickUpOption1.Id;
        outletAccount.SAP_Sold_to__c ='sapsoldoutlet';
        //outletAccount.Operator__c=contractType.id;
        lstAcc.add(outletAccount);
        test.startTest();
        insert lstAcc;
        
        Id bUrectype = Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Business Unit').getRecordTypeId();   
        Territory_Hierarchy__c terriheirarchyIB =New Territory_Hierarchy__c();
        terriheirarchyIB.Name='Iberia';
        terriheirarchyIB.Geography__c=countryId1;
        terriheirarchyIB.RecordTypeId=BUrectype;
        insert terriheirarchyIB;
        
        Id salesarearectype = Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Sales Area').getRecordTypeId();   
        Territory_Hierarchy__c terriheirarchySA =New Territory_Hierarchy__c();
        terriheirarchySA.Name='IBSalesArea';
        terriheirarchySA.Geography__c=countryId1;
        terriheirarchySA.RecordTypeId=Salesarearectype;
        terriheirarchySA.Parent_BU__c= terriheirarchyIB.Id;
        insert terriheirarchySA;
        
        Id regioinrecType = Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Region').getRecordTypeId();   
        Territory_Hierarchy__c terriheirarchyregion =New Territory_Hierarchy__c();
        terriheirarchyregion.Name='Sales region';
        terriheirarchyregion.Geography__c=countryId1;
        terriheirarchyregion.RecordTypeId=regioinrecType;
        terriheirarchyregion.Parent_BU__c= terriheirarchySA.Id;
        insert terriheirarchyregion;
        
        Territory__c testterritory=New Territory__c();
        testterritory.Name='Testterriotory';
        testterritory.Territory_Type__c='Sales';
        testterritory.Country__c= countryId;
        testterritory.Status__c='Active';
        testterritory.Region__c= terriheirarchyregion.Id;
        testterritory.Sales_Area__c= terriheirarchySA.Id;
        testterritory.Business_Unit__c=terriheirarchyIB.Id;        
        testterritory.Primary_Sales_Rep__c = usr.id;
        insert testterritory;
        
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=countryId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;Category;Volume Target;Rate Per UoM;Investment;Product Growth Strategy;UoM;';
       // contractType.Volume_UoM_for_Spirits__c='BTL';
        insert contractType;
       
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Contract objContract = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract.Status = 'Draft';
        objContract.Contract_End_Date__c = System.today()+29;
        objContract.AccountId=outletAccount.Id;
        objContract.ECM_Territory__c=testterritory.Id;
        objContract.ECM_Overall_Investment_Amount__c=100020.55;
        objContract.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c=12000934.32;
        objContract.ECM_Hybrid_CustInvest_Total_PercentGP__c=243123.33;
        objContract.ECM_Overall_Investment_Figure__c=122.43;
        //objContract.ECM_Contract_Type__c=contractType.Id;
        objContract.ECM_Agreement_Type__c=contractType.Id;
        objContract.recordTypeId=contractRecordTypeId;
        objContract.ECM_Channel__c='On-Premise';
        objContract.ECM_Banner__c=banner.Id;
        objContract.StartDate = system.today();
        objContract.Contract_End_Date__c = system.today()+360;
        insert objContract;
        objContract.Status = 'Active';
        update objContract;
        
        Product__c product1 = new Product__c();
        product1.Name='Test';
        product1.Product_Full_Name__c='Test';
        product1.Country__c=countryId;
        insert product1;
        
        Depletions__c dep = new Depletions__c();
        dep.ECM_Volume__c = 100.00;
        dep.ECM_Outlet__c = outletAccount.id;
        dep.ECM_Start_Period__c = rebateCalendarMap.ECM_Rebate_Period_Start__c.addDays(4);
        dep.ECM_End_Period__c = rebateCalendarMap.ECM_Rebate_Period_End__c.addDays(-6);
        dep.ECM_Product__c = product1.id;
        dep.ECM_Outlet__c = outletAccount.Id;
        insert dep;
        
         test.stopTest();
        
        
       /* List<BusinessHours> bHourList1 = [select id from BusinessHours];
        Market_Setting__c mktSetting1 = new Market_Setting__c();
        mktSetting1.Name = 'Market Setting';
        mktSetting1.Geography__c = countryId;
        mktSetting1.Business_Hours__c = bHourList1[0].Id;
        mktSetting1.Minimum_Product_Assortment__c = 'Binary';
        mktSetting1.Minimum_Activation_Standards__c = 'Binary';
        mktSetting1.Distribution__c = 'Binary';
        mktSetting1.New_Product_Distribution__c = 'Progressive';
        mktSetting1.Open_Opportunity__c = 'Calculative';
        mktSetting1.Closed_Opportunity__c = 'Calculative';
        mktSetting1.Outlet_Execution_Score__c = 'Calculative';
       // mktSetting1.A_P_Threshold__c=10;
        mktSetting1.ECM_Email_to_Send_Payment_CSV__c='test@test.com';
        mktSetting1.Prospect_Approver__c = 'Sales Manager & MDM Approval Required' ;
        mktSetting1.ECM_SAP_Order_Type__c = 'Sap';
        mktSetting1.ECM_Evidence_email_enabled__c=true;
        mktSetting1.ECM_Payment_Evidence_Pre_Payment_SP__c='ECM_PaymentSummaryEvidenceRequestPrePySP';
        mktSetting1.ECM_Payment_Evidence_Pre_Payment__c='ECM_PaymentSummaryEvidenceRequestPrePay';
        mktSetting1.ECM_Payment_Evidence_template__c='ECM_PaymentSummaryEvidenceRequestStd';
        mktSetting1.ECM_Payment_Evidence_SP_template__c='ECM_PaymentSummaryEvidenceRequestStdSP';
        mktSetting1.ECM_Payment_Invoice_SP_template__c='ECM_PaymentSummaryInvoiceRequestSP';
        mktSetting1.ECM_Payment_Invoice_template__c='ECM_PaymentSummaryInvoiceRequest';        
        insert mktSetting1;*/
        
        Market_Assortment_Product__c marketassort1 = new Market_Assortment_Product__c();
        Marketassort1.Product__c=product1.Id;
        Marketassort1.Market_Assortment__c=countryId;
        Marketassort1.ECM_INTO_Material__c = 9;
        insert Marketassort1;
        
        ECM_Contract_Item__c newcontractitem1= new ECM_Contract_Item__c();
        newcontractitem1.ECM_Contract__c=objContract.Id;
        newcontractitem1.ECM_Product__c=Marketassort1.id;
        insert newcontractitem1;
        
        Outlet_Contract__c outlet = new Outlet_Contract__c();
        outlet.Outlet__c = objContract.AccountId;
        outlet.Contract__c=objContract.Id;
        insert outlet;
    }
}