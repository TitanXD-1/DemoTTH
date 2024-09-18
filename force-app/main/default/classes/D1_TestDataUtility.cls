/**
 * @name D1_TestDataUtility
 * @description This is generic class to create sample records. This class will be used in all test classes for Diageo One.
 * @history                                                                                                                       

 * VERSION   AUTHOR            DATE              DETAIL
 * 1.0   Sudipta  Nandi       14/09/2020      Initial Development
**/
@IsTest
@SuppressWarnings('PMD.ExcessivePublicCount,PMD.CyclomaticComplexity')
public without sharing class D1_TestDataUtility {
    
    public static Map <String,Schema.RecordTypeInfo> mapAccountRecordTypes = Account.sObjectType.getDescribe().getRecordTypeInfosByName(); // Get Account Record type Map
    public static Map <String,Schema.RecordTypeInfo> mapGeographyRecordTypes = Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName(); // Get Geography Record type Map
    public static Map <String,Schema.RecordTypeInfo> mapPickupoptionRecordTypes = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName(); // Get Pickup Option Record type Map

    // Get the record type id of from the Map based on the Name
    public static Id outletRecTypeId = mapAccountRecordTypes.get('Outlet').getRecordTypeId();
    public static Id prospectRecTypeId = mapAccountRecordTypes.get('Prospect').getRecordTypeId();
    public static Id ownerRecTypeId = mapAccountRecordTypes.get('Owner/Operator').getRecordTypeId();    
    public static Id custRecTypeId = mapAccountRecordTypes.get('Direct Customer').getRecordTypeId();
    public static Id areaRecTypeId = mapGeographyRecordTypes.get('Area').getRecordTypeId();
    public static Id distRecTypeId = mapAccountRecordTypes.get('Distributor/Wholesaler').getRecordTypeId();
    public static Id outletpriorRecTypeId = mapPickupoptionRecordTypes.get('Outlet Prioritization').getRecordTypeId();
    
    public static Map<String,Id> geoMap = new Map<String,Id>();
    
    /**
     * @description create org settings
     * @param void 
     * @return void
     */ 
    public static void createOrgSettings(){
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = True;
        orgSetting.Run_Validation_Rules__c = false;
        insert orgSetting;
    }

    /**
     * @description create Geography Object
     * @param recordtypeName 
     * @return  `Geography__c`
     */    
    public static Geography__c createGeography(String recordtypeName){
        Geography__c geography = new Geography__c();
        geography.RecordTypeId =  Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName().get(recordtypeName).getRecordTypeId();
        return geography; 
    }

    /**
     * @description Setup Global Geography Hierarchy
     * @return  `Geography__c`
     */    
    public static Geography__c setupGlobalHierarchy(){
        Geography__c globalRec = createGeography('Global');
        globalRec.Name = 'Global';
        globalRec.Code__c = 'GBL';
        insert globalRec;
        return globalRec;
    } 
    
    /**
     * @description Setup Geography Hierarchy
     * @param countryCode 
     * @return  `Id`
     */    
    public static Id setupCountry(string countryCode){
        if(geoMap != null && geoMap.size()>0 && geoMap.containsKey('Country')){
            return geoMap.get('Country');
        }else{
            Geography__c globalRec = createGeography('Global');
            globalRec.Name = 'Global1';
            globalRec.Code__c = 'GBL';
            insert globalRec;
            geoMap.put('Global1',globalRec.Id);
            
            Geography__c market = createGeography('Market');
            market.Name = 'Europe and Turkey';
            market.Code__c = 'EU';
            market.Parent_Geography__c = globalRec.Id;
            insert market;
            geoMap.put('Market',market.Id);
            
            Geography__c hub = createGeography('Hub');
            hub.Name = 'Continental Europe';
            hub.Code__c = 'CE';
            hub.Parent_Geography__c = market.Id;
            insert hub;
            geoMap.put('Hub',hub.Id);
            
            Geography__c cluster = createGeography('Cluster');
            cluster.Name = 'Central Europe';
            cluster.Code__c = 'CEE';
            cluster.Parent_Geography__c = hub.Id;
            insert cluster;
            geoMap.put('Cluster',cluster.Id);
            
            Geography__c country = createGeography('Country');
            country.Name = 'Great Britain_TestGB';
            country.Code__c = countryCode;
            country.Parent_Geography__c = cluster.Id;        
            country.Extended_Country_Code__c = 'GBR';
            country.isDiageoOneEnabled__c   = True;
            country.Enable_E_Commerce__c = true;
            country.RecordTypeId = Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Country').getRecordTypeId();
            country.Flag_Content_Document_ID__c = 'Test';
            country.Flag_Content_Version_Id__c='Test';
            insert country;
            
            geoMap.put('Country',country.Id);
            
            Geography__c area = createGeography('Area');
            area.Name = 'London';
            area.Code__c = 'LN';
            area.Parent_Geography__c = country.Id;
            area.RecordTypeId=AreaRecTypeId;
            insert area;
            geoMap.put('Area',area.Id);
            
            return country.Id;
        }
    }
    /**
     * @description create account with record type Outlet  
     * @return  `Account`
     */    
    public static Account getD1Customer(){
        Account distAccount = new Account();
        distAccount.Name = 'Test Customer Account';
        distAccount.AccountNumber = '10483';
        distAccount.Country__c = geoMap.get('Country');
        distAccount.Area__c = geoMap.get('area');
        distAccount.Hub__c = geoMap.get('Hub');
        distAccount.Market__c = geoMap.get('Market');
        distAccount.Cluster__c= geoMap.get('Cluster');
        distAccount.RecordTypeId =  outletRecTypeId;
        distAccount.Outlet_Email_Address__c = 'test@test.com';
        distAccount.VAT_Number__c = '1234';
        distAccount.BillingStreet = '27 Colmore Row';
        distAccount.BillingCity = 'Birmingham';
        //distAccount.BillingState = 'UK';
        distAccount.BillingPostalCode = 'B3 2EW';
        distAccount.BillingCountry = 'United Kingdom';
        distAccount.BillingCountryCode = 'GB';
        distAccount.Global_Channel__c = 'Off Trade';
        distAccount.Global_Sub_Channel__c = 'Retailer';
        distAccount.Global_Segment__c = 'Hypermarket';
        distAccount.Global_Sub_Segment__c = 'Modern Hypermarket';
        distAccount.Status__c= 'Active';
        distAccount.Independent_of_Operator__c = true;
        distAccount.Independent_of_Owner__c = true;
        distAccount.D1_EDGE_Customer__c = true;
        distAccount.Direct_Customer__c = true;
        distAccount.KUNNR__c = '987867';
        distAccount.Salesforce_Delivery_Days_Keg__c='1;2;3;4;5';
        distAccount.Delivery_Pattern__c = '0';
        distAccount.Salesforce_Delivery_Days_Packaged_Good__c = '1;2;3;4;5';
        distAccount.D1_Registration_Status__c = 'AppInvited';
        return distAccount; 
    }
    
    /**
     * @description Setup DirectCustomer
     * @return  `Account`
     */    
    public static Account getDirectCustomer(){
        Account directCustomer = new Account();
        directCustomer.Name = 'Test Direct Account';
        directCustomer.D1_EDGE_Customer__c = true;
        directCustomer.Direct_Customer__c = true;
        directCustomer.Market__c = geoMap.get('Market');
        directCustomer.Hub__c = geoMap.get('Hub');
        directCustomer.Cluster__c = geoMap.get('Cluster');
        directCustomer.Country__c = geoMap.get('Country');
        directCustomer.BillingCountry = 'United Kingdom';
        directCustomer.BillingCountryCode = 'GB';
        directCustomer.RecordTypeId =  custRecTypeId;
        directCustomer.Salesforce_Delivery_Days_Packaged_Good__c='1;2;3;4;5;6;7';
        directCustomer.Salesforce_Delivery_Days_Keg__c='1;2;3;4;5;6;7';
        directCustomer.Delivery_Pattern__c='0';
        directCustomer.Delivery_Plant__c = 'GA4';
        directCustomer.KUNNR__c = '12345';
        return directCustomer;
    }
    
    /**
     * @description insertCartAndCartItems
     * @param testoutlet 
     */    
    public static void insertCartAndCartItems(Account testoutlet){
        
        WebStore webstoreObj = new WebStore();
        webstoreObj.Name = 'Test Store';
        insert webstoreObj;
        
        BuyerGroup buyerGroupObj1 = new BuyerGroup();
        buyerGroupObj1.Name = 'Test 113';
        buyerGroupObj1.List_Price_Available__c = true;
        buyerGroupObj1.PortfolioID__c = 'Test112233';
        insert buyerGroupObj1;
        
        List<BuyerAccount> buyerAccountLst = [select Id from BuyerAccount where isActive = true and BuyerId = :testoutlet.Id];
        if(buyerAccountLst == NULL || buyerAccountLst.size() == 0) { 
            BuyerAccount buyerAccountObj = new BuyerAccount();
            buyerAccountObj.Name = 'Test';
            buyerAccountObj.BuyerId = testoutlet.Id;
            buyerAccountObj.isActive = true;
            buyerAccountObj.BuyerStatus = 'Active';
            insert buyerAccountObj;
        }
        buyerAccountLst = [select Id from BuyerAccount where isActive = true and BuyerId = :testoutlet.Id];
        BuyerGroupMember buyerGrpMemberObj = new BuyerGroupMember();
        buyerGrpMemberObj.BuyerId = testoutlet.Id;
        buyerGrpMemberObj.BuyerGroupId = buyerGroupObj1.Id;
        insert buyerGrpMemberObj;
        
        
        WebStoreBuyerGroup storeBuyerGrpObj = new WebStoreBuyerGroup();
        storeBuyerGrpObj.BuyerGroupId = buyerGroupObj1.Id;
        storeBuyerGrpObj.WebStoreId = webstoreObj.Id;
        insert storeBuyerGrpObj;
        
        Pricebook2 priceBookObj = new Pricebook2();
        priceBookObj.IsActive = true;
        priceBookObj.PortfolioID__c = 'Test112233';
        priceBookObj.Name = 'Test PB';
        insert priceBookObj;
        
        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(),IsActive = true);
        
        BuyerGroupPricebook priceBookBuyerGrpObj = new BuyerGroupPricebook();
        priceBookBuyerGrpObj.BuyerGroupId = buyerGroupObj1.Id;
        priceBookBuyerGrpObj.IsActive = true;
        priceBookBuyerGrpObj.Pricebook2Id = priceBookObj.Id;
        insert priceBookBuyerGrpObj;
        
        Product2 prodObj = new Product2();
        prodObj.Name = 'Test P';
        prodObj.SAP_Material_Id__c = '0000012345';
        insert prodObj;
        
        CommerceEntitlementPolicy entPolicyObj = new CommerceEntitlementPolicy();
        entPolicyObj.PortfolioID__c = 'Test112233';
        entPolicyObj.Name = 'Test Policy';
        insert entPolicyObj;
        
        CommerceEntitlementProduct entProdObj = new CommerceEntitlementProduct();
        entProdObj.ProductId = [select Id from Product2 limit 1].Id;
        entProdObj.PolicyId = [select Id from CommerceEntitlementPolicy where PortfolioID__c = 'Test112233' limit 1].Id;
        insert entProdObj;
        
        WebStorePricebook webStorePBObj = new WebStorePricebook();
        webStorePBObj.IsActive = true;
        webStorePBObj.Pricebook2Id = priceBookObj.Id;
        webStorePBObj.WebStoreId = webstoreObj.Id;
        insert webStorePBObj;
        
        ProductCatalog productCatalogObj = new ProductCatalog();
        productCatalogObj.Name = webstoreObj.Name;
        insert productCatalogObj;
        
        WebStoreCatalog webStoreCatalogObj = new WebStoreCatalog();
        webStoreCatalogObj.ProductCatalogId = productCatalogObj.Id;
        webStoreCatalogObj.SalesStoreId = webstoreObj.Id;
        insert webStoreCatalogObj;
        
        PricebookEntry priceBookEntryObj1 = new PricebookEntry();
        priceBookEntryObj1.IsActive = true;
        priceBookEntryObj1.UnitPrice = 0;
        priceBookEntryObj1.Pricebook2Id = standardPricebook.Id;
        priceBookEntryObj1.Product2Id = [select Id from Product2 limit 1].Id;
        insert priceBookEntryObj1;
        
        PricebookEntry priceBookEntryObj = new PricebookEntry();
        priceBookEntryObj.IsActive = true;
        priceBookEntryObj.UnitPrice = 0;
        priceBookEntryObj.Pricebook2Id = priceBookObj.Id;
        priceBookEntryObj.Product2Id = [select Id from Product2 limit 1].Id;
        insert priceBookEntryObj;
        
        Sales_Area__c sa= new Sales_Area__c();
        sa.Max_Order_Line_Items__c = 2;
        sa.Name = 'Test Sales Area';
        sa.Distribution_Channel_Code__c = '10';
        sa.Division_Code__c = '10';
        sa.Sales_Organisation_Code__c = 'CH01';
        insert sa; 
        
        
        PNR_Partner_Function__c pf = new PNR_Partner_Function__c();
        pf.PNR_Sold_To__c = testoutlet.Id;
        pf.D1_EDGE_Customer__c = true;
        pf.PNR_Type__c = 'Sold-To';
        pf.Item_Proposal__c ='PF-1234';
        pf.Sales_Area__c = sa.Id;
        insert pf;
        
        OrderSplit__c oSplit1 = insertOrderSplit(sa.Id);
        insert oSplit1;
        OrderSplit__c oSplit2 = insertOrderSplitNK(sa.Id);
        insert oSplit2;
        
        ContactPointAddress cpa = insertContactPointAddress();
        cpa.ParentId = testoutlet.ID;
        cpa.Source__c = 'Diageo One';
        insert cpa;
        
        WebCart webCArtObj = new WebCart();
        webCArtObj.Name = 'TestCart';
        webCArtObj.WebStoreId = webstoreObj.Id;
        webCArtObj.AccountId = testoutlet.Id;
        webCArtObj.Order_Split_1__c = oSplit1.id;
        webCArtObj.Order_Split_2__c = oSplit2.id;
        webCArtObj.Split_2_PO_Number__c = '123654';
        webCArtObj.PoNumber = '4569875';
        webCArtObj.Status = 'Active';
        webCArtObj.Sales_Area__c = sa.Id;
        webCArtObj.Delivery_Address__c = cpa.Id;
        insert webCArtObj;
        
        Order_Delivery_Date__c orderDeliveryDate1 = getOrderDeliveryDate(oSplit1.Id);
        orderDeliveryDate1.Delivery_Date_ID__c = 'TestKeg';
        insert orderDeliveryDate1;
        
        Order_Delivery_Date__c orderDeliveryDate2 = getOrderDeliveryDate(oSplit2.Id);
        orderDeliveryDate2.Delivery_Date_ID__c = 'TestNonKeg';
        insert orderDeliveryDate2;
        
        Portfolio_Item__c pfItem = getPortfolioItem(prodObj.Id,oSplit1.Id);
        insert pfItem;

        
        CartDeliveryGroup cartDeliveryGroup = new CartDeliveryGroup(CartId=webCArtObj.Id, Name='Default Delivery');
        insert cartDeliveryGroup;
        
        CartItem cartItem = new CartItem(CartId=webCArtObj.Id, Sku='SKU_Test1', SalesPrice=10.00, Quantity=3.0, 
                                         Type='Product', Name='TestProduct', CartDeliveryGroupId=cartDeliveryGroup.Id,
                                         Product2Id = prodObj.Id);
        insert cartItem;        
    }

    /**
     * @description Order Split Keg
     * @param saId 
     * @return  `OrderSplit__c`
     */    
    public static OrderSplit__c insertOrderSplit(Id saId){

        OrderSplit__c oSpilt = new OrderSplit__c();
        oSpilt.Sales_Area__c = saId;
        oSpilt.Description__c ='Test1234';
        oSpilt.Market_Description__c='Keg';
        oSpilt.Delivery_Day_Series__c=2;
        oSpilt.Max_future_order_days__c=56;
        oSpilt.Delivery_day_holiday_shift_ripple__c = true;
        oSpilt.Is_lead_time_in_business_days__c = true;
        oSpilt.Lead_Time_in_day__c = 2;
        oSpilt.Cut_Off_Time__c = Time.newInstance(15, 00, 0, 0);
        oSpilt.Use_Plant_Exception_Calendar__c = false;
        oSpilt.SAP_OrderSplit_ID__c = '445566';
        return oSpilt;
    }

    /**
     * @description Order Split Non-Keg
     * @param salesAreaId 
     * @return  `OrderSplit__c`
     */    
    public static OrderSplit__c insertOrderSplitNK(Id salesAreaId){
        OrderSplit__c oSpilt = new OrderSplit__c();
        oSpilt.Sales_Area__c = salesAreaId;
        oSpilt.Description__c ='Test1234NK';
        oSpilt.Market_Description__c='Non Keg';
        oSpilt.Delivery_Day_Series__c=2;
        oSpilt.Max_future_order_days__c=56;
        oSpilt.Delivery_day_holiday_shift_ripple__c = true;
        oSpilt.Is_lead_time_in_business_days__c = true;
        oSpilt.Lead_Time_in_day__c = 2;
        oSpilt.Cut_Off_Time__c = Time.newInstance(15, 00, 0, 0);
        oSpilt.Use_Plant_Exception_Calendar__c = false;
        oSpilt.SAP_OrderSplit_ID__c = '445577';
        return oSpilt;
    }
    
    /**
     * @description insertContactPointAddress
     * @return  `ContactPointAddress`
     */    
    public static ContactPointAddress insertContactPointAddress(){
        ContactPointAddress contactPoint = new ContactPointAddress();
        contactPoint.Name = 'test';
        contactPoint.Name2__c = 'test';
        contactPoint.AddressType = 'Shipping';
        contactPoint.Source__c = 'Diageo One';
        return contactPoint;
    }

    /**
     * @description createD1Settings
     * @param country 
     * @return  `D1_Setting__c`
     */    
    public static D1_Setting__c createD1Settings(Geography__c country){
        D1_Setting__c d1setting = new D1_Setting__c();
        d1setting.Name = 'GB';
        d1setting.Unique_ID__c = 'test GB';
        d1setting.Language__c = 'en_GB';
        d1setting.Market__c = country.Id;
        d1setting.Name_2_value__c = true;
        d1setting.Default__c = true;
        d1setting.Hide_Tax_Identification_Number__c = false;
        d1setting.Tax_Identification_Number__c = 'Tax Identification Number';
        d1setting.Enable_Sales_Area_Terms_and_Conditions__c = true;
        d1setting.Direct_Customers_Email_Domain_Check__c = true;
        d1setting.Is_Public_About_Us_On__c = true;
        d1setting.Is_Public_FAQ_On__c = true;
        d1setting.Is_Public_Contact_Us_On__c = true;     
        d1setting.Is_Logged_In_About_Us_On__c=true;
        d1setting.Self_Registration__c = true;
        d1setting.Is_Logged_In_FAQ_On__c=true;
        d1setting.Is_Logged_In_Contact_Us_On__c=true;
        d1setting.Navigation_Menu_Name__c = 'Default Navigation';
        d1setting.Order_Limit_Per_Day__c = 5;
        d1setting.Order_Limit_Per_Day_Message__c = 'You have reached maximum allowed order limit';
        d1setting.Default__c = true;
        d1Setting.NPS_Survey_URL__c  = '';
        return d1setting;
    }
    
    /**
     * @description getD1UserType
     * @param countryName 
     * @param userType 
     * @param d1SettingId 
     * @return  `D1_User_Type__c`
     */    
    public static D1_User_Type__c getD1UserType(String countryName,String userType,Id d1SettingId){
        D1_User_Type__c d1UserType = new D1_User_Type__c();
        d1UserType.Name = countryName+' '+userType;
        d1UserType.User_Type__c = userType;
        d1UserType.D1_Setting__c = d1SettingId;
        d1UserType.Customer_Service_Group__c = 'customer.service@yopmail.com';
        d1UserType.Tax_Identification_Number__c = 'VAT_Number__c';
        d1UserType.Help_and_Support_Topic_Names__c = 'Account Management;Online Ordering';
        d1UserType.Email_Domain_Check__c = true;
        d1UserType.Case_Type__c = 'General;My Financials';
        d1UserType.Case_Subtype__c = 'Account Balance;I Have A Question';
        //insert d1UserType;
        return d1UserType;
        
    }
    
    /**
     * @description insertD1TermsConditions
     * @param d1setting 
     * @return  `D1_Terms_Conditions__c`
     */    
    public static D1_Terms_Conditions__c insertD1TermsConditions(D1_Setting__c d1setting){
        D1_Terms_Conditions__c termsConditions = new D1_Terms_Conditions__c();
        termsConditions.Name='Term1';
        termsConditions.Status__c='Draft';
        termsConditions.Market__c=d1setting.id;
        termsConditions.Content__c='Content1';
        termsConditions.Releases__c='Minor Releases';
        termsConditions.recordtypeid=Schema.SObjectType.D1_Terms_Conditions__c.getRecordTypeInfosByName().get('Order Terms and Condition').getRecordTypeId();        
        return termsConditions;
    }
    
    /**
     * @description product2TestData
     * @return  `list<Product2>`
     */    
    public static list<Product2> product2TestData(){
        //Trigger_Setting__mdt triggerSetting = [SELECT MasterLabel, IsEnabled__c FROM Trigger_Setting__mdt where MasterLabel =:'Product2Trigger' LIMIT 1];
        list<Product2> products = new List<Product2>();
        ProductCatalog catlog = new ProductCatalog(Name = 'Shop');
        insert catlog;
        ProductCategory catP = new ProductCategory(Name = 'Product',CatalogId =catlog.Id);
        insert catP;
        
        ProductCategory catP1 = new ProductCategory(Name = 'Beer',CatalogId =catlog.Id,ParentCategoryId = catP.Id);
        insert catP1;
        ProductCategory catP2 = new ProductCategory(Name = 'Alcoholic Pre-Mix Drink',CatalogId =catlog.Id,ParentCategoryId = catP.Id);
        insert catP2;
        
        Product__c product1 = new Product__c(Name = 'Custom Product1', Classification__c = 'Beer');
        product1.Product_Full_Name__c = 'New Product';
        product1.Diageo_Cost__c = 10;
        product1.A_P_Cost__c =10;
        product1.POS_Related_Brand__c='JW';
        product1.Units_per_POS__c= 10;
        product1.Outlet_Cost__c=10;
        product1.Pricing_Type__c = 'By Unit';
        product1.Limit_Per_Order__c=10;
        product1.POS_Related_Item__c='JW';
        product1.Product_Code__c='test2341';
        product1.SAP_IO_Number__c='Sample';
        product1.POS_Item_Short_Description__c='This is good item';
        product1.Start_Date__c = system.today();   
        insert product1;

        Product__c product2 = new Product__c(Name = 'Custom Product2', Classification__c = 'Beverage');
        product2.Product_Full_Name__c = 'New Product';
        product2.Diageo_Cost__c = 10;
        product2.A_P_Cost__c =10;
        product2.POS_Related_Brand__c='JW';
        product2.Units_per_POS__c= 10;
        product2.Outlet_Cost__c=10;
        product2.Pricing_Type__c = 'By Unit';
        product2.Limit_Per_Order__c=10;
        product2.POS_Related_Item__c='JW';
        product2.Product_Code__c='test2342';
        product2.SAP_IO_Number__c='Sample';
        product2.POS_Item_Short_Description__c='This is good item';
        product2.Start_Date__c = system.today();   
        insert product2;

        Product__c product3 = new Product__c(Name = 'Custom Product3', Classification__c = 'Alcoholic');
        product3.Product_Full_Name__c = 'New Product';
        product3.Diageo_Cost__c = 10;
        product3.A_P_Cost__c =10;
        product3.POS_Related_Brand__c='JW';
        product3.Units_per_POS__c= 10;
        product3.Outlet_Cost__c=10;
        product3.Pricing_Type__c = 'By Unit';
        product3.Limit_Per_Order__c=10;
        product3.POS_Related_Item__c='JW';
        product3.Product_Code__c='test2343';
        product3.SAP_IO_Number__c='Sample';
        product3.POS_Item_Short_Description__c='This is good item';
        product3.Start_Date__c = system.today();   
        insert product3;

        Product__c product4 = new Product__c(Name = 'Custom Product4', Classification__c = 'Spirit');
        product4.Product_Full_Name__c = 'New Product';
        product4.Diageo_Cost__c = 10;
        product4.A_P_Cost__c =10;
        product4.POS_Related_Brand__c='JW';
        product4.Units_per_POS__c= 10;
        product4.Outlet_Cost__c=10;
        product4.Pricing_Type__c = 'By Unit';
        product4.Limit_Per_Order__c=10;
        product4.POS_Related_Item__c='JW';
        product4.Product_Code__c='test2344';
        product4.SAP_IO_Number__c='Sample';
        product4.POS_Item_Short_Description__c='This is good item';
        product4.Start_Date__c = system.today();   
        insert product4;

        Product__c product5 = new Product__c(Name = 'Custom Product5', Classification__c = 'Wine');
        product5.Product_Full_Name__c = 'New Product';
        product5.Diageo_Cost__c = 10;
        product5.A_P_Cost__c =10;
        product5.POS_Related_Brand__c='JW';
        product5.Units_per_POS__c= 10;
        product5.Outlet_Cost__c=10;
        product5.Pricing_Type__c = 'By Unit';
        product5.Limit_Per_Order__c=10;
        product5.POS_Related_Item__c='JW';
        product5.Product_Code__c='test2345';
        product5.SAP_IO_Number__c='Sample';
        product5.POS_Item_Short_Description__c='This is good item';
        product5.Start_Date__c = system.today();   
        insert product5;

        for(integer i = 1; i<=50;i++){
            products.add(new Product2(Name = 'Baileys Original – Test '+i,isActive=true,Brand_Variant__c = product1.id));
        }
        for(integer i = 51; i<=100;i++){ 
            products.add(new Product2(Name = 'Baileys Original – Test '+i,isActive=true,Brand_Variant__c = product3.id));
        }
        
        for(integer i = 101; i<=250;i++){
            products.add(new Product2(Name = 'Baileys Original – Test '+i,isActive=true,D1_Category__c = 'Wine'));
        } 
        
        insert products;
        return products;
    }

    /**
     * @userStory NCP-1871
     * @description Setup all Fault fixer Object level
     * @param key 
     */    
    public static void setupAllFaultFixerLevelObjects(String key){
        key = String.isEmpty(key) ? 'key': key;

        final String reCORDTYPECATEGORY = 'Category';
        final String reORDTYPESUBCATEGORY = 'Sub Category';
        final String reORDTYPEISSUE = 'Issue';
        final String reORDTYPEDIAGNOSIS = 'Diagnosis';
        final String reORDTYPETROUBLESHOOTINGSTEPS = 'Troubleshooting Steps';
        
        D1_Fault_Fixer__c category = getFaultFixerObject(reCORDTYPECATEGORY, null, key+reCORDTYPECATEGORY);
        insert category;
        
        D1_Fault_Fixer__c subCategory = getFaultFixerObject(reORDTYPESUBCATEGORY, category.id, key+reORDTYPESUBCATEGORY);
        insert subCategory;
        
        D1_Fault_Fixer__c issue = getFaultFixerObject(reORDTYPEISSUE, subCategory.id, key+reORDTYPEISSUE);
        insert issue;
        
        D1_Fault_Fixer__c diagnostics = getFaultFixerObject(reORDTYPEDIAGNOSIS, issue.id, key+reORDTYPEDIAGNOSIS);
        insert diagnostics;
        
        D1_Fault_Fixer__c troubleshootSteps = getFaultFixerObject(reORDTYPETROUBLESHOOTINGSTEPS, diagnostics.id, key+reORDTYPETROUBLESHOOTINGSTEPS);
        insert troubleshootSteps;
        
        D1_Fault_Fixer__c troubleshootSteps2 = getFaultFixerObject(reORDTYPETROUBLESHOOTINGSTEPS, issue.id, key+reORDTYPETROUBLESHOOTINGSTEPS);
        insert troubleshootSteps2;        
    }

    /**
     * @userStory NCP-1871
     * @description Return Fault fixer Object
     * @param recordType 
     * @param parentId 
     * @param name 
     * @return  `D1_Fault_Fixer__c`
     */    
    public static D1_Fault_Fixer__c getFaultFixerObject(String recordType, String parentId, String name){
        Id recordTypeId = getRecordTypeIdByName('D1_Fault_Fixer__c', recordType);
        D1_Fault_Fixer__c obj = new D1_Fault_Fixer__c(
            Name = name,
            Display_Title__c = name,
            Parent__c = parentId,
            recordTypeId = recordTypeId,
            Active__c = true
        );
        
        return obj;
    }
    
    /**
     * @userStory NCP-1871
     * @description Return RecodType Id from RecordType name
     * @param objectName 
     * @param strRecordTypeName 
     * @return  `Id`
     */    
    public static Id getRecordTypeIdByName(String objectName, String strRecordTypeName){
        return  Schema.getGlobalDescribe().get(objectName).getDescribe().getRecordTypeInfosByName().get(strRecordTypeName).getRecordTypeId();
    }
    
    /**
     * @description setUpExternalUser
     * @param account 
     * @param userType 
     */    
    public static void setUpExternalUser(Account account, String userType) {
        User testAdminUser ;
        User thisUser =  [ select Id from User where Id = :UserInfo.getUserId() ];
        Geography__c country ;
        D1_User_Type__c d1UserType;
        D1_Setting__c d1setting;
        
        System.runAs(thisUser){            
            UserRole ur   =   [Select Id From UserRole Where Name = 'Global' Limit 1];
            testAdminUser = runAsUser('testAdmin','System Administrator');        
            testAdminUser.userRoleId = ur.id;
            insert testAdminUser;  
            
            if(userType=='Direct Buyer')
            {
                Id countryId = setupCountry('GB');
                country = new Geography__c(Id= countryId);
                upsert country;   
            }
            else
            {
                country=[select id,Name from Geography__c where id =:account.Country__c ];
                
            }
            
            d1setting = createD1Settings(country);
            insert d1setting;
            
            d1UserType = getD1UserType(country.Name,userType,d1setting.Id);
            insert d1UserType; 
            
        }        
        system.runAs(testAdminUser){
            account.Market__c = geoMap.get('Market');
            account.Hub__c = geoMap.get('Hub');
            account.Cluster__c = geoMap.get('Cluster');
            account.Country__c = geoMap.get('Country');
            upsert account; // account is inserted here so that there is no role assignment issue while deploying to higher environments - please do not remove
 
            Contact primcon1=new Contact(FirstName='fname1',
                                         LastName = 'lname',
                                         Email = 'testclassextuser1@testdomain.com',
                                         Phone = '12345672890',Contact_Type__c='Primary',AccountID=account.Id); 
            insert primcon1;
            
            PNR_Partner_Function__c pf = getPartnerFunction(account,'Sold-To');
            insert pf;
            
            Sales_Area__c sa= salesAreaData();
            insert sa;
            
            List<Contact> conList=[select id, AccountId from Contact where accountId=:account.Id limit 1 ];
            system.assert(conList.size() > 0, 'contact list not found');
            //List<user> userList = new List<User>();
            User externalUser1 = runAsUser('extuser1','DiageoOne External User');
            externalUser1.Username = 'testclassextuser1@testdomain.com';
            externalUser1.Email='testclassextuser1@testdomain.com';
            externalUser1.Available_Countries__c = 'GB';
            externalUser1.LanguageLocaleKey='en_GB';
            externalUser1.ContactId = primcon1.id;
            externalUser1.D1_User_Type__c = userType;
            externalUser1.D1_User_Type_Id__c = d1UserType.id;
            externalUser1.CommunityNickname = 'Mania.Test1';
            externalUser1.Effective_Account_Id__c = primcon1.AccountID;
            externalUser1.isActive = True;
            externalUser1.D1_User_Type_Id__c = d1UserType.Id;
            
            //userList.add(externalUser1);
            
            insert externalUser1;
            
        }
    }

    /**
     * @description salesAreaData
     * @return  `Sales_Area__c`
     */    
    public static Sales_Area__c salesAreaData(){
        Sales_Area__c saObj = new Sales_Area__c();
        saObj.Name = 'GB011010';
        saObj.Sales_Organisation_Code__c = 'GB01';
        saObj.Distribution_Channel_Code__c = '10';
        saObj.Division_Code__c = '10';
        saObj.Max_Order_Line_Items__c = 2;
        saObj.Sales_Area_ID__c = 'testSau123658';
        saObj.CurrencyIsoCode ='GBP';
        //insert saObj;
        return saObj;
    }
    
    /**
     * @description getPickUpOption
     * @param countryId 
     * @param recordTypeName 
     * @param typeData 
     * @param name 
     * @return  `Pick_Up_Options__c`
     */  
    @SuppressWarnings('PMD.ExcessiveParameterList')   
    public static Pick_Up_Options__c getPickUpOption(Id countryId, String recordTypeName, String typeData, String name){
        Pick_Up_Options__c pickupOption = new Pick_Up_Options__c();
        pickupOption.Name = name;
        pickupOption.Status__c = 'Active';
        //pickupOption.Type__c = typeData;
        pickupOption.Geography__c = countryId;
        pickupOption.recordTypeId = D1_TestDataUtility.getRecordTypeIdByName('Pick_Up_Options__c', recordTypeName);
        return pickupOption;
    }
    
    /**
     * @description getProduct
     * @param countryId 
     * @param recordType 
     * @param productTypeId 
     * @return  `Product__c`
     */    
    public static Product__c getProduct(Id countryId, String recordType, Id productTypeId){
        Product__c testProd = new Product__c(Name='Johnny Walker Black Label');
        testProd.UPIID__c='12345';
        testProd.Product_Full_Name__c = 'New Product';
        testProd.Country__c =  countryId;
        testProd.Diageo_Cost__c = 10;
        testProd.A_P_Cost__c =10;
        testProd.POS_Related_Brand__c='JW';
        testProd.Units_per_POS__c= 10;
        testProd.Outlet_Cost__c=10;
        testProd.Pricing_Type__c = 'By Unit';
        testProd.Limit_Per_Order__c=10;
        testProd.POS_Related_Item__c='JW';
        testProd.Product_Code__c='test234';
        testProd.SAP_IO_Number__c='Sample';
        testProd.POS_Item_Short_Description__c='This is good item';
        testProd.Start_Date__c = system.today();
        testProd.Product_Type__c = productTypeId;
        testProd.Diageo_One_Product__c = true;
        testProd.IsActive__c = true;
        testProd.POS_Variant_Types__c = 'Pint';
        testProd.recordTypeId = D1_TestDataUtility.getRecordTypeIdByName('Product__c',recordType);
        return testProd; 
    }

    /**
     * get territory
     * @return  `Territory__c`
     */
    public static Territory__c getTerritoryRec(){        
        Territory__c  territory = new Territory__c();
        territory.name = 'Test Territory' ;
       // territory.Country__c = geoMap.get('Country'); 
        territory.Territory_Type__c = 'Auxiliary';
        territory.Status__c = 'Active';
        return territory; 
    }

    /**
     * Opportunity Template
     * @param product 
     * @param territory 
     * @param country 
     * @return  `Opportunity_Template__c`
     */
    public static Opportunity_Template__c getOpportunityTemplate(Id product, Id territory, Id countryId){
        Pick_Up_Options__c oultlVstPriPkUp = getPickUpOption(countryId, 'Outlet Prioritization','Outlet Visit Prioritization','Test');
        Opportunity_Template__c oppTem = new Opportunity_Template__c();
        oppTem.Cluster__c = geoMap.get('Cluster');
        oppTem.Opportunity_Type__c = 'Cycle Brief';
        OppTem.Action__c = 'TestAction';
        OppTem.Start_Date__c = System.today();
        oppTem.Closing_Method__c = 'Manual';
        OppTem.Weight_Type__c = 'Manual Value';
        //OppTem.Activation__c = 'Test Activation';
        OppTem.Activation__c = oultlVstPriPkUp.Id;
        OppTem.Product__c = product;
        OppTem.Territory__c = territory;
        OppTem.Country__c = countryId;        
        OppTem.End_Date__c = System.today()+10;        
        OppTem.Segment__c = 'Supermarket';
        OppTem.Sub_Segment__c = 'Reserve Supermarket';        
        OppTem.Channel__c = 'Off Trade';        
        return oppTem;
    }
    
    /**
     * @description getStock
     * @param countryId 
     * @param areaId 
     * @param productId 
     * @param outletId 
     * @param recordType 
     * @return  `Stock__c`
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')     
    public static Stock__c getStock(String countryId, String areaId, String productId, String outletId, String recordType){
        Stock__c objStock = new Stock__c();
        objStock.recordTypeId = D1_TestDataUtility.getRecordTypeIdByName('Stock__c',recordType);
        objStock.Country__c = countryId;
        objStock.Area__c = areaId;
        objStock.Product__c = productId;
        objStock.Allocated__c = 100;
        objStock.Type__c = 'Outlet';
        objStock.Outlet__c = outletId;
        return objStock;
    }
    
    /**
     * @description creates a new user by passing the profile name
     * @param uniqueKey 
     * @param sProfileName 
     * @return  `User`
     */    
    public static User runAsUser(String uniqueKey, String sProfileName) {
        User newUser = new User();      
        if(uniqueKey.length() > 8){
            newUser.Alias = uniqueKey.substring(0,4);
        }
        else {
            newUser.Alias = uniqueKey;
        }
        newUser.Email = uniqueKey + '@edgeorg.com';
        newUser.EmailEncodingKey  = 'UTF-8';
        newUser.LastName = 'Test' + uniqueKey;
        newUser.FirstName = uniqueKey;
        newUser.LanguageLocaleKey  = 'en_GB';
        newUser.LocaleSidKey = 'en_GB';
        newUser.ProfileId = [select Id from Profile where Name =: sProfileName limit 1].Id;
        newUser.TimeZoneSidKey = 'America/Chicago';
        newUser.Username = uniqueKey + '@test' + Math.round(Math.random() * 10000) + '.com'; 
        newUser.Available_Countries__c = 'GB';
        //newUser.CommunityNickname = 'Mania.Test1';
        newUser.isActive = True;
        return newUser; 
    }
    
    /**
     * @description Create Contact
     * @param outletId 
     * @param type 
     * @return  `Static Contact`
     */     
    public Static Contact getContact(Id outletId, String type){
        Contact contact = new Contact();
        contact.FirstName = 'test';
        contact.LastName = 'Contact';
        contact.AccountId = outletId;
        contact.Email = 'test.test@gmail.com';
        contact.Contact_Type__c = type;
        contact.Phone = '12345672890';
        return contact;
    }
    
    /**
     * @description Create Custom Order
     * @param accID 
     * @param recTypeID 
     * @return  `order__c`
     */    
    public static order__c createOrder(id accID,ID recTypeID){
        Order__c order = new Order__c();
        order.Delivery_Address__c = accID;
        order.Request_Type__c = '';
        order.RecordTypeId = recTypeID; 
        order.Source_Application__c ='Diageo One';
        order.Account__c = accID;
        return order;
    }

    /**
     * @description Get Custom Order Item
     * @param orderId 
     * @return  `Order_Item__c`
     */    
    public static Order_Item__c createOrderItem(id orderId){
        Order_Item__c orderItem = new Order_Item__c();
        orderItem.Order__c = orderId;
        orderItem.Status__c = 'Order Delivered';
        orderItem.Quantity__c = 1;
        return orderItem;
    }

    /**
     * @description Update WebCart
     * @return  `ID`
     */    
    public static ID updateWebCart(){
        
        WebCart webCartObj = [ SELECT Id,AccountId FROM WebCart WHERE Name ='TestCart' LIMIT 1 ];
            webCArtObj.Split_2_PO_Number__c = '123654';
            webCArtObj.PoNumber = '4569875';
            update webCArtObj;
            return WebCartObj.Id;
    }

    /**
     * @description Insert Partner Function
     * @param acc 
     * @param Type 
     * @return  `PNR_Partner_Function__c`
     */    
    public static PNR_Partner_Function__c getPartnerFunction(Account acc,String type){
        PNR_Partner_Function__c pf = new PNR_Partner_Function__c();
        pf.D1_EDGE_Customer__c = true;
        pf.PNR_Customer_No__c = acc.Id;
        pf.PNR_Type__c = type;
        pf.PNR_Sold_To__c= acc.id;
        pf.Item_Proposal__c = '223344';
        //insert pf;
        return pf;
    }
    
    /**
     * @description getD1UserTypeRole
     * @param userType 
     * @param userRole 
     * @return  `D1_User_Types_Role__c`
     */    
    public static D1_User_Types_Role__c getD1UserTypeRole(D1_User_Type__c userType,D1_User_Role__c userRole){
        D1_User_Types_Role__c userTypeRole = new D1_User_Types_Role__c();
        userTypeRole.Name = userType.Name+'-'+userRole.Name;
        userTypeRole.D1_User_Type__c = userType.Id;
        userTypeRole.D1_User_Role__c = userRole.Id;
        userTypeRole.Description__c = 'Test Role';
        userTypeRole.Display_Name__c = 'Test Display';
        //insert userTypeRole;
        return userTypeRole;
            
    }

    /**
     * @description Get UserRole 
     * @param name 
     * @return  `D1_User_Role__c`
     */    
    public static D1_User_Role__c getD1UserRole(String name){
        D1_User_Role__c userRole = new D1_User_Role__c();
        userRole.Name = name;
        //userRole.Description__c = 'Test Role';
        userRole.Access_Type__c = name;
        userRole.IsDefault__c = false;
        //insert userRole;
        return userRole;
    }

    /**
     * @description Get Event 
     * @return  `D1_Event__c`
     */    
    public static D1_Event__c getEvent(){
        D1_Event__c e1 = new D1_Event__c();
        e1.Name='Event 1';
        e1.Category__c='New Year';
        e1.Description__c = 'Sample description';
        insert e1;
        return e1;
    }

    /**
     * @description Get Brand
     * @return  `D1_Brand__c`
     */    
    public static D1_Brand__c getBrand(){
        D1_Brand__c b1 = new D1_Brand__c();
        b1.Name='Brand 1';
        b1.Category__c='Johny Walker';
        b1.Description__c = 'Sample description';
        insert b1;
        return b1;
    }

    /**
     * @description Get Content Assignment Test Data
     * @return  `D1_Content_Assignment__c`
     */    
    public static D1_Content_Assignment__c cATestData(){
        D1_Content_Assignment__c contentAssgn = new D1_Content_Assignment__c();
        contentAssgn.D1_Event__c = getEvent().id;
        contentAssgn.Popular_Brand__c = false;
        contentAssgn.D1_Brand__c = null;
        contentAssgn.Geography__c = [SELECT id,code__c from Geography__c WHERE code__c='GB' limit 1].id;
        contentAssgn.RecordTypeId = Schema.SObjectType.D1_Content_Assignment__c.getRecordTypeInfosByName().get('Event').getRecordTypeId();
        contentAssgn.DCH_Asset_Tags__c = 'Christmas;New Year';
        insert contentAssgn;
        return contentAssgn;
    }

    /**
     * @description Get Content Version 
     * @return  `ContentVersion`
     */    
    public static ContentVersion getContentVersion(){
        ContentVersion conVerObj = new ContentVersion();
        conVerObj.Title = 'Test Title';
        conVerObj.PathOnClient = 'Product12345.JPEG';
        conVerObj.VersionData = Blob.valueOf('Test Content');
        conVerObj.IsMajorVersion = true;
        return conVerObj;
    }

    /**
     * @description Get Download Folder 
     * @param contentAssignmentId 
     * @param version_Id 
     * @param doc_Id 
     * @return  `D1_Download_Folder__c`
     */    
    public static D1_Download_Folder__c getDownloadFolder(id contentAssignmentId, string versionId , string docId){
        D1_Download_Folder__c objDF = new D1_Download_Folder__c();
        objDF.Description__c = 'Sample description';
        objDF.Folder_Link__c = '';
        objDF.Active__c = true;
        objDF.D1_Content_Assignment__c =contentAssignmentId;
        objDF.Folder_Content_version_Id__c=versionId; 
        objDF.Folder_Content_Document_Id__c=docId;
        insert objDF;
        return objDF;
    }

    /**
     * @description Get Download Folder Items 
     * @param downloadFolder 
     * @return  `D1_Download_Folder_Item__c`
     */    
    public static D1_Download_Folder_Item__c getDownloadFolderItem(D1_Content_Assignment__c downloadFolder){
        D1_Download_Folder_Item__c dwnldFolderItm = new D1_Download_Folder_Item__c();
        dwnldFolderItm.D1_Content_Assignment__c= downloadFolder.Id;
        dwnldFolderItm.Folder_Link__c='';
        dwnldFolderItm.Active__c=true;
        dwnldFolderItm.Description__c='Sample description';
        dwnldFolderItm.FolderItem_Content_Document_Id__c=downloadFolder.Folder_Content_Document_Id__c;
        dwnldFolderItm.FolderItem_Content_version_Id__c=downloadFolder.Folder_Content_version_Id__c;
        dwnldFolderItm.Type__c = 'Social Images';
        dwnldFolderItm.DCH_Asset_Tags__c = 'Social Post';
        insert dwnldFolderItm;
        return dwnldFolderItm;
    }
 
    /**
     * @description Get Contact Agreement
     * @param termsCon 
     * @return  `D1_Contact_Agreement__c`
     */    
    public static D1_Contact_Agreement__c getContactAgreement(D1_Terms_Conditions__c termsCon){
        D1_Contact_Agreement__c contAgg = new D1_Contact_Agreement__c();
        contAgg.D1_Terms_Conditions__c = termsCon.id;
        contAgg.Version__c =6;
        return contAgg;
    }

    /**
     * @description Get User Role
     * @param name 
     * @return  `userRole`
     */    
    public static userRole getUserRole(string name){
        userRole ur=new UserRole();
        ur.Name=name;
        insert ur;
        return ur;
    }

    /**
     * @description Get B2b Commerce Permission set Assignment
     * @param userObj 
     */    
    public static void b2bCommercePermissionset(User userObj){
        //user userObj = runAsUser('extuser1','DiageoOne External User');
        
         PermissionSet permissionSetObj = [SELECT Id FROM PermissionSet WHERE Label = 'B2B Commerce User'];
            List<PermissionSetAssignment> psAssignmentLst = [SELECT Id FROM PermissionSetAssignment  
                                                             WHERE PermissionSetId = :permissionSetObj.Id 
                                                             AND AssigneeId =:userObj.Id];
            if(psAssignmentLst == NULL || psAssignmentLst.size() == 0) {
                PermissionSetAssignment psObj = new PermissionSetAssignment();
                psObj.AssigneeId = userObj.Id;
                psObj.PermissionSetId = permissionSetObj.Id;
                insert psObj;
            }
    }
    
    /**
     * @description getBuyerAccount
     * @param accountId 
     * @return  `BuyerAccount`
     */    
    public static BuyerAccount getBuyerAccount(Id accountId){
        BuyerAccount buyerAccount = new BuyerAccount();
        buyerAccount.BuyerId =accountId;
        buyerAccount.Name = 'Test Buyer Account';
        buyerAccount.IsActive = true;
        buyerAccount.BuyerStatus = 'Active';
        //insert buyerAccount;
        return BuyerAccount;
    }
    
    /**
     * @description getWebStore
     * @return  `WebStore`
     */    
    public static WebStore getWebStore(){
        WebStore webstoreObj = new WebStore();
        webstoreObj.Name = 'Test Store';
        //insert webstoreObj;
        return webstoreObj;
    }
    
    /**
    * @description : creates a Wishlist instance
    * @param: {Id} accountId, {Id} webstoreId 
    * @return  `Wishlist`
    */
    public static Wishlist getWishlist(Id accountId, Id webstoreId){
        Wishlist wishList = new Wishlist();
        wishList.Name = 'TestWishList';
        wishList.AccountId = accountId;
        wishList.WebStoreId = webstoreId;
        return wishList;
    }
    
    /**
    * @description : creates a List of WishlistItem for
    *                given product list
    * @param: {Id} wishListId, {List<Product2>} prodList 
    * @return  `List<WishlistItem>`
    */
    public static List<WishlistItem> getWishlistItem(Id wishListId, List<Product2> prodList){
        List<WishlistItem> wishListItems = new List<WishlistItem>();
        for(Product2 prd : prodList){
            WishlistItem item = new WishlistItem();
            item.Name = prd.Name;
            Item.Product2Id = prd.Id;
            Item.WishlistId = wishListId;
            wishListItems.add(Item);
        }
        return wishListItems;
    }
    
    /**
     * @description getProduct
     * @return  `Product2`
     */    
    public static Product2 getProduct(){
        Product2 prodObj = new Product2();
        prodObj.Name = 'Test P';
        prodObj.IsActive = true;
        prodObj.Alcohol_Percentage__c = '50%';
        prodObj.Base_Unit_of_Measure__c = 'one';
        prodObj.SAP_Material_Id__c = '0000012345';
        //insert prodObj;
        return prodObj;
    }
    
    /**
    * @description getProductRecomm
    * @param {Id} masterProd, {Id} recommProd, {Id} countryRec
    * @return  `D1_Product_Recommendation__c`
    */
    public static D1_Product_Recommendation__c getProductRecomm(Id masterProd, Id recommProd, Id countryRec){
        D1_Product_Recommendation__c prodRecomm = new D1_Product_Recommendation__c();
        prodRecomm.Master_Product__c = masterProd;
        prodRecomm.Recommended_Product__c = recommProd;
        prodRecomm.Country__c = countryRec;
        prodRecomm.Is_Active__c = true;
        return prodRecomm;
    }
    
    /**
     * @description geProductVolumeConfiguration
     * @param type 
     * @return  `Product_Volume_Configuration__c`
     */    
    public static Product_Volume_Configuration__c geProductVolumeConfiguration(String type){
        Product_Volume_Configuration__c pvc1 = new Product_Volume_Configuration__c();
        pvc1.Type__c = type;
        pvc1.name='0.05L';
        pvc1.IntegrationID__c = '00A6';
        
        return pvc1;
    }
    
    /**
     * @description getPricebook2
     * @param portfolioId 
     * @return  `Pricebook2`
     */    
    public static Pricebook2 getPricebook2(String portfolioId){
        Pricebook2 priceBookObj = new Pricebook2();
        priceBookObj.IsActive = true;
        priceBookObj.PortfolioID__c = portfolioId;
        priceBookObj.Name = 'Test PB';
        return priceBookObj;
    }
    
    /**
     * @description getPricebookEntry
     * @param pricebookId 
     * @param productId 
     * @return  `PricebookEntry`
     */    
    public static PricebookEntry getPricebookEntry(Id pricebookId,Id productId){
        PricebookEntry priceBookEntryObj = new PricebookEntry();
        priceBookEntryObj.IsActive = true;
        priceBookEntryObj.UnitPrice = 0;
        priceBookEntryObj.Pricebook2Id =pricebookId;
        priceBookEntryObj.Product2Id =productId;
        return priceBookEntryObj;
    }
    
    /**
     * @description getWebCart
     * @param webStoreId 
     * @param accountId 
     * @param osId 
     * @param osId2 
     * @return  `WebCart`
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')    
    public static WebCart getWebCart(Id webStoreId,Id accountId,Id osId,Id osId2){
        WebCart webCArtObj = new WebCart();
        webCArtObj.Name = 'TestCart';   
        webCArtObj.WebStoreId = webStoreId;
        webCArtObj.AccountId = accountId;
        webCArtObj.Order_Split_1__c = osId;
        webCArtObj.Order_Split_2__c = osId2;
        webCArtObj.Status = 'Active';
        webCArtObj.CanViewPrice__c = true;
        //webCArtObj.Delivery_Address__c = 'test';
        webCArtObj.Status = 'Active';
        webCArtObj.PoNumber = '12345';
        webCArtObj.Split_2_PO_Number__c = '34567';
        //insert webCArtObj;
        return webCArtObj;
    }
    
    /**
     * @description getCommerceEntitlementPolicy
     * @param name 
     * @param portfolioId 
     * @return  `CommerceEntitlementPolicy`
     */    
    public static CommerceEntitlementPolicy getCommerceEntitlementPolicy(String name,String portfolioId){
        CommerceEntitlementPolicy entPolicyObj = new CommerceEntitlementPolicy();
        entPolicyObj.PortfolioID__c = portfolioId;
        entPolicyObj.Name = name;
        //entPolicyObj.CanViewPrice = true; 
        return entPolicyObj;
    }
    
    /**
     * @description getCommerceEntitlementProduct
     * @param productId 
     * @param policyId 
     * @return  `CommerceEntitlementProduct`
     */    
    public static CommerceEntitlementProduct getCommerceEntitlementProduct(Id productId, Id policyId){
        CommerceEntitlementProduct entProdObj = new CommerceEntitlementProduct();
        entProdObj.ProductId = productId;
        entProdObj.PolicyId = policyId;
        entProdObj.Portfolio_Item_ID__c = 'Test1234';
        return entProdObj;
    }

    /**
     * @description createTopic
     * @param topicName 
     * @return  `Topic`
     */    
    public static Topic createTopic(String topicName){
        Topic topic = new Topic();
        topic.Name = topicName;
        return topic;
    }

    /**
     * @description createKnowledgeKav
     * @param urlData 
     * @return  `Knowledge__kav`
     */    
    public static Knowledge__kav createKnowledgeKav(String urlData, String typeVal, String subType){
        Knowledge__kav kw = new Knowledge__kav();
        kw.Title = 'Sample';
        kw.Article_Types__c = subType;
        kw.Case_Type__c = typeVal;
        kw.Article_Body__c = 'Sample';
        kw.UrlName = urlData;
        return kw;
    }

    /**
     * @description setTopicAssignment
     * @param kwid 
     * @param topicId 
     * @return  `TopicAssignment`
     */    
    public static TopicAssignment setTopicAssignment(Id kwid, Id topicId){
        TopicAssignment ta = new TopicAssignment();
        ta.EntityId = kwid;
        ta.TopicId = topicId;
        return ta;
    }

    /**
     * @description setMarketKnowledgeArticle
     * @param kw_id 
     * @param geog_id 
     * @return  `Market_Knowledge_Article__c`
     */    
    /*public static Market_Knowledge_Article__c setMarketKnowledgeArticle(Id kw_id, Id geog_id){
        Market_Knowledge_Article__c kwGeog = new Market_Knowledge_Article__c();
        kwGeog.Knowledge__c = kw_Id;
        kwGeog.Market__c = geog_id;
        return kwGeog;
    }*/
    
    /**
     * @description getOrderDeliveryDate
     * @param orderSplitId 
     * @return  `Order_Delivery_Date__c`
     */    
    public static Order_Delivery_Date__c getOrderDeliveryDate(Id orderSplitId){
        DateTime todayDt = DateTime.now();
        Order_Delivery_Date__c orderDeliveryDate = new Order_Delivery_Date__c();
        orderDeliveryDate.Order_Split_ID__c=orderSplitId;
        orderDeliveryDate.Cutoff_datetime__c=DateTime.newInstanceGmt(todayDt.year(), todayDt.month(), todayDt.day(), todayDt.hour(), todayDt.minute(), todayDt.second()).addDays(3);
        orderDeliveryDate.Substitue_Delivery_Date__c=System.Today().addDays(4);
        orderDeliveryDate.Is_Delivery__c=true;
        orderDeliveryDate.Delivery_Date__c = System.Today().addDays(4);
        orderDeliveryDate.Delivery_Date_ID__c = 'Test';
        orderDeliveryDate.Substitue_Delivery_Date__c = System.Today().addDays(6);
        orderDeliveryDate.Is_Holiday__c = false;
        //insert orderDeliveryDate;
        return orderDeliveryDate;
    }
    
    /**
     * @description getPortfolioItem
     * @param prodId 
     * @param oSplitId 
     * @return  `Portfolio_Item__c`
     */    
    public static Portfolio_Item__c getPortfolioItem(Id prodId,Id oSplitId){
        Portfolio_Item__c portItem = new Portfolio_Item__c();
        portItem.Portfolio_ID__c ='PF-1234';
        portItem.Product__c = prodId;
        portItem.Order_Split__c = oSplitId;
        portItem.UnitPrice__c = 0;
        //insert portItem;
        return portItem;
    }
    
    /**
     * @description getCartItem
     * @param webCartId 
     * @return  `CartItem`
     */    
    public static CartItem getCartItem(Id webCartId){
        CartItem cartItem = new CartItem();
        cartItem.Name = 'Test Cart';
        cartItem.CartId=webCartId;
        cartItem.Sku='SKU_Test1';
        cartItem.SalesPrice=10.00;
        cartItem.Quantity=3.0;
        cartItem.Type='Product';
        return cartItem;
    }
    
    /**
     * @description getCartDeliveryGroup
     * @param webCartId 
     * @return  `CartDeliveryGroup`
     */    
    public static CartDeliveryGroup getCartDeliveryGroup(Id webCartId){
        CartDeliveryGroup cartDeliveryGroup = new CartDeliveryGroup();
        cartDeliveryGroup.CartId=webCartId;
        cartDeliveryGroup.Name='Default Delivery';
        return cartDeliveryGroup;
    }
    
    /**
     * @description getCartDeliveryGroup
     * @param accountId 
     * @return  `Order`
     */    
    public static Order getOrder(Id accountId){
        Order ordRec = new Order();
        ordRec.AccountId = accountId;
        ordRec.EffectiveDate = date.today();
        ordRec.Status = 'Draft';            
        return ordRec;
    }
    
    /**
     * @description getOrderItem
     * @param orderId 
     * @return  `OrderItem`
     */    
    public static OrderItem getOrderItem(Id orderId){
        OrderItem ordProd = new OrderItem();
        //ordProd.Product2Id = prodObj.id;
        ordProd.UnitPrice = 55.00;
        ordProd.Quantity = 5;
        ordProd.OrderId = orderId;
        ordProd.ListPrice = 10;
        return ordProd;
    }

    /**
     * @description Method is to handle D1_DuplicatePOWSDLMockTest and arguments passing are PO_Num , SAP_Order, SFDC_Num
     * @param poNUMINPUT 
     * @param sapORDERINPUT 
     * @param sfdcORDERINPUT 
     * @return  `List<D1_OrderDuplicatePOCheckWSDL.CONFLICTS_element>`
     */    
    public static List<D1_OrderDuplicatePOCheckWSDL.CONFLICTS_element> getOrderDuplicatePOCheckWSDL(string poNUMINPUT, String sapORDERINPUT, String sfdcORDERINPUT){
            List<D1_OrderDuplicatePOCheckWSDL.CONFLICTS_element> conflictList = new List<D1_OrderDuplicatePOCheckWSDL.CONFLICTS_element>();
            D1_OrderDuplicatePOCheckWSDL.CONFLICTS_element elementsObj = new D1_OrderDuplicatePOCheckWSDL.CONFLICTS_element();
            elementsObj.PO_NUM= poNUMINPUT;
            elementsObj.SAP_ORDER = sapORDERINPUT;
            elementsObj.SFDC_ORDER = sfdcORDERINPUT;
            conflictList.add(elementsObj);
            return conflictList;
    }

    /**
     * @description D1_OrderHistoryWSDLMockTest : method to get SalesOrderHistoricalInboun ItemResponse
     * @return  `D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Item_Response_D1`
     */    
    public static D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Item_Response_D1 getSalesOrderHistoricalInboundItemResponse(){
            D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Item_Response_D1 item = new  D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Item_Response_D1();
            item.ITEM_NUMBER ='test';
            item.PRODUCT ='test';
            item.DESCRIPTION ='test';
            item.QUANTITY ='test';
            item.SALES_UOM ='test';
            item.VALUE ='test';
            item.TAX ='test';
            item.CURRENCY_x ='test';
            item.REJECTED = false;
            item.PLANT ='test';
            item.REJECTION_REASON ='test';
            item.DELIVERED_QUANTITY ='test';
            return item;
    }

    /**
     * @description D1_OrderHistoryWSDLMockTest : method to get DT_SalesOrderHistoricalInbound_Header_Response_D1e
     * @return  `D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Header_Response_D1`
     */    
    public static D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Header_Response_D1 getSalesOrderHistoricalInboundHeaderResponse(){
            D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Header_Response_D1 order = new  D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Header_Response_D1();
            order.SAP_ORDER_NUM = 'test';
            order.SFDC_ORDER_NUM = 'test';
            order.ORDER_GROUP = 'test';
            order.STATUS = 'test';
            order.ORDER_DATETIME = DateTime.newInstance(2012, 7, 09, 3, 3, 3);
            order.REQ_DEL_DATE = date.newinstance(1960, 2, 17);
            order.CUSTOMER_REF = 'test';
            order.ORDER_METHOD = 'test';
            order.ORDER_TYPE = 'test';
            order.ORDER_REASON = 'test';
            order.VALUE = 'test';
            order.TAX = 'test';
            order.CURRENCY_x = 'test';
            order.DELIVERY_DATE = date.newinstance(1960, 2, 17);
            order.DELIVERY_PLANT = 'test';
            order.CUSTOMER_NO = '23456';
            return order;
    }

    /**
     * @description createCase
     * @param recordTypeId 
     * @param type 
     * @param subject 
     * @param description 
     * @param status 
     * @return  `Case`
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')      
    public static Case createCase(String recordTypeId, String type, String subject, String description, String status){
        Case cs = new Case();
        cs.RecordTypeId = recordTypeId;
        cs.Type = type;
        cs.D1_Subject__c = subject;
        cs.Description = description;
        cs.Status = status;
        return cs;
    }

    /**
     * @description createFeed
     * @param caseRec_id 
     * @param contentVersion_id 
     * @return  `FeedItem`
     */    
    public static FeedItem createFeed(Id caseRecid, Id contentVersionid){
        FeedItem feed = new FeedItem();
        feed.parentid = caseRecid;
        feed.type = 'ContentPost';
        feed.RelatedRecordId = contentVersionid;
        feed.Body = 'Hello';
        return feed;
    }
    
    /**
     * @description getSalesOrder
     * @return  `Sales_Order__c`
     */    
    public static Sales_Order__c getSalesOrder(){
        Sales_Order__c salesOrder = new Sales_Order__c();
        //salesOrder.Order_Summary__c = orderSummaryId;
        salesOrder.SAP_Order_Number__c = '12346';
        salesOrder.Contact_email__c = 'test@diageo.com';
        salesOrder.Delivery_Date__c = Date.today();
        salesOrder.Order_Status__c ='Queued';
        salesOrder.Purchase_Order_Number__c = '1245698';
        return salesOrder;
    }

    /**
     * @description insertOrderSplit
     * @return  `OrderSplit__c`
     */    
    public static OrderSplit__c insertOrderSplit(){
        Sales_Area__c sa= new Sales_Area__c();
        sa.Max_Order_Line_Items__c = 2;
        sa.Name ='Test Sales Area 123';
        insert sa; 
        
        OrderSplit__c oSpilt = new OrderSplit__c();
        oSpilt.Sales_Area__c = sa.Id;
        oSpilt.Description__c ='Test1234';
        oSpilt.Market_Description__c='Keg';
        oSpilt.Delivery_Day_Series__c=2;
        oSpilt.Max_future_order_days__c=56;
        insert oSpilt;
        return oSpilt;
    }

    /**
     * @description getCartItem
     * @return  `ConnectApi.CartItem`
     */    
    public static ConnectApi.CartItem getCartItem(){
        ConnectApi.CartItem cartItem = new ConnectApi.CartItem();
        cartItem.listPrice ='0';
        return cartItem;
    }

    /**
     * @description getCartProduct
     * @return  `ConnectApi.CartItemProduct`
     */    
    public static ConnectApi.CartItemProduct getCartProduct(){
        ConnectApi.CartItemProduct cartProduct = new ConnectApi.CartItemProduct();
        return cartProduct;
    }

    /**
     * @description getCartItemResult
     * @return  `ConnectApi.CartItemResult`
     */    
    public static ConnectApi.CartItemResult getCartItemResult(){
        ConnectApi.CartItemResult cartItemResult = new ConnectApi.CartItemResult();
        return cartItemResult;
    }

    /**
     * @description getCartItemDetails
     * @return  `ConnectApi.CartItemCollection`
     */    
    public static ConnectApi.CartItemCollection getCartItemDetails(){
        Product2 p = new Product2();
        p.Name = 'Test Pp';
        p.IsActive = true;
        p.Alcohol_Percentage__c = '60%';
        p.Base_Unit_of_Measure__c = 'one';
        p.SAP_Material_Id__c = '0000054321';
        insert p;
        
        ConnectApi.CartItemProduct cartProduct = getCartProduct();
        cartProduct.productId = p.Id;
        //cartProduct.thumbnailImage = new ConnectApi.ProductMedia();
        
        ConnectApi.CartItem cartItem = getCartItem();
        cartItem.productId = p.Id;
        cartItem.productDetails = cartProduct;
        
        ConnectApi.CartItemResult itemResult = getCartItemResult();
        itemResult.cartItem = cartItem;
        
        ConnectApi.CartItemCollection cc = new ConnectApi.CartItemCollection();
        cc.cartItems = new List<ConnectApi.CartItemResult>{itemResult};
        cc.cartSummary = new ConnectApi.CartSummary();
        
        return cc;
    }

    /**
     * @description Update Account Contact Relation object
     * @param acc 
     * @param con 
     * @return  `AccountContactRelation`
     */    
    public static AccountContactRelation returnACR(id acc, id con){
        AccountContactRelation acr = [Select id from AccountContactRelation where AccountID =:acc
                                      AND ContactID =: con];
        AccountContactRelation acrRecord = new AccountContactRelation(id=acr.id);  
        acrRecord.Contact_Type__c = 'Primary';
        acrRecord.D1_Roles__c = 'My Contracts;Financial Documents'; 
        acrRecord.D1_Active__c = True;
        return acrRecord;
    }

    /**
     * @description getDistributerAccountRecord
     * @return  `Account`
     */    
    public static Account getDistributerAccountRecord(){
        Account distAccount = new Account();
        distAccount.Name = 'Test Distributor Account';
        distAccount.Country__c = geoMap.get('Country');
        distAccount.Hub__c = geoMap.get('Hub');
        distAccount.Market__c = geoMap.get('Market');
        distAccount.Cluster__c = geoMap.get('Cluster');
        distAccount.Region__c = geoMap.get('Region');
        distAccount.Area__c = geoMap.get('Area');
        distAccount.RecordTypeId =  distRecTypeId;
        distAccount.Outlet_Email_Address__c = 'test@test.com';
        distAccount.Global_Channel__c = 'Off Trade';
        distAccount.Global_Sub_Channel__c = 'Retailer';
        distAccount.Global_Segment__c = 'Discounter';
        distAccount.Global_Sub_Segment__c = 'Modern Discounter';
        distAccount.BillingCountry = 'Australia';
        return distAccount; 
    }

    /**
     * @description create Outlet Member record
     * @param outletId 
     * @param distributorId 
     * @return  `Supplier_Outlet__c`
     */    
    public static Supplier_Outlet__c suppOutletRec(Id outletId, Id distributorId){
        Supplier_Outlet__c supOutltObj = new Supplier_Outlet__c();
        supOutltObj.Outlet__c = outletId;
        supOutltObj.Distributor_Wholesaler__c = distributorId;
        return supOutltObj;
    } 

    /**
     * @description getMap
     * @param countryId 
     * @param testProductId 
     * @return  `Market_Assortment_Product__c`
     */    
    public static Market_Assortment_Product__c getMap(Id countryId, String testProductId){
        Market_Assortment_Product__c testMAP = new Market_Assortment_Product__c(Market_Assortment__c=countryId,D1_Enabled__c=true,Product__c=testProductId,Transfer_Order_Product_New__c='Off Trade;On Trade;Route to Market');
        return testMAP;
        
    }
    
    /**
     * @description this method is to return userResult Wrapper
     * @return  `D1_UserRegistrationValidator.UserValidationResultWrapper`
     */    
    public static D1_UserRegistrationValidator.UserValidationResultWrapper getUserResultWrapper()
    {
        D1_UserRegistrationValidator.UserValidationResultWrapper userResultWrapper = new D1_UserRegistrationValidator.UserValidationResultWrapper();
        userResultWrapper.isSuccess = True;
        userResultWrapper.isUserExists = True;
        userResultWrapper.isNoPrimaryContact = true ;
        return userResultWrapper;
    }

    /**
     * @description this method is for returning contact wrapper
     * @param contactId 
     * @return  `D1_UserRegistrationValidator.ContactWrapper`
     */    
    public static D1_UserRegistrationValidator.ContactWrapper getContactWrapper(Id contactId){
        D1_UserRegistrationValidator.ContactWrapper conWrap = new D1_UserRegistrationValidator.ContactWrapper();
        conWrap.contactId = contactId;
        conWrap.accountName ='Test';
        conWrap.accountAddress = 'Test';
        conWrap.email = 'abc@diageo.com';
        conWrap.firstName = 'john';
        conWrap.lastName = 'Test';
        conWrap.mobile = '987456987';
        return conWrap;
    }
   
    /**
     * @description getOrderItemSummaryWrapper
     * @return  `D1_SendSalesOrderToSAP.OrderItemSummaryWrapper`
     */    
    public static D1_SendSalesOrderToSAP.OrderItemSummaryWrapper getOrderItemSummaryWrapper(){
        D1_SendSalesOrderToSAP.OrderItemSummaryWrapper odrWrapObj =  new D1_SendSalesOrderToSAP.OrderItemSummaryWrapper();
        odrWrapObj.QtyOrdered = 1;
        odrWrapObj.ItemCount = 1.0;
        odrWrapObj.Plant = 'test Plant';
        odrWrapObj.SelectedMaterial = 'Material Val';
        odrWrapObj.IdVal = '1245987';
        odrWrapObj.UnitOfMeasure = 'UOM Val';
        odrWrapObj.DiscountSurcharge = 1;
        return odrWrapObj;
    }

    /**
     * @description getSalesOrderItemResponseList
     * @return  `List<D1_OrderSimulationController.DT_SalesOrderSimulateSF_Item_Response_D1>`
     */    
    public static List<D1_OrderSimulationController.DT_SalesOrderSimulateSF_Item_Response_D1> getSalesOrderItemResponseList(){
        List<D1_OrderSimulationController.DT_SalesOrderSimulateSF_Item_Response_D1> itemResponseList = new List<D1_OrderSimulationController.DT_SalesOrderSimulateSF_Item_Response_D1>();
        D1_OrderSimulationController.DT_SalesOrderSimulateSF_Item_Response_D1 itemResponse =  new D1_OrderSimulationController.DT_SalesOrderSimulateSF_Item_Response_D1();
        itemResponse.PRICE_ERROR = false;           
        itemResponseList.add(itemResponse);
        return itemResponseList;
    }

    /**
     * @description getSalesOrderItemResponse
     * @return  `D1_OrderSimulationController.DT_SalesOrderSimulateSF_Response_D1`
     */    
    public static D1_OrderSimulationController.DT_SalesOrderSimulateSF_Response_D1 getSalesOrderItemResponse(){
        List<D1_OrderSimulationController.DT_SalesOrderSimulate_Message_Response> msgResponseList = new List<D1_OrderSimulationController.DT_SalesOrderSimulate_Message_Response>();
            D1_OrderSimulationController.DT_SalesOrderSimulate_Message_Response  msgResponse = new D1_OrderSimulationController.DT_SalesOrderSimulate_Message_Response();
            msgResponse.TYPE_x = 'E';
            msgResponse.MESSAGE = 'Message';
            msgResponse.ID = '12345';
            msgResponse.NUMBER_x = '123425';  
            msgResponseList.add(msgResponse);
        D1_OrderSimulationController.DT_SalesOrderSimulateSF_Response_D1 responseX =  new D1_OrderSimulationController.DT_SalesOrderSimulateSF_Response_D1();           
        responseX.VBELN = 'Test';
        responseX.STATUS = 'Success';
        responseX.MESSAGES  = msgResponseList;
        return responseX;
    }

    /**
     * @description getFeedItem
     * @param caseRecId 
     * @param feedBody 
     * @param visibility 
     * @return  `Feeditem`
     */    
    public static Feeditem getFeedItem(Id caseRecId, String feedBody, String visibility){
        FeedItem feedTest = new FeedItem();
        feedTest.Body = feedBody;
        feedTest.ParentId = caseRecId;
        feedTest.Visibility = visibility;
        return feedTest;
    }

    /**
     * @description getContract
     * @param accountId 
     * @param recordTypeId 
     * @return  `Contract`
     */    
    public static Contract getContract(Id accountId, Id recordTypeId){
        Contract objContract = new Contract();
        objContract.AccountId = accountId;
        objContract.Status = 'Draft';
        objContract.StartDate = System.today();
        objContract.Contract_End_Date__c = System.today()+7;
        objContract.UOS_Target__c = 45;
        objContract.UOS_AP_Rate__c = 5;
        objContract.UOS_Rebate_Rate__c = 2;
        objContract.RecordTypeId = recordTypeId;
        objContract.UOS_Earnt__c=10;
        return objContract;
    }  

    /**
     * @description getOutletContract
     * @param contractRecordId 
     * @param outletAccountId 
     * @return  `Outlet_Contract__c`
     */    
    public static Outlet_Contract__c getOutletContract(Id contractRecordId, Id outletAccountId){
        Outlet_Contract__c oc = new Outlet_Contract__c();
        oc.Contract__c = contractRecordId;
        oc.Outlet__c = outletAccountId;
        return oc;
    }

    /**
     * @description createLead
     * @return  `Lead`
     */    
    public static Lead createLead(){
        Lead newLead = new Lead ();
        newLead.Company='TestCompany'; 
        newLead.Status='Open';
        newLead.FirstName='Test';
        newLead.LastName='Tester';
        newLead.Email = 'email2@gmail.com';
        newLead.MobilePrefix__c = '+44';
        newLead.Mobile__c = '1512123452';
        newLead.PhonePrefix__c = '+44';
        newLead.Phone__c = '4561237892';
        return newLead;
    }
    
    /**
     * @description Creates BuyerGroup
     * @param portfolioId 
     * @return  BuyerGroup
     */    
    public static BuyerGroup getBuyerGroup(String portfolioId){
        BuyerGroup bg = new BuyerGroup();
        bg.Name = 'Test BuyerGroup';
        bg.PortfolioID__c = portfolioId;
        return bg;
    }
    
    /**
     * @description Creates BuyerGroupMember
     * @param buyerGrpId 
     * @param acc 
     * @return  BuyerGroupMember
     */    
    public static BuyerGroupMember getBuyerGroupMember(Id buyerGrpId, Account acc){
        BuyerGroupMember bgm = new BuyerGroupMember();
        bgm.BuyerGroupId = buyerGrpId;
        bgm.BuyerId = acc.Id;
        return bgm;
    }
    
    public static D1_UserRegistrationDetailWrapper getD1UserRegistrationDetailWrapper(Account acc,Contact con){
        
        D1_UserRegistrationDetailWrapper userWrapper1 = new D1_UserRegistrationDetailWrapper();
        userWrapper1.accountId = acc.Id;
        userWrapper1.contactId = con.Id;
        userWrapper1.email = 'testclassextuser1@test.com';
        userWrapper1.firstName = 'John';
        userWrapper1.lastName = 'Dario';
        userWrapper1.mobile = '7895448';
        userWrapper1.languageLocaleKey= 'en_GB';
        userWrapper1.userCountryCode='es';
        return userWrapper1;
    }
    
    public static D1_AddUserPermissionsController.UserPermissionWrapper getUserPermissionWrapper(List<D1_AddUserPermissionsController.AccountWrapper> awList,D1_AddUserPermissionsController.AccountWrapper payerAccWrap){
        
        D1_AddUserPermissionsController.UserPermissionWrapper upw = new D1_AddUserPermissionsController.UserPermissionWrapper();
        upw.index=6;
        upw.accountLabel='TestLabel';
        upw.accountWrapperList=awList;
        upw.payerLabel='TestPayerLabel';
        upw.payerAccountWrapper=payerAccWrap;
        return upw;
    }
    
    public static D1_AddUserPermissionsController.AccountWrapper getAccountWrapper(Account acc,List<D1_AddUserPermissionsController.PermissionWrapper> pwList){
        
        D1_AddUserPermissionsController.AccountWrapper aw = new D1_AddUserPermissionsController.AccountWrapper();
        aw.accountId=acc.Id;
        aw.accountWrapperKey='TestLabel';
        aw.accountNumber='345654';
        aw.accountName=acc.Name;
        aw.accountCity='London';
        aw.accountType='Direct Buyer';
        aw.isSelected=true;
        aw.isDisabled=false;
        aw.permissionWrapperList = pwList;
        return aw;
    }
    
    public static D1_AddUserPermissionsController.PermissionWrapper getPermissionWrapper(){
        
        D1_AddUserPermissionsController.PermissionWrapper pw = new D1_AddUserPermissionsController.PermissionWrapper();
        pw.permissionWrapperKey='TestWrapKey';
        pw.permissionLabel='TestPermissionLabel';
        pw.permissionName='User Management';
        pw.isDefault=true;
        pw.isDisabled=false;
        pw.isSelected=true;
        return pw;
    }
    
    
    public static Campaign getCampaignList(Id countryId){
        Campaign objTargetList = new Campaign();
        objTargetList.isActive = True;
        objTargetList.Country__c = countryId;
        objTargetList.Name = 'Target List 1';
        return objTargetList;
    }

    @SuppressWarnings('PMD.ExcessiveParameterList') 
    public static D1_Content_Assignment__c getContentAssignment(string eventId, string brandId, string faultFixerId, string dchTags){
        Id brandRecordTypeId = Schema.SObjectType.D1_Content_Assignment__c.getRecordTypeInfosByName().get('Brand').getRecordTypeId();
        Id eventRecordTypeId = Schema.SObjectType.D1_Content_Assignment__c.getRecordTypeInfosByName().get('Event').getRecordTypeId();
        Id allAssetRecordTypeId = Schema.SObjectType.D1_Content_Assignment__c.getRecordTypeInfosByName().get('All Asset').getRecordTypeId();
        Id faultFixerRecordTypeId = Schema.SObjectType.D1_Content_Assignment__c.getRecordTypeInfosByName().get('Fault Fixer').getRecordTypeId();
        Id caRecordTypeId = null;
        //Get RecordType Id
        if(String.isNotBlank(brandId)){
            caRecordTypeId = brandRecordTypeId;
        }else if(String.isNotBlank(eventId)){
            caRecordTypeId = eventRecordTypeId;
        }else if(String.isNotBlank(faultFixerId)){
            caRecordTypeId = faultFixerRecordTypeId;
        }else{
            caRecordTypeId = allAssetRecordTypeId;
        }
        
        D1_Content_Assignment__c contentAssignment = new D1_Content_Assignment__c();
        contentAssignment.D1_Event__c = eventId;
        contentAssignment.D1_Brand__c = brandId;
        contentAssignment.D1_Fault_Fixer__c = faultFixerId;
        contentAssignment.Popular_Brand__c = false;
        contentAssignment.Active__c = true;
        contentAssignment.Geography__c = [SELECT Id, Code__c FROM Geography__c WHERE Code__c='GB' LIMIT 1].Id;
        contentAssignment.RecordTypeId = Schema.SObjectType.D1_Content_Assignment__c.getRecordTypeInfosByName().get('Event').getRecordTypeId();
        contentAssignment.DCH_Asset_Tags__c = dchTags;

        return contentAssignment;
    }
}