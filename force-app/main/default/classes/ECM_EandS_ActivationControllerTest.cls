/*
* Name: ECM_EandS_ActivationControllerTest
* Purpose: This is the test Class for ECM_EandS_ActivationController
* History                                                            
              	                                             
VERSION    	AUTHOR                	DATE              	DETAIL
1.0      	Pratap Sen        	09/06/2022        	Initial Development
1.1     	Priya Soni        	15/09/2022        	ECM-5753: Modification - testClassMethod1, testClassMethod3 & setupData
1.2     	Saurav Prasad       14/07/2023        	142555	:	CM static code violation for the classes_SFDC_Technical Debt

*/
@isTest
public class ECM_EandS_ActivationControllerTest {
     /**
	* @description : createPickUpOptionsShare - This method Creates PickUp Option Sharing
	* @return : void
	* @param : List<Pick_Up_Options__c> pickUpOptList, SalesRep Id
	*/
    public static void createPickUpOptionsShare(List<Pick_Up_Options__c> pickUpOptList,Id salesRepId){
        List<Pick_Up_Options__Share> recsharingList = new List<Pick_Up_Options__Share>();
        for(Pick_Up_Options__c it : pickUpOptList){
            Pick_Up_Options__Share shareRec = new Pick_Up_Options__Share(UserOrGroupId = salesRepId,RowCause = 'Geography_Sharing__c',
                                                                         AccessLevel = 'Read',ParentId = it.Id);
            recsharingList.add(shareRec);
        }
        insert recsharingList;
    }
    /**
    * @description: testClassMethod1 - This method tests getActivationData() & getPickUpOptionsByCategory()
	* Scenario - When no Event Additional Information Record (EAI) Exists
	* @return : void
    * @param : void
    */
    @isTest
    public static void testClassMethod1(){
        //prepare data
        dataWrapper wrap = setupData();
        List<Pick_Up_Options__c> subCategoryList = wrap.subCategory;
        createPickUpOptionsShare(subCategoryList,wrap.salesRep.Id);
        String conId = wrap.conId;
        String rectype1;
        rectype1 = wrap.recTypeId1;
        String rectype2;
        rectype2 = wrap.recTypeId2;
        //Test Apex Method & Assert Result
        ECM_EandS_ActivationController.activationWrapper getData = ECM_EandS_ActivationController.getActivationData(wrap.objContractAU.ECM_Agreement_Type__c,conId,Label.ECM_ActivationScreenRecordTypes);
        System.runAs(wrap.salesRep){                
            System.assert(getData.sec1_pckUpOptions.containsKey('Cat1') && getData.sec2_pckUpOptions.containsKey('Cat2'),'getData should not be null'); //Map of PickUp Options List must contain category Names as Key
            System.assert(getData.sec1_evntInfo.isEmpty() && getData.sec2_evntInfo.isEmpty(),'getData should not be null');//No EAI Record should return
            System.assert(getData.sec1_pckUpOptions.get('Cat1').size() + getData.sec2_pckUpOptions.get('Cat2').size() == subCategoryList.size(),'getData should not be null');//All available PickUp Options for with Activation Category != null must return       
        }
    }
	/**
    * @description: testClassMethod2 - This method tests saveActivationData(),Scenario - Insert Event Additional Information Record (EAI)
	* @return : void
    * @param : void
    */
    @isTest
    public static void testClassMethod2(){
        Try{
            //prepare data
            dataWrapper wrap = setupData();
            String conId = wrap.conId;
            List<Pick_Up_Options__c> subCategoryList = wrap.subCategory;
            createPickUpOptionsShare(subCategoryList,wrap.salesRep.Id);
            String rectype1 = wrap.recTypeId1;
            String rectype2 = wrap.recTypeId2;
            List<ECM_Event_Additional_Information__c> evntInsert = new List<ECM_Event_Additional_Information__c>{
            new ECM_Event_Additional_Information__c(ECM_Information_Type__c = subCategoryList[0].Id, ECM_Contract__c = conId, RecordTypeId = rectype1),
            new ECM_Event_Additional_Information__c(ECM_Information_Type__c = subCategoryList[1].Id, ECM_Contract__c = conId, RecordTypeId = rectype1),
            new ECM_Event_Additional_Information__c(ECM_Information_Type__c = subCategoryList[2].Id, ECM_Contract__c = conId, RecordTypeId = rectype2),
            new ECM_Event_Additional_Information__c(ECM_Information_Type__c = subCategoryList[3].Id, ECM_Contract__c = conId, RecordTypeId = rectype2)
            };
            String jsonData = JSON.serialize(evntInsert);
            //Test Apex Method & Assert Result
            System.runAs(wrap.salesRep){
                Map<String,List<ECM_Event_Additional_Information__c>> retVal = ECM_EandS_ActivationController.saveActivationData(conId,jsonData,rectype1+','+rectype2);
                //Total 4 EAI should now be associated with Contract : 2 with rectype1 and 2 with rectype2
                System.assert(retVal.get(rectype1).size() == 2 && retVal.get(rectype2).size() == 2,'retVal should not be null');
            }
        }
        Catch(Exception ex){
             System.debug(LoggingLevel.Debug,'Exception Caught in testClassMethod2 '+ ex.getLineNumber() +'\n'+ ex.getMessage());
        }
    }
    /**
    * @description: testClassMethod2 - This method tests saveActivationData(),Scenario - Update & Remove Event Additional Information Record (EAI)
	* @return : void
    * @param : void
    */
    @isTest
    public static void testClassMethod3(){
        Try{
            //prepare data
            testClassMethod2();
            String conId = [SELECT Id FROM Contract LIMIT 1].Id;
            id agreementId = [SELECT ECM_Agreement_Type__c FROM Contract LIMIT 1].ECM_Agreement_Type__c;
            User salesRep = [SELECT Id,ProfileId,Available_Countries__c FROM User LIMIT 1];
            String description1 = 'Description for EAI record of Record Type 1';
            String description2 = 'Description for EAI record of Record Type 2';
            ECM_EandS_ActivationController.activationWrapper getData = ECM_EandS_ActivationController.getActivationData(agreementId, conId,Label.ECM_ActivationScreenRecordTypes);
            List<ECM_Event_Additional_Information__c> listEAI = new List<ECM_Event_Additional_Information__c>{getData.sec1_evntInfo[0],getData.sec2_evntInfo[0]};
            listEAI[0].ECM_Description__c = description1;
            listEAI[1].ECM_Description__c = description2;
            String jsonData = JSON.serialize(listEAI);
            String rectype1 = getData.sec1RecordTypeId;
            String rectype2 = getData.sec2RecordTypeId;
            //Test Apex Method & Assert Result
            System.runAs(salesRep){
                Map<String,List<ECM_Event_Additional_Information__c>> retVal = ECM_EandS_ActivationController.saveActivationData(conId,jsonData,rectype1+','+rectype2);
                
                //Total 2 EAI should now be associated with Contract : 1 with rectype1 and 1 with rectype2
                System.assert(retVal.get(rectype1).size() == 1 && retVal.get(rectype2).size() == 1,'retVal should not be null');
                //Desciption should be there in upserted EAI records returned
                System.assert(retVal.get(rectype1)[0].ECM_Description__c == description1 && retVal.get(rectype2)[0].ECM_Description__c == description2,'retVal should not be null');
            }
        }
        Catch(Exception ex){
             System.debug(LoggingLevel.Debug,'Exception Caught in testClassMethod3 '+ ex.getLineNumber() +'\n'+ ex.getMessage());
        }
    }
    /**
    * @description: negativeScenarioTestMethod() - This method tests Exception handling in saveActivationData()
    * Scenario - Insertion of Event Additional Information Record (EAI) when user has no access on PickUp Option Records
	* @return : void
    * @param : void
    */
	@isTest
    public static void negativeScenarioTestMethod(){
        dataWrapper wrap = setupData();
        String conId = wrap.conId;
        List<Pick_Up_Options__c> subCategoryList = wrap.subCategory;
        String rectype1 = wrap.recTypeId1;
        String rectype2 = wrap.recTypeId2;
        List<ECM_Event_Additional_Information__c> insrtManualRecord = new List<ECM_Event_Additional_Information__c>
        {new ECM_Event_Additional_Information__c(ECM_Information_Type__c = subCategoryList[0].Id, ECM_Contract__c = conId, RecordTypeId = rectype1)};
        String jsonData = JSON.serialize(insrtManualRecord);  
        Map<String,List<ECM_Event_Additional_Information__c>> retVal;
        System.runAs(wrap.salesRep){
            Try{
                retVal = ECM_EandS_ActivationController.saveActivationData(conId,jsonData,rectype1+','+rectype2);
            }
            Catch(DmlException ex){
                system.assert(ex.getMessage().contains('Upsert failed'),'error message should contains Upsert failed'); //Upsert should be failed due to insufficient access on cross-reference id
                system.assert(retVal.get(rectype1).size() == 0,'retVal.get(rectype1) value should match'); //no records will be updated/inserted
            }
        }
    }
    @isTest
    public static dataWrapper setupData() {
        //Record Type Ids
    	Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        List<String> recordTypes = Label.ECM_ActivationScreenRecordTypes.Split(',');
        Id pckUpOptionRecId1 = Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get(RecordTypes[0].trim()).getRecordTypeId();
        Id evntInfoRecId1 = Schema.SObjectType.ECM_Event_Additional_Information__c.getRecordTypeInfosByName().get(RecordTypes[0].trim()).getRecordTypeId();
        Id pckUpOptionRecId2 = Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get(RecordTypes[1].trim()).getRecordTypeId();
        Id evntInfoRecId2 = Schema.SObjectType.ECM_Event_Additional_Information__c.getRecordTypeInfosByName().get(RecordTypes[1].trim()).getRecordTypeId();
        
        //Territory for outlet
        Territory__c  testTerritory = EDGE_UtilityTestClass.getTerritoryRec();
        insert testTerritory;
        
        //Contract Mandatory Records : Account
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        insert acc;
        
        //Sales Rep User
        User salesRep = ECM_UtilityTestClass.createUser('srp',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
        salesRep.Username = 'salesRp1234@test.com';
        salesRep.Available_Countries__c='AU';
        insert salesRep;
        
        
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
        objContractAU.ownerId = salesRep.Id;
        objContractAU.StartDate = system.today().addmonths(-6).toStartOfMonth();
        objContractAU.Contract_End_Date__c = system.today().addmonths(6).addDays(-1);
        insert objContractAU;
        system.assert(objContractAU.id!=null,'objContractAU id should not be null');
        
        //Setting up PickUp Options for Category : One for each Record Type
        List<Pick_Up_Options__c> category = new List<Pick_Up_Options__c>{ECM_UtilityTestClass.createPickUpOption(geographyId,pckUpOptionRecId1),
            															ECM_UtilityTestClass.createPickUpOption(geographyId,pckUpOptionRecId2)};
        category[0].Name = 'Cat1[AU]';
        category[0].Status__c = 'Active';
        category[1].Name = 'Cat2[AU]';
        category[1].Status__c = 'Active';
        insert category;
        
        //Setting up PickUp Options for Sub-Category : Two for Each Record Type
        List<Pick_Up_Options__c> subCategory = new List<Pick_Up_Options__c>{ECM_UtilityTestClass.createPickUpOption(geographyId,pckUpOptionRecId1),
            																ECM_UtilityTestClass.createPickUpOption(geographyId,pckUpOptionRecId1),
            																ECM_UtilityTestClass.createPickUpOption(geographyId,pckUpOptionRecId2),
            																ECM_UtilityTestClass.createPickUpOption(geographyId,pckUpOptionRecId2)};
        subCategory[0].Name = 'SubCatA[AU]';
        subCategory[0].Status__c = 'Active';
        subCategory[1].Name = 'SubCatB[AU]';
        subCategory[1].Status__c = 'Active';
        subCategory[0].ECM_Activation_Category__c = category[0].Id;
        subCategory[1].ECM_Activation_Category__c = category[0].Id;
        subCategory[2].Name = 'SubCatC[AU]';
        subCategory[2].Status__c = 'Active';
        subCategory[3].Name = 'SubCatD[AU]';
        subCategory[3].Status__c = 'Active';
        subCategory[2].ECM_Activation_Category__c = category[1].Id;
        subCategory[3].ECM_Activation_Category__c = category[1].Id;
        insert subCategory;
		
        ///ECM-5753
        ///ECM_Event_Additional_Info_Agreement__c is the bridge object between Agrement type and Pickup option
        ECM_Event_Additional_Info_Agreement__c eventAddInfoAgrEAI1 =new ECM_Event_Additional_Info_Agreement__c();
        eventAddInfoAgrEAI1.ECM_Agreement_Type__c = contractType.Id;
        eventAddInfoAgrEAI1.ECM_Event_Additional_Pickup_Option__c = subCategory[0].Id;
        insert eventAddInfoAgrEAI1;
        
        ECM_Event_Additional_Info_Agreement__c eventAddInfoAgrEAI2 =new ECM_Event_Additional_Info_Agreement__c();
        eventAddInfoAgrEAI2.ECM_Agreement_Type__c = contractType.Id;
        eventAddInfoAgrEAI2.ECM_Event_Additional_Pickup_Option__c = subCategory[1].Id;
        insert eventAddInfoAgrEAI2;
        
        ECM_Event_Additional_Info_Agreement__c eventAddInfoAgrEAI3 =new ECM_Event_Additional_Info_Agreement__c();
        eventAddInfoAgrEAI3.ECM_Agreement_Type__c = contractType.Id;
        eventAddInfoAgrEAI3.ECM_Event_Additional_Pickup_Option__c = subCategory[2].Id;
        insert eventAddInfoAgrEAI3;
        
        ECM_Event_Additional_Info_Agreement__c eventAddInfoAgrEAI4 =new ECM_Event_Additional_Info_Agreement__c();
        eventAddInfoAgrEAI4.ECM_Agreement_Type__c = contractType.Id;
        eventAddInfoAgrEAI4.ECM_Event_Additional_Pickup_Option__c = subCategory[3].Id;
        insert eventAddInfoAgrEAI4;
        
        //Prepare data wrapper
        dataWrapper wrap = new dataWrapper();
        wrap.conId = objContractAU.Id;
        wrap.salesRep = salesRep;
        wrap.subCategory = subCategory;
        wrap.recTypeId1 = evntInfoRecId1;
        wrap.recTypeId2 = evntInfoRecId2;
        wrap.objContractAU = objContractAU;
        
        //Check Navigation related Methods
        ECM_EandS_ActivationController.savecontract(objContractAU);
        
        return wrap;
    }
    
    public class DataWrapper{
        public String conId{get;set;}
        public User salesRep{get;set;}
        public List<Pick_Up_Options__c> subCategory{get;set;}
        public String recTypeId1{get;set;}
        public String recTypeId2{get;set;}
        public Contract objContractAU{get;set;}
    }
}