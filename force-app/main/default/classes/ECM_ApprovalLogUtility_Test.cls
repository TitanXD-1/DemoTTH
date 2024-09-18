/*
*@Name: ECM_ApprovalLogUtility_Test
*@Purpose: This class is used to cover testclass for the - ECM_ApprovalLogTriggerHelper & ECM_ApprovalLogUtility
*@History:                                                            
*VERSION       AUTHOR                  DATE                   DETAIL
*1.0      Saurav Kumar Prasad       			          Initial Development
*1.1         Pratap Sen             25/10/2022         updated updatePrimaryApprovalLog_Spain_ApproveScenario to cover new changes
*1.2     Joshraj Sen/Sakshi Shah    21/05/2024         PMD Fix 152943
*/
@isTest
public class ECM_ApprovalLogUtility_Test {
	/*
    * @description : tests ECM_ApprovalLogTriggerHelper methods & AU primary approval specific methods of ECM_ApprovalLogUtility
    * @return : void
    * @param : void
    */
	@isTest
    public static void updatePrimaryApprovalLogAustraliaApproveScenario(){
        User usr = ECM_UtilityTestClass.createUser('sr',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
        usr.Username = 'srUsr@test.com';
        usr.isActive = true;
        usr.Available_Countries__c = 'AU';
        insert usr;

        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        
        String bRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        
        Territory_Hierarchy__c hirarchy = ECM_UtilityTestClass.createhirarchy(geographyId);
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
        budjectEU.Name='TI [AU]';
        budjectEU.Geography__c=geographyId;
        budjectEU.RecordTypeId=bRecordTypeId;
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
        contractType.ECM_Automatic_approval_amount_threshold__c=400000.00;
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;Volume Target;Investment';
        contractType.ECM_Volume_UoM_for_RTD__c ='Can/Bottle 24 Pack';
        contractType.ECM_Volume_UoM_for_Draught_Cocktails__c='10L BIB';
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
        mktSetting.ECM_Contract_pdf_to_Approval_Mails__c = true;
        mktSetting.Enable_Auto_Approvals__c=true;
        mktSetting.ECM_Rejection_Email_to_Sales_Rep__c = true;
        insert mktSetting;
        
        
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Person_Responsible__c= usr.Id;
        outletAccount.OwnerId = usr.Id;
        outletAccount.Country__c=geographyId;
        insert outletAccount;
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Contract con = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        con.Status = 'Draft';
        con.Contract_End_Date__c = System.today()+29;
        con.ECM_Territory__c=testterritory.Id;
        con.ECM_Overall_Investment_Amount__c=100020.55;
        con.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c=12000934.32;
        con.ECM_Hybrid_CustInvest_Total_PercentGP__c=243123.33;
        con.ECM_Overall_Investment_Figure__c=122.43;
        con.ECM_Agreement_Type__c=contractType.Id;
        con.ECM_Channel__c='On-Premise';
        con.ECM_Banner__c=banner.Id;
        con.StartDate = system.today();
        con.Contract_End_Date__c = system.today()+360;
        insert con;
        
        Contract objContract = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract.Status = 'Draft';
        objContract.Contract_End_Date__c = System.today()+29;
        objContract.ECM_Territory__c=testterritory.Id;
        objContract.ECM_Overall_Investment_Amount__c=40.55;
        objContract.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c=12.32;
        objContract.ECM_Hybrid_CustInvest_Total_PercentGP__c=24.33;
        objContract.ECM_Overall_Investment_Figure__c=18.43;
        objContract.ECM_Agreement_Type__c=contractType.Id;
        objContract.ECM_Channel__c='On-Premise';
        objContract.ECM_Banner__c=banner.Id;
        objContract.StartDate = system.today();
        objContract.Contract_End_Date__c = system.today()+360;
        objContract.ECM_Recalled__c = true;
        objContract.ECM_Parent_Contract__c = con.Id;
        insert objContract;
        
        objContract.Status = 'In Approval Process';
        update objContract;
        
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
        ContentDocumentLink linkedFile = new ContentDocumentLink(LinkedEntityId=objContract.Id, ContentDocumentId=insertedFile.ContentDocumentId);
        insert linkedFile;
      
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
        
        ECM_Contract_Item__c newcontractitem1= new ECM_Contract_Item__c();
        newcontractitem1.ECM_Contract__c=objContract.Id;
        newcontractitem1.ECM_Product__c=marketassort.id;
        insert newcontractitem1;
        
        ECM_Contract_Item__c newcontractitem2= new ECM_Contract_Item__c();
        newcontractitem2.ECM_Contract__c=objContract.Id;
        newcontractitem2.ECM_Product__c=marketassort.id;
        insert newcontractitem2;
          
        
        ECM_Extra_Approval__c ecmEX1 = new ECM_Extra_Approval__c();
        ecmEX1.ECM_Active__c = true;
        ecmEX1.ECM_Approver_Position_Name__c = 'Test Approver';
        ecmEX1.ECM_Approver_s_Email_Address__c = 'name.surname_Aus_1@diageo.com';
        ecmEX1.ECM_Lower_Limit_Amount__c = 100;
        ecmEX1.ECM_Upper_Limit_Amount__c = 200;
        ecmEX1.ECM_Re_Investment_Rate_Lower_Limit__c = 1;
        ecmEX1.ECM_Re_Investment_Rate_Upper_Limit__c = 20;
        ecmEX1.ECM_Enable_Delegation__c = false;
        ecmEX1.ECM_Type__c = 'Contract';
        insert ecmEX1;
        
        ECM_Extra_Approval__c ecmEX2 = new ECM_Extra_Approval__c();
        ecmEX2.ECM_Active__c = true;
        ecmEX2.ECM_Approver_Position_Name__c = 'Test Approver Manager';
        ecmEX2.ECM_Approver_s_Email_Address__c = 'name.surname_Aus_2@diageo.com';
        ecmEX2.ECM_Re_Investment_Rate_Lower_Limit__c = 1;
        ecmEX2.ECM_Re_Investment_Rate_Upper_Limit__c = 200;
        ecmEX2.ECM_Enable_Delegation__c = false;
        ecmEX2.ECM_Type__c = 'Contract';
        ecmEX2.ECM_Delegated_Approver_Email_Address__c ='Test2@test.com';
        insert ecmEX2;
        
        ECM_Extra_Approval__c ecmEX3 = new ECM_Extra_Approval__c();
        ecmEX3.ECM_Active__c = true;
        ecmEX3.ECM_Approver_Position_Name__c = 'Test Approver Senior Manager';
        ecmEX3.ECM_Approver_s_Email_Address__c = 'name.surname_Aus_3@diageo.com';
        ecmEX3.ECM_Lower_Limit_Amount__c = 100;
        ecmEX3.ECM_Upper_Limit_Amount__c = 200;
        ecmEX3.ECM_Re_Investment_Rate_Lower_Limit__c = 1;
        ecmEX3.ECM_Re_Investment_Rate_Upper_Limit__c = 20;
        ecmEX3.ECM_Enable_Delegation__c = true;
        ecmEX3.ECM_Type__c = 'Contract';
        ecmEX3.ECM_Delegated_Approver_Email_Address__c ='Test2@test.com';
        insert ecmEX3;
          
        List<ECM_Agreement_Approval__c> eCMAAList = new List<ECM_Agreement_Approval__c>();
        
        ECM_Agreement_Approval__c ecmAA1 = new ECM_Agreement_Approval__c();
        ecmAA1.ECM_Agreement_Type__c = contractType.Id;
        ecmAA1.ECM_Extra_Approval__c = ecmEX1.Id;
        eCMAAList.add(ecmAA1);
        
        ECM_Agreement_Approval__c ecmAA2 = new ECM_Agreement_Approval__c();
        ecmAA2.ECM_Agreement_Type__c = contractType.Id;
        ecmAA2.ECM_Extra_Approval__c = ecmEX2.Id;
        eCMAAList.add(ecmAA2);
        
        ECM_Agreement_Approval__c ecmAA3 = new ECM_Agreement_Approval__c();
        ecmAA3.ECM_Agreement_Type__c = contractType.Id;
        ecmAA3.ECM_Extra_Approval__c = ecmEX3.Id;
        eCMAAList.add(ecmAA3);
        
        Insert eCMAAList;
        
        //List<ECM_Approval_Log__c> ecmCurrentApprovalLogList = new List<ECM_Approval_Log__c>();
        
        String eCMApprovalLogRecordTypeId = ECM_Approval_Log__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Primary approver').getRecordTypeId();
        String eCMApprovalLogExtraRecordTypeId = Schema.SObjectType.ECM_Approval_Log__c.getRecordTypeInfosByDeveloperName().get('ECM_Extra_approver').getRecordTypeId();
        ECM_Approval_Log__c ecmCurrentApprovalLog = new ECM_Approval_Log__c();
        ecmCurrentApprovalLog.ECM_Approver_s_Position__c='Legal';
        ecmCurrentApprovalLog.Name='test@test.com';
        ecmCurrentApprovalLog.ECM_Status__c='Requested';
        ecmCurrentApprovalLog.ECM_Comment__c='Test User';
        ecmCurrentApprovalLog.ECM_Type__c = 'Contract';
        ecmCurrentApprovalLog.ECM_Contract__c=objContract.Id;
        ecmCurrentApprovalLog.RecordTypeId=eCMApprovalLogRecordTypeId;
        Insert ecmCurrentApprovalLog;
		
        EDGE_UtilityTestClass.createOrgSettings();         
        Org_Setting__c orgSetting = Org_Setting__c.getOrgDefaults();
        orgSetting.Run_Triggers__c=true;
        update orgSetting;
        
        Test.startTest();
        
        /*Contract ecmCont = [select Id, ECM_Overall_Investment_Amount__c, ECM_Agreement_Type__c,Status,Account.Country__r.Name,Account.Country__r.Code__c,
                            Account.Country__c,ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c, ECM_Hybrid_CustInvest_Total_PercentGP__c,
                            ECM_Overall_Investment_Figure__c,ECM_Territory__r.Country__r.Name,ECM_Territory__r.Region__c,
                            ECM_Territory__r.Business_Unit__c,ECM_Territory__r.Sales_Area__c,ECM_Territory__c,Recordtype.DeveloperName,

                            ECM_Recalled__c,ECM_Reason_For_Recall__c,ECM_Parent_Contract__c,ECM_Parent_Contract__r.startDate,startDate,ECM_Duration__c,ECM_Parent_Contract__r.ECM_Duration__c,
                            ECM_Parent_Contract__r.ECM_of_the_total_investment_vs_NSV__c,ECM_of_the_total_investment_vs_NSV__c,ECM_Parent_Contract__r.ECM_Overall_investments__c,ECM_Overall_investments__c,
                            ECM_Parent_Contract__r.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c,ECM_Parent_Contract__r.ECM_Hybrid_CustInvest_Total_PercentGP__c, Owner.Email

                            from Contract where Id=:objContract.Id limit 1];*/
        
        list<ECM_Approval_Log__c>ecmApprovalLogs = [Select Id, Name, ECM_Status__c, ECM_Comment__c, ECM_Approver_s_Position__c,
                                                    recordTypeId,recordType.Name,ECM_Time_Date_Log__c,ECM_No_of_Approval_Cycles__c,
                                                    ECM_Sales_Driver__c,ECM_Approval_Log__c.ECM_Type__c From ECM_Approval_Log__c 
                                                    Where ECM_Contract__c=:objContract.Id];
        for(ECM_Approval_Log__c temp:ecmApprovalLogs){
            if(temp.ECM_Type__c=='Contract'){
                temp.ECM_Status__c='Approved';
            }           
        }
        
        Database.update(ecmApprovalLogs);
                list<ECM_Approval_Log__c>ecmExtraApprovalLogs = [Select Id, Name, ECM_Status__c, ECM_Comment__c, ECM_Approver_s_Position__c,
                                                    recordTypeId,recordType.Name,ECM_Time_Date_Log__c,ECM_No_of_Approval_Cycles__c,
                                                    ECM_Sales_Driver__c,ECM_Approval_Log__c.ECM_Type__c From ECM_Approval_Log__c 
                                                    Where ECM_Contract__c=:objContract.Id and recordTypeId=:eCMApprovalLogExtraRecordTypeId];
        system.assertEquals(ecmExtraApprovalLogs.size(),1,'ecmExtraApprovalLogs size should match');
        
        for(ECM_Approval_Log__c temp:ecmExtraApprovalLogs){
            if(temp.ECM_Type__c=='Contract'){
                temp.ECM_Status__c='Approved';
            }           
        }
        
        Database.update(ecmExtraApprovalLogs);
        
        Test.stopTest();		
		
	}
	
    /*
    * @description : tests ECM_ApprovalLogTriggerHelper methods & AU delegated approval specific methods of ECM_ApprovalLogUtility
    * @return : void
    * @param : void
    */
	@isTest
    public static void updatePrimaryApprovalLogAustraliadelegateApproveScenario(){
		
		Profile prof = [select id from profile where name=: 'Sales Representative'];
        User usr = new User();
        usr.firstName = 'test1';
        usr.lastName = 'test2';
        usr.profileId = prof.id;        
        usr.email = 'test@test.com';
        usr.Username ='testcm123'+'_'+userinfo.getOrganizationId()+'@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='AU';
        usr.Title='Legal';
        insert usr;
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU'); 
        String bRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        
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
        budjectEU.Name='TI [AU]';
        budjectEU.Geography__c=geographyId;
        budjectEU.RecordTypeId=bRecordTypeId;
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
        contractType.ECM_Volume_UoM_for_RTD__c ='Can/Bottle 24 Pack';
        contractType.ECM_Volume_UoM_for_Draught_Cocktails__c='10L BIB';
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
        mktSetting.ECM_Contract_pdf_to_Approval_Mails__c = true;
        mktSetting.Enable_Auto_Approvals__c=true;

        mktSetting.ECM_Rejection_Email_to_Sales_Rep__c = true;
        insert mktSetting;
        
        
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Person_Responsible__c= usr.Id;
        outletAccount.OwnerId = usr.Id;
        outletAccount.Country__c=geographyId;
        insert outletAccount;
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Contract con = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        con.Status = 'Draft';
        con.Contract_End_Date__c = System.today()+29;
        con.AccountId=outletAccount.Id;
        con.ECM_Territory__c=testterritory.Id;
        con.ECM_Overall_Investment_Amount__c=100020.55;
        con.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c=12000934.32;
        con.ECM_Hybrid_CustInvest_Total_PercentGP__c=243123.33;
        con.ECM_Overall_Investment_Figure__c=122.43;
        //objContract.ECM_Contract_Type__c=contractType.Id;
        con.ECM_Agreement_Type__c=contractType.Id;
        con.recordTypeId=contractRecordTypeId;
        con.ECM_Channel__c='On-Premise';
        con.ECM_Banner__c=banner.Id;
        con.StartDate = system.today();
        con.Contract_End_Date__c = system.today()+360;
        insert con;
        
        Contract objContract = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract.Status = 'Draft';
        objContract.Contract_End_Date__c = System.today()+29;
        objContract.AccountId=outletAccount.Id;
        objContract.ECM_Territory__c=testterritory.Id;
        objContract.ECM_Overall_Investment_Amount__c=40.55;
        objContract.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c=12.32;
        objContract.ECM_Hybrid_CustInvest_Total_PercentGP__c=24.33;
        objContract.ECM_Overall_Investment_Figure__c=18.43;
        //objContract.ECM_Contract_Type__c=contractType.Id;
        objContract.ECM_Agreement_Type__c=contractType.Id;
        objContract.recordTypeId=contractRecordTypeId;
        objContract.ECM_Channel__c='On-Premise';
        objContract.ECM_Banner__c=banner.Id;
        objContract.StartDate = system.today();
        objContract.Contract_End_Date__c = system.today()+360;
        objContract.ECM_Recalled__c = true;
        objContract.ECM_Parent_Contract__c = con.Id;
        insert objContract;
        
        objContract.Status = 'In Approval Process';
        update objContract;
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
        ContentDocumentLink linkedFile = new ContentDocumentLink(LinkedEntityId=objContract.Id, ContentDocumentId=insertedFile.ContentDocumentId);
        insert linkedFile;
      
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
        
        ECM_Contract_Item__c newcontractitem1= new ECM_Contract_Item__c();
        newcontractitem1.ECM_Contract__c=objContract.Id;
        newcontractitem1.ECM_Product__c=marketassort.id;
        insert newcontractitem1;
        
        ECM_Contract_Item__c newcontractitem2= new ECM_Contract_Item__c();
        newcontractitem2.ECM_Contract__c=objContract.Id;
        newcontractitem2.ECM_Product__c=marketassort.id;
        insert newcontractitem2;
          
        
        ECM_Extra_Approval__c ecmEX1 = new ECM_Extra_Approval__c();
        ecmEX1.ECM_Active__c = true;
        ecmEX1.ECM_Approver_Position_Name__c = 'Test Approver';
        ecmEX1.ECM_Approver_s_Email_Address__c = 'name.surname_Aus_1@diageo.com';
        ecmEX1.ECM_Lower_Limit_Amount__c = 100;
        ecmEX1.ECM_Upper_Limit_Amount__c = 200;
        ecmEX1.ECM_Re_Investment_Rate_Lower_Limit__c = 1;
        ecmEX1.ECM_Re_Investment_Rate_Upper_Limit__c = 20;
        ecmEX1.ECM_Enable_Delegation__c = true;
		ecmEX1.ECM_Delegated_Approver_Email_Address__c ='name.surname_Aus_1_delegated@diageo.com';
        ecmEX1.ECM_Type__c = 'Contract';
        insert ecmEX1;
        
        ECM_Extra_Approval__c ecmEX2 = new ECM_Extra_Approval__c();
        ecmEX2.ECM_Active__c = true;
        ecmEX2.ECM_Approver_Position_Name__c = 'Test Approver Manager';
        ecmEX2.ECM_Approver_s_Email_Address__c = 'name.surname_Aus_2@diageo.com';
        ecmEX2.ECM_Re_Investment_Rate_Lower_Limit__c = 1;
        ecmEX2.ECM_Re_Investment_Rate_Upper_Limit__c = 200;
        ecmEX2.ECM_Enable_Delegation__c = true;
        ecmEX2.ECM_Type__c = 'Contract';
        ecmEX2.ECM_Delegated_Approver_Email_Address__c ='Test2@test.com';
        insert ecmEX2;
        
        ECM_Extra_Approval__c ecmEX3 = new ECM_Extra_Approval__c();
        ecmEX3.ECM_Active__c = true;
        ecmEX3.ECM_Approver_Position_Name__c = 'Test Approver Senior Manager';
        ecmEX3.ECM_Approver_s_Email_Address__c = 'name.surname_Aus_3@diageo.com';
        ecmEX3.ECM_Lower_Limit_Amount__c = 100;
        ecmEX3.ECM_Upper_Limit_Amount__c = 200;
        ecmEX3.ECM_Re_Investment_Rate_Lower_Limit__c = 1;
        ecmEX3.ECM_Re_Investment_Rate_Upper_Limit__c = 20;
        ecmEX3.ECM_Enable_Delegation__c = true;
        ecmEX3.ECM_Type__c = 'Contract';
        ecmEX3.ECM_Delegated_Approver_Email_Address__c ='Test2@test.com';
        insert ecmEX3;
          
        List<ECM_Agreement_Approval__c> eCMAAList = new List<ECM_Agreement_Approval__c>();
        
        ECM_Agreement_Approval__c ecmAA1 = new ECM_Agreement_Approval__c();
        ecmAA1.ECM_Agreement_Type__c = contractType.Id;
        ecmAA1.ECM_Extra_Approval__c = ecmEX1.Id;
        eCMAAList.add(ecmAA1);
        
        ECM_Agreement_Approval__c ecmAA2 = new ECM_Agreement_Approval__c();
        ecmAA2.ECM_Agreement_Type__c = contractType.Id;
        ecmAA2.ECM_Extra_Approval__c = ecmEX2.Id;
        eCMAAList.add(ecmAA2);
        
        ECM_Agreement_Approval__c ecmAA3 = new ECM_Agreement_Approval__c();
        ecmAA3.ECM_Agreement_Type__c = contractType.Id;
        ecmAA3.ECM_Extra_Approval__c = ecmEX3.Id;
        eCMAAList.add(ecmAA3);
        
        Insert eCMAAList;
        
        //List<ECM_Approval_Log__c> ecmCurrentApprovalLogList = new List<ECM_Approval_Log__c>();
        
        String eCMApprovalLogRecordTypeId = ECM_Approval_Log__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Primary approver').getRecordTypeId();
        String eCMApprovalLogExtraRecordTypeId = Schema.SObjectType.ECM_Approval_Log__c.getRecordTypeInfosByDeveloperName().get('ECM_Extra_approver').getRecordTypeId();
        ECM_Approval_Log__c ecmCurrentApprovalLog = new ECM_Approval_Log__c();
        ecmCurrentApprovalLog.ECM_Approver_s_Position__c='Legal';
        ecmCurrentApprovalLog.Name='test@test.com';
        ecmCurrentApprovalLog.ECM_Status__c='Requested';
        ecmCurrentApprovalLog.ECM_Comment__c='Test User';
        ecmCurrentApprovalLog.ECM_Type__c = 'Contract';
        ecmCurrentApprovalLog.ECM_Contract__c=objContract.Id;
        ecmCurrentApprovalLog.RecordTypeId=eCMApprovalLogRecordTypeId;

        Insert ecmCurrentApprovalLog;
		
		 EDGE_UtilityTestClass.createOrgSettings(); 
        
        Org_Setting__c orgSetting = Org_Setting__c.getOrgDefaults();
        orgSetting.Run_Triggers__c=true;
        update orgSetting;
        
        Test.startTest();
        
       /* Contract ecmCont = [select Id, ECM_Overall_Investment_Amount__c, ECM_Agreement_Type__c,Status,Account.Country__r.Name,Account.Country__r.Code__c,
                            Account.Country__c,ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c, ECM_Hybrid_CustInvest_Total_PercentGP__c,
                            ECM_Overall_Investment_Figure__c,ECM_Territory__r.Country__r.Name,ECM_Territory__r.Region__c,
                            ECM_Territory__r.Business_Unit__c,ECM_Territory__r.Sales_Area__c,ECM_Territory__c,Recordtype.DeveloperName,

                            ECM_Recalled__c,ECM_Reason_For_Recall__c,ECM_Parent_Contract__c,ECM_Parent_Contract__r.startDate,startDate,ECM_Duration__c,ECM_Parent_Contract__r.ECM_Duration__c,
                            ECM_Parent_Contract__r.ECM_of_the_total_investment_vs_NSV__c,ECM_of_the_total_investment_vs_NSV__c,ECM_Parent_Contract__r.ECM_Overall_investments__c,ECM_Overall_investments__c,
                            ECM_Parent_Contract__r.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c,ECM_Parent_Contract__r.ECM_Hybrid_CustInvest_Total_PercentGP__c, Owner.Email

                            from Contract where Id=:objContract.Id limit 1];*/
        
        list<ECM_Approval_Log__c>ecmApprovalLogs = [Select Id, Name, ECM_Status__c, ECM_Comment__c, ECM_Approver_s_Position__c,
                                                    recordTypeId,recordType.Name,ECM_Time_Date_Log__c,ECM_No_of_Approval_Cycles__c,
                                                    ECM_Sales_Driver__c,ECM_Approval_Log__c.ECM_Type__c From ECM_Approval_Log__c 
                                                    Where ECM_Contract__c=:objContract.Id];
        for(ECM_Approval_Log__c temp:ecmApprovalLogs){
            if(temp.ECM_Type__c=='Contract'){
                temp.ECM_Status__c='Approved';
            }           
        }
        
        Database.update(ecmApprovalLogs);
                list<ECM_Approval_Log__c>ecmExtraApprovalLogs = [Select Id, Name, ECM_Status__c, ECM_Comment__c, ECM_Approver_s_Position__c,
                                                    recordTypeId,recordType.Name,ECM_Time_Date_Log__c,ECM_No_of_Approval_Cycles__c,
                                                    ECM_Sales_Driver__c,ECM_Approval_Log__c.ECM_Type__c From ECM_Approval_Log__c 
                                                    Where ECM_Contract__c=:objContract.Id and recordTypeId=:eCMApprovalLogExtraRecordTypeId];
        system.assertEquals(ecmExtraApprovalLogs.size(),1,'ecmExtraApprovalLogs size should match');
        
        for(ECM_Approval_Log__c temp:ecmExtraApprovalLogs){
            if(temp.ECM_Type__c=='Contract'){
                temp.ECM_Status__c='Approved';
            }           
        }
        
        Database.update(ecmExtraApprovalLogs);
        
        Test.stopTest();		
		
	}
	
    /*
    * @description : tests ECM_ApprovalLogTriggerHelper methods & AU primary approval specific methods of ECM_ApprovalLogUtility
    * @return : void
    * @param : void
    */
	@isTest
    public static void updatePrimaryApprovalLogAustraliaApprovewithoutExtraApproverScenario(){
		
		Profile prof = [select id from profile where name=: 'Sales Representative'];
        User usr = new User();
        usr.firstName = 'test1';
        usr.lastName = 'test2';
        usr.profileId = prof.id;        
        usr.email = 'test@test.com';
        usr.Username ='testcm123'+'_'+userinfo.getOrganizationId()+'@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='AU';
        usr.Title='Legal';
        insert usr;
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU'); 
        String bRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        
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
        budjectEU.Name='TI [AU]';
        budjectEU.Geography__c=geographyId;
        budjectEU.RecordTypeId=bRecordTypeId;
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
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;Category;Volume Target;Rate Per UoM;Investment;Product Growth Strategy;UoM;';
        contractType.ECM_Volume_UoM_for_RTD__c ='Can/Bottle 24 Pack';
        contractType.ECM_Volume_UoM_for_Draught_Cocktails__c='10L BIB';
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
        mktSetting.ECM_Contract_pdf_to_Approval_Mails__c = true;
        mktSetting.Enable_Auto_Approvals__c=true;

        mktSetting.ECM_Rejection_Email_to_Sales_Rep__c = true;
        insert mktSetting;
        
        
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Person_Responsible__c= usr.Id;
        outletAccount.OwnerId = usr.Id;
        outletAccount.Country__c=geographyId;
        insert outletAccount;
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Contract con = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        con.Status = 'Draft';
        con.Contract_End_Date__c = System.today()+29;
        con.AccountId=outletAccount.Id;
        con.ECM_Territory__c=testterritory.Id;
        con.ECM_Overall_Investment_Amount__c=100020.55;
        con.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c=12000934.32;
        con.ECM_Hybrid_CustInvest_Total_PercentGP__c=243123.33;
        con.ECM_Overall_Investment_Figure__c=122.43;
        //objContract.ECM_Contract_Type__c=contractType.Id;
        con.ECM_Agreement_Type__c=contractType.Id;
        con.recordTypeId=contractRecordTypeId;
        con.ECM_Channel__c='On-Premise';
        con.ECM_Banner__c=banner.Id;
        con.StartDate = system.today();
        con.Contract_End_Date__c = system.today()+360;
        insert con;
        
        Contract objContract = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract.Status = 'Draft';
        objContract.Contract_End_Date__c = System.today()+29;
        objContract.AccountId=outletAccount.Id;
        objContract.ECM_Territory__c=testterritory.Id;
        objContract.ECM_Overall_Investment_Amount__c=40.55;
        objContract.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c=12.32;
        objContract.ECM_Hybrid_CustInvest_Total_PercentGP__c=24.33;
        objContract.ECM_Overall_Investment_Figure__c=18.43;
        //objContract.ECM_Contract_Type__c=contractType.Id;
        objContract.ECM_Agreement_Type__c=contractType.Id;
        objContract.recordTypeId=contractRecordTypeId;
        objContract.ECM_Channel__c='On-Premise';
        objContract.ECM_Banner__c=banner.Id;
        objContract.StartDate = system.today();
        objContract.Contract_End_Date__c = system.today()+360;
        objContract.ECM_Recalled__c = true;
        objContract.ECM_Parent_Contract__c = con.Id;
        insert objContract;
        
        objContract.Status = 'In Approval Process';
        update objContract;
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
        ContentDocumentLink linkedFile = new ContentDocumentLink(LinkedEntityId=objContract.Id, ContentDocumentId=insertedFile.ContentDocumentId);
        insert linkedFile;
      
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
        
        ECM_Contract_Item__c newcontractitem1= new ECM_Contract_Item__c();
        newcontractitem1.ECM_Contract__c=objContract.Id;
        newcontractitem1.ECM_Product__c=marketassort.id;
        insert newcontractitem1;
        
        ECM_Contract_Item__c newcontractitem2= new ECM_Contract_Item__c();
        newcontractitem2.ECM_Contract__c=objContract.Id;
        newcontractitem2.ECM_Product__c=marketassort.id;
        insert newcontractitem2;
          
    
        
        //List<ECM_Approval_Log__c> ecmCurrentApprovalLogList = new List<ECM_Approval_Log__c>();
        
        String eCMApprovalLogRecordTypeId = ECM_Approval_Log__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Primary approver').getRecordTypeId();
        //String eCMApprovalLogExtraRecordTypeId = Schema.SObjectType.ECM_Approval_Log__c.getRecordTypeInfosByDeveloperName().get('ECM_Extra_approver').getRecordTypeId();
        ECM_Approval_Log__c ecmCurrentApprovalLog = new ECM_Approval_Log__c();
        ecmCurrentApprovalLog.ECM_Approver_s_Position__c='Legal';
        ecmCurrentApprovalLog.Name='test@test.com';
        ecmCurrentApprovalLog.ECM_Status__c='Requested';
        ecmCurrentApprovalLog.ECM_Comment__c='Test User';
        ecmCurrentApprovalLog.ECM_Type__c = 'Contract';
        ecmCurrentApprovalLog.ECM_Contract__c=objContract.Id;
        ecmCurrentApprovalLog.RecordTypeId=eCMApprovalLogRecordTypeId;

        Insert ecmCurrentApprovalLog;
		
		 EDGE_UtilityTestClass.createOrgSettings(); 
        
        Org_Setting__c orgSetting = Org_Setting__c.getOrgDefaults();
        orgSetting.Run_Triggers__c=true;
        update orgSetting;
        
        Test.startTest();
        
       /* Contract ecmCont = [select Id, ECM_Overall_Investment_Amount__c, ECM_Agreement_Type__c,Status,Account.Country__r.Name,Account.Country__r.Code__c,
                            Account.Country__c,ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c, ECM_Hybrid_CustInvest_Total_PercentGP__c,
                            ECM_Overall_Investment_Figure__c,ECM_Territory__r.Country__r.Name,ECM_Territory__r.Region__c,
                            ECM_Territory__r.Business_Unit__c,ECM_Territory__r.Sales_Area__c,ECM_Territory__c,Recordtype.DeveloperName,

                            ECM_Recalled__c,ECM_Reason_For_Recall__c,ECM_Parent_Contract__c,ECM_Parent_Contract__r.startDate,startDate,ECM_Duration__c,ECM_Parent_Contract__r.ECM_Duration__c,
                            ECM_Parent_Contract__r.ECM_of_the_total_investment_vs_NSV__c,ECM_of_the_total_investment_vs_NSV__c,ECM_Parent_Contract__r.ECM_Overall_investments__c,ECM_Overall_investments__c,
                            ECM_Parent_Contract__r.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c,ECM_Parent_Contract__r.ECM_Hybrid_CustInvest_Total_PercentGP__c, Owner.Email

                            from Contract where Id=:objContract.Id limit 1];*/
        
        list<ECM_Approval_Log__c>ecmApprovalLogs = [Select Id, Name, ECM_Status__c, ECM_Comment__c, ECM_Approver_s_Position__c,
                                                    recordTypeId,recordType.Name,ECM_Time_Date_Log__c,ECM_No_of_Approval_Cycles__c,
                                                    ECM_Sales_Driver__c,ECM_Approval_Log__c.ECM_Type__c From ECM_Approval_Log__c 
                                                    Where ECM_Contract__c=:objContract.Id];
        for(ECM_Approval_Log__c temp:ecmApprovalLogs){
            if(temp.ECM_Type__c=='Contract'){
                temp.ECM_Status__c='Approved';
            }           
        }
        
        Database.update(ecmApprovalLogs);
                list<ECM_Approval_Log__c>ecmExtraApprovalLogs = [Select Id, Name, ECM_Status__c, ECM_Comment__c, ECM_Approver_s_Position__c,
                                                    recordTypeId,recordType.Name,ECM_Time_Date_Log__c,ECM_No_of_Approval_Cycles__c,
                                                    ECM_Sales_Driver__c,ECM_Approval_Log__c.ECM_Type__c From ECM_Approval_Log__c 
                                                    Where ECM_Contract__c=:objContract.Id and Name='Record not found'];
        system.assertEquals(ecmExtraApprovalLogs.size(),1,'ecmExtraApprovalLogs size should match');
        
        Test.stopTest();		
		
	}
	
	/*
    * @description : tests ECM_ApprovalLogTriggerHelper methods & AU approval rejection specific methods of ECM_ApprovalLogUtility
    * @return : void
    * @param : void
    */
	@isTest
    public static void updatePrimaryApprovalLogAustraliaRejectScenario(){
		
		
		Profile prof = [select id from profile where name=: 'Sales Representative'];
        User usr = new User();
        usr.firstName = 'test1';
        usr.lastName = 'test2';
        usr.profileId = prof.id;        
        usr.email = 'test@test.com';
        usr.Username ='testcm123'+'_'+userinfo.getOrganizationId()+'@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='AU';
        usr.Title='Legal';
        insert usr;
        System.assert(usr.id!=null,'User Id should not be null');

        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU'); 
        String bRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        
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
        budjectEU.Name='TI [AU]';
        budjectEU.Geography__c=geographyId;
        budjectEU.RecordTypeId=bRecordTypeId;
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
        contractType.ECM_Volume_UoM_for_RTD__c ='Can/Bottle 24 Pack';
        contractType.ECM_Volume_UoM_for_Draught_Cocktails__c='10L BIB';
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
        mktSetting.ECM_Contract_pdf_to_Approval_Mails__c = true;
        mktSetting.Enable_Auto_Approvals__c=true;

        mktSetting.ECM_Rejection_Email_to_Sales_Rep__c = true;
        insert mktSetting;
        
        
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Person_Responsible__c= usr.Id;
        outletAccount.OwnerId = usr.Id;
        outletAccount.Country__c=geographyId;
        insert outletAccount;
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Contract con = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        con.Status = 'Draft';
        con.Contract_End_Date__c = System.today()+29;
        con.AccountId=outletAccount.Id;
        con.ECM_Territory__c=testterritory.Id;
        con.ECM_Overall_Investment_Amount__c=100020.55;
        con.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c=12000934.32;
        con.ECM_Hybrid_CustInvest_Total_PercentGP__c=243123.33;
        con.ECM_Overall_Investment_Figure__c=122.43;
        //objContract.ECM_Contract_Type__c=contractType.Id;
        con.ECM_Agreement_Type__c=contractType.Id;
        con.recordTypeId=contractRecordTypeId;
        con.ECM_Channel__c='On-Premise';
        con.ECM_Banner__c=banner.Id;
        con.StartDate = system.today();
        con.Contract_End_Date__c = system.today()+360;
        insert con;
        
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
        objContract.ECM_Recalled__c = true;
        objContract.ECM_Parent_Contract__c = con.Id;
        insert objContract;
        
        objContract.Status = 'In Approval Process';
        update objContract;
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
        ContentDocumentLink linkedFile = new ContentDocumentLink(LinkedEntityId=objContract.Id, ContentDocumentId=insertedFile.ContentDocumentId);
        insert linkedFile;
      
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
        
        ECM_Contract_Item__c newcontractitem1= new ECM_Contract_Item__c();
        newcontractitem1.ECM_Contract__c=objContract.Id;
        newcontractitem1.ECM_Product__c=marketassort.id;
        insert newcontractitem1;
        
        ECM_Contract_Item__c newcontractitem2= new ECM_Contract_Item__c();
        newcontractitem2.ECM_Contract__c=objContract.Id;
        newcontractitem2.ECM_Product__c=marketassort.id;
        insert newcontractitem2;
          
        
        ECM_Extra_Approval__c ecmEX1 = new ECM_Extra_Approval__c();
        ecmEX1.ECM_Active__c = true;
        ecmEX1.ECM_Approver_Position_Name__c = 'Test Approver';
        ecmEX1.ECM_Approver_s_Email_Address__c = 'name.surname_Aus_1@diageo.com';
        ecmEX1.ECM_Lower_Limit_Amount__c = 100;
        ecmEX1.ECM_Upper_Limit_Amount__c = 200;
        ecmEX1.ECM_Re_Investment_Rate_Lower_Limit__c = 1;
        ecmEX1.ECM_Re_Investment_Rate_Upper_Limit__c = 20;
        ecmEX1.ECM_Enable_Delegation__c = false;
        ecmEX1.ECM_Type__c = 'Contract';
        insert ecmEX1;
        
        ECM_Extra_Approval__c ecmEX2 = new ECM_Extra_Approval__c();
        ecmEX2.ECM_Active__c = true;
        ecmEX2.ECM_Approver_Position_Name__c = 'Test Approver Manager';
        ecmEX2.ECM_Approver_s_Email_Address__c = 'name.surname_Aus_2@diageo.com';
        ecmEX2.ECM_Lower_Limit_Amount__c = 100;
        ecmEX2.ECM_Upper_Limit_Amount__c = 200;
        ecmEX2.ECM_Re_Investment_Rate_Lower_Limit__c = 1;
        ecmEX2.ECM_Re_Investment_Rate_Upper_Limit__c = 20;
        ecmEX2.ECM_Enable_Delegation__c = false;
        ecmEX2.ECM_Type__c = 'Contract';
        ecmEX2.ECM_Delegated_Approver_Email_Address__c ='Test2@test.com';
        insert ecmEX2;
        
        ECM_Extra_Approval__c ecmEX3 = new ECM_Extra_Approval__c();
        ecmEX3.ECM_Active__c = true;
        ecmEX3.ECM_Approver_Position_Name__c = 'Test Approver Senior Manager';
        ecmEX3.ECM_Approver_s_Email_Address__c = 'name.surname_Aus_3@diageo.com';
        ecmEX3.ECM_Lower_Limit_Amount__c = 100;
        ecmEX3.ECM_Upper_Limit_Amount__c = 200;
        ecmEX3.ECM_Re_Investment_Rate_Lower_Limit__c = 1;
        ecmEX3.ECM_Re_Investment_Rate_Upper_Limit__c = 20;
        ecmEX3.ECM_Enable_Delegation__c = true;
        ecmEX3.ECM_Type__c = 'Contract';
        ecmEX3.ECM_Delegated_Approver_Email_Address__c ='name.surname_Aus_delegated@diageo.com';
        insert ecmEX3;
          
        List<ECM_Agreement_Approval__c> eCMAAList = new List<ECM_Agreement_Approval__c>();
        
        ECM_Agreement_Approval__c ecmAA1 = new ECM_Agreement_Approval__c();
        ecmAA1.ECM_Agreement_Type__c = contractType.Id;
        ecmAA1.ECM_Extra_Approval__c = ecmEX1.Id;
        eCMAAList.add(ecmAA1);
        
        ECM_Agreement_Approval__c ecmAA2 = new ECM_Agreement_Approval__c();
        ecmAA2.ECM_Agreement_Type__c = contractType.Id;
        ecmAA2.ECM_Extra_Approval__c = ecmEX2.Id;
        eCMAAList.add(ecmAA2);
        
        ECM_Agreement_Approval__c ecmAA3 = new ECM_Agreement_Approval__c();
        ecmAA3.ECM_Agreement_Type__c = contractType.Id;
        ecmAA3.ECM_Extra_Approval__c = ecmEX3.Id;
        eCMAAList.add(ecmAA3);
        
        Insert eCMAAList;
        
        //List<ECM_Approval_Log__c> ecmCurrentApprovalLogList = new List<ECM_Approval_Log__c>();
        
        String eCMApprovalLogRecordTypeId = ECM_Approval_Log__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Primary approver').getRecordTypeId();
        //String eCMApprovalLogExtraRecordTypeId = Schema.SObjectType.ECM_Approval_Log__c.getRecordTypeInfosByDeveloperName().get('ECM_Extra_approver').getRecordTypeId();
        ECM_Approval_Log__c ecmCurrentApprovalLog = new ECM_Approval_Log__c();
        ecmCurrentApprovalLog.ECM_Approver_s_Position__c='Legal';
        ecmCurrentApprovalLog.Name='test@test.com';
        ecmCurrentApprovalLog.ECM_Status__c='Requested';
        ecmCurrentApprovalLog.ECM_Comment__c='Test User';
        ecmCurrentApprovalLog.ECM_Type__c = 'Contract';
        ecmCurrentApprovalLog.ECM_Contract__c=objContract.Id;
        ecmCurrentApprovalLog.RecordTypeId=eCMApprovalLogRecordTypeId;

        Insert ecmCurrentApprovalLog;
		
		 EDGE_UtilityTestClass.createOrgSettings(); 
        
        Org_Setting__c orgSetting = Org_Setting__c.getOrgDefaults();
        orgSetting.Run_Triggers__c=true;
        update orgSetting;
        
        Test.startTest();
        
        /*Contract ecmCont = [select Id, ECM_Overall_Investment_Amount__c, ECM_Agreement_Type__c,Status,Account.Country__r.Name,Account.Country__r.Code__c,
                            Account.Country__c,ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c, ECM_Hybrid_CustInvest_Total_PercentGP__c,
                            ECM_Overall_Investment_Figure__c,ECM_Territory__r.Country__r.Name,ECM_Territory__r.Region__c,
                            ECM_Territory__r.Business_Unit__c,ECM_Territory__r.Sales_Area__c,ECM_Territory__c,Recordtype.DeveloperName,

                            ECM_Recalled__c,ECM_Reason_For_Recall__c,ECM_Parent_Contract__c,ECM_Parent_Contract__r.startDate,startDate,ECM_Duration__c,ECM_Parent_Contract__r.ECM_Duration__c,
                            ECM_Parent_Contract__r.ECM_of_the_total_investment_vs_NSV__c,ECM_of_the_total_investment_vs_NSV__c,ECM_Parent_Contract__r.ECM_Overall_investments__c,ECM_Overall_investments__c,
                            ECM_Parent_Contract__r.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c,ECM_Parent_Contract__r.ECM_Hybrid_CustInvest_Total_PercentGP__c, Owner.Email

                            from Contract where Id=:objContract.Id limit 1];*/
        
        list<ECM_Approval_Log__c>ecmApprovalLogs = [Select Id, Name, ECM_Status__c, ECM_Comment__c, ECM_Approver_s_Position__c,
                                                    recordTypeId,recordType.Name,ECM_Time_Date_Log__c,ECM_No_of_Approval_Cycles__c,
                                                    ECM_Sales_Driver__c,ECM_Approval_Log__c.ECM_Type__c From ECM_Approval_Log__c 
                                                    Where ECM_Contract__c=:objContract.Id];
        for(ECM_Approval_Log__c temp:ecmApprovalLogs){
            if(temp.ECM_Type__c=='Contract'){
                temp.ECM_Status__c='Rejected';
            }           
        }
        
        Database.update(ecmApprovalLogs);
        Test.stopTest();		
		
	}
	
    /*
    * @description : tests ECM_ApprovalLogTriggerHelper methods & EU contract approval specific methods of ECM_ApprovalLogUtility
    * @return : void
    * @param : void
    */
	@isTest
    public static void updatePrimaryApprovalLogSpainApproveScenario(){
        //Set Up User to create contract with
        User usr = ECM_UtilityTestClass.createUser('sr',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
        usr.Username = 'srUsr@test.com';
        usr.isActive = true;
        usr.Available_Countries__c = 'ES';
        insert usr;
        System.assert(usr.id!=null,'User Id should not be null');
		
        //Set up geography for Spain
        Id geographyId = EDGE_UtilityTestClass.setupCountry('ES'); 
        Geography__c country = new Geography__c();
        country.Id = geographyId;
        country.Name = 'Spain';
        update country;
        
        //Set up budget type to be added in Sales Driver
        String bRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        Pick_Up_Options__c budjectEU = new Pick_Up_Options__c(Geography__c = geographyId, RecordTypeId = bRecordTypeId);
        budjectEU.Name = 'TI [ES]';
        insert budjectEU;
        
        //Set up Territory hierarchy,Territory & Territory Budget for Sales Driver
        Territory_Hierarchy__c terrHr = ECM_UtilityTestClass.createhirarchy(geographyId);
        terrHr.recordtypeId = Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Activation Territory').getRecordTypeId();
        insert terrHr;
        
        Territory__c testTerr = New Territory__c(Country__c = geographyId, Activation_Territory__c = terrHr.Id);
        testTerr.Name = 'Testterriotory';
        testTerr.Territory_Type__c = 'Sales';
        testTerr.Status__c = 'Active';
        testTerr.Primary_Sales_Rep__c = usr.id;
        insert testTerr;
                
        Territory_Budget__c terrBdgt = ECM_UtilityTestClass.createTerritoryBudget(testTerr.Id, terrHr.Id);
        terrBdgt.ECM_Budget_Type__c = budjectEU.Id;
        insert terrBdgt;
        
        //Mandatory Record to create contract : agreement type & account
        ECM_Contract_Type__c conType = ECM_UtilityTestClass.createContractType(geographyId);
        conType.ECM_Automatic_approval_amount_threshold__c = 40.00;
        conType.Name = 'Promotional';
        conType.ECM_Volume_UoM_for_Beer__c = 'EU';
        conType.ECM_Screen_3_field_configuration__c = 'Product Name;Brand;Category;Volume Target;UoM;Rate Per UoM;Investment';
        insert conType;
        
        Account outletAcc = EDGE_UtilityTestClass.getOutletRecord();
        outletAcc.Person_Responsible__c = usr.Id;
        outletAcc.OwnerId = usr.Id;
        outletAcc.Country__c = geographyId;
        insert outletAcc;
        
        //Set up market settings to test approval configurations based upon MS
        Market_Setting__c mktSetting = new Market_Setting__c(Name = 'ES Market Setting', Geography__c = geographyId);
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
        mktSetting.ECM_Contract_pdf_to_Approval_Mails__c = true;
        mktSetting.Enable_Auto_Approvals__c=true;
        mktSetting.ECM_Rejection_Email_to_Sales_Rep__c = true;
        insert mktSetting;
        
        //Set up contracts
        String conRecTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
		List<Contract> conList = new List<Contract>();
		Contract con = EDGE_UtilityTestClass.getContract(outletAcc.Id, conRecTypeId);
        con.Status = 'Draft';
        con.ECM_Territory__c = testTerr.Id;
        con.ECM_Overall_Investment_Figure__c = 12.43;
        con.ECM_Agreement_Type__c = conType.Id;
        con.StartDate = system.today();
        con.Contract_End_Date__c = system.today()+360;
        insert con;
		
        Contract contractForApproval = con.clone(false,false,false,false);
        conList.add(contractForApproval);
        
		Contract contractForSDApproval = con.clone(false,false,false,false);
        conList.add(contractForSDApproval);
		
		Contract contractForSDItemApproval = con.clone(false,false,false,false);
        conList.add(contractForSDItemApproval);
        
        Contract objContract = con.clone(false,false,false,false);
        objContract.ECM_Overall_Investment_Figure__c = 122.43;
        objContract.ECM_Recalled__c = true;
        objContract.ECM_Parent_Contract__c = con.Id;
        conList.add(objContract);
        
        Contract conAmended = con.clone(false,false,false,false);
        conAmended.ECM_Parent_Contract__c = con.Id;
        conAmended.ECM_Amended__c = true;
        conList.add(conAmended);
		Database.insert(conList);
        
        //Set up Contract KPI & put contracts in approval process
        ECM_Contract_KPI__c conKpi = new ECM_Contract_KPI__c();
        conKpi.ECM_Contract__c = contractForApproval.Id;
        conKpi.ECM_EU_Volume__c = 1;
        conKpi.ECM_Total_NSV__c = 2;
        conKpi.ECM_CAAP__c = 4;
        conKpi.ECM_Type__c = 'Total';
        insert conKpi;
        for(contract c : conList){
			c.status='In Approval Process';
		}
		Database.update(conList);
		
        //Create a new file
        ContentVersion newFile = new ContentVersion(PathOnClient = 'TestFile', Title = 'TestFile');
        newFile.VersionData = Blob.valueOf('sample content');
        newFile.Content_Type__c = Label.ECM_ContentTypeApprovalMail;
        newFile.RecordTypeId = ContentVersion.sObjectType.getDescribe().getRecordTypeInfosByName().get('Contracts').getRecordTypeId();
        
        ContentVersion sgnCon = newFile.clone(false,false,false,false);
        sgnCon.PathOnClient = 'SignedCon';
        sgnCon.Title = 'SignedCon';
        sgnCon.Content_Type__c = Label.ECM_ContentTypeSignedContract;
        List<ContentVersion> cvList = new List<ContentVersion>{newFile, sgnCon};
        insert cvList;
        Map<Id,ContentVersion> cvMap = new Map<Id,ContentVersion>(cvList);
        
        //Link the file with the contentdocumentid of inserted content versions
        List<ContentDocumentLink> conDocLnkLst = new List<ContentDocumentLink>();
        for(ContentVersion cv : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN: cvMap.keySet()]){
            ContentDocumentLink conDocLnk1 = new ContentDocumentLink(LinkedEntityId = objContract.Id, ContentDocumentId = cv.ContentDocumentId);
            conDocLnkLst.add(conDocLnk1);
            ContentDocumentLink conDocLnk2 = new ContentDocumentLink(LinkedEntityId = con.Id, ContentDocumentId = cv.ContentDocumentId);
            conDocLnkLst.add(conDocLnk2);
        }
        insert conDocLnkLst;
        
        //Set up product and product related items to create contract item
        List<Product__c> prodList = new List<Product__c>{new Product__c(Name = 'Test1', Product_Full_Name__c = 'Test1', Country__c = geographyId),
            											 new Product__c(Name = 'Test2', Product_Full_Name__c = 'Test2', Country__c = geographyId)};
		insert prodList;
   
        Product_UOM__c prdUOM1 = new Product_UOM__c(Product__c = prodList[0].Id, Conversion_Factor__c = 2);
        prdUOM1.Type__c = 'BTL';
        prdUOM1.Unique_ID__c =  prodList[0].Id + '_BTL';
        insert prdUOM1;
        
        Product_UOM__c prdUOM2 = prdUOM1.clone(false,false,false,false);
        prdUOM2.Product__c = prodList[1].Id;
        prdUOM2.Unique_ID__c =  prodList[1].Id + '_BTL';
        insert prdUOM2;
        
        Market_Assortment_Product__c map1 = new Market_Assortment_Product__c(Product__c = prodList[0].Id, Market_Assortment__c = geographyId);
        Market_Assortment_Product__c map2 = new Market_Assortment_Product__c(Product__c = prodList[1].Id, Market_Assortment__c = geographyId);
        List<Market_Assortment_Product__c> mapList = new List<Market_Assortment_Product__c>{map1, map2};
        insert mapList;
       
        ECM_Product_Agreement__c prdAg1 = new ECM_Product_Agreement__c(ECM_Market_Assortment_Product__c = map1.Id, ECM_Contract_Type__c = conType.Id);
        ECM_Product_Agreement__c prdAg2 = new ECM_Product_Agreement__c(ECM_Market_Assortment_Product__c = map2.Id, ECM_Contract_Type__c = conType.Id);
        List<ECM_Product_Agreement__c> prdAgList = new List<ECM_Product_Agreement__c>{prdAg1, prdAg2};
        insert prdAgList;
        
        //Set up contract items for all three contracts for both products
        List<ECM_Contract_Item__c> conItmList = new List<ECM_Contract_Item__c>();
        for(Contract conRec : conList){
            ECM_Contract_Item__c conItm1 = new ECM_Contract_Item__c(ECM_Contract__c = conRec.Id, ECM_Product__c = map1.id);
            ECM_Contract_Item__c conItm2 = new ECM_Contract_Item__c(ECM_Contract__c = conRec.Id, ECM_Product__c = map2.id);
            conItmList.addAll(new List<ECM_Contract_Item__c>{conItm1, conItm2});
        }
		database.insert(conItmList);
        
        //Set up Sales Driver, Sales Driver Items & Sales Driver Item details and link them with Contract
        Id sdiRecId = Schema.SObjectType.ECM_Sales_Driver_Item__c.getRecordTypeInfosByName().get('Sales Driver').getRecordTypeId();
        Id sdidRecId = Schema.SObjectType.ECM_Sales_Driver_Item_Detail__c.getRecordTypeInfosByName().get('Sales Driver').getRecordTypeId();
        
        ECM_Sales_Driver__c sD1 = ECM_UtilityTestClass.getSalesdriver(terrBdgt.Id, geographyId);
        ECM_Sales_Driver__c sD2 = ECM_UtilityTestClass.getSalesdriver(terrBdgt.Id, geographyId);
        List<ECM_Sales_Driver__c> sdList = new List<ECM_Sales_Driver__c>{sD1, sD2};
        insert sdList;
		
		ECM_Sales_Driver_Item__c sdI1 = new ECM_Sales_Driver_Item__c(Contract__c = conList[1].Id, ECM_Sales_Driver__c = sD1.Id, 
                                                                      RecordTypeId = sdiRecId, ECM_Total_Investment_Amount__c = 150);
        ECM_Sales_Driver_Item__c sdI2 = new ECM_Sales_Driver_Item__c(Contract__c = conList[1].Id, ECM_Sales_Driver__c = sD2.Id,
                                                                      RecordTypeId = sdiRecId, ECM_Total_Investment_Amount__c = 100);
        ECM_Sales_Driver_Item__c sdI3 = new ECM_Sales_Driver_Item__c(Contract__c = conList[2].Id, ECM_Sales_Driver__c = sD1.Id,
                                                                      RecordTypeId = sdiRecId, ECM_Total_Investment_Amount__c = 150);
        ECM_Sales_Driver_Item__c sdI4 = new ECM_Sales_Driver_Item__c(Contract__c = conList[2].Id, ECM_Sales_Driver__c = sD2.Id,
                                                                      RecordTypeId = sdiRecId, ECM_Total_Investment_Amount__c = 100);
        List<ECM_Sales_Driver_Item__c> sdiList = new List<ECM_Sales_Driver_Item__c>{sdI1, sdI2, sdI3, sdI4};
        insert sdiList;
		
        ECM_Sales_Driver_Item_Detail__c salesDetails1 = ECM_UtilityTestClass.insertSalesdriverDetails(sdI1, conItmList[2]);
        salesDetails1.Recordtypeid = sdidRecId;
        salesDetails1.ECM_Investment_Amount__c = 200;
        insert salesDetails1;
		
		ECM_Sales_Driver_Item_Detail__c salesDetails2 = ECM_UtilityTestClass.insertSalesdriverDetails(sdI1, conItmList[3]);
        salesDetails2.Recordtypeid = sdidRecId;
        salesDetails2.ECM_Investment_Amount__c = 300;
        insert salesDetails2;
		
        ECM_Sales_Driver_Item_Detail__c salesDetails3 = ECM_UtilityTestClass.insertSalesdriverDetails(sdI3, conItmList[4]);
        salesDetails3.Recordtypeid = sdidRecId;
        salesDetails3.ECM_Investment_Amount__c = 200;
        insert salesDetails3;
		
		ECM_Sales_Driver_Item_Detail__c salesDetails4 = ECM_UtilityTestClass.insertSalesdriverDetails(sdI4, conItmList[5]);
        salesDetails4.Recordtypeid = sdidRecId;
        salesDetails4.ECM_Investment_Amount__c = 300;
        insert salesDetails4;
		
        //Set up Extra Approver records and map them with Agreement type
        List<ECM_Extra_Approval__c> extrApprvr = new List<ECM_Extra_Approval__c>();
        ECM_Extra_Approval__c ecmEX1 = new ECM_Extra_Approval__c(ECM_Active__c = true, ECM_Approver_Position_Name__c = 'Test Approver');
        ecmEX1.ECM_Approver_s_Email_Address__c = 'name.surname@diageo.com';
        ecmEX1.ECM_Lower_Limit_Amount__c = 10;
        ecmEX1.ECM_Upper_Limit_Amount__c = 20;
        ecmEX1.ECM_Re_Investment_Rate_Lower_Limit__c = 1;
        ecmEX1.ECM_Re_Investment_Rate_Upper_Limit__c = 20;
        ecmEX1.ECM_Enable_Delegation__c = false;
        ecmEX1.ECM_Type__c = 'Contract Sales Driver';
        ecmEX1.ECM_Sales_Driver__c = sD1.id;
        extrApprvr.add(ecmEX1);
        
        ECM_Extra_Approval__c ecmEX12 = ecmEX1.clone(false,false,false,false);
        ecmEX12.ECM_Approver_s_Email_Address__c = 'name2.surname@diageo.com';
        ecmEX12.ECM_Lower_Limit_Amount__c = null;
        ecmEX12.ECM_Upper_Limit_Amount__c = null;
        ecmEX12.ECM_Enable_Delegation__c = true;
        ecmEX12.ECM_Sales_Driver__c = sD2.id;
		ecmEX12.ECM_Delegated_Approver_Email_Address__c='Test2@test.com';
        extrApprvr.add(ecmEX12);
        
        ECM_Extra_Approval__c ecmEX2 = ecmEX1.clone(false,false,false,false);
        ecmEX2.ECM_Enable_Delegation__c = false;
        ecmEX2.ECM_Type__c = 'Contract';
        ecmEX2.ECM_Delegated_Approver_Email_Address__c ='Test2@test.com';
        extrApprvr.add(ecmEX2);
        
        ECM_Extra_Approval__c ecmEX3 = ecmEX12.clone(false,false,false,false);
        ecmEX3.ECM_Type__c = 'Contract';
        extrApprvr.add(ecmEX3);
        
        ECM_Extra_Approval__c ecmEX4 = ecmEX1.clone(false,false,false,false);
        ecmEX4.ECM_Re_Investment_Rate_Lower_Limit__c = null;
        ecmEX4.ECM_Re_Investment_Rate_Upper_Limit__c = null;
        ecmEX4.ECM_Type__c = 'Contract Sales Driver Item';
        ecmEX4.ECM_Delegated_Approver_Email_Address__c ='Test2@test.com';
        extrApprvr.add(ecmEX4);
		
		ECM_Extra_Approval__c ecmEX5 = ecmEX12.clone(false,false,false,false);
        ecmEX5.ECM_Enable_Delegation__c = false;
        ecmEX5.ECM_Type__c = 'Contract Sales Driver Item';
        extrApprvr.add(ecmEX5);
        
        ECM_Extra_Approval__c ecmEX6 = ecmEX2.clone(false,false,false,false);
        ecmEX6.ECM_Lower_Limit_Amount__c = 11;
        ecmEX6.ECM_Upper_Limit_Amount__c = 21;
        ecmEX6.ECM_Enable_Delegation__c = true;
        extrApprvr.add(ecmEX6);
        
        ECM_Extra_Approval__c ecmEX7 = ecmEX12.clone(false,false,false,false);
        ecmEX7.ECM_Lower_Limit_Amount__c = 10;
        ecmEX7.ECM_Upper_Limit_Amount__c = 200;
        ecmEX7.ECM_Enable_Delegation__c = true;
        ecmEX7.ECM_Delegated_Approver_Email_Address__c='Test7@test.com';
        extrApprvr.add(ecmEX7);
        insert extrApprvr;
        
        List<ECM_Agreement_Approval__c> agrAprvList = new List<ECM_Agreement_Approval__c>();
        for(ECM_Extra_Approval__c ecmEX : extrApprvr){
            ECM_Agreement_Approval__c agrAprv = new ECM_Agreement_Approval__c(ECM_Agreement_Type__c = conType.Id, ECM_Extra_Approval__c = ecmEX.Id);
            agrAprvList.add(agrAprv);
        }
        insert agrAprvList;
        
        //Set up Approval Logs
        List<ECM_Approval_Log__c> ecmCurrentApprovalLogList = new List<ECM_Approval_Log__c>(); 
        String eCMApprovalLogRecordTypeId = ECM_Approval_Log__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Primary approver').getRecordTypeId();
        String eCMApprovalLogExtraRecordTypeId = Schema.SObjectType.ECM_Approval_Log__c.getRecordTypeInfosByDeveloperName().get('ECM_Extra_approver').getRecordTypeId();
		
        ECM_Approval_Log__c ecmCurrentApprovalLog = new ECM_Approval_Log__c();
        ecmCurrentApprovalLog.ECM_Approver_s_Position__c='Legal';
        ecmCurrentApprovalLog.Name='test1@test.com';
        ecmCurrentApprovalLog.ECM_Status__c='Requested';
        ecmCurrentApprovalLog.ECM_Comment__c='Test User';
        ecmCurrentApprovalLog.ECM_Sales_Driver__c = sd1.id;
        ecmCurrentApprovalLog.ECM_Type__c = 'Contract Sales Driver';
        ecmCurrentApprovalLog.ECM_Contract__c=conList[1].Id;
        ecmCurrentApprovalLog.RecordTypeId=eCMApprovalLogRecordTypeId;
        ecmCurrentApprovalLogList.add(ecmCurrentApprovalLog);
        
        ECM_Approval_Log__c ecmCurrentApprovalLog1 = new ECM_Approval_Log__c();
        ecmCurrentApprovalLog1.ECM_Approver_s_Position__c='Legal';
        ecmCurrentApprovalLog1.Name='test11@test.com';
        ecmCurrentApprovalLog1.ECM_Status__c='Requested';
        ecmCurrentApprovalLog1.ECM_Comment__c='Test User';
        ecmCurrentApprovalLog1.ECM_Type__c = 'Contract';
        ecmCurrentApprovalLog1.ECM_Contract__c=conList[0].Id;
        ecmCurrentApprovalLog1.RecordTypeId=eCMApprovalLogRecordTypeId;
        ecmCurrentApprovalLogList.add(ecmCurrentApprovalLog1);
        
        ECM_Approval_Log__c ecmCurrentApprovalLog3 = new ECM_Approval_Log__c();
        ecmCurrentApprovalLog3.ECM_Approver_s_Position__c='Legal';
        ecmCurrentApprovalLog3.Name='test13@test.com';
        ecmCurrentApprovalLog3.ECM_Status__c='Requested';
        ecmCurrentApprovalLog3.ECM_Comment__c='Test User';
        ecmCurrentApprovalLog3.ECM_Type__c = 'Contract Sales Driver Item';
        ecmCurrentApprovalLog3.ECM_Contract__c = conList[2].Id;
        ecmCurrentApprovalLog3.RecordTypeId=eCMApprovalLogExtraRecordTypeId;
        ecmCurrentApprovalLogList.add(ecmCurrentApprovalLog3);
        
        ECM_Approval_Log__c ecmCurrentApprovalLog4 = ecmCurrentApprovalLog1.clone(false,false,false,false);
        ecmCurrentApprovalLog4.ECM_Contract__c = conList[4].Id;
        ecmCurrentApprovalLogList.add(ecmCurrentApprovalLog4);
        Insert ecmCurrentApprovalLogList;
		
        //Set up Org Settings
		EDGE_UtilityTestClass.createOrgSettings(); 
        Org_Setting__c orgSetting = Org_Setting__c.getOrgDefaults();
        orgSetting.Run_Triggers__c=true;
        update orgSetting;
        
        Test.startTest();
        Contract ecmCont = [SELECT Id, ECM_Overall_Investment_Amount__c, ECM_Agreement_Type__c,Status,Account.Country__r.Name,Account.Country__r.Code__c,
                            Account.Country__c,ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c, ECM_Hybrid_CustInvest_Total_PercentGP__c,
                            ECM_Overall_Investment_Figure__c,ECM_Territory__r.Country__r.Name,ECM_Territory__r.Region__c,
                            ECM_Territory__r.Business_Unit__c,ECM_Territory__r.Sales_Area__c,ECM_Territory__c,Recordtype.DeveloperName,
                            ECM_Recalled__c,ECM_Reason_For_Recall__c,ECM_Parent_Contract__c,ECM_Parent_Contract__r.startDate,startDate,ECM_Duration__c,ECM_Parent_Contract__r.ECM_Duration__c,
                            ECM_Parent_Contract__r.ECM_of_the_total_investment_vs_NSV__c,ECM_of_the_total_investment_vs_NSV__c,ECM_Parent_Contract__r.ECM_Overall_investments__c,ECM_Overall_investments__c,
                            ECM_Parent_Contract__r.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c,ECM_Parent_Contract__r.ECM_Hybrid_CustInvest_Total_PercentGP__c, Owner.Email
                            FROM Contract 
                            WHERE Id IN:conList LIMIT 1];        
        List<ECM_Approval_Log__c> ecmApprovalLogs = [SELECT Id, Name, ECM_Status__c, ECM_Comment__c, ECM_Approver_s_Position__c,
                                                    recordTypeId,recordType.Name,ECM_Time_Date_Log__c,ECM_No_of_Approval_Cycles__c,
                                                    ECM_Sales_Driver__c,ECM_Approval_Log__c.ECM_Type__c 
                                                    FROM ECM_Approval_Log__c 
                                                    WHERE ECM_Contract__c IN:conList];
        for(ECM_Approval_Log__c temp : ecmApprovalLogs){
            temp.ECM_Status__c='Approved'; 
        }
        Database.update(ecmApprovalLogs);
        list<ECM_Approval_Log__c> ecmExtraApprovalLogs = [SELECT Id, Name, ECM_Status__c, ECM_Comment__c, ECM_Approver_s_Position__c,
                                                         recordTypeId,recordType.Name,ECM_Time_Date_Log__c,ECM_No_of_Approval_Cycles__c,
                                                         ECM_Sales_Driver__c,ECM_Approval_Log__c.ECM_Type__c 
                                                         FROM ECM_Approval_Log__c 
                                                         WHERE ECM_Contract__c IN:conList AND recordtypeid =: eCMApprovalLogExtraRecordTypeId];
        Assert.isTrue(!ecmExtraApprovalLogs.isEmpty(),'No Empty Approval Logs'); //Validate that post primary approval, extra approval logs are created
        ECM_ApprovalLogUtility.contractPdf(ecmCont, 'Approved', null);
        ECM_ApprovalLogUtility.contractPdf(ecmCont, 'Active', null);
        ECM_ApprovalLogUtility.addendumPdf(ecmCont, null, null);
        Test.stopTest();		
	}
 /** 
* @description  method cDocsLinkList
* @return  List<ContentDocumentLink>
* @param   contentVersionsList
* @param   approvalLog
**/
        public static List<ContentDocumentLink> cDocsLinkList(List<ContentVersion> contentVersionsList, Id approvalLog){
        List<ContentDocumentLink> cDocLinkLists =new List<ContentDocumentLink>();
          for(ContentVersion contentDoc:contentVersionsList){
                //After saved the Content Verison, get the ContentDocumentId   
                ContentDocumentLink cDocLink = new ContentDocumentLink();
                cDocLink.ContentDocumentId = contentDoc.ContentDocumentId;//Add ContentDocumentId
                cDocLink.LinkedEntityId = approvalLog;//Add attachment parentId
                cDocLink.ShareType = 'I';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
                cDocLink.Visibility = 'InternalUsers';//AllUsers, InternalUsers, SharedUsers
                cDocLinkLists.add(cDocLink);
            } 
        return cDocLinkLists;
    }
    /*
    * @description : tests ECM_ApprovalLogTriggerHelper methods & EU addendum approval specific methods of ECM_ApprovalLogUtility
    * @return : void
    * @param : void
    */ 
    @isTest
    public static void updatePrimaryApprovalLogSpainaddendumApproveScenario(){
		Profile prof = [select id from profile where name=: 'Sales Representative'];
        User usr = runAsUser(prof.id);
        insert usr;
        System.assert(usr.id!=null,'User Id should not be null');
		
        Id geographyId = EDGE_UtilityTestClass.setupCountry('ES'); 
        
        Geography__c country= new Geography__c();
        country.Id=geographyId;
        country.Name='Spain';
        update country;
        
        String bRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        
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
        budjectEU.RecordTypeId=bRecordTypeId;
        insert budjectEU;
        
        Pick_Up_Options__c budjectEU1= new Pick_Up_Options__c();
        budjectEU1.Name='A&P [ES]';
        budjectEU1.Geography__c=geographyId;
        budjectEU1.RecordTypeId=bRecordTypeId;
        insert budjectEU1;
                
        Territory_Budget__c terriBudget1 = ECM_UtilityTestClass.createTerritoryBudget(testterritory.Id, hirarchy.Id);
        terriBudget1.ECM_Budget_Type__c=budjectEU.Id;
        insert terriBudget1;
        
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.Volume_UoM_for_Spirits__c='BTL';
        contractType.ECM_Volume_UoM_for_Beer__c='EU';
        contractType.ECM_Automatic_approval_amount_threshold__c=4000000.00;
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;Volume Target;Investment;UoM';
        contractType.ECM_Volume_UoM_for_RTD__c ='Can/Bottle 24 Pack';
        contractType.ECM_Volume_UoM_for_Draught_Cocktails__c='10L BIB';
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
        mktSetting.ECM_Contract_pdf_to_Approval_Mails__c = false;
        mktSetting.Enable_Auto_Approvals__c=true;

        mktSetting.ECM_Rejection_Email_to_Sales_Rep__c = true;
        insert mktSetting;
        
        
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Person_Responsible__c= usr.Id;
        outletAccount.OwnerId = usr.Id;
        outletAccount.Country__c=geographyId;
        insert outletAccount;
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
		List<Contract> contractApprovalList= new List<Contract>();
		
		Contract con = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        con.Status = 'Draft';
        con.Contract_End_Date__c = System.today()+29;
        con.AccountId=outletAccount.Id;
        con.ECM_Territory__c=testterritory.Id;
        con.ECM_Overall_Investment_Amount__c=12.55;
        con.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c=12.32;
        con.ECM_Hybrid_CustInvest_Total_PercentGP__c=24.33;
        con.ECM_Overall_Investment_Figure__c=12.43;
        //objContract.ECM_Contract_Type__c=contractType.Id;
        con.ECM_Agreement_Type__c=contractType.Id;
        con.recordTypeId=contractRecordTypeId;
        con.ECM_Channel__c='On-Premise';
        con.ECM_Banner__c=banner.Id;
        con.StartDate = system.today();
        con.Contract_End_Date__c = system.today()+360;
        insert con;
        
        con.status='Active';
        update con;
        
        ECM_Addendum__c addendum=new ECM_Addendum__c();
        addendum.Name = 'Test_addendum';
        addendum.ECM_Status__c ='In Approval';
        addendum.ECM_Addendum_Type__c= 'Add New Product';
        addendum.ECM_Contract__c=con.id;
        insert addendum;
		
       /* Contract contractForApproval = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        contractForApproval.Status = 'Draft';
        contractForApproval.Contract_End_Date__c = System.today()+29;
        contractForApproval.AccountId=outletAccount.Id;
        contractForApproval.ECM_Territory__c=testterritory.Id;
        contractForApproval.ECM_Overall_Investment_Amount__c=12.55;
        contractForApproval.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c=12.32;
        contractForApproval.ECM_Hybrid_CustInvest_Total_PercentGP__c=24.33;
        contractForApproval.ECM_Overall_Investment_Figure__c=12.43;
        //objContract.ECM_Contract_Type__c=contractType.Id;
        contractForApproval.ECM_Agreement_Type__c=contractType.Id;
        contractForApproval.recordTypeId=contractRecordTypeId;
        contractForApproval.ECM_Channel__c='On-Premise';
        contractForApproval.ECM_Banner__c=banner.Id;
        contractForApproval.StartDate = system.today();
        contractForApproval.Contract_End_Date__c = system.today()+360;
        contractApprovalList.add(contractForApproval);
		
		Contract contractForSDApproval = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        contractForSDApproval.Status = 'Draft';
        contractForSDApproval.Contract_End_Date__c = System.today()+29;
        contractForSDApproval.AccountId=outletAccount.Id;
        contractForSDApproval.ECM_Territory__c=testterritory.Id;
        contractForSDApproval.ECM_Overall_Investment_Amount__c=12.55;
        contractForSDApproval.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c=12.32;
        contractForSDApproval.ECM_Hybrid_CustInvest_Total_PercentGP__c=24.33;
        contractForSDApproval.ECM_Overall_Investment_Figure__c=12.43;
        //objContract.ECM_Contract_Type__c=contractType.Id;
        contractForSDApproval.ECM_Agreement_Type__c=contractType.Id;
        contractForSDApproval.recordTypeId=contractRecordTypeId;
        contractForSDApproval.ECM_Channel__c='On-Premise';
        contractForSDApproval.ECM_Banner__c=banner.Id;
        contractForSDApproval.StartDate = system.today();
        contractForSDApproval.Contract_End_Date__c = system.today()+360;
        contractApprovalList.add(contractForSDApproval);
		
		Contract contractForSDItemApproval = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        contractForSDItemApproval.Status = 'Draft';
        contractForSDItemApproval.Contract_End_Date__c = System.today()+29;
        contractForSDItemApproval.AccountId=outletAccount.Id;
        contractForSDItemApproval.ECM_Territory__c=testterritory.Id;
        contractForSDItemApproval.ECM_Overall_Investment_Amount__c=12.55;
        contractForSDItemApproval.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c=12.32;
        contractForSDItemApproval.ECM_Hybrid_CustInvest_Total_PercentGP__c=24.33;
        contractForSDItemApproval.ECM_Overall_Investment_Figure__c=12.43;
        //objContract.ECM_Contract_Type__c=contractType.Id;
        contractForSDItemApproval.ECM_Agreement_Type__c=contractType.Id;
        contractForSDItemApproval.recordTypeId=contractRecordTypeId;
        contractForSDItemApproval.ECM_Channel__c='On-Premise';
        contractForSDItemApproval.ECM_Banner__c=banner.Id;
        contractForSDItemApproval.StartDate = system.today();
        contractForSDItemApproval.Contract_End_Date__c = system.today()+360;
        contractApprovalList.add(contractForSDItemApproval);*/
        
        Contract objContract = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract.Status = 'Draft';
        objContract.Contract_End_Date__c = System.today()+29;
        objContract.AccountId=outletAccount.Id;
        objContract.ECM_Territory__c=testterritory.Id;
        objContract.ECM_Overall_Investment_Amount__c=10.55;
        objContract.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c=120.32;
        objContract.ECM_Hybrid_CustInvest_Total_PercentGP__c=24.33;
        objContract.ECM_Overall_Investment_Figure__c =122.43;
        objContract.ECM_Total_Indirect_Investment__c =122.43;
        //objContract.ECM_Contract_Type__c=contractType.Id;
        objContract.ECM_Agreement_Type__c=contractType.Id;
        objContract.recordTypeId=contractRecordTypeId;
        objContract.ECM_Channel__c='On-Premise';
        objContract.ECM_Banner__c=banner.Id;
        objContract.StartDate = system.today();
        objContract.Contract_End_Date__c = system.today()+360;
        objContract.ECM_Recalled__c = false;
        contractApprovalList.add(objContract);
		
		Database.insert(contractApprovalList);
        List<ECM_Addendum__c> addendumApprovalList= new List<ECM_Addendum__c>(); 
        
        for(contract c:contractApprovalList){
            ECM_Addendum__c addendum1 = new ECM_Addendum__c();
            addendum1.Name = 'Test_addendum1';
            addendum1.ECM_Status__c ='Draft';
            addendum1.ECM_Addendum_Type__c= 'Add New Product';
            addendum1.ECM_Contract__c=c.id;
            addendumApprovalList.add(addendum1);
		}
		Database.insert(addendumApprovalList);
        contractApprovalList[0].Status = 'Active';
		Database.update(contractApprovalList);
		
      
        Product__c product = new Product__c();
        product.Name='Test';
        product.Product_Full_Name__c='Test';
        product.Country__c=geographyId;
        insert product;
        
        Product__c product2 = new Product__c();
        product2.Name='Test product2';
        product2.Product_Full_Name__c='Testproduct2';
        product2.Country__c=geographyId;
        insert product2;
        
        Product_UOM__c prdtUOM = new Product_UOM__c();
        prdtUOM.Product__c = product.Id;
        prdtUOM.Conversion_Factor__c = 2;
        prdtUOM.Type__c = 'BTL';
        prdtUOM.Unique_ID__c = product.Id + '_BTL';
        insert prdtUOM;
        
        Product_UOM__c prdtUOM2 = new Product_UOM__c();
        prdtUOM2.Product__c = product2.Id;
        prdtUOM2.Conversion_Factor__c = 2;
        prdtUOM2.Type__c = 'BTL';
        prdtUOM2.Unique_ID__c = product2.Id + '_BTL';
        insert prdtUOM2;
        
        Market_Assortment_Product__c marketassort = new Market_Assortment_Product__c();
        marketassort.Product__c=product.Id;
        marketassort.Market_Assortment__c=geographyId;
        insert marketassort;
        
        Market_Assortment_Product__c marketassort2 = new Market_Assortment_Product__c();
        marketassort2.Product__c=product2.Id;
        marketassort2.Market_Assortment__c=geographyId;
        insert marketassort2;
        
        
        ECM_Product_Agreement__c productagg = new ECM_Product_Agreement__c();
        productagg.ECM_Market_Assortment_Product__c=marketassort.Id;
        productagg.ECM_Contract_Type__c=contractType.Id;
        insert productagg;
        
        ECM_Product_Agreement__c productagg2 = new ECM_Product_Agreement__c();
        productagg2.ECM_Market_Assortment_Product__c=marketassort2.Id;
        productagg2.ECM_Contract_Type__c=contractType.Id;
        insert productagg2;
        
        
        
        List<ECM_Contract_Item__c>contractItemList= new List<ECM_Contract_Item__c>();
        ECM_Contract_Item__c newcontractitem1contract1= new ECM_Contract_Item__c();
        newcontractitem1contract1.ECM_Contract__c=contractApprovalList[0].Id;
        newcontractitem1contract1.ECM_Product__c=marketassort.id;
        newcontractitem1contract1.ECM_Volume__c = 20;
        newcontractitem1contract1.ECM_Baseline_volume__c =20;
        newcontractitem1contract1.ECM_Volume_Target_per_PF__c =15;
        newcontractitem1contract1.ECM_Investment__c = 80;
        newcontractitem1contract1.ECM_AnP_investment__c =80;
        newcontractitem1contract1.ECM_Trade_investments__c= 80;
        newcontractitem1contract1.ECM_UoM__c ='4';
        contractItemList.add(newcontractitem1contract1);
        
        ECM_Contract_Item__c newcontractitem2contract1= new ECM_Contract_Item__c();
        newcontractitem2contract1.ECM_Contract__c=contractApprovalList[0].Id;
        newcontractitem2contract1.ECM_Product__c=marketassort2.id;
        newcontractitem2contract1.ECM_Volume__c = 20;
        newcontractitem2contract1.ECM_Baseline_volume__c =20;
        newcontractitem2contract1.ECM_Volume_Target_per_PF__c =15;
        newcontractitem2contract1.ECM_Investment__c = 80;
        newcontractitem2contract1.ECM_AnP_investment__c =80;
        newcontractitem2contract1.ECM_Trade_investments__c= 80;
        newcontractitem2contract1.ECM_UoM__c ='4';
        newcontractitem2contract1.ECM_Addendum__c = addendumApprovalList[0].Id;
        contractItemList.add(newcontractitem2contract1);
		
		
          /*ECM_Contract_Item__c newcontractitem1_contract2= new ECM_Contract_Item__c();
        newcontractitem1_contract2.ECM_Contract__c=contractApprovalList[1].Id;
        newcontractitem1_contract2.ECM_Product__c=marketassort.id;
        contractItemList.add(newcontractitem1_contract2);
		
		
          ECM_Contract_Item__c newcontractitem2_contract2= new ECM_Contract_Item__c();
        newcontractitem2_contract2.ECM_Contract__c=contractApprovalList[1].Id;
        newcontractitem2_contract2.ECM_Product__c=marketassort2.id;
        contractItemList.add(newcontractitem2_contract2);
		
		
          ECM_Contract_Item__c newcontractitem1_contract3= new ECM_Contract_Item__c();
        newcontractitem1_contract3.ECM_Contract__c=contractApprovalList[2].Id;
        newcontractitem1_contract3.ECM_Product__c=marketassort.id;
        contractItemList.add(newcontractitem1_contract3);
		
		
          ECM_Contract_Item__c newcontractitem2_contract3= new ECM_Contract_Item__c();
        newcontractitem2_contract3.ECM_Contract__c=contractApprovalList[2].Id;
        newcontractitem2_contract3.ECM_Product__c=marketassort2.id;
        contractItemList.add(newcontractitem2_contract3);*/
		
		database.insert(contractItemList);
        
        Id salesDriverRecTypeId = Schema.SObjectType.ECM_Sales_Driver__c.getRecordTypeInfosByName().get('Investment').getRecordTypeId();
        Id salesDriverItemRecTypeId = Schema.SObjectType.ECM_Sales_Driver_Item__c.getRecordTypeInfosByName().get('Sales Driver').getRecordTypeId();
        Id salesDriverItemDetailRecTypeId = Schema.SObjectType.ECM_Sales_Driver_Item_Detail__c.getRecordTypeInfosByName().get('Sales Driver').getRecordTypeId();
        
        ECM_Sales_Driver__c salesDriver = ECM_UtilityTestClass.getSalesdriver(terriBudget1.Id,geographyId);
        salesDriver.Recordtypeid = salesDriverRecTypeId;
        salesDriver.ECM_Budget_Type__c = budjectEU.Id;
        insert salesDriver;
        
        ECM_Sales_Driver__c salesDriver1 = ECM_UtilityTestClass.getSalesdriver(terriBudget1.Id,geographyId);
        salesDriver1.ECM_Budget_Type__c = budjectEU1.Id;
        salesDriver1.Recordtypeid = salesDriverRecTypeId;
        insert salesDriver1;
		
		
		ECM_Sales_Driver_Item__c eSCDI = new ECM_Sales_Driver_Item__c(Contract__c=contractApprovalList[0].Id,ECM_Sales_Driver__c=salesDriver.Id);
        eSCDI.RecordTypeId = salesDriverItemRecTypeId;
        eSCDI.ECM_Total_Investment_Amount__c = 200;
        insert eSCDI;
		
		ECM_Sales_Driver_Item__c eSCDI2 = new ECM_Sales_Driver_Item__c(Contract__c=contractApprovalList[0].Id,ECM_Sales_Driver__c=salesDriver1.Id);
        eSCDI2.RecordTypeId = salesDriverItemRecTypeId;
        eSCDI2.ECM_Total_Investment_Amount__c = 100;
        insert eSCDI2;
		
        ECM_Sales_Driver_Item_Detail__c salesDetails1 = ECM_UtilityTestClass.insertSalesdriverDetails(eSCDI, newcontractitem1contract1);
        salesDetails1.RecordTypeId = salesDriverItemDetailRecTypeId;
        salesDetails1.ECM_Investment_Amount__c = 200;
        insert salesDetails1;
		
		ECM_Sales_Driver_Item_Detail__c salesDetails2 = ECM_UtilityTestClass.insertSalesdriverDetails(eSCDI, newcontractitem2contract1);
        salesDetails2.RecordTypeId = salesDriverItemDetailRecTypeId;
        salesDetails2.ECM_Investment_Amount__c = 3000;
        salesDetails2.ECM_Addendum__c = addendumApprovalList[0].Id;
        insert salesDetails2;
        
        ECM_Sales_Driver_Item_Detail__c salesDetails11 = ECM_UtilityTestClass.insertSalesdriverDetails(eSCDI2, newcontractitem1contract1);
        salesDetails11.RecordTypeId = salesDriverItemDetailRecTypeId;
        salesDetails11.ECM_Investment_Amount__c = 200;
        insert salesDetails11;
		
		ECM_Sales_Driver_Item_Detail__c salesDetails22 = ECM_UtilityTestClass.insertSalesdriverDetails(eSCDI2, newcontractitem2contract1);
        salesDetails22.ECM_Investment_Amount__c = 3000;
        salesDetails22.RecordTypeId = salesDriverItemDetailRecTypeId;
        salesDetails22.ECM_Addendum__c = addendumApprovalList[0].Id;
        insert salesDetails22;
		
        ECM_Extra_Approval__c ecmEX1 = new ECM_Extra_Approval__c();
        ecmEX1.Name = 'Test 1';
        ecmEX1.ECM_Active__c = true;
        ecmEX1.ECM_Approver_Position_Name__c = 'Test Approver';
        ecmEX1.ECM_Approver_s_Email_Address__c = 'name.surname1@diageo.com';
        ecmEX1.ECM_Lower_Limit_Amount__c = 10;
        ecmEX1.ECM_Upper_Limit_Amount__c = 200000;
        ecmEX1.ECM_Enable_Delegation__c = false;
        ecmEX1.ECM_Type__c = 'Contract Sales Driver';
        ecmEX1.ECM_Sales_Driver__c = salesDriver.id;
        //ecmEX1.ECM_Legal_Related__c = true;
        insert ecmEX1;
		
		ECM_Extra_Approval__c ecmEX12 = new ECM_Extra_Approval__c();
        ecmEX12.Name = 'Test 2';
        ecmEX12.ECM_Active__c = true;
        ecmEX12.ECM_Approver_Position_Name__c = 'Test Approver';
        ecmEX12.ECM_Approver_s_Email_Address__c = 'name.surname2@diageo.com';
        ecmEX12.ECM_Lower_Limit_Amount__c = 10;
        ecmEX12.ECM_Upper_Limit_Amount__c = 200000;
        ecmEX12.ECM_Enable_Delegation__c = true;
        ecmEX12.ECM_Type__c = 'Contract Sales Driver';
        ecmEX12.ECM_Sales_Driver__c = salesDriver.id;
        //ecmEX12.ECM_Legal_Related__c = true;
		ecmEX12.ECM_Delegated_Approver_Email_Address__c='Test2@test.com';
        insert ecmEX12;
		
        
        ECM_Extra_Approval__c ecmEX2 = new ECM_Extra_Approval__c();
        ecmEX2.Name = 'Test 3';
        ecmEX2.ECM_Active__c = true;
        ecmEX2.ECM_Approver_Position_Name__c = 'Test Approver';
        ecmEX2.ECM_Approver_s_Email_Address__c = 'name.surname3@diageo.com';
        ecmEX2.ECM_Lower_Limit_Amount__c = 10;
        ecmEX2.ECM_Upper_Limit_Amount__c = 200000;
        ecmEX2.ECM_Re_Investment_Rate_Lower_Limit__c = 1;
        ecmEX2.ECM_Re_Investment_Rate_Upper_Limit__c = 20;
        ecmEX2.ECM_Enable_Delegation__c = false;
        ecmEX2.ECM_Type__c = 'Contract';
        //ecmEX2.ECM_Legal_Related__c = true;
        ecmEX2.ECM_Delegated_Approver_Email_Address__c ='Test2@test.com';
        insert ecmEX2;
        
        ECM_Extra_Approval__c ecmEX3 = new ECM_Extra_Approval__c();
        ecmEX3.Name = 'Test 4';
        ecmEX3.ECM_Active__c = true;
        ecmEX3.ECM_Approver_Position_Name__c = 'Test Approverr';
        ecmEX3.ECM_Approver_s_Email_Address__c = 'name.surname4@diageo.com';
        ecmEX3.ECM_Lower_Limit_Amount__c = 1;
        ecmEX3.ECM_Upper_Limit_Amount__c = 2000000;
        ecmEX3.ECM_Enable_Delegation__c = false;
        ecmEX3.ECM_Type__c = 'Contract';
        ecmEX3.ECM_Legal_Related__c = true;
        ecmEX3.ECM_Delegated_Approver_Email_Address__c ='Test2@test.com';
        insert ecmEX3;
        
        ECM_Extra_Approval__c ecmEX6 = new ECM_Extra_Approval__c();
        ecmEX6.Name = 'Test 7';
        ecmEX6.ECM_Active__c = true;
        ecmEX6.ECM_Approver_Position_Name__c = 'Test Approverdiageo';
        ecmEX6.ECM_Approver_s_Email_Address__c = 'name.surname66@diageo.com';
        ecmEX6.ECM_Lower_Limit_Amount__c = 1;
        ecmEX6.ECM_Upper_Limit_Amount__c = 2000000;
        ecmEX6.ECM_Enable_Delegation__c = true;
        ecmEX6.ECM_Type__c = 'Contract';
        ecmEX6.ECM_Legal_Related__c = true;
        ecmEX6.ECM_Delegated_Approver_Email_Address__c ='test2222@diageo.com';
        insert ecmEX6;
        
        ECM_Extra_Approval__c ecmEX4 = new ECM_Extra_Approval__c();
        ecmEX4.Name = 'Test 5';
        ecmEX4.ECM_Active__c = true;
        ecmEX4.ECM_Approver_Position_Name__c = 'Test Approver';
        ecmEX4.ECM_Approver_s_Email_Address__c = 'name.surname5@diageo.com';
        ecmEX4.ECM_Upper_Limit_Amount__c = 20;
        ecmEX4.ECM_Enable_Delegation__c = false;
        ecmEX4.ECM_Type__c = 'Contract Sales Driver Item';
        ecmEX4.ECM_Delegated_Approver_Email_Address__c ='Test2@test.com';
        //ecmEX4.ECM_Legal_Related__c = true;
        insert ecmEX4;
		
		ECM_Extra_Approval__c ecmEX5 = new ECM_Extra_Approval__c();
        ecmEX5.Name = 'Test 6';
        ecmEX5.ECM_Active__c = true;
        ecmEX5.ECM_Approver_Position_Name__c = 'Test Approver';
        ecmEX5.ECM_Approver_s_Email_Address__c = 'name.surname6@diageo.com';		
        ecmEX5.ECM_Upper_Limit_Amount__c = 20;
        ecmEX5.ECM_Enable_Delegation__c = false;
        ecmEX5.ECM_Type__c = 'Contract Sales Driver Item';
        ecmEX5.ECM_Delegated_Approver_Email_Address__c ='Test2@test.com';
        //ecmEX5.ECM_Legal_Related__c = true;
        insert ecmEX5;
        
        List<ECM_Agreement_Approval__c> eCMAAList = new List<ECM_Agreement_Approval__c>();
        
        ECM_Agreement_Approval__c ecmAA1 = new ECM_Agreement_Approval__c();
        ecmAA1.ECM_Agreement_Type__c = contractType.Id;
        ecmAA1.ECM_Extra_Approval__c = ecmEX1.Id;
        eCMAAList.add(ecmAA1);
		
		     ECM_Agreement_Approval__c ecmAA12 = new ECM_Agreement_Approval__c();
             ecmAA12.ECM_Agreement_Type__c = contractType.Id;
             ecmAA12.ECM_Extra_Approval__c = ecmEX12.Id;
        eCMAAList.add(ecmAA12);
        
        ECM_Agreement_Approval__c ecmAA2 = new ECM_Agreement_Approval__c();
        ecmAA2.ECM_Agreement_Type__c = contractType.Id;
        ecmAA2.ECM_Extra_Approval__c = ecmEX2.Id;
        eCMAAList.add(ecmAA2);
        
        ECM_Agreement_Approval__c ecmAA3 = new ECM_Agreement_Approval__c();
        ecmAA3.ECM_Agreement_Type__c = contractType.Id;
        ecmAA3.ECM_Extra_Approval__c = ecmEX3.Id;
        eCMAAList.add(ecmAA3);
        
        ECM_Agreement_Approval__c ecmAA6 = new ECM_Agreement_Approval__c();
        ecmAA6.ECM_Agreement_Type__c = contractType.Id;
        ecmAA6.ECM_Extra_Approval__c = ecmEX6.Id;
        eCMAAList.add(ecmAA6);
        
        ECM_Agreement_Approval__c ecmAA4 = new ECM_Agreement_Approval__c();
        ecmAA4.ECM_Agreement_Type__c = contractType.Id;
        ecmAA4.ECM_Extra_Approval__c = ecmEX4.Id;
        eCMAAList.add(ecmAA4);
		
		ECM_Agreement_Approval__c ecmAA5 = new ECM_Agreement_Approval__c();
        ecmAA5.ECM_Agreement_Type__c = contractType.Id;
        ecmAA5.ECM_Extra_Approval__c = ecmEX5.Id;
        eCMAAList.add(ecmAA5);
        
        Insert eCMAAList;
        
        List<ECM_Approval_Log__c> ecmCurrentApprovalLogList = new List<ECM_Approval_Log__c>();
        
        String eCMApprovalLogRecordTypeId = ECM_Approval_Log__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Primary approver').getRecordTypeId();
        String eCMApprovalLogExtraRecordTypeId = Schema.SObjectType.ECM_Approval_Log__c.getRecordTypeInfosByDeveloperName().get('ECM_Extra_approver').getRecordTypeId();
		
        ECM_Approval_Log__c ecmCurrentApprovalLog = new ECM_Approval_Log__c();
        ecmCurrentApprovalLog.ECM_Approver_s_Position__c='Legal';
        //ecmCurrentApprovalLog.Name='test1@test.com';
        ecmCurrentApprovalLog.Name='name.surname@diageo.com';//name.surname4@diageo.com
        ecmCurrentApprovalLog.ECM_Status__c='Approved';
        ecmCurrentApprovalLog.ECM_Comment__c='Test User';
        ecmCurrentApprovalLog.ECM_No_of_Approval_Cycles__c =1;
        ecmCurrentApprovalLog.ECM_Sales_Driver__c = salesDriver.id;
        ecmCurrentApprovalLog.ECM_Type__c = 'Contract';
        //ecmCurrentApprovalLog.ECM_Time_Date_Log__c=;
        ecmCurrentApprovalLog.ECM_Contract__c=contractApprovalList[0].Id;
        ecmCurrentApprovalLog.RecordTypeId=eCMApprovalLogRecordTypeId;
        ecmCurrentApprovalLogList.add(ecmCurrentApprovalLog);
        
        ECM_Approval_Log__c ecmCurrentApprovalLog2 = new ECM_Approval_Log__c();
        ecmCurrentApprovalLog2.ECM_Approver_s_Position__c='Legal';
        //ecmCurrentApprovalLog.Name='test1@test.com';
        ecmCurrentApprovalLog2.Name='name.surname4@diageo.com';
        ecmCurrentApprovalLog2.ECM_Status__c='Approved';
        ecmCurrentApprovalLog2.ECM_Comment__c='Test User';
        ecmCurrentApprovalLog2.ECM_No_of_Approval_Cycles__c =1;
        ecmCurrentApprovalLog2.ECM_Sales_Driver__c = salesDriver.id;
        ecmCurrentApprovalLog2.ECM_Type__c = 'Contract';
        //ecmCurrentApprovalLog2.ECM_Time_Date_Log__c=;
        ecmCurrentApprovalLog2.ECM_Contract__c=contractApprovalList[0].Id;
        ecmCurrentApprovalLog2.RecordTypeId=eCMApprovalLogExtraRecordTypeId;
        ecmCurrentApprovalLogList.add(ecmCurrentApprovalLog2);
        
        ECM_Approval_Log__c ecmCurrentApprovalLog3 = new ECM_Approval_Log__c();
        ecmCurrentApprovalLog3.ECM_Approver_s_Position__c='Legal';
        //ecmCurrentApprovalLog.Name='test1@test.com';
        ecmCurrentApprovalLog3.Name='test2222@diageo.com';
        ecmCurrentApprovalLog3.ECM_Status__c='Approved';
        ecmCurrentApprovalLog3.ECM_Comment__c='Test User';
        ecmCurrentApprovalLog3.ECM_No_of_Approval_Cycles__c =1;
        ecmCurrentApprovalLog3.ECM_Sales_Driver__c = salesDriver.id;
        ecmCurrentApprovalLog3.ECM_Type__c = 'Contract';
        //ecmCurrentApprovalLog3.ECM_Time_Date_Log__c=;
        ecmCurrentApprovalLog3.ECM_Contract__c=contractApprovalList[0].Id;
        ecmCurrentApprovalLog3.RecordTypeId=eCMApprovalLogExtraRecordTypeId;
        ecmCurrentApprovalLogList.add(ecmCurrentApprovalLog3);
        
        ECM_Approval_Log__c ecmCurrentApprovalLog1 = new ECM_Approval_Log__c();
        ecmCurrentApprovalLog1.ECM_Approver_s_Position__c='Legal';
        ecmCurrentApprovalLog1.Name='name.surname@diageo.com';
        //ecmCurrentApprovalLog1.Name='test11@test.com';
        ecmCurrentApprovalLog1.ECM_Status__c='Requested';
        ecmCurrentApprovalLog1.ECM_Comment__c='Test User';
        ecmCurrentApprovalLog1.ECM_No_of_Approval_Cycles__c =2;
        ecmCurrentApprovalLog1.ECM_Type__c = 'Contract';
        //ecmCurrentApprovalLog.ECM_Time_Date_Log__c=;
        ecmCurrentApprovalLog1.ECM_Contract__c=contractApprovalList[0].Id;
        ecmCurrentApprovalLog1.ECM_Addendum__c=addendumApprovalList[0].Id;
        ecmCurrentApprovalLog1.RecordTypeId=eCMApprovalLogRecordTypeId;
        ecmCurrentApprovalLogList.add(ecmCurrentApprovalLog1);
        

        
        /*ECM_Approval_Log__c ecmCurrentApprovalLog3 = new ECM_Approval_Log__c();
        ecmCurrentApprovalLog3.ECM_Approver_s_Position__c='Legal';
        //ecmCurrentApprovalLog3.Name='test13@test.com';
        ecmCurrentApprovalLog3.Name=' name.surname@diageo.com';
       ecmCurrentApprovalLog3.ECM_No_of_Approval_Cycles__c =2;
        ecmCurrentApprovalLog3.ECM_Status__c='Requested';
        ecmCurrentApprovalLog3.ECM_Comment__c='Test User';
        ecmCurrentApprovalLog3.ECM_Type__c = 'Contract Sales Driver Item';
        ecmCurrentApprovalLog3.ECM_Contract__c=contractApprovalList[0].Id;
        ecmCurrentApprovalLog3.ECM_Addendum__c=addendumApprovalList[0].Id;
        ecmCurrentApprovalLog3.RecordTypeId=eCMApprovalLogExtraRecordTypeId;
        ecmCurrentApprovalLogList.add(ecmCurrentApprovalLog3);*/
        //Added as a list
                Id recordIdContentVersion = null;
                recordIdContentVersion = Schema.SObjectType.ContentVersion.getRecordTypeInfosByDeveloperName().get('Contracts').getRecordTypeId();
          Id recordIdContentVersionAddnm = null;
          recordIdContentVersionAddnm = Schema.SObjectType.ContentVersion.getRecordTypeInfosByDeveloperName().get('Addendum').getRecordTypeId();
       List<ContentVersion> contveList =new  List<ContentVersion>();
        Insert ecmCurrentApprovalLogList;
        List<Id> approvalLogIdList=new List<Id>();
        for(ECM_Approval_Log__c ecmCurrentAppLog:ecmCurrentApprovalLogList){   
           contveList = contveLists(ecmCurrentAppLog);
        }
        
        insert contveList;
        List<ContentDocumentLink> cDocLinkList =new List<ContentDocumentLink>();
        List<ContentVersion> contentVersionList = new List<ContentVersion>();
        contentVersionList = [SELECT ContentDocumentId FROM ContentVersion WHERE Id IN:contveList];
        for(Id approvalLog: approvalLogIdList){
          cDocLinkList =  cDocsLinkList(contentVersionList,approvalLog);
        }
        
        insert cDocLinkList;
        EDGE_UtilityTestClass.createOrgSettings(); 
        
        Org_Setting__c orgSetting = Org_Setting__c.getOrgDefaults();
        orgSetting.Run_Triggers__c=true;
        update orgSetting;
        
        Test.startTest();
        
        ECM_CreateContractController.changeAddendumStatus(addendumApprovalList[0].Id,false);
        ECM_CreateContractController.changeAddendumStatus(addendumApprovalList[0].Id,true);
        
        /*Contract ecmCont = [select Id, ECM_Overall_Investment_Amount__c, ECM_Agreement_Type__c,Status,Account.Country__r.Name,Account.Country__r.Code__c,
                            Account.Country__c,ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c, ECM_Hybrid_CustInvest_Total_PercentGP__c,
                            ECM_Overall_Investment_Figure__c,ECM_Territory__r.Country__r.Name,ECM_Territory__r.Region__c,
                            ECM_Territory__r.Business_Unit__c,ECM_Territory__r.Sales_Area__c,ECM_Territory__c,Recordtype.DeveloperName,
                            
                            ECM_Recalled__c,ECM_Reason_For_Recall__c,ECM_Parent_Contract__c,ECM_Parent_Contract__r.startDate,startDate,ECM_Duration__c,ECM_Parent_Contract__r.ECM_Duration__c,
                            ECM_Parent_Contract__r.ECM_of_the_total_investment_vs_NSV__c,ECM_of_the_total_investment_vs_NSV__c,ECM_Parent_Contract__r.ECM_Overall_investments__c,ECM_Overall_investments__c,
                            ECM_Parent_Contract__r.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c,ECM_Parent_Contract__r.ECM_Hybrid_CustInvest_Total_PercentGP__c, Owner.Email

                            from Contract where Id IN:contractApprovalList limit 1];*/
        
        list<ECM_Approval_Log__c>ecmApprovalLogs = [Select Id, Name, ECM_Status__c, ECM_Comment__c, ECM_Approver_s_Position__c,
                                                    recordTypeId,recordType.Name,ECM_Time_Date_Log__c,ECM_No_of_Approval_Cycles__c,
                                                    ECM_Sales_Driver__c,ECM_Approval_Log__c.ECM_Type__c From ECM_Approval_Log__c 
                                                    Where ECM_Contract__c IN:contractApprovalList];
        for(ECM_Approval_Log__c temp:ecmApprovalLogs){
            if(temp.ECM_Status__c == 'Requested'){
                temp.ECM_Status__c='Approved';
            }
            
        }
        
        Database.update(ecmApprovalLogs);
                list<ECM_Approval_Log__c>ecmExtraApprovalLogs;
                ecmExtraApprovalLogs = [Select Id, Name, ECM_Status__c, ECM_Comment__c, ECM_Approver_s_Position__c,
                                                    recordTypeId,recordType.Name,ECM_Time_Date_Log__c,ECM_No_of_Approval_Cycles__c,
                                                    ECM_Sales_Driver__c,ECM_Approval_Log__c.ECM_Type__c From ECM_Approval_Log__c 
                                                    Where ECM_Contract__c IN:contractApprovalList and recordtypeid=:eCMApprovalLogExtraRecordTypeId];
        //system.assertEquals(ecmExtraApprovalLogs.size(), 3);
        Test.stopTest();		
	}
     /** 
* @description  method cDocsLinkList
* @return  List<ContentDocumentLink>
* @param   profId
**/
      
    public static User runAsUser(Id profId) {
        User usr = new User();      
        usr.firstName = 'test1';
        usr.lastName = 'test2';
        usr.profileId = profId;        
        usr.email = 'test@test.com';
        usr.Username ='testcm123'+'_'+userinfo.getOrganizationId()+'@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='ES';
        usr.Title='Legal';
        return usr;
    }
 /** 
  * @description  method cDocsLinkList
  * @return  List<ContentVersion>
  * @param   ecmCurrentAppLog
  **/
    public static List<ContentVersion> contveLists(ECM_Approval_Log__c ecmCurrentAppLog){
        String eCMApprovalLogRecordTypeId = ECM_Approval_Log__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Primary approver').getRecordTypeId();
        List<Id> approvalLogIdList=new List<Id>();
        Id recordIdContentVersion = Schema.SObjectType.ContentVersion.getRecordTypeInfosByDeveloperName().get('Contracts').getRecordTypeId();
        Id recordIdContentVersionAddnm = Schema.SObjectType.ContentVersion.getRecordTypeInfosByDeveloperName().get('Addendum').getRecordTypeId();
       List<ContentVersion> contverList =new  List<ContentVersion>();
        if(ecmCurrentAppLog.RecordTypeId == eCMApprovalLogRecordTypeId ){
                ContentVersion cVersionPdf = new ContentVersion();
                approvalLogIdList.add(ecmCurrentAppLog.Id);
            if(String.isNotEmpty(recordIdContentVersion)){
                cVersionPdf.RecordTypeId = recordIdContentVersion;
            }
            cVersionPdf.Content_Type__c = 'Contracts';
            cVersionPdf.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
            cVersionPdf.PathOnClient = system.label.ECM_Contract_Approval_Email_PDF_Name;//File name with extention
            cVersionPdf.Title = system.label.ECM_Contract_Approval_Email_PDF_Name;//Name of the file
            cVersionPdf.VersionData = blob.valueof('attPdf body');//File content
            contverList.add(cVersionPdf);
                
                 ContentVersion cVersionPdfAddnm = new ContentVersion();
            if(String.isNotEmpty(recordIdContentVersionAddnm)){
                cVersionPdfAddnm.RecordTypeId = recordIdContentVersionAddnm;
            }
            cVersionPdfAddnm.Content_Type__c = 'Contracts';
            cVersionPdfAddnm.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
            cVersionPdfAddnm.PathOnClient = system.label.ECM_Addendum_Approval_File_Name;//File name with extention
            cVersionPdfAddnm.Title = system.label.ECM_Addendum_Approval_File_Name;//Name of the file
            cVersionPdfAddnm.VersionData = blob.valueof('attPdf body');//File content
            contverList.add(cVersionPdfAddnm);
            }
        return contverList;
    }
  /*  public static List<ContentDocumentLink> cDocsLinkList(List<ContentVersion> contentVersionsList, Id approvalLog){
        List<ContentDocumentLink> cDocLinkLists =new List<ContentDocumentLink>();
          for(ContentVersion contentDoc:contentVersionsList){
                //After saved the Content Verison, get the ContentDocumentId   
                ContentDocumentLink cDocLink = new ContentDocumentLink();
                cDocLink.ContentDocumentId = contentDoc.ContentDocumentId;//Add ContentDocumentId
                cDocLink.LinkedEntityId = approvalLog;//Add attachment parentId
                cDocLink.ShareType = 'I';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
                cDocLink.Visibility = 'InternalUsers';//AllUsers, InternalUsers, SharedUsers
                cDocLinkLists.add(cDocLink);
            } 
        return cDocLinkLists;
    }*/
}