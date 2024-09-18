/*
* Name: ECM_CreateContractControllerEandSTest
* Purpose: This is the test Class for ECM_CreateContractControllerEandS
* History                                                            

VERSION    	AUTHOR                	DATE              	DETAIL
1.0      	Pratap Sen        	27/05/2020        	Initial Development
2.0			Saurav Prasad		13/06/2022			ECM-5638 : E&S Amplification UX pg7_SFDC_AU_E&S
2.1         Abhijeet Mishra     13/06/2022          ECM-5634 : E&S Branding UX pg5_SFDC_AU_E&S 
2.2         Pratap Sen          30/08/2022          ECM-5816 : Code restructure & changes for E&S contract submission for Approval
2.3         Priya Soni          15/09/2022          ECM-5753 : ECM_Event_Additional_Info_Agreement__c instance is created
*/
@isTest
public class ECM_CreateContractControllerEandSTest {
    /*
    * @Name : testBrandingScreenMethods
    * @description : Tests Methods for Branding Screen
	*/     
    @isTest
    public static void testBrandingScreenMethods(){
        WrapBrandingData wrapData = setUpBrandingData();
        Test.startTest();
        ECM_CreateContractControllerEandS.getBrandingData(wrapData.conId,wrapData.agreementID);
        Map<String,List<ECM_Event_Additional_Information__c>> saveBrandingData;
        saveBrandingData = ECM_CreateContractControllerEandS.saveBrandingData(wrapData.conId, wrapData.listOfEAI, wrapData.recordTypes);
        AggregateResult recCount = [SELECT count(id) FROM ECM_Event_Additional_Information__c 
                                    WHERE ECM_Contract__c =: wrapData.conId AND (recordType.Name = 'Branding' or recordType.Name = 'Branding Merchandise')];
        System.assert(recCount.get('expr0') == 2,'expr0 should match');
        Test.stopTest();
    }
    
	/*
    * @Name : testParityMethods
    * @description : Tests methods used for Parity Screen
	*/  
    @isTest
    public static void testParityMethods(){
        List<Contract> conList = setupAUContract();
        Test.startTest();
        ECM_CreateContractControllerEandS.brandingWrapper brandingWrapper = ECM_CreateContractControllerEandS.getParityPickUpOptionType(conList[0].Id,conList[0].ECM_Agreement_Type__c);
        System.assert(brandingWrapper!=null,'brandingWrapper should not be null');
        Test.stopTest();
    }
    
	/*
    * @Name : testGenericMethods
    * @description : Tests common methods used for multiple screens
	*/      
    @isTest
    public static void testGenericMethods(){
        List<Contract> conList = setupAUContract();
        Test.startTest();
        Boolean checkVal = ECM_CreateContractControllerEandS.getAgreementType(conList[0].ECM_Agreement_Type__c);
        System.assert(CheckVal == true,'checkVal should not be null');
        ECM_CreateContractControllerEandS.getListCon(conList[0]);
        ECM_CreateContractControllerEandS.savecontract(conList[0]);
        Test.stopTest();
    }
	
	/*
    * @Name : testSubmitforApproval
    * @description : Tests contract submission for Approval
	*/      
    @isTest
    public static void testSubmitforApproval(){
        List<Contract> conList = setupAUContract();
        Test.startTest();
        ECM_CreateContractController.objectWrapper wrap = ECM_CreateContractControllerEandS.submitForApproval(conList[0]);
        System.assert(wrap.customerName == 'Approved','parameters should match');

        wrap = ECM_CreateContractControllerEandS.submitForApproval(conList[1]);
        System.assert(wrap.customerName == 'In Approval Process','parameters should match');
        Test.stopTest();
    }
    
	/*
    * @Name : setUpBrandingData
    * @description : Creates required data set up for branding screen
    * @return : wrapBrandingData
    * @param : void
	*/  
    @isTest 
    public static WrapBrandingData setUpBrandingData(){
        //Set up Contract & Geography
        List<Contract> conList = setupAUContract();
        Id geographyId = [SELECT Geography__c FROM ECM_Contract_Type__c WHERE Id =: conList[0].ECM_Agreement_Type__c LIMIT 1].Geography__c;
        
        //Set up record type Ids
        String recordTypeBrnding = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Branding').getRecordTypeId();
        String recordTypeBrndingMr = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Branding Merchandise').getRecordTypeId();
        String brandingEAI = ECM_Event_Additional_Information__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Branding').getRecordTypeId();
        String brandingMrEAI = ECM_Event_Additional_Information__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Branding Merchandise').getRecordTypeId();
        List<String> recordTypeList = new List<String>{brandingEAI, brandingMrEAI};
        
        //Prepare PickUp Options
        List<Pick_Up_Options__c> pickUpOptList = new List<Pick_Up_Options__c>();
        Pick_Up_Options__c branding = new Pick_Up_Options__c(RecordTypeId = recordTypeBrnding, Geography__c = geographyId, Status__c = 'Active');
        branding.Name = 'Branding Item[AU]';
        
		Pick_Up_Options__c brandingMr = new Pick_Up_Options__c(RecordTypeId = recordTypeBrndingMr, Geography__c = geographyId, Status__c = 'Active');
        brandingMr.Name = 'Branding Marchendise[AU]';
        
        pickUpOptList.add(branding);
        pickUpOptList.add(brandingMr);
        insert pickUpOptList;
        
        ///ECM-5753
        ///ECM_Event_Additional_Info_Agreement__c is the bridge object between Agrement type and Pickup option
        ECM_Event_Additional_Info_Agreement__c eventAddInfoAgrEAI1 =new ECM_Event_Additional_Info_Agreement__c();
        eventAddInfoAgrEAI1.ECM_Agreement_Type__c = conList[0].ECM_Agreement_Type__c;
        eventAddInfoAgrEAI1.ECM_Event_Additional_Pickup_Option__c = branding.Id;
        insert eventAddInfoAgrEAI1;
        System.assert(eventAddInfoAgrEAI1.id!=null,'eventAddInfoAgrEAI1 Id should not be null');
        
        ECM_Event_Additional_Info_Agreement__c eventAddInfoAgrEAI2 =new ECM_Event_Additional_Info_Agreement__c();
        eventAddInfoAgrEAI2.ECM_Agreement_Type__c = conList[0].ECM_Agreement_Type__c;
        eventAddInfoAgrEAI2.ECM_Event_Additional_Pickup_Option__c = brandingMr.Id;
        insert eventAddInfoAgrEAI2;
        
        
        //Prepare EAI records
        ECM_Event_Additional_Information__c eventAddInfo1 = new ECM_Event_Additional_Information__c(ECM_Contract__c = conList[0].Id, ECM_Information_Type__c = branding.Id, RecordTypeId = brandingEAI);
        eventAddInfo1.ECM_Description__c = 'Branding Record Test';
        eventAddInfo1.ECM_Unique_Id__c = conList[0].Id +'_'+ branding.Id +'_'+ brandingEAI;
        insert eventAddInfo1;
        
        ECM_Event_Additional_Information__c eventAddInfo2 = eventAddInfo1.clone(false,false,false,false);
        eventAddInfo2.ECM_Description__c = 'Branding Second Record Test';

        ECM_Event_Additional_Information__c eventAddInfo3 = new ECM_Event_Additional_Information__c(ECM_Contract__c = conList[0].Id, ECM_Information_Type__c = brandingMr.Id, RecordTypeId = brandingMrEAI);
        eventAddInfo3.ECM_Unique_Id__c = conList[0].Id +'_'+ brandingMr.Id +'_'+ brandingMrEAI;
        eventAddInfo3.ECM_Description__c = 'Branding Mr Record Test';
        insert eventAddInfo3;
        
        ECM_Event_Additional_Information__c eventAddInfo4 = eventAddInfo3.clone(false,false,false,false);
        List<ECM_Event_Additional_Information__c> listOfEAI = new List<ECM_Event_Additional_Information__c>{eventAddInfo1, eventAddInfo2, eventAddInfo3,eventAddInfo4};
        
        //Wrap Up all data and return
        WrapBrandingData wrapData = new WrapBrandingData();
        wrapData.conId = conList[0].Id;
        wrapData.listOfEAI = JSON.Serialize(listOfEAI);
        wrapData.recordTypes = recordTypeList;
        return wrapData;
    }
    
    
    /*Wrapper used to send branding test data*/
    public class WrapBrandingData {
        String conId;
        String listOfEAI;
        id agreementID;
        List<String> recordTypes;
    }

	/*
	 
    * @Name : InvestmentRecordTest
    * @description : Tests methods for Investment Summary Screen
	*/      
    @istest
    static void investmentRecordTest(){
  		List<Contract> conList = setupAUContract();
        
        //Prepare Event Additional Info records
		String invEAI = Schema.SobjectType.ECM_Event_Additional_Information__c.getRecordTypeInfosByDeveloperName().get('Investment').getRecordTypeId();
        String evntinvEAI = Schema.SobjectType.ECM_Event_Additional_Information__c.getRecordTypeInfosByDeveloperName().get('ECM_Event_Investment').getRecordTypeId();
        
        ECM_Event_Additional_Information__c eventAddInfo1 = new ECM_Event_Additional_Information__c(ECM_Contract__c = conList[0].Id, RecordTypeId = invEAI, ECM_Investment_Amount__c = 10);
        eventAddInfo1.ECM_Unique_Id__c = conList[0].Id+'_'+eventAddInfo1.ECM_Investment_Amount__c;
        
        ECM_Event_Additional_Information__c eventAddInfo2 = new ECM_Event_Additional_Information__c(ECM_Contract__c = conList[0].Id, RecordTypeId = evntinvEAI, ECM_Investment_Amount__c = 20);
        eventAddInfo2.ECM_Unique_Id__c = conList[0].Id+'_'+eventAddInfo2.ECM_Investment_Amount__c;
        
        List<ECM_Event_Additional_Information__c> eventInfoList = new List<ECM_Event_Additional_Information__c>{eventAddInfo1,eventAddInfo2};
        insert eventInfoList;
        
        //Prapre JSON wrapper for events
		List<ECM_Event__c> evtList = [SELECT Id,name,ECM_Contract__c,ECM_Event_Date__c,ECM_Event_Name__c FROM ECM_Event__c WHERE ECM_Contract__c =: conList[0].Id];
        String eventData = JSON.serialize( evtList);
        system.debug(LoggingLevel.Debug,'eventData-->'+eventData);
        
        //Test fetchInvestmentData & prepare JSON investment wrapper
        Test.startTest();        
		ECM_CreateContractControllerEandS.tableData dataWrapper = new ECM_CreateContractControllerEandS.tableData();
		dataWrapper = ECM_CreateContractControllerEandS.fetchInvestmentData(conList[0].Id);
        
        for(ECM_CreateContractControllerEandS.Row r : dataWrapper.rows){
            for(ECM_CreateContractControllerEandS.Cell cellData:r.Cells){
                if(cellData.Name.contains('EVE') && cellData.datatype=='input'){
                    cellData.Value='100';
                }
                if(cellData.Name.contains('Investment Data')){
                    cellData.Value='50';
                }
                if(cellData.Name.contains('EventInvestmentData')){
                    cellData.Value='250';
                }
                if(cellData.Name.contains('totalSponsorshipInvesmentAmount')){
                    cellData.Value='500';
                }
                
            }
        }
		String investmentData = JSON.serialize(dataWrapper.rows);
        system.debug(LoggingLevel.Debug,'dataWrapper-->'+investmentData);
		
        //Prepare JSON wrapper for screen-5 KPI data & Test saveInvestmentRecord
        ECM_ReviewAndSubmitController.Wrapper_Review_cal onpremisereview = ECM_ReviewAndSubmitController.Review_On_Premise_Caluculatons(conList[0]);
        String onPremiseString = JSON.serialize(onpremisereview);
		ECM_CreateContractControllerEandS.saveInvestmentRecord(investmentData,eventData,100,200,'EAC1234',onPremiseString,conList[0]);
        
        //Validate Number of Event Additional Info created
        Map<String, ECM_Event_Additional_Information__c > investmentMap = new Map<String, ECM_Event_Additional_Information__c > ();
        Map<String, ECM_Event_Additional_Information__c > eventInvestmentmap = new Map<String, ECM_Event_Additional_Information__c > ();
        
        List<ECM_Event_Additional_Information__c> eventAdditionalList = [SELECT id, ECM_Amount_Per_Investment_Per_Event__c, ECM_Contract__c, ECM_Description__c, ECM_Event__c,
                                                                         ECM_Investment__c, ECM_Information_Type__c, ECM_Investment_Amount__c, ECM_Investment_Percentage__c,
                                                                         ECM_Investment_Type__c, ECM_Quantity__c, ECM_Unique_Id__c, recordtype.Name, ECM_Investment__r.ECM_Investment_Type__c,ECM_Event__r.name
                                                                         FROM ECM_Event_Additional_Information__c
                                                                         WHERE ECM_Contract__c =: conList[0].Id];
           
        for (ECM_Event_Additional_Information__c eventadditional:eventAdditionalList){
            if (eventadditional.recordtype.Name == 'Investment') {
                investmentMap.put(eventadditional.ECM_Investment_Type__c, eventadditional);
            } else if (eventadditional.recordtype.Name == 'Event Investment') {
                eventInvestmentmap.put(eventadditional.ECM_Investment__r.ECM_Investment_Type__c + '_' + eventadditional.ECM_Event__r.Name, eventadditional);
            }
        }
        system.assertEquals(investmentMap.Size(),5,'Both should match');
        system.assertEquals(eventInvestmentmap.Size(),5,'Both should match');
        Test.stopTest();
    }
    
	/*
    * @Name : setupAUContract
    * @description : Creates required data set up for Contract & it's related items
    * @return : List<Contract>
    * @param : void
	*/  
    @isTest
    public static List<Contract> setupAUContract() {
        //Set up geography & recordTypes
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        //String accRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('E&S').getRecordTypeId();
        
        //Set up Sales Rep & Sales Mg User
        User salesMG = ECM_UtilityTestClass.createUser('slm',ECM_UtilityTestClass.getProfile('Sales Manager').Id);
        salesMG.Username = 'salesLM1234@test.com';
        salesMG.Email = 'testSM@test.com';
        salesMG.Available_Countries__c = 'AU';
        insert salesMG;
        
        User salesRep = ECM_UtilityTestClass.createUser('srp',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
        salesRep.Username = 'salesRp1234@test.com';
        salesRep.Email = 'salesRp@test.com';
        salesRep.ManagerId = salesMG.Id;
        salesRep.Available_Countries__c='AU';
        insert salesRep;
        System.assert(salesRep.id!=null,'salesRep should not be null');
        
        //Territory for outlet
        Territory__c  testTerritory = EDGE_UtilityTestClass.getTerritoryRec();
        testTerritory.Primary_Sales_Rep__c = salesRep.Id;
        insert testTerritory;
        
        //Contract Mandatory Records : Account
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        insert acc;
        
        //Contract Mandatory Records : Agreement Type
        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        contractType.Name='PromotionalAU';
        contractType.ECM_Volume_target__c = true;
        contractType.ECM_Volume_UoM_for_Beer__c = 'EU';
        contractType.ECM_Screen_3_field_configuration__c = 'Product Name;Brand;Category;Volume Target;Rate Per UoM;Investment;Product Growth Strategy';
        contractType.ECM_Automatic_approval_amount_threshold__c = 100;
        insert contractType;

        //Setting up two contracts with different funding amount
        List<Contract> conList = new List<Contract>();
        Contract objContractAU = EDGE_UtilityTestClass.getContract(acc.Id, contractRecordTypeId);
        objContractAU.Status = 'Draft';
        objContractAU.ECM_Territory__c = testterritory.Id;
        objContractAU.ECM_Agreement_Type__c = contractType.Id;
        objContractAU.ECM_Channel__c = 'On-Premise';
        objContractAU.OwnerId = salesRep.Id;
        objContractAU.StartDate = system.today().addmonths(-6).toStartOfMonth();
        objContractAU.ECM_Duration__c = 12;
        objContractAU.Contract_End_Date__c = system.today().addmonths(6).addDays(-1);
        objContractAU.ECM_Indicative_Total_Funding__c = 80;
        
        Contract objContractAU1 = objContractAU.clone(false,false,false,false);
        objContractAU1.ECM_Indicative_Total_Funding__c = 200;
        
        conList.add(objContractAU);
        conList.add(objContractAU1);
        insert conList;
        
        //Add Contract Item
        ECM_Contract_Item__c ciRec = new ECM_Contract_Item__c(ECM_Contract__c = objContractAU.id, ECM_MAT_override__c = 20.00);
        ciRec.ECM_MAT_UOS__c = 20.00;
        ciRec.ECM_Total_GP__c = 20.00;
        ciRec.ECM_Total_COGS__c = 20.00;
        ciRec.ECM_Total_SKU_Specific_Rebate_ON__c = 10.00;
        ciRec.ECM_TotalSKU_SpecificRebate__c = 10.00;
        ciRec.ECM_Total_GP_ON__c = 20.00;
        insert ciRec;
        
        //Create Event Record
        ECM_Event__c evt = new ECM_Event__c(ECM_Contract__c = objContractAU.id, ECM_Event_Name__c = 'Test Event');
        evt.ECM_Event_Date__c = System.today().addDays(30);
		evt.ECM_Event_Unique_Id__c = 'Test Event';
		insert evt;
        return conList;
    }
}