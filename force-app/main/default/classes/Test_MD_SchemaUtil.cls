@isTest(SeeAllData=false)
public with sharing class Test_MD_SchemaUtil {
    static testMethod void testGetObjectField() {
        System.assert(MD_SchemaUtil.getObjectField('Account', 'AccountNumber').getDescribe().getName() == 'AccountNumber' 
                     && MD_SchemaUtil.getObjectField('NonObject', 'NonField') == null);
    }    
    
	/* getObjectFields */
    static testMethod void testGetObjectFields() {
        Schema.DescribeSObjectResult objectType = Schema.MD_Agreement__c.getSObjectType().getDescribe();
        Map<String, Schema.SobjectField> objectFields = MD_SchemaUtil.getObjectFields(objectType);
        System.assert(objectFields.size() > 0);
    }
	
    /* valid getObjectDescribeByName */
    static testMethod void testGetObjectDescribeByName() {
        Schema.DescribeSObjectResult objectDescribe = MD_SchemaUtil.getObjectDescribeByName('MD_Agreement__c');
        System.assert(objectDescribe != null);
    }
	
    /* invalid getObjectDescribeByName */
    static testMethod void testGetObjectDescribeByNameInvalid() {
        Schema.DescribeSObjectResult objectDescribe = MD_SchemaUtil.getObjectDescribeByName('Fail');
        System.assert(objectDescribe == null);
    }
    
    /* getOperatorsForField */
    static testMethod  void testGetOperatorsForField() {
        Schema.DescribeSObjectResult objectDescribe = MD_SchemaUtil.getObjectDescribeByName('MD_Agreement__c');
        Schema.SobjectField objectField = MD_SchemaUtil.getObjectFields(objectDescribe).get('Id');
        List<SelectOption> operators = MD_SchemaUtil.getOperatorsForField(objectField);
        System.assert(objectField != null);
    }
	
    /* getOperatorsForFieldType */
    static testMethod void testGetOperatorsForFieldTypeString() {
        List<SelectOption> operators = MD_SchemaUtil.getOperatorsForFieldType(Schema.DisplayType.STRING);
        System.assert(!operators.isEmpty());
    }
    
    static testMethod void testGetOperatorsForFieldTypeNumber() {
        List<SelectOption> operators = MD_SchemaUtil.getOperatorsForFieldType(Schema.DisplayType.INTEGER);
        System.assert(!operators.isEmpty());
    }
    
    static testMethod void testGetOperatorsForFieldTypeDate() {
        List<SelectOption> operators = MD_SchemaUtil.getOperatorsForFieldType(Schema.DisplayType.DATE);
        System.assert(!operators.isEmpty());
    }
}