/*
* Name: ECM_DepletionVolUpdatOnConItemsBat_Test
* Purpose: This is the test Class for ECM_DepletionVolumeUpdateOnConItemsBatch
* History                                                            
              	                                             
VERSION    	AUTHOR                	DATE              	DETAIL
1.0      	CM dev Team        		14/05/2020        	Initial Development
1.1		 	Tanishq and Anshu		25/03/2022			Requirement per ECM-5352 
1.2         Pratap and Subhrojit    12/04/2022          Re-structured test class and added test methods for AU for ECM-5314
1.3         Pratap Sen              10/05/2022          Updated for ECM-5527
*/
@isTest
public class ECM_DepletionVolUpdatOnConItemsBat_Test {
    /**
	* @description : testDepletionDataEU - This method tests ECM_DepletionVolumeUpdateOnConItemsBatch.actualVolumeCTDEU()
	* @return : void
	* @param : Void
	*/
    @isTest
    public static void testDepletionDataEU(){
        Test.startTest();
        try{  
            setupEU();
            Market_Batch_Setting__mdt batchSetting = [SELECT MasterLabel, Batch_Class__c, Country_Code__c,Market_Order__c, Serial_Number__c, Scope__c, 
                                                      Job_Group__c, Region__c FROM Market_Batch_Setting__mdt WHERE Batch_Class__c = 'ECM_DepletionVolumeUpdateOnConItemsBatch'
                                                      AND Country_Code__c ='ES' ];            
            batchSetting.Market_Order__c=100;
            String className = batchSetting.Batch_Class__c;  
            system.assert(className != null,'className should not be null');      
            Type t = Type.forName(className);
            BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
            job.getBatchDetails(batchSetting);
            system.debug(LoggingLevel.Debug,'SCOPE SIZE -- '+batchSetting.Scope__c);
            Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
            
        }catch(Exception ex){
            system.debug(LoggingLevel.Debug,'Exception Caught in ECM_DepletionVolUpdatOnConItemsBat_Test class at Line: '+ex.getLineNumber()+' Error: '+ex.getMessage());
        }
        Test.stopTest();
    }
    /**
	* @description : testDepletionDataAU - This method tests ECM_DepletionVolumeUpdateOnConItemsBatch.actualVolumeCTDAU()
	* @return : void
	* @param : Void
	*/
    @isTest
    public static void testDepletionDataAU(){
        Test.startTest();
        try{
            setupAU();
            Market_Batch_Setting__mdt batchSetting = [SELECT MasterLabel, Batch_Class__c, Country_Code__c,Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, 
                                                      Region__c FROM Market_Batch_Setting__mdt WHERE Batch_Class__c = 'ECM_DepletionVolumeUpdateOnConItemsBatch'
                                                      AND Country_Code__c ='AU'];            
            batchSetting.Market_Order__c=101;
            String className = batchSetting.Batch_Class__c;   
            system.assert(className != null,'className should not be null');       
            Type t = Type.forName(className);
            BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
            job.getBatchDetails(batchSetting);
            Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));   
        }
        catch(Exception ex){
            system.debug(LoggingLevel.Debug,'Exception Caught in ECM_DepletionVolUpdatOnConItemsBat_Test class at Line: '+ex.getLineNumber()+' Error: '+ex.getMessage());
        }
        Test.stopTest();
    }
    /**
	* @description : creates test data for Europe
	* @return : void
	* @param : Void
	*/
    @isTest 
    public static void setupEU() {
        //Setting up Geography first as rest of records are dependent on Geography : Spain (Europe)
		Id geographyId = EDGE_UtilityTestClass.setupCountryPL('ES');

		//Territory for outlet        
        Territory__c  testTerritory = EDGE_UtilityTestClass.getTerritoryRec();
        insert testTerritory;
        system.assert(testTerritory.Id != null,'testTerritory Id should not be null');
        //Setting up Required Item for EU Contract: Agreement Type
        ECM_Contract_Type__c contractType= ECM_UtilityTestClass.createContractType(geographyId);
        contractType.ECM_Volume_UoM_for_Beer__c = 'EU';
        contractType.ECM_Screen_3_field_configuration__c = 'Product Name;Brand;Category;Volume Target;Rate Per UoM;Investment;Product Growth Strategy';
        insert contractType;
        
        //Setting up Required Item for EU Contract: Account - RecordType Outlet
        String accRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId(); 
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.RecordTypeId = accRecordTypeId;
        outlet.BillingCity = 'Madrid';
        outlet.BillingState = 'Madrid';
        outlet.BillingCountry = 'Spain';
        outlet.BillingCountryCode = 'ES';
        insert outlet;
        
        //Setting up Required Item for EU Contract: Payment Frequency : Two Records to test two different scenarios based upon Payment Frequency
        ECM_Payment_Frequency__c paymentFreq = ECM_UtilityTestClass.getPayFre(geographyId);
        paymentFreq.ECM_Type__c = 'Yearly';
        paymentFreq.ECM_Number_of_months_for_recurrence__c = '12';
        List<ECM_Payment_Frequency__c> paymentFreqList = new List<ECM_Payment_Frequency__c>{paymentFreq};
        ECM_Payment_Frequency__c paymentFreq1 = paymentFreq.clone(false,false,false,false);
        paymentFreq.ECM_Type__c = 'Monthly Retrospective';
        paymentFreq.ECM_Number_of_months_for_recurrence__c = '1';
        paymentFreqList.add(paymentFreq1);
        insert paymentFreqList;
        
        //Setting up EU Contract Records : Two contracts to test 'Selected UoM' and 'Payment Frequency' dependent two scenarios
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Contract objContractEU = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
        objContractEU.Status = 'Draft';
        objContractEU.ECM_Territory__c=testTerritory.Id;
        objContractEU.ECM_Agreement_Type__c=contractType.Id;
        objContractEU.ECM_Payment_Frequency_Type__c = paymentFreq.Id;
        objContractEU.ECM_Select_UoM__c = 'min UoM';
        objContractEU.StartDate = system.today().addmonths(-1).toStartOfMonth()-3;
        objContractEU.Contract_End_Date__c = system.today()+360;
        //List<Contract> conList = new List<Contract>{objContractEU};
        /*Contract objContractEU1 = objContractEU.clone(false,false,false,false);
        objContractEU1.ECM_Payment_Frequency_Type__c = paymentFreq1.Id;
        objContractEU1.ECM_Select_UoM__c = '9LC EU';
        conList.add(objContractEU1);*/
        insert objContractEU; 

        //Setting Up Product Record : a single product to be included in multiple related items
        Product__c product = EDGE_UtilityTestClass.getProd();
        product.Name='JW black Tester';
        product.Country__c=geographyId;
        insert product;
        
        //Setting Up Product UoM to fetch the conversion factors
        List<Product_UOM__c> prodUOM = new List<Product_UOM__c>{new Product_UOM__c(Product__c = product.Id,Conversion_Factor__c = 2,
                                                                                   Type__c ='CEQ',Unique_ID__c = '1515'),
            													new Product_UOM__c(Product__c = product.Id,Conversion_Factor__c = 3,
                                                                                   Type__c ='BTL',Unique_ID__c = '1616')};
        insert prodUOM;
        
        //Setting up MAP and two contract Items to map with contracts
        Market_Assortment_Product__c marketAssortment = ECM_UtilityTestClass.createMarketAssortmentProduct(product.Id,geographyId);
        insert marketAssortment;
        List<ECM_Contract_Item__c> conItemList = new List<ECM_Contract_Item__c>{ECM_UtilityTestClass.createcontractitem(objContractEU.Id,marketAssortment.Id)
            																	};
        insert conItemList;
        
        //Updating contract status to Update before mapping Depletions & Payment Summaries
        objContractEU.Status = 'Active';
        //conList[1].Status = 'Active';
        update objContractEU;
        
        //Setting up Depletion Records Combinations : min UoM - BTL & LPA, 9LC EU - BTL & CEQ
        Depletions__c dep1 = new Depletions__c();
        dep1.ECM_Volume__c = 100.00;
        dep1.ECM_Start_Period__c = system.today().addmonths(-1).toStartOfMonth();
        dep1.ECM_End_Period__c = system.today().addmonths(1).toStartOfMonth()-1;
        dep1.ECM_Product__c = product.id;
        dep1.ECM_Outlet__c = outlet.Id;
        dep1.ECM_Geography__c=geographyId;
        dep1.ECM_UoM__c = 'BTL';
        dep1.Contract__c=objContractEU.id;
        List<Depletions__c> depList = new List<Depletions__c>{dep1};
            
        Depletions__c dep2 = dep1.clone(false,false,false,false);
        dep2.ECM_UoM__c = 'LPA';
        depList.add(dep2);
        
        Depletions__c dep3 = dep2.clone(false,false,false,false);
        dep3.ECM_UoM__c = 'CEQ';
        dep3.Contract__c=objContractEU.id;
        depList.add(dep3);
        
        Depletions__c dep4 = dep3.clone(false,false,false,false);
        dep4.ECM_UoM__c = 'BTL';
        depList.add(dep4);
        insert depList;
        
        //Setting up Tax Code : Mandatory record for Approved Payment Summary
		String taxCodeRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Tax Code').getRecordTypeId();
        Pick_Up_Options__c taxCode= new Pick_Up_Options__c();
        taxCode.Name = 'No Tax[ES]';
        taxCode.Geography__c=geographyId;
        taxCode.RecordTypeId=taxCodeRecordTypeId;
        insert taxCode;
        
        //Setting up two Approved Payment Summary
        ECM_Payment_Summary__c ps1 = ECM_UtilityTestClass.getPaymentSummary(objContractEU.Id);
		ps1.ECM_Payment_Summary_Status__c='Approved';
		ps1.ECM_Type__c='Volume-Based';
        ps1.ECM_Tax_Code__c = taxCode.id;
        ps1.ECM_Start_Period__c = system.today().addmonths(-1).toStartOfMonth();
        ps1.ECM_End_Period__c = system.today().addmonths(1).toStartOfMonth()-1;
        List<ECM_Payment_Summary__c> psList = new List<ECM_Payment_Summary__c>{ps1};
            
        ECM_Payment_Summary__c ps2 = ps1.clone(false,false,false,false);
        ps2.ECM_Payment_Summary_Status__c='Completed';
        ps2.ECM_Contract__c = objContractEU.Id;
        psList.add(ps2);
        insert psList;
    }
    /**
	* @description : creates test data for Australia
	* @return : void
	* @param : Void
	*/
    @isTest
    public static void setupAU() {
        //Setting up Record Types
		Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        String accRecordTypeId;
		accRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        String contractRecordGroupTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Group').getRecordTypeId();
        
        //Territory for outlet
        Territory__c  testTerritory = EDGE_UtilityTestClass.getTerritoryRec();
        insert testTerritory;
        system.assert(testTerritory.Id != null,'testTerritory Id should not be null');
        //Contract Mandatory Records : Account - two outlets & one group
        List<Account> accList = new List<Account>{EDGE_UtilityTestClass.getOutletRecord(),EDGE_UtilityTestClass.getOutletRecord(),
            									  EDGE_UtilityTestClass.getOutletRecord(),EDGE_UtilityTestClass.getOwnerOperatorAccount()};
        accList[0].Name = 'Test_OutletAU0';
        accList[1].Name = 'Test_OutletAU1';
        accList[1].Parent_Outlet__c = accList[0].Id;
        accList[1].Hybrid__c = True;
        accList[2].Name = 'Test_OutletAU2';
        accList[2].Hybrid__c = false;
        insert accList;
        
        //Contract Mandatory Records : Agreement Type
        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        contractType.Name='PromotionalAU';
        contractType.ECM_Volume_UoM_for_Beer__c = 'EU';
        contractType.ECM_Screen_3_field_configuration__c = 'Product Name;Brand;Category;Volume Target;Rate Per UoM;Investment;Product Growth Strategy';
        insert contractType;
        
		//Setting up three contracts : one with 'min UoM' & another one with '9LC EU' product uoM, one group contract
        Contract objContractAU = EDGE_UtilityTestClass.getContract(accList[2].Id, contractRecordTypeId);
        objContractAU.Status = 'Draft';
        objContractAU.ECM_Territory__c=testterritory.Id;
        objContractAU.ECM_Agreement_Type__c=contractType.Id;
        objContractAU.ECM_Channel__c='On-Premise';
        objContractAU.StartDate = system.today().addmonths(-6).toStartOfMonth();
        objContractAU.Contract_End_Date__c = system.today().addmonths(6).addDays(-1);
        List<Contract> conList = new List<Contract>{objContractAU}; 
        
        Contract objContractAU1 = objContractAU.clone(false,false,false,false);
        objContractAU1.StartDate = system.today().addmonths(-6).toStartOfMonth();
        objContractAU1.Contract_End_Date__c = system.today().addmonths(6).addDays(-1);
        conList.add(objContractAU1);
        
        Contract objContractGrpAU = EDGE_UtilityTestClass.getContract(accList[3].Id, contractRecordGroupTypeId);
        objContractGrpAU.Status = 'Draft';
        objContractGrpAU.ECM_Agreement_Type__c=contractType.Id;
        objContractGrpAU.ECM_Channel__c='On-Premise';
        objContractGrpAU.StartDate = system.today().addmonths(-6).toStartOfMonth();
        objContractGrpAU.Contract_End_Date__c = system.today().addmonths(12).addDays(-1);
        conList.add(objContractGrpAU);
        insert conList;
        
        //Setting up outlet contracts for Group
        List<Outlet_Contract__c> outletConList = new List<Outlet_Contract__c>{new Outlet_Contract__c(Outlet__c = accList[0].Id,Contract__c = objContractGrpAU.Id),
            															      new Outlet_Contract__c(Outlet__c = accList[1].Id,Contract__c = objContractGrpAU.Id),
            																  new Outlet_Contract__c(Outlet__c = accList[2].Id,Contract__c = objContractGrpAU.Id)};
        insert outletConList;

        //Setting Up Product Record : product to be included in multiple related items
        Product__c product = EDGE_UtilityTestClass.getProd();
        product.Name='JW black Tester';
        product.Country__c=geographyId;
        insert product;
        
        //Setting up MAP,Product Agreement and two contract Items to map with contracts
        Market_Assortment_Product__c marketAssortment = ECM_UtilityTestClass.createMarketAssortmentProduct(product.Id,geographyId);
        insert marketAssortment;
        List<ECM_Contract_Item__c> conItemList = new List<ECM_Contract_Item__c>
        {ECM_UtilityTestClass.createcontractitem(objContractAU.Id,marketAssortment.Id),
        
        ECM_UtilityTestClass.createcontractitem(objContractGrpAU.Id,marketAssortment.Id)};
        insert conItemList;
        
        //Setting up Depletion Lists 
        Depletions__c dep1 = new Depletions__c();
        dep1.ECM_Volume__c = 100.00;
        dep1.ECM_Start_Period__c = system.today().addmonths(-1).toStartOfMonth();
        dep1.ECM_End_Period__c = dep1.ECM_Start_Period__c.addmonths(1).toStartOfMonth()-1;
        dep1.ECM_Product__c = product.id;
        dep1.ECM_Outlet__c = accList[2].Id;
        dep1.ECM_Geography__c=geographyId;
        dep1.ECM_UoM__c = 'BTL';
        List<Depletions__c> depList = new List<Depletions__c>{dep1};
            
        Depletions__c dep2 = dep1.clone(false,false,false,false);
        depList.add(dep2);   
        Depletions__c dep3 = dep1.clone(false,false,false,false);
        dep3.ECM_Outlet__c = accList[0].Id;
        depList.add(dep3);        
        Depletions__c dep4 = dep1.clone(false,false,false,false);
        dep4.ECM_Outlet__c = accList[1].Id;
        depList.add(dep4);
        insert depList;   
    }
}