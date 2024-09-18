/*
@Name: ECM_volumetargetController_AU_Test
@Purpose: This Class is used ECM_as code coverage for ECM_volumetargetController_AU
@History                                                            
@VERSION		AUTHOR						DATE				DETAIL
@1.0		Veerendra Billakurthi							Initial Development
@2.0		Saurav Prasad				23/02/2022			ECM-5220 - Logic_New Field In Agreement Type for the new screen-"Activation Spend" 
*/
@isTest
public class ECM_volumetargetController_AU_Test {
    @testSetup
    public static void testdata(){
        User usr = ECM_UtilityTestClass.createUser('Testuser@diageo.com',ECM_UtilityTestClass.getProfile('Sales Representative').id);
        Insert usr;
        
        Id geographyId = EDGE_UtilityTestClass.setupCountry('ES'); 
        Territory__c territoryRecord= ECM_UtilityTestClass.createTerritory(geographyId);
        Insert territoryRecord;
        
        ECM_Contract_Type__c contractTypeRecord=  ECM_UtilityTestClass.createContractType(geographyId);   
        Insert contractTypeRecord;
        
        String productTypeRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Product Strategy').getRecordTypeId();
        Pick_Up_Options__c pickupoptionsrecord=ECM_UtilityTestClass.createPickUpOption(geographyId,productTypeRecordTypeId);
        pickupoptionsrecord.Status__c = 'Active';
        String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        Pick_Up_Options__c pickupoptionsrecord1 = ECM_UtilityTestClass.createPickUpOption(geographyId,bannerRecordTypeId);
        pickupoptionsrecord1.Status__c = 'Active';
        pickupoptionsrecord1.Name='IBA[AU]';
        Insert new List<Pick_Up_Options__c>{pickupoptionsrecord,pickupoptionsrecord1};
            
            Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Person_Responsible__c= usr.Id;
        outletAccount.OwnerId = usr.Id;
        insert outletAccount;
        
        String contractrecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Group').getRecordTypeId();  
        String contractrecordTypeId2 = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();  
        contract contractrecord= ECM_UtilityTestClass.createContract(outletAccount.Id,contractrecordTypeId);
        Pick_Up_Options__c banner=[Select Id,Name from Pick_Up_Options__c where Name='IBA[AU]'];
        contractrecord.ECM_Banner__c = banner.Id;        
        contractrecord.ECM_Channel__c = 'On-Premise';
        Insert contractrecord;
        
        contract contractrecord2= ECM_UtilityTestClass.createContract(outletAccount.Id,contractrecordTypeId2);
        //Pick_Up_Options__c banner=[Select Id,Name from Pick_Up_Options__c where Name='IBA[AU]'];
        contractrecord2.ECM_Banner__c = banner.Id;        
        contractrecord2.ECM_Channel__c = 'On-Premise';
        Insert contractrecord2;
        
        Outlet_Contract__c oc = new Outlet_Contract__c();
        oc.Contract__c = contractrecord.Id;
        oc.Outlet__c = outletAccount.Id;
        insert oc;
        Business_Role__c businessRoleRecord=ECM_UtilityTestClass.businessRole(geographyId,'Australia'); 
        Insert businessRoleRecord;
        
        User_Business_Role__c userBusinnesRolerecord=ECM_UtilityTestClass.createUserBusinessRole(businessRoleRecord.Id,usr);
        Insert userBusinnesRolerecord;
        
        ECM_Role_Agreement__c roleAgreementRecord=ECM_UtilityTestClass.createRoleAgreement(businessRoleRecord.Id,contractTypeRecord.Id);
        Insert roleAgreementRecord;
        List<Product__c> lstProd = new List<Product__c>();
        Product__c productrecord=ECM_UtilityTestClass.createProduct(geographyId,'Test');
        productrecord.Product_Full_Name__c='Test';
        lstProd.add(productrecord);
        Product__c productrecord1 =ECM_UtilityTestClass.createProduct(geographyId,'Test');
        productrecord1.Product_Full_Name__c='Test2';
        lstProd.add(productrecord1);
        Insert lstProd;
        List<Market_Assortment_Product__c> lstMarketAssortmentrecord = new List<Market_Assortment_Product__c>();
        Market_Assortment_Product__c marketAssortmentrecord= ECM_UtilityTestClass.createMarketAssortmentProduct(productrecord.Id,geographyId);
        marketAssortmentrecord.ECM_Pickup_Option__c = pickupoptionsrecord.Id;
        marketAssortmentrecord.Unique_ID__c = 'a0w9E00000635g4QAA_a0f1l000004ODPbAAO';
        lstMarketAssortmentrecord.add(marketAssortmentrecord);
        Market_Assortment_Product__c marketAssortmentrecord1= ECM_UtilityTestClass.createMarketAssortmentProduct(productrecord1.Id,geographyId);
        marketAssortmentrecord1.ECM_Pickup_Option__c = pickupoptionsrecord.Id;
        lstMarketAssortmentrecord.add(marketAssortmentrecord1);
        Insert lstMarketAssortmentrecord;
        
        Product_UOM__c productUOMrecord= ECM_UtilityTestClass.createProductUOM(productrecord.Id);
        productUOMrecord.Unique_ID__c = 'a0w9E00000635g4QAA_a0f1l000004ODPbAAO';
        Insert productUOMrecord;
        
        ECM_Product_Agreement__c productAgreementrecord= ECM_UtilityTestClass.createProductAgreement(contractTypeRecord.Id,marketAssortmentrecord.Id);
        Insert productAgreementrecord;
        
        ECM_Price_List__c priceListRecord = ECM_UtilityTestClass.createPriceList('Vodka',geographyId);
        Insert priceListRecord;
        
        ECM_Price_List_Item__c priceItemRecord = ECM_UtilityTestClass.createPriceListItem(pickupoptionsrecord1.Id,productrecord.Id,priceListRecord.Id);
        priceItemRecord.ECM_Base_Price__c = 10;
        priceItemRecord.ECM_LUC_Conversion_Factor__c = 1;
        Insert priceItemRecord;
        
        ECM_Contract_Item__c contractItemrecord= ECM_UtilityTestClass.createcontractitem(contractrecord.Id,marketAssortmentrecord.Id);
        contractItemrecord.ECM_Product__c = marketAssortmentrecord.Id;
        Insert contractItemrecord;
        ECM_Contract_Item__c contractItemrecord1= ECM_UtilityTestClass.createcontractitem(contractrecord2.Id,marketAssortmentrecord1.Id);
        contractItemrecord1.ECM_Product__c = marketAssortmentrecord1.Id;
        Insert contractItemrecord1;
        
        Depletions__c depletionrecord = ECM_UtilityTestClass.createDepletion(productrecord.Id);
        depletionrecord.ECM_Volume__c = 100;
        depletionrecord.ECM_Outlet__c = outletAccount.Id;
        depletionrecord.ECM_Start_Period__c = system.today()-300;
        depletionrecord.ECM_End_Period__c = system.today()-50;
        Insert depletionrecord;
        
        Depletions__c depletionrecord2 = ECM_UtilityTestClass.createDepletion(productrecord.Id);
        depletionrecord2.ECM_Volume__c = 100;
        depletionrecord2.ECM_Outlet__c = outletAccount.Id;
        depletionrecord2.ECM_Start_Period__c = system.today()-300;
        depletionrecord2.ECM_End_Period__c = system.today()-50;
        Insert depletionrecord2;
        
        
    }
    
    @isTest
    public static void createcon(){
        List<Contract> conrecord= [SELECT Id, Name FROM Contract Limit 2];
        
        List<ECM_volumetargetController_AU.strategywrapper> strgWrap;
        strgWrap = ECM_volumetargetController_AU.fetchvolumetargets(conrecord[0]);
        conrecord[0].ECM_Channel__c='hybrid';
        update conrecord;
        System.assert(conrecord!=null,'conrecord should not be null');
      
        test.startTest();
        List<ECM_volumetargetController_AU.strategywrapper> strgWrap1;
        strgWrap1 = ECM_volumetargetController_AU.fetchvolumetargets(conrecord[0]);
        Pick_Up_Options__c pickupopt=[Select Id,Name from Pick_Up_Options__c Limit 1];
        pickupopt.Name='RTD[AU]';
        update pickupopt;

        List<ECM_volumetargetController_AU.strategywrapper> strgWrapRTD;
        strgWrapRTD = ECM_volumetargetController_AU.fetchvolumetargets(conrecord[0]);
        pickupopt.Name='Spirits Pouring[AU]';
        update pickupopt;

        List<ECM_volumetargetController_AU.strategywrapper> strgWrapSpritsPoring;
        strgWrapSpritsPoring = ECM_volumetargetController_AU.fetchvolumetargets(conrecord[0]);
        pickupopt.Name='Spirits Premium[AU]';
        update pickupopt;

        List<ECM_volumetargetController_AU.strategywrapper> strgWrapSpritsPremium;
        strgWrapSpritsPremium = ECM_volumetargetController_AU.fetchvolumetargets(conrecord[1]);
        pickupopt.Name='Spirits Reserve[AU]';
        update pickupopt;

        List<ECM_volumetargetController_AU.strategywrapper> strgWrapSpritreserve;
        strgWrapSpritreserve = ECM_volumetargetController_AU.fetchvolumetargets(conrecord[0]);
        pickupopt.Name='Spirits Draught[AU]';
        update pickupopt;

        List<ECM_volumetargetController_AU.strategywrapper> strgWrapSpritDraught;
        strgWrapSpritDraught = ECM_volumetargetController_AU.fetchvolumetargets(conrecord[0]);
        pickupopt.Name='Distilled Non-alcoholic Adult Beverage[AU]';
        update pickupopt;
        
        List<ECM_volumetargetController_AU.strategywrapper> strgWrapDistilledNAB;
        strgWrapDistilledNAB = ECM_volumetargetController_AU.fetchvolumetargets(conrecord[0]);
        test.stopTest();
    }
    
    @isTest
    public static void createcon1(){
        List<Contract> conrecord= [SELECT Id, Name FROM Contract Limit 2];
        
        List<ECM_volumetargetController_AU.strategywrapper> strgWrap;
        strgWrap = ECM_volumetargetController_AU.fetchvolumetargets(conrecord[0]);
        conrecord[0].ECM_Channel__c='hybrid';
        update conrecord;
        System.assert(conrecord!=null,'conrecord should not be null');
        test.startTest();
        List<ECM_volumetargetController_AU.strategywrapper> strgWrap1;
        strgWrap1 = ECM_volumetargetController_AU.fetchvolumetargets(conrecord[0]);
        Pick_Up_Options__c pickupopt=[Select Id,Name from Pick_Up_Options__c Limit 1];
        pickupopt.Name='RTD[AU]';
        update pickupopt;
        List<ECM_volumetargetController_AU.strategywrapper> strgWrapRTD;
        strgWrapRTD = ECM_volumetargetController_AU.fetchvolumetargets(conrecord[0]);
        pickupopt.Name='Spirits Pouring[AU]';
        update pickupopt;
        List<ECM_volumetargetController_AU.strategywrapper> strgWrapSpritsPoring;
        strgWrapSpritsPoring = ECM_volumetargetController_AU.fetchvolumetargets(conrecord[0]);
        pickupopt.Name='Spirits Premium[AU]';
        update pickupopt;
        List<ECM_volumetargetController_AU.strategywrapper> strgWrapSpritsPremium;
        strgWrapSpritsPremium = ECM_volumetargetController_AU.fetchvolumetargets(conrecord[1]);
        pickupopt.Name='Spirits Reserve[AU]';
        update pickupopt;
        List<ECM_volumetargetController_AU.strategywrapper> strgWrapSpritreserve;
        strgWrapSpritreserve = ECM_volumetargetController_AU.fetchvolumetargets(conrecord[0]);
        pickupopt.Name='Spirits Draught[AU]';
        update pickupopt;
        List<ECM_volumetargetController_AU.strategywrapper> strgWrapSpritDraught;
        strgWrapSpritDraught = ECM_volumetargetController_AU.fetchvolumetargets(conrecord[0]);
        pickupopt.Name='Distilled Non-alcoholic Adult Beverage[AU]';
        update pickupopt;
        List<ECM_volumetargetController_AU.strategywrapper> strgWrapDistilledNAB;
        strgWrapDistilledNAB = ECM_volumetargetController_AU.fetchvolumetargets(conrecord[0]);
        
        ECM_volumetargetController_AU.savecontract(conrecord[0]);
        test.stopTest();
    }
    
    public static Pick_Up_Options__c pickupObj(string namestr){
        Pick_Up_Options__c pickupopt=[Select Id,Name from Pick_Up_Options__c where RecordType.Name='Product Strategy'];
        pickupopt.Name='namestr'; 
        update pickupopt;
        return pickupopt;
    }
    public static Pick_Up_Options__c createpickupObj(){
        Territory__c territory=[Select Id,Name,Country__c from Territory__c Limit 1];
        String productTypeRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Product Strategy').getRecordTypeId();
        Pick_Up_Options__c strategy=ECM_UtilityTestClass.createPickUpOption(territory.Country__c,productTypeRecordTypeId);
        strategy.Status__c = 'Active';
        strategy.Name='Spirits Draught[AU]'; 
        insert strategy;
        return strategy;
    }
    public static ECM_Contract_Item__c conItemObj(Contract conObj,Market_Assortment_Product__c mapObj){
        ECM_Contract_Item__c conItem=[Select Id,Name,ECM_TotalSKU_SpecificRebate__c,ECM_Product__r.ECM_Pickup_Option__r.Name,ECM_Contract__r.ECM_RTD_Discount_Level__r.Name,ECM_Contract__r.ECM_Spirits_Reserve_Discount_Level__r.Name,
                                      ECM_Contract__r.ECM_Spirits_Discount_Level__r.Name,ECM_Contract__r.ECM_Spirits_Pouring_Discount_Level__r.Name,
                                      ECM_Contract__r.ECM_Spirits_Premium_Discount_Level__r.Name, ECM_Contract__r.ECM_Draught_Spirits_Discount_Level__r.Name,ECM_Contract__r.ECM_Channel__c from ECM_Contract_Item__c Limit 1];
        conItem.ECM_MAT_override__c =10;
        conItem.ECM_Product__c= mapObj.Id;  
        //conItem.ECM_Contract__c=conObj.Id;
        conItem.ECM_TSDD_Override__c =30;
        conItem.ECM_TotalSKU_SpecificRebate__c=100;
        Update conItem;
        System.assert(conItem.Id!=null,'conItem Id should not be null');
        return conItem;
    }
    
    
    @isTest
    public static void testupdateContract(){
        test.startTest();
        Pick_Up_Options__c pickupopt=pickupObj('PL1[AU]');
        Contract conrecord= [SELECT Id, Name,ECM_Spirits_Reserve_Discount_Level__c,ECM_Draught_Spirits_Discount_Level__c FROM Contract Limit 1];
        conrecord.ECM_Channel__c='Hybrid';
        conrecord.ECM_Draught_Spirits_Discount_Level__c= pickupopt.Id;
        update conrecord;
        
        Market_Assortment_Product__c mapprod=[Select Id, Name from Market_Assortment_Product__c Limit 1];
        mapprod.ECM_Pickup_Option__c= createpickupObj().Id;
        update mapprod;
        
        ECM_Contract_Item__c conItem=conItemObj(conrecord,mapprod);
        
        ECM_Price_List_Item__c plItem=[Select Id,Name,ECM_UOS__c,ECM_Banner_Discount__c,ECM_Gross_Profit__c,ECM_Cost_of_Goods_Sold__c from ECM_Price_List_Item__c Limit 1];
        plItem.ECM_UOS__c =10;
        plItem.ECM_Gross_Profit__c =100;
        plItem.ECM_Cost_of_Goods_Sold__c =10;
        plItem.ECM_PL1__c=10;
        plItem.ECM_Basic_Discount__c=100;
        update plItem;   
        System.assert(plItem.Id!=null,'plItem Id should not be null');    
        ECM_volumetargetController_AU.updateContractItems(wrapperJsonstring(plItem,conItem));
        test.stopTest();
    }
    @isTest
    public static void testupdateContract1(){
        test.startTest();
        Pick_Up_Options__c pickupopt=[Select Id,Name from Pick_Up_Options__c where RecordType.Name='Product Strategy'];
        pickupopt.Name='Range[AU]';
        update pickupopt;
        Contract conrecord= [SELECT Id, Name,ECM_Spirits_Reserve_Discount_Level__c,ECM_Draught_Spirits_Discount_Level__c FROM Contract Limit 1];
        conrecord.ECM_Channel__c='Hybrid';
        conrecord.ECM_Draught_Spirits_Discount_Level__c= pickupopt.Id;
        update conrecord;
        
        // Id geographyId = EDGE_UtilityTestClass.setupCountry('ES');
        Territory__c territory=[Select Id,Name,Country__c from Territory__c Limit 1];
        
        String productTypeRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Product Strategy').getRecordTypeId();
        Pick_Up_Options__c strategy=ECM_UtilityTestClass.createPickUpOption(territory.Country__c,productTypeRecordTypeId);
        strategy.Status__c = 'Active';
        strategy.Name='Spirits Draught[AU]'; 
        insert strategy;
        
        Market_Assortment_Product__c mapprod=[Select Id, Name from Market_Assortment_Product__c Limit 1];
        mapprod.ECM_Pickup_Option__c= strategy.Id;
        update mapprod;
        
        ECM_Contract_Item__c conItem=[Select Id,Name,ECM_TotalSKU_SpecificRebate__c,ECM_Product__r.ECM_Pickup_Option__r.Name,ECM_Contract__r.ECM_RTD_Discount_Level__r.Name,ECM_Contract__r.ECM_Spirits_Reserve_Discount_Level__r.Name,
                                      ECM_Contract__r.ECM_Spirits_Discount_Level__r.Name,ECM_Contract__r.ECM_Spirits_Pouring_Discount_Level__r.Name,
                                      ECM_Contract__r.ECM_Spirits_Premium_Discount_Level__r.Name, ECM_Contract__r.ECM_Draught_Spirits_Discount_Level__r.Name,ECM_Contract__r.ECM_Channel__c from ECM_Contract_Item__c Limit 1];
        conItem.ECM_MAT_override__c =10;
        conItem.ECM_Product__c= mapprod.Id;  
        //conItem.ECM_Contract__c=conrecord.Id;
        conItem.ECM_TSDD_Override__c =30;
        conItem.ECM_TotalSKU_SpecificRebate__c=100;
        conItem.ECM_TotalAdditional_Discount__c=1;
        Update conItem;
        
        ECM_Price_List_Item__c plItem=[Select Id,Name,ECM_UOS__c,ECM_Banner_Discount__c,ECM_Gross_Profit__c,ECM_Cost_of_Goods_Sold__c from ECM_Price_List_Item__c Limit 1];
        plItem.ECM_UOS__c =10;
        plItem.ECM_Gross_Profit__c =100;
        plItem.ECM_Cost_of_Goods_Sold__c =10;
        plItem.ECM_Range__c=10;
        plItem.ECM_Basic_Discount__c=100;
        update plItem; 
        System.assert(plItem.Id!=null,'plItem Id should not be null');      
        ECM_volumetargetController_AU.updateContractItems(wrapperJsonstring(plItem,conItem));
        test.stopTest();
    }
    
    @isTest
    public static void testupdateContract2(){
        test.startTest();
        Pick_Up_Options__c pickupopt=[Select Id,Name from Pick_Up_Options__c where RecordType.Name='Product Strategy'];
        pickupopt.Name='SD1[AU]';
        update pickupopt;
        Contract conrecord= [SELECT Id, Name,ECM_Spirits_Reserve_Discount_Level__c,ECM_Draught_Spirits_Discount_Level__c FROM Contract Limit 1];
        conrecord.ECM_Channel__c='Hybrid';
        conrecord.ECM_Draught_Spirits_Discount_Level__c= pickupopt.Id;
        update conrecord;
        
        // Id geographyId = EDGE_UtilityTestClass.setupCountry('ES');
        Territory__c territory=[Select Id,Name,Country__c from Territory__c Limit 1];
        
        String productTypeRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Product Strategy').getRecordTypeId();
        Pick_Up_Options__c strategy=ECM_UtilityTestClass.createPickUpOption(territory.Country__c,productTypeRecordTypeId);
        strategy.Status__c = 'Active';
        strategy.Name='Spirits Draught[AU]'; 
        insert strategy;
        
        Market_Assortment_Product__c mapprod=[Select Id, Name from Market_Assortment_Product__c Limit 1];
        mapprod.ECM_Pickup_Option__c= strategy.Id;
        update mapprod;
        
        ECM_Contract_Item__c conItem=[Select Id,Name,ECM_TotalSKU_SpecificRebate__c,ECM_Product__r.ECM_Pickup_Option__r.Name,ECM_Contract__r.ECM_RTD_Discount_Level__r.Name,ECM_Contract__r.ECM_Spirits_Reserve_Discount_Level__r.Name,
                                      ECM_Contract__r.ECM_Spirits_Discount_Level__r.Name,ECM_Contract__r.ECM_Spirits_Pouring_Discount_Level__r.Name,
                                      ECM_Contract__r.ECM_Spirits_Premium_Discount_Level__r.Name, ECM_Contract__r.ECM_Draught_Spirits_Discount_Level__r.Name,ECM_Contract__r.ECM_Channel__c from ECM_Contract_Item__c Limit 1];
        conItem.ECM_MAT_override__c =10;
        conItem.ECM_Product__c= mapprod.Id;  
        //conItem.ECM_Contract__c=conrecord.Id;
        conItem.ECM_TSDD_Override__c =30;
        conItem.ECM_TotalSKU_SpecificRebate__c=100;
        conItem.ECM_TotalAdditional_Discount__c=1;
        
        Update conItem;
        
        ECM_Price_List_Item__c plItem=[Select Id,Name,ECM_UOS__c,ECM_Banner_Discount__c,ECM_Gross_Profit__c,ECM_Cost_of_Goods_Sold__c from ECM_Price_List_Item__c Limit 1];
        plItem.ECM_UOS__c =10;
        plItem.ECM_Gross_Profit__c =100;
        plItem.ECM_Cost_of_Goods_Sold__c =10;
        plItem.ECM_SD1__c=10;
        plItem.ECM_Basic_Discount__c=100;
        update plItem;       
        System.assert(plItem.Id!=null,'plItem Id should not be null');
        ECM_volumetargetController_AU.updateContractItems(wrapperJsonstring(plItem,conItem));
        test.stopTest();
    }
    @isTest
    public static void testupdateContract3(){
        test.startTest();
        Pick_Up_Options__c pickupopt=[Select Id,Name from Pick_Up_Options__c where RecordType.Name='Product Strategy'];
        pickupopt.Name='PL1[AU]';
        update pickupopt;
        Contract conrecord= [SELECT Id, Name,ECM_Spirits_Reserve_Discount_Level__c,ECM_Draught_Spirits_Discount_Level__c FROM Contract Limit 1];
        conrecord.ECM_Channel__c='Hybrid';
        conrecord.ECM_Draught_Spirits_Discount_Level__c= pickupopt.Id;
        update conrecord;
        System.assert(conrecord.Id!=null,'conrecord Id should not be null');
        
        // Id geographyId = EDGE_UtilityTestClass.setupCountry('ES');
        Territory__c territory=[Select Id,Name,Country__c from Territory__c Limit 1];
        
        String productTypeRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Product Strategy').getRecordTypeId();
        Pick_Up_Options__c strategy=ECM_UtilityTestClass.createPickUpOption(territory.Country__c,productTypeRecordTypeId);
        strategy.Status__c = 'Active';
        strategy.Name='Spirits Draught[AU]'; 
        insert strategy;
        
        Market_Assortment_Product__c mapprod=[Select Id, Name from Market_Assortment_Product__c Limit 1];
        mapprod.ECM_Pickup_Option__c= strategy.Id;
        update mapprod;
        
        ECM_Contract_Item__c conItem=[Select Id,Name,ECM_TotalSKU_SpecificRebate__c,ECM_Product__r.ECM_Pickup_Option__r.Name,ECM_Contract__r.ECM_RTD_Discount_Level__r.Name,ECM_Contract__r.ECM_Spirits_Reserve_Discount_Level__r.Name,
                                      ECM_Contract__r.ECM_Spirits_Discount_Level__r.Name,ECM_Contract__r.ECM_Spirits_Pouring_Discount_Level__r.Name,
                                      ECM_Contract__r.ECM_Spirits_Premium_Discount_Level__r.Name, ECM_Contract__r.ECM_Draught_Spirits_Discount_Level__r.Name,ECM_Contract__r.ECM_Channel__c from ECM_Contract_Item__c Limit 1];
        conItem.ECM_MAT_override__c =10;
        conItem.ECM_Product__c= mapprod.Id;  
        //conItem.ECM_Contract__c=conrecord.Id;
        conItem.ECM_TSDD_Override__c =30;
        conItem.ECM_TotalSKU_SpecificRebate__c=100;
        conItem.ECM_TotalAdditional_Discount__c=1;
        Update conItem;
        
        ECM_Price_List_Item__c plItem=[Select Id,Name,ECM_UOS__c,ECM_Banner_Discount__c,ECM_Gross_Profit__c,ECM_Cost_of_Goods_Sold__c from ECM_Price_List_Item__c Limit 1];
        plItem.ECM_UOS__c =10;
        plItem.ECM_Gross_Profit__c =100;
        plItem.ECM_Cost_of_Goods_Sold__c =10;
        plItem.ECM_PL1__c=10;
        plItem.ECM_Basic_Discount__c=100;
        update plItem;       
        ECM_volumetargetController_AU.updateContractItems(wrapperJsonstring(plItem,conItem));
        test.stopTest();
    }
    
    public static string wrapperJsonstring(ECM_Price_List_Item__c plItemObj,ECM_Contract_Item__c conItemObj){
        ECM_volumetargetController_AU.strategywrapper strwrap=New ECM_volumetargetController_AU.strategywrapper();
        List<ECM_volumetargetController_AU.strategywrapper> strwrapList=New List<ECM_volumetargetController_AU.strategywrapper>();
        ECM_volumetargetController_AU.volumetargetwrapper volwrap=New ECM_volumetargetController_AU.volumetargetwrapper();
        List<ECM_volumetargetController_AU.volumetargetwrapper> volwrapList=New List<ECM_volumetargetController_AU.volumetargetwrapper>();
        volwrap.contractItem =conItemObj;
        volwrap.mattargetoriginal=10;
        volwrap.hybridVolumeSplit=50;
        volwrap.priceListItem = plItemObj;
        volwrap.minsalesdriverval =10;
        volwrap.Salesdrivediscount=20;
        volwrapList.add(volwrap);
        strwrap.strategy ='Spirits[AU]';
        strwrap.volumetargetwrap=volwrapList;
        strwrap.volumeInvestmentdesc ='Test';
        strwrapList.add(strwrap);
        String jsonstr=JSON.serialize(strwrapList);
        return jsonstr;
    }
}