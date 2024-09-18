/*
 * @Name: ECM_SalesAgreementTriggerHelper
 * @Description: This is the test class for SalesAgreementTrigger
 * @History                                                            
                                                         
 VERSION    AUTHOR                DATE              DETAIL
 1.0        Sayan Mullick     	  13/09/2021        Initial Development for ECM-4416
 1.1        Subhrojit Majumdar    20/12/2021        Technical Debt Changes against ECM-5068
*/ 
@isTest
public class ECM_SalesAgreementTriggerHelperTest {
   /**
    * @Name : salesAggrementValidationTest
	* @description : This method is used to test the SalesAgreementDuplicateCheck() method of the ECM_SalesAgreementTriggerHelper class
	*/
	@isTest
    public static void salesAggrementValidationTest(){
        WrapperInst wrapobj = createData();
        Id recordtypeSalesId = Schema.SObjectType.ECM_Sales_Agreement__c.getRecordTypeInfosByName().get('Sales Agreement').getRecordTypeId();
        ECM_Sales_Agreement__c salesAggObj = ECM_UtilityTestClass.createsalesAggrement(wrapobj.aggTypeObj,wrapobj.salesDriverObj);
        salesAggObj.RecordTypeId = recordtypeSalesId;
        Test.startTest();
        try{
            insert salesAggObj;
        }catch(Exception ex){
            String errorMessage = Label.ECM_Sales_Agreement_Error_Msg;
            errorMessage = errorMessage.split('\\.')[0];
            String expectedError = ex.getMessage().split('\\,')[1].split('\\.')[0].trim();
            System.assertEquals(errorMessage,expectedError,ex.getMessage());
        }
        Test.stopTest();
    }
   /**
    * @Name : salesAggrementValidationTest
	* @description : This method is used to test the SalesAgreementDuplicateCheck() method of the ECM_SalesAgreementTriggerHelper class
	*/
    @isTest
    public static void updatesalesAggrementValidationTest(){
        WrapperInst wrapobj = createData();
        Id recordtypeSDId = Schema.SObjectType.ECM_Sales_Driver__c.getRecordTypeInfosByName().get('Investment').getRecordTypeId();
        ECM_Sales_Driver__c salesDriverObj = ECM_UtilityTestClass.getSalesdriver(wrapobj.terriBudgetId,wrapobj.countryIdVal);
        salesDriverObj.RecordTypeId = recordtypeSDId;
        insert salesDriverObj;
        
        Id recordtypeSalesId = Schema.SObjectType.ECM_Sales_Agreement__c.getRecordTypeInfosByName().get('Sales Agreement').getRecordTypeId();
        ECM_Sales_Agreement__c salesAggObj = ECM_UtilityTestClass.createsalesAggrement(wrapobj.aggTypeObj,salesDriverObj.Id);
        salesAggObj.RecordTypeId = recordtypeSalesId;
        insert salesAggObj;
        salesAggObj.ECM_Sales_Driver__c = wrapobj.salesDriverObj;
        Test.startTest();
        try{
            update salesAggObj;
        }catch(Exception ex){
            String errorMessage = Label.ECM_Sales_Agreement_Error_Msg;
            errorMessage = errorMessage.split('\\.')[0];
            String expectedError = ex.getMessage().split('\\,')[1].split('\\.')[0].trim();
            System.assertEquals(errorMessage,expectedError,ex.getMessage());
        }
        Test.stopTest();
    }
   /**
    * @Name : createData()
	* @description : This method is used to create test data for SalesAgreementDuplicateCheck() method of the ECM_SalesAgreementTriggerHelper class
    * @return : returns a Wrapper with Sales Driver,Agreement type,Territory Budget & geography Id
	*/
    public static WrapperInst createData(){
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        EDGE_UtilityTestClass.createOrgSettings();
                
        Id recordtypeId=Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Business Unit').getRecordTypeId();
        Territory_Hierarchy__c hirarchy1= ECM_UtilityTestClass.getTerritoryHierarchy(recordtypeId, countryId, null);
        insert hirarchy1;
        
        Id recordtypeId2=Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Sales Area').getRecordTypeId();
        Territory_Hierarchy__c hirarchy2= ECM_UtilityTestClass.getTerritoryHierarchy(recordtypeId2, countryId, hirarchy1.id);
        insert hirarchy2;
        
        Id recordtypeId3=Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Region').getRecordTypeId();
        Territory_Hierarchy__c hirarchy3= ECM_UtilityTestClass.getTerritoryHierarchy(recordtypeId3, countryId, hirarchy2.id);
        insert hirarchy3;
        
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        territory.Region__c=hirarchy3.Id;
        insert territory;
        
        String bRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        Pick_Up_Options__c budjectEU = ECM_UtilityTestClass.createPickUpOption(countryId, bRecordTypeId);
        insert budjectEU;
        
        Territory_Budget__c terriBudget = ECM_UtilityTestClass.createTerritoryBudget(territory.Id, hirarchy3.Id);
        terriBudget.ECM_Budget_Type__c=budjectEU.Id;
        insert terriBudget;
        
        Id recordtypeSDId = Schema.SObjectType.ECM_Sales_Driver__c.getRecordTypeInfosByName().get('Investment').getRecordTypeId();
        ECM_Sales_Driver__c salesDriverObj = ECM_UtilityTestClass.getSalesdriver(terriBudget.Id,countryId);
        salesDriverObj.RecordTypeId = recordtypeSDId;
        insert salesDriverObj;
        
        ECM_Contract_Type__c aggTypeObj = ECM_UtilityTestClass.getAgreementType(countryId);
        insert aggTypeObj;
        
        Id recordtypeSalesId = Schema.SObjectType.ECM_Sales_Agreement__c.getRecordTypeInfosByName().get('Sales Agreement').getRecordTypeId();
        ECM_Sales_Agreement__c salesAggObj = ECM_UtilityTestClass.createsalesAggrement(aggTypeObj.Id,salesDriverObj.Id);
        salesAggObj.RecordTypeId = recordtypeSalesId;
        insert salesAggObj;
        
        
        WrapperInst wrapObj = new WrapperInst();
        wrapObj.salesDriverObj = salesDriverObj.Id;
        wrapObj.aggTypeObj = aggTypeObj.Id;  
        wrapObj.countryIdVal = countryId;
        wrapObj.terriBudgetId = terriBudget.Id;
        return wrapObj;
    }
    
    class WrapperInst{
        String salesDriverObj{get;set;}
        String aggTypeObj{get;set;}
        String countryIdVal{get;set;}
        String terriBudgetId{get;set;}
    }
}