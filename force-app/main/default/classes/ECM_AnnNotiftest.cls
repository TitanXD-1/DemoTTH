/*
@Name: ECM_ContractAnniversaryNotiMailTest
@Purpose: This test class is for ECM_ContractAnniversaryNotificationBatch and ECM_ContractAnniversaryNotiMailHelper

@History                                                                                                                     
VERSION    AUTHOR        		DATE              DETAIL
1.0        Priya Soni           18/07/2022        Initial Development (ECM-5903)
1.1        Anand Uppalapati     16/09/2022        ECM-6025 Anniversary email to Sales Rep/Customer_SFDC_EU
*/
@isTest
public class ECM_AnnNotiftest {
    @isTest
    public static void sendNotificationIETest(){
        Test.startTest();
        createDataIE();
        Market_Batch_Setting__mdt batchSetting = [SELECT MasterLabel, Batch_Class__c, Country_Code__c,Market_Order__c, 
                                                  Serial_Number__c, Scope__c, Job_Group__c, Region__c 
                                                  FROM Market_Batch_Setting__mdt 
                                                  WHERE Batch_Class__c = 'ECM_ContractAnniversaryNotificationBatch'
                                                  AND Country_Code__c ='IE' ];
        String className = batchSetting.Batch_Class__c;
        System.assert(className!=null,'className should not be null');
        Type t  = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));		
        Test.stopTest();
    }
    
    @isTest
    public static void sendNotificationTestIE2(){
        Test.startTest();
        createDataIE2();
        Market_Batch_Setting__mdt batchSetting = [SELECT MasterLabel, Batch_Class__c, Country_Code__c,Market_Order__c, 
                                                  Serial_Number__c, Scope__c, Job_Group__c, Region__c 
                                                  FROM Market_Batch_Setting__mdt 
                                                  WHERE Batch_Class__c = 'ECM_ContractAnniversaryNotificationBatch'
                                                  AND Country_Code__c ='IE' ];
        String className = batchSetting.Batch_Class__c;
        System.assert(className!=null,'className should not be null');
        Type t  = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));		
        Test.stopTest();
    }
    public static void createDataIE2(){
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        String pickupRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        String type;
        type='Local-Segment1';
        
        Id geographyId = EDGE_UtilityTestClass.setupCountry('IE');
        
        Geography__c  marketObj;
        List<Geography__c> marketList = [SELECT Id FROM Geography__c WHERE Name ='Global'];
        if(!marketList.isEmpty()){
            marketObj = EDGE_UtilityTestClass.createGeography('Market');
            marketObj.Name = 'Europe and Turkey';
            marketObj.Code__c = 'EAT2';
            marketObj.Parent_Geography__c = marketList[0].Id;
            insert marketObj;
        }
        
        string recordTypeName;
        recordTypeName = Schema.SObjectType.Geography__c.getRecordTypeInfosByDeveloperName().get('Market').getRecordTypeId();
        
        //user rec
       
        
        User testSysAdminUser = EDGE_UtilityTestClass.runAsUser('SystemAdmin','System Administrator');
        testSysAdminUser.Available_Countries__c = 'IE';
        insert testSysAdminUser; 
        
         user newuser = EDGE_UtilityTestClass.runAsUser('Testabc','Sales Representative');
        newuser.Email = userInfo.getUserEmail();
        newuser.Available_Countries__c ='IE';
        newuser.ManagerId =testSysAdminUser.Id;
        insert newuser;
        
        Territory_Hierarchy__c hirarchy= ECM_UtilityTestClass.createhirarchy(geographyId);
        hirarchy.recordtypeId=Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Activation Territory').getRecordTypeId();
        insert hirarchy; 
        
        //create territory rec
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        territory.Activation_Territory__c = hirarchy.Id;
        insert territory;
        
        Pick_Up_Options__c budjectEU= new Pick_Up_Options__c();
        budjectEU.Name='TI [IE]';
        budjectEU.Geography__c=geographyId;
        budjectEU.RecordTypeId=pickupRecordTypeId;
        insert budjectEU;
        
        //Setting up Required Item for EU Contract: Account - RecordType Outlet
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.country__c = geographyId;
        acc.Sales_Org__c='sale';
        acc.SAP_Sold_to__c='sapsold';
        acc.Email_for_contracts_payments__c = userInfo.getUserEmail();
        acc.Independent_of_Operator__c=true;
        acc.Independent_of_Owner__c=true;
        insert acc;
        
        //product record
        Product__c pdt = ECM_UtilityTestClass.createProduct(geographyId,'Test Product');
        pdt.Product_Full_Name__c = 'Test Product';
        pdt.Category__c = 'Cocktails';
        pdt.Classification__c = 'RTD';
        insert pdt;
        
        //map record
        Market_Assortment_Product__c maPdt = ECM_UtilityTestClass.createMarketAssortmentProduct(pdt.id,geographyId);
        insert maPdt;
        
        
        //contract type rec
        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        contractType.ECM_Volume_UoM_for_RTD__c = 'Not Applicable';
        contractType.ECM_Volume_UoM_for_Draught_Cocktails__c = 'Not Applicable';
        contractType.ECM_Anniversary_Email_to_Customer__c = 'To Contract Owner & Line Mgr';
        insert contractType;
        
        //product agreement Record
        ECM_Product_Agreement__c  pdtAgr = ECM_UtilityTestClass.createProductAgreement(contractType.id,maPdt.id);
        pdtAgr.ECM_Lead_Brand__c = true;
        insert pdtAgr;
        
        //Setting up contract to link with payment summary
        Contract contr = ECM_UtilityTestClass.createContract(acc.id,contractRecordTypeId);  
        contr.Status = 'Draft';
        contr.ECM_Duration__c = 37;
        Date dt = System.today().addMonths(1);
        contr.StartDate = dt.addMonths(-36);
        contr.ECM_Agreement_Type__c = contractType.Id;
        integer months;
        months = Integer.valueOF(contractType.ECM_Expiration_Start_Date_Rule_in_Months__c);
        contr.Contract_End_Date__c = contr.StartDate.addMonths(38);
        contr.ECM_Expiration_Notification_sent__c = false;
        contr.ownerId = newuser.Id;
        insert contr;
        
        contr.Status = 'Active';
        update contr;
        
        
        //createcontractitem
        ECM_Contract_Item__c contractItem = ECM_UtilityTestClass.createcontractitem(contr.id,maPdt.id);
        contractItem.ECM_Lead_Brand__c = true;
        contractItem.ECM_Product__c=maPdt.Id;
        insert contractItem;
        
        
        
        Territory_Budget__c terriBudget1 = ECM_UtilityTestClass.createTerritoryBudget(territory.Id, hirarchy.Id);
        terriBudget1.ECM_Budget_Type__c=budjectEU.Id;
        insert terriBudget1;
        Id salesDriverRecTypeId = Schema.SObjectType.ECM_Sales_Driver__c.getRecordTypeInfosByName().get('Investment').getRecordTypeId();
        Id salesDriverItemRecTypeId = Schema.SObjectType.ECM_Sales_Driver_Item__c.getRecordTypeInfosByName().get('Sales Driver').getRecordTypeId();
        Id salesDriverItemDetailRecTypeId = Schema.SObjectType.ECM_Sales_Driver_Item_Detail__c.getRecordTypeInfosByName().get('Sales Driver').getRecordTypeId();
        
        ECM_Sales_Driver__c salesDriver = ECM_UtilityTestClass.getSalesdriver(terriBudget1.Id,geographyId);
        salesDriver.RecordTypeId = salesDriverRecTypeId;
        salesDriver.ECM_Category__c ='Draught Cocktail';
        insert salesDriver;
        

        
        ECM_Sales_Driver_Item__c eSCDI = new ECM_Sales_Driver_Item__c(Contract__c=contr.Id,ECM_Sales_Driver__c=salesDriver.Id);
        eSCDI.RecordTypeId = salesDriverItemRecTypeId;
        eSCDI.ECM_Total_Investment_Amount__c = 150;
        eSCDI.Contract__c =contr.Id;
        insert eSCDI;
        
        
        
        ECM_Sales_Driver_Item_Detail__c salesDetails1 = ECM_UtilityTestClass.insertSalesdriverDetails(eSCDI, contractItem);
        salesDetails1.Recordtypeid = salesDriverItemDetailRecTypeId;
        salesDetails1.ECM_Investment_Amount__c = 200;
        insert salesDetails1;
        
      
        
        System.runAs(testSysAdminUser){ 
            
            EmailTemplate validEmailTemplate = new EmailTemplate();
            validEmailTemplate.isActive = true;
            validEmailTemplate.Name = 'ECMConAnnivNotifiESDraughtCustomer';
            validEmailTemplate.DeveloperName = 'ECM_ConAnniv_NotifiESDrgtCust';
            validEmailTemplate.TemplateType = 'text';
            validEmailTemplate.FolderId = UserInfo.getUserId();
            
            insert validEmailTemplate;
        }
    }
    public static void createDataIE(){
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        String pickupRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        String type;
        type='Local-Segment1';
        
        Id geographyId = EDGE_UtilityTestClass.setupCountry('IE');
        
        Geography__c  marketObj;
        List<Geography__c> marketList = [SELECT Id FROM Geography__c WHERE Name ='Global'];
        if(!marketList.isEmpty()){
            marketObj = EDGE_UtilityTestClass.createGeography('Market');
            marketObj.Name = 'Europe and Turkey';
            marketObj.Code__c = 'EAT2';
            marketObj.Parent_Geography__c = marketList[0].Id;
            insert marketObj;
        }
        
        string recordTypeName;
        recordTypeName = Schema.SObjectType.Geography__c.getRecordTypeInfosByDeveloperName().get('Market').getRecordTypeId();
        
        //user rec
        user newuser = EDGE_UtilityTestClass.runAsUser('Testabc','Sales Representative');
        newuser.Email = userInfo.getUserEmail();
        newuser.Available_Countries__c ='IE';
        insert newuser;
        
        User testSysAdminUser = EDGE_UtilityTestClass.runAsUser('SystemAdmin','System Administrator');
        testSysAdminUser.Available_Countries__c = 'IE';
        insert testSysAdminUser; 
        
        Territory_Hierarchy__c hirarchy= ECM_UtilityTestClass.createhirarchy(geographyId);
        hirarchy.recordtypeId=Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Activation Territory').getRecordTypeId();
        insert hirarchy; 
        
        //create territory rec
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        territory.Activation_Territory__c = hirarchy.Id;
        insert territory;
        
        Pick_Up_Options__c budjectEU= new Pick_Up_Options__c();
        budjectEU.Name='TI [IE]';
        budjectEU.Geography__c=geographyId;
        budjectEU.RecordTypeId=pickupRecordTypeId;
        insert budjectEU;
        
        //Setting up Required Item for EU Contract: Account - RecordType Outlet
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.country__c = geographyId;
        acc.Sales_Org__c='sale';
        acc.SAP_Sold_to__c='sapsold';
        acc.Email_for_contracts_payments__c = userInfo.getUserEmail();
        acc.Independent_of_Operator__c=true;
        acc.Independent_of_Owner__c=true;
        insert acc;
        
        //product record
        Product__c pdt = ECM_UtilityTestClass.createProduct(geographyId,'Test Product');
        pdt.Product_Full_Name__c = 'Test Product';
        pdt.Category__c = 'Cocktails';
        pdt.Classification__c = 'RTD';
        insert pdt;
        
        //map record
        Market_Assortment_Product__c maPdt = ECM_UtilityTestClass.createMarketAssortmentProduct(pdt.id,geographyId);
        insert maPdt;
        
        
        //contract type rec
        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        contractType.ECM_Volume_UoM_for_RTD__c = 'Not Applicable';
        contractType.ECM_Volume_UoM_for_Draught_Cocktails__c = 'Not Applicable';
        contractType.ECM_Anniversary_Email_to_Customer__c = 'To Customer';
        insert contractType;
        
        //product agreement Record
        ECM_Product_Agreement__c  pdtAgr = ECM_UtilityTestClass.createProductAgreement(contractType.id,maPdt.id);
        pdtAgr.ECM_Lead_Brand__c = true;
        insert pdtAgr;
        
        //Setting up contract to link with payment summary
        Contract contr = ECM_UtilityTestClass.createContract(acc.id,contractRecordTypeId);  
        contr.Status = 'Draft';
        contr.ECM_Duration__c = 37;
        Date dt = System.today().addMonths(1);
        contr.StartDate = dt.addMonths(-36);
        contr.ECM_Agreement_Type__c = contractType.Id;
        integer months;
        months = Integer.valueOF(contractType.ECM_Expiration_Start_Date_Rule_in_Months__c);
        contr.Contract_End_Date__c = contr.StartDate.addMonths(38);
        contr.ECM_Expiration_Notification_sent__c = false;
        contr.ownerId = newuser.Id;
        insert contr;
        
        contr.Status = 'Active';
        update contr;
        
        
        //createcontractitem
        ECM_Contract_Item__c contractItem = ECM_UtilityTestClass.createcontractitem(contr.id,maPdt.id);
        contractItem.ECM_Lead_Brand__c = true;
        contractItem.ECM_Product__c=maPdt.Id;
        insert contractItem;
        
        
        
        Territory_Budget__c terriBudget1 = ECM_UtilityTestClass.createTerritoryBudget(territory.Id, hirarchy.Id);
        terriBudget1.ECM_Budget_Type__c=budjectEU.Id;
        insert terriBudget1;
        Id salesDriverRecTypeId = Schema.SObjectType.ECM_Sales_Driver__c.getRecordTypeInfosByName().get('Investment').getRecordTypeId();
        Id salesDriverItemRecTypeId = Schema.SObjectType.ECM_Sales_Driver_Item__c.getRecordTypeInfosByName().get('Sales Driver').getRecordTypeId();
        Id salesDriverItemDetailRecTypeId = Schema.SObjectType.ECM_Sales_Driver_Item_Detail__c.getRecordTypeInfosByName().get('Sales Driver').getRecordTypeId();
        
        ECM_Sales_Driver__c salesDriver = ECM_UtilityTestClass.getSalesdriver(terriBudget1.Id,geographyId);
        salesDriver.RecordTypeId = salesDriverRecTypeId;
        salesDriver.ECM_Category__c ='Draught Cocktail';
        insert salesDriver;
        
        ECM_Sales_Driver__c salesDriver2 = ECM_UtilityTestClass.getSalesdriver(terriBudget1.Id,geographyId);
        salesDriver2.RecordTypeId = salesDriverRecTypeId;
        salesDriver2.ECM_Category__c ='Pouring';
        insert salesDriver2;
        
        ECM_Sales_Driver_Item__c eSCDI = new ECM_Sales_Driver_Item__c(Contract__c=contr.Id,ECM_Sales_Driver__c=salesDriver.Id);
        eSCDI.RecordTypeId = salesDriverItemRecTypeId;
        eSCDI.ECM_Total_Investment_Amount__c = 150;
        eSCDI.Contract__c =contr.Id;
        insert eSCDI;
        
        ECM_Sales_Driver_Item__c eSCDI2 = new ECM_Sales_Driver_Item__c(Contract__c=contr.Id,ECM_Sales_Driver__c=salesDriver2.Id);
        eSCDI2.RecordTypeId = salesDriverItemRecTypeId;
        eSCDI2.ECM_Total_Investment_Amount__c = 150;
        eSCDI2.Contract__c =contr.Id;
        insert eSCDI2;
        
        ECM_Sales_Driver_Item_Detail__c salesDetails1 = ECM_UtilityTestClass.insertSalesdriverDetails(eSCDI, contractItem);
        salesDetails1.Recordtypeid = salesDriverItemDetailRecTypeId;
        salesDetails1.ECM_Investment_Amount__c = 200;
        insert salesDetails1;
        
        ECM_Sales_Driver_Item_Detail__c salesDetails2 = ECM_UtilityTestClass.insertSalesdriverDetails(eSCDI2, contractItem);
        salesDetails2.Recordtypeid = salesDriverItemDetailRecTypeId;
        salesDetails2.ECM_Investment_Amount__c = 200;
        insert salesDetails2;
        
        System.runAs(testSysAdminUser){ 
            
            EmailTemplate validEmailTemplate = new EmailTemplate();
            validEmailTemplate.isActive = true;
            validEmailTemplate.Name = 'ECMConAnnivNotifiIEDraughtCustomer';
            validEmailTemplate.DeveloperName = 'ECM_ConAnniv_NotifiIEDrgtCust';
            validEmailTemplate.TemplateType = 'text';
            validEmailTemplate.FolderId = UserInfo.getUserId();
            
            insert validEmailTemplate;
        }
        
    }
    
    //////
    @isTest
    public static void sendNotificationTest(){
        Test.startTest();
        createData();
        Market_Batch_Setting__mdt batchSetting = [SELECT MasterLabel, Batch_Class__c, Country_Code__c,Market_Order__c, 
                                                  Serial_Number__c, Scope__c, Job_Group__c, Region__c 
                                                  FROM Market_Batch_Setting__mdt 
                                                  WHERE Batch_Class__c = 'ECM_ContractAnniversaryNotificationBatch'
                                                  AND Country_Code__c ='ES' ];
        String className = batchSetting.Batch_Class__c;
        System.assert(className!=null,'className should not be null');
        Type t  = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));		
        Test.stopTest();
    }
    
    @isTest
    public static void sendNotificationTest2(){
        Test.startTest();
        createData2();
        Market_Batch_Setting__mdt batchSetting = [SELECT MasterLabel, Batch_Class__c, Country_Code__c,Market_Order__c, 
                                                  Serial_Number__c, Scope__c, Job_Group__c, Region__c 
                                                  FROM Market_Batch_Setting__mdt 
                                                  WHERE Batch_Class__c = 'ECM_ContractAnniversaryNotificationBatch'
                                                  AND Country_Code__c ='ES' ];
        String className = batchSetting.Batch_Class__c;
        System.assert(className!=null,'className should not be null');
        Type t  = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));		
        Test.stopTest();
    }
    public static void createData2(){
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        String pickupRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        String type;
        type='Local-Segment1';
        
        Id geographyId = EDGE_UtilityTestClass.setupCountry('ES');
        
        Geography__c  marketObj;
        List<Geography__c> marketList = [SELECT Id FROM Geography__c WHERE Name ='Global'];
        if(!marketList.isEmpty()){
            marketObj = EDGE_UtilityTestClass.createGeography('Market');
            marketObj.Name = 'Europe and Turkey';
            marketObj.Code__c = 'EAT2';
            marketObj.Parent_Geography__c = marketList[0].Id;
            insert marketObj;
        }
        
        string recordTypeName;
        recordTypeName = Schema.SObjectType.Geography__c.getRecordTypeInfosByDeveloperName().get('Market').getRecordTypeId();
        
        //user rec
       
        
        User testSysAdminUser = EDGE_UtilityTestClass.runAsUser('SystemAdmin','System Administrator');
        testSysAdminUser.Available_Countries__c = 'ES';
        insert testSysAdminUser; 
        
         user newuser = EDGE_UtilityTestClass.runAsUser('Testabc','Sales Representative');
        newuser.Email = userInfo.getUserEmail();
        newuser.Available_Countries__c ='ES';
        newuser.ManagerId =testSysAdminUser.Id;
        insert newuser;
        
        Territory_Hierarchy__c hirarchy= ECM_UtilityTestClass.createhirarchy(geographyId);
        hirarchy.recordtypeId=Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Activation Territory').getRecordTypeId();
        insert hirarchy; 
        
        //create territory rec
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        territory.Activation_Territory__c = hirarchy.Id;
        insert territory;
        
        Pick_Up_Options__c budjectEU= new Pick_Up_Options__c();
        budjectEU.Name='TI [ES]';
        budjectEU.Geography__c=geographyId;
        budjectEU.RecordTypeId=pickupRecordTypeId;
        insert budjectEU;
        
        //Setting up Required Item for EU Contract: Account - RecordType Outlet
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.country__c = geographyId;
        acc.Sales_Org__c='sale';
        acc.SAP_Sold_to__c='sapsold';
        acc.Email_for_contracts_payments__c = userInfo.getUserEmail();
        acc.Independent_of_Operator__c=true;
        acc.Independent_of_Owner__c=true;
        insert acc;
        
        //product record
        Product__c pdt = ECM_UtilityTestClass.createProduct(geographyId,'Test Product');
        pdt.Product_Full_Name__c = 'Test Product';
        pdt.Category__c = 'Cocktails';
        pdt.Classification__c = 'RTD';
        insert pdt;
        
        //map record
        Market_Assortment_Product__c maPdt = ECM_UtilityTestClass.createMarketAssortmentProduct(pdt.id,geographyId);
        insert maPdt;
        
        
        //contract type rec
        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        contractType.ECM_Volume_UoM_for_RTD__c = 'Not Applicable';
        contractType.ECM_Volume_UoM_for_Draught_Cocktails__c = 'Not Applicable';
        contractType.ECM_Anniversary_Email_to_Customer__c = 'To Contract Owner & Line Mgr';
        insert contractType;
        
        //product agreement Record
        ECM_Product_Agreement__c  pdtAgr = ECM_UtilityTestClass.createProductAgreement(contractType.id,maPdt.id);
        pdtAgr.ECM_Lead_Brand__c = true;
        insert pdtAgr;
        
        //Setting up contract to link with payment summary
        Contract contr = ECM_UtilityTestClass.createContract(acc.id,contractRecordTypeId);  
        contr.Status = 'Draft';
        contr.ECM_Duration__c = 37;
        Date dt = System.today().addMonths(1);
        contr.StartDate = dt.addMonths(-36);
        contr.ECM_Agreement_Type__c = contractType.Id;
        integer months;
        months = Integer.valueOF(contractType.ECM_Expiration_Start_Date_Rule_in_Months__c);
        contr.Contract_End_Date__c = contr.StartDate.addMonths(37);
        contr.ECM_Expiration_Notification_sent__c = false;
        contr.ownerId = newuser.Id;
        insert contr;
        
        contr.Status = 'Active';
        update contr;
        
        
        //createcontractitem
        ECM_Contract_Item__c contractItem = ECM_UtilityTestClass.createcontractitem(contr.id,maPdt.id);
        contractItem.ECM_Lead_Brand__c = true;
        contractItem.ECM_Product__c=maPdt.Id;
        insert contractItem;
        
        
        
        Territory_Budget__c terriBudget1 = ECM_UtilityTestClass.createTerritoryBudget(territory.Id, hirarchy.Id);
        terriBudget1.ECM_Budget_Type__c=budjectEU.Id;
        insert terriBudget1;
        Id salesDriverRecTypeId = Schema.SObjectType.ECM_Sales_Driver__c.getRecordTypeInfosByName().get('Investment').getRecordTypeId();
        Id salesDriverItemRecTypeId = Schema.SObjectType.ECM_Sales_Driver_Item__c.getRecordTypeInfosByName().get('Sales Driver').getRecordTypeId();
        Id salesDriverItemDetailRecTypeId = Schema.SObjectType.ECM_Sales_Driver_Item_Detail__c.getRecordTypeInfosByName().get('Sales Driver').getRecordTypeId();
        
        ECM_Sales_Driver__c salesDriver = ECM_UtilityTestClass.getSalesdriver(terriBudget1.Id,geographyId);
        salesDriver.RecordTypeId = salesDriverRecTypeId;
        salesDriver.ECM_Category__c ='Draught Cocktail';
        insert salesDriver;
        

        
        ECM_Sales_Driver_Item__c eSCDI = new ECM_Sales_Driver_Item__c(Contract__c=contr.Id,ECM_Sales_Driver__c=salesDriver.Id);
        eSCDI.RecordTypeId = salesDriverItemRecTypeId;
        eSCDI.ECM_Total_Investment_Amount__c = 150;
        eSCDI.Contract__c =contr.Id;
        insert eSCDI;
        
        
        
        ECM_Sales_Driver_Item_Detail__c salesDetails1 = ECM_UtilityTestClass.insertSalesdriverDetails(eSCDI, contractItem);
        salesDetails1.Recordtypeid = salesDriverItemDetailRecTypeId;
        salesDetails1.ECM_Investment_Amount__c = 200;
        insert salesDetails1;
        
      
        
        System.runAs(testSysAdminUser){ 
            
            EmailTemplate validEmailTemplate = new EmailTemplate();
            validEmailTemplate.isActive = true;
            validEmailTemplate.Name = 'ECMConAnnivNotifiESDraughtCustomer';
            validEmailTemplate.DeveloperName = 'ECM_ConAnniv_NotifiESDrgtCust';
            validEmailTemplate.TemplateType = 'text';
            validEmailTemplate.FolderId = UserInfo.getUserId();
            
            insert validEmailTemplate;
        }
    }
    public static void createData(){
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        String pickupRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        String type;
        type='Local-Segment1';
        
        Id geographyId = EDGE_UtilityTestClass.setupCountry('ES');
        
        Geography__c  marketObj;
        List<Geography__c> marketList = [SELECT Id FROM Geography__c WHERE Name ='Global'];
        if(!marketList.isEmpty()){
            marketObj = EDGE_UtilityTestClass.createGeography('Market');
            marketObj.Name = 'Europe and Turkey';
            marketObj.Code__c = 'EAT2';
            marketObj.Parent_Geography__c = marketList[0].Id;
            insert marketObj;
        }
        
        string recordTypeName;
        recordTypeName = Schema.SObjectType.Geography__c.getRecordTypeInfosByDeveloperName().get('Market').getRecordTypeId();
        
        //user rec
        user newuser = EDGE_UtilityTestClass.runAsUser('Testabc','Sales Representative');
        newuser.Email = userInfo.getUserEmail();
        newuser.Available_Countries__c ='ES';
        insert newuser;
        
        User testSysAdminUser = EDGE_UtilityTestClass.runAsUser('SystemAdmin','System Administrator');
        testSysAdminUser.Available_Countries__c = 'ES';
        insert testSysAdminUser; 
        
        Territory_Hierarchy__c hirarchy= ECM_UtilityTestClass.createhirarchy(geographyId);
        hirarchy.recordtypeId=Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Activation Territory').getRecordTypeId();
        insert hirarchy; 
        
        //create territory rec
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        territory.Activation_Territory__c = hirarchy.Id;
        insert territory;
        
        Pick_Up_Options__c budjectEU= new Pick_Up_Options__c();
        budjectEU.Name='TI [ES]';
        budjectEU.Geography__c=geographyId;
        budjectEU.RecordTypeId=pickupRecordTypeId;
        insert budjectEU;
        
        //Setting up Required Item for EU Contract: Account - RecordType Outlet
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.country__c = geographyId;
        acc.Sales_Org__c='sale';
        acc.SAP_Sold_to__c='sapsold';
        acc.Email_for_contracts_payments__c = userInfo.getUserEmail();
        acc.Independent_of_Operator__c=true;
        acc.Independent_of_Owner__c=true;
        insert acc;
        
        //product record
        Product__c pdt = ECM_UtilityTestClass.createProduct(geographyId,'Test Product');
        pdt.Product_Full_Name__c = 'Test Product';
        pdt.Category__c = 'Cocktails';
        pdt.Classification__c = 'RTD';
        insert pdt;
        
        //map record
        Market_Assortment_Product__c maPdt = ECM_UtilityTestClass.createMarketAssortmentProduct(pdt.id,geographyId);
        insert maPdt;
        
        
        //contract type rec
        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        contractType.ECM_Volume_UoM_for_RTD__c = 'Not Applicable';
        contractType.ECM_Volume_UoM_for_Draught_Cocktails__c = 'Not Applicable';
        contractType.ECM_Anniversary_Email_to_Customer__c = 'To Customer';
        insert contractType;
        
        //product agreement Record
        ECM_Product_Agreement__c  pdtAgr = ECM_UtilityTestClass.createProductAgreement(contractType.id,maPdt.id);
        pdtAgr.ECM_Lead_Brand__c = true;
        insert pdtAgr;
        
        //Setting up contract to link with payment summary
        Contract contr = ECM_UtilityTestClass.createContract(acc.id,contractRecordTypeId);  
        contr.Status = 'Draft';
        contr.ECM_Duration__c = 37;
        Date dt = System.today().addMonths(1);
        contr.StartDate = dt.addMonths(-36);
        contr.ECM_Agreement_Type__c = contractType.Id;
        integer months;
        months = Integer.valueOF(contractType.ECM_Expiration_Start_Date_Rule_in_Months__c);
        contr.Contract_End_Date__c = contr.StartDate.addMonths(37);
        contr.ECM_Expiration_Notification_sent__c = false;
        contr.ownerId = newuser.Id;
        insert contr;
        
        contr.Status = 'Active';
        update contr;
        
        
        //createcontractitem
        ECM_Contract_Item__c contractItem = ECM_UtilityTestClass.createcontractitem(contr.id,maPdt.id);
        contractItem.ECM_Lead_Brand__c = true;
        contractItem.ECM_Product__c=maPdt.Id;
        insert contractItem;
        
        
        
        Territory_Budget__c terriBudget1 = ECM_UtilityTestClass.createTerritoryBudget(territory.Id, hirarchy.Id);
        terriBudget1.ECM_Budget_Type__c=budjectEU.Id;
        insert terriBudget1;
        Id salesDriverRecTypeId = Schema.SObjectType.ECM_Sales_Driver__c.getRecordTypeInfosByName().get('Investment').getRecordTypeId();
        Id salesDriverItemRecTypeId = Schema.SObjectType.ECM_Sales_Driver_Item__c.getRecordTypeInfosByName().get('Sales Driver').getRecordTypeId();
        Id salesDriverItemDetailRecTypeId = Schema.SObjectType.ECM_Sales_Driver_Item_Detail__c.getRecordTypeInfosByName().get('Sales Driver').getRecordTypeId();
        
        ECM_Sales_Driver__c salesDriver = ECM_UtilityTestClass.getSalesdriver(terriBudget1.Id,geographyId);
        salesDriver.RecordTypeId = salesDriverRecTypeId;
        salesDriver.ECM_Category__c ='Draught Cocktail';
        insert salesDriver;
        
        ECM_Sales_Driver__c salesDriver2 = ECM_UtilityTestClass.getSalesdriver(terriBudget1.Id,geographyId);
        salesDriver2.RecordTypeId = salesDriverRecTypeId;
        salesDriver2.ECM_Category__c ='Pouring';
        insert salesDriver2;
        
        ECM_Sales_Driver_Item__c eSCDI = new ECM_Sales_Driver_Item__c(Contract__c=contr.Id,ECM_Sales_Driver__c=salesDriver.Id);
        eSCDI.RecordTypeId = salesDriverItemRecTypeId;
        eSCDI.ECM_Total_Investment_Amount__c = 150;
        eSCDI.Contract__c =contr.Id;
        insert eSCDI;
        
        ECM_Sales_Driver_Item__c eSCDI2 = new ECM_Sales_Driver_Item__c(Contract__c=contr.Id,ECM_Sales_Driver__c=salesDriver.Id);
        eSCDI2.RecordTypeId = salesDriverItemRecTypeId;
        eSCDI2.ECM_Total_Investment_Amount__c = 150;
        eSCDI2.Contract__c =contr.Id;
        insert eSCDI2;
        
        ECM_Sales_Driver_Item_Detail__c salesDetails1 = ECM_UtilityTestClass.insertSalesdriverDetails(eSCDI, contractItem);
        salesDetails1.Recordtypeid = salesDriverItemDetailRecTypeId;
        salesDetails1.ECM_Investment_Amount__c = 200;
        insert salesDetails1;
        
        ECM_Sales_Driver_Item_Detail__c salesDetails2 = ECM_UtilityTestClass.insertSalesdriverDetails(eSCDI2, contractItem);
        salesDetails2.Recordtypeid = salesDriverItemDetailRecTypeId;
        salesDetails2.ECM_Investment_Amount__c = 200;
        insert salesDetails2;
        
        System.runAs(testSysAdminUser){ 
            
            EmailTemplate validEmailTemplate = new EmailTemplate();
            validEmailTemplate.isActive = true;
            validEmailTemplate.Name = 'ECMConAnnivNotifiESDraughtCustomer';
            validEmailTemplate.DeveloperName = 'ECM_ConAnniv_NotifiESDrgtCust';
            validEmailTemplate.TemplateType = 'text';
            validEmailTemplate.FolderId = UserInfo.getUserId();
            
            insert validEmailTemplate;
        }
        
    }
    ////////
    
}