/**********************************************************************
Name: ECM_PaymentSummaryCsvExportHandler_Test
=======================================================================
Purpose: This class is used to cover test data for the - ECM_PaymentSummaryCsvExportHandler
=======================================================================
History                                                            
-------                                                            
VERSION    AUTHOR                   DATE              DETAIL
1.0      Inayathulla Md      19/05/2020        Initial Development

***********************************************************************/
@istest
public class ECM_PaymentSummaryCsvExportHandler_Test {
    @isTest
    static void getSummaryDetailsTest(){
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        Geography__c geo = new Geography__c(id=geographyId,ECM_SAP_Plant_for_Payment_File__c='Test');
        update geo;
        Id uid;
        uid = userinfo.getUserId();
        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        insert acc;
        System.assert(acc!=null,'acc should not be null');
        acc.country__c = geographyId;
        update acc;
        
        Account acc1 = EDGE_UtilityTestClass.getDistriAccRec();
        insert acc1;
        
        Contact con = new Contact();
        con.LastName = 'My';
        con.FirstName = 'Test';
        con.Email = 'test@abc.com';
        con.AccountId = acc1.id;
        con.Contact_Type__c = 'Primary';
        insert con;
        Date myDate = Date.newInstance(2020, 5, 17);
        List<Contract> contractlst =new List<Contract>();
        Contract contr = new Contract(Name = 'Test',AccountId = acc.id,Contract_End_Date__c=myDate);
        contractlst.add(contr); 
        Contract contr1 = new Contract(Name = 'Test1',AccountId = acc.id,Contract_End_Date__c=myDate);
        contractlst.add(contr1);
        insert contractlst;  
        AccountContactRelation acr = new AccountContactRelation();
        acr.AccountId = acc.id;
        acr.ContactId = con.id;
        acr.Contact_Type__c = 'Primary';
        acr.IsActive = true;
        insert acr;
        String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        
        Pick_Up_Options__c budgetTypeObj= new Pick_Up_Options__c();
        budgetTypeObj.Name='TI[ES]';
        budgetTypeObj.Geography__c=geographyId;
        budgetTypeObj.RecordTypeId=bannerRecordTypeId;
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
        paymemtSummary.ECM_Payment_Summary_Status__c = 'Approved';
        paymemtSummary.ECM_Type__c = 'Promo-Standard';
        paymemtSummary.ECM_Invoice_Status__c='Requested';
        paymemtSummary.ECM_Contract__c = contr.id;
        paymemtSummary.ECM_Start_Period__c = system.today();
        paymemtSummary.ECM_End_Period__c = system.today()+2;
        paymemtSummary.ECM_Budget_types__c = budgetTypeObj.id;
        paymemtSummary.ECM_Invoice_Status__c ='Approved';
        paymemtSummary.ECM_Invoice_Receival_Date__c = system.today()+1;
        insert paymemtSummary;
        
        Product__c product = new Product__c();
        product.Product_Full_Name__c='Test';
        product.Country__c=geographyId;
        insert product;
        
        Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(geographyId);
        insert mktSetting;
        
        Market_Assortment_Product__c marketassort = new Market_Assortment_Product__c();
        marketassort.Product__c=product.Id;
        marketassort.Market_Assortment__c=geographyId;
        insert marketassort;
        
        ECM_Contract_Item__c newcontractitem= new ECM_Contract_Item__c();
        newcontractitem.ECM_Contract__c=contr.Id;
        newcontractitem.ECM_Product__c=marketassort.id;
        insert newcontractitem;
        
        ECM_Payment_Summary_Item__c paymemtSummaryItem = new ECM_Payment_Summary_Item__c();
        paymemtSummaryItem.ECM_Payment_Summary__c = paymemtSummary.id;
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
        internalOrder.Name='Order1234567';
        insert internalOrder;
        
        List<ECM_Payment_Summary_Item__c> paymemtSummaryItemList = new List<ECM_Payment_Summary_Item__c>();
        paymemtSummaryItemList.add(paymemtSummaryItem);
        
        List<ECM_Payment_Summary__c> paymemtSummaryList = new List<ECM_Payment_Summary__c>();
        paymemtSummaryList.add(paymemtSummary);
        List<Id> psIdLst = new List<Id>();
        psIdLst.add(paymemtSummary.id);
        
        ECM_PaymentSummaryCsvExportHandler.sendEmail(psIdLst);
    }
    @isTest
    static void getSummaryDetailsTest1(){
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
       // Geography__c geo = new Geography__c(id=geographyId,ECM_SAP_Plant_for_Payment_File__c='Test');
        //update geo;
        Id uid;
        uid = userinfo.getUserId();
        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        insert acc;
        System.assert(acc!=null,'acc should not be null');
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
        Date myDate = Date.newInstance(2020, 5, 17);
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
        contractType.Volume_UoM_for_Spirits__c='CAS';
        contractType.ECM_Screen_3_field_configuration__c = 'UoM';
        insert contractType;
        
        List<Contract> contractlst =new List<Contract>();
        Contract contr = new Contract(Name = 'Test',AccountId = acc.id,ECM_Agreement_Type__c=contractType.id,Contract_End_Date__c=myDate);
        contractlst.add(contr); 
        Contract contr1 = new Contract(Name = 'Test1',AccountId = acc.id,ECM_Agreement_Type__c=contractType.id,Contract_End_Date__c=myDate);
        contractlst.add(contr1);
        insert contractlst;  
        AccountContactRelation acr = new AccountContactRelation();
        acr.AccountId = acc.id;
        acr.ContactId = con.id;
        acr.Contact_Type__c = 'Primary';
        acr.IsActive = true;
        insert acr;
        String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        
        Pick_Up_Options__c budgetTypeObj= new Pick_Up_Options__c();
        budgetTypeObj.Name='TI[ES]';
        budgetTypeObj.Geography__c=geographyId;
        budgetTypeObj.RecordTypeId=bannerRecordTypeId;
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
        paymemtSummary.ECM_Payment_Summary_Status__c = 'Approved';
        paymemtSummary.ECM_Type__c = 'Promo-Standard';
        paymemtSummary.ECM_Invoice_Status__c='Requested';
        paymemtSummary.ECM_Contract__c = contr.id;
        paymemtSummary.ECM_Start_Period__c = Date.newInstance(System.today().year(), 5, 17);
        paymemtSummary.ECM_End_Period__c = Date.newInstance(System.today().year(), 10, 17);
        paymemtSummary.ECM_Budget_types__c = budgetTypeObj.id;
        paymemtSummary.ECM_Invoice_Status__c ='Approved';
        paymemtSummary.ECM_Fiscal_Years__c = 'FY'+String.valueOf(System.today().year()).subString(2,4);
        //paymemtSummary.ECM_Invoice_Receival_Date__c = system.today()+1;
        insert paymemtSummary;
        
        Product__c product = new Product__c();
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
        insert mktSetting;
        
        /* Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(geographyId);
mktSetting.
insert mktSetting;*/
        
        Market_Assortment_Product__c marketassort = new Market_Assortment_Product__c();
        marketassort.Product__c=product.Id;
        marketassort.Market_Assortment__c=geographyId;
        marketassort.ECM_INTO_Material__c = 9;
        insert marketassort;
        
        ECM_Contract_Item__c newcontractitem= new ECM_Contract_Item__c();
        newcontractitem.ECM_Contract__c=contr.Id;
        newcontractitem.ECM_Product__c=marketassort.id;
        insert newcontractitem;
        
        ECM_Payment_Summary_Item__c paymemtSummaryItem = new ECM_Payment_Summary_Item__c();
        paymemtSummaryItem.ECM_Payment_Summary__c = paymemtSummary.id;
        paymemtSummaryItem.ECM_Confirm__c = true;
        paymemtSummaryItem.ECM_Contract_Item__c = newcontractitem.id;			
        //paymemtSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
        insert paymemtSummaryItem;
        try{
            ECM_Internal_Order__c internalOrder = new ECM_Internal_Order__c();
            internalOrder.ECM_Product__c = product.id;
            internalOrder.ECM_Active__c = true;
            internalOrder.ECM_Description__c = 'ABCD';
            internalOrder.ECM_Budget_Amount__c = 100.00;
            internalOrder.ECM_Start_Date__c = system.today();
            internalOrder.ECM_End_Date__c = system.today()+1;
            internalOrder.ECM_Fiscal_Year__c = 'FY20';
            internalOrder.ECM_Budget_Type_Pickup_Option__c = budgetTypeObj.id;
            internalOrder.ECM_Geography__c = geographyId;
            internalOrder.ECM_Auto_Assignment__c = true;
            internalOrder.Name = 'Order0123456';
            insert internalOrder;
            ECM_Internal_Order__c internalOrder1 = new ECM_Internal_Order__c();
            internalOrder1.ECM_Product__c = product.id;
            internalOrder1.ECM_Active__c = true;
            internalOrder1.ECM_Description__c = 'ABCD';
            internalOrder1.ECM_Budget_Amount__c = 100.00;
            internalOrder1.ECM_Start_Date__c = Date.newInstance(System.today().year(), 5, 17);
            internalOrder1.ECM_End_Date__c = Date.newInstance(System.today().year(), 10, 17);
            internalOrder1.ECM_Budget_Type_Pickup_Option__c = budgetTypeObj.id;
            internalOrder1.ECM_Fiscal_Year__c = 'FY21';
            internalOrder1.ECM_Geography__c = geographyId;
            internalOrder1.ECM_Auto_Assignment__c = true;
            internalOrder1.Name = 'Order0012345';
        insert internalOrder1;
        }catch(Exception ex){
            system.debug(LoggingLevel.Debug,'exception ='+ex);
        }
        
        
        List<ECM_Payment_Summary_Item__c> paymemtSummaryItemList = new List<ECM_Payment_Summary_Item__c>();
        paymemtSummaryItemList.add(paymemtSummaryItem);
        
        List<ECM_Payment_Summary__c> paymemtSummaryList = new List<ECM_Payment_Summary__c>();
        paymemtSummaryList.add(paymemtSummary);
        List<Id> psIdLst = new List<Id>();
        psIdLst.add(paymemtSummary.id);
		       
        ECM_PaymentSummaryCsvExportHandler.sendEmail(psIdLst);
    }
}