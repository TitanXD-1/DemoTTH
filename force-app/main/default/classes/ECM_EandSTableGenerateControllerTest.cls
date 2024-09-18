/*
*@Name: ECM_EandSTableGenerateControllerTest
*@Purpose: This class is used to cover testclass for the - ECM_EandSTableGenerateController
*@History:                                                            
*VERSION      AUTHOR                  DATE                DETAIL
*1.0       Pratik Somani           30/08/2022        Initial Development
*1.1       Ravi Kant               05/09/2022        Changes for ECM-6054
*1.2       Pratik Somani           13/09/2022        Changes for ECM-6053,ECM-6055,ECM-6056,ECM-6057
*/
@isTest
public class ECM_EandSTableGenerateControllerTest {
    /*
    * @description : tests prepareTableData method of ECM_EandSTableGenerateController
    * @return : void
    * @param : void
    */
    @isTest
    public static void testTableGenerator(){
        Test.startTest();
        
        wrapData conWrp = setupContract();
        //Add E&S specific records with contract
        setUpEventAndAmplification(conWrp.conId);
        setUpActivation(conWrp.conId, conWrp.geoId);
        setUpInvestments(conWrp.conId, conWrp.geoId);
        setUpBranding(conWrp.conId, conWrp.geoId);
        setUpParityAndTickets(conWrp.conId, conWrp.geoId);
        
        Contract conRec = [SELECT Id,ECM_Size__c,ECM_Brands__c,ECM_Opening_Hours__c,ECM_Activation_Plans_presented_to_Event__c,ECM_Quantity_of_Activation_Spaces__c,
                           ECM_Locations__c,ECM_Site_Maps__c,ECM_Indicative_Total_Funding__c
                           FROM Contract WHERE Id =: conWrp.conId];
        
        Map<String,ECM_EandSTableGenerateController.tableWrapper> tableMap = ECM_EandSTableGenerateController.prepareTableData(conRec,'AU');
        
        ECM_EandSPDFTableComponentController pdfTableComponentController = new ECM_EandSPDFTableComponentController();
        pdfTableComponentController.tableDataString=JSON.serialize(tableMap);                                        
        pdfTableComponentController.gettableData();
        
        pdfTableComponentController.tableDataString=JSON.serialize(tableMap.get('Pourage'));                                        
        pdfTableComponentController.gettableData();
        Test.stopTest();
        System.assert(conRec!=null,'conRec should not be null');
    }
    
    /*
    * @description : Generic Data Set up Required for Contract Testing - Prepares a Contract record with Contract Items
    * @return : wrapData
    * @param : void
    */
    @isTest
    public static wrapData setupContract() {
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('E&S').getRecordTypeId();
        
        //Territory for outlet
        Territory__c  testTerritory = EDGE_UtilityTestClass.getTerritoryRec();
        insert testTerritory;
        System.assert(testTerritory!=null,'testTerritory should not be null');
        
        //Contract Mandatory Records : Account
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        insert acc;
        
        //Contract Mandatory Records : Agreement Type
        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        contractType.Name='PromotionalAU';
        contractType.ECM_Volume_UoM_for_Beer__c = 'EU';
        contractType.ECM_Screen_3_field_configuration__c = 'Product Name;Brand;Category;Volume Target;Rate Per UoM;Investment;Product Growth Strategy';
        insert contractType;
        
        //Setting up contract
        Contract objContractAU = EDGE_UtilityTestClass.getContract(acc.Id, contractRecordTypeId);
        objContractAU.Status = 'Draft';
        objContractAU.ECM_Territory__c=testterritory.Id;
        objContractAU.ECM_Agreement_Type__c=contractType.Id;
        objContractAU.ECM_Channel__c='On-Premise';
        objContractAU.StartDate = system.today().addmonths(-6).toStartOfMonth();
        objContractAU.ECM_Duration__c = 12;
        objContractAU.Contract_End_Date__c = system.today().addmonths(6).addDays(-1);
        objContractAU.ECM_Indicative_Total_Funding__c = 80;
        insert objContractAU;
        
        //Add Contract Items with Contract
        addRelatedItemsforCon(objContractAU.Id, geographyId);
        
        //Prepare Data Wrapper to Return
        wrapData wrpCon = new wrapData();
        wrpCon.conId = objContractAU.Id;
        wrpCon.geoId = geographyId;
        return wrpCon;
    }
    
    /*Wrapper to Wrap Contract Data & Geography*/
    public class WrapData{
        public Id conId;
        public Id geoId;
    }
    
    /*
    * @description : Set up Contract Items with required testing data and Add Contract Item with Contract
    * @return : Contract
    * @param : conId - Contract Id, geographyId - geography Id
    */
    public static void addRelatedItemsforCon(Id conId, Id geographyId){
        //Setting up product Product Strategy - Needed to test Pourage Table
        Pick_Up_Options__c pOption = new Pick_Up_Options__c(Name = 'RTD[AU]', Geography__c = geographyId, Status__c = 'Active');
        pOption.ECM_Strategy_group__c = 'Premium Core';
        pOption.RecordTypeId = Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Product Strategy').getRecordTypeId();
        insert pOption;
        
        //Setting Up Product Records
        List<Product__c> product = new List<Product__c> {ECM_UtilityTestClass.createProduct(geographyId,'TestProd1'),
            											 ECM_UtilityTestClass.createProduct(geographyId,'TestProd2')};
        product[0].Product_Full_Name__c='TestProdfullName1';
        product[0].RecordTypeId = Schema.SObjectType.Product__c.getRecordTypeInfosByName().get('Brand Variant').getRecordTypeId();
        product[0].Category__c = 'Tequila';
        
        product[1].Product_Full_Name__c='TestProdfullName2';
        product[1].RecordTypeId = Schema.SObjectType.Product__c.getRecordTypeInfosByName().get('Brand Variant').getRecordTypeId();
        product[1].Category__c = 'Tequila';
        insert product;
        
        //Setting Up Market Assortment Product(MAP) records using Product & PickUp Options
        List<Market_Assortment_Product__c> mapRec = new List<Market_Assortment_Product__c>{ECM_UtilityTestClass.createMarketAssortmentProduct(product[0].Id,geographyId),
            																			   ECM_UtilityTestClass.createMarketAssortmentProduct(product[1].Id,geographyId)};
        mapRec[0].ECM_INTO_Material__c = 8;
        mapRec[0].ECM_Pickup_Option__c = pOption.id;
        mapRec[1].ECM_INTO_Material__c = 10;
        mapRec[1].ECM_Pickup_Option__c = pOption.id;
        insert mapRec; 
        
        //Setting up contract items with Map and adding MAT & TSDD data for testing Investment Table
        List<ECM_Contract_Item__c> ciRec = new List<ECM_Contract_Item__c> {ECM_UtilityTestClass.createcontractitem(conId, mapRec[0].id),
            															   ECM_UtilityTestClass.createcontractitem(conId, mapRec[1].id)};                                               
        ciRec[0].ECM_MAT_original__c = 1;
        ciRec[0].ECM_TSDD_Original__c = 10;
        ciRec[0].ECM_TSDD_Override__c = 10;
		ciRec[0].ECM_TotalSKU_SpecificRebate__c = 10;
        ciRec[0].ECM_Exclusive__c = false;
        
        ciRec[1].ECM_MAT_original__c = 1;
        ciRec[1].ECM_TSDD_Original__c = 10;
		ciRec[1].ECM_TotalSKU_SpecificRebate__c = 10;
        ciRec[1].ECM_Exclusive__c = true;
        insert ciRec;
    }
	
    /*
    * @description : inserts Event & Amplification Records for a contract
    * @return : void
    * @param : conId - Id of Contract
    */
    public static void setUpEventAndAmplification(Id conId){
        //Set up Event Record
        ECM_Event__c objEve = new ECM_Event__c(ECM_Event_Name__c = 'Test Event', ECM_Event_Date__c = System.today());
        objEve.ECM_Contract__c  = conId;
        objEve.ECM_Percent_Sponsorship_Fee_Allocation__c = 100;
        objEve.ECM_Event_Unique_Id__c = objEve.ECM_Contract__c + objEve.ECM_Event_Name__c + objEve.ECM_Event_Date__c;
        insert objEve;
        
        //Set up Amplification Records : 1 Website, 2 App & 1 eDM
        ECM_Amplification__c ampOfWebSite = new ECM_Amplification__c(ECM_Contract__c = conId, 	ECM_Logo_Inculsion__c = 'Yes', ECM_Home_Page_Banners__c = 'Yes');
        ampOfWebSite.ECM_Run_of_Site_Banners__c = 'No';
        ampOfWebSite.ECM_Brand__c = 'Morrison';
        ampOfWebSite.ECM_Asset_Productions__c = 'Diageo';
        ampOfWebSite.ECM_Redirect_Links__c = 'https://edge--edgecmdev.sandbox.lightning.force.com/lightning/setup';
        ampOfWebSite.ECM_Unique_Id__c = conId + 'website';
        ampOfWebSite.RecordTypeId = Schema.SObjectType.ECM_Amplification__c.getRecordTypeInfosByName().get('Website').getRecordTypeId();
        
        ECM_Amplification__c ampOfApp1 = new ECM_Amplification__c(ECM_Contract__c = conId, 	ECM_Logo_Inculsion__c = 'Yes', ECM_Home_Page_Banners__c = 'Yes');
        ampOfApp1.ECM_Run_of_Site_Banners__c = 'No';
        ampOfApp1.ECM_Brand__c = 'Morrison';
        ampOfApp1.ECM_Asset_Productions__c = 'Diageo';
        ampOfApp1.ECM_Push_Notifications__c = 'Yes';
        ampOfApp1.ECM_Unique_Id__c = conId + 'App1';
        ampOfApp1.RecordTypeId = Schema.SObjectType.ECM_Amplification__c.getRecordTypeInfosByName().get('App').getRecordTypeId();
        ECM_Amplification__c ampOfApp2 = ampOfApp1.clone(false,false,false,false);
        ampOfApp2.ECM_Brand__c = 'Bear';
        ampOfApp2.ECM_Unique_Id__c = conId + 'App2';
        
        ECM_Amplification__c ampOfEDM= new ECM_Amplification__c(ECM_Contract__c = conId, 	ECM_Logo_Inculsion__c = 'Yes', ECM_Asset_Productions__c = 'Diageo');
        ampOfEDM.ECM_Banners__c = 'No';
        ampOfEDM.ECM_Content_Inclusions__c = 'Editorial';
        ampOfEDM.ECM_Redirect_Links__c = 'https://edgecmdev.com';
        ampOfEDM.ECM_Unique_Id__c = conId + 'eDM';
        ampOfEDM.RecordTypeId = Schema.SObjectType.ECM_Amplification__c.getRecordTypeInfosByName().get('eDM').getRecordTypeId();
        
        List<ECM_Amplification__c> ampList = new List<ECM_Amplification__c>{ampOfWebSite, ampOfApp1, ampOfApp2, ampOfEDM};
        insert ampList;
    }
    
    /*
    * @description : inserts Event Additional Information (EAI) records of Activation By Organiser & Activation By Diageo Record Types
    * @return : void
    * @param : conId - Id of Contract , geographyId - Id of geography
    */
    public static void setUpActivation(Id conId, Id geographyId){
        //Record Type Ids for PickUp Options and Event Additional Information
        List<String> recordTypes = Label.ECM_ActivationScreenrecordTypes.Split(',');
        Id recTypeActByOrgPO = Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get(recordTypes[0].trim()).getRecordTypeId();
        Id recTypeActByDiageoPO = Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get(recordTypes[1].trim()).getRecordTypeId();
        Id recTypeActByOrgEAI = Schema.SObjectType.ECM_Event_Additional_Information__c.getRecordTypeInfosByName().get(recordTypes[0].trim()).getRecordTypeId();
        Id recTypeActByDiageoEAI = Schema.SObjectType.ECM_Event_Additional_Information__c.getRecordTypeInfosByName().get(recordTypes[1].trim()).getRecordTypeId();
        
        //Setting up PickUp Options for Category : One for Activation by Organiser and Two for Activation by Diageo
        List<Pick_Up_Options__c> category = new List<Pick_Up_Options__c>{ECM_UtilityTestClass.createPickUpOption(geographyId,recTypeActByOrgPO),
            															 ECM_UtilityTestClass.createPickUpOption(geographyId,recTypeActByDiageoPO),
            															 ECM_UtilityTestClass.createPickUpOption(geographyId,recTypeActByDiageoPO)};
        category[0].Name = 'Cat1[AU]';
        category[1].Name = 'Cat2[AU]';
        category[2].Name = 'Cat3[AU]';
        insert category;
        
        //Setting up PickUp Options for Sub-Category : Two for Each Record Type of Activation
        List<Pick_Up_Options__c> subCategory = new List<Pick_Up_Options__c>{ECM_UtilityTestClass.createPickUpOption(geographyId,recTypeActByOrgPO),
            																ECM_UtilityTestClass.createPickUpOption(geographyId,recTypeActByOrgPO),
            																ECM_UtilityTestClass.createPickUpOption(geographyId,recTypeActByDiageoPO),
            																ECM_UtilityTestClass.createPickUpOption(geographyId,recTypeActByDiageoPO)};
        
        //Two sub-category for Catgory Cat1    																
        subCategory[0].Name = 'SubCatA[AU]';
        subCategory[0].Status__c = 'Active';
        subCategory[0].ECM_Activation_Category__c = category[0].Id;
        subCategory[1].Name = 'SubCatB[AU]';
        subCategory[1].Status__c = 'Active';
        subCategory[1].ECM_Activation_Category__c = category[0].Id;
        
        //One subcategory for each of Category Cat2 & Cat3                                                                    
        subCategory[2].Name = 'SubCatC[AU]';
        subCategory[2].Status__c = 'Active';
        subCategory[2].ECM_Activation_Category__c = category[1].Id;
        subCategory[3].Name = 'SubCatD[AU]';
        subCategory[3].Status__c = 'Active';
        subCategory[3].ECM_Activation_Category__c = category[2].Id;
        insert subCategory;

        //Set Up EAIs
        List<ECM_Event_Additional_Information__c> evntInsert = new List<ECM_Event_Additional_Information__c>{
        new ECM_Event_Additional_Information__c(ECM_Information_Type__c = subCategory[0].Id, ECM_Contract__c = conId, RecordTypeId = recTypeActByOrgEAI, ECM_Unique_Id__c = 'test'),
        new ECM_Event_Additional_Information__c(ECM_Information_Type__c = subCategory[1].Id, ECM_Contract__c = conId, RecordTypeId = recTypeActByOrgEAI, ECM_Unique_Id__c = 'test1'),
        new ECM_Event_Additional_Information__c(ECM_Information_Type__c = subCategory[2].Id, ECM_Contract__c = conId, RecordTypeId = recTypeActByDiageoEAI, ECM_Unique_Id__c = 'test2'),
        new ECM_Event_Additional_Information__c(ECM_Information_Type__c = subCategory[3].Id, ECM_Contract__c = conId, RecordTypeId = recTypeActByDiageoEAI, ECM_Unique_Id__c ='test3')};
		insert evntInsert;
    }
    
    /*
    * @description : inserts Event Additional Information (EAI) records of Investment & Event Investment Record Types
    * @return : void
    * @param : con - Contract Record, geographyId - Id of geography
    */
    public static void setUpInvestments(Id conId, Id geoId){
        //Record Type Ids for Event Additional Information and fetch Event Id
        String invEAI = Schema.SobjectType.ECM_Event_Additional_Information__c.getRecordTypeInfosByDeveloperName().get('Investment').getRecordTypeId();
        String evntinvEAI = Schema.SobjectType.ECM_Event_Additional_Information__c.getRecordTypeInfosByDeveloperName().get('ECM_Event_Investment').getRecordTypeId();
        Id evntId = [SELECT Id FROM ECM_Event__c WHERE ECM_Contract__c =: conId].Id;
        
        //Prepare Event Additional Information of Investment Record Type
        ECM_Event_Additional_Information__c invPourage = new ECM_Event_Additional_Information__c(ECM_Contract__c = conId, 	RecordTypeId = invEAI);
        invPourage.ECM_Investment_Type__c = 'Pourage(Including Volume)';
        invPourage.ECM_Investment_Amount__c = 100;
        invPourage.ECM_Investment_Percentage__c = 25;
        invPourage.ECM_Unique_Id__c = conId + invPourage.ECM_Investment_Type__c;
        
        ECM_Event_Additional_Information__c invOnsite = invPourage.clone(false,false,false,false);
        invOnsite.ECM_Investment_Type__c = 'Onsite(ex pourage)';
        invOnsite.ECM_Unique_Id__c = conId + invOnsite.ECM_Investment_Type__c;
        
        ECM_Event_Additional_Information__c invAmp = invPourage.clone(false,false,false,false);
        invAmp.ECM_Investment_Type__c = 'Amplification';
        invAmp.ECM_Unique_Id__c = conId + invAmp.ECM_Investment_Type__c;
        
        ECM_Event_Additional_Information__c invActv = invPourage.clone(false,false,false,false);
        invActv.ECM_Investment_Type__c = 'Activation';
        invActv.ECM_Investment_Percentage__c = null;
        invActv.ECM_Unique_Id__c = conId + invActv.ECM_Investment_Type__c;
        List<ECM_Event_Additional_Information__c> invList = new List<ECM_Event_Additional_Information__c>{invPourage, invOnsite, invAmp, invActv};
        insert invList;
        
        //Prepare Event Additional Information of Event Investment Record Type using Each Type of Investment record & Event
        List<ECM_Event_Additional_Information__c> eventInvList = new List<ECM_Event_Additional_Information__c>();
        eventInvList.add(new ECM_Event_Additional_Information__c(ECM_Contract__c = conId, ECM_Investment__c = invPourage.Id,
                                                                 ECM_Amount_Per_Investment_Per_Event__c = 100,	ECM_Event__c = evntId,
                                                                 ECM_Unique_Id__c = conId + '1',RecordTypeId = evntinvEAI));
        
        eventInvList.add(new ECM_Event_Additional_Information__c(ECM_Contract__c = conId, ECM_Investment__c = invOnsite.Id,
                                                                 ECM_Amount_Per_Investment_Per_Event__c = 100,	ECM_Event__c = evntId,
                                                                 ECM_Unique_Id__c = conId + '2',RecordTypeId = evntinvEAI));
        
        eventInvList.add(new ECM_Event_Additional_Information__c(ECM_Contract__c = conId, ECM_Investment__c = invAmp.Id,
                                                                 ECM_Amount_Per_Investment_Per_Event__c = 100,	ECM_Event__c = evntId,
                                                                 ECM_Unique_Id__c = conId + '3',RecordTypeId = evntinvEAI));
        
        eventInvList.add(new ECM_Event_Additional_Information__c(ECM_Contract__c = conId, ECM_Investment__c = invActv.Id,
                                                                 ECM_Amount_Per_Investment_Per_Event__c = 100,	ECM_Event__c = evntId,
                                                                 ECM_Unique_Id__c = conId + '4',RecordTypeId = evntinvEAI));
        insert eventInvList;
    }
    
    /*
    * @description : inserts Event Additional Information (EAI) records of Branding & Branding Merchandise Record Types
    * @return : void
    * @param : conId - Id of Contract , geographyId - Id of geography
    */
    public static void setUpBranding(Id conId, Id geoId){
        //Record Type Ids for PickUp Options and Event Additional Information
        String recTypeBrandingPO = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Branding').getRecordTypeId();
        String recTypeBrandingMrPO = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Branding Merchandise').getRecordTypeId();
        String recTypeBrandingEAI = ECM_Event_Additional_Information__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Branding').getRecordTypeId();
        String recTypeBrandingMrEAI = ECM_Event_Additional_Information__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Branding Merchandise').getRecordTypeId();
		
        //Insert Pick Uptions to link with EAIs
        List<Pick_Up_Options__c> pickUpOptnList = new List<Pick_Up_Options__c>();
        pickUpOptnList.add(new Pick_Up_Options__c(Name = 'Branding Naming Rights[AU]',Geography__c = geoId, Status__c = 'Active', RecordTypeId = recTypeBrandingPO));
        pickUpOptnList.add(new Pick_Up_Options__c(Name = 'Branding Alcohol Signage %[AU]',Geography__c = geoId, Status__c = 'Active', RecordTypeId = recTypeBrandingPO));
        pickUpOptnList.add(new Pick_Up_Options__c(Name = 'Branding Electronic[AU]',Geography__c = geoId, Status__c = 'Active', RecordTypeId = recTypeBrandingPO));
        pickUpOptnList.add(new Pick_Up_Options__c(Name = 'Branding Static[AU]',Geography__c = geoId, Status__c = 'Active', RecordTypeId = recTypeBrandingPO));
        pickUpOptnList.add(new Pick_Up_Options__c(Name = 'Branding Merchandise[AU]',Geography__c = geoId, Status__c = 'Active', RecordTypeId = recTypeBrandingMrPO));
        
        //Set up Branding Specific category and subcategories in Branding Pick Up Options
        pickUpOptnList[0].ECM_Branding_Categorisation__c = 'Diageo Naming Rights';
        pickUpOptnList[1].ECM_Branding_Categorisation__c = 'Total Alcohol Signage %';
        pickUpOptnList[2].ECM_Branding_Categorisation__c = 'Menu Boards';
        pickUpOptnList[2].ECM_Sub_Branding_Categorisation__c = 'Electronic';
        pickUpOptnList[3].ECM_Branding_Categorisation__c = 'Menu Boards';
        pickUpOptnList[3].ECM_Sub_Branding_Categorisation__c = 'Static';
        insert pickUpOptnList;

        //Set Up Branding EAI with all categorisation of pick up options & One Branding Merchandise EAI
		List<ECM_Event_Additional_Information__c> brandingEAI = new List<ECM_Event_Additional_Information__c>();
        ECM_Event_Additional_Information__c brandingEAI1 = new ECM_Event_Additional_Information__c(ECM_Contract__c = conId, ECM_Information_Type__c = pickUpOptnList[0].Id, RecordTypeId = recTypeBrandingEAI);
        brandingEAI1.ECM_Description__c = 'Branding Rec for Naming Rights';
        brandingEAI1.ECM_Quantity__c = 5;
        brandingEAI1.ECM_Unique_Id__c = conId+'_'+brandingEAI1.ECM_Information_Type__c;
        brandingEAI.add(brandingEAI1);
        
        ECM_Event_Additional_Information__c brandingEAI2 = new ECM_Event_Additional_Information__c(ECM_Contract__c = conId, ECM_Information_Type__c = pickUpOptnList[1].Id, 
                                                                                                   RecordTypeId = recTypeBrandingEAI);
        brandingEAI2.ECM_Description__c = 'Branding Rec for Total Alcohol Signage';
        brandingEAI2.ECM_Quantity__c = 10;
        brandingEAI2.ECM_Unique_Id__c = conId+'_'+brandingEAI2.ECM_Information_Type__c;
        brandingEAI.add(brandingEAI2);
        
        ECM_Event_Additional_Information__c brandingEAI3 = new ECM_Event_Additional_Information__c(ECM_Contract__c = conId, ECM_Information_Type__c = pickUpOptnList[2].Id, 
                                                                                                   RecordTypeId = recTypeBrandingEAI);
        brandingEAI3.ECM_Description__c = 'Branding Rec for Electronic';
        brandingEAI3.ECM_Quantity__c = 15;
        brandingEAI3.ECM_Unique_Id__c = conId+'_'+brandingEAI3.ECM_Information_Type__c;
        brandingEAI.add(brandingEAI3);
        
        ECM_Event_Additional_Information__c brandingEAI4 = new ECM_Event_Additional_Information__c(ECM_Contract__c = conId, ECM_Information_Type__c = pickUpOptnList[3].Id, 
                                                                                                   RecordTypeId = recTypeBrandingEAI);
        brandingEAI4.ECM_Description__c = 'Branding Rec for Static';
        brandingEAI4.ECM_Quantity__c = 15;
        brandingEAI4.ECM_Unique_Id__c = conId+'_'+brandingEAI4.ECM_Information_Type__c;
        brandingEAI.add(brandingEAI4);
        
        ECM_Event_Additional_Information__c brandingEAI5 = new ECM_Event_Additional_Information__c(ECM_Contract__c = conId, ECM_Information_Type__c = pickUpOptnList[4].Id, 
                                                                                                   RecordTypeId = recTypeBrandingMrEAI);
        brandingEAI5.ECM_Description__c = 'Branding Merchandise Record';
        brandingEAI5.ECM_Quantity__c = 15;
        brandingEAI5.ECM_Unique_Id__c = conId+'_'+brandingEAI5.ECM_Information_Type__c;
        brandingEAI.add(brandingEAI5);
        insert brandingEAI;
    }
	
    /*
    * @description : inserts Event Additional Information (EAI) records of Parity & Ticket Record Types
    * @return : void
    * @param : conId - Id of Contract , geographyId - Id of geography
    */
    public static void setUpParityAndTickets(Id conId, Id geoId){
        //Record Type Ids for PickUp Options and Event Additional Information
        String recTypeParityPO = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Parity').getRecordTypeId();
        String recTypeTicketPO = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Ticket').getRecordTypeId();
        String recTypeParityEAI = ECM_Event_Additional_Information__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Parity').getRecordTypeId();
        String recTypeTicketEAI = ECM_Event_Additional_Information__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Ticket').getRecordTypeId();
		
        //Insert Pick Uptions to link with EAIs
        List<Pick_Up_Options__c> pickUpOptnList = new List<Pick_Up_Options__c>();
        pickUpOptnList.add(new Pick_Up_Options__c(Name = 'TestParity',Geography__c = geoId, Status__c = 'Active', RecordTypeId = recTypeParityPO));
        pickUpOptnList.add(new Pick_Up_Options__c(Name = 'TestTckt',Geography__c = geoId, Status__c = 'Active', RecordTypeId = recTypeTicketPO));
        insert pickUpOptnList;
        
        //Parity
        ECM_Event_Additional_Information__c parityEAI = new ECM_Event_Additional_Information__c(ECM_Contract__c = conId, ECM_Information_Type__c = pickUpOptnList[0].Id);
        parityEAI.ECM_Description__c = 'parity Investment $(x)';
        parityEAI.ECM_Quantity__c = 5;
        parityEAI.ECM_Unique_Id__c = conId+'_'+pickUpOptnList[0].Id;
        parityEAI.RecordTypeId = recTypeParityEAI;
        insert parityEAI;
        
        //Ticket
        ECM_Event_Additional_Information__c ticketEAI = new ECM_Event_Additional_Information__c(ECM_Contract__c = conId, ECM_Information_Type__c = pickUpOptnList[1].Id);
        ticketEAI.ECM_Description__c = 'Ticketing test';
        ticketEAI.ECM_Quantity__c = 5;
        ticketEAI.ECM_Unique_Id__c = conId+'_'+pickUpOptnList[1].Id;
        ticketEAI.RecordTypeId = recTypeTicketEAI;
        insert ticketEAI;
    }
}