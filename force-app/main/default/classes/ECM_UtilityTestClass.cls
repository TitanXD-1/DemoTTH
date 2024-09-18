/*
*@Name: ECM_UtilityTestClass
*@description : This is generic class to create sample records. This class will 
    			be used in all test classes.
*@history                                                            
                                                          
VERSION		 AUTHOR                 DATE              DETAIL
1.0      Veerendra Billakurthi    12/03/2020        Initial Development
2.0		 Saurav Paul			  20/08/2021		Added getPaymentSummary,getPayFre
2.1		 Saurav Paul			  01/09/2021		getDeliverPartner
2.2		 Subhrojit Majumdar		  14/09/2021        Added createPaymentAgreement
2.3		 Sayan Mullick			  15/09/2021        Added createsalesAggrement, createProductAgreement
2.4      Tanishq Banerjee         22/12/2021        Added getPaymemtSummaryItem
2.5      Pratap Sen               24/12/2021        Technical Debt Changes against ECM-4994 & Added getInternalOrder,
*/
@isTest
public class ECM_UtilityTestClass {
   /**
    * @description Create profile
    * @param profilename 
    * @return profile
	*/
    public static profile getProfile(string profileName){
        return [Select Id, Name From Profile Where Name=:profileName Limit 1];
    }
   /**
	* @description : Create User
	* @param : last-name of user 
    * @param :profile id of user 
   	* @return : User
	*/
    
    Public static User createUser(string username, Id profileId){
        User usr = new User();
        usr.firstName = '';

        usr.lastName = username.split('@')[0];

        usr.profileId = profileId;        
        usr.email = 'test@test.com';
        usr.Username =username;
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='ES';
        return usr;
    }
  /**
   * @description : Create Territory
   * @param : Geography Id
   * @return : Territory__c
   */
    Public static Territory__c createTerritory(string geographyId){
        Territory__c testterritory=New Territory__c();
        testterritory.Name='Testterriotory';
        testterritory.Territory_Type__c='Sales';
        testterritory.Country__c= geographyId;
        testterritory.Status__c='Active';
        return testterritory;
    }
   /**
	* @description : Create Agreement Type
    * @param : Geography Id
	* @return : ECM_Contract_Type__c
	*/
    Public static ECM_Contract_Type__c createContractType(string geographyId){
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.Volume_UoM_for_Spirits__c = 'BTL';
        contractType.ECM_Volume_UoM_for_Beer__c = 'Not Applicable';
        contractType.ECM_Automatic_approval_amount_threshold__c = 40.00;
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;Category;Volume Target;Rate Per UoM;Investment;Product Growth Strategy;UoM;';
        contractType.ECM_Mandatory_Fields_Check__c ='Prior To Submitting Contract For Approval';
        contractType.Enable_Default_Payment_Frequency__c = true;
        contractType.ECM_Prepayment_Reminder__c = 5;
        contractType.ECM_Volume_UoM_for_RTD__c = 'Can/Bottle 24 Pack';
        contractType.ECM_Volume_UoM_for_Draught_Cocktails__c = '10L BIB';
        return contractType;
    }
   /**
	* @description : Create Pickup Option
	* @param : Geography Id, pickup Option RecordType Id
    * @return : Pick_Up_Options__c
	*/
    Public static Pick_Up_Options__c createPickUpOption(string geographyId, string bannerRecordTypeId){
        Pick_Up_Options__c pickOption= new Pick_Up_Options__c();
        pickOption.Name='Spirits[AU]';
        pickOption.Geography__c=geographyId;
        pickOption.RecordTypeId=bannerRecordTypeId;
        return pickOption;
    }
   /**
	* @description : Create Contract
	* @return : Contract
	* @param : Account Id,Contract RecordType Id
	*/
    Public static Contract createContract(Id accountId, Id recordTypeId){        
        Contract contractobj = EDGE_UtilityTestClass.getContract(accountId, recordTypeId);        
        return contractobj;
    }
   /**
	* @description : Create Business Role
	* @return : Business_Role__c
	* @param : Geography Id, Business Role Name
	*/
    Public static Business_Role__c businessRole(Id geographyId,string roleName){ 
        Business_Role__c businessRole =new Business_Role__c();
        businessRole.Name=roleName;
        businessRole.Country__c=geographyId;
        businessRole.Call_Type__c='Telephone';
        businessRole.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;OPPS OPEN;OPPS CLOSED;';
        return businessRole;
    }
   /**
	* @description : Create User-Business Role
	* @return : User_Business_Role__c
	* @param : Business Role Id, User record
	*/
     Public static User_Business_Role__c createUserBusinessRole(Id businessRole,User usr){ 
       User_Business_Role__c userBusinessRole =new User_Business_Role__c();        
       userBusinessRole.Business_Role__c=businessRole;
       userBusinessRole.User__c=usr.Id;
       return userBusinessRole;
    }
   /**
	* @description : Create Role Agreement
	* @return : ECM_Role_Agreement__c
	* @param : Business Role Id, Agreement type Id
	*/
     Public static ECM_Role_Agreement__c createRoleAgreement(Id businessRole, Id contractType){
     ECM_Role_Agreement__c  roleAgreement =new ECM_Role_Agreement__c();        
        roleAgreement.Business_Role__c=businessRole;
        roleAgreement.Agreement_Type__c=contractType;
        return roleAgreement;
     }
   /**
	* @description : Create Territory Hierarchy
	* @return : Territory_Hierarchy__c
	* @param : Geography Id
	*/
     Public static Territory_Hierarchy__c createhirarchy(string geographyId){
         Territory_Hierarchy__c  hirarchy = new Territory_Hierarchy__c();
         hirarchy.Name='Test';
         hirarchy.Geography__c=geographyId;         
         return hirarchy;
     }
   /**
	* @description : Create Product
	* @return : Product__c
	* @param : Geography Id, Product Name
	*/
    Public static Product__c createProduct(string geographyId, string prodname){
        Product__c product = new Product__c();
        product.Name=prodname;
        product.Country__c=geographyId;
        return product;
    }
   /**
	* @description : Create Market Assortment Product
	* @return : Market_Assortment_Product__c
	* @param : Product Id, geography Id
	*/
     Public static Market_Assortment_Product__c createMarketAssortmentProduct(Id product,string geographyId){
        Market_Assortment_Product__c marketassort = new Market_Assortment_Product__c();
        marketassort.Product__c=product;
        marketassort.Market_Assortment__c=geographyId;
        return marketassort;
    }
   /**
	* @description : Create Product UOM
	* @return : Product_UOM__c
	* @param : Product Id
	*/
    Public static Product_UOM__c createProductUOM(Id product){
        Product_UOM__c prdtUOM = new Product_UOM__c();
        prdtUOM.Product__c = product;
        prdtUOM.Conversion_Factor__c = 2;
        return prdtUOM;
    }
   /**
	* @description : Create Product Agreement
	* @return : ECM_Product_Agreement__c
	* @param : Agreement Type Id, Market Assortment Product Id
	*/
    Public static ECM_Product_Agreement__c createProductAgreement(Id contractType,Id marketassort){
        ECM_Product_Agreement__c productagg = new ECM_Product_Agreement__c();
        productagg.ECM_Market_Assortment_Product__c=marketassort;
        productagg.ECM_Contract_Type__c=contractType;
        return productagg;
    }
   /**
	* @description : Create Contract Item
	* @return : ECM_Contract_Item__c
	* @param : Contract Id, Product Id
	*/
    Public static ECM_Contract_Item__c createcontractitem(Id objContract,Id marketassort){
        ECM_Contract_Item__c newcontractitem= new ECM_Contract_Item__c();
        newcontractitem.ECM_Contract__c=objContract;
        newcontractitem.ECM_Product__c=marketassort;
        return newcontractitem;
    }
   /**
	* @description : Create Depletion
	* @return : Depletions__c
	* @param : Product Id
	*/
    Public static Depletions__c createDepletion(Id marketassort){
        Depletions__c depletionObj= new Depletions__c();
        depletionObj.ECM_Volume__c=19;
        depletionObj.ECM_Product__c=marketassort;
        return depletionObj;
    }
   /**
	* @description : Create Territory Budget
	* @return : Territory_Budget__c
	* @param : Territory, Territory Hierarchy Id
	*/
    Public static Territory_Budget__c createTerritoryBudget(Id territory,Id hirarchy){
        Territory_Budget__c territoryBudget = new Territory_Budget__c();
        territoryBudget.ECM_Territory_Hierarchy__c=hirarchy;
        territoryBudget.Territory__c = territory;
        territoryBudget.Start_Date__c = Date.newInstance(2020, 01, 01);
        territoryBudget.End_Date__c = Date.newInstance(2020, 01, 22);
        territoryBudget.Initial_Amount__c = 100;
        territoryBudget.Spent_Amount__c = 10;
        //insert territoryBudget;
        return territoryBudget;
    }
   /**
	* @description : Create Price List
	* @return : ECM_Price_List__c
	* @param : Price List Name, Geography Id
	*/
    Public static ECM_Price_List__c createPriceList(String priceName,string geographyId){
        ECM_Price_List__c pricelistObj = new ECM_Price_List__c();
        pricelistObj.Name = priceName;
        pricelistObj.ECM_Geography__c=geographyId;
        return pricelistObj;
    }
   /**
	* @description : Get Sales Driver
	* @return : ECM_Sales_Driver__c
	* @param : Territory Budget, Geography Id
	*/
    Public static ECM_Sales_driver__c getSalesdriver(String territoryBudget,string geographyId){ 
        // List<ECM_Sales_Driver__c> SalesDriverList=New List<ECM_Sales_Driver__c>();
        String salesDriverRecordTypeId=ECM_Sales_Driver__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Investment').getRecordTypeId();
        ECM_Sales_Driver__c salesdriver = new ECM_Sales_Driver__c();
        salesdriver.Name = 'Bottle Test';
        salesdriver.Geography__c = geographyId;
        salesdriver.RecordTypeId=salesDriverRecordTypeId;
        salesdriver.ECM_Territory_Budget__c = territoryBudget;
        return salesdriver;
    }
   /**
	* @description : Create Price List Item
	* @return : ECM_Price_List_Item__c
	* @param : Pickup Option, Product, Price List
	*/
    Public static ECM_Price_List_Item__c createPriceListItem(String optionId, string productId, string priceListId ){
        ECM_Price_List_Item__c pricelistItemObj = new ECM_Price_List_Item__c();
        pricelistItemObj.ECM_Product__c = productId;
        pricelistItemObj.ECM_Pickup_Option__c = optionId;
        pricelistItemObj.ECM_Price_List__c = priceListId;
        return pricelistItemObj;
    }
   /**
	* @description : Create Sales Agreement
	* @return : ECM_Sales_Agreement__c
	* @param : Agreement Type, Sales Driver
	*/
    public static ECM_Sales_Agreement__c createsalesAggrement(String aggType, string salesDriver){
        ECM_Sales_Agreement__c salesAgg = new ECM_Sales_Agreement__c();
        salesAgg.ECM_Agreement_Type__c = aggType;
        salesAgg.ECM_Sales_Driver__c = salesDriver;
        return salesAgg;
    }
   /**
	* @description : Create Payment Agreement
	* @return : ECM_Payment_Agreement__c
	* @param : Agreement Type, Payment Frequency
	*/
    public static ECM_Payment_Agreement__c createPaymentAgreement(String aggType, String paymentFreq){
        ECM_Payment_Agreement__c paymentAgg = new ECM_Payment_Agreement__c();
        paymentAgg.ECM_Agreement_Type__c = aggType;
        paymentAgg.ECM_Payment_Frequency__c = paymentFreq;
        return paymentAgg;
    }
   /**
	* @description : Insert Sales Driver Item Details
	* @return : ECM_Sales_Driver_Item_Detail__c
	* @param : Sales Driver Item, Contract Item
	*/
    Public static ECM_Sales_Driver_Item_Detail__c insertSalesdriverDetails(ECM_Sales_Driver_Item__c salesItem, ECM_Contract_Item__c productDetails){
        ECM_Sales_Driver_Item_Detail__c salesdetails =  new ECM_Sales_Driver_Item_Detail__c();
        salesdetails.ECM_Product__c = productDetails.Id;
        salesdetails.ECM_Sales_Driver_Item__c = salesItem.Id;
        salesdetails.ECM_Investment_Amount__c = 50;
        //salesdetails.ECM_Contract__c = productDetails.ECM_Contract__c;        
       // Insert salesdetails;
        return salesdetails;
    }
   /**
	* @description : Create Wrapper Object with Sales Driver Item,Sales Driver Item Details & contract item
	* @return : ECM_CreateContractController.salesdriverItemWrap
	* @param : Sales Driver Item,Sales Driver Item Details,Contract Item
	*/
    public static ECM_CreateContractController.salesdriverItemWrap salesdrivervalues(ECM_Sales_Driver_Item__c salesdrivers,ECM_Sales_Driver_Item_Detail__c salesdriverdetails,ECM_Contract_Item__c conitem){
        List<ECM_Sales_Driver_Item_Detail__c> salesDetails = new List<ECM_Sales_Driver_Item_Detail__c>{salesdriverdetails};
        ECM_CreateContractController.salesdriverItemWrap salesdriver= new ECM_CreateContractController.salesdriverItemWrap(); 
            salesdriver.saledrive.applied=true;
            SalesDriver.saledrive.SalesDriver=salesdrivers.ECM_Sales_Driver__c;
            SalesDriver.saledrive.Id= salesdrivers.Id;
            SalesDriver.salesDriver= salesdrivers;
            //SalesDriver.salesDriver.ECM_Sales_Driver_Name__c= 'test';
            SalesDriver.salesDriver.ECM_Total_Investment_Amount__c=33;
            // SalesDriver.salesDriver.ECM_Sales_Driver__r.ECM_Automatic_Amount_Split__c=false;
            // SalesDriver.salesDriver.ECM_Sales_Driver__c=salesdrivers.ECM_Sales_Driver__c;
            SalesDriver.totalInvest=33;
            salesdriver.paymentId = 'Partial Payment';
        
        for(ECM_Sales_Driver_Item_Detail__c salesdetail : salesDetails){
            ECM_CreateContractController.salesdriverItemDetailsWrap salesdetailswrap = new ECM_CreateContractController.salesdriverItemDetailsWrap();
            salesdetailswrap.salesDriverDetails = salesdetail;
            salesdetailswrap.productname = conitem;
            salesdetailswrap.selectedProductcheck = true;
            salesdetailswrap.investment = salesdetail.ECM_Investment_Amount__c;
            SalesDriver.saledriveItemDetailsWrapList.add(salesdetailswrap);
        }        
        return salesdriver;
    }
   /**
	* @description : Create Wrapper Object with Sales Driver Item & Sales Driver Item Details
	* @return : ECM_CreateContractController.salesdriveritems
	* @param : Sales Driver Item & Sales Driver Item Details
	*/
    public static ECM_CreateContractController.salesdriveritems getSalesdriveritems(ECM_Sales_Driver__c salesdriver,ECM_Sales_Driver_Item__c salesdriverItem){
        ECM_CreateContractController.salesdriveritems saleswrap = new ECM_CreateContractController.salesdriveritems();
        saleswrap.Drivername = 'TestDriver';
        saleswrap.SalesDriver = salesdriver.Id;
        saleswrap.DriverType = salesdriver.RecordTypeId;
        saleswrap.Id = salesdriverItem.Id;
        saleswrap.Name = salesdriverItem.Name;            
        
        return saleswrap;
    }
   /**
	* @description : Create Payment Frequency
	* @return : ECM_Payment_Frequency__c
	* @param : Country Id
	*/
    public static ECM_Payment_Frequency__c getPayFre(Id countryId){
        ECM_Payment_Frequency__c paymfreq = new ECM_Payment_Frequency__c();
        paymfreq.ECM_Type__c = 'Monthly';
        paymfreq.ECM_Other_Investment__c = true;
        paymfreq.ECM_Volume_target__c = true;
        paymfreq.ECM_Number_of_months_for_recurrence__c = '20';
        paymfreq.ECM_From_When_Starts__c =' Calendar Year';
        paymfreq.ECM_Geography__c = countryId;
        return paymfreq;
    }
   /**
	* @description : Create Payment Summary
	* @return : ECM_Payment_Summary__c
	* @param : Country Id
	*/
    public static ECM_Payment_Summary__c getPaymentSummary(Id contId){
        ECM_Payment_Summary__c paySummaryObj = new ECM_Payment_Summary__c();
        paySummaryObj.ECM_Invoice_Attachment__c = true;
        paySummaryObj.ECM_Evidence_Attachment__c = true;
        paySummaryObj.ECM_Type__c = 'Promo-PrePayment';
        paySummaryObj.ECM_Contract__c = contId;
        return paySummaryObj;
    }
   /**
	* @description : Create Territory Hierarchy
	* @return : Territory_Hierarchy__c
	* @param : Country Id, Parent Territory Hierarchy Id
	*/
    public static Territory_Hierarchy__c getTerritoryHierarchy(Id recId,Id conId, Id parBUId){
        Territory_Hierarchy__c hierObj = new Territory_Hierarchy__c();
        hierObj.Name = 'Test Spain BU';
        hierObj.RecordTypeId = recId;
        hierObj.Geography__c = conId;
        if(String.isNotBlank(parBUId)){
            hierObj.Parent_BU__c = parBUId;
        }
        return hierObj;
    }
   /**
	* @description : Create Territory
	* @return : Territory__c
	* @param : Country Id, Hierarcy Region Id
	*/
    public static Territory__c getTerritory(Id contId, Id hierRegionId){
        Territory__c territoryObj = New Territory__c();
        territoryObj.Name='Testterriotory';
        territoryObj.Territory_Type__c='Sales';
        territoryObj.Country__c = contId;
        territoryObj.Status__c ='Active';
        territoryObj.Region__c = hierRegionId;
        return territoryObj;
    }
   /**
	* @description : Create Extra Approval
	* @return : ECM_Extra_Approval__c
	* @param : Country Id, Territory Hierarchy Id
	*/
    public static ECM_Extra_Approval__c  getExtraApproval(Id contId, Id terrHierId){
        ECM_Extra_Approval__c extraAppObj = new ECM_Extra_Approval__c ();
        extraAppObj.ECM_Approver_Position_Name__c = 'Spain Extra Approver';
        extraAppObj.ECM_Approver_s_Email_Address__c = 'test@diageo.com';
        extraAppObj.ECM_Automatic_Approval_if_Total_Amount__c = false;
        extraAppObj.ECM_Delegated_Approver_Email_Address__c = 'test@diageo.com';
        extraAppObj.ECM_Enable_Delegation__c = true;
        extraAppObj.ECM_Geography__c = contId;
        extraAppObj.ECM_Legal_Related__c = false;
        extraAppObj.ECM_Lower_Limit_Amount__c = 100;
        extraAppObj.ECM_Re_Investment_Rate_Lower_Limit__c = 20;
        extraAppObj.ECM_Re_Investment_Rate_Upper_Limit__c =50;
        extraAppObj.ECM_Territory_Hierarchy__c = terrHierId;
        extraAppObj.ECM_Upper_Limit_Amount__c = 100;
        extraAppObj.ECM_Active__c = true;
        return extraAppObj;
    }
   /**
	* @description : Create Agreement Approval
	* @return : ECM_Agreement_Approval__c
	* @param : Agreement Type Id, Extra Approval Id
	*/
    public static ECM_Agreement_Approval__c getAgrmntApproval(Id agmntType , Id xtraApproval){
        ECM_Agreement_Approval__c aggApproObj = new ECM_Agreement_Approval__c();
        aggApproObj.ECM_Agreement_Type__c = agmntType;
        aggApproObj.ECM_Extra_Approval__c = xtraApproval;
        return aggApproObj;
    }
   /**
	* @description : Create Contract Type(Agreement Type)
	* @return : ECM_Contract_Type__c
	* @param : Country Id
	*/
    public static ECM_Contract_Type__c getAgreementType(Id contId){
        ECM_Contract_Type__c agreementType = new ECM_Contract_Type__c();
        agreementType.Name ='Promotional';
        agreementType.Geography__c = contId;
        agreementType.ECM_Abbreviation__c = 'POM';
        agreementType.Volume_UoM_for_Spirits__c = 'BTL';
        agreementType.ECM_Volume_UoM_for_Beer__c = 'Not Applicable';
        agreementType.ECM_Automatic_approval_amount_threshold__c = 40.00;
        agreementType.ECM_Screen_3_field_configuration__c='Product Name;Volume Target;';
        agreementType.ECM_Mandatory_Fields_Check__c ='Prior To Submitting Contract For Approval';
        agreementType.Enable_Default_Payment_Frequency__c = true;
        agreementType.ECM_Prepayment_Reminder__c = 5;
        return agreementType;
    } 
   /**
	* @description : Create Delivery Partner
	* @return : Delivery_Partner__c
	* @param : Country Id, RecordTypeId
	*/
    public static Delivery_Partner__c getDeliverPartner(String countryId, String recordTypeId){
        Delivery_Partner__c deliverPartner = new Delivery_Partner__c();
        deliverPartner.Name ='testPartner';
        deliverPartner.DP_Id__c = '12sdefr';
        deliverPartner.Email__c = 'abc@xyz.com';
        deliverPartner.Vendor_Number__c = 1234;
        deliverPartner.Country__c = countryId;
        deliverPartner.Street__c = 'Burns bay';
        deliverPartner.City__c = 'Sydney';
        deliverPartner.Postal_Code__c = '6003';
        deliverPartner.RecordTypeId = recordTypeId;
        return deliverPartner;
    }
   /**
	* @description : Create Payment Summary Item
	* @return : ECM_Payment_Summary_Item__c
	* @param : Payment Summary Id, Contract Item Id
	*/
    public static ECM_Payment_Summary_Item__c getPaymentSummaryItem(Id paymemtSummary, Id newcontractitem){
        ECM_Payment_Summary_Item__c paymemtSummaryItem = new ECM_Payment_Summary_Item__c();
        paymemtSummaryItem.ECM_Payment_Summary__c = paymemtSummary;
        paymemtSummaryItem.ECM_Confirm__c = true;
        paymemtSummaryItem.ECM_Contract_Item__c = newcontractitem;			
        paymemtSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
        return paymemtSummaryItem;
    }
   /**
	* @description : Create Internal Order record with 'CM Internal Order' recordtype
	* @return : ECM_Internal_Order__c
	* @param : Country Id
	*/
    public static ECM_Internal_Order__c getInternalOrder(Id countryId)
    {
        ECM_Internal_Order__c recordIO = new ECM_Internal_Order__c();
        recordIO.Name = 'IO-123456789';
        recordIO.ECM_Geography__c = countryId;
        recordIO.ECM_Description__c = 'Testing Record';
        recordIO.ECM_Start_Date__c = System.today().addmonths(-6);
        recordIO.ECM_End_Date__c = System.today().addmonths(6);
        recordIO.RecordTypeId= Schema.SObjectType.ECM_Internal_Order__c.getRecordTypeInfosByName().get('CM Internal Order').getRecordTypeId();
        recordIO.ECM_Budget_Amount__c = 100;
        return recordIO;


    }
    /*
	* @description : Create Addendum(Addendum)
	* @param : Contract Id
	* @return : ECM_Addendum__c	


	*/
    public static ECM_Addendum__c getAddendum(Id contractId){
        ECM_Addendum__c addendumRec = new ECM_Addendum__c();
        addendumRec.Name='Test';
        addendumRec.ECM_Contract__c = contractId;
        addendumRec.ECM_Status__c = 'Draft';
        return addendumRec;
	/*
	* @description : Create Master Asset
	* @param : Geography Id
	* @return : Master_Asset__c	
	*/    }
    public static Master_Asset__c getMasterAsset (String geographyId){
        Master_Asset__c masObj = new Master_Asset__C();
        masObj.Name = 'Master Asset Aggrement 1';
        masObj.Part_Number__c = '123CHSGT';
        masObj.Priority_Assets__c = True;
        masObj.GUID__c = 'TWRFSHJAKSVGG';
        masObj.Short_Description__c = 'short description';
        masObj.Country__c = geographyId;
        return masObj;
    }
    /*
	* @description : Create Master Asset Agreement
	* @param : Master Asset Id , Aggrement Type Id
	* @return : ECM_Master_Asset_Agreements__c	
	*/
    public static ECM_Master_Asset_Agreements__c getMstrAsstAgg(String mstrAsst, String aggmntTyp){
        ECM_Master_Asset_Agreements__c masterAssetAggObj = new ECM_Master_Asset_Agreements__c();
        masterAssetAggObj.ECM_Agreement_Type__c = aggmntTyp;
        masterAssetAggObj.ECM_Master_Asset__c = mstrAsst;
        return masterAssetAggObj;
    }
}