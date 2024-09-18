/*
@Name: ECM_ContractCloneButtonCtrlTest
@Description: This Class is test class for ECM_ContractCloneButtonCtrl class.
@History                                                                                                                       
VERSION			AUTHOR						DATE					DETAIL
1.0			Anivesh Muppa										Initial Development
2.0			Saurav Prasad				17/01/2022				ECM-5112 - Mapping Child Contract from Parent Contract_SFDC_GLO	
3.0			Saurav Prasad &				11/02/2022				ECM-5020 : Screen 3 Contract Cloning_Validations_SFDC_AU
4.0          Suvendu Roy			    11/02/2022				ECM-5158 : Screen 3 Contract Recalling_Validations_SFDC_AU
*/
@isTest
public class ECM_ContractCloneButtonCtrlTest {
    /*static testmethod void testmethod1(){
ECM_ContractCloneButtonCtrl.getCloneScreenInfo();
ECM_ContractCloneButtonCtrl.processCloneScreenInfo(Null);
}*/
    
    @isTest
    public static void getCloneAccessTest(){
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Profile prof = [select id from profile where name =: 'Sales Representative'];
        User usrmngr = new User();
        usrmngr.firstName = 'testManager';
        usrmngr.lastName = 't2';
        usrmngr.profileId = prof.id;        
        usrmngr.email = 'EUtest.Mamager@test.com';
        usrmngr.Username ='EUtestcmMngr@test.com';
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
        usr.email = 'EUtest@test.com';
        usr.Username ='EUtestcm123@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='ES';
        usr.ManagerId = usrmngr.Id;
        usr.DelegatedApproverId = usrmngr.Id;
        insert usr;
        
        system.debug(LoggingLevel.debug,'(USer==>  '+usr);
        user newuser = EDGE_UtilityTestClass.runAsUser('Testabc','System Administrator');
        insert newuser;
        //Spain Data
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES'); 
        
        Territory__c testterritory=New Territory__c();
        testterritory.Name='Testterriotory';
        testterritory.Territory_Type__c='Sales';
        testterritory.Country__c= geographyId;
        testterritory.Status__c='Active';
        testterritory.Primary_Sales_Rep__c = usr.id;
        insert testterritory;
        
        
        Market_Setting__c mktSettingObj =EDGE_UtilityTestClass.getMarketSetting(geographyId);
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
        
        /*  String PickupRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId(); 
Pick_Up_Options__c banner1= new Pick_Up_Options__c();
banner1.Name='Range[ES]';
banner1.Geography__c=geographyId1;
banner1.RecordTypeId=PickupRecordTypeId;
banner1.Type__c ='Local-Segment1';
insert banner1;*/
        
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Person_Responsible__c= usr.Id;
        outletAccount.OwnerId = usr.Id;
        outletAccount.SAP_Sold_to__c='3984021';
        outletAccount.VAT_Number__c='TAXID123';
        outletAccount.ECM_Legal_Name__c='Legal';
        outletAccount.Email_for_contracts_payments__c='manikandan.t@diageo.com.test';
        outletAccount.Country__c = geographyId;
        outletAccount.IsOperator__c=true;
        insert outletAccount;
        
        Account distAccObj1 = EDGE_UtilityTestClass.getDistriAccRec();
        distAccObj1.Global_Channel__c = 'Off Trade';
        distAccObj1.Global_Sub_Channel__c ='Retailer';
        distAccObj1.Global_Segment__c = 'Discounter';
        distAccObj1.Global_Sub_Segment__c = 'Modern Discounter';
        insert distAccObj1;
        
        Supplier_Outlet__c supplierOutlet = EDGE_UtilityTestClass.suppOutletRec(outletAccount.Id,distAccObj1.Id );
        insert supplierOutlet;
        
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        insert territory;
        
        Territory_Hierarchy__c hirarchy= ECM_UtilityTestClass.createhirarchy(geographyId);
        hirarchy.recordtypeId=Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Region').getRecordTypeId();
        insert hirarchy;
        
        territory.Primary_Sales_Rep__c = usr.id;
        territory.Country__c= geographyId;
        territory.Region__c=hirarchy.Id;
        update territory;        
        
        ECM_Payment_Frequency__c paymFreq = new ECM_Payment_Frequency__c();
        paymFreq.ECM_Type__c='Monthly';
        paymFreq.ECM_Other_Investment__c=true;
        paymFreq.ECM_Volume_target__c=true;
        paymFreq.ECM_Number_of_months_for_recurrence__c='20';
        paymFreq.ECM_From_When_Starts__c='Calendar Year';
        paymFreq.ECM_Geography__c=geographyId;
        insert paymFreq;
        
        ECM_Contract_Type__c contractTypeEU=new ECM_Contract_Type__c();
        contractTypeEU.Name='Promotional';
        contractTypeEU.Geography__c=geographyId;
        contractTypeEU.ECM_Abbreviation__c='POM';
        contractTypeEU.ECM_Allow_Multiple_Agreements__c=TRUE;
        contractTypeEU.Volume_UoM_for_Spirits__c='BTL';
        contractTypeEU.ECM_Enable_Cloning__c=TRUE;
        contractTypeEU.ECM_Ad_Hoc__c=TRUE;
        contractTypeEU.ECM_Min_Duration__c=2;
        contractTypeEU.ECM_Aggrement_Duration__c='Days';
        contractTypeEU.ECM_Max_Duration__c=38;
        contractTypeEU.ECM_Visible__c=true;
        contractTypeEU.ECM_Allow_Independent__c=true;
        contractTypeEU.ECM_Volume_UoM_for_Beer__c = 'Not Applicable';
        contractTypeEU.ECM_Automatic_approval_amount_threshold__c=30.00;
        contractTypeEU.ECM_Screen_3_field_configuration__c='Product Name;Volume Target;Tiering';
        contractTypeEU.ECM_Volume_target__c =true;
        contractTypeEU.ECM_Volume_UoM_for_RTD__c = 'Not Applicable';
        contractTypeEU.ECM_Volume_UoM_for_Draught_Cocktails__c = 'Not Applicable';
        insert contractTypeEU;
        
        
        ECM_Contract_Type__c contractTypeEU1=new ECM_Contract_Type__c();
        contractTypeEU1.Name='Promotional';
        contractTypeEU1.Geography__c=geographyId;
        contractTypeEU1.ECM_Abbreviation__c='POM';
        contractTypeEU1.ECM_Allow_Multiple_Agreements__c=false;
        contractTypeEU1.Volume_UoM_for_Spirits__c='BTL';
        contractTypeEU1.ECM_Enable_Cloning__c=TRUE;
        contractTypeEU1.ECM_Ad_Hoc__c=TRUE;
        contractTypeEU1.ECM_Min_Duration__c=2;
        contractTypeEU1.ECM_Aggrement_Duration__c='Days';
        contractTypeEU1.ECM_Max_Duration__c=38;
        contractTypeEU1.ECM_Visible__c=true;
        contractTypeEU1.ECM_Allow_Independent__c=true;
        contractTypeEU1.ECM_Volume_UoM_for_Beer__c = 'Not Applicable';
        contractTypeEU1.ECM_Automatic_approval_amount_threshold__c=30.00;
        contractTypeEU1.ECM_Screen_3_field_configuration__c='Product Name;Volume Target;';
        contractTypeEU1.ECM_Volume_UoM_for_RTD__c = 'Not Applicable';
        contractTypeEU1.ECM_Volume_UoM_for_Draught_Cocktails__c = 'Not Applicable';
        insert contractTypeEU1;
        
        
        Contract objContractEU = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContractEU.Status = 'Draft';
        objContractEU.Contract_End_Date__c = System.today()+29;
        objContractEU.AccountId=outletAccount.Id;
        objContractEU.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContractEU.ECM_Territory__c=testterritory.Id;
        objContractEU.ECM_Agreement_Type__c=contractTypeEU.Id;
        objContractEU.recordTypeId=contractRecordTypeId;
        objContractEU.ECM_Channel__c='On-Premise';
        objContractEU.ECM_Banner__c=banner.Id;
        objContractEU.StartDate = system.today();
        objContractEU.Contract_End_Date__c = system.today()+360;
        objContractEU.ECM_Amended__c = true ;
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
        objContractEU1.ECM_Primary_Beer_Distributor__c = distAccObj1.id;
        objContractEU1.ECM_Primary_Spirit_Distributor__c = distAccObj1.id;
        objContractEU1.ECM_Secondary_Spirit_Distributor__c = distAccObj1.id;
        objContractEU1.StartDate = system.today()+150;
        objContractEU1.Contract_End_Date__c = system.today()+360;
        objContractEU1.ECM_Agreement_Type__c=contractTypeEU.Id;
        objContractEU1.ECM_Amended__c = true ; //ECM-6223
        insert objContractEU1;
        objContractEU1.Status = 'Active';
        update objContractEU1;
        
        objContractEU.ECM_Parent_Contract__c = objContractEU1.Id;
        objContractEU.ECM_Cloned__c = true;
        
        
        Contract objContractEU2 = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContractEU2.Status = 'Draft';
        objContractEU2.Contract_End_Date__c = System.today()+29;
        objContractEU2.AccountId=outletAccount.Id;
        objContractEU2.ECM_Territory__c=testterritory.Id;
        //objContractEU1.ECM_Contract_Type__c=contractTypeEU.Id;
        objContractEU2.recordTypeId=contractRecordTypeId;
        objContractEU2.ECM_Channel__c='On-Premise';
        objContractEU2.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContractEU2.StartDate = system.today()+150;
        objContractEU2.Contract_End_Date__c = system.today()+360;
        objContractEU2.ECM_Agreement_Type__c=contractTypeEU.Id;
        insert objContractEU2;
        
        
        Contract objContractEU3 = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContractEU3.Status = 'Draft';
        objContractEU3.Contract_End_Date__c = System.today()+29;
        objContractEU3.AccountId=outletAccount.Id;
        objContractEU3.ECM_Territory__c=testterritory.Id;
        objContractEU3.recordTypeId=contractRecordTypeId;
        objContractEU3.ECM_Channel__c='On-Premise';
        objContractEU3.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContractEU3.StartDate = system.today()+150;
        objContractEU3.Contract_End_Date__c = system.today()+360;
        objContractEU3.ECM_Agreement_Type__c=contractTypeEU1.Id;
        insert objContractEU3;
        
        System.assert(objContractEU1.Id!=null,'Contract Id is Null');
        
        List<ECM_Clone_Contract_ScreenInfo__mdt> cloneLablesList = new List<ECM_Clone_Contract_ScreenInfo__mdt>();
        cloneLablesList = [SELECT ScreenName__c,Field_Name__c,Display_order__c,
                           Custom_Data_Type__c,Data_Type__c,Required__c,
                           Field_API_Name__c,Validation_Messages__c
                           FROM ECM_Clone_Contract_ScreenInfo__mdt 
                           WHERE Country_Code__c='ES' ORDER BY Display_order__c limit 1];
        
        List < contract > conrecordWithApprovedorActive = new List < contract > ();
        conrecordWithApprovedorActive = [select id, accountid, status, StartDate, Contract_End_Date__c from contract where ECM_Agreement_Type__c =: objContractEU.ECM_Agreement_Type__c and recordtypeid =:contractRecordTypeId and id !=: objContractEU.id and accountid =: outletAccount.id and(status =: 'Active'or status =: 'In Approval process')];
        List < contract > conrecordWithDraft = new List < contract > ();
        conrecordWithDraft = [select id, accountid, status, StartDate, Contract_End_Date__c from contract where ECM_Agreement_Type__c =: objContractEU.ECM_Agreement_Type__c and accountid =: outletAccount.id and id !=: objContractEU.id and recordtypeid =:contractRecordTypeId and status =: 'Draft'];
        
        
        //Create territory budget
        Territory_Budget__c terriBudget1 = ECM_UtilityTestClass.createTerritoryBudget(territory.Id, hirarchy.Id);
        terriBudget1.ECM_Budget_Type__c=budjectEU.Id;
        insert terriBudget1;
        //create sales Driver
        Id salesAgreeRecTypeId = Schema.SObjectType.ECM_Sales_Agreement__c.getRecordTypeInfosByName().get('Sales Agreement').getRecordTypeId();
        Id salesDriverRecTypeId = Schema.SObjectType.ECM_Sales_Driver__c.getRecordTypeInfosByName().get('Investment').getRecordTypeId();
        Id salesDrivItemRecTypeId = Schema.SObjectType.ECM_Sales_Driver_Item__c.getRecordTypeInfosByName().get('Sales Driver').getRecordTypeId();
        Id salesDrivItemDetailRecTypeId = Schema.SObjectType.ECM_Sales_Driver_Item_Detail__c.getRecordTypeInfosByName().get('Sales Driver').getRecordTypeId();
        ECM_Sales_Driver__c salesDriver = ECM_UtilityTestClass.getSalesdriver(terriBudget1.Id,geographyId);
        salesDriver.ECM_Budget_Type__c=budjectEU.Id;
        salesDriver.RecordTypeId = salesDriverRecTypeId;
        insert salesDriver;
        //create sales Driver Item
        ECM_Sales_Driver_Item__c esCDI = new ECM_Sales_Driver_Item__c(Contract__c=objContractEU1.Id,ECM_Sales_Driver__c=SalesDriver.Id,RecordTypeId=salesDrivItemRecTypeId);
        insert esCDI;
        ECM_Sales_Agreement__c salesAgg = ECM_UtilityTestClass.createsalesAggrement(contractTypeEU.Id,SalesDriver.Id);
        salesAgg.RecordTypeId=salesAgreeRecTypeId;
        insert salesAgg;
        //create product
        Product__c product = ECM_UtilityTestClass.createProduct(geographyId,'Test');
        product.Product_Full_Name__c='Test';
        insert product;
        //create product
        Product__c product1 = ECM_UtilityTestClass.createProduct(geographyId,'Test 2');
        product1.Product_Full_Name__c='Test 2';
        insert product1;
        //create product uom
        Product_UOM__c prdtUOM = ECM_UtilityTestClass.createProductUOM(product.Id);
        prdtUOM.Unique_ID__c='Test123';
        insert prdtUOM;
        //create product uom
        Product_UOM__c prdtUOM1 = ECM_UtilityTestClass.createProductUOM(product1.Id);
        prdtUOM1.Unique_ID__c='Test1234';
        insert prdtUOM1;
        //create marketassort product 
        Market_Assortment_Product__c marketassort = ECM_UtilityTestClass.createMarketAssortmentProduct(product.Id,geographyId);
        marketassort.OwnerId = usr.Id;
        insert marketassort;
        //create marketassort product 
        Market_Assortment_Product__c marketassort1 = ECM_UtilityTestClass.createMarketAssortmentProduct(product1.Id,geographyId);
        marketassort1.OwnerId = usr.Id;
        insert marketassort1;
        //create Product_Agreement
        ECM_Product_Agreement__c productagg = ECM_UtilityTestClass.createProductAgreement(contractTypeEU.Id,Marketassort.Id);
        insert productagg;
        //create Product_Agreement
        ECM_Product_Agreement__c productagg1 = ECM_UtilityTestClass.createProductAgreement(contractTypeEU.Id,Marketassort1.Id);
        insert productagg1;
        //create Contract_Item
        ECM_Contract_Item__c newcontractitem= ECM_UtilityTestClass.createcontractitem(objContractEU1.Id,Marketassort.id);
        newcontractitem.ECM_UoM__c = '1';
        newcontractitem.ECM_Lead_Brand__c = TRUE;
        newcontractitem.ECM_Volume_Target_per_PF__c = 10.5;
        newcontractitem.ECM_CTD_A_P_Investment__c = 10;  //ECM-6223
        newcontractitem.ECM_CTD_Trade_Lump_Sum__c = 20;
        newcontractitem.ECM_CTD_Overall_Investment__c = 30;
        
        
        
        insert newcontractitem;
        //create tiering
        ECM_Tiering__c tier;
        tier = ECM_CreateContractController.createTieringRecord(newcontractitem.Id, 10, 10, 20, 20, 30, 30);
        //create Contract_Item
        ECM_Contract_Item__c newcontractitem1= ECM_UtilityTestClass.createcontractitem(objContractEU1.Id,Marketassort1.id);
        newcontractitem1.ECM_UoM__c = '1';
        newcontractitem1.ECM_Lead_Brand__c = false;
        newcontractitem1.ECM_Volume_Target_per_PF__c = 5.5;
        newcontractitem1.ECM_CTD_A_P_Investment__c = 10;  //ECM-6223
        newcontractitem1.ECM_CTD_Trade_Lump_Sum__c = 20;
        newcontractitem1.ECM_CTD_Overall_Investment__c = 30;
        
        insert newcontractitem1;
        
        
        
        
        //create sales driver item
        ECM_Sales_Driver_Item_Detail__c salesDetails = ECM_UtilityTestClass.insertSalesdriverDetails(ESCDI, newcontractitem);
        salesDetails.RecordTypeId = salesDrivItemDetailRecTypeId;
        insert salesDetails;
        ECM_Sales_Driver_Item_Detail__c salesDetails1 = ECM_UtilityTestClass.insertSalesdriverDetails(ESCDI, newcontractitem1);
        salesDetails1.RecordTypeId = salesDrivItemDetailRecTypeId;
        insert salesDetails1;
        
        test.starttest();
        ECM_ContractCloneButtonCtrl.CustomCloneWrapper cWrap = new ECM_ContractCloneButtonCtrl.CustomCloneWrapper();
        Map<String,String> jsonMap = new Map<String,String>();
        
        cWrap = ECM_ContractCloneButtonCtrl.getCloneButtonAccess(objContractEU.Id);
        ECM_ContractCloneButtonCtrl.validation_for_Agreement_Type(objContractEU,outletAccount.id,contractRecordTypeId);
        for(ECM_Clone_Contract_ScreenInfo__mdt metaData : cWrap.listOfCustomMetaData){
            jsonMap.put(metaData.Field_Name__c,String.valueOf(true));
        }
        jsonMap.put('isAus',String.valueOf(cWrap.isAus));
        string jsonstring = JSON.serialize(jsonMap);
        ECM_ContractCloneButtonCtrl.processCloneScreenInfo(objContractEU,outletAccount.id,contractRecordTypeId,testterritory.Id,contractTypeEU.Id,new List<Account>{outletAccount},jsonstring);
        test.stoptest();
        
    }
    
    @isTest
    public static void getCloneAccessTestAU(){
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Profile prof = [select id from profile where name =: 'Sales Representative'];
        User usrmngrAU = new User();
        usrmngrAU.firstName = 'testManager';
        usrmngrAU.lastName = 't2';
        usrmngrAU.profileId = prof.id;        
        usrmngrAU.email = 'test.Mamager@test.com';
        usrmngrAU.Username ='AUtestcmMngr@test.com';
        usrmngrAU.Alias='test';
        usrmngrAU.Timezonesidkey='Australia/Sydney';
        usrmngrAU.LocaleSidKey='en_US';
        usrmngrAU.LanguageLocaleKey='en_US';
        usrmngrAU.EmailEncodingKey='UTF-8';
        usrmngrAU.Available_Countries__c='AU';
        insert usrmngrAU;
        User usrAU = new User();
        usrAU.firstName = 'test1';
        usrAU.lastName = 'test2';
        usrAU.profileId = prof.id;        
        usrAU.email = 'test@test.com';
        usrAU.Username ='AUtestcm123@test.com';
        usrAU.Alias='test';
        usrAU.Timezonesidkey='Australia/Sydney';
        usrAU.LocaleSidKey='en_US';
        usrAU.LanguageLocaleKey='en_US';
        usrAU.EmailEncodingKey='UTF-8';
        usrAU.Available_Countries__c='AU';
        usrAU.ManagerId = usrmngrAU.Id;
        usrAU.DelegatedApproverId = usrmngrAU.Id;
        insert usrAU;
        
        system.debug(LoggingLevel.debug,'(USer Australia ==>  '+usrAU);
        
        
        
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        
        Territory__c testterritory=New Territory__c();
        testterritory.Name='Testterriotory';
        testterritory.Territory_Type__c='Sales';
        testterritory.Country__c= geographyId;
        testterritory.Status__c='Active';
        testterritory.Primary_Sales_Rep__c = usrAU.id;
        insert testterritory;
        
        
        Market_Setting__c mktSettingObj =EDGE_UtilityTestClass.getMarketSetting(geographyId);
        mktSettingObj.ECM_Contract_Header_Details__c='ECM_Contract_Owner__c;ECM_Territory__r.Name;Account.ECM_Legal_Name__c;Account.Name;ECM_Agreement_Type__r.Name;StartDate;Contract_End_Date__c;ContractNumber;Name';
        mktSettingObj.ECM_Investment_Summary_KPIS__c='ECM_Total_Volume_Target_Spirits__c;ECM_Total_Volume_Target_Beers__c;ECM_Incremental_Volume_Spirits__c;ECM_Incremental_Volume_Beers__c;ECM_Total_trade_investment_Beers__c;ECM_Total_A_P_Investment_Spirits__c;ECM_Incremental_GP__c;ECM_Incremental_GP_Beers__c';
        mktSettingObj.ECM_Category_Split_KPIS__c='ECM_NSV_reserve_share__c;ECM_NSV_premium_core_share__c;ECM_GP_reserve_share__c;ECM_GP_innovation_share__c;ECM_GM_reserve_share__c;ECM_GM_innovation_share__c;ECM_GM_premium_core_share__c;ECM_TV_reserve_share__c;ECM_TV_premium_core_share__c;ECM_IV_reserve_share__c;ECM_IV_innovation_share__c;ECM_IV_premium_core_share__c';
        mktSettingObj.ECM_Product_Investment_Details__c='ECM_Retro_investment__c;ECM_Trade_Investments__c;ECM_AnP_investment__c;ECM_Gross_margin__c;ECM_Total_GP_EU__c;ECM_Generated_NSV_EU__c;ECM_NSV_After_Investment__c;ECM_Incremental_GP_after_Investment__c;Tiers;ECM_UoM__c;ECM_Baseline_volume__c;ECM_Volume__c;ECM_Incremental_Volume__c;ECM_CAAP_Total__c;ECM_Product_growth_driver__c';
        mktSettingObj.ECM_Sales_Drivers_Details__c='ECM_Investement_Description__c;ECM_Budget_Type__c;ECM_Payment_Frequency__r.ECM_Type__c;Payment dates;ECM_Total_Investment_Amount__c;ECM_Prepayment__c;ECM_Sales_Driver_Name__c';
        mktSettingObj.ECM_Contract_Creation_Page__c='Australia';
        mktSettingObj.ECM_Contract_Management_Market__c=true;
        mktSettingObj.ECM_SAP_Order_Type__c='YPCR';        
        mktSettingObj.ECM_Payment_Management_Email__c='test@test22.com';
        mktSettingObj.ECM_Email_to_Send_Payment_CSV__c='test@test23.com';
        insert mktSettingObj;
        
        
        Account outletAccountAU = EDGE_UtilityTestClass.getOutletRecord();
        outletAccountAU.Person_Responsible__c= usrAU.Id;
        outletAccountAU.OwnerId = usrAU.Id;
        outletAccountAU.SAP_Sold_to__c='3984099999';
        outletAccountAU.VAT_Number__c='TAXID19000';
        outletAccountAU.ECM_Legal_Name__c='Legal099';
        outletAccountAU.Email_for_contracts_payments__c='test78.t@diageo.com.test';
        outletAccountAU.Country__c = geographyId;
        outletAccountAU.IsOperator__c=true;
        insert outletAccountAU;
        
        ECM_Payment_Frequency__c paymFreq = new ECM_Payment_Frequency__c();
        paymFreq.ECM_Type__c='Monthly';
        paymFreq.ECM_Other_Investment__c=true;
        paymFreq.ECM_Volume_target__c=true;
        paymFreq.ECM_Number_of_months_for_recurrence__c='20';
        paymFreq.ECM_From_When_Starts__c='Calendar Year';
        paymFreq.ECM_Geography__c=geographyId;
        insert paymFreq;
        
        ECM_Contract_Type__c contractTypeAU=new ECM_Contract_Type__c();
        contractTypeAU.Name='Promotional';
        contractTypeAU.Geography__c=geographyId;
        contractTypeAU.ECM_Abbreviation__c='POM';
        contractTypeAU.ECM_Allow_Multiple_Agreements__c=TRUE;
        contractTypeAU.Volume_UoM_for_Spirits__c='BTL';
        contractTypeAU.ECM_Enable_Cloning__c=TRUE;
        contractTypeAU.ECM_Ad_Hoc__c=TRUE;
        contractTypeAU.ECM_Min_Duration__c=2;
        contractTypeAU.ECM_Aggrement_Duration__c='Days';
        contractTypeAU.ECM_Max_Duration__c=38;
        contractTypeAU.ECM_Visible__c=true;
        contractTypeAU.ECM_Allow_Independent__c=true;
        contractTypeAU.ECM_Volume_UoM_for_Beer__c = 'Not Applicable';
        contractTypeAU.ECM_Automatic_approval_amount_threshold__c=30.00;
        contractTypeAU.ECM_Screen_3_field_configuration__c='Product Name;Volume Target;';
        contractTypeAU.ECM_Volume_target__c =true;
        contractTypeAU.ECM_Volume_UoM_for_RTD__c = 'Not Applicable';
        contractTypeAU.ECM_Volume_UoM_for_Draught_Cocktails__c = 'Not Applicable';
        insert contractTypeAU;
        
        Contract objContract = EDGE_UtilityTestClass.getContract(outletAccountAU.Id, contractRecordTypeId);
        objContract.Status = 'Draft';
        objContract.Contract_End_Date__c = System.today()+29;
        objContract.AccountId=outletAccountAU.Id;
        objContract.ECM_Territory__c=testterritory.Id;
        objContract.recordTypeId=contractRecordTypeId;
        objContract.ECM_Channel__c='On-Premise';
        objContract.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContract.StartDate = system.today()+150;
        objContract.Contract_End_Date__c = system.today()+360;
        objContract.ECM_Agreement_Type__c=contractTypeAU.Id;
        insert objContract;
        
        Contract objContractAU = EDGE_UtilityTestClass.getContract(outletAccountAU.Id, contractRecordTypeId);
        objContractAU.Status = 'Draft';
        objContractAU.Contract_End_Date__c = System.today()+29;
        objContractAU.AccountId=outletAccountAU.Id;
        objContractAU.ECM_Territory__c=testterritory.Id;
        objContractAU.recordTypeId=contractRecordTypeId;
        objContractAU.ECM_Channel__c='On-Premise';
        objContractAU.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContractAU.StartDate = system.today()+150;
        objContractAU.Contract_End_Date__c = system.today()+360;
        objContractAU.ECM_Agreement_Type__c=contractTypeAU.Id;
        insert objContractAU;
        objContractAU.Status = 'Active';
        update objContractAU;
        
        objContract.ECM_Parent_Contract__c = objContractAU.Id;
        objContract.ECM_Cloned__c = true;
        System.assert(objContractAU.Id!=null,'Contract Id is Null');
        
        ECM_Payment_Agreement__c paymentAggObj = ECM_UtilityTestClass.createPaymentAgreement(contractTypeAU.Id,paymFreq.Id);
        Insert paymentAggObj;
        //create product
        Product__c product = ECM_UtilityTestClass.createProduct(geographyId,'Test');
        product.Product_Full_Name__c='Test';
        insert product;
        //create product
        Product__c product1 = ECM_UtilityTestClass.createProduct(geographyId,'Test 2');
        product1.Product_Full_Name__c='Test 2';
        insert product1;
        
        //create marketassort product 
        Market_Assortment_Product__c marketassort = ECM_UtilityTestClass.createMarketAssortmentProduct(product.Id,geographyId);
        marketassort.OwnerId = usrAU.Id;
        insert marketassort;
        //create marketassort product 
        Market_Assortment_Product__c marketassort1 = ECM_UtilityTestClass.createMarketAssortmentProduct(product1.Id,geographyId);
        marketassort1.OwnerId = usrAU.Id;
        insert marketassort1;
        
        //create Product_Agreement
        ECM_Product_Agreement__c productagg = ECM_UtilityTestClass.createProductAgreement(contractTypeAU.Id,Marketassort.Id);
        insert productagg;
        //create Product_Agreement
        ECM_Product_Agreement__c productagg1 = ECM_UtilityTestClass.createProductAgreement(contractTypeAU.Id,Marketassort1.Id);
        insert productagg1;
        
        //create Contract_Item
        ECM_Contract_Item__c newcontractitemAU= ECM_UtilityTestClass.createcontractitem(objContractAU.Id,Marketassort.id);
        newcontractitemAU.ECM_First_Pour__c = TRUE;
        newcontractitemAU.ECM_Mandatory_Back_Bar__c = TRUE;
        newcontractitemAU.ECM_Volume_hybrid_original__c = 10.5;
        newcontractitemAU.ECM_MAT_override__c = 55;
        newcontractitemAU.ECM_TSDD_Override__c = 55;
        newcontractitemAU.ECM_TotalSKU_SpecificRebate__c = 60;
        newcontractitemAU.ECM_FinalLUC_Target__c = 100;
        insert newcontractitemAU;
        //create Contract_Item
        ECM_Contract_Item__c newcontractitemAU1= ECM_UtilityTestClass.createcontractitem(objContractAU.Id,Marketassort1.id);
        newcontractitemAU1.ECM_First_Pour__c = false;
        newcontractitemAU1.ECM_Mandatory_Back_Bar__c = TRUE;
        newcontractitemAU1.ECM_Volume_hybrid_original__c = 11.5;
        newcontractitemAU1.ECM_MAT_override__c = 57;
        newcontractitemAU1.ECM_TSDD_Override__c = 45;
        newcontractitemAU1.ECM_TotalSKU_SpecificRebate__c = 70;
        newcontractitemAU1.ECM_FinalLUC_Target__c = 90;
        insert newcontractitemAU1;
        
        test.starttest();
        ECM_ContractCloneButtonCtrl.CustomCloneWrapper cWrap = new ECM_ContractCloneButtonCtrl.CustomCloneWrapper();
        Map<String,String> jsonMap = new Map<String,String>();
        
        cWrap = ECM_ContractCloneButtonCtrl.getCloneButtonAccess(objContract.Id);
        ECM_ContractCloneButtonCtrl.validation_for_Agreement_Type(objContract,outletAccountAU.id,contractRecordTypeId);
        for(ECM_Clone_Contract_ScreenInfo__mdt metaData : cWrap.listOfCustomMetaData){
            jsonMap.put(metaData.Field_Name__c,String.valueOf(true));
        }
        jsonMap.put('isAus',String.valueOf(cWrap.isAus));
        string jsonstring = JSON.serialize(jsonMap);
        ECM_ContractCloneButtonCtrl.processCloneScreenInfo(objContract,outletAccountAU.id,contractRecordTypeId,testterritory.Id,contractTypeAU.Id,new List<Account>{outletAccountAu},jsonstring);
        test.stoptest();
        
    }
    
}