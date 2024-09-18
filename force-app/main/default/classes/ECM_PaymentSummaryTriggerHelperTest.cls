@isTest
public class ECM_PaymentSummaryTriggerHelperTest {
     @isTest
    public static void createDataforExtraApp(){
        //Setting up required record types      
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('GB');
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
        contractType.C360_PS_Approval_Initial_vs_Actual__c = 'Product Level';
        insert contractType;

        ECM_Payment_Frequency__c paymfreq = ECM_UtilityTestClass.getPayFre(geographyId);
        paymfreq.ECM_Type__c = '100% Prepayment';
        insert paymfreq;

        //Setting up contract to link with payment summary
        Contract contr = ECM_UtilityTestClass.createContract(acc.id,contrRecTypeId);        
        contr.ECM_Agreement_Type__c = contractType.Id;
        contr.ownerId = salesRep.Id;
        contr.ECM_Payment_Frequency_Type__c = paymfreq.Id;
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
        ciRec.ECM_Volume_Target_per_PF__c = 40;
        insert ciRec;
        
        String budgetTypeRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        String taxCodeRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Tax Code').getRecordTypeId();
        
        Pick_Up_Options__c budgetTypeObj1= new Pick_Up_Options__c();
        budgetTypeObj1.Name='TI[ES]';
        budgetTypeObj1.Geography__c=geographyId;
        budgetTypeObj1.RecordTypeId=budgetTypeRecordTypeId;
        insert budgetTypeObj1;

        Pick_Up_Options__c taxCode= new Pick_Up_Options__c();
        taxCode.Name = 'No Tax[ES]';
        taxCode.Geography__c=geographyId;
        taxCode.RecordTypeId=taxCodeRecordTypeId;
        insert taxCode;

        //Setting up Payment Summary
        Date myDate = Date.newInstance(2020, 5, 17);
        Date myDate1 = Date.newInstance(2020, 8, 17);
        
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = true;
        insert orgSetting;
        Test.startTest();

        ECM_Payment_Summary__c paymentSummary1 = ECM_UtilityTestClass.getPaymentSummary(contr.id);
        paymentSummary1.ECM_Total_Amount_Confirmed__c = 40.00;
        paymentSummary1.ECM_Payment_Summary_Status__c = 'Open';
        paymentSummary1.ECM_Start_Period__c = myDate;
        paymentSummary1.ECM_End_Period__c = myDate1;
        paymentSummary1.ECM_Type__c = 'Volume-Based';
        paymentSummary1.ECM_Invoice_Status__c='Approved';
        paymentSummary1.ECM_Tax_Rate__c='Standard Rate';
        paymentSummary1.ECM_Tax_Code__c=taxCode.Id;
        paymentSummary1.ECM_Budget_types__c=budgetTypeObj1.Id;
        insert paymentSummary1;
        
        ECM_Payment_Summary_Item__c paymemtSummaryItem2 = ECM_UtilityTestClass.getPaymentSummaryItem(paymentSummary1.id,ciRec.id);
        paymemtSummaryItem2.ECM_Confirmed_Amount_Per_Payment__c = 20;
        paymemtSummaryItem2.ECM_Confirmed_Volume__c=50;
        paymemtSummaryItem2.ECM_To_Pay__c=true;
        insert paymemtSummaryItem2;

        
        
        ECM_Extra_Approval__c ecmEX1 = new ECM_Extra_Approval__c();
        ecmEX1.ECM_Approver_Position_Name__c = 'Test Approver';
        ecmEX1.ECM_Active__c = true;
        ecmEX1.ecm_type__c = 'Volume Based PS-Target';
        ecmEX1.ECM_Approver_s_Email_Address__c = 'testEX1@diageo.com';
        ecmEX1.ECM_Lower_Limit_Amount__c = 1;
        ecmEX1.ECM_Upper_Limit_Amount__c = 200;
        ecmEX1.ECM_Re_Investment_Rate_Lower_Limit__c = 10;
        ecmEX1.ECM_Re_Investment_Rate_Upper_Limit__c = 20;
        ecmEX1.ECM_Enable_Delegation__c = true;
        ecmEX1.ECM_Delegated_Approver_Email_Address__c ='Test2@diageo.com';
        ecmEX1.ECM_Extra_Approval_User__c = salesRep.Id;
        insert ecmEX1;
        
        ECM_Extra_Approval__c ecmEX2 = new ECM_Extra_Approval__c();
        ecmEX2.ECM_Approver_Position_Name__c = 'Test Approver';
        ecmEX2.ECM_Active__c = true;
        ecmEX2.ecm_type__c = label.C360_Volume_Based_PS_Initial_vs_Actual;
        ecmEX2.ECM_Approver_s_Email_Address__c = 'testEX1@diageo.com';
        ecmEX2.ECM_Enable_Delegation__c = true;
        ecmEX2.ECM_Delegated_Approver_Email_Address__c ='Test2@diageo.com';
        ecmEX2.ECM_Extra_Approval_User__c = salesRep.Id;
        insert ecmEX2;
        
        ECM_Extra_Approval__c ecmEX3 = new ECM_Extra_Approval__c();
        ecmEX3.ECM_Approver_Position_Name__c = 'Test Approver';
        ecmEX3.ECM_Active__c = true;
        ecmEX3.ecm_type__c = label.C360_Volume_Based_PS_Initial_vs_Actual;
        ecmEX3.ECM_Approver_s_Email_Address__c = 'testEX1@diageo.com';
        ecmEX3.ECM_Enable_Delegation__c = true;
        ecmEX3.ECM_Delegated_Approver_Email_Address__c ='Test2@diageo.com';
        ecmEX3.ECM_Extra_Approval_User__c = salesRep.Id;
        insert ecmEX3;
        
        
        ECM_Agreement_Approval__c agrementApproval  = new ECM_Agreement_Approval__c();
        agrementApproval.ECM_Agreement_Type__c = contractType.Id;
        agrementApproval.ECM_Extra_Approval__c = ecmEX1.Id;
        
        ECM_Agreement_Approval__c agrementApproval1  = new ECM_Agreement_Approval__c();
        agrementApproval1.ECM_Agreement_Type__c = contractType.Id;
        agrementApproval1.ECM_Extra_Approval__c = ecmEX2.Id;
        
        ECM_Agreement_Approval__c agrementApproval2  = new ECM_Agreement_Approval__c();
        agrementApproval2.ECM_Agreement_Type__c = contractType.Id;
        agrementApproval2.ECM_Extra_Approval__c = ecmEX2.Id;


        agrementApproval.CurrencyIsoCode = 'GBP';
        insert agrementApproval;
        insert agrementApproval1;
        insert agrementApproval2;
		
        paymentSummary1.ECM_Approval_Sub_Status__c=label.ECM_In_Extra_Approval;
        update paymentSummary1;
        paymentSummary1.ECM_Approval_Sub_Status__c=label.C360_Extra_Approval_Initial_vs_Actual;
        update paymentSummary1;
        
        
         ECM_Payment_Summary__c paymentSummaryRecord = new ECM_Payment_Summary__c();
         paymentSummaryRecord = [Select Id, Name, ECM_Payment_Summary_Status__c,ECM_Contract_Agreement_Type__c,ECM_Contract_Account_Id__c,ECM_Start_Period__c,ECM_End_Period__c,ECM_Contract__r.Status,ECM_Contract__r.Contract_End_Date__c,ECM_Contract__r.StartDate,ECM_Contract__r.Account.Country__c,ECM_Contract__r.RecordTypeId, ECM_Total_to_be_Invoiced__c,ECM_No_Invoice_Required__c, 
                                    ECM_Total_Amount_Forecasted__c, ECM_Total_Amount_Confirmed__c, ECM_Invoice_Receival_Date__c,ECM_Contract__r.Account.SAP_Sold_to__c,ECM_Contract__r.ECM_Agreement_Type__c,ECM_Contract__r.ECM_Territory__c, ECM_UoS_Total__c,ECM_Contract__r.Account.parent_outlet__c,
                                    ECM_Invoice_Status__c, ECM_SAP_Credit_Note_Number__c, ECM_SAP_Credit_Note_Creation_Date__c, ECM_SAP_Billing_Doc_Number__c, ECM_Contract__r.UOS_Rebate_Rate__c,ECM_Contract__r.ECM_Upfront_Pre_payment_amount__c, ECM_Contract__r.ECM_Upfront_Annual_Payment_Amount__c,  ECM_SAP_Billing_Doc_Date__c, 
                                    ECM_SAP_payment_Reference_Number__c, ECM_SAP_Payment_Date__c, ECM_Tax_Rate__c,ECM_Type__c,Owner__c,ECM_Recommended_IO_Code__c, ECM_Budget_types__r.Name,ECM_Budget_types__r.ECM_Evidence_Mandatory__c, ECM_Budget_types__c,ECM_Contract__r.UOS_Earnt__c,ECM_Contract__r.Available_AP_Spend__c,
                                    ECM_Contract__r.ECM_Agreement_Type__r.Geography__r.Name ,ECM_Contract__r.ECM_Banner__c,ECM_Contract__r.ECM_Contract_Other_Spent__c,ECM_Contract__r.ECM_Contract_Payment_Spent__c,ECM_Contract__r.ECM_Total_Training_Over_Term__c,ECM_Contract__r.ECM_Total_Others_Over_Term__c,ECM_Contract__r.OwnerId,
                                    ECM_Contract__r.Account.Id,ECM_Contract__r.Id,ECM_Contract__r.ECM_Agreement_Type__r.ECM_Evidence_for_Payment_Summary__c,ECM_Contract__r.ECM_Agreement_Type__r.ECM_Invoices_for_Payment_Summary__c,
                                    ECM_Achieved_Leading_Brand__c,ECM_Achieved_Non_Leading_Brand__c,ECM_Achieved_Overall__c,ECM_Contract__r.ECM_Duration__c,
                                    (Select Id,Name,ECM_Contract_Item__r.ECM_Product__r.Product_Name__c,ECM_Planned_Amount_Per_Payment__c,ECM_Contract_Item__r.ECM_Product__c,ECM_Contract_Item__r.ECM_UoM__c, ECM_Confirmed_Volume__c,
                                     ECM_Contract_Item__r.ECM_Volume_Target_per_PF__c,ECM_Product__c,ECM_Product__r.name,ECM_Total_UoS__c,ECM_Actual_Cases__c,ECM_Contract_Item__r.ECM_Actual_Volume_YTD__c,ECM_Confirmed_Amount_Per_Payment__c,ECM_Confirm__c,ECM_Reject__c,ECM_Roll_Over__c,
                                     ECM_Contract_Item__r.ECM_Lead_Brand__c,ECM_Contract_Item__r.ECM_Volume__c
                                     From Payment_Summary_Item__r) 
                                    From ECM_Payment_Summary__c
                                    Where id=:paymentSummary1.id];
        ECM_PaymentSummaryTriggerHelper.checkForExtraApprovalAvailability(new List<ECM_Payment_Summary__c>{paymentSummaryRecord});
        ECM_PaymentSummaryTriggerHelper.validateAdditionalExtraApproval(new List<ECM_Payment_Summary__c>{paymentSummaryRecord});
        Test.stopTest();
    }
    @isTest
    public static void createDataAU2(){
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU'); 
        Id contrRecTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        system.assert(geographyId!= null,'geographyId should not be null');
        User salesRep = ECM_UtilityTestClass.createUser('srp',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
        salesRep.Username = 'salesRp11234@test.com';
        salesRep.isActive=true;
        insert salesRep;
        
        User salesRe = ECM_UtilityTestClass.createUser('srptest',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
        salesRe.Username = 'salesRp11234dfg@test.com';
        insert salesRe;
        
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = true;
        insert orgSetting;
        
        String budgetTypeRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        String taxCodeRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Tax Code').getRecordTypeId();
        
        Pick_Up_Options__c budgetTypeObj1= new Pick_Up_Options__c();
        budgetTypeObj1.Name='Portfolio Rebates [AU]';
        budgetTypeObj1.Status__c = 'Active';
        budgetTypeObj1.Geography__c=geographyId;
        budgetTypeObj1.RecordTypeId=budgetTypeRecordTypeId;
        insert budgetTypeObj1;
        
                
        Pick_Up_Options__c taxCode= new Pick_Up_Options__c();
        taxCode.Name = 'No Tax[AU]';
        taxCode.Geography__c=geographyId;
        taxCode.RecordTypeId=taxCodeRecordTypeId;
        insert taxCode;
        
        Date myDate = Date.newInstance(2022, 2, 17);
        
        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        contractType.ECM_Prepayment_SR_approval__c=False;
        contractType.ECM_Activation_Spend_Table_Configuration__c = 'Activation Spend Sub Group;Activity Type Description;Delivery Date;Must Do;Product Name;Investment';
        insert contractType;
        
        Pick_Up_Options__c pOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pOption.Name='LE[AU]';
        insert pOption;
        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.country__c = geographyId;
        acc.Sales_Org__c ='sale';
        acc.SAP_Sold_to__c ='sapsold';
        acc.Outlet_Visit_Prioritisation_Grade__c = pOption.Id;
        acc.Independent_of_Operator__c = true;
        acc.Independent_of_Owner__c = true;
        //acc.Global_Channel__c = 'Off Trade';
        insert acc;
        
        Test.startTest();
        
        Contract contr1 = ECM_UtilityTestClass.createContract(acc.id,contrRecTypeId);        
        contr1.ECM_Agreement_Type__c = contractType.Id;
        contr1.ownerId = salesRep.Id;
        //contr1.CurrencyIsoCode = 'AUD';
        contr1.Status='Draft';        
        insert contr1;
        contr1.Status='Active';
        contr1.ECM_Upfront_Payment_Spent__c = null;
        contr1.ECM_Contract_SKU_Specific_Rebate_Paid__c =null;
        contr1.Rebate_Paid__c =null;
        update contr1;
        
        Contract contr2 = ECM_UtilityTestClass.createContract(acc.id,contrRecTypeId);        
        contr2.ECM_Agreement_Type__c = contractType.Id;
        contr2.ownerId = salesRep.Id;
        //contr1.CurrencyIsoCode = 'AUD';
        contr2.Status='Draft';        
        insert contr2;
        contr2.Status='Active';
        contr2.ECM_Upfront_Payment_Spent__c = null;
        contr2.ECM_Contract_SKU_Specific_Rebate_Paid__c =null;
        contr2.Rebate_Paid__c =null;
        update contr2;
        
        Contract contr3 = ECM_UtilityTestClass.createContract(acc.id,contrRecTypeId);        
        contr3.ECM_Agreement_Type__c = contractType.Id;
        contr3.ownerId = salesRep.Id;
        //contr1.CurrencyIsoCode = 'AUD';
        contr3.Status='Draft';        
        insert contr3;
        contr3.Status='Active';
        contr3.ECM_Upfront_Payment_Spent__c = null;
        contr3.ECM_Contract_SKU_Specific_Rebate_Paid__c =null;
        contr3.Rebate_Paid__c =null;
        update contr3;

		ECM_Payment_Summary__c paymentSummary3 = ECM_UtilityTestClass.getPaymentSummary(contr1.id); 
        paymentSummary3.ECM_Payment_Summary_Status__c = 'Open';
        paymentSummary3.ECM_Type__c='Non-Volume';
        paymentSummary3.ECM_SAP_Payment_Date__c = myDate;
        paymentSummary3.ECM_Budget_types__c=budgetTypeObj1.Id;
        paymentSummary3.ECM_Total_Amount_Confirmed__c=120;
        insert paymentSummary3;
        
        ECM_Payment_Summary__c paymentSummary4 = ECM_UtilityTestClass.getPaymentSummary(contr2.id); 
        paymentSummary4.ECM_Payment_Summary_Status__c = 'Open';
        paymentSummary4.ECM_Type__c='Non-Volume';
        paymentSummary4.ECM_SAP_Payment_Date__c = myDate;
        paymentSummary4.ECM_Budget_types__c=budgetTypeObj1.Id;
        paymentSummary4.ECM_Total_Amount_Confirmed__c=10;
        insert paymentSummary4;
        
        ECM_Payment_Summary__c paymentSummary5 = ECM_UtilityTestClass.getPaymentSummary(contr3.id); 
        paymentSummary5.ECM_Payment_Summary_Status__c = 'Open';
        paymentSummary5.ECM_Type__c='Non-Volume';
        paymentSummary5.ECM_SAP_Payment_Date__c = myDate;
        paymentSummary5.ECM_Budget_types__c=budgetTypeObj1.Id;
        paymentSummary5.ECM_Total_Amount_Confirmed__c=10;
        insert paymentSummary5;
        
		paymentSummary3.ECM_Payment_Summary_Status__c = 'Completed';
        paymentSummary4.ECM_Payment_Summary_Status__c = 'Completed';
        paymentSummary5.ECM_Payment_Summary_Status__c = 'Completed';
        update paymentSummary3;
        update paymentSummary4;
        update paymentSummary5;
        
        AccountShare accountShare = new AccountShare();
        accountShare.AccountId = acc.id;
        accountShare.UserOrGroupId = salesRep.id;
        accountShare.AccountAccessLevel = 'Edit';
        accountShare.ContactAccessLevel = 'Edit';
        accountShare.OpportunityAccessLevel = 'Edit';
        insert accountShare;
            
        
        Map<Id,String>userRoleMap= new  Map<Id,String>();
        userRoleMap.put(salesRep.id,'Delegated Extra Approver');
        userRoleMap.put(salesRe.id,'Delegated Extra Approver');        
        
        ECM_Extra_Approval__c ecmEX1 = new ECM_Extra_Approval__c();
        ecmEX1.ECM_Approver_Position_Name__c = 'Test Approver';
        ecmEX1.ECM_Active__c = true;
        ecmEX1.ecm_type__c = 'Volume Based PS-Target';
        ecmEX1.ECM_Approver_s_Email_Address__c = 'testEX1@diageo.com';
        ecmEX1.ECM_Lower_Limit_Amount__c = 50;
        ecmEX1.ECM_Upper_Limit_Amount__c = 200;
        ecmEX1.ECM_Re_Investment_Rate_Lower_Limit__c = 10;
        ecmEX1.ECM_Re_Investment_Rate_Upper_Limit__c = 20;
        ecmEX1.ECM_Enable_Delegation__c = true;
        ecmEX1.ECM_Delegated_Approver_Email_Address__c ='Test2@diageo.com';
        ecmEX1.ECM_Extra_Approval_User__c = salesRep.Id;
        insert ecmEX1;
        
        ECM_Agreement_Approval__c agrementApproval  = new ECM_Agreement_Approval__c();
        agrementApproval.ECM_Agreement_Type__c = contractType.Id;
        agrementApproval.ECM_Extra_Approval__c = ecmEX1.Id;
        insert agrementApproval;
        
         ECM_PaymentSummaryTriggerHelper.checkForExtraApprovalAvailability(new List<ECM_Payment_Summary__c>{paymentSummary3});
        ECM_PaymentSummaryTriggerHelper.checkAndProvideAccountAccess(acc.id,userRoleMap);
                        
        Test.stopTest();
        
    }
    
    
    @isTest
    public static void createDataAU1(){
        
        
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');  
        Id contrRecTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        system.assert(geographyId!= null,'geographyId should not be null');
        
        User salesRep = ECM_UtilityTestClass.createUser('srp',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
        salesRep.Username = 'salesRp11234@test.com';
        insert salesRep;
        
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = true;
        insert orgSetting;
        
        String budgetTypeRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        String taxCodeRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Tax Code').getRecordTypeId();
        
        Pick_Up_Options__c budgetTypeObj1= new Pick_Up_Options__c();
        budgetTypeObj1.Name='Portfolio Rebates [AU]';
        budgetTypeObj1.Status__c = 'Active';
        budgetTypeObj1.Geography__c=geographyId;
        budgetTypeObj1.RecordTypeId=budgetTypeRecordTypeId;
        insert budgetTypeObj1;
        
        Pick_Up_Options__c budgetTypeObj2= new Pick_Up_Options__c();
        budgetTypeObj2.Name='SKU Specific Rebates [AU]';
        budgetTypeObj2.Status__c = 'Active';
        budgetTypeObj2.Geography__c=geographyId;
        budgetTypeObj2.RecordTypeId=budgetTypeRecordTypeId;
        insert budgetTypeObj2;
        
        Pick_Up_Options__c budgetTypeObj3= new Pick_Up_Options__c();
        budgetTypeObj3.Name='Upfront Payment [AU]';
        budgetTypeObj3.Status__c = 'Active';
        budgetTypeObj3.Geography__c=geographyId;
        budgetTypeObj3.RecordTypeId=budgetTypeRecordTypeId;
        insert budgetTypeObj3;
        
        Pick_Up_Options__c taxCode= new Pick_Up_Options__c();
        taxCode.Name = 'No Tax[AU]';
        taxCode.Geography__c=geographyId;
        taxCode.RecordTypeId=taxCodeRecordTypeId;
        insert taxCode;
        
        Date myDate = Date.newInstance(2022, 2, 17);
        Date myDate1 = Date.newInstance(2023, 3, 14);
        
        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        contractType.ECM_Prepayment_SR_approval__c=False;
        contractType.ECM_Activation_Spend_Table_Configuration__c = 'Activation Spend Sub Group;Activity Type Description;Delivery Date;Must Do;Product Name;Investment';
        insert contractType;
        
        Pick_Up_Options__c pOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pOption.Name='Portfolio Rebate[AU]';
        insert pOption;
        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.country__c = geographyId;
        acc.Sales_Org__c ='sale';
        acc.SAP_Sold_to__c ='sapsold';
        acc.Outlet_Visit_Prioritisation_Grade__c = pOption.Id;
        acc.Independent_of_Operator__c = true;
        acc.Independent_of_Owner__c = true;
        //acc.Global_Channel__c = 'Off Trade';
        insert acc;
        
        Test.startTest();
        
        List<Contract> conList = new List<Contract>();
        Contract contr = ECM_UtilityTestClass.createContract(acc.id,contrRecTypeId);        
        contr.ECM_Agreement_Type__c = contractType.Id;
        contr.ownerId = salesRep.Id;
        contr.CurrencyIsoCode = 'AUD';
        conList.add(contr);
        
        Contract contr1 = ECM_UtilityTestClass.createContract(acc.id,contrRecTypeId);        
        contr1.ECM_Agreement_Type__c = contractType.Id;
        contr1.ownerId = salesRep.Id;
        contr1.CurrencyIsoCode = 'AUD';
        contr1.Status='Draft';
        contr1.ECM_Upfront_Payment_Spent__c = null;
        contr1.ECM_Contract_SKU_Specific_Rebate_Paid__c =null;
        contr1.Rebate_Paid__c=null;
        conList.add(contr1);
        
        insert conList;
        contr1.Status='Active';
        update contr1;
		
        List<ECM_Payment_Summary__c> psList = new List<ECM_Payment_Summary__c>();
		ECM_Payment_Summary__c paymentSummary3 = ECM_UtilityTestClass.getPaymentSummary(contr1.id); 
        paymentSummary3.ECM_Payment_Summary_Status__c = 'Open';
        paymentSummary3.ECM_SAP_Payment_Date__c = myDate;
        paymentSummary3.ECM_Budget_types__c=budgetTypeObj1.Id;
        psList.add(paymentSummary3);
        
        ECM_Payment_Summary__c paymentSummary4 = ECM_UtilityTestClass.getPaymentSummary(contr1.id); 
        paymentSummary4.ECM_Payment_Summary_Status__c = 'Open';
        paymentSummary4.ECM_SAP_Payment_Date__c = myDate;
        paymentSummary4.ECM_Budget_types__c=budgetTypeObj2.Id;
        psList.add(paymentSummary4);
        
        ECM_Payment_Summary__c paymentSummary5 = ECM_UtilityTestClass.getPaymentSummary(contr1.id); 
        paymentSummary5.ECM_Payment_Summary_Status__c = 'Open';
        paymentSummary5.ECM_SAP_Payment_Date__c = myDate;
        paymentSummary5.ECM_Budget_types__c=budgetTypeObj3.Id;
        psList.add(paymentSummary5);
        
        Product__c product1 = ECM_UtilityTestClass.createProduct(geographyId,'Test1');
        product1.Product_Full_Name__c='Test1';
        insert product1;        
        Market_Assortment_Product__c mapRec1 = ECM_UtilityTestClass.createMarketAssortmentProduct(product1.Id,geographyId);
        mapRec1.ECM_INTO_Material__c = 9;
        insert mapRec1; 
        
        ECM_Contract_Item__c ciRec1 = ECM_UtilityTestClass.createcontractitem(contr.Id,mapRec1.id);
        ciRec1.ECM_Actual_Volume_YTD__c = null;
        ciRec1.ECM_Net_Net_List_Price__c = 10;
        ciRec1.ECM_UoM__c=null;
        insert ciRec1;
        
        
        
        ECM_Payment_Summary__c paymentSummary1 = ECM_UtilityTestClass.getPaymentSummary(contr.id);
        paymentSummary1.ECM_Total_Amount_Confirmed__c = 40.00;
        paymentSummary1.ECM_Payment_Summary_Status__c = 'Approved';
        paymentSummary1.ECM_Start_Period__c = myDate;
        paymentSummary1.ECM_End_Period__c = myDate1;
        paymentSummary1.ECM_Type__c = 'Volume-Based';
        paymentSummary1.ECM_Invoice_Status__c='Approved';
        paymentSummary1.ECM_Tax_Rate__c='Standard Rate';
        paymentSummary1.CurrencyIsoCode ='GBP';
        paymentSummary1.ECM_Tax_Code__c=taxCode.Id;
        paymentSummary1.ECM_Budget_types__c=budgetTypeObj1.Id;
        psList.add(paymentSummary1);
        
        insert psList;
        
        ECM_Payment_Summary_Item__c paymemtSummaryItem1 = ECM_UtilityTestClass.getPaymentSummaryItem(paymentSummary1.id,ciRec1.id);
        paymemtSummaryItem1.ECM_Confirmed_Amount_Per_Payment__c = 20;
        insert paymemtSummaryItem1;
        
        psList[0].ECM_Payment_Summary_Status__c = 'Completed';
        psList[1].ECM_Payment_Summary_Status__c = 'Completed';
        psList[2].ECM_Payment_Summary_Status__c = 'Completed';
        update psList;
        Test.stopTest();
    }
    
    @isTest
    public static void createDataAU(){
        
        
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');  
        system.assert(geographyId!= null,'geographyId should not be null');
        Id contrRecTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        User salesRep = ECM_UtilityTestClass.createUser('srp',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
        salesRep.Username = 'salesRp11234@test.com';
        insert salesRep;
        
        
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = true;
        insert orgSetting;
        
        String budgetTypeRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        String taxCodeRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Tax Code').getRecordTypeId();
        
        Pick_Up_Options__c budgetTypeObj1= new Pick_Up_Options__c();
        budgetTypeObj1.Name='Portfolio Rebate[AU]';
        budgetTypeObj1.Geography__c=geographyId;
        budgetTypeObj1.RecordTypeId=budgetTypeRecordTypeId;
        insert budgetTypeObj1;

        
        Pick_Up_Options__c taxCode= new Pick_Up_Options__c();
        taxCode.Name = 'No Tax[AU]';
        taxCode.Geography__c=geographyId;
        taxCode.RecordTypeId=taxCodeRecordTypeId;
        insert taxCode;
        
        /*
Market_Setting__c mktSetting = new Market_Setting__c();
mktSetting.Name = 'Market Setting';
mktSetting.Geography__c = geographyId;
mktSetting.ECM_Budget_Type_for_Volume_Based_PS__c= budgetTypeObj1.Id;
insert mktSetting;        
*/
        
        Account ownerAccount = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        ownerAccount.BillingCountry = 'Australia';
        ownerAccount.BillingState = 'New South Wales';
        //ownerAccount.Person_Responsible__c = UserInfo.getUserId();
        ownerAccount.Country__c = geographyId;
        ownerAccount.IsOwner__c = true;
        ownerAccount.IsOperator__c =false;
        ownerAccount.Person_Responsible__c = salesRep.Id;
        ownerAccount.Status__c = 'Active';
        //ownerAccount.Global_Channel__c = 'On Trade';
        insert ownerAccount;
        
        Date myDate = Date.newInstance(2022, 2, 17);
        Date myDate1 = Date.newInstance(2023, 3, 14);
        Date myDate2 = Date.newInstance(2022, 9, 14);
        
        
        ECM_Internal_Order__c internalOrder = ECM_UtilityTestClass.getInternalOrder(geographyId);
        internalOrder.ECM_Active__c = true;
        internalOrder.Name = 'IO1234567890';
        internalOrder.ECM_Start_Date__c = myDate;
        internalOrder.ECM_End_Date__c = myDate1;
        internalOrder.ECM_Budget_Type_Pickup_Option__c = budgetTypeObj1.Id;
        internalOrder.Owner__c = ownerAccount.Id;
        internalOrder.ECM_State__c = 'New South Wales';
        insert internalOrder;
        
        
        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        contractType.ECM_Prepayment_SR_approval__c=False;
        contractType.ECM_Activation_Spend_Table_Configuration__c = 'Activation Spend Sub Group;Activity Type Description;Delivery Date;Must Do;Product Name;Investment';
        insert contractType;        
        Pick_Up_Options__c pOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pOption.Name='Portfolio Rebate[AU]';
        insert pOption;
        Test.startTest(); 

        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.country__c = geographyId;
        acc.Sales_Org__c ='sale';
        acc.SAP_Sold_to__c ='sapsold';
        acc.Outlet_Visit_Prioritisation_Grade__c = pOption.Id;
        //acc.Parent_Outlet__c = ownerAccount.Id;
        acc.ParentId = ownerAccount.Id;
        acc.Independent_of_Operator__c = true;
        acc.Independent_of_Owner__c = false;
        //acc.Global_Channel__c = 'Off Trade';
        insert acc;

        Contract contr = ECM_UtilityTestClass.createContract(acc.id,contrRecTypeId);        
        contr.ECM_Agreement_Type__c = contractType.Id;
        contr.ownerId = salesRep.Id;
        contr.CurrencyIsoCode = 'AUD';
        insert contr;     
        
        ECM_Payment_Summary__c paymentSummary1 = ECM_UtilityTestClass.getPaymentSummary(contr.id);
        paymentSummary1.ECM_Total_Amount_Confirmed__c = 40.00;
        paymentSummary1.ECM_Payment_Summary_Status__c = 'Open';
        paymentSummary1.ECM_Start_Period__c = myDate;
        paymentSummary1.ECM_End_Period__c = myDate1;
        paymentSummary1.ECM_Type__c = 'Volume-Based';
        paymentSummary1.ECM_Invoice_Status__c='Approved';
        paymentSummary1.ECM_Tax_Rate__c='Standard Rate';
        paymentSummary1.CurrencyIsoCode ='GBP';
        paymentSummary1.ECM_Tax_Code__c=taxCode.Id;
        paymentSummary1.ECM_Budget_types__c=budgetTypeObj1.Id;
        insert paymentSummary1;
        
        ECM_Payment_Summary__c paymentSummary2 = ECM_UtilityTestClass.getPaymentSummary(contr.id);
        paymentSummary2.ECM_Total_Amount_Confirmed__c = 40.00;
        paymentSummary2.ECM_Payment_Summary_Status__c = 'Open';
        paymentSummary2.ECM_Start_Period__c = myDate2;
        paymentSummary2.ECM_End_Period__c = myDate1;
        paymentSummary2.ECM_Type__c = 'Non-Volume';
        paymentSummary2.ECM_Invoice_Status__c='Approved';
        paymentSummary2.ECM_Tax_Rate__c='Standard Rate';
        paymentSummary2.CurrencyIsoCode ='GBP';
        paymentSummary2.ECM_Tax_Code__c=taxCode.Id;
        paymentSummary2.ECM_Budget_types__c=budgetTypeObj1.Id;
        insert paymentSummary2;
        
        paymentSummary2.ECM_Payment_Summary_Status__c = 'Approved';        
        
        
        paymentSummary1.ECM_Payment_Summary_Status__c='Approved';
        update paymentSummary1;
        update paymentSummary2;        
        Test.stopTest();
        
    }
    
    @isTest
    public static void createDataES(){
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
        paymfreq.ECM_Type__c = '100% Prepayment';
        insert paymfreq;

        //Setting up contract to link with payment summary
        Contract contr = ECM_UtilityTestClass.createContract(acc.id,contrRecTypeId);        
        contr.ECM_Agreement_Type__c = contractType.Id;
        contr.ownerId = salesRep.Id;
        contr.ECM_Payment_Frequency_Type__c = paymfreq.Id;
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
        
        String budgetTypeRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        String taxCodeRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Tax Code').getRecordTypeId();
        
        Pick_Up_Options__c budgetTypeObj1= new Pick_Up_Options__c();
        budgetTypeObj1.Name='TI[ES]';
        budgetTypeObj1.Geography__c=geographyId;
        budgetTypeObj1.RecordTypeId=budgetTypeRecordTypeId;
        insert budgetTypeObj1;

        Pick_Up_Options__c taxCode= new Pick_Up_Options__c();
        taxCode.Name = 'No Tax[ES]';
        taxCode.Geography__c=geographyId;
        taxCode.RecordTypeId=taxCodeRecordTypeId;
        insert taxCode;

        //Setting up Payment Summary
        Date myDate = Date.newInstance(2020, 5, 17);
        Date myDate1 = Date.newInstance(2020, 8, 17);
        
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = true;
        insert orgSetting;
        Test.startTest();

        
        List<ECM_Payment_Summary__c> psList = new List<ECM_Payment_Summary__c>();    
        ECM_Payment_Summary__c paymentSummary1 = ECM_UtilityTestClass.getPaymentSummary(contr.id);
        paymentSummary1.ECM_Total_Amount_Confirmed__c = 40.00;
        paymentSummary1.ECM_Payment_Summary_Status__c = 'Open';
        paymentSummary1.ECM_Start_Period__c = myDate;
        paymentSummary1.ECM_End_Period__c = myDate1;
        paymentSummary1.ECM_Type__c = 'Promo-Standard';
        paymentSummary1.ECM_Invoice_Status__c='Approved';
        paymentSummary1.ECM_Tax_Rate__c='Standard Rate';
        paymentSummary1.ECM_Tax_Code__c=taxCode.Id;
        paymentSummary1.ECM_Budget_types__c=budgetTypeObj1.Id;
        psList.add(paymentSummary1);
        
        ECM_Payment_Summary__c paymentSummary4 = ECM_UtilityTestClass.getPaymentSummary(contr.id);
        paymentSummary4.ECM_Type__c = 'Promo-Standard';
        paymentSummary4.ECM_Payment_Summary_Status__c = 'Provisional';
        paymentSummary4.ECM_Start_Period__c = myDate;
        paymentSummary4.ECM_Budget_types__c=budgetTypeObj1.Id;
        paymentSummary4.ECM_Approval_Sub_Status__c='';
        psList.add(paymentSummary4);
        insert psList;
        //Setting up payment summary item
        
        ECM_Payment_Summary_Item__c paymemtSummaryItem2 = ECM_UtilityTestClass.getPaymentSummaryItem(paymentSummary1.id,ciRec.id);
        paymemtSummaryItem2.ECM_Confirmed_Amount_Per_Payment__c = 20;
        paymemtSummaryItem2.ECM_To_Pay__c=true;
        insert paymemtSummaryItem2;

        ECM_Payment_Summary_Item__c paySumItem4 = ECM_UtilityTestClass.getPaymentSummaryItem(paymentSummary4.id,ciRec.id);
        paySumItem4.ECM_Confirmed_Amount_Per_Payment__c = 20;
        paySumItem4.ECM_To_Pay__c=true;
        insert paySumItem4;
        
        paymentSummary4.ECM_Type__c = 'Promo-PrePayment';
        paymentSummary4.ECM_Payment_Summary_Status__c = 'Open';
        paymentSummary4.ECM_Start_Period__c = myDate1;
        paymentSummary4.ECM_Budget_types__c=budgetTypeObj1.Id;
        paymentSummary4.ECM_Approval_Sub_Status__c=label.ECM_In_Extra_Approval;

        paymentSummary1.ECM_Payment_Summary_Status__c='Approved';
        
        ECM_Extra_Approval__c ecmEX1 = new ECM_Extra_Approval__c();
        ecmEX1.ECM_Approver_Position_Name__c = 'Test Approver';
        ecmEX1.ECM_Active__c = true;
        ecmEX1.ecm_type__c = 'Promo-PrePayment PS';
        ecmEX1.ECM_Approver_s_Email_Address__c = 'testEX1@diageo.com';
        ecmEX1.ECM_Lower_Limit_Amount__c = 1;
        ecmEX1.ECM_Upper_Limit_Amount__c = 200;
        ecmEX1.ECM_Re_Investment_Rate_Lower_Limit__c = 10;
        ecmEX1.ECM_Re_Investment_Rate_Upper_Limit__c = 20;
        ecmEX1.ECM_Enable_Delegation__c = true;
        ecmEX1.ECM_Delegated_Approver_Email_Address__c ='Test2@diageo.com';
        ecmEX1.ECM_Extra_Approval_User__c = salesRep.Id;
        insert ecmEX1;
        
        ECM_Extra_Approval__c ecmEX2 = new ECM_Extra_Approval__c();
        ecmEX2.ECM_Approver_Position_Name__c = 'Test Approver';
        ecmEX2.ECM_Active__c = true;
        ecmEX2.ecm_type__c = 'Promo-Standard PS';
        ecmEX2.ECM_Approver_s_Email_Address__c = 'testEX1@diageo.com';
        ecmEX2.ECM_Lower_Limit_Amount__c = 1;
        ecmEX2.ECM_Upper_Limit_Amount__c = 200;
        ecmEX2.ECM_Re_Investment_Rate_Lower_Limit__c = 10;
        ecmEX2.ECM_Re_Investment_Rate_Upper_Limit__c = 20;
        ecmEX2.ECM_Enable_Delegation__c = true;
        ecmEX2.ECM_Delegated_Approver_Email_Address__c ='Test2@diageo.com';
        ecmEX2.ECM_Extra_Approval_User__c = salesRep.Id;
        insert ecmEX2;
        
        ECM_Agreement_Approval__c agrementApproval  = new ECM_Agreement_Approval__c();
        agrementApproval.ECM_Agreement_Type__c = contractType.Id;
        agrementApproval.ECM_Extra_Approval__c = ecmEX1.Id;
        
        ECM_Agreement_Approval__c agrementApproval1  = new ECM_Agreement_Approval__c();
        agrementApproval1.ECM_Agreement_Type__c = contractType.Id;
        agrementApproval1.ECM_Extra_Approval__c = ecmEX2.Id;


        agrementApproval.CurrencyIsoCode = 'EUR';
        insert agrementApproval;
        insert agrementApproval1;
		 //ECM_PaymentSummaryTriggerHelper.checkForExtraApprovalAvailability(psList);
        update psList;
        
         ECM_Payment_Summary__c paymentSummaryRecord = new ECM_Payment_Summary__c();
         paymentSummaryRecord = [Select Id, Name, ECM_Payment_Summary_Status__c,ECM_Contract_Agreement_Type__c,ECM_Contract_Account_Id__c,ECM_Start_Period__c,ECM_End_Period__c,ECM_Contract__r.Status,ECM_Contract__r.Contract_End_Date__c,ECM_Contract__r.StartDate,ECM_Contract__r.Account.Country__c,ECM_Contract__r.RecordTypeId, ECM_Total_to_be_Invoiced__c,ECM_No_Invoice_Required__c, 
                                    ECM_Total_Amount_Forecasted__c, ECM_Total_Amount_Confirmed__c, ECM_Invoice_Receival_Date__c,ECM_Contract__r.Account.SAP_Sold_to__c,ECM_Contract__r.ECM_Agreement_Type__c,ECM_Contract__r.ECM_Territory__c, ECM_UoS_Total__c,ECM_Contract__r.Account.parent_outlet__c,
                                    ECM_Invoice_Status__c, ECM_SAP_Credit_Note_Number__c, ECM_SAP_Credit_Note_Creation_Date__c, ECM_SAP_Billing_Doc_Number__c, ECM_Contract__r.UOS_Rebate_Rate__c,ECM_Contract__r.ECM_Upfront_Pre_payment_amount__c, ECM_Contract__r.ECM_Upfront_Annual_Payment_Amount__c,  ECM_SAP_Billing_Doc_Date__c, 
                                    ECM_SAP_payment_Reference_Number__c, ECM_SAP_Payment_Date__c, ECM_Tax_Rate__c,ECM_Type__c,Owner__c,ECM_Recommended_IO_Code__c, ECM_Budget_types__r.Name,ECM_Budget_types__r.ECM_Evidence_Mandatory__c, ECM_Budget_types__c,ECM_Contract__r.UOS_Earnt__c,ECM_Contract__r.Available_AP_Spend__c,
                                    ECM_Contract__r.ECM_Agreement_Type__r.Geography__r.Name ,ECM_Contract__r.ECM_Banner__c,ECM_Contract__r.ECM_Contract_Other_Spent__c,ECM_Contract__r.ECM_Contract_Payment_Spent__c,ECM_Contract__r.ECM_Total_Training_Over_Term__c,ECM_Contract__r.ECM_Total_Others_Over_Term__c,ECM_Contract__r.OwnerId,
                                    ECM_Contract__r.Account.Id,ECM_Contract__r.Id,ECM_Contract__r.ECM_Agreement_Type__r.ECM_Evidence_for_Payment_Summary__c,ECM_Contract__r.ECM_Agreement_Type__r.ECM_Invoices_for_Payment_Summary__c,
                                    ECM_Achieved_Leading_Brand__c,ECM_Achieved_Non_Leading_Brand__c,ECM_Achieved_Overall__c,ECM_Contract__r.ECM_Duration__c,
                                    (Select Id,Name,ECM_Contract_Item__r.ECM_Product__r.Product_Name__c,ECM_Planned_Amount_Per_Payment__c,ECM_Contract_Item__r.ECM_Product__c,ECM_Contract_Item__r.ECM_UoM__c, ECM_Confirmed_Volume__c,
                                     ECM_Contract_Item__r.ECM_Volume_Target_per_PF__c,ECM_Product__c,ECM_Product__r.name,ECM_Total_UoS__c,ECM_Actual_Cases__c,ECM_Contract_Item__r.ECM_Actual_Volume_YTD__c,ECM_Confirmed_Amount_Per_Payment__c,ECM_Confirm__c,ECM_Reject__c,ECM_Roll_Over__c,
                                     ECM_Contract_Item__r.ECM_Lead_Brand__c,ECM_Contract_Item__r.ECM_Volume__c
                                     From Payment_Summary_Item__r) 
                                    From ECM_Payment_Summary__c
                                    Where id=:paymentSummary4.id];
        ECM_PaymentSummaryTriggerHelper.checkForExtraApprovalAvailability(new List<ECM_Payment_Summary__c>{paymentSummaryRecord});
        Test.stopTest();
    }
    @isTest
    public static void createDataES1(){
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        Id uid = userinfo.getUserId();
    
        User cioUser = ECM_UtilityTestClass.createUser('cio',ECM_UtilityTestClass.getProfile('CIO User').Id);
        cioUser.Username = 'cioUser1234@test.com';
        insert cioUser;
        
        //Setting up a sales rep user to run test as
        User salesRep = ECM_UtilityTestClass.createUser('srp',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
        salesRep.Username = 'salesRp1234@test.com';
        salesRep.isActive=true;
        salesRep.managerid=uid;
        insert salesRep;

        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.BillingStreet = '17 Asian Highway1 45';
        insert acc;
        acc.country__c = geographyId;
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
        
        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        insert contractType;
        
        Date myDate = Date.newInstance(2020, 5, 17);
        List<Contract> contractlst =new List<Contract>();
        Contract contr = new Contract(Name = 'Test',AccountId = acc.id,StartDate=myDate.addMonths(-6).toStartOfMonth(),Contract_End_Date__c=myDate.addMonths(1).toStartOfMonth().addDays(-1),ECM_Duration__c=myDate.addMonths(-6).toStartOfMonth().monthsBetween(myDate.addMonths(1).toStartOfMonth()),ECM_Agreement_Type__c=contractType.Id);
        contr.OwnerId = salesRep.Id;
        contractlst.add(contr); 
        Contract contr1 = new Contract(Name = 'Test1',AccountId = acc.id,StartDate=myDate.addMonths(-6).toStartOfMonth(),Contract_End_Date__c=myDate.addMonths(1).toStartOfMonth().addDays(-1),ECM_Duration__c=myDate.addMonths(-6).toStartOfMonth().monthsBetween(myDate.addMonths(1).toStartOfMonth()));
        contractlst.add(contr1);
        insert contractlst;  
        
        contr.Status = 'Active';
        update contr;
        
        AccountContactRelation acr = new AccountContactRelation();
        acr.AccountId = acc.id;
        acr.ContactId = con.id;
        acr.Contact_Type__c = 'Primary';
        acr.IsActive = true;
        insert acr;
        String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        
        Pick_Up_Options__c budgetTypeObj= ECM_UtilityTestClass.createPickUpOption(geographyId,bannerRecordTypeId);
        budgetTypeObj.Name='TI[ES]';
        budgetTypeObj.Geography__c=geographyId;
        budgetTypeObj.ECM_SAP_Order_reason__c = 'Y10'; 
        budgetTypeObj.ECM_SAP_Pricing_condition__c = 'O25';
        insert budgetTypeObj;
        
        Pick_Up_Options__c budgetTypeObj2= new Pick_Up_Options__c();
        budgetTypeObj2.Name='On-Premise[AU]';
        budgetTypeObj2.Geography__c=geographyId;
        budgetTypeObj2.RecordTypeId=Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        budgetTypeObj2.ECM_SAP_Order_reason__c = 'Y10'; 
        budgetTypeObj2.ECM_SAP_Pricing_condition__c = 'O25';
        insert budgetTypeObj2;
        
        
        ECM_Payment_Summary__c paymemtSummary = new ECM_Payment_Summary__c();
        paymemtSummary.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummary.ECM_Payment_Summary_Status__c = 'Open';
        paymemtSummary.ECM_Type__c = 'Promo-Standard';
        paymemtSummary.ECM_Invoice_Status__c='Requested';
        paymemtSummary.ECM_Contract__c = contr.id;
        paymemtSummary.ECM_Start_Period__c = system.today();
        paymemtSummary.ECM_End_Period__c = system.today()+2;
        paymemtSummary.ECM_Budget_types__c = budgetTypeObj.id;
        paymemtSummary.ECM_Invoice_Status__c ='Approved';
        paymemtSummary.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymemtSummary.ECM_approval_sub_status__C = 'Manager Approval';
        paymemtSummary.ECM_Manager_Approver__c=userinfo.getUserId();
        paymemtSummary.ECM_Tax_Rate__c='Standard Rate';
        paymemtSummary.ECM_Recommended_IO_Code__c='MHJ0WACF6900';
        insert paymemtSummary;
        
        ECM_Payment_Summary__c paymemtSummary2 = new ECM_Payment_Summary__c();
        paymemtSummary2.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummary2.ECM_Payment_Summary_Status__c = 'Submitted';
        paymemtSummary2.ECM_Type__c = 'Volume-Based';
        paymemtSummary2.ECM_Invoice_Status__c='Requested';
        paymemtSummary2.ECM_Contract__c = contr.id;
        paymemtSummary2.ECM_Start_Period__c = system.today();
        paymemtSummary2.ECM_End_Period__c = system.today()+2;
        paymemtSummary2.ECM_Budget_types__c = budgetTypeObj.id;
        paymemtSummary2.ECM_Invoice_Status__c ='Approved';
        paymemtSummary2.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymemtSummary2.ECM_SAP_payment_Reference_Number__c=10;
        paymemtSummary2.ECM_Email_Sent__c =false;
        //PaymemtSummary2.ownerid = uid;
        insert paymemtSummary2;
        ECM_Payment_Summary__c paymemtSummary3 = new ECM_Payment_Summary__c();
        paymemtSummary3.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummary3.ECM_Payment_Summary_Status__c = 'Submitted';
        paymemtSummary3.ECM_Type__c = 'Non-Volume';
        paymemtSummary3.ECM_Invoice_Status__c='Requested';
        paymemtSummary3.ECM_Contract__c = contr.id;
        paymemtSummary3.ECM_Start_Period__c = system.today();
        paymemtSummary3.ECM_End_Period__c = system.today()+2;
        paymemtSummary3.ECM_Budget_types__c = budgetTypeObj.id;
        paymemtSummary3.ECM_Invoice_Status__c ='Approved';
        paymemtSummary3.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymemtSummary3.ECM_SAP_payment_Reference_Number__c=10;
        paymemtSummary3.ECM_Email_Sent__c =false;
        //PaymemtSummary3.ownerid = uid;
        insert paymemtSummary3;
        
        ECM_Payment_Summary__c paymentSummaryRecord = new ECM_Payment_Summary__c();
            paymentSummaryRecord = ECM_PaymentSummaryController.getPaymentSummary(paymemtSummary.Id);
         Test.startTest();
        Product__c product = new Product__c();
        product.Name='Test';
        product.Product_Full_Name__c='Test';
        product.Country__c=geographyId;
        insert product;
        
        List<BusinessHours> bHourList = [select id from BusinessHours];
        Market_Setting__c mktSetting = new Market_Setting__c();
        mktSetting.Name = 'Market Setting';
        mktSetting.Geography__c = geographyId;
        mktSetting.Business_Hours__c = bHourList[0].Id;
        mktSetting.Minimum_Product_Assortment__c = 'Binary';
        mktSetting.Minimum_Activation_Standards__c = 'Binary';
        mktSetting.Distribution__c = 'Binary';
        mktSetting.New_Product_Distribution__c = 'Progressive';
        mktSetting.Open_Opportunity__c = 'Calculative';
        mktSetting.Closed_Opportunity__c = 'Calculative';
        mktSetting.Outlet_Execution_Score__c = 'Calculative';
        mktSetting.A_P_Threshold__c=10;
        mktSetting.Prospect_Approver__c = 'Sales Manager & MDM Approval Required' ;
        mktSetting.ECM_SAP_Order_Type__c = 'Sap';
        mktSetting.ECM_Evidence_email_enabled__c=true;
        mktSetting.ECM_Payment_Management_Email__c='TEST@test.com';
        mktSetting.ECM_Diageo_Entity_Address_for_Invoicing__c='TEST@test.com';
        mktSetting.ECM_Payment_Evidence_Pre_Payment_SP__c='ECM_PaymentSummaryEvidenceRequestPrePySP';
        mktSetting.ECM_Payment_Evidence_Pre_Payment__c='ECM_PaymentSummaryEvidenceRequestPrePay';
        mktSetting.ECM_Payment_Evidence_template__c='ECM_PaymentSummaryEvidenceRequestStd';
        mktSetting.ECM_Payment_Evidence_SP_template__c='ECM_PaymentSummaryEvidenceRequestStdSP';
        mktSetting.ECM_Payment_Invoice_SP_template__c='ECM_PaymentSummaryInvoiceRequestSP';
        mktSetting.ECM_Payment_Invoice_template__c='ECM_PaymentSummaryInvoiceRequest';
        mktSetting.ECM_Manager_Approval__c = 'Promo-Standard;Volume-Based;Promo-PrePayment';
        mktSetting.ECM_Rejection_Email_to_Sales_Rep__c = true;
        insert mktSetting;        
        
        /* Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(geographyId);
mktSetting.ECM_Evidence_email_enabled__c=true;
insert mktSetting;
*/
       
        
        Market_Assortment_Product__c marketassort = new Market_Assortment_Product__c();
        marketassort.Product__c=product.Id;
        marketassort.Market_Assortment__c=geographyId;
        marketassort.ECM_INTO_Material__c = 9;
        insert marketassort;
        
        ECM_Contract_Item__c newcontractitem= new ECM_Contract_Item__c();
        newcontractitem.ECM_Contract__c=contr.Id;
        newcontractitem.ECM_Product__c=Marketassort.id;
        insert newcontractitem;
        
        ECM_Tiering__c tier= new ECM_Tiering__c();
        tier.ECM_Contract_Item__c=newcontractitem.Id;
        tier.ECM_Tier_1_rate_per_UoM__c=1.00;
        tier.ECM_Tier_1_volume_limit__c=1;
        tier.ECM_Tier2_rate_per_UoM__c=2.00;
        tier.ECM_Tier_2_volume_limit__c=2;
        tier.ECM_Tier_3_rate_per_UoM__c=3.00;
        tier.ECM_Tier_3_volume_limit__c=3;
        insert tier;
        
        ECM_Payment_Summary_Item__c paymemtSummaryItem = new ECM_Payment_Summary_Item__c();
        paymemtSummaryItem.ECM_Payment_Summary__c = PaymemtSummary.id;
        paymemtSummaryItem.ECM_Confirm__c = true;
        paymemtSummaryItem.ECM_Contract_Item__c = newcontractitem.id;			
        paymemtSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
        insert paymemtSummaryItem;
        
        
        ECM_Internal_Order__c internalOrder = new ECM_Internal_Order__c();
        internalOrder.ECM_Product__c = product.id;
        internalOrder.ECM_Active__c = true;
        internalOrder.ECM_Description__c = 'ABCD';
        internalOrder.ECM_Budget_Amount__c = 100.00;
        internalOrder.ECM_Start_Date__c = system.today();
        internalOrder.ECM_End_Date__c = system.today()+1;
        internalOrder.ECM_Budget_Type_Pickup_Option__c = budgetTypeObj.id;
        internalOrder.ECM_Geography__c = geographyId;
        internalOrder.ECM_Auto_Assignment__c = true;
        internalOrder.Name='123456789101';
        insert internalOrder;
        
        List<ECM_Payment_Summary_Item__c> paymemtSummaryItemList = new List<ECM_Payment_Summary_Item__c>();
        paymemtSummaryItemList.add(PaymemtSummaryItem);
        
        List<ECM_Payment_Summary__c> paymemtSummaryList = new List<ECM_Payment_Summary__c>();
        paymemtSummaryList.add(paymemtSummary);
        List<Id> psIdLst = new List<Id>();
        psIdLst.add(paymemtSummary.id);
        
        map<id,ECM_Payment_Summary__c> newMap = new map<id,ECM_Payment_Summary__c>();
        newMap.put(paymentSummaryRecord.Id,paymentSummaryRecord);
        map<id,ECM_Payment_Summary__c> oldMap = new map<id,ECM_Payment_Summary__c>();
        
        
        ECM_PaymentSummaryTriggerHelper.fetchContractDetails(new List<ECM_Payment_Summary__c> {PaymemtSummary});
        
        PaymemtSummary.ECM_Payment_Summary_Status__c = 'In Approval Process';
        PaymemtSummary.ECM_Approval_Sub_Status__c=Label.ECM_In_Manager_Approval;
        update PaymemtSummary;
        
        oldMap.put(PaymemtSummary.Id, PaymemtSummary);
        
        
        ECM_PaymentSummaryTriggerHelper.sendRejectionEmail(newMap, oldMap);
        ECM_PaymentSummaryTriggerHelper.checkForCIOApproval(oldMap.values());
        ECM_PaymentSummaryTriggerHelper.updateCIOApprovalRecords(new set<id>{PaymemtSummary.Id});        
        // Create an approval request for the account
        Approval.ProcessSubmitRequest apprReq = new Approval.ProcessSubmitRequest();
        apprReq.setComments('Submitting request for approval.');
        apprReq.setObjectId(PaymemtSummary.id);
        
        apprReq.setNextApproverIds(new List<Id>{uid});
        // Submit on behalf of a specific submitter
        apprReq.setSubmitterId(salesRep.Id); 
        
        // Submit the record to specific process and skip the criteria evaluation
        apprReq.setSkipEntryCriteria(true);
        
        // Submit the approval request for the account
        Approval.ProcessResult result = Approval.process(apprReq);
        
        System.assertEquals(
            'Pending', result.getInstanceStatus(), 
            'Instance Status'+result.getInstanceStatus());
        
         
        
        // Approve the submitted request
        // First, get the ID of the newly created item
        List<Id> newWorkItemIds = result.getNewWorkitemIds();
        
        // Instantiate the new ProcessWorkitemRequest object and populate it
        Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
        req2.setComments('Approving request.');
        req2.setAction('Approve');
        req2.setNextApproverIds(new Id[] {cioUser.Id});
        
        // Use the ID from the newly created item to specify the item to be worked
        req2.setWorkitemId(newWorkItemIds.get(0));
        
        // Submit the request for approval
        Approval.ProcessResult result2 =  Approval.process(req2);
        
        // Verify the results
        System.assert(result2.isSuccess(), 'Result Status:'+result2.isSuccess());
        // This fails when approval process requires unanimous approval
        System.assertEquals(
            'Approved', result2.getInstanceStatus(), 
            'Instance Status'+result2.getInstanceStatus());
        
        
        PaymemtSummary.ECM_Payment_Summary_Status__c = 'Submitted';
        PaymemtSummary.ECM_Approval_Sub_Status__c = Label.ECM_CIO_Approval;
        update PaymemtSummary;
        
        Approval.ProcessSubmitRequest apprReq1 = new Approval.ProcessSubmitRequest();
        apprReq1.setComments('Submitting request for approval.');
        apprReq1.setObjectId(PaymemtSummary.id);
        
        apprReq1.setNextApproverIds(new List<Id>{cioUser.Id});
        // Submit on behalf of a specific submitter
        apprReq1.setSubmitterId(uid); 
        
        // Submit the record to specific process and skip the criteria evaluation
        apprReq1.setSkipEntryCriteria(true);
        
        // Submit the approval request for the account
        Approval.ProcessResult result1 = Approval.process(apprReq1);
        
        
        System.assertEquals(
            'Pending', result1.getInstanceStatus(), 
            'Instance Status'+result1.getInstanceStatus());
		
        ECM_PaymentSummaryTriggerHelper.checkForCIOApproval(oldMap.values());
        ECM_PaymentSummaryTriggerHelper.updateCIOApprovalRecords(new set<id>{PaymemtSummary.Id});
        ECM_PaymentSummaryTriggerHelper.sendInvocePSEmail(newMap, oldMap);
    }

    @isTest
    private static void testCreateRollOverPaymentSummary(){
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