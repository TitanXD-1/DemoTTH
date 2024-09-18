/*
* Name: ECM_PaymentSummaryToSAPCalloutTest
* Purpose: This class is used to cover test data for the - ECM_PaymentSummaryToSAPCallout
* History                                                            
* VERSION    AUTHOR         	DATE              DETAIL
1.0		   Anivesh							Initial Development
2.0		 Saurav Prasad  	07/10/2020		Updated - ECM-2878
2.1		 Saurav Prasad  	21/12/2021		ECM-5067 - CLONE - Tech Debt_Work on test CLS to maintain best practice_GLO_Part 2

*/

@isTest
public class ECM_PaymentSummaryToSAPCalloutTest {
    @isTest
    public static void sendDataTest(){
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        Geography__c geoArea = [select Id from Geography__c where Parent_Geography__c =:geographyId LIMIT 1];
        Id uid = userinfo.getUserId();
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        insert acc;
        acc.country__c = geographyId;
        acc.Area__c = geoArea.Id;
        update acc;    
        Account acc1 = EDGE_UtilityTestClass.getDistriAccRec();
        acc1.country__c = geographyId;
        insert acc1;   
        Contact con = new Contact();
        con.LastName = 'My';
        con.FirstName = 'Test';
        con.Email = 'test@abc.com';
        con.AccountId = acc1.id;
        con.Contact_Type__c = 'Primary';
        insert con;
        
        ECM_Contract_Type__c agrmentType = ECM_UtilityTestClass.createContractType(geographyId);
        agrmentType.Volume_UoM_for_Spirits__c='CAS';
        agrmentType.ECM_Volume_UoM_for_Beer__c='EU';
        insert agrmentType;
        
        //retrieve outlet record type for contract
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        //create contract
        Contract contr = EDGE_UtilityTestClass.getContract(acc.Id, contractRecordTypeId);
        contr.Status = 'Draft';
        contr.Contract_End_Date__c = Date.today().addMonths(13).toStartOfMonth().addDays(-1);
        contr.AccountId=acc.Id;
        contr.ECM_Agreement_Type__c=agrmentType.Id;
        contr.recordTypeId=contractRecordTypeId;
        contr.ECM_Channel__c='On-Premise';
        contr.StartDate = Date.today().toStartOfMonth();
        contr.ECM_Duration__c=12;
        contr.Ownerid = uid;
        insert contr;
        contr.Status ='Active';
        update contr;
        
        AccountContactRelation acr = new AccountContactRelation();
        acr.AccountId = acc.id;
        acr.ContactId = con.id;
        acr.Contact_Type__c = 'Primary';
        acr.IsActive = true;
        insert acr;
        
        String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        
        Pick_Up_Options__c budgetTypeObj= ECM_UtilityTestClass.createPickUpOption(geographyId,bannerRecordTypeId);//new Pick_Up_Options__c();
        budgetTypeObj.Name='TI[ES]';
        //budgetTypeObj.ECM_SAP_Order_reason__c = 'Y10'; 
        //budgetTypeObj.ECM_SAP_Pricing_condition__c = 'O25';
        insert budgetTypeObj;
        
        Pick_Up_Options__c budgetTypeObj2= ECM_UtilityTestClass.createPickUpOption(geographyId,Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId());
        budgetTypeObj2.Name='On-Premise[AU]';
        budgetTypeObj2.ECM_SAP_Order_reason__c = 'Y10'; 
        budgetTypeObj2.ECM_SAP_Pricing_condition__c = 'O25';
        insert budgetTypeObj2;
        
        ECM_Payment_Summary__c paymentSummary = new ECM_Payment_Summary__c();
        paymentSummary.ECM_Total_Amount_Confirmed__c = 20.00;
        paymentSummary.ECM_Payment_Summary_Status__c = 'Submitted';
        paymentSummary.ECM_Type__c = 'Promo-Standard';
        paymentSummary.ECM_Invoice_Status__c='Requested';
        paymentSummary.ECM_Contract__c = contr.id;
        paymentSummary.ECM_Start_Period__c = contr.StartDate;
        paymentSummary.ECM_End_Period__c = contr.StartDate.addMonths(3).addDays(-1);
        paymentSummary.ECM_Budget_types__c = budgetTypeObj.id;
        paymentSummary.ECM_Invoice_Status__c ='Approved';
        paymentSummary.ECM_Invoice_Receival_Date__c = paymentSummary.ECM_Start_Period__c.addDays(1);
        //paymentSummary.ownerid = uid;
        ECM_PaymentSummaryTriggerHelper.fiscalYearCalculate(new List<ECM_Payment_Summary__c>{paymentSummary});
        insert paymentSummary;
        
        system.assertEquals(contr.id,paymentSummary.ECM_Contract__c,'Wrong contract assignment');
        
        ECM_Payment_Summary__c paymentSummary2 = new ECM_Payment_Summary__c();
        paymentSummary2.ECM_Total_Amount_Confirmed__c = 20.00;
        paymentSummary2.ECM_Payment_Summary_Status__c = 'Submitted';
        paymentSummary2.ECM_Type__c = 'Volume-Based';
        paymentSummary2.ECM_Invoice_Status__c='Requested';
        paymentSummary2.ECM_Contract__c = contr.id;
        paymentSummary2.ECM_Start_Period__c = system.today();
        paymentSummary2.ECM_End_Period__c = system.today()+2;
        paymentSummary2.ECM_Budget_types__c = budgetTypeObj.id;
        paymentSummary2.ECM_Invoice_Status__c ='Approved';
        //paymentSummary2.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymentSummary2.ECM_SAP_payment_Reference_Number__c=10;
        paymentSummary2.ECM_Email_Sent__c =false;
        //paymentSummary2.ownerid = uid;
        insert paymentSummary2;
        
        ECM_Payment_Summary__c paymentSummary3 = new ECM_Payment_Summary__c();
        paymentSummary3.ECM_Total_Amount_Confirmed__c = 20.00;
        paymentSummary3.ECM_Payment_Summary_Status__c = 'Submitted';
        paymentSummary3.ECM_Type__c = 'Non-Volume';
        paymentSummary3.ECM_Invoice_Status__c='Requested';
        paymentSummary3.ECM_Contract__c = contr.id;
        paymentSummary3.ECM_Start_Period__c = contr.StartDate.addMonths(3);
        paymentSummary3.ECM_End_Period__c = contr.StartDate.addMonths(6).addDays(-1);
        paymentSummary3.ECM_Budget_types__c = budgetTypeObj.id;
        paymentSummary3.ECM_Invoice_Status__c ='Approved';
        paymentSummary3.ECM_Invoice_Receival_Date__c = paymentSummary3.ECM_Start_Period__c.addDays(1);
        paymentSummary3.ECM_SAP_payment_Reference_Number__c=10;
        paymentSummary3.ECM_Email_Sent__c =false;
        ECM_PaymentSummaryTriggerHelper.fiscalYearCalculate(new List<ECM_Payment_Summary__c>{paymentSummary3});
        //paymentSummary3.ownerid = uid;
        insert paymentSummary3;
        
        system.assertEquals(contr.id,paymentSummary3.ECM_Contract__c,'Wrong contract assignment');
        
        Product__c product = ECM_UtilityTestClass.createProduct(geographyId,'ProdTest');  
        product.Product_Full_Name__c='ProdTest';
        insert product;
        
        Product__c product1 = ECM_UtilityTestClass.createProduct(geographyId,'ProdTest1');  
        product1.Product_Full_Name__c='ProdTest1';
        insert product1;
        
        Market_Setting__c mktSetting = EDGE_UtilityTestClass.getMarketSetting(geographyId);
        //mktSetting.ECM_SAP_Order_Type__c = 'Sap';
        mktSetting.ECM_Evidence_email_enabled__c=true;
        mktSetting.ECM_Email_to_Send_Payment_CSV__c = 'TEST@test.com';
        mktSetting.ECM_Payment_Management_Email__c='TEST@test.com';
        mktSetting.ECM_Diageo_Entity_Address_for_Invoicing__c='TEST@test.com';
        insert mktSetting;
        
        Market_Assortment_Product__c marketassort = ECM_UtilityTestClass.createMarketAssortmentProduct(product.id,geographyId);
        //marketassort.ECM_INTO_Material__c = 9;
        insert marketassort;
        
        Market_Assortment_Product__c marketassort1 = ECM_UtilityTestClass.createMarketAssortmentProduct(product1.id,geographyId);
        //marketassort1.ECM_INTO_Material__c = 9;
        insert marketassort1;
        
        ECM_Contract_Item__c newcontractitem= new ECM_Contract_Item__c();
        newcontractitem.ECM_Contract__c=contr.Id;
        newcontractitem.ECM_Product__c=Marketassort.id;
        insert newcontractitem;
        
        ECM_Contract_Item__c newcontractitem1= new ECM_Contract_Item__c();
        newcontractitem1.ECM_Contract__c=contr.Id;
        newcontractitem1.ECM_Product__c=Marketassort1.id;
        insert newcontractitem1;
        
        Test.startTest();
        
        ECM_Payment_Summary_Item__c paymentSummaryItem = new ECM_Payment_Summary_Item__c();
        paymentSummaryItem.ECM_Payment_Summary__c = paymentSummary.id;
        paymentSummaryItem.ECM_Confirm__c = true;
        paymentSummaryItem.ECM_Contract_Item__c = newcontractitem.id;			
        paymentSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
        insert paymentSummaryItem;
        
        ECM_Payment_Summary_Item__c paymentSummaryItem1 = new ECM_Payment_Summary_Item__c();
        paymentSummaryItem1.ECM_Payment_Summary__c = paymentSummary.id;
        paymentSummaryItem1.ECM_Confirm__c = true;
        paymentSummaryItem1.ECM_Contract_Item__c = newcontractitem1.id;			
        paymentSummaryItem1.ECM_Confirmed_Amount_Per_Payment__c =10;
        insert paymentSummaryItem1;
        
        system.assertEquals(paymentSummary.id,paymentSummaryItem.ECM_Payment_Summary__c,'Wrong paymentSummary assignment');
        system.assertEquals(newcontractitem.id,paymentSummaryItem.ECM_Contract_Item__c,'Wrong ContractItem assignment');
        
        ECM_Internal_Order__c internalOrder = new ECM_Internal_Order__c();
        internalOrder.ECM_Product__c = product.id;
        internalOrder.Name = 'Salesforce100';
        internalOrder.ECM_Active__c = true;
        internalOrder.ECM_Description__c = 'ABCD';
        internalOrder.ECM_Budget_Amount__c = 100.00;
        internalOrder.ECM_Start_Date__c = paymentSummary.ECM_Start_Period__c;
        internalOrder.ECM_End_Date__c = paymentSummary.ECM_End_Period__c;
        internalOrder.ECM_Budget_Type_Pickup_Option__c = budgetTypeObj.id;
        internalOrder.ECM_Geography__c = geographyId;
        internalOrder.ECM_Auto_Assignment__c = true;
        insert internalOrder;
        
        ECM_Internal_Order__c internalOrder1 = new ECM_Internal_Order__c();
        internalOrder1.ECM_Product__c = product1.id;
        internalOrder1.Name = 'Salesforce101';
        internalOrder1.ECM_Active__c = true;
        internalOrder1.ECM_Description__c = 'ABCD';
        internalOrder1.ECM_Budget_Amount__c = 100.00;
        internalOrder1.ECM_Start_Date__c = paymentSummary.ECM_Start_Period__c;
        internalOrder1.ECM_End_Date__c = paymentSummary.ECM_End_Period__c;
        internalOrder1.ECM_Budget_Type_Pickup_Option__c = budgetTypeObj.id;
        internalOrder1.ECM_Geography__c = geoArea.Id;
        internalOrder1.ECM_Auto_Assignment__c = true;
        insert internalOrder1;
        
        system.assertEquals(product.id,internalOrder.ECM_Product__c,'Wrong product assignment');
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SalesOrderCreation');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        
        ECM_PaymentSummaryToSAPCallout.getPaymentData(new Set<Id>{paymentSummary.id});
        ECM_PaymentSummaryToSAPCallout.getPaymentDataNonVolume(new Set<Id>{paymentSummary3.id});
        ECM_PaymentSummaryToSAPCallout.sendResponse('',paymentSummaryItem.id);
        ECM_PaymentSummaryToSAPCallout.sendResponse('',paymentSummaryItem1.id);
        Test.stopTest();
    }
    @isTest
    public static void sendDataTest1(){
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        Geography__c country=[select id,ECM_SAP_Plant_for_Payment_File__c from Geography__c where id=:geographyId];
        country.ECM_SAP_Plant_for_Payment_File__c='ES11';
        update country;
        
        Geography__c geoArea = [select Id from Geography__c where Parent_Geography__c =:geographyId LIMIT 1];
        Id uid = userinfo.getUserId();
        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        insert acc;
        acc.country__c = geographyId;
        acc.Area__c = geoArea.Id;
        acc.Sales_Org__c ='sale';
        acc.SAP_Sold_to__c ='sapsold';
        update acc;
        
        Account acc1 = EDGE_UtilityTestClass.getDistriAccRec();
        acc1.country__c = geographyId;
        insert acc1;
        
        Contact con = new Contact();
        con.LastName = 'My';
        con.FirstName = 'Test';
        con.Email = 'test@abc.com';
        con.AccountId = acc1.id;
        con.Contact_Type__c = 'Primary';
        insert con;
        ECM_Contract_Type__c agrmentType = ECM_UtilityTestClass.createContractType(geographyId);
        agrmentType.Volume_UoM_for_Spirits__c='CAS';
        agrmentType.ECM_Volume_UoM_for_Beer__c='EU';
        insert agrmentType;
        
        //retrieve outlet record type for contract
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        //create contract
        Contract contr = EDGE_UtilityTestClass.getContract(acc.Id, contractRecordTypeId);
        contr.Status = 'Draft';
        contr.Contract_End_Date__c = Date.today().addMonths(13).toStartOfMonth().addDays(-1);
        contr.AccountId=acc.Id;
        contr.ECM_Agreement_Type__c=agrmentType.Id;
        contr.recordTypeId=contractRecordTypeId;
        contr.ECM_Channel__c='On-Premise';
        contr.StartDate = Date.today().toStartOfMonth();
        contr.ECM_Duration__c=12;
        contr.Ownerid = uid;
        insert contr;
        contr.Status ='Active';
        update contr;
        
        AccountContactRelation acr = new AccountContactRelation();
        acr.AccountId = acc.id;
        acr.ContactId = con.id;
        acr.Contact_Type__c = 'Primary';
        acr.IsActive = true;
        insert acr;
        
        String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        
        Pick_Up_Options__c budgetTypeObj= ECM_UtilityTestClass.createPickUpOption(geographyId,bannerRecordTypeId);//new Pick_Up_Options__c();
        budgetTypeObj.Name='TI[ES]';
        budgetTypeObj.ECM_SAP_Order_reason__c = 'Y10'; 
        budgetTypeObj.ECM_SAP_Pricing_condition__c = 'O25';
        insert budgetTypeObj;
        
        Pick_Up_Options__c budgetTypeObj2= ECM_UtilityTestClass.createPickUpOption(geographyId,Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId());
        budgetTypeObj2.Name='On-Premise[AU]';
        budgetTypeObj2.ECM_SAP_Order_reason__c = 'Y10'; 
        budgetTypeObj2.ECM_SAP_Pricing_condition__c = 'O25';
        insert budgetTypeObj2;
        
        Pick_Up_Options__c taxCodeObj = ECM_UtilityTestClass.createPickUpOption(geographyId,Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Tax Code').getRecordTypeId());
        taxCodeObj.Name='Reduced Rate -Premise[AU]';
        taxCodeObj.ECM_SAP_Order_reason__c = 'Y10'; 
        taxCodeObj.ECM_SAP_Pricing_condition__c = 'O25';
        taxCodeObj.CST_SAP_Code__c = 'A';
        insert taxCodeObj;
        
        ECM_Payment_Summary__c paymentSummary = new ECM_Payment_Summary__c();
        paymentSummary.ECM_Total_Amount_Confirmed__c = 20.00;
        paymentSummary.ECM_Payment_Summary_Status__c = 'Submitted';
        paymentSummary.ECM_Type__c = 'Promo-Standard';
        paymentSummary.ECM_Invoice_Status__c='Requested';
        paymentSummary.ECM_Contract__c = contr.id;
        paymentSummary.ECM_Start_Period__c = contr.StartDate;
        paymentSummary.ECM_End_Period__c = contr.StartDate.addMonths(3).addDays(-1);
        paymentSummary.ECM_Budget_types__c = budgetTypeObj.id;
        paymentSummary.ECM_Invoice_Status__c ='Approved';
        paymentSummary.ECM_Invoice_Receival_Date__c = paymentSummary.ECM_Start_Period__c.addDays(1);
        paymentSummary.ECM_Tax_Rate__c='Standard Rate';
        paymentSummary.ECM_Recommended_IO_Code__c='MHJ0WACF6900';
        paymentSummary.ECM_Tax_Code__c = taxCodeObj.Id;
        ECM_PaymentSummaryTriggerHelper.fiscalYearCalculate(new List<ECM_Payment_Summary__c>{paymentSummary});
        insert paymentSummary;
        
        system.assertEquals(contr.id,paymentSummary.ECM_Contract__c,'Wrong contract assignment');
        
        ECM_Payment_Summary__c paymentSummary2 = new ECM_Payment_Summary__c();
        paymentSummary2.ECM_Total_Amount_Confirmed__c = 20.00;
        paymentSummary2.ECM_Payment_Summary_Status__c = 'Submitted';
        paymentSummary2.ECM_Type__c = 'Volume-Based';
        paymentSummary2.ECM_Invoice_Status__c='Requested';
        paymentSummary2.ECM_Contract__c = contr.id;
        paymentSummary2.ECM_Start_Period__c = system.today();
        paymentSummary2.ECM_End_Period__c = system.today()+2;
        paymentSummary2.ECM_Budget_types__c = budgetTypeObj.id;
        paymentSummary2.ECM_Invoice_Status__c ='Approved';
        paymentSummary2.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymentSummary2.ECM_SAP_payment_Reference_Number__c=10;
        paymentSummary2.ECM_Email_Sent__c =false;
        paymentSummary2.ECM_Tax_Rate__c='Standard Rate';
        paymentSummary2.ECM_Tax_Code__c = taxCodeObj.Id;
        insert paymentSummary2;
        
        ECM_Payment_Summary__c paymentSummary3 = new ECM_Payment_Summary__c();
        paymentSummary3.ECM_Total_Amount_Confirmed__c = 20.00;
        paymentSummary3.ECM_Payment_Summary_Status__c = 'Submitted';
        paymentSummary3.ECM_Type__c = 'Non-Volume';
        paymentSummary3.ECM_Invoice_Status__c='Requested';
        paymentSummary3.ECM_Contract__c = contr.id;
        paymentSummary3.ECM_Start_Period__c = contr.StartDate.addMonths(3);
        paymentSummary3.ECM_End_Period__c = contr.StartDate.addMonths(6).addDays(-1);
        paymentSummary3.ECM_Budget_types__c = budgetTypeObj.id;
        paymentSummary3.ECM_Invoice_Status__c ='Approved';
        paymentSummary3.ECM_Invoice_Receival_Date__c = paymentSummary3.ECM_Start_Period__c.addDays(1);
        paymentSummary3.ECM_SAP_payment_Reference_Number__c=10;
        paymentSummary3.ECM_Email_Sent__c =false;
        paymentSummary3.ECM_Tax_Rate__c='Standard Rate';
        paymentSummary3.ECM_Recommended_IO_Code__c='MHJ0WACF6900';
        paymentSummary3.ECM_Tax_Code__c = taxCodeObj.Id;
        ECM_PaymentSummaryTriggerHelper.fiscalYearCalculate(new List<ECM_Payment_Summary__c>{paymentSummary3});
        insert paymentSummary3;
        
        system.assertEquals(contr.id,paymentSummary3.ECM_Contract__c,'Wrong contract assignment');
        
        Product__c product = ECM_UtilityTestClass.createProduct(geographyId,'ProdTest');  
        product.Product_Full_Name__c='ProdTest';
        insert product;
        
        Product__c product1 = ECM_UtilityTestClass.createProduct(geographyId,'ProdTest1');  
        product1.Product_Full_Name__c='ProdTest1';
        insert product1;
        
        
        Market_Assortment_Product__c marketassort1 = ECM_UtilityTestClass.createMarketAssortmentProduct(product1.id,geographyId);
        marketassort1.ECM_INTO_Material__c = 9;
        insert marketassort1;
        
        
        Market_Setting__c mktSetting = EDGE_UtilityTestClass.getMarketSetting(geographyId);
        mktSetting.ECM_SAP_Order_Type__c = 'Sap';
        mktSetting.ECM_Evidence_email_enabled__c=true;
        mktSetting.ECM_Email_to_Send_Payment_CSV__c = 'TEST@test.com';
        mktSetting.ECM_Payment_Management_Email__c='TEST@test.com';
        mktSetting.ECM_Diageo_Entity_Address_for_Invoicing__c='TEST@test.com';
        insert mktSetting;
        
        Test.startTest();
        
        Market_Assortment_Product__c marketassort = ECM_UtilityTestClass.createMarketAssortmentProduct(product.id,geographyId);
        marketassort.ECM_INTO_Material__c = 9;
        insert marketassort;
        
        ECM_Contract_Item__c newcontractitem= new ECM_Contract_Item__c();
        newcontractitem.ECM_Contract__c=contr.Id;
        newcontractitem.ECM_Product__c=Marketassort.id;
        insert newcontractitem;
        
        ECM_Contract_Item__c newcontractitem1= new ECM_Contract_Item__c();
        newcontractitem1.ECM_Contract__c=contr.Id;
        newcontractitem1.ECM_Product__c=Marketassort1.id;
        insert newcontractitem1;
        
        ECM_Payment_Summary_Item__c paymentSummaryItem = new ECM_Payment_Summary_Item__c();
        paymentSummaryItem.ECM_Payment_Summary__c = paymentSummary.id;
        paymentSummaryItem.ECM_Confirm__c = true;
        paymentSummaryItem.ECM_Contract_Item__c = newcontractitem.id;			
        paymentSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
        paymentSummaryItem.ECM_Total_Rebate__c=20.20;
        insert paymentSummaryItem;
        
        ECM_Payment_Summary_Item__c paymentSummaryItem1 = new ECM_Payment_Summary_Item__c();
        paymentSummaryItem1.ECM_Payment_Summary__c = paymentSummary.id;
        paymentSummaryItem1.ECM_Confirm__c = true;
        paymentSummaryItem1.ECM_Contract_Item__c = newcontractitem1.id;			
        paymentSummaryItem1.ECM_Confirmed_Amount_Per_Payment__c =10;
        paymentSummaryItem.ECM_Total_Rebate__c=20.20;
        insert paymentSummaryItem1;
        
        system.assertEquals(paymentSummary.id,paymentSummaryItem.ECM_Payment_Summary__c,'Wrong paymentSummary assignment');
        system.assertEquals(newcontractitem.id,paymentSummaryItem.ECM_Contract_Item__c,'Wrong ContractItem assignment');
        
        ECM_Internal_Order__c internalOrder = new ECM_Internal_Order__c();
        internalOrder.ECM_Product__c = product.id;
        internalOrder.ECM_Active__c = true;
        internalOrder.Name = 'Salesforce200';
        internalOrder.ECM_Description__c = 'ABCD';
        internalOrder.ECM_Budget_Amount__c = 100.00;
        internalOrder.ECM_Start_Date__c = paymentSummary.ECM_Start_Period__c;
        internalOrder.ECM_End_Date__c = paymentSummary.ECM_End_Period__c;
        internalOrder.ECM_Budget_Type_Pickup_Option__c = budgetTypeObj.id;
        internalOrder.ECM_Geography__c = geographyId;
        internalOrder.ECM_Auto_Assignment__c = true;
        insert internalOrder;
        
        system.assertEquals(product.id,internalOrder.ECM_Product__c,'Wrong product assignment');
        
        ECM_Internal_Order__c internalOrder1 = new ECM_Internal_Order__c();
        internalOrder1.ECM_Product__c = product1.id;
        internalOrder1.Name = 'Salesforce201';
        internalOrder1.ECM_Active__c = true;
        internalOrder1.ECM_Description__c = 'ABCD';
        internalOrder1.ECM_Budget_Amount__c = 100.00;
        internalOrder1.ECM_Start_Date__c = paymentSummary.ECM_Start_Period__c;
        internalOrder1.ECM_End_Date__c = paymentSummary.ECM_End_Period__c;
        internalOrder1.ECM_Budget_Type_Pickup_Option__c = budgetTypeObj.id;
        internalOrder1.ECM_Geography__c = geoArea.Id;
        internalOrder1.ECM_Auto_Assignment__c = true;
        insert internalOrder1;
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SalesOrderCreation');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        
        ECM_PaymentSummaryToSAPCallout.getPaymentData(new Set<Id>{paymentSummary.id});
        ECM_PaymentSummaryToSAPCallout.getPaymentDataNonVolume(new Set<Id>{paymentSummary3.id});
        ECM_PaymentSummaryToSAPCallout.createLog('Test exception',''+paymentSummary.id, 'jsonPayload', 'Failure','Payment File','Error Occurred for Payment Item Id : '+PaymentSummary.Id);
        ECM_PaymentSummaryToSAPCallout.sendResponse('',paymentSummaryItem.id);
        ECM_PaymentSummaryToSAPCallout.sendResponse('',paymentSummaryItem1.id);
        Test.stopTest();
    }
    @isTest
    public static void sendDataTest2(){
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        Geography__c country=[select id,ECM_SAP_Plant_for_Payment_File__c from Geography__c where id=:geographyId];
        country.ECM_SAP_Plant_for_Payment_File__c='ES11';
        update country;
        
        Geography__c geoArea = [select Id from Geography__c where Parent_Geography__c =:geographyId LIMIT 1];
        Id uid = userinfo.getUserId();
        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        insert acc;
        acc.country__c = geographyId;
        acc.Area__c = geoArea.Id;
        acc.Sales_Org__c ='sale';
        acc.SAP_Sold_to__c ='sapsold';
        update acc;
        
        Account acc1 = EDGE_UtilityTestClass.getDistriAccRec();
        acc1.country__c = geographyId;
        insert acc1;
        
        Contact con = new Contact();
        con.LastName = 'My';
        con.FirstName = 'Test';
        con.Email = 'test@abc.com';
        con.AccountId = acc1.id;
        con.Contact_Type__c = 'Primary';
        insert con;
        ECM_Contract_Type__c agrmentType = ECM_UtilityTestClass.createContractType(geographyId);
        agrmentType.Volume_UoM_for_Spirits__c='CAS';
        agrmentType.ECM_Volume_UoM_for_Beer__c='EU';
        insert agrmentType;
        
        //retrieve outlet record type for contract
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        //create contract
        Contract contr = EDGE_UtilityTestClass.getContract(acc.Id, contractRecordTypeId);
        contr.Status = 'Draft';
        contr.Contract_End_Date__c = Date.today().addMonths(13).toStartOfMonth().addDays(-1);
        contr.AccountId=acc.Id;
        contr.ECM_Agreement_Type__c=agrmentType.Id;
        contr.recordTypeId=contractRecordTypeId;
        contr.ECM_Channel__c='On-Premise';
        contr.StartDate = Date.today().toStartOfMonth();
        contr.ECM_Duration__c=12;
        contr.Ownerid = uid;
        insert contr;
        contr.Status ='Active';
        update contr;
        
        AccountContactRelation acr = new AccountContactRelation();
        acr.AccountId = acc.id;
        acr.ContactId = con.id;
        acr.Contact_Type__c = 'Primary';
        acr.IsActive = true;
        insert acr;
        String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        
        Pick_Up_Options__c budgetTypeObj= ECM_UtilityTestClass.createPickUpOption(geographyId,bannerRecordTypeId);//new Pick_Up_Options__c();
        budgetTypeObj.Name='TI[ES]';
        budgetTypeObj.ECM_SAP_Order_reason__c = 'Y10'; 
        budgetTypeObj.ECM_SAP_Pricing_condition__c = 'O25';
        insert budgetTypeObj;
        
        Pick_Up_Options__c budgetTypeObj2= ECM_UtilityTestClass.createPickUpOption(geographyId,Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId());
        budgetTypeObj2.Name='On-Premise[AU]';
        budgetTypeObj2.ECM_SAP_Order_reason__c = 'Y10'; 
        budgetTypeObj2.ECM_SAP_Pricing_condition__c = 'O25';
        insert budgetTypeObj2;
        
        Pick_Up_Options__c taxCodeObj = ECM_UtilityTestClass.createPickUpOption(geographyId,Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Tax Code').getRecordTypeId());
        taxCodeObj.Name='Reduced Rate -Premise[AU]';
        taxCodeObj.ECM_SAP_Order_reason__c = 'Y10'; 
        taxCodeObj.ECM_SAP_Pricing_condition__c = 'O25';
        taxCodeObj.CST_SAP_Code__c = 'A';
        insert taxCodeObj;
        
        ECM_Payment_Summary__c paymentSummary = new ECM_Payment_Summary__c();
        paymentSummary.ECM_Total_Amount_Confirmed__c = 20.00;
        paymentSummary.ECM_Payment_Summary_Status__c = 'Submitted';
        paymentSummary.ECM_Type__c = 'Promo-Standard';
        paymentSummary.ECM_Invoice_Status__c='Requested';
        paymentSummary.ECM_Contract__c = contr.id;
        paymentSummary.ECM_Start_Period__c = contr.StartDate;
        paymentSummary.ECM_End_Period__c = contr.StartDate.addMonths(3).addDays(-1);
        paymentSummary.ECM_Budget_types__c = budgetTypeObj.id;
        paymentSummary.ECM_Invoice_Status__c ='Approved';
        paymentSummary.ECM_Invoice_Receival_Date__c = paymentSummary.ECM_Start_Period__c.addDays(1);
        paymentSummary.ECM_Tax_Rate__c='Standard Rate';
        paymentSummary.ECM_Recommended_IO_Code__c='MHJ0WACF6900';
        paymentSummary.ECM_Tax_Code__c = taxCodeObj.id;
        ECM_PaymentSummaryTriggerHelper.fiscalYearCalculate(new List<ECM_Payment_Summary__c>{paymentSummary});
        insert paymentSummary;
        
        system.assertEquals(contr.id,paymentSummary.ECM_Contract__c,'Wrong contract assignment');
        
        ECM_Payment_Summary__c paymentSummary2 = new ECM_Payment_Summary__c();
        paymentSummary2.ECM_Total_Amount_Confirmed__c = 20.00;
        paymentSummary2.ECM_Payment_Summary_Status__c = 'Submitted';
        paymentSummary2.ECM_Type__c = 'Volume-Based';
        paymentSummary2.ECM_Invoice_Status__c='Requested';
        paymentSummary2.ECM_Contract__c = contr.id;
        paymentSummary2.ECM_Start_Period__c = system.today();
        paymentSummary2.ECM_End_Period__c = system.today()+2;
        paymentSummary2.ECM_Budget_types__c = budgetTypeObj.id;
        paymentSummary2.ECM_Invoice_Status__c ='Approved';
        paymentSummary2.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymentSummary2.ECM_SAP_payment_Reference_Number__c=10;
        paymentSummary2.ECM_Email_Sent__c =false;
        paymentSummary2.ECM_Tax_Rate__c='Standard Rate';
        insert paymentSummary2;
        
        ECM_Payment_Summary__c paymentSummary3 = new ECM_Payment_Summary__c();
        paymentSummary3.ECM_Total_Amount_Confirmed__c = 20.00;
        paymentSummary3.ECM_Payment_Summary_Status__c = 'Submitted';
        paymentSummary3.ECM_Type__c = 'Non-Volume';
        paymentSummary3.ECM_Invoice_Status__c='Requested';
        paymentSummary3.ECM_Contract__c = contr.id;
        paymentSummary3.ECM_Start_Period__c = contr.StartDate.addMonths(3);
        paymentSummary3.ECM_End_Period__c = contr.StartDate.addMonths(6).addDays(-1);
        paymentSummary3.ECM_Budget_types__c = budgetTypeObj.id;
        paymentSummary3.ECM_Invoice_Status__c ='Approved';
        paymentSummary3.ECM_Invoice_Receival_Date__c = paymentSummary3.ECM_Start_Period__c.addDays(1);
        paymentSummary3.ECM_SAP_payment_Reference_Number__c=10;
        paymentSummary3.ECM_Email_Sent__c =false;
        paymentSummary3.ECM_Tax_Rate__c='Standard Rate';
        paymentSummary3.ECM_Recommended_IO_Code__c='MHJ0WACF6900';
        ECM_PaymentSummaryTriggerHelper.fiscalYearCalculate(new List<ECM_Payment_Summary__c>{paymentSummary3});
        insert paymentSummary3;
        
        system.assertEquals(contr.id,paymentSummary3.ECM_Contract__c,'Wrong contract assignment');
        
        Product__c product = ECM_UtilityTestClass.createProduct(geographyId,'ProdTest');  
        product.Product_Full_Name__c='ProdTest';
        insert product;
        
        Market_Setting__c mktSetting = EDGE_UtilityTestClass.getMarketSetting(geographyId);
        mktSetting.ECM_SAP_Order_Type__c = 'Sap';
        mktSetting.ECM_Evidence_email_enabled__c=true;
        mktSetting.ECM_Email_to_Send_Payment_CSV__c = 'TEST@test.com';
        mktSetting.ECM_Payment_Management_Email__c='TEST@test.com';
        mktSetting.ECM_Diageo_Entity_Address_for_Invoicing__c='TEST@test.com';
        insert mktSetting;
        
        Test.startTest();
        
        Market_Assortment_Product__c marketassort = ECM_UtilityTestClass.createMarketAssortmentProduct(product.id,geographyId);
        marketassort.ECM_INTO_Material__c = 9;
        insert marketassort;
        
        ECM_Contract_Item__c newcontractitem= new ECM_Contract_Item__c();
        newcontractitem.ECM_Contract__c=contr.Id;
        newcontractitem.ECM_Product__c=Marketassort.id;
        insert newcontractitem;
        
        ECM_Payment_Summary_Item__c paymentSummaryItem = new ECM_Payment_Summary_Item__c();
        paymentSummaryItem.ECM_Payment_Summary__c = paymentSummary.id;
        paymentSummaryItem.ECM_Confirm__c = true;
        paymentSummaryItem.ECM_Contract_Item__c = newcontractitem.id;			
        paymentSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
        paymentSummaryItem.ECM_Total_Rebate__c=20.20;
        insert paymentSummaryItem;
        
        system.assertEquals(paymentSummary.id,paymentSummaryItem.ECM_Payment_Summary__c,'Wrong paymentSummary assignment');
        system.assertEquals(newcontractitem.id,paymentSummaryItem.ECM_Contract_Item__c,'Wrong ContractItem assignment');
        
        ECM_Internal_Order__c internalOrder = new ECM_Internal_Order__c();
        internalOrder.ECM_Product__c = product.id;
        internalOrder.ECM_Active__c = true;
        internalOrder.Name = 'Salesforce300';
        internalOrder.ECM_Description__c = 'ABCD';
        internalOrder.ECM_Budget_Amount__c = 100.00;
        internalOrder.ECM_Start_Date__c = paymentSummary.ECM_Start_Period__c;
        internalOrder.ECM_End_Date__c = paymentSummary.ECM_End_Period__c;
        internalOrder.ECM_Budget_Type_Pickup_Option__c = budgetTypeObj.id;
        internalOrder.ECM_Geography__c = geographyId;
        internalOrder.ECM_Auto_Assignment__c = true;
        internalOrder.ECM_Fiscal_Year__c=paymentSummary.ECM_Fiscal_Years__c.split('/')[0];
        insert internalOrder;
        
        system.assertEquals(product.id,internalOrder.ECM_Product__c,'Wrong product assignment');
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SalesOrderCreationError');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        
        ECM_PaymentSummaryToSAPCallout.getPaymentData(new Set<Id>{paymentSummary.id});
        ECM_PaymentSummaryToSAPCallout.getPaymentDataNonVolume(new Set<Id>{paymentSummary3.id});
        ECM_PaymentSummaryToSAPCallout.createLog('Test exception',''+paymentSummary.id, 'jsonPayload', 'Failure','Payment File','Error Occurred for Payment Item Id : '+paymentSummary.Id);
        Test.stopTest();
    }
}