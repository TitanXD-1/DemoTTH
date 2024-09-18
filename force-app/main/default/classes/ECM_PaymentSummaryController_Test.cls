/*
@Name: ECM_PaymentSummaryController_Test 
@Description: This class is used to cover test data for the - ECM_PaymentSummaryController,ECM_PaymentSummaryEmailHandler,ECM_PaymentSummaryHandler.
@History                                                                                                                       
VERSION          AUTHOR                     DATE              DETAIL
1.0              Inayathulla Md             15/04/2020        Initial Development
2.0              Saurav Prasad              03/09/2021        ECM-4760 Logic for Calculations in % Achieved table for Leading & Non Leading Brand in Payment Summary Screen
3.0              Wribhu Bose                27/10/2022        ECM-6270 - Added code for decimal formatter in ECM_GetPaymentSummaryDetails
4.0              Joshraj Sen/Sakshi Shah    01/04/2024        152305 Fixed SCA
*/
@istest
public class ECM_PaymentSummaryController_Test {
    static Account acc1=new Account();
    static Account outletAccount=new Account();
    static Id geoIDSpain;
    @isTest static void getSummaryDetailsTest(){
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        System.assert(geographyId!=null,'Geography ID is Fetched');
        List<Account> accounts = ECM_PaymentSummaryController_Test.getAccounts(geographyId);       
        List<Contact> contacts = ECM_PaymentSummaryController_Test.getContacts(accounts);        
        List<ECM_Contract_Type__c> contractTypeList = ECM_PaymentSummaryController_Test.getContractTypeList(geographyId);      
        List<Contract> contractList = ECM_PaymentSummaryController_Test.getContractList(accounts,contractTypeList);       
        List<AccountContactRelation> accContactRelationList =new List<AccountContactRelation>();
        accContactRelationList=ECM_PaymentSummaryController_Test.getAccContactRelation(accounts,contacts);
        Pick_Up_Options__c budgetTypeObj =ECM_PaymentSummaryController_Test.getBudgetTypeObj(geographyId);
        List<ECM_Payment_Summary__c> paymemtSummaryList = ECM_PaymentSummaryController_Test.getPaymentSummaryList(contractList,new List<Pick_Up_Options__c>{budgetTypeObj}); 
        List<ECM_Payment_Summary__c> paymemtSummary2List = ECM_PaymentSummaryController_Test.getPaymentSummary2List(contractList,new List<Pick_Up_Options__c>{budgetTypeObj}); 
        List<ECM_Payment_Summary__c> paymemtSummary3List = ECM_PaymentSummaryController_Test.getPaymentSummary3List(contractList,new List<Pick_Up_Options__c>{budgetTypeObj}); 
        List<ECM_Payment_Summary__c> paymentSummaryRecordList = ECM_PaymentSummaryController_Test.getPaymentSummaryRecordList(paymemtSummaryList);       
        Test.startTest();
        List<Product__c> productList = ECM_PaymentSummaryController_Test.getProductList(geographyId);
        List<Market_Setting__c> mktSettingList = new List<Market_Setting__c>();
        mktSettingList=ECM_PaymentSummaryController_Test.getMktSettingList(geographyId);              
        List<Market_Assortment_Product__c> marketassortList = ECM_PaymentSummaryController_Test.getMarketassortList(productList,geographyId); 
        List<ECM_Contract_Item__c> newcontractitemList = ECM_PaymentSummaryController_Test.getNewcontractList(contractList,marketassortList);
        List<ECM_Tiering__c> tierList =new List<ECM_Tiering__c>();
        tierList = ECM_PaymentSummaryController_Test.getTierList(newcontractitemList);
        List<ECM_Payment_Summary_Item__c> paymemtSummaryItemList = ECM_PaymentSummaryController_Test.getPaymentSummaryItemList(newcontractitemList,paymemtSummaryList);
        List<ECM_Payment_Summary_Item__c> paymentSummaryItemList2= new List<ECM_Payment_Summary_Item__c>();
        paymentSummaryItemList2=ECM_PaymentSummaryController_Test.getPaymentSummaryItemList(newcontractitemList,paymemtSummary3List);
        List<ECM_Internal_Order__c> internalOrderList = new List<ECM_Internal_Order__c>();
        internalOrderList=ECM_PaymentSummaryController_Test.getInternalOrderList(productList,new List<Pick_Up_Options__c>{budgetTypeObj},geographyId);        
        ECM_PaymentSummaryController.getPaymentSummaryDetails(paymemtSummaryList[0].id);
        ECM_PaymentSummaryController.fetchUser();
        ECM_Payment_Summary__c paymemtSummary= [select id,ECM_Approval_Sub_Status__c,ECM_Type__c,ECM_Payment_Summary_Status__c,ECM_Manager_Approver__c,ECM_Contract__r.Account.Country__c,ECM_Contract__r.RecordTypeId,ECM_Contract__r.ownerId from ecm_payment_summary__c where id=:paymemtSummaryList[0].Id Limit 1];
        ECM_PaymentSummaryController.updatePaymentSummary(paymemtSummary,JSON.serialize(paymemtSummaryItemList));
        ECM_PaymentSummaryController.updatePaymentSummary(paymemtSummary3List[0],JSON.serialize(paymemtSummaryItemList));
        ECM_PaymentSummaryController.updatePaymentSummaryAndSubmit(paymemtSummary3List[0],JSON.serialize(paymemtSummaryItemList));
        ECM_PaymentSummaryController.updatePaymentSummaryAndSubmit(paymentSummaryRecordList[0],JSON.serialize(paymemtSummaryItemList));     
        ECM_PaymentSummaryController.getInvoiceStatus(); //updatePaymentSummary
        ECM_PaymentSummaryController.getTaxRate();
        ECM_PaymentSummaryController_Test.sendSAPCalloutMethods(paymemtSummary2List,paymemtSummary3List);
        ECM_PaymentSummaryController.fetchUserDetails();
        ECM_PaymentSummaryController.getPaymentSummaryStatus();
        Test.stopTest();    
    }
    static List<ECM_Payment_Summary__c> getPaymentSummaryList(List<Contract> contractList,List<Pick_Up_Options__c> budgetTypeObj){
        List<ECM_Payment_Summary__c> paymemtSummaryList = new List<ECM_Payment_Summary__c>();
        ECM_Payment_Summary__c paymemtSummary = new ECM_Payment_Summary__c();
        paymemtSummary.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummary.ECM_Payment_Summary_Status__c = 'Submitted';
        paymemtSummary.ECM_Type__c = 'Promo-Standard';
        paymemtSummary.ECM_Invoice_Status__c='Requested';
        paymemtSummary.ECM_Contract__c = contractList[0].id;
        paymemtSummary.ECM_Start_Period__c = system.today();
        paymemtSummary.ECM_End_Period__c = system.today()+2;
        paymemtSummary.ECM_Budget_types__c = budgetTypeObj[0].id;
        paymemtSummary.ECM_Invoice_Status__c ='Approved';
        paymemtSummary.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymemtSummary.ECM_approval_sub_status__C = 'Manager Approval';
        paymemtSummary.ECM_Manager_Approver__c=userinfo.getUserId();
        paymemtSummary.ECM_Tax_Rate__c='Standard Rate';
        paymemtSummary.ECM_Recommended_IO_Code__c='MHJ0WACF6900';
        paymemtSummaryList.add(paymemtSummary);
        insert paymemtSummaryList;
        return paymemtSummaryList;   
    }
    public static List<ECM_Payment_Summary__c> getPaymentSummary2List(List<Contract> contractList,List<Pick_Up_Options__c> budgetTypeObj){
        List<ECM_Payment_Summary__c> paymemtSummary2List = new List<ECM_Payment_Summary__c>();
        ECM_Payment_Summary__c paymentSummary2 = new ECM_Payment_Summary__c();
        paymentSummary2.ECM_Total_Amount_Confirmed__c = 20.00;
        paymentSummary2.ECM_Payment_Summary_Status__c = 'Submitted';
        paymentSummary2.ECM_Type__c = 'Volume-Based';
        paymentSummary2.ECM_Invoice_Status__c='Requested';
        paymentSummary2.ECM_Contract__c = contractList[0].id;
        paymentSummary2.ECM_Start_Period__c = system.today();
        paymentSummary2.ECM_End_Period__c = system.today()+2;
        paymentSummary2.ECM_Budget_types__c = budgetTypeObj[0].id;
        paymentSummary2.ECM_Invoice_Status__c ='Approved';
        paymentSummary2.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymentSummary2.ECM_SAP_payment_Reference_Number__c=10;
        paymentSummary2.ECM_Email_Sent__c =false;
        //paymentSummary2.ownerid = uid;
        paymemtSummary2List.add(paymentSummary2);
        insert paymemtSummary2List;
        return paymemtSummary2List;
    }
    public static List<ECM_Payment_Summary__c> getPaymentSummary3List(List<Contract> contractList,List<Pick_Up_Options__c> budgetTypeObj){
        List<ECM_Payment_Summary__c> paymemtSummary3List = new List<ECM_Payment_Summary__c>();
        ECM_Payment_Summary__c paymentSummary3 = new ECM_Payment_Summary__c();
        paymentSummary3.ECM_Total_Amount_Confirmed__c = 20.00;
        paymentSummary3.ECM_Payment_Summary_Status__c = 'Submitted';
        paymentSummary3.ECM_Type__c = 'Non-Volume';
        paymentSummary3.ECM_Invoice_Status__c='Requested';
        paymentSummary3.ECM_Contract__c = contractList[0].id;
        paymentSummary3.ECM_Start_Period__c = system.today();
        paymentSummary3.ECM_End_Period__c = system.today()+2;
        paymentSummary3.ECM_Budget_types__c = budgetTypeObj[0].id;
        paymentSummary3.ECM_Invoice_Status__c ='Approved';
        paymentSummary3.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymentSummary3.ECM_SAP_payment_Reference_Number__c=10;
        paymentSummary3.ECM_Email_Sent__c =false;
        //paymentSummary3.ownerid = uid;
        paymemtSummary3List.add(paymentSummary3);
        insert paymemtSummary3List;
        return paymemtSummary3List;
    }
    static List<Account> getAccounts(Id geographyId)
    {
        List<Account> accounts=new List<Account>();
        Account acc0 = EDGE_UtilityTestClass.getOutletRecord();
        acc0.BillingStreet = '17 Asian Highway1 45';
        insert acc0;
        acc0.country__c = geographyId;
        acc0.Sales_Org__c ='sale';
        acc0.SAP_Sold_to__c ='sapsold';
        update acc0;
        accounts.add(acc0);
        Account acc1 = EDGE_UtilityTestClass.getDistriAccRec();
        acc1.country__c = geographyId;
        insert acc1;
        accounts.add(acc1);
        return accounts;
    }
    static List<Contact> getContacts(List<Account> accounts)
    {
        List<Contact> contacts=new List<Contact>();
        Contact con0 = new Contact();
        con0.LastName = 'My';
        con0.FirstName = 'Test';
        con0.Email = 'test@abc.com';
        con0.AccountId = accounts[1].id;
        con0.Contact_Type__c = 'Primary';
        contacts.add(con0);
        insert contacts;
        return contacts;
    }
    static List<ECM_Contract_Type__c> getContractTypeList(Id geographyId){
        List<ECM_Contract_Type__c> contractTypeList = new List<ECM_Contract_Type__c>();
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
        contractType.Volume_UoM_for_Spirits__c='CAS';
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Volume Target;';
        contractType.ECM_Volume_UoM_for_Beer__c = 'KEG';
        contractType.ECM_Volume_UoM_for_RTD__c = 'Can/Bottle 24 Pack';
        contractType.ECM_Volume_UoM_for_Draught_Cocktails__c = '10L BIB';       
        contractTypeList.add(contractType);
        insert contractTypeList;
        System.assert(contractType.id!=null,'contractType id should not be null');
        return contractTypeList;
    }
    static List<Contract> getContractList(List<Account> accounts,List<ECM_Contract_Type__c> contractTypeList){
        Date myDate = Date.newInstance(2020, 5, 17);
        List<Contract> contractList =new List<Contract>();
        Contract contr = new Contract(Name = 'Test',AccountId = accounts[0].id,StartDate=myDate.addMonths(-6).toStartOfMonth(),Contract_End_Date__c=myDate.addMonths(1).toStartOfMonth().addDays(-1),ECM_Duration__c=myDate.addMonths(-6).toStartOfMonth().monthsBetween(myDate.addMonths(1).toStartOfMonth()),ECM_Agreement_Type__c=contractTypeList[0].Id);
        contractList.add(contr); 
        Contract contr1 = new Contract(Name = 'Test1',AccountId = accounts[0].id,StartDate=myDate.addMonths(-6).toStartOfMonth(),Contract_End_Date__c=myDate.addMonths(1).toStartOfMonth().addDays(-1),ECM_Duration__c=myDate.addMonths(-6).toStartOfMonth().monthsBetween(myDate.addMonths(1).toStartOfMonth()));
        contractList.add(contr1);
        insert contractList;  
        contr.Status = 'Active';
        update contr;
        return contractList;
    }
    
    static List<AccountContactRelation> getAccContactRelation(List<Account> accounts,List<Contact> contacts){
        List<AccountContactRelation> accConRelList = new List<AccountContactRelation>();
        AccountContactRelation accConRel = new AccountContactRelation();
        accConRel.AccountId = accounts[0].id;
        accConRel.ContactId = contacts[0].id;
        accConRel.Contact_Type__c = 'Primary';
        accConRel.IsActive = true;
        accConRelList.add(accConRel);
        insert accConRelList;
        return accConRelList;
    }
    static Pick_Up_Options__c getBudgetTypeObj(Id geographyId){
        //List<Pick_Up_Options__c> budgetTypeObjList = new List<Pick_Up_Options__c>();
        Pick_Up_Options__c budgetTypeObj0 =new Pick_Up_Options__c();
        budgetTypeObj0.RecordTypeId=Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId(); 
        budgetTypeObj0.Name='TI[ES]';
        budgetTypeObj0.Geography__c=geographyId;
        budgetTypeObj0.ECM_SAP_Order_reason__c = 'Y10'; 
        budgetTypeObj0.ECM_SAP_Pricing_condition__c = 'O25';
        return budgetTypeObj0;
    }
    
    
    static List<ECM_Payment_Summary__c> getPaymentSummaryRecordList(List<ECM_Payment_Summary__c> paymemtSummaryList){
        List<ECM_Payment_Summary__c> paymentSummaryRecordList = new List<ECM_Payment_Summary__c>();
        ECM_Payment_Summary__c paymentSummaryRecord = new ECM_Payment_Summary__c();
        paymentSummaryRecord = [Select Id, Name, ECM_Payment_Summary_Status__c, ECM_Start_Period__c,ECM_End_Period__c,ECM_Contract__r.Status,ECM_Contract__r.Contract_End_Date__c,ECM_Contract__r.StartDate,ECM_Contract__r.Account.Country__c,ECM_Contract__r.RecordTypeId, ECM_Total_to_be_Invoiced__c,ECM_No_Invoice_Required__c, 
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
                                Where id=:paymemtSummaryList[0].id];
        
        paymentSummaryRecordList.add(paymentSummaryRecord);
        return paymentSummaryRecordList;
    }
    static List<Product__c> getProductList(Id geographyId){
        List<Product__c> productList = new List<Product__c>();
        Product__c product = new Product__c();
        product.Name='Test';
        product.Product_Full_Name__c='Test';
        product.Country__c=geographyId;
        productList.add(product);
        insert productList;
        return productList;
    }
    static List<Market_Setting__c> getMktSettingList(id geographyId){
        List<BusinessHours> bHourList1 = [select id from BusinessHours];
        List<Market_Setting__c> mktSettingList = new List<Market_Setting__c>();
        Market_Setting__c mktSetting = new Market_Setting__c();
        mktSetting.Name = 'Market Setting';
        mktSetting.Geography__c = geographyId;
        mktSetting.Business_Hours__c = bHourList1[0].Id;
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
        mktSettingList.add(mktSetting);
        System.debug(LoggingLevel.DEBUG, mktSetting);
        insert mktSettingList;
        return mktSettingList;
    }
    static List<Market_Assortment_Product__c> getMarketassortList (List<Product__c> productList,Id geographyId){
        List<Market_Assortment_Product__c> marketassortList = new List<Market_Assortment_Product__c>();
        Market_Assortment_Product__c marketassort = new Market_Assortment_Product__c();
        marketassort.Product__c=productList[0].Id;
        marketassort.Market_Assortment__c=geographyId;
        marketassort.ECM_INTO_Material__c = 9;
        marketassortList.add(marketassort);
        insert marketassortList;
        return marketassortList;
    }
    static List<ECM_Contract_Item__c> getNewcontractList(List<Contract> contractList,List<Market_Assortment_Product__c> marketassortList){
        List<ECM_Contract_Item__c> newcontractitemList = new List<ECM_Contract_Item__c>();
        ECM_Contract_Item__c newcontractitem= new ECM_Contract_Item__c();
        newcontractitem.ECM_Contract__c=contractList[0].Id;
        newcontractitem.ECM_Product__c=marketassortList[0].id;
        newcontractitemList.add(newcontractitem);
        insert newcontractitemList;
        return newcontractitemList;
    }
    static List<ECM_Tiering__c> getTierList(List<ECM_Contract_Item__c> newcontractitemList){
        List<ECM_Tiering__c> tierList = new List<ECM_Tiering__c>();
        ECM_Tiering__c tier= new ECM_Tiering__c();
        tier.ECM_Contract_Item__c=newcontractitemList[0].Id;
        tier.ECM_Tier_1_rate_per_UoM__c=1.00;
        tier.ECM_Tier_1_volume_limit__c=1;
        tier.ECM_Tier2_rate_per_UoM__c=2.00;
        tier.ECM_Tier_2_volume_limit__c=2;
        tier.ECM_Tier_3_rate_per_UoM__c=3.00;
        tier.ECM_Tier_3_volume_limit__c=3;
        tierList.add(tier);
        insert tierList;
        return tierList;
    }
    static List<ECM_Payment_Summary_Item__c> getPaymentSummaryItemList(List<ECM_Contract_Item__c> newcontractitemList,List<ECM_Payment_Summary__c> paymemtSummaryList){
        List<ECM_Payment_Summary_Item__c> paymemtSummaryItemList = new List<ECM_Payment_Summary_Item__c>();
        ECM_Payment_Summary_Item__c paymemtSummaryItem = new ECM_Payment_Summary_Item__c();
        paymemtSummaryItem.ECM_Payment_Summary__c = paymemtSummaryList[0].id;
        paymemtSummaryItem.ECM_Confirm__c = true;
        paymemtSummaryItem.ECM_Contract_Item__c = newcontractitemList[0].id;			
        paymemtSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
        paymemtSummaryItemList.add(paymemtSummaryItem);
        insert paymemtSummaryItemList;
        return paymemtSummaryItemList;
    }
    static List<ECM_Internal_Order__c> getInternalOrderList(List<Product__c> productList,List<Pick_Up_Options__c> budgetTypeObjList,id geographyId){
        List<ECM_Internal_Order__c> internalOrderList = new List<ECM_Internal_Order__c>();
        ECM_Internal_Order__c internalOrder = new ECM_Internal_Order__c();
        internalOrder.ECM_Product__c = productList[0].id;
        internalOrder.ECM_Active__c = true;
        internalOrder.ECM_Description__c = 'ABCD';
        internalOrder.ECM_Budget_Amount__c = 100.00;
        internalOrder.ECM_Start_Date__c = system.today();
        internalOrder.ECM_End_Date__c = system.today()+1;
        internalOrder.ECM_Budget_Type_Pickup_Option__c = budgetTypeObjList[0].id;
        internalOrder.ECM_Geography__c = geographyId;
        internalOrder.ECM_Auto_Assignment__c = true;
        internalOrder.Name='123456789101';
        internalOrderList.add(internalOrder);
        insert internalOrder;
        return internalOrderList;
    }
    
    static void sendSAPCalloutMethods(List<ECM_Payment_Summary__c> paymemtSummary2List,List<ECM_Payment_Summary__c> paymemtSummary3List){
        ECM_PaymentSummaryController.sendSAPCallout(paymemtSummary2List[0].Id);
        ECM_PaymentSummaryController.sendSAPCallout(paymemtSummary3List[0].Id);
    }
    static Geography__c getCountry(Id geographyId1)
    {
        Geography__c country=[select id,ECM_SAP_Plant_for_Payment_File__c from Geography__c where id=:geographyId1 limit 1];
        country.ECM_SAP_Plant_for_Payment_File__c='AU11';
        update country;
        return country;
    }
    static User createSalesRep(Id uid)
    {
        Profile prof = [select id from profile where name=: 'Sales Representative'];
        User usr = new User();
        usr.firstName = 'test1';
        usr.lastName = 'test2';
        usr.profileId = prof.id;        
        usr.email = 'test@test.com';
        usr.Username ='testcm1123456@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='ES';
        usr.Title='Legal';
        usr.ManagerId = uid;
        insert usr;
        return usr;
    }
    static Territory__c getTerritory(String geographyId1,User usr)
    {
        Territory__c testterritory=New Territory__c();
        testterritory.Name='Testterriotory';
        testterritory.Territory_Type__c='Sales';
        testterritory.Country__c= geographyId1;
        testterritory.Status__c='Active';
        testterritory.Primary_Sales_Rep__c = usr.id;
        insert testterritory;
        return testterritory;
    }
    static Contract getContract(Account outletAccount,Territory__c testterritory,ECM_Contract_Type__c contractType)
    {
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Contract objContract = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract.Status = 'Draft';
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
        objContract.StartDate = system.today()-1;
        objContract.Contract_End_Date__c = system.today()+361;
        objContract.ECM_Duration__c = objContract.StartDate.monthsBetween(objContract.Contract_End_Date__c);
        insert objContract;
        return objContract;
    }
    static List<contentdocumentlink> getContentDocumentLink(ECM_Payment_Summary__c paymemtSummary1)
    {
        contentVersion evidencefile= new contentVersion();
        evidencefile.VersionData =Blob.valueOf('New Evidence File');
        evidencefile.Content_Type__c='Evidence';
        evidencefile.title='New Evidence File';
        evidencefile.PathOnClient='New Evidence File.txt';
        evidencefile.RecordTypeId=Schema.SObjectType.contentversion.getRecordTypeInfosByName().get('Payments').getRecordTypeId();
        insert evidencefile;
        
        contentVersion invoicefile= new contentVersion();
        invoicefile.VersionData =Blob.valueOf('New Invoice File');
        invoicefile.Content_Type__c='Invoice';
        invoicefile.title='New Invoice File';
        invoicefile.PathOnClient='New Invoice File.txt';
        invoicefile.RecordTypeId=Schema.SObjectType.contentversion.getRecordTypeInfosByName().get('Payments').getRecordTypeId();
        insert invoicefile;
        List<contentdocumentlink>contentlinkList= new List<contentdocumentlink>();
        for(contentVersion cv:[select id,contentdocumentid from contentVersion where id =:evidencefile.Id or id =:invoicefile.Id ]){
            contentdocumentlink contentlink= new contentdocumentlink();
            contentlink.contentdocumentid=cv.contentdocumentid;
            contentlink.LinkedEntityId=paymemtSummary1.id;
            contentlinkList.add(contentlink);
        }
        
        if(!contentlinkList.isEmpty()){
            database.insert(contentlinkList);
        }
        return contentlinkList;
    }
    static ECM_Payment_Summary__c getQueriedPaymentSummary(Account outletAccount,ECM_Payment_Summary__c paymemtSummary1,Product__c product1)
    {
        Depletions__c dep = new Depletions__c();
        dep.ECM_Volume__c = 100.00;
        dep.ECM_Outlet__c = outletAccount.id;
        dep.ECM_Start_Period__c = system.today()+360;
        dep.ECM_End_Period__c = system.today()+29;
        dep.ECM_Product__c = product1.id;
        dep.ECM_Outlet__c = outletAccount.Id;
        insert dep;
        
        String thisYear = String.valueOf(Date.today().Year());
        List<ECM_Rebates_Calendar__mdt> rcMDT= [Select ECM_Rebate_Calculation_Date__c, ECM_Rebate_Period_End__c, 
                                                ECM_Rebate_Period_Start__c, ECM_Region__c, ECM_Financial_Year__c,
                                                ECM_Quarter__c
                                                From ECM_Rebates_Calendar__mdt
                                                Where /*ECM_Rebate_Calculation_Date__c=TODAY and */ECM_Region__c='Australia'
                                                and ECM_Financial_Year__c=:thisYear limit 1];
        
        
        ECM_Payment_Summary__c psObj = [Select Id, Name, ECM_Payment_Summary_Status__c, ECM_Start_Period__c,ECM_End_Period__c,ECM_Contract__r.Status,ECM_Contract__r.Contract_End_Date__c,ECM_Contract__r.StartDate,ECM_Contract__r.Account.Country__c,ECM_Contract__r.RecordTypeId, ECM_Total_to_be_Invoiced__c,ECM_No_Invoice_Required__c, 
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
                                        Where id=:paymemtSummary1.id];
        
        if(rcMDT.size()>0){
            Depletions__c dep1 = new Depletions__c();
            dep1.ECM_Volume__c = 100.00;
            dep1.ECM_Outlet__c = outletAccount.id;
            dep1.ECM_Start_Period__c = psObj.ECM_Contract__r.StartDate;
            dep1.ECM_End_Period__c = rcMDT[0].ECM_Rebate_Period_End__c;
            dep1.ECM_Product__c = product1.id;
            dep1.ECM_Outlet__c = outletAccount.Id;
            insert dep1;
        }  
        return psObj;
    }
    @isTest static void getSummaryDetailsTest1(){
        Id geographyId1 = EDGE_UtilityTestClass.setupCountry('AU');
        System.assert(geographyId1!=null,'Geography ID is Fetched');
        Geography__c country=new Geography__c();
        country=ECM_PaymentSummaryController_Test.getCountry(geographyId1);
        Id uid = userinfo.getUserId();        
        List<Account> accounts=ECM_PaymentSummaryController_Test.getAccounts(geographyId1);
        acc1 = accounts[0];
        acc1.country__c = geographyId1;
        update acc1;   
        Date myDate1;
        myDate1 = Date.newInstance(2020, 5, 17);
        User usr=ECM_PaymentSummaryController_Test.createSalesRep(uid);
        System.assert(usr.id!=null,'usr id should not be null');
        Territory__c testterritory=ECM_PaymentSummaryController_Test.getTerritory(geographyId1,usr);     
        outletAccount = accounts[0].clone(false,false,false,false);
        outletAccount.Person_Responsible__c= usr.Id;
        outletAccount.OwnerId = usr.Id;   
        outletAccount.Name = 'Test1_Outlet';
        insert outletAccount;     
        ECM_Contract_Type__c contractType=ECM_PaymentSummaryController_Test.getContractTypeList(geographyId1)[0]; 
        Pick_Up_Options__c pickup=ECM_PaymentSummaryController_Test.getBudgetTypeObj(geographyId1);
        Contract objContract=ECM_PaymentSummaryController_Test.getContract(outletAccount,testterritory,contractType);
        objContract.ECM_Banner__c=pickup.Id;
        objContract.Status = 'Active';
        update objContract;    
        ECM_Payment_Summary__c paymemtSummary1 =ECM_PaymentSummaryController_Test.getPaymentSummary2List(new List<Contract>{objContract},new List<Pick_Up_Options__c>{pickup})[0];
        List<contentdocumentlink> contentDocumentLink=new List<ContentDocumentLink>();
        contentDocumentLink=ECM_PaymentSummaryController_Test.getContentDocumentLink(paymemtSummary1);        
        ECM_Payment_Summary__c paymentSummary2 =ECM_PaymentSummaryController_Test.getPaymentSummaryList(new List<Contract>{objContract},new List<Pick_Up_Options__c>{pickup})[0];
        Product__c product1 = ECM_PaymentSummaryController_Test.getProductList(geographyId1)[0];     
        Market_Setting__c mktSetting1 = new Market_Setting__c();
        mktSetting1=ECM_PaymentSummaryController_Test.getMktSettingList(geographyId1)[0];          
        Market_Assortment_Product__c marketassort1 = ECM_PaymentSummaryController_Test.getMarketassortList(new List<Product__c>{product1},geographyId1)[0];      
        ECM_Contract_Item__c newcontractitem1= ECM_PaymentSummaryController_Test.getNewcontractList(new List<Contract> {objContract},new List<Market_Assortment_Product__c>{marketassort1})[0];      
        ECM_Payment_Summary_Item__c paymemtSummaryItem1 = ECM_PaymentSummaryController_Test.getPaymentSummaryItemList(new List<ECM_Contract_Item__c>{newcontractitem1},new List<ECM_Payment_Summary__c>{paymemtSummary1})[0];
        Test.startTest();    
        ECM_Internal_Order__c internalOrder1 = new ECM_Internal_Order__c();
        internalOrder1=ECM_PaymentSummaryController_Test.getInternalOrderList(new List<Product__c>{product1},new List<Pick_Up_Options__c>{pickup},geographyId1)[0];
        List<ECM_Payment_Summary_Item__c> paymemtSummaryItemList = new List<ECM_Payment_Summary_Item__c>();
        paymemtSummaryItemList.add(paymemtSummaryItem1); 
        List<ECM_Payment_Summary__c> paymemtSummaryList = new List<ECM_Payment_Summary__c>();
        paymemtSummaryList.add(paymemtSummary1);
        paymemtSummaryList.add(paymentSummary2);
        List<Id> psIdLst = new List<Id>();
        psIdLst.add(paymemtSummary1.id);
        ECM_Payment_Summary__c psObj=ECM_PaymentSummaryController_Test.getQueriedPaymentSummary(outletAccount,paymemtSummary1,product1); 
        ECM_PaymentSummaryController_Test.callmethodsgetSummaryDetailsTest1(psObj,paymemtSummaryList,paymemtSummaryItemList);
        Test.stopTest();
        
    }
    static void callmethodsgetSummaryDetailsTest1(ECM_Payment_Summary__c psObj,List<ECM_Payment_Summary__c> paymemtSummary,List<ECM_Payment_Summary_Item__c> paymemtSummaryItemList)
    {
        ECM_PaymentSummaryController.PsWrapper psWrap= new ECM_PaymentSummaryController.PsWrapper();
        psWrap = ECM_PaymentSummaryController.getPaymentSummaryDetails(String.valueOf(paymemtSummary[0].Id));
        ECM_PaymentSummaryController.updatePaymentSummaryAndSubmit(psObj,JSON.serialize(paymemtSummaryItemList));     
        ECM_PaymentSummaryController.getSKURebateCase(psObj);
        ECM_PaymentSummaryController.handleCsvGeneration(paymemtSummary[0].id);
        ECM_PaymentSummaryController.getPSattachments(paymemtSummary[0].id,paymemtSummary[0].ECM_Budget_types__c);
        ECM_PaymentSummaryController.fetchUserDetails();
        ECM_PaymentSummaryTriggerHelper.fetchContractDetails(paymemtSummary);
        ECM_PaymentSummaryTriggerHelper.updateIOCode(paymemtSummary);
        ECM_PaymentSummaryController.PsWrapper wrap= new ECM_PaymentSummaryController.PsWrapper();
        wrap.psContractItems = new List<ECM_PaymentSummaryController.SKURebatesRate>();
        outletAccount.Parent_Outlet__c=acc1.id;
        update outletAccount;
        ECM_PaymentSummaryController.getSKURebateCase(psObj);
        ECM_PaymentSummaryController.handleCsvGeneration(paymemtSummary[0].id);
        ECM_Payment_Summary__c paymentSummary2=paymemtSummary[1];
        paymentSummary2.ECM_Payment_Summary_Status__c = 'Rejected';
        update paymentSummary2;       
        try{
            ECM_PaymentSummaryController.getActualSoldCases(psWrap.psgetwrap);
        }
        catch(Exception ex){
            System.debug(LoggingLevel.DEBUG,'Handled exception on getSummaryDetailsTest1');
        }
        
    }
    @isTest static void psEmailHandler(){
        Id geographyId1 = EDGE_UtilityTestClass.setupCountry('AU');
        System.assert(geographyId1!=null,'Geography ID is Fetched');
        Id uid = userinfo.getUserId();
        List<Account> accounts=ECM_PaymentSummaryController_Test.getAccounts(geographyId1);
        acc1 = accounts[0];
        acc1.country__c = geographyId1;
        update acc1;
        Date myDate1;
        myDate1 = Date.newInstance(2020, 5, 17);
        User usr=ECM_PaymentSummaryController_Test.createSalesRep(uid);
        System.assert(usr.id!=null,'usr id should not be null');
        Territory__c testterritory=ECM_PaymentSummaryController_Test.getTerritory(geographyId1,usr);  
        outletAccount = accounts[0].clone(false,false,false,false);
        outletAccount.Person_Responsible__c= usr.Id;
        outletAccount.OwnerId = usr.Id;   
        outletAccount.Name = 'Test2_Outlet';
        insert outletAccount;
        ECM_Contract_Type__c contractType=ECM_PaymentSummaryController_Test.getContractTypeList(geographyId1)[0]; 
        Pick_Up_Options__c pickup=ECM_PaymentSummaryController_Test.getBudgetTypeObj(geographyId1); 
        Contract objContract=ECM_PaymentSummaryController_Test.getContract(outletAccount,testterritory,contractType);
        objContract.ECM_Banner__c=pickup.Id;
        objContract.Contract_End_Date__c = System.today()+29;
        objContract.StartDate = system.today();
        objContract.Contract_End_Date__c = system.today()+360;
        objContract.Status = 'Active';
        update objContract;  
        ECM_Payment_Summary__c paymemtSummary1 =ECM_PaymentSummaryController_Test.getPaymentSummaryList(new List<Contract>{objContract},new List<Pick_Up_Options__c>{pickup})[0];
        ECM_Payment_Summary__c paymensum1;
        paymensum1 = [Select id,ECM_Start_Period__c,ECM_SAP_payment_Reference_Number__c,ECM_Invoice_Receival_Date__c,ECM_Budget_types__c,ECM_Invoice_Status__c,ECM_End_Period__c,ECM_Total_Amount_Confirmed__c,ECM_Type__c,ECM_Payment_Summary_Status__c,ECM_Contract__c from ECM_Payment_Summary__c where id=:paymemtSummary1.Id];
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        Account outletAccount1 = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount1.Person_Responsible__c= usr.Id;
        outletAccount1.OwnerId = usr.Id;
        outletAccount1.Country__c=geographyId;
        outletAccount1.Name = 'Test22_Outlet';
        insert outletAccount1;
        ECM_Payment_Summary__c paymentSummary2 =ECM_PaymentSummaryController_Test.getPaymentSummaryList(new List<Contract>{objContract},new List<Pick_Up_Options__c>{pickup})[0]; 
        Product__c product1 = ECM_PaymentSummaryController_Test.getProductList(geographyId1)[0]; 
        Market_Setting__c mktSetting1 = new Market_Setting__c();
        mktSetting1=ECM_PaymentSummaryController_Test.getMktSettingList(geographyId1)[0];  
        Market_Assortment_Product__c marketassort1 = ECM_PaymentSummaryController_Test.getMarketassortList(new List<Product__c>{product1},geographyId1)[0]; 
        ECM_Contract_Item__c newcontractitem1= ECM_PaymentSummaryController_Test.getNewcontractList(new List<Contract> {objContract},new List<Market_Assortment_Product__c>{marketassort1})[0]; 
        Test.startTest();
        ECM_Payment_Summary_Item__c paymemtSummaryItem1 = ECM_PaymentSummaryController_Test.getPaymentSummaryItemList(new List<ECM_Contract_Item__c>{newcontractitem1},new List<ECM_Payment_Summary__c>{paymemtSummary1})[0];
        ECM_Internal_Order__c internalOrder1 = new ECM_Internal_Order__c();
        internalOrder1=ECM_PaymentSummaryController_Test.getInternalOrderList(new List<Product__c>{product1},new List<Pick_Up_Options__c>{pickup},geographyId1)[0];
        List<ECM_Payment_Summary_Item__c> paymemtSummaryItemList = new List<ECM_Payment_Summary_Item__c>();
        paymemtSummaryItemList.add(paymemtSummaryItem1); 
        List<ECM_Payment_Summary__c> paymemtSummaryList = new List<ECM_Payment_Summary__c>();
        paymemtSummaryList.add(paymemtSummary1);
        paymemtSummaryList.add(paymentSummary2);
        List<Id> psIdLst = new List<Id>();
        psIdLst.add(paymemtSummary1.id);
        ECM_Payment_Summary__c psObj=new ECM_Payment_Summary__c();
        psObj=ECM_PaymentSummaryController_Test.getQueriedPaymentSummary(outletAccount,paymemtSummary1,product1); 
        Test.stopTest();
    }
    
     @isTest static void testupdateIOCode(){         
        Id geographyId1 = EDGE_UtilityTestClass.setupCountry('AU');
        System.assert(geographyId1!=null,'Geography ID is Fetched');
        Id uid = userinfo.getUserId();
        List<Account> accounts=ECM_PaymentSummaryController_Test.getAccounts(geographyId1);
        acc1 = accounts[0];
        acc1.country__c = geographyId1;
        update acc1;
        Date myDate1;
        myDate1 = Date.newInstance(2020, 5, 17);
        User usr=ECM_PaymentSummaryController_Test.createSalesRep(uid);
        System.assert(usr.id!=null,'usr id should not be null');
        Territory__c testterritory=ECM_PaymentSummaryController_Test.getTerritory(geographyId1,usr); 
        outletAccount = accounts[0].clone(false,false,false,false);
        outletAccount.Person_Responsible__c= usr.Id;
        outletAccount.OwnerId = usr.Id;   
        outletAccount.Name = 'Test3_Outlet';
        insert outletAccount; 
        ECM_Contract_Type__c contractType=ECM_PaymentSummaryController_Test.getContractTypeList(geographyId1)[0]; 
        Pick_Up_Options__c pickup=ECM_PaymentSummaryController_Test.getBudgetTypeObj(geographyId1);
        Contract objContract=ECM_PaymentSummaryController_Test.getContract(outletAccount,testterritory,contractType);
        objContract.ECM_Banner__c=pickup.Id;
        objContract.Contract_End_Date__c = System.today()+29;
        objContract.StartDate = system.today();
        objContract.Contract_End_Date__c = system.today()+360;
        objContract.Status = 'Active';
        objContract.OwnerId = usr.Id;
        update objContract;
        ECM_Payment_Summary__c paymemtSummary1 =ECM_PaymentSummaryController_Test.getPaymentSummary2List(new List<Contract>{objContract},new List<Pick_Up_Options__c>{pickup})[0];	
         paymemtSummary1.ECM_Additional_Info__c = 'ok';
         update paymemtSummary1;
        ECM_Payment_Summary__c paymensum1;
        paymensum1 = [Select id,ECM_Start_Period__c,ECM_SAP_payment_Reference_Number__c,ECM_Invoice_Receival_Date__c,ECM_Budget_types__c,ECM_Invoice_Status__c,ECM_End_Period__c,ECM_Total_Amount_Confirmed__c,ECM_Type__c,ECM_Payment_Summary_Status__c,ECM_Contract__c from ECM_Payment_Summary__c where id=:paymemtSummary1.Id];    
        geoIDSpain = EDGE_UtilityTestClass.setupCountrySpain('ES');
        Account outletAccount1 = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount = accounts[0].clone(false,false,false,false);
        outletAccount1.Country__c=geoIDSpain;
        outletAccount1.BillingStreet = '17 Asian Highway5 45';
        outletAccount1.Name = 'Test11_Outlet';
        insert outletAccount1;   
        ECM_Payment_Summary__c paymentSummary2 =ECM_PaymentSummaryController_Test.getPaymentSummaryList(new List<Contract>{objContract},new List<Pick_Up_Options__c>{pickup})[0];
        paymentSummary2.ECM_Additional_Info__c = 'ok';
        update paymentSummary2;
        Product__c product1 =ECM_PaymentSummaryController_Test.getProductList(geographyId1)[0]; 
        Market_Setting__c mktSetting1 = new Market_Setting__c();
        mktSetting1=ECM_PaymentSummaryController_Test.getMktSettingList(geographyId1)[0];  
        mktSetting1.ECM_Target__c = 30;
        mktSetting1.ECM_Enable_Target__c =True;
        update mktSetting1;
        Market_Assortment_Product__c marketassort1 = ECM_PaymentSummaryController_Test.getMarketassortList(new List<Product__c>{product1},geographyId1)[0]; 
        ECM_Contract_Item__c newcontractitem1= ECM_PaymentSummaryController_Test.getNewcontractList(new List<Contract> {objContract},new List<Market_Assortment_Product__c>{marketassort1})[0]; 
        List<ECM_Payment_Summary__c> paymemtSummaryList = new List<ECM_Payment_Summary__c>();
        paymemtSummaryList.add(paymemtSummary1);
        paymemtSummaryList.add(paymentSummary2);
        ECM_Payment_Summary__c paymentSummaryRecord = new ECM_Payment_Summary__c();
        paymentSummaryRecord=ECM_PaymentSummaryController_Test.getPaymentSummaryRecordList(paymemtSummaryList)[0];
        Test.startTest();
        ECM_Internal_Order__c internalOrder1 = new ECM_Internal_Order__c();
        internalOrder1=ECM_PaymentSummaryController_Test.getInternalOrderList(new List<Product__c>{product1},new List<Pick_Up_Options__c>{pickup},geographyId1)[0];
        ECM_Payment_Summary_Item__c paymemtSummaryItem1 =ECM_PaymentSummaryController_Test.getPaymentSummaryItemList(new List<ECM_Contract_Item__c>{newcontractitem1},new List<ECM_Payment_Summary__c>{paymemtSummary1})[0];
        List<ECM_Payment_Summary_Item__c> paymemtSummaryItemList = new List<ECM_Payment_Summary_Item__c>();
        paymemtSummaryItemList.add(paymemtSummaryItem1);
        List<Id> psIdLst = new List<Id>();
        psIdLst.add(paymemtSummary1.id);
        ECM_Payment_Summary__c psObj=new ECM_Payment_Summary__c();
        psObj=ECM_PaymentSummaryController_Test.getQueriedPaymentSummary(outletAccount,paymemtSummary1,product1);
         ECM_PaymentSummaryController_Test.testupdateIOCode1(paymemtSummaryList,paymemtSummaryItemList,paymentSummaryRecord);
         TEST.stopTest();
        }
        static void testupdateIOCode1(List<ECM_Payment_Summary__c> paymemtSummaryList, List<ECM_Payment_Summary_Item__c> paymemtSummaryItemList,ECM_Payment_Summary__c paymentSummaryRecord){
        ECM_GetPaymentSummaryDetails paymentsumdetails = new ECM_GetPaymentSummaryDetails();
        paymentsumdetails.geoCountry = geoIDSpain;
        paymentsumdetails.targetObjectId = paymemtSummaryList[0].id;
        paymentsumdetails.getPsDetails();
        paymentsumdetails.getPsItemsDetails();
        paymentsumdetails.getPsItemsInvoiceDetails(); //ECM-6327
        paymentsumdetails.getMsDetails();
        ECM_PaymentSummaryController.handleCsvGeneration(paymemtSummaryList[0].id);
        ECM_PaymentSummaryTriggerHelper.fetchContractDetails(paymemtSummaryList);
        ECM_PaymentSummaryTriggerHelper.updateIOCode(paymemtSummaryList);
        ECM_PaymentSummaryController.getPaymentSummaryDetails(paymemtSummaryList[0].id);
        ECM_PaymentSummaryController.updatePaymentSummary(paymemtSummaryList[0],JSON.serialize(paymemtSummaryItemList));
        ECM_PaymentSummaryController.updatePaymentSummaryAndSubmit(paymentSummaryRecord,JSON.serialize(paymemtSummaryItemList));
        }
    
    @isTest static void afterupdatePSTriggerTest(){
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        
        Profile prof = [select id from profile where name=: 'Sales Representative'];
        User usrmngr = new User();
        usrmngr.firstName = 'testManager';
        usrmngr.lastName = 't2';
        usrmngr.profileId = prof.id;        
        usrmngr.email = 'test.Mamager@test.com';
        usrmngr.Username ='testcmMngr1@test.com';
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
        usr.email = 'test@test.com';
        usr.Username ='testcm12345@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='ES';
        usr.ManagerId = usrmngr.Id;
        insert usr;
        System.assert(usr.id!=null,'user id should not be null');
        
        String accRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();        
        Account outlet = new Account();
        outlet.Name = 'Test4_Outlet';
        outlet.RecordTypeId = accRecordTypeId;
        outlet.BillingStreet = '20 Asian Highway 45';
        outlet.BillingCity = 'Sydney';
        outlet.IsOperator__c=true;
        outlet.BillingState = 'Tasmania';
        outlet.BillingPostalCode = '5668';
        outlet.BillingCountry = 'Australia';
        outlet.BillingCountryCode = 'AU';
        outlet.Outlet_Email_Address__c = 'test@test.com';
        outlet.Global_Channel__c = 'Off Trade';
        outlet.Global_Sub_Channel__c = 'Retailer';
        outlet.Global_Segment__c = 'Hypermarket';
        outlet.Global_Sub_Segment__c = 'Modern Hypermarket';
        outlet.Status__c= 'Active';
        insert outlet;  
        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.BillingStreet = '17 Asian Highway5 45';
        insert acc;
        acc.country__c = geographyId;
        acc.Sales_Org__c ='sale';
        acc.SAP_Sold_to__c ='sapsold';
        update acc;
        
        Contact con = new Contact();
        con.LastName = 'My';
        con.FirstName = 'Test';
        con.Email = 'test@abc.com';
        con.AccountId = acc.id;
        con.Contact_Type__c = 'Primary';
        insert con;
        
        AccountContactRelation accConRel = new AccountContactRelation();
        accConRel.AccountId = outlet.id;
        accConRel.ContactId = con.id;
        accConRel.Contact_Type__c = 'Primary';
        accConRel.IsActive = true;
        insert accConRel;
        
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
        contractType.Volume_UoM_for_Spirits__c='CAS';
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Volume Target;';
        contractType.ECM_Volume_UoM_for_Beer__c = 'KEG';
        contractType.ECM_Volume_UoM_for_RTD__c = 'Can/Bottle 24 Pack';
        contractType.ECM_Volume_UoM_for_Draught_Cocktails__c = '10L BIB';
        insert contractType;
        
        Territory__c testterritory=New Territory__c();
        testterritory.Name='Testterriotory';
        testterritory.Territory_Type__c='Sales';
        testterritory.Country__c= geographyId;
        testterritory.Status__c='Active';
        testterritory.Primary_Sales_Rep__c = usr.id;
        insert testterritory;
        
        String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        Pick_Up_Options__c banner= new Pick_Up_Options__c();
        banner.Name='Range[ES]';
        banner.Geography__c=geographyId;
        banner.RecordTypeId=bannerRecordTypeId;
        insert banner;
        
        String budgetrectypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        Pick_Up_Options__c budgettype= new Pick_Up_Options__c();
        budgettype.Name='Upfront Payment [AU]';
        budgettype.Status__c='Active';
        budgettype.Geography__c=geographyId;
        budgettype.RecordTypeId=budgetrectypeId;
        insert budgettype;
        
        ECM_Payment_Frequency__c paymfreq = new ECM_Payment_Frequency__c();
        paymfreq.ECM_Type__c='At the End of the Contract';
        paymfreq.ECM_Other_Investment__c=true;
        paymfreq.ECM_Volume_target__c=true;
        paymfreq.ECM_Number_of_months_for_recurrence__c='20';
        paymfreq.ECM_From_When_Starts__c='Calendar Year';
        paymfreq.ECM_Geography__c=geographyId;
        Insert paymfreq;
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
        objContract.Status = 'Draft';
        objContract.Contract_End_Date__c = system.today()-1;
        objContract.AccountId=outlet.Id;
        objContract.ECM_Territory__c=testterritory.Id;
        //objContract.ECM_Contract_Type__c=contractType.Id;
        objContract.ECM_Agreement_Type__c=contractType.Id;
        objContract.recordTypeId=contractRecordTypeId;
        objContract.ECM_Channel__c='On-Premise';
        objContract.ECM_Banner__c=banner.Id;
        objContract.StartDate = system.today()-90;
        objContract.ECM_Payment_Frequency_type__c =paymfreq.Id;
        //objContract.Contract_End_Date__c = system.today()+360;
        insert objContract;
        objContract.Status='Active';
        update objContract;
        
        ECM_Payment_Summary__c ps=New ECM_Payment_Summary__c();
        ps.ECM_Type__c='Promo-Standard';
        ps.ECM_Payment_Summary_Status__c='Open';
        ps.ECM_Budget_types__c=budgettype.Id;
        ps.ECM_Start_Period__c =system.today();
        ps.ECM_End_Period__c =system.today()+30;
        ps.ECM_Contract__c=objContract.Id;
        ps.ECM_SAP_Payment_Date__c =system.today();
        ps.ECM_Email_Sent__c =false;
        try{
            insert ps;
            
            ps.ECM_Payment_Summary_Status__c='Completed';
            update ps;
        }
        catch(Exception ex){
            System.debug(LoggingLevel.DEBUG, 'Handled Exception:'+ex);
        }
    }
    @isTest static void getSummaryDetailsTest2(){
        Id geographyId1 = EDGE_UtilityTestClass.setupCountry('AU');
        Id uid = userinfo.getUserId();
        String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();  
        Profile prof = [select id from profile where name=: 'Sales Representative'];
        User usr = new User();
        usr.firstName = 'test1';
        usr.lastName = 'test2';
        usr.profileId = prof.id;        
        usr.email = 'test@test.com';
        usr.Username ='testcm1234@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='ES';
        usr.Title='Legal';
        usr.ManagerId = uid;
        insert usr;
        System.assert(usr.id!=null,'usr id should not be null');
        
        Territory__c testterritory=New Territory__c();
        testterritory.Name='Testterriotory';
        testterritory.Territory_Type__c='Sales';
        testterritory.Country__c= geographyId1;
        testterritory.Status__c='Active';
        testterritory.Primary_Sales_Rep__c = usr.id;
        insert testterritory;
        
        outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Person_Responsible__c= usr.Id;
        outletAccount.OwnerId = usr.Id;
        outletAccount.Country__c = geographyId1;
        outletAccount.BillingStreet = '19 Asian Highway 45';
        outletAccount.Name = 'Test3_Outlet';
        //outletAccount.Operator__c=contractType.id;
        insert outletAccount;         
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Contract objContract = ECM_PaymentSummaryController_Test.getContractforgetSummaryDetailsTest(geographyId1,testterritory,usr); 
        Pick_Up_Options__c pickups=ECM_PaymentSummaryController_Test.getBudgetTypeObj(geographyId1);
               
        ECM_Payment_Summary__c paymemtSummary1 = new ECM_Payment_Summary__c();
        paymemtSummary1.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummary1.ECM_Payment_Summary_Status__c = 'Submitted';
        paymemtSummary1.ECM_Type__c = 'Volume-Based';
        //paymemtSummary1.ECM_Invoice_Status__c='Requested';
        paymemtSummary1.ECM_Contract__c = objContract.id;
        paymemtSummary1.ECM_Start_Period__c = system.today();
        paymemtSummary1.ECM_End_Period__c = system.today()+2;
        paymemtSummary1.ECM_Budget_types__c = pickups.Id;
        paymemtSummary1.ECM_Invoice_Status__c ='Approved';
        paymemtSummary1.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymemtSummary1.ECM_SAP_payment_Reference_Number__c=10;
        paymemtSummary1.ECM_Additional_Info__c = 'ok';
        //PaymemtSummary1.ownerid = uid;
        insert paymemtSummary1;	
        
        ECM_Payment_Summary__c paymensum1;
        paymensum1 = [Select id,ECM_Start_Period__c,ECM_SAP_payment_Reference_Number__c,ECM_Invoice_Receival_Date__c,ECM_Budget_types__c,ECM_Invoice_Status__c,ECM_End_Period__c,ECM_Total_Amount_Confirmed__c,ECM_Type__c,ECM_Payment_Summary_Status__c,ECM_Contract__c
                                             from ECM_Payment_Summary__c where id=:paymemtSummary1.Id];
        
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        Account outletAccount1 = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount1.Person_Responsible__c= usr.Id;
        outletAccount1.OwnerId = usr.Id;
        outletAccount1.Country__c=geographyId;
        outletAccount1.BillingStreet = '17 Asian Highway5 45';
        outletAccount1.Name = 'Test11_Outlet';
        insert outletAccount1;  
       ECM_Contract_Type__c contractType1=new ECM_Contract_Type__c();
        contractType1.Name='Promotional1';
        contractType1.Geography__c=geographyId;
        contractType1.ECM_Abbreviation__c='POM';
        contractType1.ECM_Automatic_approval_amount_threshold__c=40.00;
        contractType1.Volume_UoM_for_Spirits__c='CAS';
        contractType1.ECM_Screen_3_field_configuration__c='Product Name;Volume Target;';
        contractType1.ECM_Volume_UoM_for_Beer__c = 'KEG';
        contractType1.ECM_Volume_UoM_for_RTD__c = 'Can/Bottle 24 Pack';
        contractType1.ECM_Volume_UoM_for_Draught_Cocktails__c = '10L BIB';
        insert contractType1;
        
        Pick_Up_Options__c banner1= new Pick_Up_Options__c();
        banner1.Name='Tile[AU]';
        banner1.Geography__c=geographyId1;
        banner1.RecordTypeId=bannerRecordTypeId;
        insert banner1;
        
        Contract objContract1 = EDGE_UtilityTestClass.getContract(outletAccount1.Id, contractRecordTypeId);
        objContract1.Status = 'Draft';
        objContract1.Contract_End_Date__c = System.today()+29;
        objContract1.AccountId=outletAccount.Id;
        objContract1.ECM_Territory__c=testterritory.Id;
        objContract1.ECM_Overall_Investment_Amount__c=100020.55;
        objContract1.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c=12000934.32;
        objContract1.ECM_Hybrid_CustInvest_Total_PercentGP__c=243123.33;
        objContract1.ECM_Overall_Investment_Figure__c=122.43;
        //objContract.ECM_Contract_Type__c=contractType.Id;
        objContract1.ECM_Agreement_Type__c=contractType1.Id;
        objContract1.recordTypeId=contractRecordTypeId;
        objContract1.ECM_Channel__c='On-Premise';
        objContract1.ECM_Banner__c=banner1.Id;
        objContract1.StartDate = system.today();
        objContract1.Contract_End_Date__c = system.today()+360;
        insert objContract1;
        objContract1.Status = 'Active';
        update objContract1;
        ECM_Payment_Summary__c paymentSummary2 = new ECM_Payment_Summary__c();
        paymentSummary2.ECM_Total_Amount_Confirmed__c = 20.00;
        paymentSummary2.ECM_Payment_Summary_Status__c = 'Submitted';
        paymentSummary2.ECM_Type__c = 'Promo-PrePayment';
        paymentSummary2.ECM_Invoice_Status__c='Requested';
        paymentSummary2.ECM_Contract__c = objContract1.id;
        paymentSummary2.ECM_Start_Period__c = system.today();
        paymentSummary2.ECM_End_Period__c = system.today()+2;
        paymentSummary2.ECM_Budget_types__c = pickups.Id;
        paymentSummary2.ECM_Invoice_Status__c ='Approved';
        paymentSummary2.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymentSummary2.ECM_SAP_payment_Reference_Number__c=10;
        paymentSummary2.ECM_Email_Sent__c =false;
        paymentSummary2.ECM_Additional_Info__c = 'ok';
       // paymentSummary2.ownerid = uid;
        insert paymentSummary2;
        
        Product__c product1 = new Product__c();
        product1.Name='Test';
        product1.Product_Full_Name__c='Test';
        product1.Country__c=geographyId1;
        insert product1;
        Market_Assortment_Product__c marketassort1=ECM_PaymentSummaryController_Test.getMarketAssortmentProductforgetSummaryDetailsTest(geographyId1,geographyId,product1);
         ECM_Internal_Order__c internalOrder1 = new ECM_Internal_Order__c();
        internalOrder1.ECM_Product__c = product1.id;
        internalOrder1.ECM_Active__c = true;
        internalOrder1.ECM_Description__c = 'ABCD';
        internalOrder1.ECM_Budget_Amount__c = 100.00;
        internalOrder1.ECM_Start_Date__c = system.today()-1;
        internalOrder1.ECM_End_Date__c = system.today()+1;
        internalOrder1.ECM_Budget_Type_Pickup_Option__c = pickups.id;
        internalOrder1.ECM_Geography__c = geographyId1;
        internalOrder1.ECM_Auto_Assignment__c = true;
        internalOrder1.ECM_State__c = 'Queensland';
        internalOrder1.Name='123456789101';
        //InternalOrder1.Owner__c = acc1.id;
        insert internalOrder1;
        Depletions__c dep = new Depletions__c();
        dep.ECM_Volume__c = 100.00;
        dep.ECM_Outlet__c = outletAccount.id;
        dep.ECM_Start_Period__c = system.today()+360;
        dep.ECM_End_Period__c = system.today()+29;
        dep.ECM_Product__c = product1.id;
        dep.ECM_Outlet__c = outletAccount.Id;
        insert dep;
        
        ECM_Contract_Item__c newcontractitem1= new ECM_Contract_Item__c();
        newcontractitem1.ECM_Contract__c=objContract.Id;
        newcontractitem1.ECM_Product__c=marketassort1.id;
        insert newcontractitem1;
        
          ECM_Payment_Summary__c paymentSummaryRecord = new ECM_Payment_Summary__c();
            paymentSummaryRecord = [Select Id, Name, ECM_Payment_Summary_Status__c, ECM_Start_Period__c,ECM_End_Period__c,ECM_Contract__r.Status,ECM_Contract__r.Contract_End_Date__c,ECM_Contract__r.StartDate,ECM_Contract__r.Account.Country__c,ECM_Contract__r.RecordTypeId, ECM_Total_to_be_Invoiced__c,ECM_No_Invoice_Required__c, 
                                    ECM_Total_Amount_Forecasted__c, ECM_Total_Amount_Confirmed__c, ECM_Invoice_Receival_Date__c,ECM_Contract__r.Account.SAP_Sold_to__c,ECM_Contract__r.ECM_Agreement_Type__c,ECM_Contract__r.ECM_Territory__c, ECM_UoS_Total__c,ECM_Contract__r.Account.parent_outlet__c,ECM_Additional_Info__c,
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
                                    Where id=:paymemtSummary1.id];
            Test.startTest();
        
        ECM_Payment_Summary_Item__c paymemtSummaryItem1 = new ECM_Payment_Summary_Item__c();
        paymemtSummaryItem1.ECM_Payment_Summary__c = paymemtSummary1.id;
        paymemtSummaryItem1.ECM_Confirm__c = true;
        paymemtSummaryItem1.ECM_Contract_Item__c = newcontractitem1.id;			
        paymemtSummaryItem1.ECM_Confirmed_Amount_Per_Payment__c =10;
        insert paymemtSummaryItem1;
        
    
          
    
        ECM_GetPaymentSummaryDetails paymentsumdetails = new ECM_GetPaymentSummaryDetails();
        paymentsumdetails.geoCountry = geographyId;
        paymentsumdetails.targetObjectId = paymemtSummary1.id;
        paymentsumdetails.getPsDetails();
        paymentsumdetails.getPsItemsDetails();
        paymentsumdetails.getPsItemsInvoiceDetails(); //ECM-6327
        paymentsumdetails.getMsDetails();
       
        ECM_PaymentSummaryController.handleCsvGeneration(paymemtSummary1.id);
        ECM_PaymentSummaryTriggerHelper.fetchContractDetails(new List<ECM_Payment_Summary__c>{paymemtSummary1});
        ECM_PaymentSummaryTriggerHelper.updateIOCode(new List<ECM_Payment_Summary__c>{paymemtSummary1});    
        ECM_PaymentSummaryController.getPaymentSummaryDetails(paymemtSummary1.id);        
        ECM_PaymentSummaryController.updatePaymentSummary(paymemtSummary1,JSON.serialize(new List<ECM_Payment_Summary_Item__c>{paymemtSummaryItem1}));
        ECM_PaymentSummaryController.updatePaymentSummaryAndSubmit(paymentSummaryRecord,JSON.serialize(new List<ECM_Payment_Summary_Item__c>{paymemtSummaryItem1}));
        ECM_PaymentSummaryController.updateInternalOrder(new List<ECM_Internal_Order__c>{internalOrder1});
        TEST.stopTest();
    }

   static Market_Assortment_Product__c getMarketAssortmentProductforgetSummaryDetailsTest(Id geographyId1,Id geographyId,Product__c product1)
   {
       
        List<BusinessHours> bHourList1 = [select id from BusinessHours];
        List<Market_Setting__c> mrktsettinglst = new List<Market_Setting__c>();
        Market_Setting__c mktSetting1 = new Market_Setting__c();
        mktSetting1.Name = 'Market Setting';
        mktSetting1.ECM_Evidence_email_enabled__c=true;
        mktSetting1.Geography__c = geographyId1;
        mktSetting1.Business_Hours__c = bHourList1[0].Id;
        mktSetting1.Minimum_Product_Assortment__c = 'Binary';
        mktSetting1.Minimum_Activation_Standards__c = 'Binary';
        mktSetting1.Distribution__c = 'Binary';
        mktSetting1.New_Product_Distribution__c = 'Progressive';
        mktSetting1.Open_Opportunity__c = 'Calculative';
        mktSetting1.Closed_Opportunity__c = 'Calculative';
        mktSetting1.Outlet_Execution_Score__c = 'Calculative';
        mktSetting1.A_P_Threshold__c=10;
        mktSetting1.Prospect_Approver__c = 'Sales Manager & MDM Approval Required' ;
        mktSetting1.ECM_SAP_Order_Type__c = 'Sap';
        mktSetting1.ECM_Payment_Evidence_Pre_Payment_SP__c='ECM_PaymentSummaryEvidenceRequestPrePySP';
        mktSetting1.ECM_Payment_Evidence_Pre_Payment__c='ECM_PaymentSummaryEvidenceRequestPrePay';
        mktSetting1.ECM_Payment_Evidence_template__c='ECM_PaymentSummaryEvidenceRequestStd';
        mktSetting1.ECM_Payment_Evidence_SP_template__c='ECM_PaymentSummaryEvidenceRequestStdSP';
        mktSetting1.ECM_Payment_Invoice_SP_template__c='ECM_PaymentSummaryInvoiceRequestSP';
        mktSetting1.ECM_Payment_Invoice_template__c='ECM_PaymentSummaryInvoiceRequest';
        mktSetting1.ECM_Manager_Approval__c = 'Promo-Standard;Volume-Based;Promo-PrePayment';
        mktSetting1.ECM_Target__c = 30;
        mktSetting1.ECM_Enable_Target__c =True;
        mrktsettinglst.add(mktSetting1);
        Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(geographyId);
        mrktsettinglst.add(mktSetting);
        insert mrktsettinglst;	
        Market_Assortment_Product__c marketassort1 = new Market_Assortment_Product__c();
        marketassort1.Product__c=product1.Id;
        marketassort1.Market_Assortment__c=geographyId1;
        marketassort1.ECM_INTO_Material__c = 9;
        insert marketassort1;
        return marketassort1;
   }
    
    static Contract getContractforgetSummaryDetailsTest(Id geographyId1,Territory__c testterritory,User usr)
    {
          ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
          contractType.Name='Promotional';
          contractType.Geography__c=geographyId1;
          contractType.ECM_Abbreviation__c='POM';
          contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
          contractType.Volume_UoM_for_Spirits__c='CAS';
          contractType.ECM_Screen_3_field_configuration__c='Product Name;Volume Target;';
          contractType.ECM_Volume_UoM_for_Beer__c = 'KEG';
          contractType.ECM_Volume_UoM_for_RTD__c = 'Can/Bottle 24 Pack';
          contractType.ECM_Volume_UoM_for_Draught_Cocktails__c = '10L BIB';
          contractType.ECM_Language_for_Customer_Email__c = 'fr'; //ECM-6270
          insert contractType;
        
        String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        
        Pick_Up_Options__c banner= new Pick_Up_Options__c();
        banner.Name='Range[ES]';
        banner.Geography__c=geographyId1;
        banner.RecordTypeId=bannerRecordTypeId;
        insert banner;
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Contract objContract = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract.Status = 'Draft';
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
        objContract.ECM_Duration__c = objContract.StartDate.monthsBetween(objContract.Contract_End_Date__c);
        insert objContract;
        objContract.Status = 'Active';
        objContract.OwnerId = usr.Id;
        update objContract;
        return objContract;
    }

}