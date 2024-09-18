/*
@Name: CO_SendToSAPRequest

@Purpose: This class is used Create Request body for Send To SAP Action on Customer Request

@History                                                            
                                                          
VERSION    AUTHOR            DATE              DETAIL
1.0        Gaurav Singh      8-28-2022        Initial Development

*/
public with sharing class CO_SendToSAPRequest {
    public Static String createRequestBody( Customer_Request__c crRecord, List<CO_SendToSAP.RequestMapping> requestMappings, String sourceSystem ){
        Map<String,Object> requestData = new Map<String,Object>();
        for( CO_SendToSAP.RequestMapping requestMapping : requestMappings ){
            if( !requestData.containsKey(requestMapping.requestMappingRecord.Attribute_Name__c) && (requestMapping.requestMappingRecord.Country__c == NULL || requestMapping.requestMappingRecord.Country__c == crRecord.Country__r.Code__c) && (requestMapping.requestMappingRecord.Sales_Orgnanization__c == NULL || requestMapping.requestMappingRecord.Sales_Orgnanization__c == crRecord.CO_Sales_Organisation__r.Code__c) && (requestMapping.requestMappingRecord.Customer_Type__c == NULL || requestMapping.requestMappingRecord.Customer_Type__c == crRecord.RecordType.DeveloperName) ){
                createRequestAttributeObject(crRecord, requestMapping, requestData);
            }
        }
        
        return JSON.serialize(requestData);
    }

    private Static Map<String,Object> createRequestObject( SObject crRecord, List<CO_SendToSAP.RequestMapping> requestMappings ){
        Map<String,Object> requestData = new Map<String,Object>();
        for( CO_SendToSAP.RequestMapping requestMapping : requestMappings ){
            createRequestAttributeObject(crRecord, requestMapping, requestData);
        }

        return (requestData.isEmpty()?null:requestData);
    }

    private Static void createRequestAttributeObject( SObject crRecord, CO_SendToSAP.RequestMapping requestMapping, Map<String,Object> requestData ){
        if( requestMapping.childRequestMappings.isEmpty() ){
            setAttributeGetFieldInRequestBody(requestData, requestMapping.requestMappingRecord, crRecord);
        }else if( String.isNotBlank(requestMapping.requestMappingRecord.Child_Relationship_API_Name__c) ){
            createRequestAttributeChildRelObject(requestData, crRecord, requestMapping);
        }else{
            createRequestAttributeChildObject(requestData, crRecord, requestMapping);
        }
    }

    private Static void createRequestAttributeChildRelObject( Map<String,Object> requestData, SObject crRecord, CO_SendToSAP.RequestMapping requestMapping  ){        
        List<SObject> childRecords = new List<SObject>();
        for(SObject childRec : crRecord.getSObjects(requestMapping.requestMappingRecord.Child_Relationship_API_Name__c)){
            childRecords.add(childRec);
        }
        
        if( childRecords != NULL ){
            List<Object> childObjects = new List<Object>();
            for( SObject childRecord : childRecords ){
                Object childObject = createRequestObject(childRecord, requestMapping.childRequestMappings);

                if( childObject != NULL ){
                    childObjects.add(childObject);
                }
            }

            requestData.put(requestMapping.requestMappingRecord.Attribute_Name__c, childObjects);
        }
    }

    private Static void createRequestAttributeChildObject( Map<String,Object> requestData, SObject crRecord, CO_SendToSAP.RequestMapping requestMapping  ){        
        Object childObject = createRequestObject(crRecord, requestMapping.childRequestMappings);
        if( childObject != NULL ){
            requestData.put(requestMapping.requestMappingRecord.Attribute_Name__c, childObject);
        }
    }


    private Static void createRequestAttributeChildObject( Map<String,Object> requestData, Customer_Request__c crRecord, CO_SendToSAP.RequestMapping requestMapping  ){        
        Object childObject = createRequestObject(crRecord, requestMapping.childRequestMappings);
        if( childObject != NULL ){
            requestData.put(requestMapping.requestMappingRecord.Attribute_Name__c, childObject);
        }
    }

    private Static void setAttributeGetFieldInRequestBody( Map<String,Object> requestData, CO_SF_To_SAP_Mapping__mdt requestMapping, SObject sfObject){
        List<String> fieldDepth = requestMapping.API_Name__c.split('\\.');
        Integer currentDepth = 0;
        while( currentDepth < fieldDepth.size() ){
            if( currentDepth == fieldDepth.size()-1 ){
                Object fieldValue = sfObject.get(fieldDepth[currentDepth]);

                setAttributeFieldValueInRequestBody(requestData, fieldValue, requestMapping);
            }else{
                sfObject = sfObject.getSObject(fieldDepth[currentDepth]);
                if( sfObject == NULL ){
                    break;
                }
            }
            
            currentDepth++;
        }
    }

    private Static void setAttributeFieldValueInRequestBody( Map<String,Object> requestData, Object fieldValue, CO_SF_To_SAP_Mapping__mdt requestMapping){
        if( fieldValue != NULL ){
            String attributeConversion = (String.isNotBlank(requestMapping.Attribute_Data_Type__c)?requestMapping.Attribute_Data_Type__c.toLowerCase():'None');
            switch on attributeConversion {
                when 'boolean' {
                    requestData.put(requestMapping.Attribute_Name__c, (Boolean.valueOf(fieldValue)? 'X':''));
                }	
                when 'integer' {
                    requestData.put(requestMapping.Attribute_Name__c, Integer.valueOf(fieldValue));
                }
                when 'decimal' {
                    requestData.put(requestMapping.Attribute_Name__c, Decimal.valueOf((String)fieldValue));
                }
                when 'string' {
                    requestData.put(requestMapping.Attribute_Name__c, String.valueOf(fieldValue).replaceAll('\r\n',' '));
                }
                when 'date' {
                    Date dt = Date.valueOf(fieldValue);
                    requestData.put(requestMapping.Attribute_Name__c, dt.year()+(dt.month()<10?'0':'')+dt.month()+(dt.day()<10?'0':'')+dt.day());
                }
                when else {
                    requestData.put(requestMapping.Attribute_Name__c, getAttributeFieldValue(fieldValue,requestMapping));
                }
            }
        }
    }

    private Static Object getAttributeFieldValue( Object fieldValue, CO_SF_To_SAP_Mapping__mdt requestMapping ){
        if( requestMapping.Length__c != NULL && ((String)fieldValue).length() > requestMapping.Length__c ){
            return ((String)fieldValue).substring(0, Integer.valueof(requestMapping.Length__c));
        }else{
            return fieldValue;
        }
    }
}