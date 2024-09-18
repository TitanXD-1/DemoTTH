@isTest
private class ECM_RollOverPaymentSummaryHelperTest {
    @isTest
    private static void createDataES1(){
        //Setting up required record types      
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');        
        system.assert(geographyId!= null,'geographyId should not be null');
        Id contrRecTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        User cioUser = ECM_UtilityTestClass.createUser('cio',ECM_UtilityTestClass.getProfile('CIO User').Id);
        cioUser.Username = 'cioUser1234@test.com';
        insert cioUser;
        
        //Setting up a sales rep user to run test as
        User salesRep = ECM_UtilityTestClass.createUser('srp',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
        salesRep.Username = 'salesRp1234@test.com';
        salesRep.isActive=true;
        salesRep.DelegatedApproverId=cioUser.id;
        insert salesRep;
        
        Pick_Up_Options__c pOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pOption.Name='LI[ES]';
        insert pOption;
        
        //Setting up mandatory contract field records
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.country__c = geographyId;
        acc.Sales_Org__c ='sale';
        acc.SAP_Sold_to__c ='sapsold';
        acc.Outlet_Visit_Prioritisation_Grade__c = pOption.Id;  
        insert acc;
        
        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        contractType.ECM_Prepayment_SR_approval__c=False;
        contractType.CurrencyIsoCode = 'EUR';
        insert contractType;

        ECM_Payment_Frequency__c paymfreq = ECM_UtilityTestClass.getPayFre(geographyId);
        paymfreq.ECM_Type__c = system.label.ECM_PaymentByActivation;
        insert paymfreq;

        //Setting up contract to link with payment summary
        Contract contr = ECM_UtilityTestClass.createContract(acc.id,contrRecTypeId);        
        contr.ECM_Agreement_Type__c = contractType.Id;
        contr.ownerId = salesRep.Id;
        contr.ECM_Payment_Frequency_Type__c = paymfreq.Id;
        //contr.Status = system.label.ECM_ContractApprovedStatus;
        insert contr;
        
        //Setting up contract items to create payment summary item
        Product__c product = ECM_UtilityTestClass.createProduct(geographyId,'Test');
        product.Product_Full_Name__c='Test';
        insert product;        
        Market_Assortment_Product__c mapRec = ECM_UtilityTestClass.createMarketAssortmentProduct(product.Id,geographyId);
        mapRec.ECM_INTO_Material__c = 9;
        insert mapRec;  
        ECM_Contract_Item__c ciRec = ECM_UtilityTestClass.createcontractitem(contr.Id,mapRec.id);
        ciRec.ECM_Actual_Volume_YTD__c = 20;
        ciRec.ECM_Net_Net_List_Price__c = 10;
        ciRec.ECM_UoM__c='5';
        insert ciRec;
        
        Product__c product1 = ECM_UtilityTestClass.createProduct(geographyId,'Test1');
        product1.Product_Full_Name__c='Test1';
        insert product1;        
        Market_Assortment_Product__c mapRec1 = ECM_UtilityTestClass.createMarketAssortmentProduct(product1.Id,geographyId);
        mapRec1.ECM_INTO_Material__c = 9;
        insert mapRec1;  
        ECM_Contract_Item__c ciRec1 = ECM_UtilityTestClass.createcontractitem(contr.Id,mapRec1.id);
        ciRec1.ECM_Actual_Volume_YTD__c = 20;
        ciRec1.ECM_Net_Net_List_Price__c = 10;
        ciRec1.ECM_UoM__c='5';
        insert ciRec1;
        
        String budgetTypeRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        String taxCodeRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Tax Code').getRecordTypeId();
        
        Pick_Up_Options__c budgetTypeObj1= new Pick_Up_Options__c();
        budgetTypeObj1.Name='TI[ES]';
        budgetTypeObj1.Geography__c=geographyId;
        budgetTypeObj1.RecordTypeId=budgetTypeRecordTypeId;
        insert budgetTypeObj1;
        
        Pick_Up_Options__c budgetTypeObj2= new Pick_Up_Options__c();
        budgetTypeObj2.Name='A&P[ES]';
        budgetTypeObj2.Geography__c=geographyId;
        budgetTypeObj2.RecordTypeId=budgetTypeRecordTypeId;
        insert budgetTypeObj2;
        
        Pick_Up_Options__c taxCode= new Pick_Up_Options__c();
        taxCode.Name = 'No Tax[ES]';
        taxCode.Geography__c=geographyId;
        taxCode.RecordTypeId=taxCodeRecordTypeId;
        insert taxCode;
        
        Pick_Up_Options__c taxCode1= new Pick_Up_Options__c();
        taxCode1.Name = 'Reduced Tax[ES]';
        taxCode1.Geography__c=geographyId;
        taxCode1.RecordTypeId=taxCodeRecordTypeId;
        insert taxCode1;
        
        //Setting up Payment Summary
        Date myDate = Date.newInstance(2020, 5, 17);
        Date myDate1 = Date.newInstance(2020, 9, 17);
        Date myDate2 = Date.newInstance(2021, 9, 17);
        
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = true;
        insert orgSetting;
        
        contr.Status = Label.ECM_ContractApprovedStatus;
        update contr;  
        
        ECM_Payment_Summary__c paymemtSummary = ECM_UtilityTestClass.getPaymentSummary(contr.id);
        paymemtSummary.ECM_Start_Period__c = myDate1;
        paymemtSummary.ECM_End_Period__c = myDate2;
        paymemtSummary.ECM_Type__c = 'Promo-Standard';
        paymemtSummary.ECM_Invoice_Status__c='Approved';
        paymemtSummary.ECM_Tax_Rate__c='Standard Rate';
        paymemtSummary.ECM_Tax_Code__c=taxCode.Id;
        paymemtSummary.ECM_Invoice_Receival_Date__c = myDate;
        paymemtSummary.ECM_Total_to_be_Invoiced__c = 10;
        paymemtSummary.ECM_UoS_Total__c = 20;
        paymemtSummary.CurrencyIsoCode = 'GBP';
        paymemtSummary.ECM_No_Invoice_Required__c = TRUE;
        paymemtSummary.ECM_Budget_types__c=budgetTypeObj1.Id;
        paymemtSummary.ECM_Total_Amount_Confirmed__c = 200;
        paymemtSummary.ECM_Total_Amount_Forecasted__c = 400;
        paymemtSummary.ECM_Payment_Frequency__c = paymfreq.Id;
        
        insert paymemtSummary;
        
        //Setting up payment summary item
        ECM_Payment_Summary_Item__c paymemtSummaryItem2 = ECM_UtilityTestClass.getPaymentSummaryItem(PaymemtSummary.id,ciRec.id);
        paymemtSummaryItem2.ECM_Confirmed_Amount_Per_Payment__c = 20;
        paymemtSummaryItem2.ECM_Planned_Amount_Per_Payment__c = 60;
        paymemtSummaryItem2.ECM_To_Pay__c=true;
        paymemtSummaryItem2.ECM_Roll_Over__c =true;
        insert paymemtSummaryItem2;
        
        ECM_Payment_Summary_Item__c paymemtSummaryItem3 = ECM_UtilityTestClass.getPaymentSummaryItem(PaymemtSummary.id,ciRec.id);
        paymemtSummaryItem3.ECM_Confirmed_Amount_Per_Payment__c = 20;
        paymemtSummaryItem3.ECM_Planned_Amount_Per_Payment__c = 60;
        paymemtSummaryItem3.ECM_To_Pay__c =true;
        paymemtSummaryItem3.ECM_Roll_Over__c =true;
        paymemtSummaryItem3.ECM_Confirm__c =true;
        insert paymemtSummaryItem3;

        map<id,ECM_Payment_Summary__c> newMap = new map<id,ECM_Payment_Summary__c>();
        newMap.put(PaymemtSummary.Id,PaymemtSummary);
        map<id,ECM_Payment_Summary__c> oldMap = new map<id,ECM_Payment_Summary__c>();

        PaymemtSummary.ECM_Payment_Summary_Status__c = 'Submitted';
        PaymemtSummary.ECM_Approval_Sub_Status__c=Label.ECM_CIO_Approval;
        update PaymemtSummary;

        oldMap.put(PaymemtSummary.Id, PaymemtSummary);

        Test.startTest();
        PaymemtSummary.ECM_Payment_Summary_Status__c = 'Approved';
        PaymemtSummary.ECM_Approval_Sub_Status__c='';
        update PaymemtSummary;
        Test.stopTest();
    }
}