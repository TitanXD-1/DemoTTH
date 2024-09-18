/*
@Name: ECM_CreateContractController_Test
@Description: This Class is test class for ECM_CreateContractController class.
@History                                                                                                                       
VERSION    AUTHOR                     DATE              DETAIL
1.0      Amit,Veerendra,Keshav       21/01/2020        Initial Development
1.1			Saurav Prasad			 06/03/2023			CUS-123	:	FASTTRACK-Logic for the Legal Compliance Field 
1.2         Joshraj Sen              23/04/2024         152811 - Custom Button to Generate PDF from Market Setting
*/
@isTest
public class ECM_CreateContractController_Test 
{
    @isTest 
    public static void createOutletContractTest(){
        List<Account> acclist = new List<Account>();
        List<Account> acclist1 = new List<Account>();
        Profile prof = [select id from profile where name=: 'Sales Representative'];
        User usrmngr = new User();
        usrmngr.firstName = 'testManager';
        usrmngr.lastName = 't2';
        usrmngr.profileId = prof.id;        
        usrmngr.email = 'test.MamagerSfdc@test.com';
        usrmngr.Username ='test.MamagerSfdc@test.com';
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
        usr.email = 'test.MamagerSfdc1@test.com';
        usr.Username ='test.MamagerSfdc1@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='ES';
        usr.ManagerId = usrmngr.Id;
        usr.DelegatedApproverId = usrmngr.Id;
        insert usr;
        System.assert(usr.id!=null,'user id should not be null');
        
        system.debug(LoggingLevel.Debug,'(USer==>  '+usr);
        user newuser = EDGE_UtilityTestClass.runAsUser('Testabc','System Administrator');
        insert newuser;
        Map<string,string> fieldsformappingrecords;
        fieldsformappingrecords= new  Map<string,string>{'Draught Discounts' => 'ECM_Draught_Spirits_Discount_Level__c',
            'Pouring Discounts' => 'ECM_Spirits_Pouring_Discount_Level__c',
            'Premium Discounts' => 'ECM_Spirits_Premium_Discount_Level__c',
            'Reserve Discounts' => 'ECM_Spirits_Reserve_Discount_Level__c',
            'RTD Discount' => 'ECM_RTD_Discount_Level__c',
            'Spirits Discounts' => 'ECM_Spirits_Discount_Level__c'};
                
        Map<String,contract> mapstringrecordvalue = new Map<string,contract>();
        List<ECM_Contract_Item__c> contractItemslist = new List<ECM_Contract_Item__c>();
        List<ECM_Contract_Item__c> contractItemslist1 = new List<ECM_Contract_Item__c>();
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
                
        //Id geographyId1 = EDGE_UtilityTestClass.setupCountry('AU'); 
        Territory__c testterritory=New Territory__c();
        testterritory.Name='Testterriotory';
        testterritory.Territory_Type__c='Sales';
        testterritory.Country__c= geographyId;
        testterritory.Status__c='Active';
        testterritory.Primary_Sales_Rep__c = usr.id;
        insert testterritory;
        
        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        contractType.ECM_Activation_Spend_Table_Configuration__c = 'Activation Spend Sub Group;Activity Type Description;Delivery Date;Must Do';
        contractType.ECM_Contract_Approval_mail_to_Customer__c = true;
        contractType.ECM_of_Outlets_Tap_Space_Required__c = 0.8;
        insert contractType;
        
        Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(geographyId);
        mktSetting.ECM_Contract_Header_Details__c='ECM_Contract_Owner__c;ECM_Territory__r.Name;Account.ECM_Legal_Name__c;Account.Name;ECM_Agreement_Type__r.Name;StartDate;Contract_End_Date__c;ContractNumber;Name';
        mktSetting.ECM_Investment_Summary_KPIS__c='ECM_Total_Volume_Target_Spirits__c;ECM_Total_Volume_Target_Beers__c;ECM_Incremental_Volume_Spirits__c;ECM_Incremental_Volume_Beers__c;ECM_Total_trade_investment_Beers__c;ECM_Total_A_P_Investment_Spirits__c;ECM_Incremental_GP__c;ECM_Incremental_GP_Beers__c';
        mktSetting.ECM_Category_Split_KPIS__c='ECM_NSV_reserve_share__c;ECM_NSV_premium_core_share__c;ECM_GP_reserve_share__c;ECM_GP_innovation_share__c;ECM_GM_reserve_share__c;ECM_GM_innovation_share__c;ECM_GM_premium_core_share__c;ECM_TV_reserve_share__c;ECM_TV_premium_core_share__c;ECM_IV_reserve_share__c;ECM_IV_innovation_share__c;ECM_IV_premium_core_share__c';
        mktSetting.ECM_Product_Investment_Details__c='ECM_Retro_investment__c;ECM_Trade_Investments__c;ECM_AnP_investment__c;ECM_Gross_margin__c;ECM_Total_GP_EU__c;ECM_Generated_NSV_EU__c;ECM_NSV_After_Investment__c;ECM_Incremental_GP_after_Investment__c;Tiers;ECM_UoM__c;ECM_Baseline_volume__c;ECM_Volume__c;ECM_Incremental_Volume__c;ECM_CAAP_Total__c;ECM_Product_growth_driver__c';
        mktSetting.ECM_Sales_Drivers_Details__c='ECM_Investement_Description__c;ECM_Budget_Type__c;ECM_Payment_Frequency__r.ECM_Type__c;Payment dates;ECM_Total_Investment_Amount__c;ECM_Prepayment__c;ECM_Sales_Driver_Name__c';
        mktSetting.ECM_Contract_Creation_Page__c='Global';
        mktSetting.ECM_Contract_Management_Market__c=true;
        mktSetting.ECM_SAP_Order_Type__c='YPCR';    
        mktSetting.ECM_Mandatory_field_for_Contract__c='SAP Sold To;Legal Name;SAP Ship to;Customer email for Contract;Sales org;';
        mktSetting.ECM_Payment_Management_Email__c='test@test22.com';
        mktSetting.ECM_Email_to_Send_Payment_CSV__c='test@test23.com';
        mktSetting.ECM_Contract_pdf_to_Approval_Mails__c = true;
        insert mktSetting;
        
        String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        String bRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        //String localSRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        
        Pick_Up_Options__c banner= new Pick_Up_Options__c();
        banner.Name='Range[ES]';
        banner.Geography__c=geographyId;
        banner.RecordTypeId=bannerRecordTypeId;
        insert banner;
        
        Pick_Up_Options__c bannerAU= new Pick_Up_Options__c();
        bannerAU.Name='IBA[AU]';
        bannerAU.Geography__c=geographyId;
        bannerAU.RecordTypeId=bannerRecordTypeId;
        insert bannerAU;
                
        Pick_Up_Options__c budjectEU= new Pick_Up_Options__c();
        budjectEU.Name='A&P [ES]';
        budjectEU.Geography__c=geographyId;
        budjectEU.RecordTypeId=bRecordTypeId;
        insert budjectEU;
        
        String pickupRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId();
        String pickupRecordTypeId1 = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Local Segment').getRecordTypeId();
        //id Discountrecordtypeid=Schema.Sobjecttype.Pick_Up_Options__c.getRecordTypeInfosByName().get('Discount Level').getRecordTypeId();
        
        Pick_Up_Options__c banner1= new Pick_Up_Options__c();
        banner1.Name='Range[ES]';
        banner1.Geography__c=geographyId;
        banner1.RecordTypeId=pickupRecordTypeId;
        banner1.Type__c ='Local-Segment1';
        //insert banner1;
        
        Pick_Up_Options__c bannerAU1= new Pick_Up_Options__c();
        bannerAU1.Name='IBAE[AU]';
        bannerAU1.Geography__c=geographyId;
        bannerAU1.RecordTypeId=pickupRecordTypeId1;
        bannerAU1.Type__c='Local-Segment1';
        bannerAU1.Status__c='Active';
        insert bannerAU1;
        
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Person_Responsible__c= usr.Id;
        outletAccount.OwnerId = usr.Id;
        outletAccount.SAP_Sold_to__c='3984021';
        outletAccount.VAT_Number__c='TAXID123';
        outletAccount.ECM_Legal_Name__c='Legal';
        outletAccount.Email_for_contracts_payments__c='manikandan.t@diageo.com.test';
        outletAccount.Country__c = geographyId;
        outletAccount.IsOperator__c=true;
        outletAccount.SAP_Ship_to__c = 'sap1234';
        outletAccount.Sales_Org__c = 'sap0987';
        insert outletAccount;
        
        String accRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId(); 
        
        Account outlet = new Account();
        outlet.Name = 'Test55_Outlet';
        outlet.RecordTypeId = accRecordTypeId;
        outlet.BillingStreet = '17 Asian Highway 45';
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
        outlet.Email_for_contracts_payments__c='manikandan.t@diageo.com.test';
        insert outlet;  
        
        Account outletAccount1 = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount1.Person_Responsible__c= usr.Id;
        outletAccount1.OwnerId = usr.Id;
        outletAccount1.IsOperator__c=true;
        //outletAccount1.Operator__c=outlet.id;
        outletAccount1.SAP_Sold_to__c='398402';
        outletAccount1.ECM_Legal_Name__c='Legal';
        outletAccount1.Email_for_contracts_payments__c='manikandan.t@diageo.com.test';
        outletAccount1.VAT_Number__c='TAXID13';
        outletAccount1.Name ='Test_Outlet_Diageo1';
        insert outletAccount1;
        
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        insert territory;
        
        Territory_Hierarchy__c hirarchy= ECM_UtilityTestClass.createhirarchy(geographyId);
        hirarchy.recordtypeId=Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Region').getRecordTypeId();
        insert hirarchy;
        
        territory.Primary_Sales_Rep__c = usr.id;
        territory.Country__c= geographyId;
        territory.Region__c=hirarchy.Id;
        update territory;
        
        ECM_Payment_Frequency__c paymfreq = new ECM_Payment_Frequency__c();
        paymfreq.ECM_Type__c='Monthly';
        paymfreq.ECM_Other_Investment__c=true;
        paymfreq.ECM_Volume_target__c=true;
        paymfreq.ECM_Number_of_months_for_recurrence__c='20';
        paymfreq.ECM_From_When_Starts__c='Calendar Year';
        paymfreq.ECM_Geography__c=geographyId;
        Insert paymfreq;
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        //String contractGroupRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Group').getRecordTypeId();
        
        Contract objContract = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract.Status = 'Draft';
        objContract.Contract_End_Date__c = System.today()+29;
        objContract.AccountId=outletAccount.Id;
        objContract.ECM_Territory__c=testterritory.Id;
        //objContract.ECM_Contract_Type__c=contractType.Id;
        objContract.ECM_Agreement_Type__c=contractType.Id;
        objContract.recordTypeId=contractRecordTypeId;
        objContract.ECM_Channel__c='On-Premise';
        objContract.ECM_Banner__c=banner.Id;
        objContract.StartDate = system.today();
        objContract.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContract.Contract_End_Date__c = system.today()+360;
        objContract.OwnerId = usr.id;
        insert objContract;

        ECM_Event__c objeve = new ECM_Event__c();
        objeve.ECM_Contract__c  = objContract.Id;
        objeve.ECM_Event_Name__c = 'Event1';
        objeve.ECM_Event_Date__c = System.today();
        objeve.ECM_Event_Unique_Id__c = objeve.ECM_Contract__c+objeve.ECM_Event_Name__c+objeve.ECM_Event_Date__c;
        insert objeve;
        List<ECM_Event__c> deleteEventList = new List<ECM_Event__c>();
        deleteEventList.add(objeve);
        
        Contract objContract2 = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract2.Status = 'Draft';
        objContract2.Contract_End_Date__c = System.today()+29;
        objContract2.AccountId=outletAccount.Id;
        objContract2.ECM_Territory__c=testterritory.Id;
        //objContract2.ECM_Contract_Type__c=contractType.Id;
        objContract2.recordTypeId=contractRecordTypeId;
        objContract2.ECM_Channel__c='On-Premise';
        objContract2.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContract2.StartDate = system.today()+150;
        objContract2.Contract_End_Date__c = system.today()+360;
        objContract2.ECM_Agreement_Type__c=contractType.Id;
        insert objContract2;
        
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
        ContentDocumentLink linkedFile = new ContentDocumentLink(LinkedEntityId=objContract2.Id, ContentDocumentId=insertedFile.ContentDocumentId);
        insert linkedFile;
        
        system.debug(LoggingLevel.Debug,'CreatedById---'+objContract2.CreatedById);
        Contract objContract3 = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract3.Status = 'Draft';
        objContract3.Contract_End_Date__c = System.today()+29;
        objContract3.AccountId=outletAccount.Id;
        objContract3.ECM_Territory__c=testterritory.Id;
        //objContract3.ECM_Contract_Type__c=contractType.Id;
        objContract3.recordTypeId=contractRecordTypeId;
        objContract3.ECM_Channel__c='On-Premise';
        objContract3.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContract3.StartDate = system.today();
        objContract3.Contract_End_Date__c = system.today()+150;
        insert objContract3;
        
        Contract objContract4 = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract4.Status = 'Draft';
        objContract4.Contract_End_Date__c = System.today()+29;
        objContract4.AccountId=outletAccount.Id;
        objContract4.ECM_Territory__c=testterritory.Id;
        //objContract4.ECM_Contract_Type__c=contractType.Id;
        objContract4.recordTypeId=contractRecordTypeId;
        objContract4.ECM_Channel__c='On-Premise';
        objContract4.StartDate = system.today()+150;
        objContract4.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContract4.Contract_End_Date__c = system.today()+180;
        insert objContract4;
        
        Contract objContract5 = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract5.Status = 'Draft';
        objContract5.Contract_End_Date__c = System.today()+29;
        objContract5.AccountId=outletAccount.Id;
        objContract5.ECM_Territory__c=testterritory.Id;
        //objContract5.ECM_Contract_Type__c=contractType.Id;
        objContract5.recordTypeId=contractRecordTypeId;
        objContract5.ECM_Channel__c='On-Premise';
        objContract5.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContract5.StartDate = system.today()+90;
        objContract5.Contract_End_Date__c = system.today()+500;
        insert objContract5;
        
        Contract objContract6 = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract6.Status = 'Draft';
        objContract6.Contract_End_Date__c = System.today()+29;
        objContract6.AccountId=outletAccount.Id;
        objContract6.ECM_Territory__c=testterritory.Id;
        //objContract6.ECM_Contract_Type__c=contractType.Id;
        objContract6.recordTypeId=contractRecordTypeId;
        objContract6.ECM_Channel__c='On-Premise';
        objContract6.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContract6.StartDate = system.today()+90;
        objContract6.Contract_End_Date__c = system.today()+900;
        insert objContract6;
        
        Contract objContract7 = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract7.Status = 'Draft';
        objContract7.Contract_End_Date__c = System.today()+29;
        objContract7.AccountId=outletAccount.Id;
        objContract7.ECM_Territory__c=testterritory.Id;
        //objContract7.ECM_Contract_Type__c=contractType.Id;
        objContract7.ECM_Agreement_Type__c=contractType.Id;
        objContract7.recordTypeId=contractRecordTypeId;
        objContract7.ECM_Channel__c='On-Premise';
        objContract7.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContract7.ECM_Banner__c=banner.Id;
        objContract7.StartDate = system.today();
        objContract7.Contract_End_Date__c = system.today()+360;
        objContract7.ECM_Overall_Investment_Amount__c=30.00;
        insert objContract7;
        
        //CUS-123
        Id pgdRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get(System.Label.ECM_VolumeTargetApexClass_Product_Growth_driver).getRecordTypeId();
        Pick_Up_Options__c pgdRecord = new Pick_Up_Options__c();
        pgdRecord.ECM_Product_Growth_Driver_Category__c='Pouring';
        pgdRecord.ECM_Legal_Compliance__c = true;
        pgdRecord.Geography__c = geographyId;
        pgdRecord.RecordTypeId = pgdRecordTypeId;
        pgdRecord.Name = 'Test PGD[AU]';
        Insert pgdRecord;
        
        Contract objContract8 = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract8.Status = 'Draft';
        objContract8.Contract_End_Date__c = System.today()+29;
        objContract8.AccountId=outletAccount.Id;
        objContract8.ECM_Territory__c=testterritory.Id;
        //objContract8.ECM_Contract_Type__c=contractType.Id;
        objContract8.ECM_Agreement_Type__c=contractType.Id;
        objContract8.recordTypeId=contractRecordTypeId;  
        objContract8.ECM_Channel__c='On-Premise';
        objContract8.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContract8.ECM_Banner__c=banner.Id;
        objContract8.StartDate = system.today();
        objContract8.Contract_End_Date__c = system.today()+360;
        insert objContract8;
        
        objContract8.UOS_AP_Rate__c= 55;
        objContract8.UOS_Rebate_Rate__c=88;
        objContract8.Status='Active';
        update objContract8;  
        
        //Spain Data
        Id geographyId1 = EDGE_UtilityTestClass.setupCountrySpain('ES'); 
        Market_Setting__c mktSettingObj =EDGE_UtilityTestClass.getMarketSetting(geographyId1);
        mktSettingObj.ECM_Contract_Header_Details__c='ECM_Contract_Owner__c;ECM_Territory__r.Name;Account.ECM_Legal_Name__c;Account.Name;ECM_Agreement_Type__r.Name;StartDate;Contract_End_Date__c;ContractNumber;Name';
        mktSettingObj.ECM_Investment_Summary_KPIS__c='ECM_Total_Volume_Target_Spirits__c;ECM_Total_Volume_Target_Beers__c;ECM_Incremental_Volume_Spirits__c;ECM_Incremental_Volume_Beers__c;ECM_Total_trade_investment_Beers__c;ECM_Total_A_P_Investment_Spirits__c;ECM_Incremental_GP__c;ECM_Incremental_GP_Beers__c';
        mktSettingObj.ECM_Category_Split_KPIS__c='ECM_NSV_reserve_share__c;ECM_NSV_premium_core_share__c;ECM_GP_reserve_share__c;ECM_GP_innovation_share__c;ECM_GM_reserve_share__c;ECM_GM_innovation_share__c;ECM_GM_premium_core_share__c;ECM_TV_reserve_share__c;ECM_TV_premium_core_share__c;ECM_IV_reserve_share__c;ECM_IV_innovation_share__c;ECM_IV_premium_core_share__c';
        mktSettingObj.ECM_Product_Investment_Details__c='ECM_Retro_investment__c;ECM_Trade_Investments__c;ECM_AnP_investment__c;ECM_Gross_margin__c;ECM_Total_GP_EU__c;ECM_Generated_NSV_EU__c;ECM_NSV_After_Investment__c;ECM_Incremental_GP_after_Investment__c;Tiers;ECM_UoM__c;ECM_Baseline_volume__c;ECM_Volume__c;ECM_Incremental_Volume__c;ECM_CAAP_Total__c;ECM_Product_growth_driver__c';
        mktSettingObj.ECM_Sales_Drivers_Details__c='ECM_Investement_Description__c;ECM_Budget_Type__c;ECM_Payment_Frequency__r.ECM_Type__c;Payment dates;ECM_Total_Investment_Amount__c;ECM_Prepayment__c;ECM_Sales_Driver_Name__c';
        mktSettingObj.ECM_Contract_Creation_Page__c='Global';
        mktSettingObj.ECM_Contract_Management_Market__c=true;
        mktSettingObj.ECM_SAP_Order_Type__c='YPCR';        
        mktSettingObj.ECM_Payment_Management_Email__c='test@test22.com';
        mktSettingObj.ECM_Email_to_Send_Payment_CSV__c='test@test23.com';
        insert mktSettingObj;
        
        ECM_Contract_Type__c contractTypeEU = ECM_UtilityTestClass.createContractType(geographyId);
        insert contractTypeEU;        
        
        
        
        Contract objContractEU = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContractEU.Status = 'Draft';
        objContractEU.Contract_End_Date__c = System.today()+29;
        objContractEU.AccountId=outletAccount.Id;
        objContractEU.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContractEU.ECM_Territory__c=testterritory.Id;
        //objContractEU.ECM_Contract_Type__c=contractTypeEU.Id;
        objContractEU.ECM_Agreement_Type__c=contractTypeEU.Id;
        objContractEU.recordTypeId=contractRecordTypeId;
        objContractEU.ECM_Channel__c='On-Premise';
        objContractEU.ECM_Banner__c=banner.Id;
        objContractEU.StartDate = system.today();
        objContractEU.Contract_End_Date__c = system.today()+360;
        insert objContractEU; 
        
        Contract objContractEU1 = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContractEU1.Status = 'Draft';
        objContractEU1.Contract_End_Date__c = System.today()+29;
        objContractEU1.AccountId=outletAccount.Id;
        objContractEU1.ECM_Territory__c=testterritory.Id;
        //objContractEU1.ECM_Contract_Type__c=contractTypeEU.Id;
        objContractEU1.recordTypeId=contractRecordTypeId;
        objContractEU1.ECM_Channel__c='On-Premise';
        objContractEU1.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContractEU1.StartDate = system.today()+150;
        objContractEU1.Contract_End_Date__c = system.today()+360;
        objContractEU1.ECM_Agreement_Type__c=contractTypeEU.Id;
        insert objContractEU1;
        
        objContractEU1.Status = 'Active';
        update objContractEU1;
        
        mapstringrecordvalue.put(objContract.ECM_Channel__c,objContract);
        Business_Role__c businessRole =new Business_Role__c();
        businessRole.Name='Spain Mainland';
        businessRole.Country__c=geographyId;
        businessRole.Call_Type__c='Telephone';
        insert businessRole;
        
        User_Business_Role__c userBusinessRole =new User_Business_Role__c();        
        userBusinessRole.Business_Role__c=businessRole.Id;
        userBusinessRole.User__c=usr.Id;
        insert userBusinessRole;
        
        User_Business_Role__c ubr = new User_Business_Role__c();
        ubr.Business_Role__c= businessRole.Id ;
        ubr.User__c=userinfo.getUserId();
        insert ubr;
        
        ECM_Role_Agreement__c  roleAgreement =new ECM_Role_Agreement__c();        
        //roleAgreement.Business_Role__c=userBusinessRole.Business_Role__c;
        roleAgreement.Business_Role__c=businessRole.Id;
        roleAgreement.Agreement_Type__c=contractType.Id;
        insert roleAgreement;
        
        Product__c product = new Product__c();
        product.Name='Test';
        product.Product_Full_Name__c='Test';
        product.Country__c=geographyId;
        insert product;
        
        Product_UOM__c prdtUOM = new Product_UOM__c();
        prdtUOM.Product__c = product.Id;
        prdtUOM.Conversion_Factor__c = 2;
        prdtUOM.Type__c='BTL';
        prdtUOM.Unique_ID__c= product.id +'BTL';
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
        contractItemslist.add(newcontractitem);
        
        ECM_Contract_Item__c newcontractitem1= new ECM_Contract_Item__c();
        newcontractitem1.ECM_Contract__c=objContract7.Id;
        newcontractitem1.ECM_Product__c=marketassort.id;
        newcontractitem1.ECM_Product_Growth_Driver__c = 'Test PGD/TestPdf';
        insert newcontractitem1;
        ECM_Addendum__c add= new ECM_Addendum__c();
        add.ECM_Contract__c = objContract7.Id;
        add.ECM_Status__c = 'draft';
        insert add;
        contractItemslist1.add(newcontractitem1);
        ECM_Contract_Item__c newcontractitem2= new ECM_Contract_Item__c();
        newcontractitem2.ECM_Contract__c=objContract8.Id;
        newcontractitem2.ECM_Product__c=marketassort.id;
        newcontractitem2.ECM_Addendum__c = add.Id;
        insert newcontractitem2;
        ECM_Contract_Item__c newcontractitem3= new ECM_Contract_Item__c();
        newcontractitem3.ECM_Contract__c=objContract7.Id;
        newcontractitem3.ECM_Product__c=marketassort.id;
        newcontractitem3.ECM_Addendum__c = add.Id;
        newcontractitem3.ECM_EU_Volume__c = 80;
        insert newcontractitem3;
        
        //Sales driver Records
        Territory_Budget__c terriBudget = ECM_UtilityTestClass.createTerritoryBudget(territory.Id, hirarchy.Id);
        insert terriBudget;
        
        Territory_Budget__c terriBudget1 = ECM_UtilityTestClass.createTerritoryBudget(territory.Id, hirarchy.Id);
        terriBudget1.ECM_Budget_Type__c=budjectEU.Id;
        insert terriBudget1;
        
        ECM_Sales_Driver__c salesDriver = ECM_UtilityTestClass.getSalesdriver(terriBudget1.Id,geographyId);
        insert salesDriver;
        
        ECM_Sales_Driver_Item__c eSCDI = new ECM_Sales_Driver_Item__c(Contract__c=objContract7.Id,ECM_Sales_Driver__c=salesDriver.Id,ECM_Investment_Yr1__c=123, ECM_Investment_Yr2__c=123,ECM_Investment_Yr3__c=123,ECM_Payment_Date_Yr1__c=system.today(),ECM_Payment_Date_Yr2__c = system.today(),ECM_Payment_Date_Yr3__c=system.today());
        insert eSCDI;
        
        ECM_Sales_Driver_Item_Detail__c salesDetails1 = ECM_UtilityTestClass.insertSalesdriverDetails(eSCDI, newcontractitem1);
        insert salesDetails1;
        
        List<ECM_Sales_Driver_Item__c> eSDList = new List<ECM_Sales_Driver_Item__c>();
        eSDList.add(eSCDI);
        Depletions__c dep = new Depletions__c();
        dep.ECM_Volume__c = 100.00;
        dep.ECM_Outlet__c = outletAccount.id;
        dep.ECM_Start_Period__c = system.today()+360;
        dep.ECM_End_Period__c = system.today()+29;
        dep.ECM_Product__c = product.id;
        dep.ECM_Outlet__c = outletAccount.Id;
        insert dep;
        
        acclist.add(outletAccount1);
        //system.assertEquals(userBusinessRole.User__c, usr.Id);
        ECM_CreateContractController.getContractTypes();
        ECM_CreateContractController.getContractTypesOutlet(outletAccount.Id);
        
        Outlet_Contract__c otletcontract=New Outlet_Contract__c();
        otletcontract.Contract__c=objContract.Id;
        otletcontract.Outlet__c=outletAccount.Id;
        otletcontract.Activation_Date__c=system.today();
        insert otletcontract;
        otletcontract.ECM_Total_Outlet_Taps__c= 100;
        otletcontract.ECM_No_of_Taps_Diageo_will_Invest__c=75;
        otletcontract.ECM_of_Taps_Diageo_will_invest__c= .75;
        List<Outlet_Contract__c> otletContractList = new List<Outlet_Contract__c>();
        
        ECM_CreateContractController.getEvents(objContract.Id);
        ECM_CreateContractController.deleteEvents(JSON.serialize(deleteEventList));
        
        
        Account ownerAccount=EDGE_UtilityTestClass.getOwnerOperatorAccount();
        ownerAccount.Person_Responsible__c= usr.Id;
        ownerAccount.OwnerId = usr.Id;
        ownerAccount.SAP_Sold_to__c='39840210';
        ownerAccount.VAT_Number__c='TAXID1230';
        ownerAccount.ECM_Legal_Name__c='Legal';
        ownerAccount.Email_for_contracts_payments__c='manikandan.t@diageo.com.test';
        ownerAccount.Country__c = geographyId1;
        ownerAccount.IsOperator__c=true;
        insert ownerAccount;
        
        system.runAs(usr){

            ECM_CreateContractController.getAccountById(outletAccount.Id);
           // ECM_CreateContractController.getUserCountry();
            ECM_Tiering__c tieringObj =new ECM_Tiering__c();
                tieringObj.ECM_Tier_1_volume_limit__c =3;
                tieringObj.ECM_Tier_1_rate_per_UoM__c =4;
                tieringObj.ECM_Tier_2_volume_limit__c =1;
                tieringObj.ECM_Tier2_rate_per_UoM__c =2;
                tieringObj.ECM_Tier_3_volume_limit__c =2;
                tieringObj.ECM_Tier_3_rate_per_UoM__c =3;
                tieringObj.ECM_Contract_Item__c =newcontractitem1.Id;
            insert tieringObj;
            system.debug(LoggingLevel.Debug,'userBusinessRole id==> '+[select id from User_Business_Role__c]);
            
            //ECM_CreateContractController.getContractTypes();
            ECM_CreateContractController.createContract(objContract, outletAccount.Id, contractRecordTypeId, testterritory.Id, contractType.Id,acclist);
            ECM_CreateContractController.createContract(objContract2, outletAccount.Id, contractRecordTypeId, testterritory.Id, contractType.Id,acclist);
            ECM_CreateContractController.createContract(objContract3, outletAccount.Id, contractRecordTypeId, testterritory.Id, contractType.Id,acclist);
            ECM_CreateContractController.createContract(objContract4, outletAccount.Id, contractRecordTypeId, testterritory.Id, contractType.Id,acclist);
            ECM_CreateContractController.createContract(objContract5, outletAccount.Id, contractRecordTypeId, testterritory.Id, contractType.Id,acclist);
            ECM_CreateContractController.createContract(objContract6, outletAccount.Id, contractRecordTypeId, testterritory.Id, contractType.Id,acclist1);
            ECM_CreateContractController.cancelContract(objContract.Id);
            ECM_CreateContractController.getContract(objContract2.Id);
            Test.startTest();
            // ECM_CreateContractController.getContract(objContract2.Id);
            // ECM_CreateContractController.getContractTypesOutlet(outletAccount.Id);
            ECM_CreateContractController.getPickUpOptionsPicklistvalues();
            ECM_CreateContractController.getListOfAccounts();
            ECM_CreateContractController.setdefaultvalues_Discount(objContract);
            ECM_CreateContractController.getChannelPicklistvalues();
            ECM_CreateContractController.getPicklistvalues('Contract','ECM_Channel__c');
            ECM_CreateContractController.statesAndProvinces();
            ECM_CreateContractController.getAccountRecords(1,outletAccount.Operator__c);
            ECM_CreateContractController.loadAccountRecords(3,1,outletAccount1.Operator__c);
            ECM_CreateContractController.validation_for_Agreement_Type(objContractEU,outletAccount.id,contractRecordTypeId);
            ECM_CreateContractController.updateContractItems(contractItemslist);
            ECM_CreateContractController.deleteOldContractItems(contractItemslist);
            ECM_CreateContractController.paymentFrequencyvalues(objContract.ECM_Agreement_Type__c);
            ECM_CreateContractController.paymentSchedulevalues(objContract.ECM_Agreement_Type__c);
            ECM_CreateContractController.salesdrivers(objContract.ECM_Agreement_Type__c);
            ECM_CreateContractController.saveVolumeTargets(JSON.serialize(contractItemslist1),contractType,objContract,add.id);
            ECM_CreateContractController.userAndContractInfo info = new ECM_CreateContractController.userAndContractInfo();
            info = ECM_CreateContractController.getContract(objContract.Id);
            Contract conRec = info.contractInfo.con;
            ECM_CreateContractController.getOutletTapsTable(conRec);
            try
            {
                //String errorRelease = ECM_CreateContractController.submitForApproval(JSON.serialize(contractItemslist1));
                ECM_CreateContractController.updateKpiValues(JSON.serialize(objContract7));
                ECM_CreateContractController.submitForApproval(JSON.serialize(objContract2) ,JSON.serialize(contractItemslist1),JSON.serialize(otletContractList));
            }
            catch(exception e)
            {
                System.debug(LoggingLevel.debug,'Error ');
            }  
            ECM_CreateContractController.get_contractitem_with_exsisiting_baseVol(contractItemslist1);
            //CUS-123
            ECM_CreateContractController.getLeadProductWithSubCategory(objContract7.Id);
            ECM_CreateContractController.savecontract(objContract7);
            ECM_CreateContractController.get_default_Banner_AU();
            ECM_CreateContractController.salesdrivervaluesAU(objContract7.Id);
            ECM_CreateContractController.getUser(newuser.id);
            ECM_CreateContractController.processSalesDriversToInsert('',objContract7);
            List<ECM_CreateContractController.salesdriverItemWrap> salesWrap = ECM_CreateContractController.loadInvestmentsValues(objContract7,contractItemslist1,false,true);
            ECM_CreateContractController.processSalesDriversToInsert(JSON.serialize(salesWrap),objContract7);
            ECM_CreateContractController.createSalesDriverItemDetailForAddendum(objContract7.Id,add.id);
            //Sales driver Testing 
            ECM_CreateContractController.salesdriverItemWrap salesDriveWrap = ECM_UtilityTestClass.salesdrivervalues(eSCDI, salesDetails1,newcontractitem);            
            ECM_CreateContractController.loadInvestmentsValues(objContract,new List<ECM_Contract_Item__c>{newcontractitem},false,false);
            ECM_CreateContractController.salesdriveritems lstsalesdriver = ECM_UtilityTestClass.getSalesdriveritems(salesDriver,eSCDI);
            String str =JSON.serialize(lstsalesdriver);
            //List<ECM_CreateContractController.salesdriverItemWrap> lstSalesWrap = ECM_CreateContractController.saveSalesDrivers('',str,new List<ECM_Contract_Item__c>{newcontractitem});
            ECM_CreateContractController.SalesdriversAU('['+str+']',objContract.Id);
            // ECM_CreateContractController.checkTieringInvestment(objContract);
            //ECM_Tiering__c tier = ECM_CreateContractController.createTieringRecord(newcontractitem1.Id, 10, 10, 20, 20, 30, 30);
            // ECM_CreateContractController.getTieringObj();
            List<ECM_CreateContractController.salesdriverItemWrap> sditm = new List<ECM_CreateContractController.salesdriverItemWrap>();            
            sditm.add(salesDriveWrap);
            // ECM_CreateContractController.processSalesDriversToInsert(JSON.serialize(sditm),objContract); 
            ECM_CreateContractController.removeSalesDriver(eSCDI.id);  
            // ECM_CreateContractController.delTieringObjrec(tieringObj.Id);
			ECM_CreateContractController.getASTableConfiguration(contractType.Id);
            ECM_CreateContractController.getASSubGroup();
            ECM_CreateContractController.salesdriverDescription(eSCDI);
            Test.stopTest();
        }   
    } 
	
	 @isTest 
    public static void createOutletContractTest2(){
        List<Account> acclist = new List<Account>();
        Profile prof = [select id from profile where name=: 'Sales Representative'];
        User usrmngr = new User();
        usrmngr.firstName = 'testManager';
        usrmngr.lastName = 't2';
        usrmngr.profileId = prof.id;        
        usrmngr.email = 'test.MamagerSfdc4@test.com';
        usrmngr.Username ='test.MamagerSfdc4@test.com';
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
        usr.email = 'test.MamagerSfdc2@test.com';
        usr.Username ='test.MamagerSfdc2@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='ES';
        usr.ManagerId = usrmngr.Id;
        insert usr;
        System.assert(usr.id!=null,'User Id should not be null');
        
        system.debug(LoggingLevel.Debug,'(USer==>  '+usr);
        user newuser = EDGE_UtilityTestClass.runAsUser('Testabc','System Administrator');
        insert newuser;
        Map<string,string> fieldsformappingrecords;
        fieldsformappingrecords= new  Map<string,string>{'Draught Discounts' => 'ECM_Draught_Spirits_Discount_Level__c',
            'Pouring Discounts' => 'ECM_Spirits_Pouring_Discount_Level__c',
            'Premium Discounts' => 'ECM_Spirits_Premium_Discount_Level__c',
            'Reserve Discounts' => 'ECM_Spirits_Reserve_Discount_Level__c',
            'RTD Discount' => 'ECM_RTD_Discount_Level__c',
            'Spirits Discounts' => 'ECM_Spirits_Discount_Level__c'};
                Map<String,contract> mapstringrecordvalue = new Map<string,contract>();
        List<ECM_Contract_Item__c> contractItemslist = new List<ECM_Contract_Item__c>();
        List<ECM_Contract_Item__c> contractItemslist1 = new List<ECM_Contract_Item__c>();
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        
        
        
        //Id geographyId1 = EDGE_UtilityTestClass.setupCountry('AU'); 
        Territory__c testterritory=New Territory__c();
        testterritory.Name='Testterriotory';
        testterritory.Territory_Type__c='Sales';
        testterritory.Country__c= geographyId;
        testterritory.Status__c='Active';
        testterritory.Primary_Sales_Rep__c = usr.id;
        insert testterritory;
        
        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        contractType.ECM_of_Outlets_Tap_Space_Required__c = 0.8;
        insert contractType;
        
        Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(geographyId);
        mktSetting.ECM_Contract_Header_Details__c='ECM_Contract_Owner__c;ECM_Territory__r.Name;Account.ECM_Legal_Name__c;Account.Name;ECM_Agreement_Type__r.Name;StartDate;Contract_End_Date__c;ContractNumber;Name';
        mktSetting.ECM_Investment_Summary_KPIS__c='ECM_Total_Volume_Target_Spirits__c;ECM_Total_Volume_Target_Beers__c;ECM_Incremental_Volume_Spirits__c;ECM_Incremental_Volume_Beers__c;ECM_Total_trade_investment_Beers__c;ECM_Total_A_P_Investment_Spirits__c;ECM_Incremental_GP__c;ECM_Incremental_GP_Beers__c';
        mktSetting.ECM_Category_Split_KPIS__c='ECM_NSV_reserve_share__c;ECM_NSV_premium_core_share__c;ECM_GP_reserve_share__c;ECM_GP_innovation_share__c;ECM_GM_reserve_share__c;ECM_GM_innovation_share__c;ECM_GM_premium_core_share__c;ECM_TV_reserve_share__c;ECM_TV_premium_core_share__c;ECM_IV_reserve_share__c;ECM_IV_innovation_share__c;ECM_IV_premium_core_share__c';
        mktSetting.ECM_Product_Investment_Details__c='ECM_Retro_investment__c;ECM_Trade_Investments__c;ECM_AnP_investment__c;ECM_Gross_margin__c;ECM_Total_GP_EU__c;ECM_Generated_NSV_EU__c;ECM_NSV_After_Investment__c;ECM_Incremental_GP_after_Investment__c;Tiers;ECM_UoM__c;ECM_Baseline_volume__c;ECM_Volume__c;ECM_Incremental_Volume__c;ECM_CAAP_Total__c;ECM_Product_growth_driver__c';
        mktSetting.ECM_Sales_Drivers_Details__c='ECM_Investement_Description__c;ECM_Budget_Type__c;ECM_Payment_Frequency__r.ECM_Type__c;Payment dates;ECM_Total_Investment_Amount__c;ECM_Prepayment__c;ECM_Sales_Driver_Name__c';
        mktSetting.ECM_Attribute_Visibility_Screen1__c='Direct_Customer__c;Outlet_Visit_Prioritisation_Grade__c;Global_Segment__c';
        mktSetting.ECM_Contract_Creation_Page__c='Global';
        //mktSetting.ECM_Mandatory_field_for_Contract__c='SAP Ship To;';
        mktSetting.ECM_Contract_Management_Market__c=true;
        mktSetting.ECM_SAP_Order_Type__c='YPCR';
        mktSetting.ECM_Payment_Management_Email__c='test@test2.com';
        mktSetting.ECM_Email_to_Send_Payment_CSV__c='test@test3.com';
        insert mktSetting;
        String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        String bRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        
        Pick_Up_Options__c banner= new Pick_Up_Options__c();
        banner.Name='Range[ES]';
        banner.Geography__c=geographyId;
        banner.RecordTypeId=bannerRecordTypeId;
        insert banner;
        Pick_Up_Options__c bannerAU= new Pick_Up_Options__c();
        bannerAU.Name='IBA[AU]';
        bannerAU.Geography__c=geographyId;
        bannerAU.RecordTypeId=bannerRecordTypeId;
        insert bannerAU;
        Pick_Up_Options__c budjectEU= new Pick_Up_Options__c();
        budjectEU.Name='TI [ES]';
        budjectEU.Geography__c=geographyId;
        budjectEU.RecordTypeId=bRecordTypeId;
        insert budjectEU;
        
        String pickupRecordTypeId;
        pickupRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId(); 
        Pick_Up_Options__c banner1= new Pick_Up_Options__c();
        banner1.Name='Range[ES]';
        banner1.Geography__c=geographyId;
        banner1.RecordTypeId=pickupRecordTypeId;
        banner1.Type__c ='Local-Segment1';
        //insert banner1;
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Person_Responsible__c= usr.Id;
        outletAccount.OwnerId = usr.Id;
        outletAccount.SAP_Sold_to__c='3984021';
        outletAccount.VAT_Number__c='TAXID123';
        outletAccount.ECM_Legal_Name__c='Legal';
        outletAccount.Email_for_contracts_payments__c='manikandan.t@diageo.com.test';
        outletAccount.Country__c = geographyId;
        outletAccount.IsOperator__c=true;
        outletAccount.Name ='Test445';
        insert outletAccount;
        
        //String distRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Distributor/Wholesaler').getRecordTypeId(); 
        
        Account distr = EDGE_UtilityTestClass.getDistriAccRec();
        distr.Name = 'Test66_Distr';
        //distr.RecordTypeId = distRecordTypeId;
        distr.Country__c = geographyId;
		distr.Status__c= 'Active';        
        insert distr;
        
        Supplier_Outlet__c suppl = EDGE_UtilityTestClass.suppOutletRec(outletAccount.Id,distr.Id);
        insert suppl;
        
        String accRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId(); 
        
        Account outlet = new Account();
        outlet.Name = 'Test66_Outlet';
        outlet.RecordTypeId = accRecordTypeId;
        outlet.BillingStreet = '17 Asian Highway 45';
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
        outlet.Email_for_contracts_payments__c='manikandan.t@diageo.com.test';
        outlet.Name ='Test679';
        insert outlet;  
        Account outletAccount1 = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount1.Person_Responsible__c= usr.Id;
        outletAccount1.OwnerId = usr.Id;
        outletAccount1.Hybrid__c=true;
        outlet.IsOperator__c=true;
        //outletAccount1.Operator__c=outlet.id;
        outletAccount.SAP_Sold_to__c='398402';
        outletAccount.ECM_Legal_Name__c='Legal';
        outletAccount.Email_for_contracts_payments__c='manikandan.t@diageo.com.test';
        outletAccount.VAT_Number__c='TAXID13';
        outletAccount.Name ='Test111';
        insert outletAccount1;
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        insert territory;
        Territory_Hierarchy__c hirarchy= ECM_UtilityTestClass.createhirarchy(geographyId);
        hirarchy.recordtypeId=Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Region').getRecordTypeId();
        insert hirarchy;
        territory.Primary_Sales_Rep__c = usr.id;
        territory.Country__c= geographyId;
        territory.Region__c=hirarchy.Id;
        update territory;
        ECM_Payment_Frequency__c paymfreq = new ECM_Payment_Frequency__c();
        paymfreq.ECM_Type__c='Monthly';
        paymfreq.ECM_Other_Investment__c=true;
        paymfreq.ECM_Volume_target__c=true;
        paymfreq.ECM_Number_of_months_for_recurrence__c='20';
        paymfreq.ECM_From_When_Starts__c='Calendar Year';
        paymfreq.ECM_Geography__c=geographyId;
        Insert paymfreq;
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        String contractGroupRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Group').getRecordTypeId();
        Contract objContract = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract.Status = 'Draft';
        objContract.Contract_End_Date__c = System.today()+29;
        objContract.AccountId=outletAccount.Id;
        objContract.ECM_Territory__c=testterritory.Id;
        //objContract.ECM_Contract_Type__c=contractType.Id;
        objContract.ECM_Agreement_Type__c=contractType.Id;
        objContract.recordTypeId=contractRecordTypeId;
        objContract.ECM_Channel__c='On-Premise';
        objContract.ECM_Banner__c=banner.Id;
        objContract.StartDate = system.today();
        objContract.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContract.Contract_End_Date__c = system.today()+360;
        objContract.OwnerId = usr.id;
        insert objContract;
        
        Contract objContract2 = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract2.Status = 'Draft';
        objContract2.Contract_End_Date__c = System.today()+29;
        objContract2.AccountId=outletAccount.Id;
        objContract2.ECM_Territory__c=testterritory.Id;
        objContract2.recordTypeId=contractRecordTypeId;
        objContract2.ECM_Channel__c='On-Premise';
        objContract2.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContract2.StartDate = system.today()+150;
        objContract2.Contract_End_Date__c = system.today()+360;
        objContract2.ECM_Agreement_Type__c = contractType.Id;
        objContract2.ECM_Amended__c = true;//ECM-6264
        objContract2.ECM_Parent_Contract__c = objContract.Id;
        insert objContract2;
        system.debug(LoggingLevel.Debug,'CreatedById---'+objContract2.CreatedById);
        Contract objContract3 = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract3.Status = 'Draft';
        objContract3.Contract_End_Date__c = System.today()+29;
        objContract3.AccountId=outletAccount.Id;
        objContract3.ECM_Territory__c=testterritory.Id;
        //objContract3.ECM_Contract_Type__c=contractType.Id;
        objContract3.recordTypeId=contractRecordTypeId;
        objContract3.ECM_Channel__c='On-Premise';
        objContract3.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContract3.StartDate = system.today();
        objContract3.Contract_End_Date__c = system.today()+150;
        insert objContract3;
        
        Contract objContract4 = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract4.Status = 'Draft';
        objContract4.Contract_End_Date__c = System.today()+29;
        objContract4.AccountId=outletAccount.Id;
        objContract4.ECM_Territory__c=testterritory.Id;
        //objContract4.ECM_Contract_Type__c=contractType.Id;
        objContract4.recordTypeId=contractRecordTypeId;
        objContract4.ECM_Channel__c='On-Premise';
        objContract4.StartDate = system.today()+150;
        objContract4.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContract4.Contract_End_Date__c = system.today()+180;
        insert objContract4;
        
        Contract objContract5 = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract5.Status = 'Draft';
        objContract5.Contract_End_Date__c = System.today()+29;
        objContract5.AccountId=outletAccount.Id;
        objContract5.ECM_Territory__c=testterritory.Id;
        //objContract5.ECM_Contract_Type__c=contractType.Id;
        objContract5.recordTypeId=contractRecordTypeId;
        objContract5.ECM_Channel__c='On-Premise';
        objContract5.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContract5.StartDate = system.today()+90;
        objContract5.Contract_End_Date__c = system.today()+500;
        insert objContract5;
        
        Contract objContract6 = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract6.Status = 'Draft';
        objContract6.Contract_End_Date__c = System.today()+29;
        objContract6.AccountId=outletAccount.Id;
        objContract6.ECM_Territory__c=testterritory.Id;
        //objContract6.ECM_Contract_Type__c=contractType.Id;
        objContract6.recordTypeId=contractRecordTypeId;
        objContract6.ECM_Channel__c='On-Premise';
        objContract6.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContract6.StartDate = system.today()+90;
        objContract6.Contract_End_Date__c = system.today()+900;
        insert objContract6;
        
        Contract objContract7 = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract7.Status = 'Draft';
        objContract7.Contract_End_Date__c = System.today()+29;
        objContract7.AccountId=outletAccount.Id;
        objContract7.ECM_Territory__c=testterritory.Id;
        //objContract7.ECM_Contract_Type__c=contractType.Id;
        objContract7.ECM_Agreement_Type__c=contractType.Id;
        objContract7.recordTypeId=contractRecordTypeId;
        objContract7.ECM_Channel__c='On-Premise';
        objContract7.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContract7.ECM_Banner__c=banner.Id;
        objContract7.StartDate = system.today();
        objContract7.Contract_End_Date__c = system.today()+360;
        objContract7.ECM_Overall_Investment_Amount__c=30.00;
        insert objContract7;
        Contract objContract9 = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract9.Status = 'Draft';
        objContract9.Contract_End_Date__c = System.today()-29;
        objContract9.AccountId=outletAccount.Id;
        objContract9.ECM_Territory__c=testterritory.Id;
        //objContract7.ECM_Contract_Type__c=contractType.Id;
        objContract9.ECM_Agreement_Type__c=contractType.Id;
        objContract9.recordTypeId=contractRecordTypeId;
        objContract9.ECM_Channel__c='On-Premise';
        objContract9.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContract9.ECM_Banner__c=banner.Id;
        objContract9.StartDate = system.today()-50;
        //objContract9.Contract_End_Date__c = system.today()+360;
        objContract9.ECM_Overall_Investment_Amount__c=30.00;
        objContract9.ECM_CTD_Overall_Investment__c = 20.00;
        objContract9.ECM_CTD_Total_A_P_Investment__c = 15.00;
        objContract9.ECM_CTD_Total_GP__c = 25.00;
        objContract9.ECM_Total_Indirect_Investment__c = 40.00;
        //objContract9.ECM_CTD_CAAP_ROI__c = 50.00;
        objContract9.ECM_CTD_Total_NSV__c = 22.00;
        //objContract9.ECM_CTD_Overall_Invst_incl_Indirect_Inv__c = 47.00;
        insert objContract9;
        objContract9.Status = 'Closed';
        update objContract9;
        Contract objContract8 = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract8.Status = 'Draft';
        objContract8.Contract_End_Date__c = System.today()+29;
        objContract8.AccountId=outletAccount.Id;
        objContract8.ECM_Territory__c=testterritory.Id;
        //objContract8.ECM_Contract_Type__c=contractType.Id;
        objContract8.ECM_Agreement_Type__c=contractType.Id;
        objContract8.recordTypeId=contractRecordTypeId;  
        objContract8.ECM_Channel__c='On-Premise';
        objContract8.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContract8.ECM_Banner__c=banner.Id;
        objContract8.StartDate = system.today();
        objContract8.Contract_End_Date__c = system.today()+360;
        insert objContract8;
        objContract8.UOS_AP_Rate__c= 55;
        objContract8.UOS_Rebate_Rate__c=88;
        objContract8.Status='Active';
        update objContract8;
        
        //Spain Data
        Id geographyId1 = EDGE_UtilityTestClass.setupCountrySpain('ES'); 
        ECM_Contract_Type__c contractTypeEU = ECM_UtilityTestClass.createContractType(geographyId);
        insert contractTypeEU;
        Contract objContractEU = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContractEU.Status = 'Draft';
        objContractEU.Contract_End_Date__c = System.today()+29;
        objContractEU.AccountId=outletAccount.Id;
        objContractEU.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContractEU.ECM_Territory__c=testterritory.Id;
        //objContractEU.ECM_Contract_Type__c=contractTypeEU.Id;
        objContractEU.ECM_Agreement_Type__c=contractTypeEU.Id;
        objContractEU.recordTypeId=contractRecordTypeId;
        objContractEU.ECM_Channel__c='On-Premise';
        objContractEU.ECM_Banner__c=banner.Id;
        objContractEU.StartDate = system.today();
        objContractEU.Contract_End_Date__c = system.today()+360;
        insert objContractEU;
        
        Contract objContractEU16 = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContractEU16.Status='Draft';
        objContractEU16.ECM_Agreement_Type__c=contractTypeEU.Id;
        objContractEU16.recordTypeId=contractRecordTypeId;
        insert objContractEU16;
        
        Contract objContractEU1 = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContractEU1.Status = 'Draft';
        objContractEU1.Contract_End_Date__c = System.today()+29;
        objContractEU1.AccountId=outletAccount.Id;
        objContractEU1.ECM_Territory__c=testterritory.Id;
        //objContractEU1.ECM_Contract_Type__c=contractTypeEU.Id;
        objContractEU1.recordTypeId=contractRecordTypeId;
        objContractEU1.ECM_Channel__c='On-Premise';
        objContractEU1.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContractEU1.StartDate = system.today()+150;
        objContractEU1.Contract_End_Date__c = system.today()+360;
        objContractEU1.ECM_Agreement_Type__c=contractTypeEU.Id;
        insert objContractEU1;
        objContractEU1.Status = 'Active';
        update objContractEU1;
        mapstringrecordvalue.put(objContract.ECM_Channel__c,objContract);
        Business_Role__c businessRole =new Business_Role__c();
        businessRole.Name='Spain Mainland';
        businessRole.Country__c=geographyId;
        businessRole.Call_Type__c='Telephone';
        insert businessRole;
        
        User_Business_Role__c userBusinessRole =new User_Business_Role__c();        
        userBusinessRole.Business_Role__c=businessRole.Id;
        userBusinessRole.User__c=usr.Id;
        insert userBusinessRole;
        User_Business_Role__c ubr = new User_Business_Role__c();
        ubr.Business_Role__c= businessRole.Id ;
        ubr.User__c=userinfo.getUserId();
        insert ubr;
        
        ECM_Role_Agreement__c  roleAgreement =new ECM_Role_Agreement__c();        
        //roleAgreement.Business_Role__c=userBusinessRole.Business_Role__c;
        roleAgreement.Business_Role__c=businessRole.Id;
        roleAgreement.Agreement_Type__c=contractType.Id;
        insert roleAgreement;
        
        Product__c product = new Product__c();
        product.Name='Test';
        product.Product_Full_Name__c='Test';
        product.Country__c=geographyId;
        insert product;
        Product_UOM__c prdtUOM = new Product_UOM__c();
        prdtUOM.Product__c = product.Id;
        prdtUOM.Conversion_Factor__c = 2;
        prdtUOM.Type__c='BTL';
        prdtUOM.Unique_ID__c= product.id +'BTL';
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
        contractItemslist.add(newcontractitem);
        ECM_Contract_Item__c newcontractitem1= new ECM_Contract_Item__c();
        newcontractitem1.ECM_Contract__c=objContract7.Id;
        newcontractitem1.ECM_Product__c=marketassort.id;
        insert newcontractitem1;
        contractItemslist1.add(newcontractitem1);
        ECM_Contract_Item__c newcontractitem2= new ECM_Contract_Item__c();
        newcontractitem2.ECM_Contract__c=objContract8.Id;
        newcontractitem2.ECM_Product__c=marketassort.id;
        insert newcontractitem2;
        //Sales driver Records
        Territory_Budget__c terriBudget = ECM_UtilityTestClass.createTerritoryBudget(territory.Id, hirarchy.Id);
        insert terriBudget;
        Territory_Budget__c terriBudget1 = ECM_UtilityTestClass.createTerritoryBudget(territory.Id, hirarchy.Id);
        terriBudget1.ECM_Budget_Type__c=budjectEU.Id;
        insert terriBudget1;
        ECM_Sales_Driver__c salesDriver = ECM_UtilityTestClass.getSalesdriver(terriBudget1.Id,geographyId);
        salesDriver.ECM_Budget_Type__c=budjectEU.Id;
        insert salesDriver;
        ECM_Sales_Driver_Item__c eSCDI = new ECM_Sales_Driver_Item__c(Contract__c=objContract7.Id,ECM_Sales_Driver__c=salesDriver.Id);
        insert eSCDI;
        ECM_Sales_Driver_Item_Detail__c salesDetails1 = ECM_UtilityTestClass.insertSalesdriverDetails(eSCDI, newcontractitem1);
        insert salesDetails1;
        
        
        List<ECM_Sales_Driver_Item__c> eSDList = new List<ECM_Sales_Driver_Item__c>();
        eSDList.add(eSCDI);
        
        Depletions__c dep = new Depletions__c();
        dep.ECM_Volume__c = 100.00;
        dep.ECM_Outlet__c = outletAccount.id;
        dep.ECM_Start_Period__c = system.today()+360;
        dep.ECM_End_Period__c = system.today()+29;
        dep.ECM_Product__c = product.id;
        dep.ECM_Outlet__c = outletAccount.Id;
        insert dep;
        acclist.add(outletAccount1);
        //system.assertEquals(userBusinessRole.User__c, usr.Id);
        ECM_CreateContractController.getContractTypes();
        ECM_CreateContractController.getContractTypesOutlet(outletAccount.Id);
        
        Outlet_Contract__c otletcontract=New Outlet_Contract__c();
        otletcontract.Contract__c=objContract.Id;
        otletcontract.Outlet__c=outletAccount.Id;
        otletcontract.Activation_Date__c=system.today();
        insert otletcontract;
        otletcontract.ECM_Total_Outlet_Taps__c= 100;
        otletcontract.ECM_No_of_Taps_Diageo_will_Invest__c=75;
        otletcontract.ECM_of_Taps_Diageo_will_invest__c= .75;
        List<Outlet_Contract__c> otletContractList = new List<Outlet_Contract__c>();
        
        Account ownerAccount=EDGE_UtilityTestClass.getOwnerOperatorAccount();
        ownerAccount.Person_Responsible__c= usr.Id;
        ownerAccount.OwnerId = usr.Id;
        ownerAccount.SAP_Sold_to__c='39840210';
        ownerAccount.VAT_Number__c='TAXID1230';
        ownerAccount.ECM_Legal_Name__c='Legal';
        ownerAccount.Email_for_contracts_payments__c='manikandan.t@diageo.com.test';
        ownerAccount.Country__c = geographyId1;
        ownerAccount.IsOperator__c=true;
        insert ownerAccount;
        
        system.runAs(usr){            
            test.starttest();
            ECM_CreateContractController.getAccountById(outletAccount.Id);
            // ECM_CreateContractController.getUserCountry();
            
            ECM_CreateContractController.getPickUpOptionsPicklistvalues();
            ECM_CreateContractController.getListOfAccounts();
            ECM_CreateContractController.setdefaultvalues_Discount(objContract);
            ECM_CreateContractController.getChannelPicklistvalues();
            ECM_CreateContractController.getPicklistvalues('Contract','ECM_Channel__c');
            ECM_CreateContractController.statesAndProvinces();
            ECM_CreateContractController.getAccountRecords(1,outletAccount.Operator__c);
            ECM_CreateContractController.loadAccountRecords(3,1,outletAccount1.Operator__c);
            ECM_CreateContractController.validation_for_Agreement_Type(objContractEU,outletAccount.id,contractRecordTypeId);
            ECM_CreateContractController.updateContractItems(contractItemslist);
            ECM_CreateContractController.deleteOldContractItems(contractItemslist);
            ECM_CreateContractController.paymentFrequencyvalues(objContract.ECM_Agreement_Type__c);
            ECM_CreateContractController.paymentSchedulevalues(objContract.ECM_Agreement_Type__c);
            ECM_CreateContractController.salesdrivers(objContract.ECM_Agreement_Type__c);
            ECM_CreateContractController.saveVolumeTargets(JSON.serialize(contractItemslist1),contractType,objContract,null);
            try
            {                
                ECM_CreateContractController.submitForApproval(JSON.serialize(objContract2) ,JSON.serialize(contractItemslist1),JSON.serialize(otletContractList));
            }
            catch(exception e)
            {
                System.debug(LoggingLevel.debug,'Error ');
            }  
            //ECM_CreateContractController.submitForApproval(JSON.serialize(objContract2) ,JSON.serialize(contractItemslist1));
            ECM_CreateContractController.get_contractitem_with_exsisiting_baseVol(contractItemslist1);
            ECM_CreateContractController.savecontract(objContract7);
            ECM_CreateContractController.get_default_Banner_AU();
            ECM_CreateContractController.salesdrivervaluesAU(objContract7.Id);
            ECM_CreateContractController.processSalesDriversToInsert('',objContract7);
            //ECM_CreateContractController.sendEmailToUser(usr,objContract7,null);
            ECM_CreateContractController.getUser(newuser.id);
            ECM_CreateContractController.loadvalues(objContract7.id);
            ECM_CreateContractController.displayPrevCon(objContract9);
            ECM_CreateContractController.loadInvestmentsValues(objContract7,contractItemslist1,false,false);
            ECM_CreateContractController.getEandSContract();
            ECM_CreateContractController.getOutletTapsTable(objContract);
            //Sales driver Testing 
            ECM_CreateContractController.salesdriverItemWrap salesDriveWrap = ECM_UtilityTestClass.salesdrivervalues(eSCDI, salesDetails1,newcontractitem);
            ECM_CreateContractController.loadInvestmentsValues(objContract,new List<ECM_Contract_Item__c>{newcontractitem},false,true);
            ECM_CreateContractController.salesdriveritems lstsalesdriver = ECM_UtilityTestClass.getSalesdriveritems(salesDriver,eSCDI);
            String str =JSON.serialize(lstsalesdriver);
            //List<ECM_CreateContractController.salesdriverItemWrap> lstSalesWrap = ECM_CreateContractController.saveSalesDrivers('',str,new List<ECM_Contract_Item__c>{newcontractitem});
            ECM_CreateContractController.SalesdriversAU('['+str+']',objContract.Id);
           // ECM_CreateContractController.checkTieringInvestment(objContract);
            ECM_Tiering__c tier = ECM_CreateContractController.createTieringRecord(newcontractitem1.Id, 10, 10, 20, 20, 30, 30);
            ECM_CreateContractController.delTieringObjrec(tier.Id);
            // ECM_CreateContractController.getTieringObj();
            List<ECM_CreateContractController.salesdriverItemWrap> sditm = new List<ECM_CreateContractController.salesdriverItemWrap>();            
            sditm.add(salesDriveWrap);
            //ECM_CreateContractController.processSalesDriversToInsert(JSON.serialize(sditm),objContract); 
            ECM_CreateContractController.removeSalesDriver(eSCDI.id);
            ECM_CreateContractController.getMarketSettings(outletAccount.Id);
            ECM_CreateContractController.createContract(objContract7, ownerAccount.Id, contractGroupRecordTypeId,testterritory.id , contractType.Id,acclist);
            ECM_CreateContractController.getSupplierOutlets(outletAccount.Id);
            test.stoptest();
        }   
    } 
    @isTest
    public static void testGetContract(){
        Id contId;
        Pick_Up_Options__c pickupOption;
        //Account outlet;
        contId = EDGE_UtilityTestClass.setupCountry('ES');
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        pickupOption = EDGE_UtilityTestClass.getPickUpOption(contId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[ES]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        //pickupOption.Geography__r.Name='Australia';
        //pickupOption.Type__c ='Local-Segment1';
        insert pickupOption;
        
        
        List<Geography__c> geoList = [SELECT Id,Name,Parent_Geography__c,
                                      Parent_Geography__r.Parent_Geography__c,
                                      Parent_Geography__r.Parent_Geography__r.Parent_Geography__c,
                                      Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Parent_Geography__c,
                                      Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Parent_Geography__c
                                      FROM Geography__c 
                                      WHERE Parent_Geography__r.Parent_Geography__c =: contId];
        Id recTypeIdOutlet = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Outlet').getRecordTypeId(); 
		Account outletAcc = new Account();
        outletAcc.Name = 'Test_Outlet_Spain';
        outletAcc.RecordTypeId = recTypeIdOutlet; 
        outletAcc.BillingStreet = 'Calle Escritor Benito Pérez Galdós 43';
        outletAcc.BillingCity = 'Las Palmas de Gran Canaria';
        outletAcc.BillingState = 'ALAVA';
        outletAcc.BillingPostalCode = '35002';
        outletAcc.BillingCountry = 'Spain';
        outletAcc.BillingCountryCode = 'ES';
        outletAcc.Region__c = geoList[0].Id;
        outletAcc.Area__c = geoList[0].Parent_Geography__c;
        outletAcc.Country__c = geoList[0].Parent_Geography__r.Parent_Geography__c;
        outletAcc.Cluster__c= geoList[0].Parent_Geography__r.Parent_Geography__r.Parent_Geography__c;
        outletAcc.Hub__c = geoList[0].Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Parent_Geography__c;
        outletAcc.Market__c = geoList[0].Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Parent_Geography__c;
        outletAcc.Outlet_Email_Address__c = 'test@test.com';
        outletAcc.Global_Channel__c = 'Off Trade';
        outletAcc.Global_Sub_Channel__c = 'Retailer';
        outletAcc.Global_Segment__c = 'Hypermarket';
        outletAcc.Global_Sub_Segment__c = 'Modern Hypermarket';
        outletAcc.Status__c= 'Active';
        outletAcc.Independent_of_Operator__c = true;
        outletAcc.Independent_of_Owner__c = true;
        outletAcc.Outlet_Visit_Prioritisation_Grade__c = pickupOption.id;
        insert outletAcc;
        
        Id pkupRecTypeId = Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Product Strategy').getRecordTypeId();
        Pick_Up_Options__c pOption = new Pick_Up_Options__c();
        pOption.Name = 'Premium Core[ES]';
        pOption.Geography__c = contId;
        pOption.ECM_Strategy_group__c = 'Premium Core';
        pOption.RecordTypeId = pkupRecTypeId;
        pOption.Status__c = 'Active';
        insert pOption;
        
        String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        Pick_Up_Options__c banner = new Pick_Up_Options__c();
        banner.Name = 'Range[ES]';
        banner.Geography__c = contId;
        banner.RecordTypeId = bannerRecordTypeId;
        insert banner;
        
        Product__c product = new Product__c();
        product.Name='Test';
        product.Product_Full_Name__c='Test';
        product.Country__c = contId;
        insert product;
        
        Market_Assortment_Product__c mapObj = new Market_Assortment_Product__c();
        mapObj.Product__c = product.Id;
        mapObj.Market_Assortment__c = contId;
        mapObj.ECM_Pickup_Option__c = pOption.Id;
        insert mapObj;
        
        Id buRecTypeId = Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Business Unit').getRecordTypeId();
        Id saRecTypeId = Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Sales Area').getRecordTypeId();
        Id regRecTypeId = Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Region').getRecordTypeId();
        
        
        Territory_Hierarchy__c hierBUObj = new Territory_Hierarchy__c();
        hierBUObj.Name = 'Test Spain BU';
        hierBUObj.RecordTypeId = buRecTypeId;
        hierBUObj.Geography__c = contId;
        insert hierBUObj;
        
        Territory_Hierarchy__c hierSAObj = new Territory_Hierarchy__c();
        hierSAObj.Name = 'Test Spain BU';
        hierSAObj.RecordTypeId = saRecTypeId;
        hierSAObj.Geography__c = contId;
        hierSAObj.Parent_BU__c = hierBUObj.id;
        insert hierSAObj;
        
        Territory_Hierarchy__c hierRegionObj = new Territory_Hierarchy__c();
        hierRegionObj.Name = 'Test Spain Region';
        hierRegionObj.RecordTypeId = regRecTypeId;
        hierRegionObj.Geography__c = contId;
        hierRegionObj.Parent_BU__c = hierSAObj.id;
        insert hierRegionObj;
        
        Territory__c testTerritory = New Territory__c();
        testTerritory.Name='Testterriotory';
        testTerritory.Territory_Type__c='Sales';
        testTerritory.Country__c = contId;
        testTerritory.Status__c ='Active';
        testTerritory.Region__c = hierRegionObj.Id;
        insert testTerritory;
        System.assert(testTerritory.id!=null,'testTerritory Id should not be null');
        
        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(contId);
        contractType.ECM_of_Outlets_Tap_Space_Required__c = 0.8;
        insert contractType;
        
        ECM_Payment_Frequency__c paymFreq = new ECM_Payment_Frequency__c();	
        paymFreq.ECM_Type__c='Monthly';	
        paymFreq.ECM_Other_Investment__c=true;	
        paymFreq.ECM_Volume_target__c=true;	
        paymFreq.ECM_Number_of_months_for_recurrence__c='20';	
        paymFreq.ECM_From_When_Starts__c='Calendar Year';	
        paymFreq.ECM_Geography__c = contId;	
        Insert paymFreq;
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        
        Contract conObj =  EDGE_UtilityTestClass.getContract(outletAcc.Id, contractRecordTypeId);
        conObj.Status = 'Draft';
        conObj.Contract_End_Date__c = System.today()+29;
        conObj.AccountId = outletAcc.Id;
        conObj.ECM_Territory__c = testTerritory.Id;
        //objContract.ECM_Contract_Type__c=contractType.Id;
        conObj.ECM_Agreement_Type__c = contractType.Id;
        conObj.recordTypeId = contractRecordTypeId;
        conObj.ECM_Channel__c = 'On-Premise';
        conObj.ECM_Banner__c = banner.Id;
        conObj.StartDate = system.today();
        conObj.ECM_Payment_Frequency_type__c = paymFreq.Id;
        conObj.Contract_End_Date__c = system.today()+360;
        insert conObj;        
        
        ECM_Addendum__c addendum= new ECM_Addendum__c();
        addendum.Name='Test';
        addendum.ECM_Addendum_Type__c='Add New Product';
        addendum.ECM_Contract__c=conObj.Id;
        addendum.ECM_Status__c='Draft';
        insert addendum;        
        
        List<ECM_Contract_Item__c> conItemList = new List<ECM_Contract_Item__c>();
        ECM_Contract_Item__c conItemObj = new ECM_Contract_Item__c();
        conItemObj.ECM_Contract__c = conObj.Id;
        conItemObj.ECM_Product__c = mapObj.id;
        conItemObj.ECM_Addendum__c = addendum.Id;
        ECM_Contract_Item__c conItemObj1 = new ECM_Contract_Item__c();
        conItemObj1.ECM_Contract__c = conObj.Id;
        conItemObj1.ECM_Product__c = mapObj.id;
        conItemObj1.ECM_Addendum__c = addendum.Id;
        conItemList.add(conItemObj);
        conItemList.add(conItemObj1);
        insert conItemList;
        
        String bRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        String sDIDTypeId = ECM_Sales_Driver_Item_Detail__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Driver').getRecordTypeId();
        Pick_Up_Options__c budjectEU= new Pick_Up_Options__c();
        budjectEU.Name='TI[ES]';
        budjectEU.Geography__c=contId;
        budjectEU.RecordTypeId=bRecordTypeId;
        insert budjectEU;
        Pick_Up_Options__c budjectEU1= new Pick_Up_Options__c();
        budjectEU1.Name='A&P[ES]';
        budjectEU1.Geography__c=contId;
        budjectEU1.RecordTypeId=bRecordTypeId;
        insert budjectEU1;        
        Territory_Hierarchy__c hirarchy= ECM_UtilityTestClass.createhirarchy(contId);
        hirarchy.recordtypeId=Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Region').getRecordTypeId();
        insert hirarchy;
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        territory.Region__c = hirarchy.Id;
        insert territory;
        Territory_Budget__c terriBudget = ECM_UtilityTestClass.createTerritoryBudget(territory.Id, hirarchy.Id);
        terriBudget.ECM_Budget_Type__c=budjectEU1.Id;
        insert terriBudget;
        Territory_Budget__c terriBudget1 = ECM_UtilityTestClass.createTerritoryBudget(territory.Id, hirarchy.Id);
        terriBudget1.ECM_Budget_Type__c=budjectEU.Id;
        insert terriBudget1;
        ECM_Sales_Driver__c salesDriver = ECM_UtilityTestClass.getSalesdriver(terriBudget.Id,contId);
        salesDriver.ECM_Budget_Type__c=budjectEU1.Id;
        insert salesDriver;
        ECM_Sales_Driver__c salesDriver1 = ECM_UtilityTestClass.getSalesdriver(terriBudget1.Id,contId);
        salesDriver1.ECM_Budget_Type__c=budjectEU.Id;
        insert salesDriver1;
        ECM_Sales_Driver_Item__c eSCDI = new ECM_Sales_Driver_Item__c(Contract__c=conObj.Id,ECM_Sales_Driver__c=salesDriver.Id);
        insert eSCDI;
        ECM_Sales_Driver_Item_Detail__c salesDetails1 = ECM_UtilityTestClass.insertSalesdriverDetails(eSCDI, conItemObj);
        salesDetails1.RecordTypeId = sDIDTypeId;
        salesDetails1.ECM_Addendum__c = addendum.Id;
        insert salesDetails1;
        ECM_Sales_Driver_Item__c eSCDI1 = new ECM_Sales_Driver_Item__c(Contract__c=conObj.Id,ECM_Sales_Driver__c=salesDriver1.Id);
        insert eSCDI1;
        ECM_Sales_Driver_Item_Detail__c salesDetails2 = ECM_UtilityTestClass.insertSalesdriverDetails(eSCDI1, conItemObj1);
        salesDetails2.ECM_Addendum__c = addendum.Id;
        salesDetails2.RecordTypeId = sDIDTypeId;
        insert salesDetails2;

        
        addendum.ECM_Status__c = 'In approval';
        update addendum;
        
        Test.startTest();
        ECM_CreateContractController.getContract(conObj.Id);
        ECM_CreateContractController.getTableDetails(contractType.id);
        ECM_CreateContractController.getproductData(conObj.Id);
        String json='[{"setInvestmentAmount":"10","Id":"'+conItemObj.Id+'"},{"setInvestmentAmount":"20","Id":"'+conItemObj1.Id+'"}]';
        ECM_CreateContractController.saveInvestmentAmount(json);
        ECM_CreateContractController.cancelAddendum(addendum.Id);
        ECM_CreateContractController.changeAddendumStatus(addendum.Id, false);
        ECM_CreateContractController.changeAddendumStatus(addendum.Id, true);
        
        Test.stopTest();
    }
    @isTest
    public static void getTableDetailsTest(){
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
		ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        insert contractType;
        System.assert(contractType.id!=null,'contractType Id should not be null');
        
        Test.startTest();
        ECM_CreateContractController.getTableDetails(contractType.Id);
        Test.stopTest();
    }
    /*
	* @description : Test coverage for getDefPaymentFreq
	* @return : void
	* @param : void
	*/
    @isTest
    public static void getDefPaymentFreqTest(){
        Id contId = EDGE_UtilityTestClass.setupCountry('AU');
        ECM_Contract_Type__c agreementType = ECM_TestDataUtility.getAgreementType(contId);
        agreementType.ECM_Volume_UoM_for_RTD__c = 'Can/Bottle 24 Pack';
        agreementType.ECM_Volume_UoM_for_Draught_Cocktails__c = '10L BIB';
        insert agreementType;
        System.assert(agreementType.id!=null,'agreementType Id should not be null');
        Test.startTest();
        ECM_CreateContractController.getDefPaymentFreqAndBudgeting(agreementType.Id);
        Test.stopTest();
    }    
	@isTest
    public static void createOutletContractTest8(){
        List<Account> acclist = new List<Account>();
        Profile prof = [select id from profile where name=: 'Sales Representative'];
        User usrmngr = new User();
        usrmngr.firstName = 'testManager';
        usrmngr.lastName = 't2';
        usrmngr.profileId = prof.id;        
        usrmngr.email = 'test.MamagerSfdc4@test.com';
        usrmngr.Username ='test.MamagerSfdc4@test.com';
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
        usr.email = 'test.MamagerSfdc2@test.com';
        usr.Username ='test.MamagerSfdc2@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='ES';
        usr.ManagerId = usrmngr.Id;
        insert usr;
        System.assert(usr.id!=null,'User Id should not be null');
        
        system.debug(LoggingLevel.Debug,'(USer==>  '+usr);
        user newuser = EDGE_UtilityTestClass.runAsUser('Testabc','System Administrator');
        insert newuser;
        Map<string,string> fieldsformappingrecords;
        fieldsformappingrecords= new  Map<string,string>{'Draught Discounts' => 'ECM_Draught_Spirits_Discount_Level__c',
            'Pouring Discounts' => 'ECM_Spirits_Pouring_Discount_Level__c',
            'Premium Discounts' => 'ECM_Spirits_Premium_Discount_Level__c',
            'Reserve Discounts' => 'ECM_Spirits_Reserve_Discount_Level__c',
            'RTD Discount' => 'ECM_RTD_Discount_Level__c',
            'Spirits Discounts' => 'ECM_Spirits_Discount_Level__c'};
                Map<String,contract> mapstringrecordvalue = new Map<string,contract>();
        List<ECM_Contract_Item__c> contractItemslist = new List<ECM_Contract_Item__c>();
        List<ECM_Contract_Item__c> contractItemslist1 = new List<ECM_Contract_Item__c>();
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        
        
        
        //Id geographyId1 = EDGE_UtilityTestClass.setupCountry('AU'); 
        Territory__c testterritory=New Territory__c();
        testterritory.Name='Testterriotory';
        testterritory.Territory_Type__c='Sales';
        testterritory.Country__c= geographyId;
        testterritory.Status__c='Active';
        testterritory.Primary_Sales_Rep__c = usr.id;
        insert testterritory;
        
        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        insert contractType;
        
        Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(geographyId);
        mktSetting.ECM_Contract_Header_Details__c='ECM_Contract_Owner__c;ECM_Territory__r.Name;Account.ECM_Legal_Name__c;Account.Name;ECM_Agreement_Type__r.Name;StartDate;Contract_End_Date__c;ContractNumber;Name';
        mktSetting.ECM_Investment_Summary_KPIS__c='ECM_Total_Volume_Target_Spirits__c;ECM_Total_Volume_Target_Beers__c;ECM_Incremental_Volume_Spirits__c;ECM_Incremental_Volume_Beers__c;ECM_Total_trade_investment_Beers__c;ECM_Total_A_P_Investment_Spirits__c;ECM_Incremental_GP__c;ECM_Incremental_GP_Beers__c';
        mktSetting.ECM_Category_Split_KPIS__c='ECM_NSV_reserve_share__c;ECM_NSV_premium_core_share__c;ECM_GP_reserve_share__c;ECM_GP_innovation_share__c;ECM_GM_reserve_share__c;ECM_GM_innovation_share__c;ECM_GM_premium_core_share__c;ECM_TV_reserve_share__c;ECM_TV_premium_core_share__c;ECM_IV_reserve_share__c;ECM_IV_innovation_share__c;ECM_IV_premium_core_share__c';
        mktSetting.ECM_Product_Investment_Details__c='ECM_Retro_investment__c;ECM_Trade_Investments__c;ECM_AnP_investment__c;ECM_Gross_margin__c;ECM_Total_GP_EU__c;ECM_Generated_NSV_EU__c;ECM_NSV_After_Investment__c;ECM_Incremental_GP_after_Investment__c;Tiers;ECM_UoM__c;ECM_Baseline_volume__c;ECM_Volume__c;ECM_Incremental_Volume__c;ECM_CAAP_Total__c;ECM_Product_growth_driver__c';
        mktSetting.ECM_Sales_Drivers_Details__c='ECM_Investement_Description__c;ECM_Budget_Type__c;ECM_Payment_Frequency__r.ECM_Type__c;Payment dates;ECM_Total_Investment_Amount__c;ECM_Prepayment__c;ECM_Sales_Driver_Name__c';
        mktSetting.ECM_Attribute_Visibility_Screen1__c='Direct_Customer__c;Outlet_Visit_Prioritisation_Grade__c;Global_Segment__c';
        mktSetting.ECM_Contract_Creation_Page__c='Australia';
        //mktSetting.ECM_Mandatory_field_for_Contract__c='SAP Ship To;';
        mktSetting.ECM_Contract_Management_Market__c=true;
        mktSetting.ECM_SAP_Order_Type__c='YPCR';
        mktSetting.ECM_Payment_Management_Email__c='test@test2.com';
        mktSetting.ECM_Email_to_Send_Payment_CSV__c='test@test3.com';
        insert mktSetting;
        String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        String bRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        
        Pick_Up_Options__c banner= new Pick_Up_Options__c();
        banner.Name='Range[ES]';
        banner.Geography__c=geographyId;
        banner.RecordTypeId=bannerRecordTypeId;
        insert banner;
        Pick_Up_Options__c bannerAU= new Pick_Up_Options__c();
        bannerAU.Name='IBA[AU]';
        bannerAU.Geography__c=geographyId;
        bannerAU.RecordTypeId=bannerRecordTypeId;
        insert bannerAU;
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
        Id subGrprecId = Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Activation Spend Sub-Group').getRecordTypeId();
        Pick_Up_Options__c actSPsub1= new Pick_Up_Options__c();
        actSPsub1.Name='Brand Marketing A&P[ES]';
        actSPsub1.Geography__c=geographyId;
        actSPsub1.RecordTypeId=subGrprecId;
        insert actSPsub1;
        
        Pick_Up_Options__c actSPsub2= new Pick_Up_Options__c();
        actSPsub2.Name='Customer Marketing A&P[ES]';
        actSPsub2.Geography__c=geographyId;
        actSPsub2.RecordTypeId=subGrprecId;
        insert actSPsub2;
        
        String pickupRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId();
        //String pickupRecordTypeId1 = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Activation Spend Sub-Group').getRecordTypeId();
        Pick_Up_Options__c banner1= new Pick_Up_Options__c();
        banner1.Name='Range[ES]';
        banner1.Geography__c=geographyId;
        banner1.RecordTypeId=pickupRecordTypeId;
        banner1.Type__c ='Local-Segment1';
        //insert banner1;
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Person_Responsible__c= usr.Id;
        outletAccount.OwnerId = usr.Id;
        outletAccount.SAP_Sold_to__c='3984021';
        outletAccount.VAT_Number__c='TAXID123';
        outletAccount.ECM_Legal_Name__c='Legal';
        outletAccount.Email_for_contracts_payments__c='manikandan.t@diageo.com.test';
        outletAccount.Country__c = geographyId;
        outletAccount.IsOperator__c=true;
        outletAccount.Name ='Test445';
        insert outletAccount;
        
        String accRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId(); 
        
        Account outlet = new Account();
        outlet.Name = 'Test66_Outlet';
        outlet.RecordTypeId = accRecordTypeId;

        outletAccount.Country__c = geographyId;

        outlet.BillingStreet = '17 Asian Highway 45';
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
        outlet.Email_for_contracts_payments__c='manikandan.t@diageo.com.test';
        outlet.Name ='Test679';
        insert outlet;  
        Account outletAccount1 = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount1.Person_Responsible__c= usr.Id;
        outletAccount1.OwnerId = usr.Id;
        outletAccount1.Hybrid__c=true;
        outlet.IsOperator__c=true;
        //outletAccount1.Operator__c=outlet.id;
        outletAccount.SAP_Sold_to__c='398402';
        outletAccount.ECM_Legal_Name__c='Legal';
        outletAccount.Email_for_contracts_payments__c='manikandan.t@diageo.com.test';
        outletAccount.VAT_Number__c='TAXID13';
        outletAccount.Name ='Test111';
        insert outletAccount1;
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        insert territory;
        Territory_Hierarchy__c hirarchy= ECM_UtilityTestClass.createhirarchy(geographyId);
        hirarchy.recordtypeId=Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Region').getRecordTypeId();
        insert hirarchy;
        territory.Primary_Sales_Rep__c = usr.id;
        territory.Country__c= geographyId;
        territory.Region__c=hirarchy.Id;
        update territory;
        ECM_Payment_Frequency__c paymfreq = new ECM_Payment_Frequency__c();
        paymfreq.ECM_Type__c='Monthly';
        paymfreq.ECM_Other_Investment__c=true;
        paymfreq.ECM_Volume_target__c=true;
        paymfreq.ECM_Number_of_months_for_recurrence__c='20';
        paymfreq.ECM_From_When_Starts__c='Calendar Year';
        paymfreq.ECM_Geography__c=geographyId;
        Insert paymfreq;
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        String contractGroupRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Group').getRecordTypeId();
        Contract objContract = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract.Status = 'Draft';
        objContract.Contract_End_Date__c = System.today()+29;
        objContract.AccountId=outletAccount.Id;
        objContract.ECM_Territory__c=testterritory.Id;
        //objContract.ECM_Contract_Type__c=contractType.Id;
        objContract.ECM_Agreement_Type__c=contractType.Id;
        objContract.recordTypeId=contractRecordTypeId;
        objContract.ECM_Channel__c='On-Premise';
        objContract.ECM_Banner__c=banner.Id;
        objContract.StartDate = system.today();
        objContract.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContract.Contract_End_Date__c = system.today()+360;
        objContract.OwnerId = usr.Id;
        insert objContract;
        
        Contract objContract2 = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract2.Status = 'Draft';
        objContract2.Contract_End_Date__c = System.today()+29;
        objContract2.AccountId=outletAccount.Id;
        objContract2.ECM_Territory__c=testterritory.Id;
        //objContract2.ECM_Contract_Type__c=contractType.Id;
        objContract2.recordTypeId=contractRecordTypeId;
        objContract2.ECM_Channel__c='On-Premise';
        objContract2.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContract2.StartDate = system.today()+150;
        objContract2.Contract_End_Date__c = system.today()+360;
        objContract2.ECM_Agreement_Type__c=contractType.Id;
        insert objContract2;
        system.debug(LoggingLevel.Debug,'CreatedById---'+objContract2.CreatedById);
        Contract objContract3 = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract3.Status = 'Draft';
        objContract3.Contract_End_Date__c = System.today()+29;
        objContract3.AccountId=outletAccount.Id;
        objContract3.ECM_Territory__c=testterritory.Id;
        //objContract3.ECM_Contract_Type__c=contractType.Id;
        objContract3.recordTypeId=contractRecordTypeId;
        objContract3.ECM_Channel__c='On-Premise';
        objContract3.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContract3.StartDate = system.today();
        objContract3.Contract_End_Date__c = system.today()+150;
        insert objContract3;
        
        Contract objContract4 = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract4.Status = 'Draft';
        objContract4.Contract_End_Date__c = System.today()+29;
        objContract4.AccountId=outletAccount.Id;
        objContract4.ECM_Territory__c=testterritory.Id;
        //objContract4.ECM_Contract_Type__c=contractType.Id;
        objContract4.recordTypeId=contractRecordTypeId;
        objContract4.ECM_Channel__c='On-Premise';
        objContract4.StartDate = system.today()+150;
        objContract4.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContract4.Contract_End_Date__c = system.today()+180;
        insert objContract4;
        
        Contract objContract5 = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract5.Status = 'Draft';
        objContract5.Contract_End_Date__c = System.today()+29;
        objContract5.AccountId=outletAccount.Id;
        objContract5.ECM_Territory__c=testterritory.Id;
        //objContract5.ECM_Contract_Type__c=contractType.Id;
        objContract5.recordTypeId=contractRecordTypeId;
        objContract5.ECM_Channel__c='On-Premise';
        objContract5.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContract5.StartDate = system.today()+90;
        objContract5.Contract_End_Date__c = system.today()+500;
        insert objContract5;
        
        Contract objContract6 = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract6.Status = 'Draft';
        objContract6.Contract_End_Date__c = System.today()+29;
        objContract6.AccountId=outletAccount.Id;
        objContract6.ECM_Territory__c=testterritory.Id;
        //objContract6.ECM_Contract_Type__c=contractType.Id;
        objContract6.recordTypeId=contractRecordTypeId;
        objContract6.ECM_Channel__c='On-Premise';
        objContract6.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContract6.StartDate = system.today()+90;
        objContract6.Contract_End_Date__c = system.today()+900;
        insert objContract6;
        
        Contract objContract7 = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract7.Status = 'Draft';
        objContract7.Contract_End_Date__c = System.today()+29;
        objContract7.AccountId=outletAccount.Id;
        objContract7.ECM_Territory__c=testterritory.Id;
        //objContract7.ECM_Contract_Type__c=contractType.Id;
        objContract7.ECM_Agreement_Type__c=contractType.Id;
        objContract7.recordTypeId=contractRecordTypeId;
        objContract7.ECM_Channel__c='On-Premise';
        objContract7.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContract7.ECM_Banner__c=banner.Id;
        objContract7.StartDate = system.today();
        objContract7.Contract_End_Date__c = system.today()+360;
        objContract7.ECM_Overall_Investment_Amount__c=30.00; 
        insert objContract7;
        Contract objContract9 = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract9.Status = 'Draft';
        objContract9.Contract_End_Date__c = System.today()-29;
        objContract9.AccountId=outletAccount.Id;
        objContract9.ECM_Territory__c=testterritory.Id;
        //objContract7.ECM_Contract_Type__c=contractType.Id;
        objContract9.ECM_Agreement_Type__c=contractType.Id;
        objContract9.recordTypeId=contractGroupRecordTypeId;
        objContract9.ECM_Channel__c='On-Premise';
        objContract9.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContract9.ECM_Banner__c=banner.Id;
        objContract9.StartDate = system.today()-50;
       // objContract9.Contract_End_Date__c = system.today()+360;
        objContract9.ECM_Overall_Investment_Amount__c=30.00;
        objContract9.ECM_CTD_Overall_Investment__c = 20.00;
        objContract9.ECM_CTD_Total_A_P_Investment__c = 15.00;
        objContract9.ECM_CTD_Total_GP__c = 25.00;
        objContract9.ECM_Total_Indirect_Investment__c = 40.00;
        //objContract9.ECM_CTD_CAAP_ROI__c = 50.00;
        objContract9.ECM_CTD_Total_NSV__c = 22.00;
        //objContract9.ECM_CTD_Overall_Invst_incl_Indirect_Inv__c = 47.00;
        insert objContract9;
        objContract9.Status = 'Closed';
        update objContract9;
        Contract objContract8 = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract8.Status = 'Draft';
        objContract8.Contract_End_Date__c = System.today()+29;
        objContract8.AccountId=outletAccount.Id;
        objContract8.ECM_Territory__c=testterritory.Id;
        //objContract8.ECM_Contract_Type__c=contractType.Id;
        objContract8.ECM_Agreement_Type__c=contractType.Id;
        objContract8.recordTypeId=contractRecordTypeId;  
        objContract8.ECM_Channel__c='On-Premise';
        objContract8.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContract8.ECM_Banner__c=banner.Id;
        objContract8.StartDate = system.today();
        objContract8.Contract_End_Date__c = system.today()+360;
        insert objContract8;
        objContract8.UOS_AP_Rate__c= 55;
        objContract8.UOS_Rebate_Rate__c=88;
        objContract8.Status='Active';
        update objContract8;
        //Spain Data
        Id geographyId1 = EDGE_UtilityTestClass.setupCountrySpain('ES'); 
        ECM_Contract_Type__c contractTypeEU = ECM_UtilityTestClass.createContractType(geographyId1);
        contractTypeEU.ECM_Allow_Multiple_Agreements__c = true;
        insert contractTypeEU;
        
        Contract objContractEU = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContractEU.Status = 'Draft';
        objContractEU.Contract_End_Date__c = System.today()+29;
        objContractEU.AccountId=outletAccount.Id;
        objContractEU.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContractEU.ECM_Territory__c=testterritory.Id;
        //objContractEU.ECM_Contract_Type__c=contractTypeEU.Id;
        objContractEU.ECM_Agreement_Type__c=contractTypeEU.Id;
        objContractEU.recordTypeId=contractRecordTypeId;
        objContractEU.ECM_Channel__c='On-Premise';
        objContractEU.ECM_Banner__c=banner.Id;
        objContractEU.StartDate = system.today();
        objContractEU.Contract_End_Date__c = system.today()+360;
        insert objContractEU;  
        
        Contract objContractEU1 = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContractEU1.Status = 'Draft';
        objContractEU1.Contract_End_Date__c = System.today()+29;
        objContractEU1.AccountId=outletAccount.Id;
        objContractEU1.ECM_Territory__c=testterritory.Id;
        //objContractEU1.ECM_Contract_Type__c=contractTypeEU.Id;
        objContractEU1.recordTypeId=contractRecordTypeId;
        objContractEU1.ECM_Channel__c='On-Premise';
        objContractEU1.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContractEU1.StartDate = system.today()+150;
        objContractEU1.Contract_End_Date__c = system.today()+360;
        objContractEU1.ECM_Agreement_Type__c=contractTypeEU.Id;
        insert objContractEU1;
        objContractEU1.Status = 'Active';
        update objContractEU1;
        mapstringrecordvalue.put(objContract.ECM_Channel__c,objContract);
        Business_Role__c businessRole =new Business_Role__c();
        businessRole.Name='Spain Mainland';
        businessRole.Country__c=geographyId;
        businessRole.Call_Type__c='Telephone';
        insert businessRole;
        
        User_Business_Role__c userBusinessRole =new User_Business_Role__c();        
        userBusinessRole.Business_Role__c=businessRole.Id;
        userBusinessRole.User__c=usr.Id;
        insert userBusinessRole;
        User_Business_Role__c ubr = new User_Business_Role__c();
        ubr.Business_Role__c= businessRole.Id ;
        ubr.User__c=userinfo.getUserId();
        insert ubr;
        
        ECM_Role_Agreement__c  roleAgreement =new ECM_Role_Agreement__c();        
        //roleAgreement.Business_Role__c=userBusinessRole.Business_Role__c;
        roleAgreement.Business_Role__c=businessRole.Id;
        roleAgreement.Agreement_Type__c=contractType.Id;
        insert roleAgreement;
        
        Product__c product = new Product__c();
        product.Name='Test';
        product.Product_Full_Name__c='Test';
        product.Country__c=geographyId;
        insert product;
        Product_UOM__c prdtUOM = new Product_UOM__c();
        prdtUOM.Product__c = product.Id;
        prdtUOM.Conversion_Factor__c = 2;
        prdtUOM.Type__c='BTL';
        prdtUOM.Unique_ID__c= product.id +'BTL';
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
        ECM_Addendum__c add = new ECM_Addendum__c();
        add.ECM_Status__c = 'draft';
        add.Name = 'Add1';
        add.ECM_Contract__c = objContract7.Id;
        insert add;
        ECM_Contract_Item__c newcontractitem= new ECM_Contract_Item__c();
        newcontractitem.ECM_Contract__c=objContract.Id;
        newcontractitem.ECM_Product__c=marketassort.id;
        insert newcontractitem;
        contractItemslist.add(newcontractitem);
        ECM_Contract_Item__c newcontractitem1= new ECM_Contract_Item__c();
        newcontractitem1.ECM_Contract__c=objContract7.Id;
        newcontractitem1.ECM_Product__c=marketassort.id;
        newcontractitem1.ECM_Addendum__c=add.Id;
        insert newcontractitem1;
        contractItemslist1.add(newcontractitem1);
        ECM_Contract_Item__c newcontractitem2= new ECM_Contract_Item__c();
        newcontractitem2.ECM_Contract__c=objContract8.Id;
        newcontractitem2.ECM_Product__c=marketassort.id;
        insert newcontractitem2;
        ECM_Contract_Item__c newcontractitem3= new ECM_Contract_Item__c();
        newcontractitem3.ECM_Contract__c=objContract7.Id;
        newcontractitem3.ECM_Product__c=marketassort.id;
        insert newcontractitem3;
        //Sales driver Records
        Territory_Budget__c terriBudget = ECM_UtilityTestClass.createTerritoryBudget(territory.Id, hirarchy.Id);
        insert terriBudget;
        Territory_Budget__c terriBudget1 = ECM_UtilityTestClass.createTerritoryBudget(territory.Id, hirarchy.Id);
        terriBudget1.ECM_Budget_Type__c=budjectEU.Id;
        insert terriBudget1;
        Territory_Budget__c terriBudget2 = ECM_UtilityTestClass.createTerritoryBudget(territory.Id, hirarchy.Id);
        terriBudget2.ECM_Budget_Type__c=budjectEU1.Id;
        insert terriBudget2;
        
        ECM_Sales_Driver__c salesDriver = ECM_UtilityTestClass.getSalesdriver(terriBudget1.Id,geographyId);
        salesDriver.ECM_Budget_Type__c=budjectEU.Id;
        insert salesDriver;
        
        ECM_Sales_Driver__c salesDriver3 = ECM_UtilityTestClass.getSalesdriver(terriBudget2.Id,geographyId);
        salesDriver3.ECM_Budget_Type__c=budjectEU1.Id;
        insert salesDriver3;
        
        Id salesDriverRecordTypeId1=Schema.SObjectType.ECM_Sales_Driver__c.getRecordTypeInfosByName().get('Activation Spend').getRecordTypeId();
        ECM_Sales_Driver__c salesdriver1 = new ECM_Sales_Driver__c();
        salesdriver1.Name = 'Bottle Test1';
        salesdriver1.Geography__c = geographyId;
        salesdriver1.RecordTypeId=salesDriverRecordTypeId1;
        salesdriver1.ECM_Territory_Budget__c = terriBudget2.Id;
        salesdriver1.ECM_Budget_Type__c=budjectEU1.Id;
        salesdriver1.ECM_Activation_Spend_Sub_Group__c=actSPsub1.Id;
        insert salesdriver1;
        
        ECM_Sales_Driver__c salesdriver2 = new ECM_Sales_Driver__c();
        salesdriver2.Name = 'Bottle Test2';
        salesdriver2.Geography__c = geographyId;
        salesdriver2.RecordTypeId=salesDriverRecordTypeId1;
        salesdriver2.ECM_Territory_Budget__c = terriBudget1.Id;
        salesdriver2.ECM_Budget_Type__c=budjectEU.Id;
        salesdriver2.ECM_Activation_Spend_Sub_Group__c=actSPsub2.Id;
        insert salesdriver2;
        Id sdirecId = Schema.SObjectType.ECM_Sales_Driver_Item__c.getRecordTypeInfosByName().get('Sales Driver').getRecordTypeId();
        Id sdiasrecId = Schema.SObjectType.ECM_Sales_Driver_Item__c.getRecordTypeInfosByName().get('Activation Spend').getRecordTypeId();
        
        ECM_Sales_Driver_Item__c eSCDI = new ECM_Sales_Driver_Item__c(Contract__c=objContract7.Id,ECM_Sales_Driver__c=SalesDriver.Id,RecordTypeId=sdirecId);
        insert eSCDI;
        ECM_Sales_Driver_Item__c eSCDI1 = new ECM_Sales_Driver_Item__c(Contract__c=objContract7.Id,ECM_Sales_Driver__c=SalesDriver3.Id,RecordTypeId=sdirecId);
        insert eSCDI1;
        ECM_Sales_Driver_Item__c eSCDI2 = new ECM_Sales_Driver_Item__c(Contract__c=objContract7.Id,ECM_Sales_Driver__c=salesdriver1.Id,RecordTypeId=sdiasrecId);
        insert eSCDI2;
        ECM_Sales_Driver_Item__c eSCDI3 = new ECM_Sales_Driver_Item__c(Contract__c=objContract7.Id,ECM_Sales_Driver__c=salesdriver2.Id,RecordTypeId=sdiasrecId);
        insert eSCDI3;
        
        Id sdidrecId = Schema.SObjectType.ECM_Sales_Driver_Item_Detail__c.getRecordTypeInfosByName().get('Sales Driver').getRecordTypeId();
        Id sdidasrecId = Schema.SObjectType.ECM_Sales_Driver_Item_Detail__c.getRecordTypeInfosByName().get('Activation Spend').getRecordTypeId();

        ECM_Sales_Driver_Item_Detail__c salesDetails1 = ECM_UtilityTestClass.insertSalesdriverDetails(eSCDI, newcontractitem1);
        salesDetails1.RecordtypeId=sdidrecId;
        //salesDetails1.ECM_Activation_Spend_SubGroup__c = actSPsub1.id;
        insert salesDetails1;
		ECM_Sales_Driver_Item_Detail__c salesDetails2 = ECM_UtilityTestClass.insertSalesdriverDetails(eSCDI1, newcontractitem1);
        salesDetails2.RecordtypeId=sdidrecId;
        insert salesDetails2;
        ECM_Sales_Driver_Item_Detail__c salesDetails3 = ECM_UtilityTestClass.insertSalesdriverDetails(eSCDI2, newcontractitem1);
        salesDetails3.RecordtypeId=sdidasrecId;
        salesDetails3.ECM_Activation_Spend_SubGroup__c = actSPsub1.id;
        insert salesDetails3;
		ECM_Sales_Driver_Item_Detail__c salesDetails4 = ECM_UtilityTestClass.insertSalesdriverDetails(eSCDI3, newcontractitem1);
        salesDetails4.ECM_Activation_Spend_SubGroup__c = actSPsub1.id;
        salesDetails4.RecordtypeId=sdidasrecId;
        insert salesDetails4;
        ECM_Sales_Driver_Item_Detail__c salesDetails5 = ECM_UtilityTestClass.insertSalesdriverDetails(eSCDI, newcontractitem1);
        salesDetails5.RecordtypeId=sdidrecId;
        insert salesDetails5;
		ECM_Sales_Driver_Item_Detail__c salesDetails6 = ECM_UtilityTestClass.insertSalesdriverDetails(eSCDI1, newcontractitem1);
        salesDetails6.RecordtypeId=sdidrecId;
        insert salesDetails6;
        ECM_Sales_Driver_Item_Detail__c salesDetails7 = ECM_UtilityTestClass.insertSalesdriverDetails(eSCDI, newcontractitem1);
        salesDetails7.RecordtypeId=sdidrecId;
        salesDetails7.ECM_Product__c=null;
        insert salesDetails7;
        ECM_Sales_Driver_Item_Detail__c salesDetails8 = ECM_UtilityTestClass.insertSalesdriverDetails(eSCDI, newcontractitem1);
        salesDetails8.RecordtypeId=sdidrecId;
        salesDetails8.ECM_Product__c=newcontractitem2.Id;
        insert salesDetails8;
        List<ECM_Sales_Driver_Item__c> eSDList = new List<ECM_Sales_Driver_Item__c>();
        eSDList.add(eSCDI);

        Depletions__c dep = new Depletions__c();
        dep.ECM_Volume__c = 100.00;
        dep.ECM_Outlet__c = outletAccount.id;
        dep.ECM_Start_Period__c = system.today()+360;
        dep.ECM_End_Period__c = system.today()+29;
        dep.ECM_Product__c = product.id;
        dep.ECM_Outlet__c = outletAccount.Id;
        insert dep;
        acclist.add(outletAccount1);
        //system.assertEquals(userBusinessRole.User__c, usr.Id);
        ECM_CreateContractController.getContractTypes();
        ECM_CreateContractController.getContractTypesOutlet(outletAccount.Id);
        
        Outlet_Contract__c otletcontract=New Outlet_Contract__c();
        otletcontract.Contract__c=objContract.Id;
        otletcontract.Outlet__c=outletAccount.Id;
        otletcontract.Activation_Date__c=system.today();
        insert otletcontract;
        otletcontract.ECM_Total_Outlet_Taps__c= 100;
        otletcontract.ECM_No_of_Taps_Diageo_will_Invest__c=75;
        otletcontract.ECM_of_Taps_Diageo_will_invest__c= .75;
        List<Outlet_Contract__c> otletContractList = new List<Outlet_Contract__c>();
        
        Account ownerAccount=EDGE_UtilityTestClass.getOwnerOperatorAccount();
        ownerAccount.Person_Responsible__c= usr.Id;
        ownerAccount.OwnerId = usr.Id;
        ownerAccount.SAP_Sold_to__c='39840210';
        ownerAccount.VAT_Number__c='TAXID1230';
        ownerAccount.ECM_Legal_Name__c='Legal';
        ownerAccount.Email_for_contracts_payments__c='manikandan.t@diageo.com.test';
        ownerAccount.Country__c = geographyId1;
        ownerAccount.IsOperator__c=true;
        insert ownerAccount;
        system.runAs(usr){            
            test.starttest();
            ECM_CreateContractController.getAccountById(outletAccount.Id);
            // ECM_CreateContractController.getUserCountry();
            ECM_CreateContractController.getAttributes(outletAccount.Id);
            ECM_CreateContractController.getPickUpOptionsPicklistvalues();
            ECM_CreateContractController.getListOfAccounts();
            ECM_CreateContractController.setdefaultvalues_Discount(objContract);
            ECM_CreateContractController.getChannelPicklistvalues();
            ECM_CreateContractController.getPicklistvalues('Contract','ECM_Channel__c');
            ECM_CreateContractController.statesAndProvinces();
            ECM_CreateContractController.getAccountRecords(1,outletAccount.Operator__c);
            ECM_CreateContractController.loadAccountRecords(3,1,outletAccount1.Operator__c);
            //ECM_CreateContractController.validation_for_Agreement_Type(objContractEU,outletAccount.id,contractRecordTypeId);
            ECM_CreateContractController.updateContractItems(contractItemslist);
            ECM_CreateContractController.deleteOldContractItems(contractItemslist);
            ECM_CreateContractController.paymentFrequencyvalues(objContract.ECM_Agreement_Type__c);
            ECM_CreateContractController.paymentSchedulevalues(objContract.ECM_Agreement_Type__c);
            ECM_CreateContractController.salesdrivers(objContract.ECM_Agreement_Type__c);
            ECM_CreateContractController.saveVolumeTargets(JSON.serialize(contractItemslist1),contractType,objContract,null);
            ECM_CreateContractController.getOutletTapsTable(objContract);
            try
            {                
                ECM_CreateContractController.submitForApproval(JSON.serialize(objContract2) ,JSON.serialize(contractItemslist1),JSON.serialize(otletContractList));
            }
            catch(exception e)
            {
                System.debug(LoggingLevel.debug,'Error ');
            }  
            //ECM_CreateContractController.submitForApproval(JSON.serialize(objContract2) ,JSON.serialize(contractItemslist1));
            ECM_CreateContractController.get_contractitem_with_exsisiting_baseVol(contractItemslist1);
            ECM_CreateContractController.savecontract(objContract7);
            ECM_CreateContractController.get_default_Banner_AU();
            ECM_CreateContractController.salesdrivervaluesAU(objContract7.Id);
            /* ----- ECM_CreateContractController.processSalesDriversToInsert('',objContract7); ----- */
            //ECM_CreateContractController.sendEmailToUser(usr,objContract7,null);
            ECM_CreateContractController.getUser(newuser.id);
            ECM_CreateContractController.loadvalues(objContract7.id);
            ECM_CreateContractController.loadvalues(objContract.id);
            ECM_CreateContractController.displayPrevCon(objContract9);
            ECM_CreateContractController.loadInvestmentsValues(objContract7,contractItemslist1,false,false);
            ECM_CreateContractController.getEandSContract();
            
            //Sales driver Testing 
            ECM_CreateContractController.salesdriverItemWrap salesDriveWrap = ECM_UtilityTestClass.salesdrivervalues(eSCDI, salesDetails1,newcontractitem);
            ECM_CreateContractController.loadInvestmentsValues(objContract,new List<ECM_Contract_Item__c>{newcontractitem},false,true);
            ECM_CreateContractController.createSalesDriverItemDetailForAddendum(objContract7.Id,add.Id);
            ECM_CreateContractController.salesdriveritems lstsalesdriver = ECM_UtilityTestClass.getSalesdriveritems(salesDriver,eSCDI);
            String str =JSON.serialize(lstsalesdriver);
            List<ECM_CreateContractController.salesdriverItemWrap> lstSalesWrap;
            lstSalesWrap = ECM_CreateContractController.saveSalesDrivers('',str,contractItemslist1,objContract7.Id);
            ECM_CreateContractController.SalesdriversAU('['+str+']',objContract.Id);
           // ECM_CreateContractController.checkTieringInvestment(objContract);
            ECM_Tiering__c tier = ECM_CreateContractController.createTieringRecord(newcontractitem1.Id, 10, 10, 20, 20, 30, 30);
            ECM_CreateContractController.delTieringObjrec(tier.Id);
            // ECM_CreateContractController.getTieringObj();
            List<ECM_CreateContractController.salesdriverItemWrap> sditm = new List<ECM_CreateContractController.salesdriverItemWrap>();            
            sditm.add(salesDriveWrap);
            //ECM_CreateContractController.processSalesDriversToInsert(JSON.serialize(sditm),objContract); 
            ECM_CreateContractController.removeSalesDriver(eSCDI.id);
            ECM_CreateContractController.getMarketSettings(outletAccount.Id);
            ECM_CreateContractController.createContract(objContract7, ownerAccount.Id, contractGroupRecordTypeId,testterritory.id , contractType.Id,acclist);
            //ECM-5622
            ECM_Event__c evt = new ECM_Event__c();
            evt.ECM_Event_Name__c = 'Test Event Name';
            evt.ECM_Percent_Sponsorship_Fee_Allocation__c = 20;
            evt.ECM_Event_Date__c = System.today();
            evt.ECM_Contract__c = objContract.Id;
            evt.ECM_Event_Unique_Id__c = objContract.Id+'_'+evt.ECM_Event_Name__c+'_'+evt.ECM_Event_Date__c;
            
            ECM_Event__c evt1 = new ECM_Event__c();
            evt1.ECM_Event_Name__c = 'Test Event Name12';
            evt1.ECM_Percent_Sponsorship_Fee_Allocation__c = 10;
            evt1.ECM_Event_Date__c = System.today();
            evt1.ECM_Contract__c = objContract.Id;
            evt1.ECM_Event_Unique_Id__c = objContract.Id+'_'+evt1.ECM_Event_Name__c+'_'+evt1.ECM_Event_Date__c;
            //evt.ECM_Event_Unique_Id__c = 'Test';
            List<ECM_Event__c> evtData= new List<ECM_Event__c>{evt,evt1};
            ECM_CreateContractController.createEvents(JSON.Serialize(evtData));
            
       
            test.stoptest();
        }   
    } 
	@isTest
    public static void translationTest(){
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        
        Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(geographyId);
        mktSetting.ECM_Contract_Header_Details__c='ECM_Contract_Owner__c;ECM_Territory__r.Name;Account.ECM_Legal_Name__c;Account.Name;ECM_Agreement_Type__r.Name;StartDate;Contract_End_Date__c;ContractNumber;Name';
        mktSetting.ECM_Investment_Summary_KPIS__c='ECM_Total_Volume_Target_Spirits__c;ECM_Total_Volume_Target_Beers__c;ECM_Incremental_Volume_Spirits__c;ECM_Incremental_Volume_Beers__c;ECM_Total_trade_investment_Beers__c;ECM_Total_A_P_Investment_Spirits__c;ECM_Incremental_GP__c;ECM_Incremental_GP_Beers__c';
        mktSetting.ECM_Category_Split_KPIS__c='ECM_NSV_reserve_share__c;ECM_NSV_premium_core_share__c;ECM_GP_reserve_share__c;ECM_GP_innovation_share__c;ECM_GM_reserve_share__c;ECM_GM_innovation_share__c;ECM_GM_premium_core_share__c;ECM_TV_reserve_share__c;ECM_TV_premium_core_share__c;ECM_IV_reserve_share__c;ECM_IV_innovation_share__c;ECM_IV_premium_core_share__c';
        mktSetting.ECM_Product_Investment_Details__c='ECM_Retro_investment__c;ECM_Trade_Investments__c;ECM_AnP_investment__c;ECM_Gross_margin__c;ECM_Total_GP_EU__c;ECM_Generated_NSV_EU__c;ECM_NSV_After_Investment__c;ECM_Incremental_GP_after_Investment__c;Tiers;ECM_UoM__c;ECM_Baseline_volume__c;ECM_Volume__c;ECM_Incremental_Volume__c;ECM_CAAP_Total__c;ECM_Product_growth_driver__c';
        mktSetting.ECM_Sales_Drivers_Details__c='ECM_Investement_Description__c;ECM_Budget_Type__c;ECM_Payment_Frequency__r.ECM_Type__c;Payment dates;ECM_Total_Investment_Amount__c;ECM_Prepayment__c;ECM_Sales_Driver_Name__c';
        mktSetting.ECM_Contract_Creation_Page__c='Global';
        mktSetting.ECM_Contract_Management_Market__c=true;
        mktSetting.ECM_SAP_Order_Type__c='YPCR';    
        mktSetting.ECM_Mandatory_field_for_Contract__c='SAP Sold To;Legal Name;SAP Ship to;Customer email for Contract;Sales org;';
        mktSetting.ECM_Payment_Management_Email__c='test@test22.com';
        mktSetting.ECM_Email_to_Send_Payment_CSV__c='test@test23.com';
        insert mktSetting;
        
        String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        String bRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        
        Pick_Up_Options__c banner= new Pick_Up_Options__c();
        banner.Name='Range[ES]';
        banner.Geography__c=geographyId;
        banner.RecordTypeId=bannerRecordTypeId;
        insert banner;
        Pick_Up_Options__c bannerAU= new Pick_Up_Options__c();
        bannerAU.Name='IBA[AU]';
        bannerAU.Geography__c=geographyId;
        bannerAU.RecordTypeId=bannerRecordTypeId;
        insert bannerAU;
        Pick_Up_Options__c budjectEU= new Pick_Up_Options__c();
        budjectEU.Name='A&P [ES]';
        budjectEU.Geography__c=geographyId;
        budjectEU.RecordTypeId=bRecordTypeId;
        insert budjectEU;
        
        Profile prof = [select id from profile where name=: 'Sales Representative'];
        User usrmngr = new User();
        usrmngr.firstName = 'testManager';
        usrmngr.lastName = 't2';
        usrmngr.profileId = prof.id;        
        usrmngr.email = 'test.MamagerSfdc3@test.com';
        usrmngr.Username ='test.MamagerSfdc3@test.com';
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
        usr.email = 'test.MamagerSfdc5@test.com';
        usr.Username ='test.MamagerSfdc5@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='ES';
        usr.ManagerId = usrmngr.Id;
        usr.DelegatedApproverId = usrmngr.Id;
        insert usr;
        System.assert(usr.id!=null,'User Id should not be null');
        
        System.runAs(usr){
            ECM_CreateContractController.getUserCountry();
            
            ECM_CreateContractController.AccountWrapperList accWrap = new ECM_CreateContractController.AccountWrapperList();
            accWrap.message = '';
            accWrap.success = true;
            
            ECM_CreateContractController.objectWrapper objWrap = new ECM_CreateContractController.objectWrapper();
            objWrap.Upfront = 0;
            
            ECM_CreateContractController.Discountrecord dsRec = new ECM_CreateContractController.Discountrecord();
            dsRec.nameofdiscount = 'Full Discount';
            dsRec.pickuprecord = budjectEU;
            
            ECM_CreateContractController.DiscountWrapper dsWrap = new ECM_CreateContractController.DiscountWrapper();
            dsWrap.discountlist = dsRec;
            
            ECM_CreateContractController.contractItemsandAgreementType conItemAgreeType;
            conItemAgreeType = new ECM_CreateContractController.contractItemsandAgreementType();
            
            ECM_CreateContractController.salesdriveritemswithbudjet  salesDriverWrap = new ECM_CreateContractController.salesdriveritemswithbudjet();
            salesDriverWrap.AandP = 0;
            salesDriverWrap.ContractItem = Null;
            salesDriverWrap.TI = 0;
            
        }
    }   
    /*@isTest
    public static void testCreateEvents(){
       
        List<ECM_Event__c> evtLst = new List<ECM_Event__c>();
        List<ECM_Event__c> evtLstforCreate = new List<ECM_Event__c>();
        
        evtLst = [SELECT Id,ECM_Event_Name__c,ECM_Percent_Sponsorship_Fee_Allocation__c,ECM_Event_Date__c,ECM_Contract__c FROM ECM_Event__c LIMIT 1];
        ECM_Event__c ecmEvtToCreate = new ECM_Event__c();
        ecmEvtToCreate.ECM_Event_Name__c = 'Test '+evtLst.get(0).ECM_Event_Name__c;
        ecmEvtToCreate.ECM_Percent_Sponsorship_Fee_Allocation__c = evtLst.get(0).ECM_Percent_Sponsorship_Fee_Allocation__c;
        ecmEvtToCreate.ECM_Event_Date__c = evtLst.get(0).ECM_Event_Date__c;
        ecmEvtToCreate.ECM_Contract__c =  evtLst.get(0).ECM_Contract__c;
        
        evtLstforCreate.add(ecmEvtToCreate);
        
        ECM_CreateContractController.createEvents(evtLstforCreate);
        
    }*/
    @isTest
    public static void createOutletContractTestIE(){
        List<Account> acclist = new List<Account>();
        //List<Account> acclist1 = new List<Account>();
        Profile prof = [select id from profile where name=: 'Sales Representative'];
        User usrmngr = new User();
        usrmngr.firstName = 'testManager';
        usrmngr.lastName = 't2';
        usrmngr.profileId = prof.id;        
        usrmngr.email = 'test.MamagerSfdc@test.com';
        usrmngr.Username ='test.MamagerSfdc@test.com';
        usrmngr.Alias='test';
        usrmngr.Timezonesidkey='America/Los_Angeles';
        usrmngr.LocaleSidKey='en_US';
        usrmngr.LanguageLocaleKey='en_US';
        usrmngr.EmailEncodingKey='UTF-8';
        usrmngr.Available_Countries__c='IE';
        insert usrmngr;
        
        User usr = new User();
        usr.firstName = 'test1';
        usr.lastName = 'test2';
        usr.profileId = prof.id;        
        usr.email = 'test.MamagerSfdc1@test.com';
        usr.Username ='test.MamagerSfdc1@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='IE';
        usr.ManagerId = usrmngr.Id;
        usr.DelegatedApproverId = usrmngr.Id;
        insert usr;
        System.assert(usr.id!=null,'user id should not be null');
        
        system.debug(LoggingLevel.Debug,'(USer==>  '+usr);
        user newuser = EDGE_UtilityTestClass.runAsUser('Testabc','System Administrator');
        insert newuser;
        Map<string,string> fieldsformappingrecords;
        fieldsformappingrecords= new  Map<string,string>{'Draught Discounts' => 'ECM_Draught_Spirits_Discount_Level__c',
            'Pouring Discounts' => 'ECM_Spirits_Pouring_Discount_Level__c',
            'Premium Discounts' => 'ECM_Spirits_Premium_Discount_Level__c',
            'Reserve Discounts' => 'ECM_Spirits_Reserve_Discount_Level__c',
            'RTD Discount' => 'ECM_RTD_Discount_Level__c',
            'Spirits Discounts' => 'ECM_Spirits_Discount_Level__c'};
                
        Map<String,contract> mapstringrecordvalue = new Map<string,contract>();
        List<ECM_Contract_Item__c> contractItemslist = new List<ECM_Contract_Item__c>();
        //List<ECM_Contract_Item__c> contractItemslist1 = new List<ECM_Contract_Item__c>();
        Id geographyId = EDGE_UtilityTestClass.setupCountry('IE');
                

        Territory__c testterritory=New Territory__c();
        testterritory.Name='Testterriotory';
        testterritory.Territory_Type__c='Sales';
        testterritory.Country__c= geographyId;
        testterritory.Status__c='Active';
        testterritory.Primary_Sales_Rep__c = usr.id;
        insert testterritory;
        
        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        contractType.ECM_Activation_Spend_Table_Configuration__c = 'Activation Spend Sub Group;Activity Type Description;Delivery Date;Must Do';
        contractType.ECM_Contract_Approval_mail_to_Customer__c = true;
        contractType.ECM_of_Outlets_Tap_Space_Required__c = 0.8;
        insert contractType;
        
        Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(geographyId);
        mktSetting.ECM_Contract_Header_Details__c='ECM_Contract_Owner__c;ECM_Territory__r.Name;Account.ECM_Legal_Name__c;Account.Name;ECM_Agreement_Type__r.Name;StartDate;Contract_End_Date__c;ContractNumber;Name';
        mktSetting.ECM_Investment_Summary_KPIS__c='ECM_Total_Volume_Target_Spirits__c;ECM_Total_Volume_Target_Beers__c;ECM_Incremental_Volume_Spirits__c;ECM_Incremental_Volume_Beers__c;ECM_Total_trade_investment_Beers__c;ECM_Total_A_P_Investment_Spirits__c;ECM_Incremental_GP__c;ECM_Incremental_GP_Beers__c';
        mktSetting.ECM_Category_Split_KPIS__c='ECM_NSV_reserve_share__c;ECM_NSV_premium_core_share__c;ECM_GP_reserve_share__c;ECM_GP_innovation_share__c;ECM_GM_reserve_share__c;ECM_GM_innovation_share__c;ECM_GM_premium_core_share__c;ECM_TV_reserve_share__c;ECM_TV_premium_core_share__c;ECM_IV_reserve_share__c;ECM_IV_innovation_share__c;ECM_IV_premium_core_share__c';
        mktSetting.ECM_Product_Investment_Details__c='ECM_Retro_investment__c;ECM_Trade_Investments__c;ECM_AnP_investment__c;ECM_Gross_margin__c;ECM_Total_GP_EU__c;ECM_Generated_NSV_EU__c;ECM_NSV_After_Investment__c;ECM_Incremental_GP_after_Investment__c;Tiers;ECM_UoM__c;ECM_Baseline_volume__c;ECM_Volume__c;ECM_Incremental_Volume__c;ECM_CAAP_Total__c;ECM_Product_growth_driver__c';
        mktSetting.ECM_Sales_Drivers_Details__c='ECM_Investement_Description__c;ECM_Budget_Type__c;ECM_Payment_Frequency__r.ECM_Type__c;Payment dates;ECM_Total_Investment_Amount__c;ECM_Prepayment__c;ECM_Sales_Driver_Name__c';
        mktSetting.ECM_Contract_Creation_Page__c='Global';
        mktSetting.ECM_Contract_Management_Market__c=true;
        mktSetting.ECM_SAP_Order_Type__c='YPCR';    
        mktSetting.ECM_Mandatory_field_for_Contract__c='SAP Sold To;Legal Name;SAP Ship to;Customer email for Contract;Sales org;';
        mktSetting.ECM_Payment_Management_Email__c='test@test22.com';
        mktSetting.ECM_Email_to_Send_Payment_CSV__c='test@test23.com';
        mktSetting.ECM_Contract_pdf_to_Approval_Mails__c = true;
        insert mktSetting;
        
        String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        String bRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        //String localSRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        
        Pick_Up_Options__c banner= new Pick_Up_Options__c();
        banner.Name='Range[IE]';
        banner.Geography__c=geographyId;
        banner.RecordTypeId=bannerRecordTypeId;
        insert banner;
        
        Pick_Up_Options__c bannerAU= new Pick_Up_Options__c();
        bannerAU.Name='IBA[IE]';
        bannerAU.Geography__c=geographyId;
        bannerAU.RecordTypeId=bannerRecordTypeId;
        insert bannerAU;
                
        Pick_Up_Options__c budjectEU= new Pick_Up_Options__c();
        budjectEU.Name='A&P [IE]';
        budjectEU.Geography__c=geographyId;
        budjectEU.RecordTypeId=bRecordTypeId;
        insert budjectEU;
        
        String pickupRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId();
        String pickupRecordTypeId1 = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Local Segment').getRecordTypeId();
        //id Discountrecordtypeid=Schema.Sobjecttype.Pick_Up_Options__c.getRecordTypeInfosByName().get('Discount Level').getRecordTypeId();
        
        Pick_Up_Options__c banner1= new Pick_Up_Options__c();
        banner1.Name='Range[IE]';
        banner1.Geography__c=geographyId;
        banner1.RecordTypeId=pickupRecordTypeId;
        banner1.Type__c ='Local-Segment1';
        //insert banner1;
        
        Pick_Up_Options__c bannerAU1= new Pick_Up_Options__c();
        bannerAU1.Name='IBAE[IE]';
        bannerAU1.Geography__c=geographyId;
        bannerAU1.RecordTypeId=pickupRecordTypeId1;
        bannerAU1.Type__c='Local-Segment1';
        bannerAU1.Status__c='Active';
        insert bannerAU1;
        
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Person_Responsible__c= usr.Id;
        outletAccount.OwnerId = usr.Id;
        outletAccount.SAP_Sold_to__c='3984021';
        outletAccount.VAT_Number__c='TAXID123';
        outletAccount.ECM_Legal_Name__c='Legal';
        outletAccount.Email_for_contracts_payments__c='manikandan.t@diageo.com.test';
        outletAccount.Country__c = geographyId;
        outletAccount.IsOperator__c=true;
        outletAccount.SAP_Ship_to__c = 'sap1234';
        outletAccount.Sales_Org__c = 'sap0987';
        insert outletAccount;
        
        String accRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId(); 
        
        Account outlet = new Account();
        outlet.Name = 'Test55_Outlet';
        outlet.RecordTypeId = accRecordTypeId;
        outlet.BillingStreet = '17 Asian Highway 45';
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
        outlet.Email_for_contracts_payments__c='manikandan.t@diageo.com.test';
        insert outlet;  
        
        Account outletAccount1 = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount1.Person_Responsible__c= usr.Id;
        outletAccount1.OwnerId = usr.Id;
        outletAccount1.IsOperator__c=true;
        //outletAccount1.Operator__c=outlet.id;
        outletAccount1.SAP_Sold_to__c='398402';
        outletAccount1.ECM_Legal_Name__c='Legal';
        outletAccount1.Email_for_contracts_payments__c='manikandan.t@diageo.com.test';
        outletAccount1.VAT_Number__c='TAXID13';
        outletAccount1.Name ='Test_Outlet_Diageo1';
        insert outletAccount1;
        
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        insert territory;
        
        Territory_Hierarchy__c hirarchy= ECM_UtilityTestClass.createhirarchy(geographyId);
        hirarchy.recordtypeId=Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Region').getRecordTypeId();
        insert hirarchy;
        
        territory.Primary_Sales_Rep__c = usr.id;
        territory.Country__c= geographyId;
        territory.Region__c=hirarchy.Id;
        update territory;
        
        ECM_Payment_Frequency__c paymfreq = new ECM_Payment_Frequency__c();
        paymfreq.ECM_Type__c='Monthly';
        paymfreq.ECM_Other_Investment__c=true;
        paymfreq.ECM_Volume_target__c=true;
        paymfreq.ECM_Number_of_months_for_recurrence__c='20';
        paymfreq.ECM_From_When_Starts__c='Calendar Year';
        paymfreq.ECM_Geography__c=geographyId;
        Insert paymfreq;
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        //String contractGroupRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Group').getRecordTypeId();
        
        Contract objContract = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract.Status = 'Draft';
        objContract.Contract_End_Date__c = System.today()+29;
        objContract.AccountId=outletAccount.Id;
        objContract.ECM_Territory__c=testterritory.Id;
        //objContract.ECM_Contract_Type__c=contractType.Id;
        objContract.ECM_Agreement_Type__c=contractType.Id;
        objContract.recordTypeId=contractRecordTypeId;
        objContract.ECM_Channel__c='On-Premise';
        objContract.ECM_Banner__c=banner.Id;
        objContract.StartDate = system.today();
        objContract.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContract.Contract_End_Date__c = system.today()+360;
        objContract.OwnerId = usr.id;
        insert objContract;

        
        //Spain Data
        Id geographyId1 = EDGE_UtilityTestClass.setupCountrySpain('ES'); 
        Market_Setting__c mktSettingObj =EDGE_UtilityTestClass.getMarketSetting(geographyId1);
        mktSettingObj.ECM_Contract_Header_Details__c='ECM_Contract_Owner__c;ECM_Territory__r.Name;Account.ECM_Legal_Name__c;Account.Name;ECM_Agreement_Type__r.Name;StartDate;Contract_End_Date__c;ContractNumber;Name';
        mktSettingObj.ECM_Investment_Summary_KPIS__c='ECM_Total_Volume_Target_Spirits__c;ECM_Total_Volume_Target_Beers__c;ECM_Incremental_Volume_Spirits__c;ECM_Incremental_Volume_Beers__c;ECM_Total_trade_investment_Beers__c;ECM_Total_A_P_Investment_Spirits__c;ECM_Incremental_GP__c;ECM_Incremental_GP_Beers__c';
        mktSettingObj.ECM_Category_Split_KPIS__c='ECM_NSV_reserve_share__c;ECM_NSV_premium_core_share__c;ECM_GP_reserve_share__c;ECM_GP_innovation_share__c;ECM_GM_reserve_share__c;ECM_GM_innovation_share__c;ECM_GM_premium_core_share__c;ECM_TV_reserve_share__c;ECM_TV_premium_core_share__c;ECM_IV_reserve_share__c;ECM_IV_innovation_share__c;ECM_IV_premium_core_share__c';
        mktSettingObj.ECM_Product_Investment_Details__c='ECM_Retro_investment__c;ECM_Trade_Investments__c;ECM_AnP_investment__c;ECM_Gross_margin__c;ECM_Total_GP_EU__c;ECM_Generated_NSV_EU__c;ECM_NSV_After_Investment__c;ECM_Incremental_GP_after_Investment__c;Tiers;ECM_UoM__c;ECM_Baseline_volume__c;ECM_Volume__c;ECM_Incremental_Volume__c;ECM_CAAP_Total__c;ECM_Product_growth_driver__c';
        mktSettingObj.ECM_Sales_Drivers_Details__c='ECM_Investement_Description__c;ECM_Budget_Type__c;ECM_Payment_Frequency__r.ECM_Type__c;Payment dates;ECM_Total_Investment_Amount__c;ECM_Prepayment__c;ECM_Sales_Driver_Name__c';
        mktSettingObj.ECM_Contract_Creation_Page__c='Global';
        mktSettingObj.ECM_Contract_Management_Market__c=true;
        mktSettingObj.ECM_SAP_Order_Type__c='YPCR';        
        mktSettingObj.ECM_Payment_Management_Email__c='test@test22.com';
        mktSettingObj.ECM_Email_to_Send_Payment_CSV__c='test@test23.com';
        insert mktSettingObj;
        
        ECM_Contract_Type__c contractTypeEU = ECM_UtilityTestClass.createContractType(geographyId);
        insert contractTypeEU;        
        
        
        mapstringrecordvalue.put(objContract.ECM_Channel__c,objContract);
        Business_Role__c businessRole =new Business_Role__c();
        businessRole.Name='Spain Mainland';
        businessRole.Country__c=geographyId;
        businessRole.Call_Type__c='Telephone';
        insert businessRole;
        
        User_Business_Role__c userBusinessRole =new User_Business_Role__c();        
        userBusinessRole.Business_Role__c=businessRole.Id;
        userBusinessRole.User__c=usr.Id;
        insert userBusinessRole;
        
        User_Business_Role__c ubr = new User_Business_Role__c();
        ubr.Business_Role__c= businessRole.Id ;
        ubr.User__c=userinfo.getUserId();
        insert ubr;
        
        ECM_Role_Agreement__c  roleAgreement =new ECM_Role_Agreement__c();        
        //roleAgreement.Business_Role__c=userBusinessRole.Business_Role__c;
        roleAgreement.Business_Role__c=businessRole.Id;
        roleAgreement.Agreement_Type__c=contractType.Id;
        insert roleAgreement;
        
        Product__c product = new Product__c();
        product.Name='Test';
        product.Product_Full_Name__c='Test';
        product.Country__c=geographyId;
        insert product;
        
        Product_UOM__c prdtUOM = new Product_UOM__c();
        prdtUOM.Product__c = product.Id;
        prdtUOM.Conversion_Factor__c = 2;
        prdtUOM.Type__c='BTL';
        prdtUOM.Unique_ID__c= product.id +'BTL';
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
        contractItemslist.add(newcontractitem);
        
        //Sales driver Records
        Territory_Budget__c terriBudget = ECM_UtilityTestClass.createTerritoryBudget(territory.Id, hirarchy.Id);
        insert terriBudget;
        
        Territory_Budget__c terriBudget1 = ECM_UtilityTestClass.createTerritoryBudget(territory.Id, hirarchy.Id);
        terriBudget1.ECM_Budget_Type__c=budjectEU.Id;
        insert terriBudget1;
        
        ECM_Sales_Driver__c salesDriver = ECM_UtilityTestClass.getSalesdriver(terriBudget1.Id,geographyId);
        insert salesDriver;
        
        Depletions__c dep = new Depletions__c();
        dep.ECM_Volume__c = 100.00;
        dep.ECM_Outlet__c = outletAccount.id;
        dep.ECM_Start_Period__c = system.today()+360;
        dep.ECM_End_Period__c = system.today()+29;
        dep.ECM_Product__c = product.id;
        dep.ECM_Outlet__c = outletAccount.Id;
        insert dep;
        
        acclist.add(outletAccount1);
        //system.assertEquals(userBusinessRole.User__c, usr.Id);
        
        Outlet_Contract__c otletcontract=New Outlet_Contract__c();
        otletcontract.Contract__c=objContract.Id;
        otletcontract.Outlet__c=outletAccount.Id;
        otletcontract.Activation_Date__c=system.today();
        insert otletcontract;
        otletcontract.ECM_Total_Outlet_Taps__c= 100;
        otletcontract.ECM_No_of_Taps_Diageo_will_Invest__c=75;
        otletcontract.ECM_of_Taps_Diageo_will_invest__c= .75;
        //List<Outlet_Contract__c> otletContractList = new List<Outlet_Contract__c>();
        
        Account ownerAccount=EDGE_UtilityTestClass.getOwnerOperatorAccount();
        ownerAccount.Person_Responsible__c= usr.Id;
        ownerAccount.OwnerId = usr.Id;
        ownerAccount.SAP_Sold_to__c='39840210';
        ownerAccount.VAT_Number__c='TAXID1230';
        ownerAccount.ECM_Legal_Name__c='Legal';
        ownerAccount.Email_for_contracts_payments__c='manikandan.t@diageo.com.test';
        ownerAccount.Country__c = geographyId1;
        ownerAccount.IsOperator__c=true;
        insert ownerAccount;
        
        system.runAs(usr){

            ECM_CreateContractController.getAccountById(outletAccount.Id);
           // ECM_CreateContractController.getUserCountry();
            ECM_Tiering__c tieringObj =new ECM_Tiering__c();
                tieringObj.ECM_Tier_1_volume_limit__c =3;
                tieringObj.ECM_Tier_1_rate_per_UoM__c =4;
                tieringObj.ECM_Tier_2_volume_limit__c =1;
                tieringObj.ECM_Tier2_rate_per_UoM__c =2;
                tieringObj.ECM_Tier_3_volume_limit__c =2;
                tieringObj.ECM_Tier_3_rate_per_UoM__c =3;
                tieringObj.ECM_Contract_Item__c =newcontractitem.Id;
            insert tieringObj;
            system.debug(LoggingLevel.Debug,'userBusinessRole id==> '+[select id from User_Business_Role__c]);
            
            //ECM_CreateContractController.getContractTypes();
            ECM_CreateContractController.createContract(objContract, outletAccount.Id, contractRecordTypeId, testterritory.Id, contractType.Id,acclist);
           
            Test.startTest();
            // ECM_CreateContractController.getContract(objContract2.Id);
            // ECM_CreateContractController.getContractTypesOutlet(outletAccount.Id);
            
            ECM_CreateContractController.userAndContractInfo info = new ECM_CreateContractController.userAndContractInfo();
            info = ECM_CreateContractController.getContract(objContract.Id);
            Contract conRec = info.contractInfo.con;
            ECM_CreateContractController.getOutletTapsTable(conRec);
            
        }   
    } 
    
    @isTest 
    public static void testgetPDFGuide()
    {
        Id recordTypeId= Schema.Sobjecttype.Contract.getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Id countryId = EDGE_UtilityTestClass.setupCountry('NIR');
        Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(countryId);
        mktSetting.Enable_Agreement_Guide__c=true;
        insert mktSetting;
        ContentVersion conVerRec = EDGE_UtilityTestClass.gerConVerRec('Outle1234.jpeg');
        conVerRec.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Contracts').getRecordTypeId();
        conVerRec.Content_Type__c = 'Outlet';
        conVerRec.Title = 'OutletRes.jpeg';
        insert conVerRec;
        System.assert(conVerRec.Id != null,'outletAccount should not be null');            
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        System.assertEquals(documents.size(), 1,'documents should match');     
        ContentDocumentLink conDocLnkRec = EDGE_UtilityTestClass.getConDocLink (mktSetting.Id,documents[0].Id);
        insert conDocLnkRec;
        System.assert(conDocLnkRec.Id != null,'conDocLnkRec should not be null');
        ECM_CreateContractController.getPDFGuide(recordTypeId,mktSetting.Id);
        
    }
}