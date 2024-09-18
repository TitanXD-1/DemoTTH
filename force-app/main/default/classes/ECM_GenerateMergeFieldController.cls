/**********************************************************************
Name: ECM_GenerateMergeFieldController
=======================================================================
Purpose: This is Class to fetch the Sojects and selected object fields and to 
         use in ECM_GenerateMegreField lightning component
=======================================================================
History                                                            
-------                                                            
VERSION    AUTHOR                   DATE              DETAIL
1.0      Pradeep Kumar Reddy       27/04/2020        Initial Development
***********************************************************************/ 
public with sharing class ECM_GenerateMergeFieldController {
    
    // Method Name : getSobjects
    // Description : This method is used to get the Sobject
    @AuraEnabled
    public static list<sObjectWrapper> getSobjects(){
        list<sObjectWrapper> sobjWrapList = new List<sObjectWrapper>();
        List<String> objectList = new List<String>();
        for(ECM_Dynamic_Query__mdt dyQuery: [Select DeveloperName, MasterLabel,ECM_Object_API_Name__c,ECM_Where_Condition__c From ECM_Dynamic_Query__mdt]){
            objectList.add(dyQuery.ECM_Object_API_Name__c);
        } 
        //map<String, Schema.SobjectType> SchemaObjMap = Schema.getGlobalDescribe();
        //List<String> SchemaObjList = new List<String>(so.keyset());

        Schema.DescribeSObjectResult[] schemaDescResult = Schema.describeSObjects(objectList);
        for(Schema.DescribeSObjectResult schemaDesc: schemaDescResult){
            sObjectWrapper sobjWrap = new sObjectWrapper();
            sobjWrap.sObjectLabel = schemaDesc.getLabel();
            sobjWrap.sObjectName = schemaDesc.getName();
            sobjWrapList.add(sobjWrap);
        }

        return sobjWrapList;
    }
    // Method Name : getFields
    // Description : This method is used to get the fields which are related to the selected Object
    @AuraEnabled
    public static list<fieldsWrapper> getFields(String ObjectName){
        list<fieldsWrapper> fieldWrapList = new List<fieldsWrapper>();
        map<String, Schema.SobjectType> SchemaObjMap = Schema.getGlobalDescribe();
        map<String,Schema.SObjectField> SchemaFieldMap = SchemaObjMap.get(ObjectName).getDescribe().fields.getMap();
        Schema.DescribeSObjectResult obj = SchemaObjMap.get(ObjectName).getDescribe();

        for(String field : SchemaFieldMap.keyset()){
            fieldsWrapper fieldWrap = new fieldsWrapper();
            Schema.DescribeFieldResult dfr = obj.Fields.getMap().get(field).getDescribe();
            fieldWrap.fieldLabel = dfr.getLabel();
            fieldWrap.fieldName = dfr.getName();
            fieldWrapList.add(fieldWrap);
        }

        return fieldWrapList;
    }

    public class sObjectWrapper{
        @AuraEnabled public String sObjectLabel{get;set;}
        @AuraEnabled public String sObjectName{get;set;}
    }
    public class fieldsWrapper{
        @AuraEnabled public String fieldLabel{get;set;}
        @AuraEnabled public String fieldName{get;set;}
    }
}