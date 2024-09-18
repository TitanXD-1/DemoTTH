/**

*@description : EDGE_UtilityClassCoverage

*@purpose : This test class will give the coverage of EDGE_UtilityClass.

*VERSION     AUTHOR            DATE              DETAIL
 2.0     Joshraj Sen      21/02/2022       ES20-12118
 3.0     Joshraj Sen      12/05/2022       ES20-12516 
*/

@isTest
public class EDGE_UtilityClassCoverage {
    
    final static String OUTLETRECORDTYPEID = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();  
    
    /**

* @description : getTableBodyTest - This method will be used to provide coverage for order functionality methods of EDGE_UtilityClass.

* @return : void 

*/
    @isTest
    public static void getTableBodyTest(){
        
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
        List<Order__c> ord1 = new List<Order__c>();
        List<Order_Item__c> ordItem1 = new List<Order_Item__c>();
        Map< String, List<Order_Item__c>> mapofLineitem = new Map< String, List<Order_Item__c>>();
        Map<Id,Product__c> mapProductbyUnit = new Map<Id,Product__c>();
        Map<Id,Product__c> mapProductbySize = new Map<Id,Product__c>();
        Map<Id,Product__c> mapProductbyQuantity = new Map<Id,Product__c>();  
        Map<Id,List<Product_Variant__c>> mapProductWithVariant = new Map<Id,List<Product_Variant__c>>();
        Map<Id,List<Product_Pricing__c>> mapProductWithPricing = new Map<Id,List<Product_Pricing__c>>();
        List<Product__c> updateActiveProductList = new List<Product__c>();
        Set<Id> marketIdSet = new Set<Id>();
        Date startDate = System.today();
        Date endDate = System.today().addDays(10);
        MAP<String,String> metaDataApprovalMap = new MAP<String,String>();
        List<Outlet_Attributes_for_Approval__mdt>  outletAttributesData = new List<Outlet_Attributes_for_Approval__mdt>();
        outletAttributesData = [SELECT MasterLabel, QualifiedApiName,Market_Setting_Field_Name__c FROM Outlet_Attributes_for_Approval__mdt WHERE Related_Object__c = 'License__c' ];
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager; 
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.id;
        insert salesRep; 
        EDGE_UtilityTestClass.createOrgSettings();
        
        /*Market_Setting__c market = EDGE_UtilityTestClass.getMarketSetting(countryId);
market.A_P_Threshold__c = 100;
insert market; */
        Org_Setting__c orgSetting = Org_Setting__c.getOrgDefaults();
       	orgSetting.Run_Triggers__c=false;
        update orgSetting;
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        insert pickupOption;
        
        Pick_Up_Options__c pickupOption1 = EDGE_UtilityTestClass.getPickUpOption(countryId,'Reason Code');
        pickupOption1.Name = 'Gold[AU]';
        //insert pickupOption1;
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        outlet.ShippingCountry='Australia';
        insert outlet;
        
        Account wholesaler = EDGE_UtilityTestClass.getDistriAccRec();
        wholesaler.ShippingCountry='Australia';
        insert wholesaler;
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
        Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
        insert objContract;
        
        Order__c posOrderGroup = EDGE_UtilityTestClass.getPOSOrderGroup(salesRep.Id, outlet.Id, objContract.Id);
        posOrderGroup.Total_A_P_Cost__c = 500;
        insert posOrderGroup;
        
        posOrderGroup.Status__c = 'Ready for Order';
        update posOrderGroup;
        
      
        Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
        deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
        deliveryPartner.Batch_Notification__c = False;
        insert deliveryPartner;
        
        
        
        String freeGoodsOrderId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Free Goods').getRecordTypeId();
        Order__c freeGoodsOrder = new Order__c();
        freeGoodsOrder.RecordTypeId = freeGoodsOrderId;
        freeGoodsOrder.Account__c = outlet.Id;
        freeGoodsOrder.Delivery_Partner__c = deliveryPartner.Id;
        freeGoodsOrder.Status__c = 'Ready For Order';
        freeGoodsOrder.Sales_Representative__c = salesRep.Id;
        freeGoodsOrder.Preferred_Delivery_Date__c = Date.today();
        freeGoodsOrder.Source_Application__c = 'Diageo One';
        freeGoodsOrder.Delivery_Location__c = 'Shed';
        //freeGoodsOrder.Delivery_instructions__c= 'Careful';
        
        String transferOrderId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Transfer Order').getRecordTypeId();
        Order__c transferOrder = new Order__c();
        transferOrder.RecordTypeId = transferOrderId;
        transferOrder.Account__c = outlet.Id;
        transferOrder.Wholesaler__c =wholesaler.id;
        transferOrder.Status__c = 'Ready For Order';
        transferOrder.Sales_Representative__c = salesRep.Id;
        transferOrder.Preferred_Delivery_Date__c = Date.today();
        transferOrder.Source_Application__c = 'EDGE 365';
        //transferOrder.Delivery_instructions__c= 'Careful';
        
        Order__c posOrder = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
        posOrder.Order_Type__c = 'Shed';
        posOrder.Status__c = 'Draft';
        posOrder.Total_A_P_Cost__c = 100;
        posOrder.Order_Group__c = posOrderGroup.id;
        posOrder.Source_Application__c = 'Diageo One';
        posOrder.Delivery_Location__c = 'Outlet';
        posOrder.Delivery_Partner__c = deliveryPartner.Id;
        ord1.add(posOrder);
        ord1.add(freeGoodsOrder);
        ord1.add(transferOrder);
        insert ord1;
        System.debug(LoggingLevel.DEBUG,'Line 128 - '+ Limits.getQueries());
        
        Test.startTest();
        
        Product__c objProduct = EDGE_UtilityTestClass.getProd();
        objProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
        objProduct.Supplier_Partner__c = deliveryPartner.Id;
        objProduct.Pricing_Type__c = 'By Unit';
        objProduct.Units_per_POS__c = 10.0;
        objProduct.Diageo_Cost__c = 40;
        objProduct.Outlet_Cost__c = 50;
        objProduct.Start_Date__c = Date.Today();
        objProduct.POS_Item_Short_Description__c = 'Good';
        insert objProduct;
        
        Market_Assortment_Product__c testMAP = new Market_Assortment_Product__c(Market_Assortment__c=countryId,Product__c=objProduct.Id);
         insert testMAP;
        
        system.assert(objProduct.Id != null,'Product Present');
        mapProductbyUnit.put(objProduct.Id,objProduct);
        if(mapProductbyUnit.size()>0){
            updateActiveProductList = EDGE_UtilityClass.activateProductByUnit(mapProductbyUnit, updateActiveProductList);
        }
        
        objProduct.Pricing_Type__c = 'By Size';
        update objProduct;
        
        Product_Variant__c prodVar = new Product_Variant__c();
        prodVar.RecordTypeId = Product_Variant__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS Uniform').getRecordTypeId();
        prodVar.Product__c = objProduct.Id;
        prodVar.Gender__c = 'Male';
        prodVar.Paper_Finish__c = 'Test';
        prodVar.Unit_Price__c = 40;
        prodVar.Size__c = 'S';
        prodVar.Colour__c = 'White';
        insert prodVar;
        
        orgSetting.Run_Triggers__c=true;
        update orgSetting;
        
        mapProductbySize.put(objProduct.Id,objProduct);
        mapProductWithVariant.put(objProduct.Id,new List<Product_Variant__c>{prodVar});
        if(mapProductbySize.size()>0){
            updateActiveProductList = EDGE_UtilityClass.activateProductBySize(mapProductWithVariant, mapProductbySize, updateActiveProductList);
        }
          
        objProduct.Pricing_Type__c = 'By Quantity';
        update objProduct;
        
        Product_Pricing__c prodPricRec = new Product_pricing__c();
        prodPricRec.RecordTypeId = Product_Pricing__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
        prodPricRec.Product__c = objProduct.Id;
        prodPricRec.Range_Start__c = 15;
        prodPricRec.Range_End__c = 40;
        prodPricRec.Range_Price__c = 100;
        insert prodPricRec;
        
        mapProductbyQuantity.put(objProduct.Id,objProduct);
        mapProductWithPricing.put(objProduct.Id, new List<Product_Pricing__c>{prodPricRec});
        if(mapProductbyQuantity.size()>0){
            updateActiveProductList = EDGE_UtilityClass.activateProductByQuantity(mapProductWithPricing, mapProductbyQuantity, updateActiveProductList);
        }
        
        String allocationStockRecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
        Stock__c allocationStock = EDGE_UtilityTestClass.getStock(countryId, objProduct.Id, salesRep.Id);
        allocationStock.RecordTypeId = allocationStockRecordTypeId;
        allocationStock.Original_Stock__c = 400;
        allocationStock.Consumed_Stock__c = 100;
        insert allocationStock;
        
        String transferOrderItemId = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Transfer Order Item').getRecordTypeId();
        Order_Item__c transferOrderItem = new Order_Item__c();
        transferOrderItem.RecordTypeId = transferOrderItemId;
        transferOrderItem.Product__c = objProduct.id;
        transferOrderItem.Order__c = transferOrder.id;
        transferOrderItem.Quantity__c = 2 ;
        //transferOrderItem.Selected_UoM__c = 'BHY' ;
        transferOrderItem.Status__c = 'Ready for Order';
        
        String freeGoodsOrderItemId = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Free Goods').getRecordTypeId();
        Order_Item__c freeGoodsOrderItem = new Order_Item__c();
        freeGoodsOrderItem.RecordTypeId = freeGoodsOrderItemId;
        freeGoodsOrderItem.Product__c = objProduct.id;
        freeGoodsOrderItem.Order__c = freeGoodsOrder.id;
        freeGoodsOrderItem.Quantity__c = 2 ;
        //freeGoodsOrderItem.Selected_UoM__c = 'BHY' ;
        freeGoodsOrderItem.Status__c = 'Ready for Order';
        
        Order_Item__c orderItem1 = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, posOrder.Id);
        orderItem1.Type__c = 'Warehouse';
        orderItem1.Product_Variant__c = prodVar.Id;
        orderItem1.Stock__c = allocationStock.Id;
        orderItem1.Quantity__c = 80;
        orderItem1.Note__c = 'Test';
        orderItem1.Text_to_Print__c = 'HiTest';
        orderItem1.Status__c = 'Ready for Order';
        ordItem1.add(orderItem1);
        ordItem1.add(freeGoodsOrderItem);
        ordItem1.add(transferOrderItem);
        insert ordItem1; 
        
        
        mapofLineitem.put(posOrder.Id, ordItem1);
        Map<String, String> labelToTranslatedStrMap = EDGE_UtilityClass.translate(new List<String>{'EDGE_ClientCode', 'EDGE_OutletID','EDGE_OutletName','EDGE_SalesRepName','EDGE_SalesRepMobile','EDGE_SalesRepEmail','EDGE_ToDelivery',
            'EDGE_Address','EDGE_City','EDGE_State','EDGE_PostalCode','EDGE_Country','EDGE_OrderNumber','EDGE_ProductCode','EDGE_Quantity','EDGE_Notes',
            'EDGE_TextToPrint','EDGE_Size','EDGE_Gender','EDGE_Colour','EDGE_PaperFinish'}, 'en_US');
        marketIdSet.add(countryId);
        for(Outlet_Attributes_for_Approval__mdt oa : outletAttributesData){
            metaDataApprovalMap.put(oa.MasterLabel,oa.Market_Setting_Field_Name__c);
        } 
        EDGE_UtilityClass.getTableBody(ord1,mapofLineitem,null,null);
        EDGE_UtilityClass.getTableBody(ord1,mapofLineitem,'en_US',labelToTranslatedStrMap);
        EDGE_UtilityClass.getCountryMarketSetting();
        EDGE_UtilityClass.getFreeGoodsMail(ord1, mapofLineitem, null, null);
        EDGE_UtilityClass.getFreeGoodsMail(ord1, mapofLineitem, 'en_US', labelToTranslatedStrMap);
        EDGE_UtilityClass.checkForNull(orderItem1.id);
        EDGE_UtilityClass.checkForNull('val');
        EDGE_UtilityClass.checkForNullId(orderItem1.id);
        
        EDGE_UtilityClass.getCurrWeekNumberInCycle(startDate, endDate);
        EDGE_UtilityClass.getFieldType('Account', 'Approver_1__c');
        EDGE_UtilityClass.getMarketSettingMap(marketIdSet, metaDataApprovalMap.values());
        
        
        Set<Id> contentVersionIdSet = new Set<Id>();
        ContentVersion conVerRecPDF1 = EDGE_UtilityTestClass.gerConVerRec('Product12345.JPEG');
        conVerRecPDF1.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Order Product').getRecordTypeId();
        conVerRecPDF1.Content_Type__c = 'Order Product Image';
        conVerRecPDF1.Title = 'OutletRes.pdf';
        insert conVerRecPDF1;
       
        contentVersionIdSet.add(conVerRecPDF1.Id);
        
        ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id IN :contentVersionIdSet];
        
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId= orderItem1.id;
        contentlink.ShareType= 'V';
        contentlink.ContentDocumentId=testcontent.ContentDocumentId;
        contentlink.Visibility = 'AllUsers';
        insert contentlink; 
        
        
        List<Messaging.Emailfileattachment> fileAttachments= EDGE_UtilityClass.getAttachment(ord1);
        EDGE_UtilityClass.getTOAttachments(ord1);
        EDGE_UtilityClass.getMrktSttngForCountries(marketIdSet, metaDataApprovalMap);
        EDGE_UtilityClass.generateErrString('errorStr', new List<String>{'This is error field'});
        System.debug(LoggingLevel.DEBUG,'Line 265 - '+ Limits.getQueries());
        Test.stopTest();
        EDGE_UtilityClass.setEmailBody(fileAttachments, wholesaler, deliveryPartner, 'Hello');
    }
    
    /**
     *  @description : testcheckMrktSttngVldsForAccount- This method is used to coverage market setting based validation functionalities for Account
     
     *  @return : void  
*/
    @isTest
    public static void testcheckMrktSttngVldsForAccount(){ 
        
        User salesRep;
        User mdm;
        List<User> users = new List<User>();
        
        User adminUser= EDGE_UtilityTestClass.runAsUser('sysadminuser','System Administrator');
        adminUser.Default_Country__c = 'AU';
        adminUser.Available_Countries__c = 'AU';
        users.add(adminUser);
        
        
        User adminUser1= EDGE_UtilityTestClass.runAsUser('sysadminuser1','System Administrator');
        adminUser1.Default_Country__c = 'AU';
        adminUser1.Available_Countries__c = 'AU';
        users.add(adminUser1);
        
        insert users;
        
        System.debug(LoggingLevel.DEBUG,'296 : Utility class covergae Limits.getQueries() : '+ Limits.getQueries());
        
        //Activate the trigger
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId  = EDGE_UtilityTestClass.setupCountry('AU');
        
        System.debug(LoggingLevel.DEBUG,'302 : Utility class covergae Limits.getQueries() : '+ Limits.getQueries());
        
        Market_Setting__c marketsetting = EDGE_UtilityTestClass.getMarketSetting(countryId);
        marketsetting.Geography__c = countryId;
        marketsetting.Outlet_Closed_Status_Check__c = True;
        marketsetting.Threshold_Format__c = 'Percent';
        insert marketsetting;
        
        System.assert(marketsetting.Id!=null,'MarKet Setting Present');
        
        //Field permission set
        Field_Permission_Set__c fps = new Field_Permission_Set__c();
        fps.Type__c = 'Outlet';
        fps.Market_Setting__c = marketsetting.id;
        insert fps;
        
        List<Field_Permission__c> fpList = new List<Field_Permission__c>();
        //field permission
        Field_Permission__c fp = new Field_Permission__c();
        fp.Related_Object__c = 'Account';
        fp.Permission__c = 'Editable - Manager & MDM Approval Required';
        fp.Field__c = 'Centrally_Managed__c';
        fp.Dependent_Fields__c = 'Centrally_Managed_Note__c';
        fp.Field_Permission_Set__c = fps.id;
        fpList.add(fp);
        //insert fp;
        
        Field_Permission__c fp1 = new Field_Permission__c();
        fp1.Related_Object__c = 'Account';
        fp1.Permission__c = 'Editable - MDM Approval Required';
        fp1.Field__c  = 'Centrally_Managed_Note__c';
        fp1.Field_Permission_Set__c = fps.id;
        //insert fp1;
        fpList.add(fp1);
        
        Field_Permission__c fp2 = new Field_Permission__c();
        fp2.Related_Object__c = 'Account';
        fp2.Permission__c = 'Editable ';
        fp2.Field__c  = 'Local_Segment_Advanced_Analytics__c';
        fp2.Field_Permission_Set__c = fps.id;
        //insert fp2;
        fpList.add(fp2);
        
        Database.insert(fpList);
        
        System.debug(LoggingLevel.DEBUG,'347 : Utility class covergae Limits.getQueries() : '+ Limits.getQueries());

        EDGE_UtilityClass.stopTriggerToRun = false;
        
        //Creating  Pick Up Option
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold [AU]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        insert pickupOption;
       
        /*Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Business Unit');
insert terriHierBU;

Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Sales Area');
terriHierSA.Parent_BU__c = terriHierBU.Id;
insert terriHierSA;

Territory_Hierarchy__c terriHier = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Region');
terriHier.Parent_BU__c = terriHierSA.Id;
insert terriHier;    */
        
        System.runAs(adminUser1){
            Group grp = new Group(Name = 'AU_MDM', Type = 'Queue');
            insert grp;        
            QueueSobject mappingObject = new QueueSobject(QueueId = grp.Id, SobjectType = 'Field_Change_Request__c');
            insert mappingObject;
            
        }
        System.debug(LoggingLevel.DEBUG,'377 : Utility class covergae Limits.getQueries() : '+ Limits.getQueries());
        Test.startTest();
        /* Territory__c terr= EDGE_UtilityTestClass.getTerritoryRec();
terr.Territory_Type__c = 'Sales';
terr.Region__c = terriHier.Id;
terr.Sales_Area__c = terriHierSA.Id;
terr.Business_Unit__c = terriHierBU.Id;
terr.Country__c = countryId;
insert terr;  
system.debug('9Query' +Limits.getQueries());*/
        Account acc1 = new Account();
        acc1 =  EDGE_UtilityTestClass.getOutletRecord();
        acc1.RecordTypeId = OUTLETRECORDTYPEID;
        acc1.BillingStreet ='17 Asian Highway 45';
        acc1.BillingCity =  'Tasmania';
        acc1.BillingPostalCode = '5668';
        acc1.BillingState = 'Tasmania';
        acc1.BillingPostalCode = '5668';
        acc1.BillingCountryCode = 'AU';
        acc1.Country__c= countryId;
        acc1.Status__c = 'Active';
        acc1.Minimum_Activation_Standards__c = 60.00;
        acc1.Minimum_Product_Assortment__c  = 50.00;   
        acc1.Outlet_Visit_Prioritisation_Grade__c =pickupOption.Id; 
        //acc1.primary_sales_territory__c = terr.Id;
        // acc1.Primary_Sales_Territory_Region__c = terriHier.Id;
        acc1.Centrally_Managed__c = false;
        acc1.Centrally_Managed_Note__c = '';
        acc1.Website = 'www.test11.com';
        acc1.Total_Virtual_Calls__c = 3;
        acc1.Local_Segment_Advanced_Analytics__c = 'Rurals';
        acc1.ShippingCountry='Australia';
        insert acc1; 
        
        System.debug(LoggingLevel.DEBUG,'411 : Utility class covergae Limits.getQueries() : '+ Limits.getQueries());
        /*  Outlet_Territory__c outletTerr = new Outlet_Territory__c();
outletTerr.Territory__c = terr.Id;
outletTerr.Outlet__c = acc1.Id;
insert outletTerr;*/
        
        System.runAs(adminUser){
            
            //Creating Sales Rep 
            mdm= EDGE_UtilityTestClass.runAsUser('MDM','Master Data Manager');
            mdm.Available_Countries__c = 'AU';
            users.add(mdm);
            
            /*  insert mdm;
System.assert(mdm.Id!=null); */
            
            //Creating Sales Rep 
            salesRep= EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
            salesRep.Available_Countries__c = 'AU';
            salesRep.ManagerId = adminUser1.Id;
            insert salesRep;
            System.debug(LoggingLevel.DEBUG,'432 : Utility class covergae Limits.getQueries() : '+ Limits.getQueries());
            System.assert(salesRep.Id!=null,'Sales Rep');
            
            //Create Business Role
            Business_Role__c br = new Business_Role__c();
            br.Name = 'Sales Rep AU';
            br.Global_Equivalent__c = 'Sales Rep';
            br.Country__c = countryId;
            br.Field_Permission_Set_Outlet__c = fps.Id;
            br.Call_Type__c = 'Measure and Sell';
            br.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;WPA__c;OPPS OPEN;OPPS CLOSED';
            insert br;
            
            //user business role 
            User_Business_Role__c ubr = new User_Business_Role__c();
            ubr.Business_Role__c = br.Id;
            ubr.User__c = salesRep.id;
            insert ubr;
            
            Geography__Share geoShare = new Geography__Share();
            geoShare.ParentId = countryId;
            geoShare.UserOrGroupId = salesRep.Id;
            geoShare.AccessLevel = 'Read';
            Database.insert(geoShare,false);
            
            Business_Role__Share brs = new Business_Role__Share();
            brs.ParentId = br.Id;
            brs.UserOrGroupId = salesRep.Id;
            brs.AccessLevel = 'Read';
            Database.insert(brs,false);
        }
        
        AccountTeamMember newAccTeamMember = new AccountTeamMember();
        newAccTeamMember.AccountId = acc1.Id;
        newAccTeamMember.UserId = salesRep.Id;
        newAccTeamMember.TeamMemberRole = 'Primary';
        newAccTeamMember.AccountAccessLevel = 'Edit';
        newAccTeamMember.OpportunityAccessLevel = 'Edit';
        newAccTeamMember.ContactAccessLevel = 'Edit';
        newAccTeamMember.CaseAccessLevel = 'Edit';
        insert newAccTeamMember;

		System.debug(LoggingLevel.DEBUG,'474 : Utility class covergae Limits.getQueries() : '+ Limits.getQueries());
        
        System.runAs(salesRep){
            
            //updating outlet
            acc1.Centrally_Managed__c = true;
            acc1.Centrally_Managed_Note__c = 'test comment1';
            acc1.Local_Segment_Advanced_Analytics__c = 'Workers';
            
            
            
        }
        Test.stopTest();
        
        
    }
    
    /**
     * @description : testcheckMrktSttngVldsForLicense - This method is used to coverage market setting based validation functionalities for License
     
     * @return :void 
   
*/    
    @isTest
    public static void testcheckMrktSttngVldsForLicense(){
        Id contId;
        Pick_Up_Options__c pickupOption;
        User salesRep;
        Account outlet;
        
        EDGE_UtilityTestClass.createOrgSettings();
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        insert testAdminUser; 
        
        salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = testAdminUser.Id;
        insert salesRep;
        System.assert(salesRep.Id!=null,'Sales Rep is not Present');
        
        contId = EDGE_UtilityTestClass.setupCountry('AU'); 
        Geography__c country = new Geography__c(Id = contId, OwnerId = salesRep.Id);
        update country;
        System.assert(contId != null,'Country Id');
        
        Market_Setting__c newMs = new Market_Setting__c(Name='Australia MS',Geography__c= contId, Status__c='Editable & Mandatory - Manager Approval Required');
        insert newMs;
        System.assert(newMs != null,'Market Setting');
        
        Field_Permission_set__c fieldperSet = new Field_Permission_set__c();
        fieldperSet.Market_Setting__c = newMs.Id;
        fieldperSet.Type__c = 'Outlet';
        insert fieldperSet;
        
        Field_Permission_set__c fieldperSet2 = new Field_Permission_set__c();
        fieldperSet2.Market_Setting__c = newMs.Id;
        fieldperSet2.Type__c = 'Default Prospect';
        insert fieldperSet2;
        
        Business_Role__c bRole = new Business_Role__c();
       	bRole.Field_Permission_Set_Outlet__c = fieldperSet.Id;
        //bRole.Field_Permission_Set_Prospect__c = fieldperSet2.Id;
        bRole.Name = 'Sales Rep';
       	bRole.Global_Equivalent__c = 'Sales Rep';
        bRole.Call_Type__c = 'Measure and Sell';
        bRole.Country__c = contId;
        bRole.OwnerId = salesRep.id;
        // Removed Outlet_Visit_Compliance__c as it is obsolete
        bRole.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;WPA__c;New_Product_Distribution__c;Volume_YOY_uplift__c;#of Kegs;OPPS OPEN;OPPS CLOSED;Actual_Physical_Call_Market_Cycle__c;Total_Virtual_Calls__c;Primary_Sales_Territory__r.Name;Primary_Sales_Rep__r.name';
        insert bRole;
        
        Field_Permission__c fieldPermission = new Field_Permission__c();
        fieldPermission.Field_Permission_Set__c = fieldperSet.Id;
        fieldPermission.Field__c = 'License_Number__c';
        fieldPermission.Related_Object__c = 'License__c';
        fieldPermission.Permission__c = 'Editable - MDM Approval Required';
        insert fieldPermission;
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        pickupOption = EDGE_UtilityTestClass.getPickUpOption(contId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        pickupOption.RecordTypeId = pickupRecordType;
        test.startTest();
        insert pickupOption;
        
        outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Status__c = 'Active'; 
        outlet.BillingCity = 'Austria';
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        outlet.Global_Channel__c = 'Off Trade';
        outlet.Global_Sub_Channel__c ='Retailer';
        outlet.Global_Segment__c = 'Discounter';
        outlet.Global_Sub_Segment__c = 'Modern Discounter'; 
        outlet.Country__c = contId;
        outlet.ShippingCountry='Australia';
        
        insert outlet; 
        System.assert(outlet.Id != null,'Outlet is not present');
        
        License__c licenseRec = new License__c();
        licenseRec.Outlet_Id__c = outlet.Id;
        licenseRec.License_Number__c = '1000023';
        licenseRec.License_Type__c='Wine';
        insert licenseRec;
        
        system.runAs(testAdminUser){
            User_Business_Role__c userBRole = new User_Business_Role__c();
        	userBRole.Business_Role__c = bRole.Id;
        	userBRole.User__c = salesRep.Id;
        	insert userBRole;
            
            AccountTeamMember newAccTeamMember = new AccountTeamMember();
            newAccTeamMember.AccountId = outlet.Id;
            newAccTeamMember.UserId = salesRep.Id;
            newAccTeamMember.AccountAccessLevel = 'Edit';
            newAccTeamMember.OpportunityAccessLevel = 'Edit';
            newAccTeamMember.ContactAccessLevel = 'Edit';
            system.debug(LoggingLevel.DEBUG,'4Query' +Limits.getQueries());
            insert newAccTeamMember;
            System.assert(newAccTeamMember.Id!=null,'Account TeamMember');
            
        }
        System.runAs(salesRep){
            EDGE_UtilityClass.stopTriggerToRun = false;
            License__c testSO1 = [Select ID,License_Number__c from License__c where ID =: licenseRec.Id Limit 1];
            testSO1.License_Number__c = '3002598';
            update testSO1; 
            try{
                
            }catch(Exception ex){
                System.debug(LoggingLevel.DEBUG,'Exception - '+ex);
            }
        }
        test.stopTest();
    }

    
    /**
     * @description  : testcheckMrktSttngVldsForSupplier-This method is used to coverage market setting based validation functionalities for Supplier
     
     * @return :void
       
*/   
    @isTest
    public static void testcheckMrktSttngVldsForSupplier(){
        
        Id contId;
        Pick_Up_Options__c pickupOption; 
        List<Account> distAccList = new List<Account>();
        User salesRep;
        Account outlet;
        Supplier_Outlet__c prmrySubRecObj1;
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        insert testAdminUser; 
        EDGE_UtilityTestClass.createOrgSettings();
        contId = EDGE_UtilityTestClass.setupCountry('AU'); 
        System.assert(contId != null,'Country');
        
        Market_Setting__c newMs = new Market_Setting__c(Name='Australia MS',Geography__c= contId, Status__c='Editable & Mandatory - Manager Approval Required');
        insert newMs;
        System.assert(newMs != null,'New Market Setting');
        
        Field_Permission_set__c fieldperSet = new Field_Permission_set__c();
        fieldperSet.Market_Setting__c = newMs.Id;
        fieldperSet.Type__c = 'Outlet';
        insert fieldperSet;
        
        
        Field_Permission__c fieldPermission = new Field_Permission__c();
        fieldPermission.Field_Permission_Set__c = fieldperSet.Id;
        fieldPermission.Field__c = 'isPrimary__c';
        fieldPermission.Related_Object__c = 'Supplier_Outlet__c';
        fieldPermission.Permission__c = 'Editable & Mandatory - Manager Approval Required';
        insert fieldPermission;
        
        Business_Role__c bRole = new Business_Role__c();
        bRole.Field_Permission_Set_Outlet__c = fieldperSet.Id;
        bRole.Name = 'Sales Rep';
        bRole.Global_Equivalent__c = 'Sales Rep';
        bRole.Call_Type__c = 'Measure and Sell';
        bRole.Country__c = contId;
        // Removed Outlet_Visit_Compliance__c as it is obsolete
        bRole.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;WPA__c;New_Product_Distribution__c;Volume_YOY_uplift__c;#of Kegs;OPPS OPEN;OPPS CLOSED;Actual_Physical_Call_Market_Cycle__c;Total_Virtual_Calls__c;Primary_Sales_Territory__r.Name;Primary_Sales_Rep__r.name';
        insert bRole;
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        pickupOption = EDGE_UtilityTestClass.getPickUpOption(contId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        pickupOption.RecordTypeId = pickupRecordType;
        insert pickupOption;
        
        outlet = EDGE_UtilityTestClass.getOutletRecord(); 
        outlet.Status__c = 'Active'; 
        outlet.BillingCity = 'Austria';
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        outlet.Global_Channel__c = 'Off Trade';
        outlet.Global_Sub_Channel__c ='Retailer';
        outlet.Global_Segment__c = 'Discounter';
        outlet.Global_Sub_Segment__c = 'Modern Discounter'; 
        outlet.Country__c = contId;
        outlet.ShippingCountry='Australia';
        distAccList.add(outlet);
        
        //outlet.Last_Modify_Data_Master__c = system.today();
        //update outlet;
        
        Account distAccObj1 = EDGE_UtilityTestClass.getDistriAccRec();
        distAccObj1.Global_Channel__c = 'Off Trade';
        distAccObj1.Global_Sub_Channel__c ='Retailer';
        distAccObj1.Global_Segment__c = 'Discounter';
        distAccObj1.Global_Sub_Segment__c = 'Modern Discounter';
        distAccObj1.ShippingCountry='Australia';
        distAccList.add(distAccObj1);
        
        Account distAccObj2 = EDGE_UtilityTestClass.getDistriAccRec();
        distAccObj2.Global_Channel__c = 'Off Trade';
        distAccObj2.Global_Sub_Channel__c ='Retailer';
        distAccObj2.Global_Segment__c = 'Discounter';
        distAccObj2.Global_Sub_Segment__c = 'Modern Discounter';
        distAccObj2.ShippingCountry='Australia';
        distAccList.add(distAccObj2);
        test.startTest();
        insert distAccList;
        System.assert(distAccList.Size() != null,'Distributor');
        
        
        prmrySubRecObj1 = EDGE_UtilityTestClass.suppOutletRec(outlet.Id,distAccObj1.Id);
        insert prmrySubRecObj1;
        delete prmrySubRecObj1;
        undelete prmrySubRecObj1 ; 
        System.assert(prmrySubRecObj1.Id != null,'Supplier Outlet');
        
        system.runAs(testAdminUser){
            salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
            salesRep.Available_Countries__c = 'AU';
            salesRep.ManagerId = testAdminUser.Id;
            insert salesRep; 
            System.assert(salesRep.Id!=null,'Sales Rep');
            
            User_Business_Role__c userBRole = new User_Business_Role__c();
            userBRole.Business_Role__c = bRole.Id;
            userBRole.User__c = salesRep.Id;
            insert userBRole;
            
            Geography__Share geoShare = new Geography__Share();
            geoShare.ParentId = contId;
            geoShare.UserOrGroupId = salesRep.Id;
            geoShare.AccessLevel = 'Read';
            Database.insert(geoShare,false);
            
            Business_Role__Share brs = new Business_Role__Share();
            brs.ParentId = bRole.Id;
            brs.UserOrGroupId = salesRep.Id;
            brs.AccessLevel = 'Read';
            Database.insert(brs,false);
            
            AccountTeamMember newAccTeamMember = new AccountTeamMember();
            newAccTeamMember.AccountId = outlet.Id;
            newAccTeamMember.UserId = salesRep.Id;
            newAccTeamMember.AccountAccessLevel = 'Edit';
            newAccTeamMember.OpportunityAccessLevel = 'Edit';
            newAccTeamMember.ContactAccessLevel = 'Edit';
            insert newAccTeamMember;
            System.assert(newAccTeamMember.Id!=null,'Account Team Member');
        } 
        System.runAs(salesRep){
            EDGE_UtilityClass.stopTriggerToRun = false;
            Supplier_Outlet__c testSO1 = [Select ID,isPrimary__c from Supplier_Outlet__c where ID =: prmrySubRecObj1.Id Limit 1];
            testSO1.isPrimary__c = true;
            //update testSO1;
        }
        test.stopTest();
        
    }
    
    @isTest
    public static void testManageContact(){
        List<Account> outList = new List<Account>();
        List<Contact> conList = new List<Contact>();
        Id countryId;
        UserRole role = [Select Id,  DeveloperName FROM UserRole where DeveloperName = 'Global' Limit 1];
        User adminUser= EDGE_UtilityTestClass.runAsUser('sysadminuser','System Administrator');
        adminUser.UserRoleId = role.Id;
        adminUser.Default_Country__c = 'AU';
        adminUser.Available_Countries__c = 'AU';
        insert adminUser;
        
        System.runAs(adminUser){
            countryId = EDGE_UtilityTestClass.setupCountry('AU');
            Market_Setting__c markSet = EDGE_UtilityTestClass.getMarketSetting(countryId);
            insert markSet;
            EDGE_UtilityTestClass.createOrgSettings();            
            Pick_Up_Options__c outVisitPrior= EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
            outVisitPrior.Name = 'Priot [AU]';
            insert outVisitPrior;
            
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            outlet.Outlet_Visit_Prioritisation_Grade__c = outVisitPrior.Id;
            outlet.Name = 'Outlet First';
            outlet.ShippingCountry='Australia';
            outList.add(outlet);
            Account outlet1= EDGE_UtilityTestClass.getOutletRecord();
            outlet1.Outlet_Visit_Prioritisation_Grade__c = outVisitPrior.Id;
            outlet1.Name = 'Outlet Second';
            outlet1.ShippingCountry='Australia';
            outList.add(outlet1);
            Account outlet2= EDGE_UtilityTestClass.getOutletRecord();
            outlet2.Outlet_Visit_Prioritisation_Grade__c = outVisitPrior.Id;
            outlet2.Name = 'Outlet Third';
            outlet2.ShippingCountry='Australia';
            outList.add(outlet2);
            insert outList;
            
            Contact contact1 = EDGE_UtilityTestClass.getContact(outlet.Id);
            conList.add(contact1);
            Contact contact2 = EDGE_UtilityTestClass.getContact(outlet1.Id);
            contact2.LastName = 'Jordon';
            contact2.Email = 'jrd@gmail.com';
            conList.add(contact2);
            insert conList;
            
            User commUser = EDGE_UtilityTestClass.runAsUser('test', 'Customer Community User');
            commUser.ContactId = contact1.Id;
            commUser.PortalRole = 'Manager';
            insert commUser;
            system.assert(commUser.Id!=null,'Manager');
            AccountContactRelation accConRel1 = new AccountContactRelation();
            accConRel1.AccountId = outlet.Id;
            accConRel1.ContactId = contact2.Id;
            // Removed under ES20-12548 and ES20-12393
            //accConRel1.Contact_Type__c = 'Secondary';
            insert accConRel1;
            Test.startTest();
            outlet2.Deletion_Flag_from_SAP__c = true;
            update outList;
            outlet.Status__c = 'Closed';
            update outlet;
            Test.stopTest();
            
        }
        
    }
    
}