/*
*@Name: ECM_ReviewAndSubmitControllerTest
*@Description: This class is used to cover test data for the - ECM_ReviewAndSubmitController,ECM_CreatePaymentSummaryController,ECM_GetContractItemDetails
*@History                                                            

VERSION    AUTHOR                   DATE              DETAIL
1.0      Inayathulla Md      16/04/2020        Initial Development
2.0		 Saurav Prasad		 23/08/2021		   ECM-4689 Email Templates for Product level investment exceeding threshold
2.1		 Saurav Prasad		 22/12/2021		   ECM-5067 - CLONE - Tech Debt_Work on test CLS to maintain best practice_GLO_Part 2
2.2		 Nikhilesh Chandak	 13/09/2022		   ECM-5952 Added testMethodForEmailTemplateGB
2.3      Joshraj Sen         03/04/2024        SCA Fix 152305
*/
@istest
public class ECM_ReviewAndSubmitControllerTest {
    
    static Account outletAccount =new Account();
    static Territory__c testterritory=new Territory__c();
    static User getUser()
    {
        Profile prof = [select id from profile where name=: 'Sales Representative'];
        User usr = ECM_UtilityTestClass.createUser('testcm12345@test.com',prof.Id);
        usr.firstName = 'test1';
        usr.Title='Legal';
        insert usr;
        return usr;
    }
    static Territory_Hierarchy__c getRegion(Id geographyId)
    {
        Territory_Hierarchy__c hirarchy= ECM_UtilityTestClass.createhirarchy(geographyId);
        hirarchy.recordtypeId=Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Activation Territory').getRecordTypeId();
        insert hirarchy;
        return hirarchy;
    }
    static Territory__c getTerritory(Id geographyId,Territory_Hierarchy__c hirarchy,User usr)
    {
        Territory__c testterritory=ECM_UtilityTestClass.createTerritory(geographyId);
        testterritory.Primary_Sales_Rep__c = usr.id;
        testterritory.Activation_Territory__c = hirarchy.Id;
        insert testterritory;
        return testterritory;
        
    }
    static Pick_Up_Options__c getBudgetTypeES(Id geographyId)
    {
        String bRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        Pick_Up_Options__c budjectEU= ECM_UtilityTestClass.createPickUpOption(geographyId,bRecordTypeId);
        budjectEU.Name='TI [ES]';
        insert budjectEU;
        return budjectEU;
    }
    static Pick_Up_Options__c getBudgetTypeGB(Id geographyId)
    {
        String bRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        Pick_Up_Options__c budjectEU= ECM_UtilityTestClass.createPickUpOption(geographyId,bRecordTypeId);
        budjectEU.Name='TI [GB]';
        insert budjectEU;
        return budjectEU;
    }
    static Territory_Budget__c getTerritoryBudgets(Territory__c testterritory,Territory_Hierarchy__c hirarchy,Pick_Up_Options__c budjectEU)
    {
        Territory_Budget__c terriBudget1 = ECM_UtilityTestClass.createTerritoryBudget(testterritory.Id, hirarchy.Id);
        terriBudget1.ECM_Budget_Type__c=budjectEU.Id;
        insert terriBudget1;
        return terriBudget1;
    }
    static ECM_Contract_Type__c getContractTypes(Id geographyId)
    {
        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.getAgreementType(geographyId);
        contractType = ECM_UtilityTestClass.getAgreementType(geographyId);
        contractType.ECM_Volume_UoM_for_Beer__c='EU';
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;Volume Target;Investment';
        contractType.ECM_Volume_UoM_for_RTD__c = 'Can/Bottle 24 Pack';
        contractType.ECM_Volume_UoM_for_Draught_Cocktails__c = '10L BIB';
        contractType.ECM_Contract_Approval_mail_to_Customer__c=true;
        insert contractType;
        return contractType;
    }
     static Pick_Up_Options__c getBannerES(Id geographyId)
    {
        String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();    
        Pick_Up_Options__c banner= ECM_UtilityTestClass.createPickUpOption(geographyId,bannerRecordTypeId);
        banner.Name='Range[ES]';
        insert banner;
        return banner;
    }
    static Pick_Up_Options__c getBannerGB(Id geographyId)
    {
        String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();    
        Pick_Up_Options__c banner= ECM_UtilityTestClass.createPickUpOption(geographyId,bannerRecordTypeId);
        banner.Name='Range[GB]';
        insert banner;
        return banner;
    }
    static Market_Setting__c getMarketSetting(Id geographyId)
    {
        Market_Setting__c mktSetting = EDGE_UtilityTestClass.getMarketSetting(geographyId);
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
        mktSetting.ECM_Contract_Approval_Template__c='ECM_Contract_Approval_Template';
        mktSetting.ECM_Contract_Header_Details__c='ECM_Contract_Owner__c;ECM_Territory__r.Name;Account.ECM_Legal_Name__c;Account.Name;ECM_Agreement_Type__r.Name;StartDate;Contract_End_Date__c;ContractNumber;Name;Account.SAP_Ship_to__c;Account.SAP_Sold_to__c;ECM_Primary_Spirit_Distributor__r.Name;ECM_Secondary_Spirit_Distributor__r.Name;ECM_Primary_Beer_Distributor__r.Name';
        mktSetting.ECM_Investment_Summary_KPIS__c='ECM_Total_Volume_Target_Spirits__c;ECM_Total_Volume_Target_Beers__c;ECM_Incremental_Volume_Spirits__c;ECM_Incremental_Volume_Beers__c;ECM_Total_trade_investment_Beers__c;ECM_Total_A_P_Investment_Spirits__c;ECM_Incremental_GP__c;ECM_Incremental_GP_Beers__c';
        mktSetting.ECM_Category_Split_KPIS__c='ECM_NSV_reserve_share__c;ECM_NSV_premium_core_share__c;ECM_GP_reserve_share__c;ECM_GP_innovation_share__c;ECM_GM_reserve_share__c;ECM_GM_innovation_share__c;ECM_GM_premium_core_share__c;ECM_TV_reserve_share__c;ECM_TV_premium_core_share__c;ECM_IV_reserve_share__c;ECM_IV_innovation_share__c;ECM_IV_premium_core_share__c';
        mktSetting.ECM_Product_Investment_Details__c='ECM_Retro_investment__c;ECM_Trade_Investments__c;ECM_AnP_investment__c;ECM_Gross_margin__c;ECM_Total_GP_EU__c;ECM_Generated_NSV_EU__c;ECM_NSV_After_Investment__c;ECM_Incremental_GP_after_Investment__c;Tiers;ECM_UoM__c;ECM_Baseline_volume__c;ECM_Volume__c;ECM_Incremental_Volume__c;ECM_CAAP_Total__c;ECM_Product_growth_driver__c';
        mktSetting.ECM_Sales_Drivers_Details__c='ECM_Investement_Description__c;ECM_Budget_Type__c;ECM_Payment_Frequency__r.ECM_Type__c;Payment dates;ECM_Total_Investment_Amount__c;ECM_Prepayment__c;ECM_Sales_Driver_Name__c';
        mktSetting.ECM_Sales_Driver_Item_Details__c = 'Investment;Product Name;Upper Limit Amount;Sales Driver';
        mktSetting.ECM_Contract_pdf_to_Approval_Mails__c = true;
        insert mktSetting;
        return mktSetting; 
    }
    static Account getOutlet(Id geographyId,User usr)
    {
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Person_Responsible__c= usr.Id;
        outletAccount.OwnerId = usr.Id;
        outletAccount.Country__c=geographyId;
        outletAccount.Email_for_contracts_payments__c='test.test@diageo.com';
        insert outletAccount;
        return outletAccount;
    }
    static Contract getContract(ECM_Contract_Type__c contractType,Pick_Up_Options__c banner)
    {
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
        objContract.AP_Spent__c=12;
        objContract.Opening_AP_Balance__c=124;
        objContract.Contract_End_Date__c = system.today()+360;
        //objContract.OwnerId = usr.Id;
        insert objContract;
        return objContract;
    }
    static ECM_Contract_KPI__c getContractKPI(Contract objContract)
    {
        ECM_Contract_KPI__c conKpi = new ECM_Contract_KPI__c();
        conKpi.ECM_Contract__c = objContract.Id;
        conKpi.ECM_EU_Volume__c = 1;
        conKpi.ECM_Total_NSV__c = 2;
        conKpi.ECM_CAAP__c = 4;
        conKpi.ECM_Type__c = 'Total';
        insert conKpi;
        return conKpi;
    }
    static Product__c getProduct(Id geographyId)
    {
        Product__c product = ECM_UtilityTestClass.createProduct(geographyId,'Test');
        product.Product_Full_Name__c='Test';
        insert product;
        return product;
    }
    static Product_UOM__c getProductUOM(Product__c product)
    {
        Product_UOM__c prdtUOM = ECM_UtilityTestClass.createProductUOM(product.Id);
        prdtUOM.Type__c = 'BTL';
        prdtUOM.Unique_ID__c = product.Id + '_BTL';
        insert prdtUOM;
        return prdtUOM;
    }
    static Market_Assortment_Product__c getMarketAssortmentProduct(Id geographyId,Product__c product,ECM_Contract_Type__c contractType)
    {
        Market_Assortment_Product__c marketassort = ECM_UtilityTestClass.createMarketAssortmentProduct(product.Id,geographyId);
        insert marketassort;        
        ECM_Product_Agreement__c productagg = ECM_UtilityTestClass.createProductAgreement(contractType.Id,marketassort.Id);
        insert productagg;  
        return marketassort;
    }
    static ECM_Contract_Item__c getContractItem(Contract objContract,Market_Assortment_Product__c marketassort)
    {
        ECM_Contract_Item__c newcontractitem= ECM_UtilityTestClass.createcontractitem(objContract.Id,marketassort.id);
        insert newcontractitem;  
        return newcontractitem;
    }
    static ECM_Sales_Driver_Item__c getSalesDriverItem(Territory_Budget__c terriBudget1,Id geographyId,Contract objContract)
    {
        ECM_Sales_Driver__c salesDriver = ECM_UtilityTestClass.getSalesdriver(terriBudget1.Id,geographyId);
        insert salesDriver;      
        ECM_Sales_Driver_Item__c esCDI = new ECM_Sales_Driver_Item__c(Contract__c=objContract.Id,ECM_Sales_Driver__c=salesDriver.Id);
        esCDI.ECM_Total_Investment_Amount__c = 150;
        insert esCDI;
        return esCDI;
    }
    static ECM_Approval_Log__c getApprovalLog(ECM_Contract_Type__c contractType , Contract objContract)
    {
        ECM_Extra_Approval__c ecmEX4 = new ECM_Extra_Approval__c();
        ecmEX4.ECM_Active__c = true;
        ecmEX4.ECM_Approver_Position_Name__c = 'Test Approver';
        ecmEX4.ECM_Approver_s_Email_Address__c = 'name.surname@diageo.com';
        ecmEX4.ECM_Upper_Limit_Amount__c = 200;
        ecmEX4.ECM_Enable_Delegation__c = false;
        ecmEX4.ECM_Type__c = 'Contract Sales Driver Item';
        ecmEX4.ECM_Delegated_Approver_Email_Address__c ='Test2@test.com';
        insert ecmEX4;
        
        ECM_Agreement_Approval__c ecmAA4 = ECM_UtilityTestClass.getAgrmntApproval(contractType.Id,ecmEX4.Id);
        insert ecmAA4;
        
        ECM_Approval_Log__c ecmCurrentApprovalLog = new ECM_Approval_Log__c();
        ecmCurrentApprovalLog.ECM_Approver_s_Position__c='Legal';
        ecmCurrentApprovalLog.Name='test@test.com';
        ecmCurrentApprovalLog.ECM_Status__c='Requested';
        ecmCurrentApprovalLog.ECM_Comment__c='Test User';
        ecmCurrentApprovalLog.ECM_Type__c = 'Contract';
        ecmCurrentApprovalLog.ECM_Contract__c=objContract.Id;
        ecmCurrentApprovalLog.RecordTypeId = ECM_Approval_Log__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Primary approver').getRecordTypeId();
        insert ecmCurrentApprovalLog;
        return ecmCurrentApprovalLog;
    }
    static User createManager()
    {
        Profile profManager = [select id from profile where name=: 'Sales Manager'];
        User usrManager = ECM_UtilityTestClass.createUser('testCM_manager1234@test.com',profManager.Id);
        insert usrManager;
        return usrManager;
    }
    static ECM_Contract_Type__c getContractTypeHybrid(Id geographyId)
    {
       
        ECM_Contract_Type__c contractType= ECM_UtilityTestClass.getAgreementType(geographyId);
        contractType.ECM_Volume_UoM_for_Beer__c='EU';
        contractType.ECM_Automatic_approval_amount_threshold__c = 100;
        contractType.ECM_Re_Investment_Rate_Approve_Threshold__c = 10;
        contractType.ECM_Volume_UoM_for_RTD__c = 'Can/Bottle 24 Pack';
        contractType.ECM_Volume_UoM_for_Draught_Cocktails__c = '10L BIB';
        insert contractType;   
        return contractType;
    }
    static Contract getContractHybrid(Id geographyId,Territory__c territory,ECM_Contract_Type__c contractType)
    {
         String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        ECM_Payment_Frequency__c paymentFrequency=new ECM_Payment_Frequency__c();
        paymentFrequency.ECM_Geography__c=geographyId;
        paymentFrequency.ECM_Type__c='Equal Instalments';
        paymentFrequency.ECM_Other_Investment__c=true;
        insert paymentFrequency;     
        ECM_Payment_Agreement__c paymentAgreement= ECM_UtilityTestClass.createPaymentAgreement(contractType.Id,paymentFrequency.Id);
        insert paymentAgreement;       
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep1','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        insert salesRep;        
        User cioUser = EDGE_UtilityTestClass.runAsUser('salesRep1','CIO User');
        cioUser.Available_Countries__c = 'AU';
        insert cioUser;         
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.Country__c = geographyId;
        insert acc;       
        Date myDate = Date.newInstance(system.today().year()+1, 5, 17);
        Date myStartDate = Date.newInstance(system.today().year(), 5, 17);
        Contract conRecord = new Contract(Name = 'Test',Status='Draft',StartDate=myStartDate,UOS_Rebate_Rate__c=88, UOS_Target__c=99,AccountId =acc.id,Contract_End_Date__c=myDate,ECM_Agreement_Type__c=contractType.id,ECM_Duration__c=2,ECM_Overall_Investment_Amount__c=40.00,ECM_Territory__c=territory.id,UOS_Earnt__c=3.00,UOS_AP_Rate__c=2.00,AP_Spent__c=2.00,Opening_AP_Balance__c=5.00,ECM_Channel__c='Hybrid',Venue_Type__c ='Premium[AU]',RecordTypeId = contractRecordTypeId,ECM_Selected_Payment_Schedule_AU__c=paymentFrequency.Id,ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c=10000,ECM_Hybrid_CustInvest_Total_PercentGP__c=90);
        insert conRecord;
        return conRecord;        
    }
    static ContentDocumentLink getLink(Contract conRecord)
    {
         //Create a new file
        ContentVersion newFile = new ContentVersion();
        newFile.PathOnClient = 'TestFile';
        newFile.Title = 'TestFile';
        newFile.VersionData = Blob.valueOf('sample content');
        newFile.Content_Type__c = Label.ECM_ContentTypeApprovalMail;
        newFile.RecordTypeId = ContentVersion.sObjectType.getDescribe().getRecordTypeInfosByName().get('Contracts').getRecordTypeId();
        insert newFile;
        
        //Query the contentDocumentId
        ContentVersion insertedFile = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =:newFile.Id];
        
        //Link the file with the product
        ContentDocumentLink linkedFile = new ContentDocumentLink(LinkedEntityId=conRecord.Id, ContentDocumentId=insertedFile.ContentDocumentId);
        insert linkedFile;
        return linkedFile;
    }
    static Market_Setting__c getMarketSettingHybrid1(Id geographyId)
    {
        Market_Setting__c mrkSet=EDGE_UtilityTestClass.getMarketSetting(geographyId);
        mrkSet.ECM_Contract_Creation_Page__c='Global';
        mrkSet.ECM_Contract_Management_Market__c=true;
        mrkSet.ECM_SAP_Order_Type__c='YPCR';
        mrkSet.ECM_Payment_Management_Email__c='test@test22.com';
        mrkSet.ECM_Email_to_Send_Payment_CSV__c='test@test23.com';
        mrkSet.ECM_Contract_Approval_Template__c='ECM_Contract_Approval_Request_Temp_AU';
        insert mrkSet;     
        
        mrkSet.ECM_Mandatory_field_for_Contract__c='SAP Sold To;Legal Name;SAP Ship to;Customer email for Contract;Sales org;';
        mrkSet.ECM_Contract_Header_Details__c='ECM_Contract_Owner__c;ECM_Territory__r.Name;Account.ECM_Legal_Name__c;Account.Name;ECM_Agreement_Type__r.Name;StartDate;Contract_End_Date__c;ContractNumber;Name';
        mrkSet.ECM_Investment_Summary_KPIS__c='ECM_Total_Volume_Target_Spirits__c;ECM_Total_Volume_Target_Beers__c;ECM_Incremental_Volume_Spirits__c;ECM_Incremental_Volume_Beers__c;ECM_Total_trade_investment_Beers__c;ECM_Total_A_P_Investment_Spirits__c;ECM_Incremental_GP__c;ECM_Incremental_GP_Beers__c';
        mrkSet.ECM_Category_Split_KPIS__c='ECM_NSV_reserve_share__c;ECM_NSV_premium_core_share__c;ECM_GP_reserve_share__c;ECM_GP_innovation_share__c;ECM_GM_reserve_share__c;ECM_GM_innovation_share__c;ECM_GM_premium_core_share__c;ECM_TV_reserve_share__c;ECM_TV_premium_core_share__c;ECM_IV_reserve_share__c;ECM_IV_innovation_share__c;ECM_IV_premium_core_share__c';
        mrkSet.ECM_Product_Investment_Details__c='ECM_Retro_investment__c;ECM_Trade_Investments__c;ECM_AnP_investment__c;ECM_Gross_margin__c;ECM_Total_GP_EU__c;ECM_Generated_NSV_EU__c;ECM_NSV_After_Investment__c;ECM_Incremental_GP_after_Investment__c;Tiers;ECM_UoM__c;ECM_Baseline_volume__c;ECM_Volume__c;ECM_Incremental_Volume__c;ECM_CAAP_Total__c;ECM_Product_growth_driver__c';
        mrkSet.ECM_Sales_Drivers_Details__c='ECM_Investement_Description__c;ECM_Budget_Type__c;ECM_Payment_Frequency__r.ECM_Type__c;Payment dates;ECM_Total_Investment_Amount__c;ECM_Prepayment__c;ECM_Sales_Driver_Name__c';
        mrkSet.ECM_Sales_Driver_Item_Details__c = 'Investment;Product Name;Upper Limit Amount;Sales Driver';
        mrkSet.ECM_Contract_pdf_to_Approval_Mails__c = true;    
        update mrkSet;
        return mrkSet;
    }
    static ECM_Contract_Type__c getContractTypeHybrid2(Id geographyId)
    {  
        ECM_Contract_Type__c contractType= ECM_UtilityTestClass.getAgreementType(geographyId);
        contractType.ECM_Volume_UoM_for_Beer__c='EU';
        contractType.ECM_Volume_UoM_for_RTD__c = 'Can/Bottle 24 Pack';
        contractType.ECM_Volume_UoM_for_Draught_Cocktails__c = '10L BIB';
        insert contractType;
        return contractType;
    }
    static Contract getContractHybrid2(Id geographyId,Territory__c territory,ECM_Contract_Type__c contractType)
    {
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        ECM_Payment_Frequency__c paymentFrequency=new ECM_Payment_Frequency__c();
        paymentFrequency.ECM_Geography__c=geographyId;
        paymentFrequency.ECM_Type__c='Equal Instalments';
        paymentFrequency.ECM_Other_Investment__c=true;
        insert paymentFrequency; 
        ECM_Payment_Agreement__c paymentAgreement= ECM_UtilityTestClass.createPaymentAgreement(contractType.Id,paymentFrequency.Id);
        insert paymentAgreement;     
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep1','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        //  salesManager.ManagerId = testAdminUser.id;
        insert salesRep;        
        User cioUser = EDGE_UtilityTestClass.runAsUser('salesRep1','CIO User');
        cioUser.Available_Countries__c = 'AU';
        //  salesManager.ManagerId = testAdminUser.id;
        insert cioUser;       
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.Country__c = geographyId;
        insert acc;      
        Date myDate = Date.newInstance(system.today().year()+1, 5, 17);
        Date myStartDate = Date.newInstance(system.today().year(), 5, 17);
        Contract conRecord = new Contract(Name = 'Test',Status='Draft',StartDate=myStartDate,UOS_Rebate_Rate__c=88, UOS_Target__c=99,AccountId =acc.id,Contract_End_Date__c=myDate,ECM_Agreement_Type__c=contractType.id,ECM_Duration__c=2,ECM_Overall_Investment_Amount__c=40.00,ECM_Territory__c=territory.id,UOS_Earnt__c=3.00,UOS_AP_Rate__c=2.00,AP_Spent__c=2.00,Opening_AP_Balance__c=5.00,ECM_Channel__c='Hybrid',Venue_Type__c ='Premium[AU]',RecordTypeId = contractRecordTypeId,ECM_Selected_Payment_Schedule_AU__c=paymentFrequency.Id);
        insert conRecord;
        return conRecord;        
    }
    static Market_Setting__c getMarketSettingHybrid2(Id geographyId)
    {
        Market_Setting__c mrkSet=EDGE_UtilityTestClass.getMarketSetting(geographyId);
        mrkSet.ECM_Contract_Creation_Page__c='Global';
        mrkSet.ECM_Contract_Management_Market__c=true;
        mrkSet.ECM_SAP_Order_Type__c='YPCR';
        mrkSet.ECM_Payment_Management_Email__c='test@test22.com';
        mrkSet.ECM_Email_to_Send_Payment_CSV__c='test@test23.com';
        insert mrkSet;     
        
        mrkSet.ECM_Mandatory_field_for_Contract__c='SAP Sold To;Legal Name;SAP Ship to;Customer email for Contract;Sales org;';
        mrkSet.ECM_Sales_Driver_Item_Details__c = 'Investment;Product Name;Upper Limit Amount;Sales Driver';
        mrkSet.ECM_Contract_Header_Details__c='ContractNumber';       
        update mrkSet;
        return mrkSet;
    }
    static List<Pick_Up_Options__c> getPickupOptionsHybrid(Id geographyId)
    {
        String pickupRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        List<Pick_Up_Options__c> pickups=new List<Pick_Up_Options__c>();
        Pick_Up_Options__c pOption = ECM_UtilityTestClass.createPickUpOption(geographyId,pickupRecordTypeId);
        pOption.Name = 'Gold[AUT]';
        pOption.Type__c = 'Local-Segment1';
        pOption.Days_between_visit__c = 5;
        pOption.Status__c = 'Active';
        pickups.add(pOption);
        
        Pick_Up_Options__c budgetTypeObj1= ECM_UtilityTestClass.createPickUpOption(geographyId,Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId());
        budgetTypeObj1.Name='Upfront Payment [AU]';
        budgetTypeObj1.Status__c = 'Active';
        pickups.add(budgetTypeObj1);
        
        Pick_Up_Options__c budgetTypeObj2= ECM_UtilityTestClass.createPickUpOption(geographyId,Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId());
        budgetTypeObj2.Name='On-Premise[AU]';
        budgetTypeObj2.ECM_SAP_Order_reason__c = 'Y10'; 
        budgetTypeObj2.ECM_SAP_Pricing_condition__c = 'O25';
        pickups.add(budgetTypeObj2);
        insert pickups;
        return pickups;
    }
    static ECM_Contract_Item__c geteciContractItem(Contract con)
    {
        ECM_Contract_Item__c eci = new ECM_Contract_Item__c();
        eci.ECM_MAT_override__c = 20.00;
        eci.ECM_Contract__c = con.id;
        eci.ECM_MAT_UOS__c = 20.00;
        eci.ECM_Total_GP__c = 20.00;
        eci.ECM_Total_COGS__c = 20.00;
        eci.ECM_Total_SKU_Specific_Rebate_ON__c = 10.00;
        eci.ECM_TotalSKU_SpecificRebate__c = 10.00;
        eci.ECM_Total_GP_ON__c = 20.00;
        insert eci; 
        return eci;
    }
    @isTest
    static void testMethodForEmailTemplate(){
        User usr = ECM_ReviewAndSubmitControllerTest.getUser();
        Id geographyId = EDGE_UtilityTestClass.setupCountry('ES'); 
        //String bRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        Territory_Hierarchy__c hirarchy= ECM_ReviewAndSubmitControllerTest.getRegion(geographyId);
        Territory__c testterritory=ECM_ReviewAndSubmitControllerTest.getTerritory(geographyId,hirarchy,usr);
        Pick_Up_Options__c budjectEU=ECM_ReviewAndSubmitControllerTest.getBudgetTypeES(geographyId);
        Territory_Budget__c terriBudget1=ECM_ReviewAndSubmitControllerTest.getTerritoryBudgets(testterritory,hirarchy,budjectEU);       
        ECM_Contract_Type__c contractType = ECM_ReviewAndSubmitControllerTest.getContractTypes(geographyId);
        Pick_Up_Options__c banner= ECM_ReviewAndSubmitControllerTest.getBannerES(geographyId);
        Market_Setting__c mktSetting=new Market_Setting__c();
        mktSetting=ECM_ReviewAndSubmitControllerTest.getMarketSetting(geographyId);
        outletAccount=ECM_ReviewAndSubmitControllerTest.getOutlet(geographyId,usr);
        Contract objContract = ECM_ReviewAndSubmitControllerTest.getContract(contractType,banner);
        ECM_Contract_KPI__c conKpi=new ECM_Contract_KPI__c();
        conKpi=ECM_ReviewAndSubmitControllerTest.getContractKPI(objContract);      
        Product__c product = ECM_ReviewAndSubmitControllerTest.getProduct(geographyId);
        Product_UOM__c prdtUOM = new Product_UOM__c();
        prdtUOM=ECM_ReviewAndSubmitControllerTest.getProductUOM(product);       
        Market_Assortment_Product__c marketassort=ECM_ReviewAndSubmitControllerTest.getMarketAssortmentProduct(geographyId,product,contractType);        
        ECM_Contract_Item__c newcontractitem=ECM_ReviewAndSubmitControllerTest.getContractItem(objContract,marketassort);    
        ECM_Sales_Driver_Item__c esCDI =ECM_ReviewAndSubmitControllerTest.getSalesDriverItem(terriBudget1,geographyId,objContract);
        ECM_Sales_Driver_Item_Detail__c salesDetails1 = ECM_UtilityTestClass.insertSalesdriverDetails(esCDI, newcontractitem);
        salesDetails1.ECM_Investment_Amount__c = 200;
        insert salesDetails1;
        Test.startTest();
        Contract con =[Select id,Name,AccountId,Account.Country_Code__c,ECM_EU_Total_Trade_Investment__c,ECM_Overall_Investment_Figure__c,ECM_Total_A_P_Investment__c,ECM_Total_GP__c,ECM_GP_ROI__c,ECM_CAP_ROI__c,ECM_of_the_total_investment_vs_NSV__c,ECM_Variable_share__c,ECM_Fixed_share__c,ECM_Total_TI_Investment__c,ECM_Total_trade_investment_Spirits__c,ECM_Total_trade_investment_Beers__c,ECM_Total_A_P_Investment_Spirits__c,ECM_Total_A_P_Investment_Beers__c,
                       ECM_Total_SKU_Specific_Rebate_Over_Term__c,ECM_Total_Others_Over_Term__c,ECM_Agreement_Type__r.ECM_Upfront_Deed_Minimum__c,ECM_Total_Training_Over_Term__c,ECM_Total_Upfront_Payment_Loan_Over_Term__c,ECM_Total_A_P_investments__c,ECM_Overall_investments__c,ContractNumber,ECM_Last_saved_page__c,Contract_End_Date__c,ECM_Duration__c,Status,
                       StartDate,recordTypeId,ECM_Banner__c,Venue_Type__c,ECM_Channel__c,BillingState,ECM_RTD_Sales_driver__c,ECM_Generated_NSV__c,ECM_Additional_information_to_support__c,
                       ECM_Spirits_Sales_driver__c,ECM_Spirits_Pouring_Sales_driver__c,ECM_Spirits_Premium_Sales_driver__c,ECM_Territory__c,ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c,ECM_Hybrid_CustInvest_Total_PercentGP__c,
                       ECM_Spirits_Reserve_Sales_driver__c,ECM_Selected_Payment_Schedule_AU__c,ECM_Additional_info_to_support_decision__c,UOS_Rebate_Rate__c,ECM_Agreement_Type__c,ECM_OnPremise_Total_A_P_PerYear__c,ECM_Payment_Schedule_Date_AU__c,CreatedBy.Name,
                       ECM_Recalled__c,ECM_Parent_Contract__c,ECM_Parent_Contract__r.ContractNumber,ECM_Parent_Contract__r.Name from Contract Where Id=:objContract.id];
        /*Assert check for contract Id*/
        system.assertEquals(con.Id,objContract.id,'Wrong Contract assignment');
        ECM_Approval_Log__c ecmCurrentApprovalLog=getApprovalLog(contractType,objContract);
        ECM_GetContractItemDetails getContractItemDetails = new ECM_GetContractItemDetails();
        getContractItemDetails.targetObjectId =con.Id; 
        getContractItemDetails.approvalLogId = ecmCurrentApprovalLog.Id;
        getContractItemDetails.getContractItems();
        getContractItemDetails.getOutletContracts();
        getContractItemDetails.getSalesDriver();
        getContractItemDetails.getAccountId();
        getContractItemDetails.getDraftContractDetails();
        getContractItemDetails.getContractDetails();
        getContractItemDetails.getActiveContractDetails();
        getContractItemDetails.getContHeaderDetails();
        getContractItemDetails.getInvSumDetails();
        getContractItemDetails.getProductDetails();
        getContractItemDetails.getApprovalLogDetails();        
        Test.stopTest();
    }
    @isTest
    static void testMethodForEmailTemplateGB(){
       User usr = ECM_ReviewAndSubmitControllerTest.getUser();
        Id geographyId = EDGE_UtilityTestClass.setupCountry('GB'); 
        //String bRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        Territory_Hierarchy__c hirarchy= ECM_ReviewAndSubmitControllerTest.getRegion(geographyId);
        Territory__c testterritory=ECM_ReviewAndSubmitControllerTest.getTerritory(geographyId,hirarchy,usr);
        Pick_Up_Options__c budjectEU=ECM_ReviewAndSubmitControllerTest.getBudgetTypeGB(geographyId);
        Territory_Budget__c terriBudget1=ECM_ReviewAndSubmitControllerTest.getTerritoryBudgets(testterritory,hirarchy,budjectEU);       
        ECM_Contract_Type__c contractType = ECM_ReviewAndSubmitControllerTest.getContractTypes(geographyId);
        Pick_Up_Options__c banner= ECM_ReviewAndSubmitControllerTest.getBannerGB(geographyId);
        Market_Setting__c mktSetting=new Market_Setting__c();
        mktSetting=ECM_ReviewAndSubmitControllerTest.getMarketSetting(geographyId);
        outletAccount=ECM_ReviewAndSubmitControllerTest.getOutlet(geographyId,usr);
        Contract objContract = ECM_ReviewAndSubmitControllerTest.getContract(contractType,banner);
        ECM_Contract_KPI__c conKpi=new ECM_Contract_KPI__c();
        conKpi=ECM_ReviewAndSubmitControllerTest.getContractKPI(objContract);      
        Product__c product = ECM_ReviewAndSubmitControllerTest.getProduct(geographyId);
        Product_UOM__c prdtUOM = new Product_UOM__c();
        prdtUOM=ECM_ReviewAndSubmitControllerTest.getProductUOM(product);       
        Market_Assortment_Product__c marketassort=ECM_ReviewAndSubmitControllerTest.getMarketAssortmentProduct(geographyId,product,contractType);        
        ECM_Contract_Item__c newcontractitem=ECM_ReviewAndSubmitControllerTest.getContractItem(objContract,marketassort);    
        ECM_Sales_Driver_Item__c esCDI =ECM_ReviewAndSubmitControllerTest.getSalesDriverItem(terriBudget1,geographyId,objContract);
        ECM_Sales_Driver_Item_Detail__c salesDetails1 = ECM_UtilityTestClass.insertSalesdriverDetails(esCDI, newcontractitem);
        salesDetails1.ECM_Investment_Amount__c = 200;
        insert salesDetails1;
        Test.startTest();
        Contract con =[Select id,Name,AccountId,Account.Country_Code__c,ECM_EU_Total_Trade_Investment__c,ECM_Overall_Investment_Figure__c,ECM_Total_A_P_Investment__c,ECM_Total_GP__c,ECM_GP_ROI__c,ECM_CAP_ROI__c,ECM_of_the_total_investment_vs_NSV__c,ECM_Variable_share__c,ECM_Fixed_share__c,ECM_Total_TI_Investment__c,ECM_Total_trade_investment_Spirits__c,ECM_Total_trade_investment_Beers__c,ECM_Total_A_P_Investment_Spirits__c,ECM_Total_A_P_Investment_Beers__c,
                       ECM_Total_SKU_Specific_Rebate_Over_Term__c,ECM_Total_Others_Over_Term__c,ECM_Agreement_Type__r.ECM_Upfront_Deed_Minimum__c,ECM_Total_Training_Over_Term__c,ECM_Total_Upfront_Payment_Loan_Over_Term__c,ECM_Total_A_P_investments__c,ECM_Overall_investments__c,ContractNumber,ECM_Last_saved_page__c,Contract_End_Date__c,ECM_Duration__c,Status,
                       StartDate,recordTypeId,ECM_Banner__c,Venue_Type__c,ECM_Channel__c,BillingState,ECM_RTD_Sales_driver__c,ECM_Generated_NSV__c,ECM_Additional_information_to_support__c,
                       ECM_Spirits_Sales_driver__c,ECM_Spirits_Pouring_Sales_driver__c,ECM_Spirits_Premium_Sales_driver__c,ECM_Territory__c,ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c,ECM_Hybrid_CustInvest_Total_PercentGP__c,
                       ECM_Spirits_Reserve_Sales_driver__c,ECM_Selected_Payment_Schedule_AU__c,ECM_Additional_info_to_support_decision__c,UOS_Rebate_Rate__c,ECM_Agreement_Type__c,ECM_OnPremise_Total_A_P_PerYear__c,ECM_Payment_Schedule_Date_AU__c,CreatedBy.Name,
                       ECM_Recalled__c,ECM_Parent_Contract__c,ECM_Parent_Contract__r.ContractNumber,ECM_Parent_Contract__r.Name from Contract Where Id=:objContract.id];
        /*Assert check for contract Id*/
        system.assertEquals(con.Id,objContract.id,'Wrong Contract assignment');
        ECM_Approval_Log__c ecmCurrentApprovalLog=getApprovalLog(contractType,objContract);
        ECM_GetContractItemDetails getContractItemDetails = new ECM_GetContractItemDetails();
        getContractItemDetails.targetObjectId =con.Id; 
        getContractItemDetails.approvalLogId = ecmCurrentApprovalLog.Id;
        getContractItemDetails.getContractItems();
        getContractItemDetails.getOutletContracts();
        getContractItemDetails.getSalesDriver();
        getContractItemDetails.getAccountId();
        getContractItemDetails.getDraftContractDetails();
        getContractItemDetails.getContractDetails();
        getContractItemDetails.getActiveContractDetails();
        getContractItemDetails.getContHeaderDetails();
        getContractItemDetails.getInvSumDetails();
        getContractItemDetails.getProductDetails();
        getContractItemDetails.getApprovalLogDetails();        
        Test.stopTest();
    }
    @isTest
    static void testReviewHybridCaluculatons(){
        //Spain geography
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');  
        User usrManager = ECM_ReviewAndSubmitControllerTest.createManager();     
        user newuser = EDGE_UtilityTestClass.runAsUser('Testabc','System Administrator');
        newuser.ManagerId = usrManager.Id;
        insert newuser;       
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        territory.Primary_Sales_Rep__c = newuser.Id;
        insert territory;
        ECM_Contract_Type__c contractType=ECM_ReviewAndSubmitControllerTest.getContractTypeHybrid(geographyId);
        Contract conRecord = ECM_ReviewAndSubmitControllerTest.getContractHybrid(geographyId,territory,contractType);
        ContentDocumentLink linkedFile =new ContentDocumentLink();
        linkedFile=ECM_ReviewAndSubmitControllerTest.getLink(conRecord);    
        Contract con =[Select id,Name,AccountId,Account.Country_Code__c,ECM_EU_Total_Trade_Investment__c,ECM_Overall_Investment_Figure__c,ECM_Total_A_P_Investment__c,ECM_Total_GP__c,ECM_GP_ROI__c,ECM_CAP_ROI__c,ECM_of_the_total_investment_vs_NSV__c,ECM_Variable_share__c,ECM_Fixed_share__c,ECM_Total_TI_Investment__c,ECM_Total_trade_investment_Spirits__c,ECM_Total_trade_investment_Beers__c,ECM_Total_A_P_Investment_Spirits__c,ECM_Total_A_P_Investment_Beers__c,
                       ECM_Total_SKU_Specific_Rebate_Over_Term__c,ECM_Total_Others_Over_Term__c,ECM_Agreement_Type__r.ECM_Upfront_Deed_Minimum__c,ECM_Total_Training_Over_Term__c,ECM_Total_Upfront_Payment_Loan_Over_Term__c,ECM_Total_A_P_investments__c,ECM_Overall_investments__c,ContractNumber,ECM_Last_saved_page__c,Contract_End_Date__c,ECM_Duration__c,Status,
                       StartDate,recordTypeId,ECM_Banner__c,Venue_Type__c,ECM_Channel__c,BillingState,ECM_RTD_Sales_driver__c,ECM_Generated_NSV__c,ECM_Additional_information_to_support__c,
                       ECM_Spirits_Sales_driver__c,ECM_Spirits_Pouring_Sales_driver__c,ECM_Spirits_Premium_Sales_driver__c,ECM_Territory__c,ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c,ECM_Hybrid_CustInvest_Total_PercentGP__c,
                       ECM_Spirits_Reserve_Sales_driver__c,ECM_Selected_Payment_Schedule_AU__c,ECM_Additional_info_to_support_decision__c,UOS_Rebate_Rate__c,ECM_Agreement_Type__c,ECM_OnPremise_Total_A_P_PerYear__c,ECM_Payment_Schedule_Date_AU__c,CreatedBy.Name,
                       ECM_Recalled__c,ECM_Parent_Contract__c,ECM_Parent_Contract__r.ContractNumber,ECM_Parent_Contract__r.Name from Contract Where Id=:conRecord.id];
        /*Assert check for contract Id*/
        system.assertEquals(con.Id,conRecord.id,'Wrong Contract assignment');
        //Create market setting
        Market_Setting__c mrkSet=new Market_Setting__c();
        mrkSet=ECM_ReviewAndSubmitControllerTest.getMarketSettingHybrid1(geographyId);
        List<Pick_Up_Options__c> pickups=new List<Pick_Up_Options__c>();
        pickups=ECM_ReviewAndSubmitControllerTest.getPickupOptionsHybrid(geographyId);
        ECM_Contract_Item__c eci=new ECM_Contract_Item__c();
        eci=ECM_ReviewAndSubmitControllerTest.geteciContractItem(con);
        ECM_ReviewAndSubmitController.Wrapper_Review_cal hybridreview = ECM_ReviewAndSubmitController.ReviewHybridCaluculatons(con);
        ECM_ReviewAndSubmitController.Wrapper_Review_cal onpremisereview = ECM_ReviewAndSubmitController.Review_On_Premise_Caluculatons(con);
        ECM_ReviewAndSubmitController.totaldisplay tdisplay = new ECM_ReviewAndSubmitController.totaldisplay();
        System.assertEquals(tdisplay.PerYear,decimal.valueOf(0),'PerYear Value is wrong');    
        ECM_ReviewAndSubmitController.get_active_A_Precord(con);
        ECM_ReviewAndSubmitController.submitForApproval(con);
        ECM_ReviewAndSubmitController.getUser(newuser.id);
        ECM_ReviewAndSubmitController.getTerritory(territory.id);
        ECM_ReviewAndSubmitController.getguidelines(con,20.00,20.00,null);
        ECM_ReviewAndSubmitController.getguidelines(con,null,null,null);
        string hybridreviewstr=JSON.serialize(hybridreview);
        string onpremisereviewstr=JSON.serialize(onpremisereview);
        ECM_ReviewAndSubmitController.SaveContract(con,'100.00','100.00',hybridreviewstr,onpremisereviewstr,100.00);
        ECM_ReviewAndSubmitController.getcontractdetails(con);
        ECM_ReviewAndSubmitController.getvolumeOverview(con.Id);
        ECM_ReviewAndSubmitController.validationErrorCheck(con);       
        ECM_ReviewAndSubmitController.paymentSchedulevalues(contractType.id);
        ECM_GetContractItemDetails getContractItemDetails = new ECM_GetContractItemDetails();
        getContractItemDetails.targetObjectId =con.Id; 
        getContractItemDetails.getContractItems();
        getContractItemDetails.getOutletContracts();
        getContractItemDetails.getSalesDriver();
        getContractItemDetails.getAccountId();
        getContractItemDetails.getDraftContractDetails();
        getContractItemDetails.getContractDetails();
        getContractItemDetails.getActiveContractDetails();
        getContractItemDetails.getContHeaderDetails();
        getContractItemDetails.getInvSumDetails();
        getContractItemDetails.getProductDetails();
    }
    @isTest
    static void testReviewHybridCaluculatons1(){
        String contractRecordTypeId =''; 
        contractRecordTypeId=Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        String pickupRecordTypeId = '';
        pickupRecordTypeId=Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        //Spain geography
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        
        user newuser = EDGE_UtilityTestClass.runAsUser('Testabc','System Administrator');
        insert newuser;
        
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        insert territory;
        
        ECM_Contract_Type__c contractType= ECM_ReviewAndSubmitControllerTest.getContractTypeHybrid2(geographyId);           
        Contract conRecord = ECM_ReviewAndSubmitControllerTest.getContractHybrid2(geographyId,territory,contractType);
        Contract con =[Select id,Name,AccountId,Account.Country_Code__c,ECM_EU_Total_Trade_Investment__c,ECM_Overall_Investment_Figure__c,ECM_Total_A_P_Investment__c,ECM_Total_GP__c,ECM_GP_ROI__c,ECM_CAP_ROI__c,ECM_of_the_total_investment_vs_NSV__c,ECM_Variable_share__c,ECM_Fixed_share__c,ECM_Total_TI_Investment__c,ECM_Total_trade_investment_Spirits__c,ECM_Total_trade_investment_Beers__c,ECM_Total_A_P_Investment_Spirits__c,ECM_Total_A_P_Investment_Beers__c,
                       ECM_Total_SKU_Specific_Rebate_Over_Term__c,ECM_Total_Others_Over_Term__c,ECM_Agreement_Type__r.ECM_Upfront_Deed_Minimum__c,ECM_Total_Training_Over_Term__c,ECM_Total_Upfront_Payment_Loan_Over_Term__c,ECM_Total_A_P_investments__c,ECM_Overall_investments__c,ContractNumber,ECM_Last_saved_page__c,Contract_End_Date__c,ECM_Duration__c,Status,
                       StartDate,recordTypeId,ECM_Banner__c,Venue_Type__c,ECM_Channel__c,BillingState,ECM_RTD_Sales_driver__c,ECM_Generated_NSV__c,ECM_Additional_information_to_support__c,
                       ECM_Spirits_Sales_driver__c,ECM_Spirits_Pouring_Sales_driver__c,ECM_Spirits_Premium_Sales_driver__c,ECM_Territory__c,ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c,ECM_Hybrid_CustInvest_Total_PercentGP__c,
                       ECM_Spirits_Reserve_Sales_driver__c,ECM_Selected_Payment_Schedule_AU__c,ECM_Additional_info_to_support_decision__c,UOS_Rebate_Rate__c,ECM_Agreement_Type__c,ECM_OnPremise_Total_A_P_PerYear__c,ECM_Payment_Schedule_Date_AU__c,CreatedBy.Name,
                       ECM_Recalled__c,ECM_Parent_Contract__c,ECM_Parent_Contract__r.ContractNumber,ECM_Parent_Contract__r.Name from Contract Where Id=:conRecord.id];
        /*Assert check for contract Id*/
        system.assertEquals(con.Id,conRecord.id,'Wrong Contract assignment');
        //Create market setting
        Market_Setting__c ms=new Market_Setting__c();
        ms=ECM_ReviewAndSubmitControllerTest.getMarketSettingHybrid2(geographyId);
        List<Pick_Up_Options__c> pickups=new List<Pick_Up_Options__c>();
        pickups=ECM_ReviewAndSubmitControllerTest.getPickupOptionsHybrid(geographyId);
        ECM_Contract_Item__c eci=new ECM_Contract_Item__c();
        eci=ECM_ReviewAndSubmitControllerTest.geteciContractItem(con);       
        ECM_ReviewAndSubmitController.Wrapper_Review_cal hybridreview = ECM_ReviewAndSubmitController.ReviewHybridCaluculatons(con);
        ECM_ReviewAndSubmitController.Wrapper_Review_cal onpremisereview = ECM_ReviewAndSubmitController.Review_On_Premise_Caluculatons(con);
        ECM_ReviewAndSubmitController.totaldisplay tdisplay = new ECM_ReviewAndSubmitController.totaldisplay();
        System.assertEquals(tdisplay.PerYear,decimal.valueOf(0),'PerYear Value is wrong');   
        ECM_ReviewAndSubmitController.get_active_A_Precord(con);
        ECM_ReviewAndSubmitController.submitForApproval(con);
        ECM_ReviewAndSubmitController.getUser(newuser.id);
        ECM_ReviewAndSubmitController.getTerritory(territory.id);
        ECM_ReviewAndSubmitController.getguidelines(con,20.00,20.00,null);
        ECM_ReviewAndSubmitController.getcontract(con.Id);
        string hybridreviewstr=JSON.serialize(hybridreview);
        string onpremisereviewstr=JSON.serialize(onpremisereview);
        ECM_ReviewAndSubmitController.SaveContract(con,'100.00','100.00',hybridreviewstr,onpremisereviewstr,100.00);
        ECM_ReviewAndSubmitController.getcontractdetails(con);
        ECM_ReviewAndSubmitController.getvolumeOverview(con.Id);
        ECM_ReviewAndSubmitController.validationErrorCheck(con);      
        ECM_ReviewAndSubmitController.paymentSchedulevalues(contractType.id);
        ECM_GetContractItemDetails getContractItemDetails = new ECM_GetContractItemDetails();
        getContractItemDetails.targetObjectId =con.Id; 
        getContractItemDetails.getContractItems();
        getContractItemDetails.getOutletContracts();
        getContractItemDetails.getSalesDriver();
        getContractItemDetails.getAccountId();
        getContractItemDetails.getDraftContractDetails();
        getContractItemDetails.getContractDetails();
        getContractItemDetails.getActiveContractDetails();
        getContractItemDetails.getContHeaderDetails();
        getContractItemDetails.getInvSumDetails();
        getContractItemDetails.getProductDetails();
    }
    @isTest
    static void testCreatePaymentSummaryController(){
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        String pickupRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        user newuser = EDGE_UtilityTestClass.runAsUser('Testabc','System Administrator');
        insert newuser;
        
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        insert territory;
        
        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.getAgreementType(geographyId);
        contractType.ECM_Volume_UoM_for_Beer__c='EU';
        contractType.ECM_Volume_UoM_for_RTD__c = 'Can/Bottle 24 Pack';
        contractType.ECM_Volume_UoM_for_Draught_Cocktails__c = '10L BIB';
        insert contractType;
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep1','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        //  salesManager.ManagerId = testAdminUser.id;
        insert salesRep; 
        
        User cioUser = EDGE_UtilityTestClass.runAsUser('salesRep1','CIO User');
        cioUser.Available_Countries__c = 'AU';
        //  salesManager.ManagerId = testAdminUser.id;
        insert cioUser; 
        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        insert acc;
        
        Date myDate = Date.newInstance(2020, 5, 17);
        Contract con = new Contract(Name = 'Test',UOS_Rebate_Rate__c=88, UOS_Target__c=99,AccountId =acc.id,Contract_End_Date__c=myDate,ECM_Agreement_Type__c=contractType.id,ECM_Duration__c=2,ECM_Overall_Investment_Amount__c=40.00,ECM_Territory__c=territory.id,UOS_Earnt__c=3.00,UOS_AP_Rate__c=2.00,AP_Spent__c=2.00,Opening_AP_Balance__c=5.00,ECM_Channel__c='Hybrid',Venue_Type__c ='Premium[AU]',RecordTypeId = contractRecordTypeId);
        insert con;
        con.Status = 'Active';
        update con;
        
        system.assertEquals(con.Status,'Active','Contract not Active');
        
        ECM_Contract_Item__c eci = new ECM_Contract_Item__c();
        eci.ECM_MAT_override__c = 20.00;
        eci.ECM_Contract__c = con.id;
        eci.ECM_MAT_UOS__c = 20.00;
        eci.ECM_Total_GP__c = 20.00;
        eci.ECM_Total_COGS__c = 20.00;
        eci.ECM_Total_SKU_Specific_Rebate_ON__c = 10.00;
        eci.ECM_TotalSKU_SpecificRebate__c = 10.00;
        eci.ECM_Total_GP_ON__c = 20.00;
        insert eci;
        
        ECM_Contract_Item__c eci1 = new ECM_Contract_Item__c();
        eci1.ECM_MAT_override__c = 20.00;
        eci1.ECM_Contract__c = con.id;
        eci1.ECM_MAT_UOS__c = 20.00;
        eci1.ECM_Total_GP__c = 20.00;
        eci1.ECM_Total_COGS__c = 20.00;
        eci1.ECM_Total_SKU_Specific_Rebate_ON__c = 10.00;
        eci1.ECM_TotalSKU_SpecificRebate__c = 10.00;
        eci1.ECM_Total_GP_ON__c = 20.00;
        insert eci1;
        
        ECM_Tiering__c tier = ECM_CreateContractController.createTieringRecord(eci.Id, 10, 1, 20, 2, 30, 3);
        System.assertEquals(tier.ECM_Contract_Item__c, eci.Id, 'tier is not isserted');
        
        ECM_Tiering__c tier2 = ECM_CreateContractController.createTieringRecord(eci1.Id, 5, 1, 10, 2,15, 3);
        System.assertEquals(tier2.ECM_Contract_Item__c, eci1.Id, 'tier2 is not isserted');
        
        Pick_Up_Options__c budgetTypeObj= ECM_UtilityTestClass.createPickUpOption(geographyId,pickupRecordTypeId);
        budgetTypeObj.Name='TI[ES]';
        budgetTypeObj.ECM_SAP_Order_reason__c = 'Y10'; 
        budgetTypeObj.ECM_SAP_Pricing_condition__c = 'O25';
        insert budgetTypeObj;
        
        ECM_Payment_Summary__c paymentSummary2 = new ECM_Payment_Summary__c();
        paymentSummary2.ECM_Total_Amount_Confirmed__c = 20.00;
        paymentSummary2.ECM_Payment_Summary_Status__c = 'Approved';
        paymentSummary2.ECM_Type__c = 'Volume-Based';
        paymentSummary2.ECM_Contract__c = con.id;
        paymentSummary2.ECM_Start_Period__c = system.today();
        paymentSummary2.ECM_End_Period__c = system.today()+2;
        paymentSummary2.ECM_Budget_types__c = budgetTypeObj.id;
        paymentSummary2.ECM_Invoice_Status__c ='Approved';
        paymentSummary2.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymentSummary2.ECM_SAP_payment_Reference_Number__c=10;
        paymentSummary2.ECM_Email_Sent__c =false;
        insert paymentSummary2;
        
        ECM_Payment_Summary_Item__c paymentSummaryItem = new ECM_Payment_Summary_Item__c();
        paymentSummaryItem.ECM_Payment_Summary__c = paymentSummary2.id;
        paymentSummaryItem.ECM_Confirm__c = true;
        paymentSummaryItem.ECM_Contract_Item__c = eci.id;			
        paymentSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
        insert paymentSummaryItem;
        
        ECM_CreatePaymentSummaryController.createPaymentSummary(con.id);
        //ECM_CreatePaymentSummaryController.createPaymentSummaryNonVolume(con.id);
        //ECM_CreatePaymentSummaryController.retrivePaymentSummary(con.id) ;
        System.runAs(salesRep){
            ECM_CreatePaymentSummaryController.retriveCurrentUserProfile();
        }
    }
    @isTest
    static void testCreatePaymentSummaryController1(){
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        String pickupRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        user newuser = EDGE_UtilityTestClass.runAsUser('Testabc','System Administrator');
        insert newuser;
        
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        insert territory;
        
        ECM_Contract_Type__c contractType= ECM_UtilityTestClass.getAgreementType(geographyId);
        contractType.ECM_Volume_UoM_for_Beer__c='EU';
        contractType.ECM_Volume_UoM_for_RTD__c = 'Can/Bottle 24 Pack';
        contractType.ECM_Volume_UoM_for_Draught_Cocktails__c = '10L BIB';
        insert contractType;
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep1','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        //  salesManager.ManagerId = testAdminUser.id;
        insert salesRep; 
        
        User cioUser = EDGE_UtilityTestClass.runAsUser('salesRep1','CIO User');
        cioUser.Available_Countries__c = 'AU';
        //  salesManager.ManagerId = testAdminUser.id;
        insert cioUser; 
        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        insert acc;
        
        Date myDate = Date.newInstance(2020, 5, 17);
        Contract con = new Contract(Name = 'Test',UOS_Rebate_Rate__c=88, UOS_Target__c=99,AccountId =acc.id,Contract_End_Date__c=myDate,ECM_Agreement_Type__c=contractType.id,ECM_Duration__c=2,ECM_Overall_Investment_Amount__c=40.00,ECM_Territory__c=territory.id,UOS_Earnt__c=3.00,UOS_AP_Rate__c=2.00,AP_Spent__c=2.00,Opening_AP_Balance__c=5.00,ECM_Channel__c='Hybrid',Venue_Type__c ='Premium[AU]',RecordTypeId = contractRecordTypeId);
        insert con;
        con.Status = 'Active';
        update con;
        
        system.assertEquals(con.Status,'Active','Contract not Active');
        
        ECM_Contract_Item__c eci = new ECM_Contract_Item__c();
        eci.ECM_MAT_override__c = 20.00;
        eci.ECM_Contract__c = con.id;
        eci.ECM_MAT_UOS__c = 20.00;
        eci.ECM_Total_GP__c = 20.00;
        eci.ECM_Total_COGS__c = 20.00;
        eci.ECM_Actual_Volume_YTD__c=10;
        eci.ECM_Total_SKU_Specific_Rebate_ON__c = 10.00;
        eci.ECM_TotalSKU_SpecificRebate__c = 10.00;
        eci.ECM_Total_GP_ON__c = 20.00;
        insert eci;
        
        ECM_Tiering__c tier = ECM_CreateContractController.createTieringRecord(ECI.Id, 0, 1, 20, 2, 30, 3);
        System.assertEquals(tier.ECM_Contract_Item__c, ECI.Id, 'tier is not isserted');
        
        
        Pick_Up_Options__c budgetTypeObj= ECM_UtilityTestClass.createPickUpOption(geographyId,pickupRecordTypeId);
        budgetTypeObj.Name='TI[ES]';
        budgetTypeObj.ECM_SAP_Order_reason__c = 'Y10'; 
        budgetTypeObj.ECM_SAP_Pricing_condition__c = 'O25';
        insert budgetTypeObj;
        
        ECM_Payment_Summary__c paymentSummary2 = new ECM_Payment_Summary__c();
        paymentSummary2.ECM_Total_Amount_Confirmed__c = 20.00;
        paymentSummary2.ECM_Payment_Summary_Status__c = 'Approved';
        paymentSummary2.ECM_Type__c = 'Volume-Based';
        paymentSummary2.ECM_Contract__c = con.id;
        paymentSummary2.ECM_Start_Period__c = system.today();
        paymentSummary2.ECM_End_Period__c = system.today()+2;
        paymentSummary2.ECM_Budget_types__c = budgetTypeObj.id;
        paymentSummary2.ECM_Invoice_Status__c ='Approved';
        paymentSummary2.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymentSummary2.ECM_SAP_payment_Reference_Number__c=10;
        paymentSummary2.ECM_Email_Sent__c =false;
        insert paymentSummary2;
        
        ECM_Payment_Summary_Item__c paymentSummaryItem = new ECM_Payment_Summary_Item__c();
        paymentSummaryItem.ECM_Payment_Summary__c = paymentSummary2.id;
        paymentSummaryItem.ECM_Confirm__c = true;
        paymentSummaryItem.ECM_Contract_Item__c = eci.id;			
        paymentSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
        insert paymentSummaryItem;
        
        ECM_CreatePaymentSummaryController.createPaymentSummary(con.id);
        ECM_CreatePaymentSummaryController.createPaymentSummaryNonVolume(con.id);
        ECM_CreatePaymentSummaryController.retrivePaymentSummary(con.id) ;
        ECM_CreatePaymentSummaryController.retriveCurrentUserProfile();
        
    }
    @isTest
    static void testCreatePaymentSummaryController2(){
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        String pickupRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        user newuser = EDGE_UtilityTestClass.runAsUser('Testabc','System Administrator');
        insert newuser;
        
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        insert territory;
        
        ECM_Contract_Type__c contractType=ECM_UtilityTestClass.getAgreementType(geographyId);
        contractType.ECM_Volume_UoM_for_Beer__c='EU';
        contractType.ECM_Volume_UoM_for_RTD__c = 'Can/Bottle 24 Pack';
        contractType.ECM_Volume_UoM_for_Draught_Cocktails__c = '10L BIB';
        insert contractType;
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep1','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        //  salesManager.ManagerId = testAdminUser.id;
        insert salesRep; 
        
        User cioUser = EDGE_UtilityTestClass.runAsUser('salesRep1','CIO User');
        cioUser.Available_Countries__c = 'AU';
        //  salesManager.ManagerId = testAdminUser.id;
        insert cioUser; 
        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        insert acc;
        
        Date myDate = Date.newInstance(2020, 5, 17);
        Contract con = new Contract(Name = 'Test',UOS_Rebate_Rate__c=88, UOS_Target__c=99,AccountId =acc.id,Contract_End_Date__c=myDate,ECM_Agreement_Type__c=contractType.id,ECM_Duration__c=2,ECM_Overall_Investment_Amount__c=40.00,ECM_Territory__c=territory.id,UOS_Earnt__c=3.00,UOS_AP_Rate__c=2.00,AP_Spent__c=2.00,Opening_AP_Balance__c=5.00,ECM_Channel__c='Hybrid',Venue_Type__c ='Premium[AU]',RecordTypeId = contractRecordTypeId);
        insert con;
        con.Status = 'Active';
        update con;
        
        system.assertEquals(con.Status,'Active','Contract not Active');
        
        ECM_Contract_Item__c eci = new ECM_Contract_Item__c();
        eci.ECM_MAT_override__c = 20.00;
        eci.ECM_Contract__c = con.id;
        eci.ECM_MAT_UOS__c = 20.00;
        eci.ECM_Total_GP__c = 20.00;
        eci.ECM_Total_COGS__c = 20.00;
        eci.ECM_Actual_Volume_YTD__c=10;
        eci.ECM_Total_SKU_Specific_Rebate_ON__c = 10.00;
        eci.ECM_TotalSKU_SpecificRebate__c = 10.00;
        eci.ECM_Total_GP_ON__c = 20.00;
        insert eci;
        
        ECM_Tiering__c tier = ECM_CreateContractController.createTieringRecord(ECI.Id, 0, 1, 0, 2, 30, 3);
        System.assertEquals(tier.ECM_Contract_Item__c, ECI.Id, 'tier is not isserted');
        
        Pick_Up_Options__c budgetTypeObj= ECM_UtilityTestClass.createPickUpOption(geographyId,pickupRecordTypeId);
        budgetTypeObj.Name='TI[ES]';
        budgetTypeObj.ECM_SAP_Order_reason__c = 'Y10'; 
        budgetTypeObj.ECM_SAP_Pricing_condition__c = 'O25';
        insert budgetTypeObj;
        
        ECM_Payment_Summary__c paymentSummary2 = new ECM_Payment_Summary__c();
        paymentSummary2.ECM_Total_Amount_Confirmed__c = 20.00;
        paymentSummary2.ECM_Payment_Summary_Status__c = 'Approved';
        paymentSummary2.ECM_Type__c = 'Volume-Based';
        paymentSummary2.ECM_Contract__c = con.id;
        paymentSummary2.ECM_Start_Period__c = system.today();
        paymentSummary2.ECM_End_Period__c = system.today()+2;
        paymentSummary2.ECM_Budget_types__c = budgetTypeObj.id;
        paymentSummary2.ECM_Invoice_Status__c ='Approved';
        paymentSummary2.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymentSummary2.ECM_SAP_payment_Reference_Number__c=10;
        paymentSummary2.ECM_Email_Sent__c =false;
        insert paymentSummary2;
        
        ECM_Payment_Summary_Item__c paymentSummaryItem = new ECM_Payment_Summary_Item__c();
        paymentSummaryItem.ECM_Payment_Summary__c = paymentSummary2.id;
        paymentSummaryItem.ECM_Confirm__c = true;
        paymentSummaryItem.ECM_Contract_Item__c = eci.id;			
        paymentSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
        insert paymentSummaryItem;
        
        ECM_CreatePaymentSummaryController.createPaymentSummary(con.id);
        ECM_CreatePaymentSummaryController.createPaymentSummaryNonVolume(con.id);
        ECM_CreatePaymentSummaryController.retrivePaymentSummary(con.id) ;
        ECM_CreatePaymentSummaryController.retriveCurrentUserProfile();
        
    }
    @isTest
    static void testCreatePaymentSummaryController3(){
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        String pickupRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        user newuser = EDGE_UtilityTestClass.runAsUser('Testabc','System Administrator');
        insert newuser;
        
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        insert territory;
        
        Id marketRecordTypeId = Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Market').getRecordTypeId();
        Geography__c geoMarket = [SELECT Id from Geography__c where RecordTypeId=:marketRecordTypeId LIMIT 1];
        
        Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(geoMarket.Id);
        mktSetting.Depletion_market__c=false;
        mktSetting.Ecm_Enable_Target__c = true;
        mktSetting.ECM_Payment_Opt_for_Exceeding_Tier_3_Vol__c = 'Pay at tier 3 rate any exceeding volume (opt.1)';
        mktSetting.ECM_Tiering_for_Volume_investment__c = true;
        mktSetting.ECM_Tiering_Payment_Amount_Calculation__c = 'Top-Level Achievement';
        insert mktSetting;
        
        ECM_Contract_Type__c contractType=ECM_UtilityTestClass.getAgreementType(geographyId);
        contractType.ECM_Volume_UoM_for_Beer__c='EU';
        contractType.ECM_Volume_UoM_for_RTD__c = 'Can/Bottle 24 Pack';
        contractType.ECM_Volume_UoM_for_Draught_Cocktails__c = '10L BIB';
        insert contractType;
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep1','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        //  salesManager.ManagerId = testAdminUser.id;
        insert salesRep; 
        
        User cioUser = EDGE_UtilityTestClass.runAsUser('salesRep1','CIO User');
        cioUser.Available_Countries__c = 'AU';
        //  salesManager.ManagerId = testAdminUser.id;
        insert cioUser; 
        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        insert acc;
        
        Date myDate = Date.newInstance(2020, 5, 17);
        Contract con = new Contract(Name = 'Test',UOS_Rebate_Rate__c=88, UOS_Target__c=99,AccountId =acc.id,Contract_End_Date__c=myDate,ECM_Agreement_Type__c=contractType.id,ECM_Duration__c=2,ECM_Overall_Investment_Amount__c=40.00,ECM_Territory__c=territory.id,UOS_Earnt__c=3.00,UOS_AP_Rate__c=2.00,AP_Spent__c=2.00,Opening_AP_Balance__c=5.00,ECM_Channel__c='Hybrid',Venue_Type__c ='Premium[AU]',RecordTypeId = contractRecordTypeId);
        insert con;
        con.Status = 'Active';
        update con;
        
        system.assertEquals(con.Status,'Active','Contract not Active');
        
        ECM_Contract_Item__c eci = new ECM_Contract_Item__c();
        eci.ECM_MAT_override__c = 20.00;
        eci.ECM_Contract__c = con.id;
        eci.ECM_MAT_UOS__c = 20.00;
        eci.ECM_Total_GP__c = 20.00;
        eci.ECM_Total_COGS__c = 20.00;
        eci.ECM_Actual_Volume_YTD__c=100;
        eci.ECM_Total_SKU_Specific_Rebate_ON__c = 10.00;
        eci.ECM_TotalSKU_SpecificRebate__c = 10.00;
        eci.ECM_Total_GP_ON__c = 20.00;
        insert eci;
        
        ECM_Tiering__c tier = ECM_CreateContractController.createTieringRecord(ECI.Id, 10, 1, 0, 2, 0, 3);
        System.assertEquals(tier.ECM_Contract_Item__c, ECI.Id, 'tier is not isserted');        
        
        Pick_Up_Options__c budgetTypeObj= ECM_UtilityTestClass.createPickUpOption(geographyId,pickupRecordTypeId);
        budgetTypeObj.Name='TI[ES]';
        budgetTypeObj.ECM_SAP_Order_reason__c = 'Y10'; 
        budgetTypeObj.ECM_SAP_Pricing_condition__c = 'O25';
        insert budgetTypeObj;
        
        ECM_Payment_Summary__c paymentSummary2 = new ECM_Payment_Summary__c();
        paymentSummary2.ECM_Total_Amount_Confirmed__c = 20.00;
        paymentSummary2.ECM_Payment_Summary_Status__c = 'Approved';
        paymentSummary2.ECM_Type__c = 'Volume-Based';
        paymentSummary2.ECM_Contract__c = con.id;
        paymentSummary2.ECM_Start_Period__c = system.today();
        paymentSummary2.ECM_End_Period__c = system.today()+2;
        paymentSummary2.ECM_Budget_types__c = budgetTypeObj.id;
        paymentSummary2.ECM_Invoice_Status__c ='Approved';
        paymentSummary2.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymentSummary2.ECM_SAP_payment_Reference_Number__c=10;
        paymentSummary2.ECM_Email_Sent__c =false;
        insert paymentSummary2;
        
        ECM_Payment_Summary_Item__c paymentSummaryItem = new ECM_Payment_Summary_Item__c();
        paymentSummaryItem.ECM_Payment_Summary__c = paymentSummary2.id;
        paymentSummaryItem.ECM_Confirm__c = true;
        paymentSummaryItem.ECM_Contract_Item__c = eci.id;			
        paymentSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
        insert paymentSummaryItem;
        
        ECM_CreatePaymentSummaryController.createPaymentSummary(con.id);
        ECM_CreatePaymentSummaryController.createPaymentSummaryNonVolume(con.id);
        ECM_CreatePaymentSummaryController.retrivePaymentSummary(con.id) ;
        User mdmES = EDGE_UtilityTestClass.runAsUser('salesRep8','Master Data Manager');
        mdmES.Available_Countries__c = 'ES';
        //  salesManager.ManagerId = testAdminUser.id;
        insert mdmES; 
        
        
        ECM_CreatePaymentSummaryController.retriveCurrentUserProfile();
        ECM_CreatePaymentSummaryController.PaymentSummaryWrapper psWrap = new ECM_CreatePaymentSummaryController.PaymentSummaryWrapper();
        psWrap.status = 'Test';
        psWrap.PsName = 'Testps';
        system.runAs(mdmES) {
            // The following code runs as user 'u'
            ECM_CreatePaymentSummaryController.fetchUserDetails();
        }
        
    }
    @isTest
    static void testCreatePaymentSummaryController4(){
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        String pickupRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        user newuser = EDGE_UtilityTestClass.runAsUser('Testabc','System Administrator');
        insert newuser;
        
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        insert territory;
        
        Id marketRecordTypeId = Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Market').getRecordTypeId();
        Geography__c geoMarket = [SELECT Id from Geography__c where RecordTypeId=:marketRecordTypeId LIMIT 1];
        
        Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(geoMarket.Id);
        mktSetting.Depletion_market__c=false;
        mktSetting.Ecm_Enable_Target__c = true;
        mktSetting.ECM_Payment_Opt_for_Exceeding_Tier_3_Vol__c = 'Pay only per tier 3 volume limit (opt.2)';
        mktSetting.ECM_Tiering_for_Volume_investment__c = true;
        mktSetting.ECM_Tiering_Payment_Amount_Calculation__c = 'Top-Level Achievement';
        insert mktSetting;
        
        ECM_Contract_Type__c contractType=ECM_UtilityTestClass.getAgreementType(geographyId);
        contractType.ECM_Volume_UoM_for_Beer__c='EU';
        contractType.ECM_Volume_UoM_for_RTD__c = 'Can/Bottle 24 Pack';
        contractType.ECM_Volume_UoM_for_Draught_Cocktails__c = '10L BIB';
        insert contractType;
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep1','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        //  salesManager.ManagerId = testAdminUser.id;
        insert salesRep; 
        
        User cioUser = EDGE_UtilityTestClass.runAsUser('salesRep1','CIO User');
        cioUser.Available_Countries__c = 'AU';
        //  salesManager.ManagerId = testAdminUser.id;
        insert cioUser; 
        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        insert acc;
        
        Date myDate = Date.newInstance(2020, 5, 17);
        Contract con = new Contract(Name = 'Test',UOS_Rebate_Rate__c=88, UOS_Target__c=99,AccountId =acc.id,Contract_End_Date__c=myDate,ECM_Agreement_Type__c=contractType.id,ECM_Duration__c=2,ECM_Overall_Investment_Amount__c=40.00,ECM_Territory__c=territory.id,UOS_Earnt__c=3.00,UOS_AP_Rate__c=2.00,AP_Spent__c=2.00,Opening_AP_Balance__c=5.00,ECM_Channel__c='Hybrid',Venue_Type__c ='Premium[AU]',RecordTypeId = contractRecordTypeId);
        insert con;
        con.Status = 'Active';
        update con;
        
        system.assertEquals(con.Status,'Active','Contract not Active');
        
        ECM_Contract_Item__c eci = new ECM_Contract_Item__c();
        eci.ECM_MAT_override__c = 20.00;
        eci.ECM_Contract__c = con.id;
        eci.ECM_MAT_UOS__c = 20.00;
        eci.ECM_Total_GP__c = 20.00;
        eci.ECM_Total_COGS__c = 20.00;
        eci.ECM_Actual_Volume_YTD__c=100;
        eci.ECM_Total_SKU_Specific_Rebate_ON__c = 10.00;
        eci.ECM_TotalSKU_SpecificRebate__c = 10.00;
        eci.ECM_Total_GP_ON__c = 20.00;
        insert eci;
        
        ECM_Tiering__c tier = ECM_CreateContractController.createTieringRecord(ECI.Id, 10, 1, 0, 2, 0, 3);
        
        System.assertEquals(tier.ECM_Contract_Item__c, ECI.Id, 'tier is not isserted');
        
        Pick_Up_Options__c budgetTypeObj= ECM_UtilityTestClass.createPickUpOption(geographyId,pickupRecordTypeId);
        budgetTypeObj.Name='TI[ES]';
        budgetTypeObj.ECM_SAP_Order_reason__c = 'Y10'; 
        budgetTypeObj.ECM_SAP_Pricing_condition__c = 'O25';
        insert budgetTypeObj;
        
        ECM_Payment_Summary__c paymentSummary2 = new ECM_Payment_Summary__c();
        paymentSummary2.ECM_Total_Amount_Confirmed__c = 20.00;
        paymentSummary2.ECM_Payment_Summary_Status__c = 'Approved';
        paymentSummary2.ECM_Type__c = 'Volume-Based';
        paymentSummary2.ECM_Contract__c = con.id;
        paymentSummary2.ECM_Start_Period__c = system.today();
        paymentSummary2.ECM_End_Period__c = system.today()+2;
        paymentSummary2.ECM_Budget_types__c = budgetTypeObj.id;
        paymentSummary2.ECM_Invoice_Status__c ='Approved';
        paymentSummary2.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymentSummary2.ECM_SAP_payment_Reference_Number__c=10;
        paymentSummary2.ECM_Email_Sent__c =false;
        insert paymentSummary2;
        
        ECM_Payment_Summary_Item__c paymentSummaryItem = new ECM_Payment_Summary_Item__c();
        paymentSummaryItem.ECM_Payment_Summary__c = paymentSummary2.id;
        paymentSummaryItem.ECM_Confirm__c = true;
        paymentSummaryItem.ECM_Contract_Item__c = eci.id;			
        paymentSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
        insert paymentSummaryItem;
        
        ECM_CreatePaymentSummaryController.createPaymentSummary(con.id);
        ECM_CreatePaymentSummaryController.createPaymentSummaryNonVolume(con.id);
        ECM_CreatePaymentSummaryController.retrivePaymentSummary(con.id) ;
        User mdmES = EDGE_UtilityTestClass.runAsUser('salesRep8','Master Data Manager');
        mdmES.Available_Countries__c = 'ES';
        //  salesManager.ManagerId = testAdminUser.id;
        insert mdmES; 
        
        ECM_CreatePaymentSummaryController.retriveCurrentUserProfile();
        ECM_CreatePaymentSummaryController.PaymentSummaryWrapper psWrap = new ECM_CreatePaymentSummaryController.PaymentSummaryWrapper();
        psWrap.status = 'Test';
        psWrap.PsName = 'Testps';
        system.runAs(mdmES) {
            // The following code runs as user 'u'
            ECM_CreatePaymentSummaryController.fetchUserDetails();
        }
        
    }
}