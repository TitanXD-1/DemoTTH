/*
*@Name: ECM_ReviewAndSubmitController_Test
*@Description: This class is used to cover test data for the - ECM_ReviewAndSubmitController,ECM_CreatePaymentSummaryController,ECM_getcontractitemdetails
*@History                                                            
                                                           
VERSION    AUTHOR                   DATE              DETAIL
1.0      Inayathulla Md      16/04/2020        Initial Development
2.0		 Saurav Prasad		 23/08/2021		   ECM-4689 Email Templates for Product level investment exceeding threshold
3.0      Joshraj Sen         03/04/2024        SCA Fix 152305
4.0      Sakshi Shah         14/05/2024        PMD Fix
*/
@istest
public class ECM_ReviewAndSubmitController_Test {
    @isTest
    static void testMethodForEmailTemplate(){
        Profile prof = [select id from profile where name=: 'Sales Representative'];
        User usr = new User();
        usr.firstName = 'test1';
        usr.lastName = 'test2';
        usr.profileId = prof.id;        
        usr.email = 'test@test.com';
        usr.Username ='testcm123@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='ES';
        usr.Title='Legal';
        insert usr;
        System.assert(usr.Id!=null,'User is Added');
        Id geographyId = EDGE_UtilityTestClass.setupCountry('ES'); 
        
        String brecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        
        Territory_Hierarchy__c hirarchy= ECM_UtilityTestClass.createhirarchy(geographyId);
        hirarchy.recordtypeId=Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Activation Territory').getRecordTypeId();
        insert hirarchy;
        
        Territory__c testterritory=New Territory__c();
        testterritory.Name='Testterriotory';
        testterritory.Territory_Type__c='Sales';
        testterritory.Country__c= geographyId;
        testterritory.Status__c='Active';
        testterritory.Primary_Sales_Rep__c = usr.id;
        testterritory.Activation_Territory__c = hirarchy.Id;
        insert testterritory;
        
        Pick_Up_Options__c budjectEU= new Pick_Up_Options__c();
        budjectEU.Name='TI [ES]';
        budjectEU.Geography__c=geographyId;
        budjectEU.RecordTypeId=brecordTypeId;
        insert budjectEU;
                
        Territory_Budget__c terriBudget1 = ECM_UtilityTestClass.createTerritoryBudget(testterritory.Id, hirarchy.Id);
        terriBudget1.ECM_Budget_Type__c=budjectEU.Id;
        insert terriBudget1;
        
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.Volume_UoM_for_Spirits__c='BTL';
        contractType.ECM_Volume_UoM_for_Beer__c='EU';
        contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;Volume Target;Investment';
        insert contractType;
        
                
        String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        
        Pick_Up_Options__c banner= new Pick_Up_Options__c();
        banner.Name='Range[ES]';
        banner.Geography__c=geographyId;
        banner.RecordTypeId=bannerRecordTypeId;
        insert banner;
        
        Market_Setting__c mktSetting = new Market_Setting__c();
        mktSetting.Name = 'Market Setting';
        mktSetting.Geography__c = geographyId;
        //mktSetting.Business_Hours__c = bHourList[0].Id;
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
        mktSetting.ECM_Contract_Approval_Template__c='ECM_Contract_Approval_Template';
        mktSetting.ECM_Contract_Header_Details__c='ECM_Contract_Owner__c;ECM_Territory__r.Name;Account.ECM_Legal_Name__c;Account.Name;ECM_Agreement_Type__r.Name;StartDate;Contract_End_Date__c;ContractNumber;Name';
        mktSetting.ECM_Investment_Summary_KPIS__c='ECM_Total_Volume_Target_Spirits__c;ECM_Total_Volume_Target_Beers__c;ECM_Incremental_Volume_Spirits__c;ECM_Incremental_Volume_Beers__c;ECM_Total_trade_investment_Beers__c;ECM_Total_A_P_Investment_Spirits__c;ECM_Incremental_GP__c;ECM_Incremental_GP_Beers__c';
        mktSetting.ECM_Category_Split_KPIS__c='ECM_NSV_reserve_share__c;ECM_NSV_premium_core_share__c;ECM_GP_reserve_share__c;ECM_GP_innovation_share__c;ECM_GM_reserve_share__c;ECM_GM_innovation_share__c;ECM_GM_premium_core_share__c;ECM_TV_reserve_share__c;ECM_TV_premium_core_share__c;ECM_IV_reserve_share__c;ECM_IV_innovation_share__c;ECM_IV_premium_core_share__c';
        mktSetting.ECM_Product_Investment_Details__c='ECM_Retro_investment__c;ECM_Trade_Investments__c;ECM_AnP_investment__c;ECM_Gross_margin__c;ECM_Total_GP_EU__c;ECM_Generated_NSV_EU__c;ECM_NSV_After_Investment__c;ECM_Incremental_GP_after_Investment__c;Tiers;ECM_UoM__c;ECM_Baseline_volume__c;ECM_Volume__c;ECM_Incremental_Volume__c;ECM_CAAP_Total__c;ECM_Product_growth_driver__c';
        mktSetting.ECM_Sales_Drivers_Details__c='ECM_Investement_Description__c;ECM_Budget_Type__c;ECM_Payment_Frequency__r.ECM_Type__c;Payment dates;ECM_Total_Investment_Amount__c;ECM_Prepayment__c;ECM_Sales_Driver_Name__c';
        mktSetting.ECM_Sales_Driver_Item_Details__c = 'Investment;Product Name;Upper Limit Amount;Sales Driver';
        //  mktSetting.Geography__r.Name='Australia';
        insert mktSetting;
        
        
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Person_Responsible__c= usr.Id;
        outletAccount.OwnerId = usr.Id;
        outletAccount.Country__c=geographyId;
        insert outletAccount;
        
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
      
        Product__c product = new Product__c();
        product.Name='Test';
        product.Product_Full_Name__c='Test';
        product.Country__c=geographyId;
        insert product;
        Product_UOM__c prdtUOM = new Product_UOM__c();
        prdtUOM.Product__c = product.Id;
        prdtUOM.Conversion_Factor__c = 2;
        prdtUOM.Type__c = 'BTL';
        prdtUOM.Unique_ID__c = product.Id + '_BTL';
        insert prdtUOM;
        Market_Assortment_Product__c marketassort = new Market_Assortment_Product__c();
        marketassort.Product__c=product.Id;
        marketassort.Market_Assortment__c=geographyId;
        //marketassort.ECM_Strategy__c='2';
        insert marketassort;
        ECM_Product_Agreement__c productagg = new ECM_Product_Agreement__c();
        productagg.ECM_Market_Assortment_Product__c=marketassort.Id;
        productagg.ECM_Contract_Type__c=contractType.Id;
        insert productagg;
        
        ECM_Contract_Item__c newcontractitem= new ECM_Contract_Item__c();
        newcontractitem.ECM_Contract__c=objContract.Id;
        newcontractitem.ECM_Product__c=marketassort.id;
        insert newcontractitem;
        
        ECM_Sales_Driver__c salesDriver = ECM_UtilityTestClass.getSalesdriver(terriBudget1.Id,geographyId);
        insert salesDriver;
        
		ECM_Sales_Driver_Item__c eSCDI = new ECM_Sales_Driver_Item__c(Contract__c=objContract.Id,ECM_Sales_Driver__c=salesDriver.Id);
        eSCDI.ECM_Total_Investment_Amount__c = 150;
        insert eSCDI;
        
        ECM_Sales_Driver_Item_Detail__c salesDetails1 = ECM_UtilityTestClass.insertSalesdriverDetails(eSCDI, newcontractitem);
        salesDetails1.ECM_Investment_Amount__c = 200;
        insert salesDetails1;
        
        ECM_Extra_Approval__c ecmEX4 = new ECM_Extra_Approval__c();
        ecmEX4.ECM_Active__c = true;
        ecmEX4.ECM_Approver_Position_Name__c = 'Test Approver';
        ecmEX4.ECM_Approver_s_Email_Address__c = 'name.surname@diageo.com';
        ecmEX4.ECM_Upper_Limit_Amount__c = 200;
        ecmEX4.ECM_Enable_Delegation__c = false;
        ecmEX4.ECM_Type__c = 'Contract Sales Driver Item';
        ecmEX4.ECM_Delegated_Approver_Email_Address__c ='Test2@test.com';
        insert ecmEX4;
        
        ECM_Agreement_Approval__c ecmAA4 = new ECM_Agreement_Approval__c();
        ecmAA4.ECM_Agreement_Type__c = contractType.Id;
        ecmAA4.ECM_Extra_Approval__c = ecmEX4.Id;
        insert ecmAA4;
        
        Test.startTest();
        
        Contract con =[Select id,Name,AccountId,Account.Country_Code__c,ECM_EU_Total_Trade_Investment__c,ECM_Overall_Investment_Figure__c,ECM_Total_A_P_Investment__c,ECM_Total_GP__c,ECM_GP_ROI__c,ECM_CAP_ROI__c,ECM_of_the_total_investment_vs_NSV__c,ECM_Variable_share__c,ECM_Fixed_share__c,ECM_Total_TI_Investment__c,ECM_Total_trade_investment_Spirits__c,ECM_Total_trade_investment_Beers__c,ECM_Total_A_P_Investment_Spirits__c,ECM_Total_A_P_Investment_Beers__c,
                            ECM_Total_SKU_Specific_Rebate_Over_Term__c,ECM_Total_Others_Over_Term__c,ECM_Agreement_Type__r.ECM_Upfront_Deed_Minimum__c,ECM_Total_Training_Over_Term__c,ECM_Total_Upfront_Payment_Loan_Over_Term__c,ECM_Total_A_P_investments__c,ECM_Overall_investments__c,ContractNumber,ECM_Last_saved_page__c,Contract_End_Date__c,ECM_Duration__c,Status,
                            StartDate,recordTypeId,ECM_Banner__c,Venue_Type__c,ECM_Channel__c,BillingState,ECM_RTD_Sales_driver__c,ECM_Generated_NSV__c,ECM_Additional_information_to_support__c,
                            ECM_Spirits_Sales_driver__c,ECM_Spirits_Pouring_Sales_driver__c,ECM_Spirits_Premium_Sales_driver__c,ECM_Territory__c,ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c,ECM_Hybrid_CustInvest_Total_PercentGP__c,
                            ECM_Spirits_Reserve_Sales_driver__c,ECM_Selected_Payment_Schedule_AU__c,ECM_Additional_info_to_support_decision__c,UOS_Rebate_Rate__c,ECM_Agreement_Type__c,ECM_OnPremise_Total_A_P_PerYear__c,ECM_Payment_Schedule_Date_AU__c,CreatedBy.Name from Contract Where Id=:objContract.id];
        ECM_GetContractItemDetails getcontractitemdetails = new ECM_GetContractItemDetails();
        getcontractitemdetails.targetObjectId =con.Id; 
        getcontractitemdetails.getContractItems();
        getcontractitemdetails.getOutletContracts();
        getcontractitemdetails.getsalesDriver();
        getcontractitemdetails.getAccountId();
        getcontractitemdetails.getDraftContractDetails();
        getcontractitemdetails.getContractDetails();
        getcontractitemdetails.getActiveContractDetails();
        getcontractitemdetails.getContHeaderDetails();
        getcontractitemdetails.getInvSumDetails();
        getcontractitemdetails.getProductDetails();
        
        Test.stopTest();

    }
    @istest
    static void testReviewHybridCaluculatons(){
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        String pickuprecordtypeid = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        String type='';
        type='Local-Segment1';
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        user newuser = EDGE_UtilityTestClass.runAsUser('Testabc','System Administrator');
        insert newuser;
        System.assert(newuser!=null,'User is added');
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        insert territory;
        
        
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.Volume_UoM_for_Spirits__c='BTL';
        contractType.ECM_Volume_UoM_for_Beer__c='EU';
        contractType.ECM_Automatic_approval_amount_threshold__c = 40.00;
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Volume Target;';
        contractType.ECM_Mandatory_Fields_Check__c ='Prior To Submitting Contract For Approval';
        insert contractType;
		
		ECM_Payment_Frequency__c paymentFrequency=new ECM_Payment_Frequency__c();
		paymentFrequency.ECM_Geography__c=geographyId;
		paymentFrequency.ECM_Type__c='Equal Instalments';
		paymentFrequency.ECM_Other_Investment__c=true;
		insert paymentFrequency;
		
		ECM_Payment_Agreement__c paymentAgreement= new ECM_Payment_Agreement__c();
		paymentAgreement.ECM_Agreement_Type__c=contractType.Id;
		paymentAgreement.ECM_Payment_Frequency__c=paymentFrequency.id;
		
		insert paymentAgreement;
		
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep1','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        //  salesManager.ManagerId = testAdminUser.id;
        insert salesRep; 
        
        User cIOuser = EDGE_UtilityTestClass.runAsUser('salesRep1','CIO User');
        cIOuser.Available_Countries__c = 'AU';
        //  salesManager.ManagerId = testAdminUser.id;
        insert cIOuser; 
        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.Country__c = geographyId;
        insert acc;
        
        Date myDate = Date.newInstance(system.today().year()+1, 5, 17);
        Date myStartDate = Date.newInstance(system.today().year(), 5, 17);
        Contract conRecord = new Contract(Name = 'Test',Status='Draft',StartDate=myStartDate,UOS_Rebate_Rate__c=88, UOS_Target__c=99,AccountId =Acc.id,Contract_End_Date__c=myDate,ECM_Agreement_Type__c=contractType.id,ECM_Duration__c=2,ECM_Overall_Investment_Amount__c=40.00,ECM_Territory__c=territory.id,UOS_Earnt__c=3.00,UOS_AP_Rate__c=2.00,AP_Spent__c=2.00,Opening_AP_Balance__c=5.00,ECM_Channel__c='Hybrid',Venue_Type__c ='Premium[AU]',RecordTypeId = contractRecordTypeId,ECM_Selected_Payment_Schedule_AU__c=paymentFrequency.Id);
        insert conRecord;
		Contract con =[Select id,Name,AccountId,Account.Country_Code__c,ECM_EU_Total_Trade_Investment__c,ECM_Overall_Investment_Figure__c,ECM_Total_A_P_Investment__c,ECM_Total_GP__c,ECM_GP_ROI__c,ECM_CAP_ROI__c,ECM_of_the_total_investment_vs_NSV__c,ECM_Variable_share__c,ECM_Fixed_share__c,ECM_Total_TI_Investment__c,ECM_Total_trade_investment_Spirits__c,ECM_Total_trade_investment_Beers__c,ECM_Total_A_P_Investment_Spirits__c,ECM_Total_A_P_Investment_Beers__c,
                            ECM_Total_SKU_Specific_Rebate_Over_Term__c,ECM_Total_Others_Over_Term__c,ECM_Agreement_Type__r.ECM_Upfront_Deed_Minimum__c,ECM_Total_Training_Over_Term__c,ECM_Total_Upfront_Payment_Loan_Over_Term__c,ECM_Total_A_P_investments__c,ECM_Overall_investments__c,ContractNumber,ECM_Last_saved_page__c,Contract_End_Date__c,ECM_Duration__c,Status,
                            StartDate,recordTypeId,ECM_Banner__c,Venue_Type__c,ECM_Channel__c,BillingState,ECM_RTD_Sales_driver__c,ECM_Generated_NSV__c,ECM_Additional_information_to_support__c,
                            ECM_Spirits_Sales_driver__c,ECM_Spirits_Pouring_Sales_driver__c,ECM_Spirits_Premium_Sales_driver__c,ECM_Territory__c,ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c,ECM_Hybrid_CustInvest_Total_PercentGP__c,
                            ECM_Spirits_Reserve_Sales_driver__c,ECM_Selected_Payment_Schedule_AU__c,ECM_Additional_info_to_support_decision__c,UOS_Rebate_Rate__c,ECM_Agreement_Type__c,ECM_OnPremise_Total_A_P_PerYear__c,ECM_Payment_Schedule_Date_AU__c,CreatedBy.Name from Contract Where Id=:conRecord.id];
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
		
        Pick_Up_Options__c pOption = new Pick_Up_Options__c();
        pOption.Name = 'Gold[AUT]';
        pOption.Geography__c = geographyId;
        pOption.Type__c = 'Local-Segment1';
        pOption.RecordTypeId = pickuprecordtypeid;
        pOption.Days_between_visit__c = 5;
        pOption.Status__c = 'Active';
        insert pOption;
        
        Pick_Up_Options__c budgetTypeObj1= new Pick_Up_Options__c();
		budgetTypeObj1.Name='Upfront Payment [AU]';
		budgetTypeObj1.Geography__c=geographyId;
        budgetTypeObj1.Status__c = 'Active';
		budgetTypeObj1.RecordTypeId=Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
		insert budgetTypeObj1;

        Pick_Up_Options__c budgetTypeObj2= new Pick_Up_Options__c();
        budgetTypeObj2.Name='On-Premise[AU]';
        budgetTypeObj2.Geography__c=geographyId;
        budgetTypeObj2.RecordTypeId=Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        budgetTypeObj2.ECM_SAP_Order_reason__c = 'Y10'; 
        budgetTypeObj2.ECM_SAP_Pricing_condition__c = 'O25';
        insert budgetTypeObj2;
        
        ECM_Contract_Item__c eCI = new ECM_Contract_Item__c();
        eCI.ECM_MAT_override__c = 20.00;
        eCI.ECM_Contract__c = con.id;
        eCI.ECM_MAT_UOS__c = 20.00;
        eCI.ECM_Total_GP__c = 20.00;
        eCI.ECM_Total_COGS__c = 20.00;
        eCI.ECM_Total_SKU_Specific_Rebate_ON__c = 10.00;
        eCI.ECM_TotalSKU_SpecificRebate__c = 10.00;
        eCI.ECM_Total_GP_ON__c = 20.00;
        insert eCI;        
        
        ECM_ReviewAndSubmitController.Wrapper_Review_cal hybridreview = ECM_ReviewAndSubmitController.ReviewHybridCaluculatons(con);
        ECM_ReviewAndSubmitController.Wrapper_Review_cal onpremisereview = ECM_ReviewAndSubmitController.Review_On_Premise_Caluculatons(con);
        ECM_ReviewAndSubmitController.totaldisplay tdisplay = null;
        tdisplay = new ECM_ReviewAndSubmitController.totaldisplay();
        ECM_ReviewAndSubmitController.get_active_A_Precord(con);
        ECM_ReviewAndSubmitController.submitForApproval(con);
       // ECM_ReviewAndSubmitController.sendEmailToUser(newuser,con);
        ECM_ReviewAndSubmitController.getUser(newuser.id);
        ECM_ReviewAndSubmitController.getTerritory(territory.id);
        ECM_ReviewAndSubmitController.getguidelines(con,20.00,20.00,null);
        string hybridreviewstr=JSON.serialize(hybridreview);
        string onpremisereviewstr=JSON.serialize(onpremisereview);
        ECM_ReviewAndSubmitController.SaveContract(con,'100.00','100.00',hybridreviewstr,onpremisereviewstr,100.00);
        ECM_ReviewAndSubmitController.getcontractdetails(con);
        ECM_ReviewAndSubmitController.getvolumeOverview(con.Id);
        ECM_ReviewAndSubmitController.validationErrorCheck(con);

        ECM_ReviewAndSubmitController.paymentSchedulevalues(contractType.id);
       // ECM_ReviewAndSubmitController.getvolumeOverview(con.id);
       // ECM_CreatePaymentSummaryController.retrivePaymentSummary(con.id) ;
        ECM_getcontractitemdetails getcontractitemdetails = new ECM_getcontractitemdetails();
        getcontractitemdetails.targetObjectId =con.Id; 
        getcontractitemdetails.getContractItems();
        getcontractitemdetails.getOutletContracts();
        getcontractitemdetails.getsalesDriver();
        getcontractitemdetails.getAccountId();
        getcontractitemdetails.getDraftContractDetails();
        getcontractitemdetails.getContractDetails();
        getcontractitemdetails.getActiveContractDetails();
        getcontractitemdetails.getContHeaderDetails();
        getcontractitemdetails.getInvSumDetails();
        getcontractitemdetails.getProductDetails();
         /* ECM_CreatePaymentSummaryController getpaymentdetails = new ECM_CreatePaymentSummaryController();
        getpaymentdetails.retriveContract(con.id) ;
      getpaymentdetails.geoCountry=geographyId;
        //getpaymentdetails.getPsDetails();
        getpaymentdetails.getPsItemsDetails();
            getpaymentdetails.getMsDetails();*/
    }
    @istest
    static void testCreatePaymentSummaryController(){
         String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        String pickuprecordtypeid = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        String type='';
        type='Local-Segment1';
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        user newuser = EDGE_UtilityTestClass.runAsUser('Testabc','System Administrator');
        insert newuser;
        System.assert(newuser!=null,'User Added');
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        insert territory;
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.Volume_UoM_for_Spirits__c='BTL';
        contractType.ECM_Volume_UoM_for_Beer__c='EU';
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Volume Target;';        
        contractType.ECM_Automatic_approval_amount_threshold__c = 40.00;
        contractType.ECM_Mandatory_Fields_Check__c ='Prior To Submitting Contract For Approval';       
        insert contractType;
        
           User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep1','Sales Representative');
            salesRep.Available_Countries__c = 'AU';
          //  salesManager.ManagerId = testAdminUser.id;
            insert salesRep; 
        
        User cIOuser = EDGE_UtilityTestClass.runAsUser('salesRep1','CIO User');
            cIOuser.Available_Countries__c = 'AU';
          //  salesManager.ManagerId = testAdminUser.id;
            insert cIOuser; 
        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        insert acc;
        
        Date myDate = Date.newInstance(2020, 5, 17);
        Contract con = new Contract(Name = 'Test',UOS_Rebate_Rate__c=88, UOS_Target__c=99,AccountId =Acc.id,Contract_End_Date__c=myDate,ECM_Agreement_Type__c=contractType.id,ECM_Duration__c=2,ECM_Overall_Investment_Amount__c=40.00,ECM_Territory__c=territory.id,UOS_Earnt__c=3.00,UOS_AP_Rate__c=2.00,AP_Spent__c=2.00,Opening_AP_Balance__c=5.00,ECM_Channel__c='Hybrid',Venue_Type__c ='Premium[AU]',RecordTypeId = contractRecordTypeId);
        insert con;
        con.Status = 'Active';
        update con;
        ECM_Contract_Item__c eCI = new ECM_Contract_Item__c();
        eCI.ECM_MAT_override__c = 20.00;
        eCI.ECM_Contract__c = con.id;
        eCI.ECM_MAT_UOS__c = 20.00;
        eCI.ECM_Total_GP__c = 20.00;
        eCI.ECM_Total_COGS__c = 20.00;
        eCI.ECM_Total_SKU_Specific_Rebate_ON__c = 10.00;
        eCI.ECM_TotalSKU_SpecificRebate__c = 10.00;
        eCI.ECM_Total_GP_ON__c = 20.00;
        insert eCI;
        
        ECM_Tiering__c tier = new ECM_Tiering__c();
        tier=ECM_CreateContractController.createTieringRecord(eci.Id, 10, 1, 20, 2, 30, 3);
        
        ECM_Tiering__c tier2 = new ECM_Tiering__c();
        tier2=ECM_CreateContractController.createTieringRecord(eci.Id, 5, 1, 10, 2,15, 3);
                    
		Pick_Up_Options__c budgetTypeObj= new Pick_Up_Options__c();
		budgetTypeObj.Name='TI[ES]';
		budgetTypeObj.Geography__c=geographyId;
		budgetTypeObj.RecordTypeId=pickuprecordtypeid;
		budgetTypeObj.ECM_SAP_Order_reason__c = 'Y10'; 
		budgetTypeObj.ECM_SAP_Pricing_condition__c = 'O25';
		insert budgetTypeObj;
        
         ECM_Payment_Summary__c paymemtSummary2 = new ECM_Payment_Summary__c();
        paymemtSummary2.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummary2.ECM_Payment_Summary_Status__c = 'Approved';
        paymemtSummary2.ECM_Type__c = 'Volume-Based';
        paymemtSummary2.ECM_Contract__c = con.id;
		paymemtSummary2.ECM_Start_Period__c = system.today();
		paymemtSummary2.ECM_End_Period__c = system.today()+2;
		paymemtSummary2.ECM_Budget_types__c = budgetTypeObj.id;
		paymemtSummary2.ECM_Invoice_Status__c ='Approved';
		paymemtSummary2.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymemtSummary2.ECM_SAP_payment_Reference_Number__c=10;
        paymemtSummary2.ECM_Email_Sent__c =false;
        insert paymemtSummary2;
        
        ECM_Payment_Summary_Item__c paymemtSummaryItem = new ECM_Payment_Summary_Item__c();
        paymemtSummaryItem.ECM_Payment_Summary__c = paymemtSummary2.id;
        paymemtSummaryItem.ECM_Confirm__c = true;
        paymemtSummaryItem.ECM_Contract_Item__c = eci.id;			
		paymemtSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
		insert paymemtSummaryItem;
        ECM_CreatePaymentSummaryController.createPaymentSummary(con.id);
        //ECM_CreatePaymentSummaryController.createPaymentSummaryNonVolume(con.id);
        //ECM_CreatePaymentSummaryController.retrivePaymentSummary(con.id) ;
        ECM_CreatePaymentSummaryController.retriveCurrentUserProfile();
       
    }
    @istest
    static void testCreatePaymentSummaryController1(){
         String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        String pickuprecordtypeid = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        String type='';
        type='Local-Segment1';
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        user newuser = EDGE_UtilityTestClass.runAsUser('Testabc','System Administrator');
        insert newuser;
        System.assert(newuser!=null,'New User');
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        insert territory;
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.Volume_UoM_for_Spirits__c='BTL';
        contractType.ECM_Volume_UoM_for_Beer__c='EU';
        contractType.ECM_Automatic_approval_amount_threshold__c = 40.00;
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Volume Target;';
        insert contractType;
        
           User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep1','Sales Representative');
            salesRep.Available_Countries__c = 'AU';
          //  salesManager.ManagerId = testAdminUser.id;
            insert salesRep; 
        
        User ciouser = EDGE_UtilityTestClass.runAsUser('salesRep1','CIO User');
            ciouser.Available_Countries__c = 'AU';
          //  salesManager.ManagerId = testAdminUser.id;
            insert ciouser; 
        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        insert acc;
        
        Date myDate = Date.newInstance(2020, 5, 17);
        Contract con = new Contract(Name = 'Test',UOS_Rebate_Rate__c=88, UOS_Target__c=99,AccountId =Acc.id,Contract_End_Date__c=myDate,ECM_Agreement_Type__c=contractType.id,ECM_Duration__c=2,ECM_Overall_Investment_Amount__c=40.00,ECM_Territory__c=territory.id,UOS_Earnt__c=3.00,UOS_AP_Rate__c=2.00,AP_Spent__c=2.00,Opening_AP_Balance__c=5.00,ECM_Channel__c='Hybrid',Venue_Type__c ='Premium[AU]',RecordTypeId = contractRecordTypeId);
        insert con;
        con.Status = 'Active';
        update con;
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
        
        ECM_Tiering__c tier = new ECM_Tiering__c();
        tier=ECM_CreateContractController.createTieringRecord(eci.Id, 0, 1, 20, 2, 30, 3);
        
        
                    
		Pick_Up_Options__c budgetTypeObj= new Pick_Up_Options__c();
		budgetTypeObj.Name='TI[ES]';
		budgetTypeObj.Geography__c=geographyId;
		budgetTypeObj.RecordTypeId=pickuprecordtypeid;
		budgetTypeObj.ECM_SAP_Order_reason__c = 'Y10'; 
		budgetTypeObj.ECM_SAP_Pricing_condition__c = 'O25';
		insert budgetTypeObj;
        
         ECM_Payment_Summary__c paymemtSummary2 = new ECM_Payment_Summary__c();
        paymemtSummary2.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummary2.ECM_Payment_Summary_Status__c = 'Approved';
        paymemtSummary2.ECM_Type__c = 'Volume-Based';
        paymemtSummary2.ECM_Contract__c = con.id;
		paymemtSummary2.ECM_Start_Period__c = system.today();
		paymemtSummary2.ECM_End_Period__c = system.today()+2;
		paymemtSummary2.ECM_Budget_types__c = budgetTypeObj.id;
		paymemtSummary2.ECM_Invoice_Status__c ='Approved';
		paymemtSummary2.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymemtSummary2.ECM_SAP_payment_Reference_Number__c=10;
        paymemtSummary2.ECM_Email_Sent__c =false;
        insert paymemtSummary2;
        
        ECM_Payment_Summary_Item__c paymemtSummaryItem = new ECM_Payment_Summary_Item__c();
        paymemtSummaryItem.ECM_Payment_Summary__c = paymemtSummary2.id;
        paymemtSummaryItem.ECM_Confirm__c = true;
        paymemtSummaryItem.ECM_Contract_Item__c = eci.id;			
		paymemtSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
		insert paymemtSummaryItem;
        
        ECM_CreatePaymentSummaryController.createPaymentSummary(con.id);
        ECM_CreatePaymentSummaryController.createPaymentSummaryNonVolume(con.id);
        ECM_CreatePaymentSummaryController.retrivePaymentSummary(con.id) ;
        ECM_CreatePaymentSummaryController.retriveCurrentUserProfile();
       
    }
    @istest
    static void testCreatePaymentSummaryController2(){
         String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        String pickuprecordtypeid = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        String type='';
        type='Local-Segment1';
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        user newuser = EDGE_UtilityTestClass.runAsUser('Testabc','System Administrator');
        insert newuser;
        System.assert(newuser!=null,'New User is Added');
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        insert territory;
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.Volume_UoM_for_Spirits__c='BTL';
        contractType.ECM_Volume_UoM_for_Beer__c='EU';
        contractType.ECM_Automatic_approval_amount_threshold__c = 40.00;
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Volume Target;';
        insert contractType;
        
           User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep1','Sales Representative');
            salesRep.Available_Countries__c = 'AU';
          //  salesManager.ManagerId = testAdminUser.id;
            insert salesRep; 
        
        User cIOuser = EDGE_UtilityTestClass.runAsUser('salesRep1','CIO User');
            cIOuser.Available_Countries__c = 'AU';
          //  salesManager.ManagerId = testAdminUser.id;
            insert cIOuser; 
        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        insert acc;
        
        Date myDate = Date.newInstance(2020, 5, 17);
        Contract con = new Contract(Name = 'Test',UOS_Rebate_Rate__c=88, UOS_Target__c=99,AccountId =Acc.id,Contract_End_Date__c=myDate,ECM_Agreement_Type__c=contractType.id,ECM_Duration__c=2,ECM_Overall_Investment_Amount__c=40.00,ECM_Territory__c=territory.id,UOS_Earnt__c=3.00,UOS_AP_Rate__c=2.00,AP_Spent__c=2.00,Opening_AP_Balance__c=5.00,ECM_Channel__c='Hybrid',Venue_Type__c ='Premium[AU]',RecordTypeId = contractRecordTypeId);
        insert con;
        con.Status = 'Active';
        update con;
        ECM_Contract_Item__c eCI = new ECM_Contract_Item__c();
        eCI.ECM_MAT_override__c = 20.00;
        eCI.ECM_Contract__c = con.id;
        eCI.ECM_MAT_UOS__c = 20.00;
        eCI.ECM_Total_GP__c = 20.00;
        eCI.ECM_Total_COGS__c = 20.00;
        eCI.ECM_Actual_Volume_YTD__c=10;
        eCI.ECM_Total_SKU_Specific_Rebate_ON__c = 10.00;
        eCI.ECM_TotalSKU_SpecificRebate__c = 10.00;
        eCI.ECM_Total_GP_ON__c = 20.00;
        insert eCI;
        
        ECM_Tiering__c tier = new ECM_Tiering__c();
        tier=ECM_CreateContractController.createTieringRecord(eci.Id, 0, 1, 0, 2, 30, 3);
        
                    
		Pick_Up_Options__c budgetTypeObj= new Pick_Up_Options__c();
		budgetTypeObj.Name='TI[ES]';
		budgetTypeObj.Geography__c=geographyId;
		budgetTypeObj.RecordTypeId=pickuprecordtypeid;
		budgetTypeObj.ECM_SAP_Order_reason__c = 'Y10'; 
		budgetTypeObj.ECM_SAP_Pricing_condition__c = 'O25';
		insert budgetTypeObj;
        
         ECM_Payment_Summary__c paymemtSummary2 = new ECM_Payment_Summary__c();
        paymemtSummary2.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummary2.ECM_Payment_Summary_Status__c = 'Approved';
        paymemtSummary2.ECM_Type__c = 'Volume-Based';
        paymemtSummary2.ECM_Contract__c = con.id;
		paymemtSummary2.ECM_Start_Period__c = system.today();
		paymemtSummary2.ECM_End_Period__c = system.today()+2;
		paymemtSummary2.ECM_Budget_types__c = budgetTypeObj.id;
		paymemtSummary2.ECM_Invoice_Status__c ='Approved';
		paymemtSummary2.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymemtSummary2.ECM_SAP_payment_Reference_Number__c=10;
        paymemtSummary2.ECM_Email_Sent__c =false;
        insert paymemtSummary2;
        
        ECM_Payment_Summary_Item__c paymemtSummaryItem = new ECM_Payment_Summary_Item__c();
        paymemtSummaryItem.ECM_Payment_Summary__c = paymemtSummary2.id;
        paymemtSummaryItem.ECM_Confirm__c = true;
        paymemtSummaryItem.ECM_Contract_Item__c = eci.id;			
		paymemtSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
		insert paymemtSummaryItem;
        
        ECM_CreatePaymentSummaryController.createPaymentSummary(con.id);
        ECM_CreatePaymentSummaryController.createPaymentSummaryNonVolume(con.id);
        ECM_CreatePaymentSummaryController.retrivePaymentSummary(con.id) ;
        ECM_CreatePaymentSummaryController.retriveCurrentUserProfile();
        
    }
    @isTest
    static void testCreatePaymentSummaryController3(){
         String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        String pickuprecordtypeid = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        String type='';
        type='Local-Segment1';
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        user newuser = EDGE_UtilityTestClass.runAsUser('Testabc','System Administrator');
        insert newuser;
        System.assert(newuser!=null,'New User is Added');
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        insert territory;
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.Volume_UoM_for_Spirits__c='BTL';
        contractType.ECM_Volume_UoM_for_Beer__c='EU';
        contractType.ECM_Automatic_approval_amount_threshold__c = 40.00;    
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Volume Target;';
        insert contractType;
        
           User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep1','Sales Representative');
            salesRep.Available_Countries__c = 'AU';
          //  salesManager.ManagerId = testAdminUser.id;
            insert salesRep; 
        
        User cIOuser = EDGE_UtilityTestClass.runAsUser('salesRep1','CIO User');
            cIOuser.Available_Countries__c = 'AU';
          //  salesManager.ManagerId = testAdminUser.id;
            insert cIOuser; 
        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        insert acc;
        
        Date myDate = Date.newInstance(2020, 5, 17);
        Contract con = new Contract(Name = 'Test',UOS_Rebate_Rate__c=88, UOS_Target__c=99,AccountId =Acc.id,Contract_End_Date__c=myDate,ECM_Agreement_Type__c=contractType.id,ECM_Duration__c=2,ECM_Overall_Investment_Amount__c=40.00,ECM_Territory__c=territory.id,UOS_Earnt__c=3.00,UOS_AP_Rate__c=2.00,AP_Spent__c=2.00,Opening_AP_Balance__c=5.00,ECM_Channel__c='Hybrid',Venue_Type__c ='Premium[AU]',RecordTypeId = contractRecordTypeId);
        insert con;
        con.Status = 'Active';
        update con;
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
        
        ECM_Tiering__c tier = new ECM_Tiering__c();
        tier=ECM_CreateContractController.createTieringRecord(eci.Id, 10, 1, 0, 2, 0, 3);
        

                    
		Pick_Up_Options__c budgetTypeObj= new Pick_Up_Options__c();
		budgetTypeObj.Name='TI[ES]';
		budgetTypeObj.Geography__c=geographyId;
		budgetTypeObj.RecordTypeId=pickuprecordtypeid;
		budgetTypeObj.ECM_SAP_Order_reason__c = 'Y10'; 
		budgetTypeObj.ECM_SAP_Pricing_condition__c = 'O25';
		insert budgetTypeObj;
        
         ECM_Payment_Summary__c paymemtSummary2 = new ECM_Payment_Summary__c();
        paymemtSummary2.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummary2.ECM_Payment_Summary_Status__c = 'Approved';
        paymemtSummary2.ECM_Type__c = 'Volume-Based';
        paymemtSummary2.ECM_Contract__c = con.id;
		paymemtSummary2.ECM_Start_Period__c = system.today();
		paymemtSummary2.ECM_End_Period__c = system.today()+2;
		paymemtSummary2.ECM_Budget_types__c = budgetTypeObj.id;
		paymemtSummary2.ECM_Invoice_Status__c ='Approved';
		paymemtSummary2.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymemtSummary2.ECM_SAP_payment_Reference_Number__c=10;
        paymemtSummary2.ECM_Email_Sent__c =false;
        insert paymemtSummary2;
        
        ECM_Payment_Summary_Item__c paymemtSummaryItem = new ECM_Payment_Summary_Item__c();
        paymemtSummaryItem.ECM_Payment_Summary__c = paymemtSummary2.id;
        paymemtSummaryItem.ECM_Confirm__c = true;
        paymemtSummaryItem.ECM_Contract_Item__c = eci.id;			
		paymemtSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
		insert paymemtSummaryItem;
        
        ECM_CreatePaymentSummaryController.createPaymentSummary(con.id);
        ECM_CreatePaymentSummaryController.createPaymentSummaryNonVolume(con.id);
        ECM_CreatePaymentSummaryController.retrivePaymentSummary(con.id) ;
         User salesRepES = EDGE_UtilityTestClass.runAsUser('salesRep8','Sales Representative');
            salesRepES.Available_Countries__c = 'ES';
          //  salesManager.ManagerId = testAdminUser.id;
            insert salesRepES; 
       

       LIST<ECM_Technical_Market_Setting__mdt> mDTS= new List<ECM_Technical_Market_Setting__mdt>();
       mDTS=[select masterlabel,ECM_Country__c,ECM_Payment_Summary_Volume__c,ECM_Contract_Extra_Approval__c from ECM_Technical_Market_Setting__mdt 
                                                        where ECM_Payment_Summary_Volume__c=True];
        ECM_CreatePaymentSummaryController.retriveCurrentUserProfile();
         //system.runAs(salesRepES) {
              // The following code runs as user 'u'
              // ECM_CreatePaymentSummaryController.fetchUserDetails();
          //}
         
    }
}