/*
@Name:- ECM_PaymentSummaryEmailHandlerTest
@Purpose:- Test Class for ECM_PaymentSummaryEmailHandler
@History                                                                                                                  
VERSION 
1.3      Joshraj/Sakshi       04/04/2024        152305
*/
@isTest
public class ECM_PaymentSummaryEmailHandlerTest {
   static Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
   static Id uid = userinfo.getUserId();
   static Date myDate = Date.newInstance(2020, 5, 17);
   static String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
@isTest
    public static void createDataES1(){
        User cioUser = ECM_PaymentSummaryEmailHandlerTest.getUser();
        //Setting up a sales rep user to run test as
        User salesRep = ECM_PaymentSummaryEmailHandlerTest.getSalesRep();
        System.assert(salesRep!=null,'Sales Rep is Added');
        List<Account> accounts = new List<Account>();
        accounts = ECM_PaymentSummaryEmailHandlerTest.getAccounts();
        Contact con = ECM_PaymentSummaryEmailHandlerTest.getCon(accounts);
        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        insert contractType;
        List<Contract> contractlst =new List<Contract>();
        contractlst = ECM_PaymentSummaryEmailHandlerTest.getContractlst(contractType,salesRep,accounts);
        AccountContactRelation acr = new AccountContactRelation();
        acr=ECM_PaymentSummaryEmailHandlerTest.getAcr(accounts,con);
        List<Pick_Up_Options__c> budgetTypeObjList = ECM_PaymentSummaryEmailHandlerTest.getBudgetTypeObjList();
        List<ECM_Payment_Summary__c> paymemtSummaryList = ECM_PaymentSummaryEmailHandlerTest.getPaymemtSummaryList(contractlst,budgetTypeObjList);
        ECM_Payment_Summary__c paymentSummaryRecord = new ECM_Payment_Summary__c();
        paymentSummaryRecord = ECM_PaymentSummaryController.getPaymentSummary(paymemtSummaryList[0].Id);
         Test.startTest();
         Product__c product = ECM_PaymentSummaryEmailHandlerTest.getProduct();
         Market_Setting__c mktSetting = ECM_PaymentSummaryEmailHandlerTest.getMktSetting();
         system.debug(LoggingLevel.Debug,mktSetting);
        /* Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(geographyId);
mktSetting.ECM_Evidence_email_enabled__c=true;
insert mktSetting;
*/      Market_Assortment_Product__c marketassort = ECM_PaymentSummaryEmailHandlerTest.getMarketAssort(product);
        ECM_Contract_Item__c newcontractitem = ECM_PaymentSummaryEmailHandlerTest.getNewcontractitem(contractlst,marketassort);
        ECM_Tiering__c tier= new ECM_Tiering__c();
        tier=ECM_PaymentSummaryEmailHandlerTest.getTier(newcontractitem);
        ECM_Internal_Order__c internalOrder = new ECM_Internal_Order__c();
        internalOrder=ECM_PaymentSummaryEmailHandlerTest.getInternalOrder(product,budgetTypeObjList);
        List<ECM_Payment_Summary_Item__c> paymemtSummaryItemList=new List<ECM_Payment_Summary_Item__c>();
        paymemtSummaryItemList = ECM_PaymentSummaryEmailHandlerTest.getPaymemtSummaryItemList(newcontractitem,paymemtSummaryList);
        List<Id> psIdLst = new List<Id>();
        psIdLst.add(paymemtSummaryList[0].id); 
        map<id,ECM_Payment_Summary__c> newMap = new map<id,ECM_Payment_Summary__c>();
        newMap.put(paymentSummaryRecord.Id,paymentSummaryRecord);
        map<id,ECM_Payment_Summary__c> oldMap = new map<id,ECM_Payment_Summary__c>();
        //ECM_PaymentSummaryTriggerHelper.fetchContractDetails(new List<ECM_Payment_Summary__c> {paymemtSummary});
        paymemtSummaryList[0].ECM_Payment_Summary_Status__c = 'In Approval Process';
        paymemtSummaryList[0].ECM_Approval_Sub_Status__c=Label.ECM_In_Manager_Approval;
        update paymemtSummaryList[0];
        oldMap.put(paymemtSummaryList[0].Id, paymemtSummaryList[0]);
        ECM_PaymentSummaryEmailHandlerTest.createDataES12(paymemtSummaryList,cioUser,salesRep);
    }
    public static void createDataES12(List<ECM_Payment_Summary__c> paymemtSummaryList,User cioUser,User salesRep){
            // Create an approval request for the account
            Approval.ProcessSubmitRequest apprReq = new Approval.ProcessSubmitRequest();
            apprReq.setComments('Submitting request for approval.');
            apprReq.setObjectId(paymemtSummaryList[0].id);
            apprReq.setNextApproverIds(new List<Id>{uid});
        // Submit on behalf of a specific submitter
        apprReq.setSubmitterId(salesRep.Id); 
        // Submit the record to specific process and skip the criteria evaluation
        apprReq.setSkipEntryCriteria(true);
        // Submit the approval request for the account
        Approval.ProcessResult result = Approval.process(apprReq);
        // Verify the result
        System.assert(result.isSuccess(),'Result Status :'+result.isSuccess());
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
            paymemtSummaryList[0].ECM_Payment_Summary_Status__c = 'Submitted';
            paymemtSummaryList[0].ECM_Approval_Sub_Status__c = Label.ECM_CIO_Approval;
            update paymemtSummaryList[0];
        Approval.ProcessSubmitRequest apprReq1 = new Approval.ProcessSubmitRequest();
        apprReq1.setComments('Submitting request for approval.');
        apprReq1.setObjectId(paymemtSummaryList[0].id);
        apprReq1.setNextApproverIds(new List<Id>{cioUser.Id});
        // Submit on behalf of a specific submitter
        apprReq1.setSubmitterId(uid); 
        // Submit the record to specific process and skip the criteria evaluation
        apprReq1.setSkipEntryCriteria(true);
        // Submit the approval request for the account
        Approval.ProcessResult result1 = Approval.process(apprReq1);
        // Verify the result
        System.assert(result1.isSuccess(),'Result Status:'+result1.isSuccess());
        System.assertEquals(
            'Pending', result1.getInstanceStatus(), 
            'Instance Status'+result1.getInstanceStatus());
        //ECM_PaymentSummaryTriggerHelper.checkForCIOApproval(oldMap.values());
        //sendEmail
        ECM_PaymentSummaryEmailHandler.sendEmail(new list<id>{paymemtSummaryList[0].Id});
        ECM_PaymentSummaryEmailHandler.sendEmail(new list<id>{paymemtSummaryList[3].Id});
        ECM_PaymentSummaryEmailHandler.sendInvEmail(new list<id>{paymemtSummaryList[0].Id}); 
        }
        
    public static User getUser(){
        User cioUser =   ECM_UtilityTestClass.createUser('cio',ECM_UtilityTestClass.getProfile('CIO User').Id);
        cioUser.Username = 'cioUser1234@test.com';
        insert cioUser;
        return cioUser;
    }
    public static User getSalesRep(){
        User salesRep = ECM_UtilityTestClass.createUser('srp',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
        salesRep.Username = 'salesRp1234@test.com';
        salesRep.isActive=true;
        salesRep.managerid=uid;
        insert salesRep;
        return salesRep;
    }
    public static List<Account> getAccounts(){
        List<Account> accounts = new List<Account>();
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.BillingStreet = '17 Asian Highway1 45';
        acc.Email_for_contracts_payments__c='test.test@diageo.com';
        insert acc;
        acc.country__c = geographyId;
        acc.Sales_Org__c ='sale';
        acc.SAP_Sold_to__c ='sapsold';
        update acc;
        accounts.add(acc);
        Account acc1 = EDGE_UtilityTestClass.getDistriAccRec();
        acc1.country__c = geographyId;
        insert acc1;
        accounts.add(acc1);
        return accounts;
    }
    public static Contact getCon(List<Account> accounts){
        Contact con = new Contact();
        con.LastName = 'My';
        con.FirstName = 'Test';
        con.Email = 'test@abc.com';
        con.AccountId = accounts[1].id;
        con.Contact_Type__c = 'Primary';
        insert con;
        return con;
    }
    public static List<Contract> getContractlst(ECM_Contract_Type__c contractType,User salesRep,List<Account> accounts){
        List<Contract> contractlst =new List<Contract>();
        Contract contr = new Contract(Name = 'Test',AccountId = accounts[0].id,StartDate=myDate.addMonths(-6).toStartOfMonth(),Contract_End_Date__c=myDate.addMonths(1).toStartOfMonth().addDays(-1),ECM_Duration__c=myDate.addMonths(-6).toStartOfMonth().monthsBetween(myDate.addMonths(1).toStartOfMonth()),ECM_Agreement_Type__c=contractType.Id);
        contr.OwnerId = salesRep.Id;
        contractlst.add(contr); 
        Contract contr1 = new Contract(Name = 'Test1',AccountId = accounts[0].id,StartDate=myDate.addMonths(-6).toStartOfMonth(),Contract_End_Date__c=myDate.addMonths(1).toStartOfMonth().addDays(-1),ECM_Duration__c=myDate.addMonths(-6).toStartOfMonth().monthsBetween(myDate.addMonths(1).toStartOfMonth()));
        contractlst.add(contr1);
        insert contractlst;
        contr.Status = 'Active';
        update contr;
        return contractlst;
    }
    public static AccountContactRelation getAcr(List<Account> accounts,Contact con){
        AccountContactRelation acr = new AccountContactRelation();
        acr.AccountId = accounts[0].id;
        acr.ContactId = con.id;
        acr.Contact_Type__c = 'Primary';
        acr.IsActive = true;
        insert acr;
        return acr;
    }
    public static List<Pick_Up_Options__c>  getBudgetTypeObjList(){
        List<Pick_Up_Options__c> budgetTypeObjList = new List<Pick_Up_Options__c>();
        Pick_Up_Options__c budgetTypeObj= ECM_UtilityTestClass.createPickUpOption(geographyId,BannerRecordTypeId);
        budgetTypeObj.Name='TI[ES]';
        budgetTypeObj.Geography__c=geographyId;
        budgetTypeObj.ECM_SAP_Order_reason__c = 'Y10'; 
        budgetTypeObj.ECM_SAP_Pricing_condition__c = 'O25';
        budgetTypeObjList.add(budgetTypeObj);
        Pick_Up_Options__c budgetTypeObj2= new Pick_Up_Options__c();
        budgetTypeObj2.Name='On-Premise[AU]';
        budgetTypeObj2.Geography__c=geographyId;
        budgetTypeObj2.RecordTypeId=Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        budgetTypeObj2.ECM_SAP_Order_reason__c = 'Y10'; 
        budgetTypeObj2.ECM_SAP_Pricing_condition__c = 'O25';
        budgetTypeObjList.add(budgetTypeObj2);
        insert budgetTypeObjList;
        return budgetTypeObjList;
    }
    public static List<ECM_Payment_Summary__c> getPaymemtSummaryList(List<Contract> contractlst,List<Pick_Up_Options__c> budgetTypeObjList){
        List<ECM_Payment_Summary__c> paymemtSummaryList = new List<ECM_Payment_Summary__c>();
        ECM_Payment_Summary__c paymemtSummary = new ECM_Payment_Summary__c();
        paymemtSummary.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummary.ECM_Payment_Summary_Status__c = 'Open';
        paymemtSummary.ECM_Type__c = 'Promo-Standard';
        paymemtSummary.ECM_Invoice_Status__c='Requested';
        paymemtSummary.ECM_Contract__c = contractlst[0].id;
        paymemtSummary.ECM_Start_Period__c = system.today();
        paymemtSummary.ECM_End_Period__c = system.today()+2;
        paymemtSummary.ECM_Budget_types__c = budgetTypeObjList[0].id;
        paymemtSummary.ECM_Invoice_Status__c ='Approved';
        paymemtSummary.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymemtSummary.ECM_approval_sub_status__C = 'Manager Approval';
        paymemtSummary.ECM_Manager_Approver__c=userinfo.getUserId();
        paymemtSummary.ECM_Tax_Rate__c='Standard Rate';
        paymemtSummary.ECM_Recommended_IO_Code__c='MHJ0WACF6900';
        paymemtSummaryList.add(paymemtSummary);  
        ECM_Payment_Summary__c paymemtSummary2 = new ECM_Payment_Summary__c();
        paymemtSummary2.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummary2.ECM_Payment_Summary_Status__c = 'Submitted';
        paymemtSummary2.ECM_Type__c = 'Volume-Based';
        paymemtSummary2.ECM_Invoice_Status__c='Requested';
        paymemtSummary2.ECM_Contract__c = contractlst[0].id;
        paymemtSummary2.ECM_Start_Period__c = system.today();
        paymemtSummary2.ECM_End_Period__c = system.today()+2;
        paymemtSummary2.ECM_Budget_types__c = budgetTypeObjList[0].id;
        paymemtSummary2.ECM_Invoice_Status__c ='Approved';
        paymemtSummary2.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymemtSummary2.ECM_SAP_payment_Reference_Number__c=10;
        paymemtSummary2.ECM_Email_Sent__c =false;
        //paymemtSummary2.ownerid = uid;
        paymemtSummaryList.add(paymemtSummary2); 
        ECM_Payment_Summary__c paymemtSummary3 = new ECM_Payment_Summary__c();
        paymemtSummary3.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummary3.ECM_Payment_Summary_Status__c = 'Submitted';
        paymemtSummary3.ECM_Type__c = 'Non-Volume';
        paymemtSummary3.ECM_Invoice_Status__c='Requested';
        paymemtSummary3.ECM_Contract__c = contractlst[0].id;
        paymemtSummary3.ECM_Start_Period__c = system.today();
        paymemtSummary3.ECM_End_Period__c = system.today()+2;
        paymemtSummary3.ECM_Budget_types__c = budgetTypeObjList[0].id;
        //paymemtSummary3.ECM_Invoice_Status__c ='Approved';
        paymemtSummary3.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymemtSummary3.ECM_SAP_payment_Reference_Number__c=10;
        paymemtSummary3.ECM_Email_Sent__c =false;
        //PaymemtSummary3.ownerid = uid;
        paymemtSummaryList.add(paymemtSummary3);
        ECM_Payment_Summary__c paymemtSummary4 = new ECM_Payment_Summary__c();
        paymemtSummary4.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummary4.ECM_Payment_Summary_Status__c = 'Submitted';
        paymemtSummary4.ECM_Type__c = 'Promo-Prepayment';
        paymemtSummary4.ECM_Invoice_Status__c='Requested';
        paymemtSummary4.ECM_Contract__c = contractlst[0].id;
        paymemtSummary4.ECM_Start_Period__c = system.today();
        paymemtSummary4.ECM_End_Period__c = system.today()+2;
        paymemtSummary4.ECM_Budget_types__c = budgetTypeObjList[0].id;
        //paymemtSummary3.ECM_Invoice_Status__c ='Approved';
        paymemtSummary4.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymemtSummary4.ECM_SAP_payment_Reference_Number__c=10;
        paymemtSummary4.ECM_Email_Sent__c =false;
        //PaymemtSummary3.ownerid = uid;
        paymemtSummaryList.add(paymemtSummary4);
        insert paymemtSummaryList;
        return paymemtSummaryList;
    }
    public static Product__c getProduct(){
        Product__c product = new Product__c();
        product.Name='Test';
        product.Product_Full_Name__c='Test';
        product.Country__c=geographyId;
        insert product;
        return product;
     }
     public static  Market_Setting__c getMktSetting(){
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
        return mktSetting;
     }
     public static Market_Assortment_Product__c getMarketAssort(Product__c product){
        Market_Assortment_Product__c marketassort = new Market_Assortment_Product__c();
        marketassort.Product__c=product.Id;
        marketassort.Market_Assortment__c=geographyId;
        marketassort.ECM_INTO_Material__c = 9;
        insert marketassort;
        return marketassort;
    }
    public static ECM_Contract_Item__c getNewcontractitem(List<Contract> contractlst,Market_Assortment_Product__c marketassort){
        ECM_Contract_Item__c newcontractitem= new ECM_Contract_Item__c();
        newcontractitem.ECM_Contract__c=contractlst[0].Id;
        newcontractitem.ECM_Product__c=marketassort.id;
        insert newcontractitem;
        return newcontractitem;
    }
    public static ECM_Tiering__c getTier(ECM_Contract_Item__c newcontractitem){
        ECM_Tiering__c tier= new ECM_Tiering__c();
        tier.ECM_Contract_Item__c=newcontractitem.Id;
        tier.ECM_Tier_1_rate_per_UoM__c=1.00;
        tier.ECM_Tier_1_volume_limit__c=1;
        tier.ECM_Tier2_rate_per_UoM__c=2.00;
        tier.ECM_Tier_2_volume_limit__c=2;
        tier.ECM_Tier_3_rate_per_UoM__c=3.00;
        tier.ECM_Tier_3_volume_limit__c=3;
        insert tier;
        return tier;
    }
    public static List<ECM_Payment_Summary_Item__c> getPaymemtSummaryItemList(ECM_Contract_Item__c newcontractitem, List<ECM_Payment_Summary__c> paymemtSummaryList){
        List<ECM_Payment_Summary_Item__c> paymemtSummaryItemList =new List<ECM_Payment_Summary_Item__c>();
        ECM_Payment_Summary_Item__c paymemtSummaryItem = new ECM_Payment_Summary_Item__c();
        paymemtSummaryItem.ECM_Payment_Summary__c = paymemtSummaryList[0].id;
        paymemtSummaryItem.ECM_Confirm__c = true;
        paymemtSummaryItem.ECM_Contract_Item__c = newcontractitem.id;			
        paymemtSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
        paymemtSummaryItemList.add(paymemtSummaryItem);
        insert paymemtSummaryItemList;
        return paymemtSummaryItemList;
        }
        public static ECM_Internal_Order__c getInternalOrder(Product__c product,List<Pick_Up_Options__c> budgetTypeObjList){
            ECM_Internal_Order__c internalOrder = new ECM_Internal_Order__c();
            internalOrder.ECM_Product__c = product.id;
            internalOrder.ECM_Active__c = true;
            internalOrder.ECM_Description__c = 'ABCD';
            internalOrder.ECM_Budget_Amount__c = 100.00;
            internalOrder.ECM_Start_Date__c = system.today();
            internalOrder.ECM_End_Date__c = system.today()+1;
            internalOrder.ECM_Budget_Type_Pickup_Option__c = budgetTypeObjList[0].id;
            internalOrder.ECM_Geography__c = geographyId;
            internalOrder.ECM_Auto_Assignment__c = true;
            internalOrder.Name='123456789101';
            insert internalOrder;
            return internalOrder;
        }
}