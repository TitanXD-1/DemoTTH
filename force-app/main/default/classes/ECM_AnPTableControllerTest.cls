/**
 * @name : ECM_AnPTableControllerTest
 * @description : Test Class for ECM_AnPTableController
 * @history
 * VERSION      AUTHOR          DATE            DETAIL
 * 1.0          Doman Murmu     08/08/2023      Initial Development
 */
@istest
public with sharing class ECM_AnPTableControllerTest {
    public static Id outletRecTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
    public static List<ECM_AnPScreenWrapper> anPWrap = new List<ECM_AnPScreenWrapper>();
    
    @testsetup
    public static void setup(){
       	Id countryId = EDGE_UtilityTestClass.setupCountrySpain('GB');
		system.assert(countryId!= null,'countryId should not be null');
        Geography__c country = [SELECT Id FROM Geography__c WHERE Id = :countryId];
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(country.Id,'Outlet Visit Prioritization');
        insert pickupOption;
        
        Geography__c  marketObj;
        List<Geography__c> marketList = [SELECT Id FROM Geography__c WHERE Name ='Global1'];
        if(!marketList.isEmpty()){
            marketObj = EDGE_UtilityTestClass.createGeography('Market');
            marketObj.Name = 'Europe and Turkey';
            marketObj.Code__c = 'EAT2';
            marketObj.Parent_Geography__c = marketList[0].Id;
            insert marketObj;
        }
        User salesRep = ECM_UtilityTestClass.createUser('srp',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
		salesRep.Username= 'sRep134@test.com';
		insert salesRep;
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();//outlet record
        outletAccount.Outlet_Visit_Prioritisation_Grade__c = pickupOption.Id;
		insert outletAccount;
        
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name ='Promotional';
        contractType.Geography__c = countryId;
        contractType.ECM_Abbreviation__c ='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c = 40.00;
        contractType.Volume_UoM_for_Spirits__c ='BTL';
        contractType.ECM_Screen_3_field_configuration__c ='Product Name;Brand;Volume Target;Rate Per UoM;Investment';
        contractType.ECM_Enable_A_P_screen__c = true;
        insert contractType;
        
        Contract contr = ECM_UtilityTestClass.createContract(outletAccount.Id,outletRecTypeId);
		contr.ECM_Agreement_Type__c= contractType.Id;
		contr.ownerId=salesRep.Id;
		contr.StartDate = System.today().toStartOfMonth();
		contr.Contract_End_Date__c = System.today().toStartOfMonth().addMonths(61).addDays(-1);
        contr.ECM_Duration__c = 60;
        contr.ECM_A_P_Records_Created__c = false;
		contr.Status='Draft';
		insert contr;
		contr.Status='Active';
		update contr;
        
        Product__c objProduct = EDGE_UtilityTestClass.getProd();
        objProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('SKU').getRecordTypeId();
        insert objProduct;
        
        Market_Assortment_Product__c testMAP = new Market_Assortment_Product__c(Market_Assortment__c=countryId,Product__c=objProduct.Id);
        insert testMAP;
        
        ECM_Contract_Item__c contItemRec = new ECM_Contract_Item__c();
        contItemRec.ECM_Contract__c = contr.Id;
        contItemRec.ECM_Product__c=testMAP.Id;
        insert contItemRec;
        
        
        Test.startTest();
		Market_Batch_Setting__mdt batchSetting = [SELECT MasterLabel, Batch_Class__c, Country_Code__c, Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c,
												  Region__c FROM Market_Batch_Setting__mdt WHERE Batch_Class__c = 'ECM_AnP_PlanningCalcBatch' AND 
												  Country_Code__c = 'GB'];
        String className = batchSetting.Batch_Class__c;
		Type t  = Type.forName(className);
		BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
		job.getBatchDetails(batchSetting);
		Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
		Test.stopTest();

    }
    
	@istest
    public static void getAnPValuesTest(){
        
        Contract con = [Select Id from Contract where ECM_Agreement_Type__r.ECM_Enable_A_P_screen__c = true limit 1];
        System.debug(LoggingLevel.DEBUG,'Contract rec ->'+con);
        anPWrap = ECM_AnPTableController.getAnPValues(con.Id);
        System.assert(anPWrap != null, 'Contract Id does not exit');
    }
    @istest
    public static void getMonthsTest(){
        Contract con = [Select Id from Contract where ECM_Agreement_Type__r.ECM_Enable_A_P_screen__c = true limit 1];
        List<Date> anPMonthRec;
        anPMonthRec = ECM_AnPTableController.getMonths(con.Id);
        System.assert(anPMonthRec != null, 'Contract Id does not exit');
    }
    
    @isTest
    public static void updateAnPValuesTest(){
        Contract con = [Select Id from Contract where ECM_Agreement_Type__r.ECM_Enable_A_P_screen__c = true limit 1];
        Id conId;
        conId=con.Id;
        List<String> fieldSetAPINames = System.Label.ECM_AnP_PlanningFieldSets.split(';');
        List<Schema.FieldSetMember> fsForecast = Schema.SObjectType.ECM_A_P_Planning__c.fieldSets.getMap().get(fieldSetAPINames[0]).getFields();
        List<Schema.FieldSetMember> fsPaid= Schema.SObjectType.ECM_A_P_Planning__c.fieldSets.getMap().get(fieldSetAPINames[1]).getFields();
        String query = 'SELECT Id,ECM_Contract_Item__c,ECM_Contract_Item__r.ECM_Product_Name__c,ECM_Contract_Item__r.ECM_TotalAnP_incl_Indirect__c,ECM_Contract_Item__r.ECM_Phasing_Forecast_Total__c,ECM_Contract_Item__r.ECM_Paid_A_P_Total__c,ECM_Contract_Item__r.ECM_Difference__c,ECM_Calendar_Year__c, ECM_Unique_Identifier__c, ';
        
        for(Schema.FieldSetMember f : fsForecast) {
            query += f.getFieldPath() + ', ';
        }
        for(Schema.FieldSetMember f : fsPaid) {
            query += f.getFieldPath() + ', ';
        }

		query=query.substring(0, query.lastIndexOf(','));
        query+=' FROM ECM_A_P_Planning__c  WHERE ECM_Contract_Item__r.ECM_Contract__c=:conId ORDER BY ECM_Contract_Item__r.ECM_Product_Name__c,ECM_Calendar_Year__c ASC';
        List<ECM_A_P_Planning__c> anpLst=Database.query(String.escapeSingleQuotes(query));
        String payload=JSON.serialize(anpLst);
        ECM_AnPTableController.updateAnPValues(payload,conId);
        System.assert(anpLst != null,'No record to update');
    }
    
    @istest
    public static void getFieldsAPITest(){
        ECM_AnPTableController.WrapperClass wrap;
        wrap = ECM_AnPTableController.getFieldsAPI();
        System.assert(wrap != null,'No fields to return');
    }

}