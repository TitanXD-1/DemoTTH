/*
 * @Class Name : ECM_AgreementApprovalTriggerHelperTest
 * @description : Test Class for Agreement Approval Trigger
 * @history:
 * VERSION    AUTHOR                DATE              DETAIL
 * 1.1        Saurav Paul       	   13/08/2021		 Initial Developement 
*/
@isTest
public class ECM_AgreementApprovalTriggerHelperTest {
    /*
     * @description : testing insert 
    */
    @isTest
    public static void testSDIExtraApprovalValidation(){
        Id contId;
        contId = EDGE_UtilityTestClass.setupCountry('ES');
        EDGE_UtilityTestClass.createOrgSettings();
        Id buRecTypeId = Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Business Unit').getRecordTypeId();
        Id saRecTypeId = Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Sales Area').getRecordTypeId();
        Id regRecTypeId = Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Region').getRecordTypeId();
        
        Territory_Hierarchy__c hierBUObj = ECM_UtilityTestClass.getTerritoryHierarchy(buRecTypeId,contId,null);
        insert hierBUObj;
        Territory_Hierarchy__c hierSAObj = ECM_UtilityTestClass.getTerritoryHierarchy(saRecTypeId,contId,hierBUObj.Id);
        insert hierSAObj;
        Territory_Hierarchy__c hierRegionObj = ECM_UtilityTestClass.getTerritoryHierarchy(regRecTypeId,contId,hierSAObj.Id);
        insert hierRegionObj;
        Territory__c territoryObj = ECM_UtilityTestClass.getTerritory(contId,hierRegionObj.Id);
        insert territoryObj;
        system.assert(territoryObj.Id != null, 'territoryObj Id should not be null');
        
        
        ECM_Extra_Approval__c  extraAppObj = ECM_UtilityTestClass.getExtraApproval(contId,hierSAObj.Id);
        extraAppObj.ECM_Type__c = 'Contract Sales Driver Item';
        extraAppObj.ECM_Lower_Limit_Amount__c = null;
        insert extraAppObj;
        ECM_Contract_Type__c agrmntTypObj = ECM_UtilityTestClass.getAgreementType(contId);
        agrmntTypObj.ECM_Screen_3_field_configuration__c='Product Name;Volume Target;UoM';
        insert agrmntTypObj;
        ECM_Agreement_Approval__c agrmntAppObj = ECM_UtilityTestClass.getAgrmntApproval(agrmntTypObj.Id,extraAppObj.Id);
        insert agrmntAppObj;
        ECM_Agreement_Approval__c agrmntAppObj1 = ECM_UtilityTestClass.getAgrmntApproval(agrmntTypObj.Id,extraAppObj.Id);
        Test.startTest();
        try{
            insert agrmntAppObj1;
        }catch(Exception ex){
            System.debug(LoggingLevel.Debug,'Error '+ex.getCause());
            
        }
        Test.stopTest();
    }
    /*
     * @description : testing update 
    */
    @isTest
    public static void testSDIExtraApprovalValidationUpdate(){
        Id contId;
        contId = EDGE_UtilityTestClass.setupCountry('ES');
        EDGE_UtilityTestClass.createOrgSettings();
        Id buRecTypeId = Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Business Unit').getRecordTypeId();
        Id saRecTypeId = Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Sales Area').getRecordTypeId();
        Id regRecTypeId = Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Region').getRecordTypeId();
        
        Territory_Hierarchy__c hierBUObj = ECM_UtilityTestClass.getTerritoryHierarchy(buRecTypeId,contId,null);
        insert hierBUObj;
        Territory_Hierarchy__c hierSAObj = ECM_UtilityTestClass.getTerritoryHierarchy(saRecTypeId,contId,hierBUObj.Id);
        insert hierSAObj;
        Territory_Hierarchy__c hierRegionObj = ECM_UtilityTestClass.getTerritoryHierarchy(regRecTypeId,contId,hierSAObj.Id);
        insert hierRegionObj;
        Territory__c territoryObj = ECM_UtilityTestClass.getTerritory(contId,hierRegionObj.Id);
        insert territoryObj;
        system.assert(territoryObj.Id != null, 'territoryObj Id should not be null');
        
        
        ECM_Extra_Approval__c  extraAppObj = ECM_UtilityTestClass.getExtraApproval(contId,hierSAObj.Id);
        extraAppObj.ECM_Type__c = 'Contract Sales Driver Item';
        extraAppObj.ECM_Lower_Limit_Amount__c = null;
        insert extraAppObj;
        
        ECM_Extra_Approval__c  extraAppObj1 = ECM_UtilityTestClass.getExtraApproval(contId,hierSAObj.Id);
        extraAppObj1.ECM_Type__c = 'Contract Sales Driver Item';
        extraAppObj1.ECM_Lower_Limit_Amount__c = null;
        insert extraAppObj1;
        
        ECM_Contract_Type__c agrmntTypObj = ECM_UtilityTestClass.getAgreementType(contId);
        agrmntTypObj.ECM_Screen_3_field_configuration__c='Product Name;Volume Target;UoM';
        insert agrmntTypObj;
        ECM_Agreement_Approval__c agrmntAppObj = ECM_UtilityTestClass.getAgrmntApproval(agrmntTypObj.Id,extraAppObj1.Id);
        insert agrmntAppObj;
        ECM_Agreement_Approval__c agrmntAppObj1 = ECM_UtilityTestClass.getAgrmntApproval(agrmntTypObj.Id,extraAppObj.Id);
        insert agrmntAppObj1;
        
        agrmntAppObj1.ECM_Extra_Approval__c = extraAppObj1.Id; 
        Test.startTest();
        try{
            Update agrmntAppObj1;
        }catch(Exception ex){
            System.debug(LoggingLevel.Debug,'Error '+ex.getCause());
        }
        Test.stopTest();
    }
    /*
     * @description :	testing update 
     * @developer	:	Saurav Prasad
    */
    @isTest
    public static void testSDIExtraApprovalDeleteAndUndelete(){
        Id contId;
        contId = EDGE_UtilityTestClass.setupCountry('ES');
        EDGE_UtilityTestClass.createOrgSettings();
        Id buRecTypeId = Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Business Unit').getRecordTypeId();
        Id saRecTypeId = Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Sales Area').getRecordTypeId();
        Id regRecTypeId = Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Region').getRecordTypeId();
        
        Territory_Hierarchy__c hierBUObj = ECM_UtilityTestClass.getTerritoryHierarchy(buRecTypeId,contId,null);
        insert hierBUObj;
        system.assert(hierBUObj.Id != null, 'hierBUObj Id should not be null');
        
        Territory_Hierarchy__c hierSAObj = ECM_UtilityTestClass.getTerritoryHierarchy(saRecTypeId,contId,hierBUObj.Id);
        insert hierSAObj;
        Territory_Hierarchy__c hierRegionObj = ECM_UtilityTestClass.getTerritoryHierarchy(regRecTypeId,contId,hierSAObj.Id);
        insert hierRegionObj;
        Territory__c territoryObj = ECM_UtilityTestClass.getTerritory(contId,hierRegionObj.Id);
        insert territoryObj;
        
        ECM_Extra_Approval__c  extraAppObj = ECM_UtilityTestClass.getExtraApproval(contId,hierSAObj.Id);
        extraAppObj.ECM_Type__c = 'Contract Sales Driver Item';
        extraAppObj.ECM_Lower_Limit_Amount__c = null;
        insert extraAppObj;
        
        ECM_Extra_Approval__c  extraAppObj1 = ECM_UtilityTestClass.getExtraApproval(contId,hierSAObj.Id);
        extraAppObj1.ECM_Type__c = 'Contract Sales Driver Item';
        extraAppObj1.ECM_Lower_Limit_Amount__c = null;
        insert extraAppObj1;
        
        ECM_Contract_Type__c agrmntTypObj = ECM_UtilityTestClass.getAgreementType(contId);
        agrmntTypObj.ECM_Screen_3_field_configuration__c='Product Name;Volume Target;UoM';
        insert agrmntTypObj;
        ECM_Agreement_Approval__c agrmntAppObj = ECM_UtilityTestClass.getAgrmntApproval(agrmntTypObj.Id,extraAppObj1.Id);
        insert agrmntAppObj;
        ECM_Agreement_Approval__c agrmntAppObj1 = ECM_UtilityTestClass.getAgrmntApproval(agrmntTypObj.Id,extraAppObj.Id);
        insert agrmntAppObj1;
        
        agrmntAppObj1.ECM_Extra_Approval__c = extraAppObj1.Id; 
        Test.startTest();
        delete agrmntAppObj1;
        undelete agrmntAppObj1;
        Test.stopTest();
    }
}