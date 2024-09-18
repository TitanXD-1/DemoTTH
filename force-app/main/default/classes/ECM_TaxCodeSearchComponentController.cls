/*
* Class Name : ECM_TaxCodeSearchComponentController
* @description: Class used in ECM_TaxCodeLookUp component to fetch tax code values from pickuo options object.
getResults* @history
* AUTHOR            DATE              	DETAIL
* Keshav         	29/11/2021      	ECM-4933 : PS: pick-up options validation_GLO
* Pratik         	12/05/2022      	ECM-5451 : Added recordtype value in getResults function
*/
public class ECM_TaxCodeSearchComponentController {
    
    @AuraEnabled
    public static List<SObJectResult> getResults(String ObjectName, String fieldName, String value, String recordType) {
        List<SObJectResult> sObjectResultList = new List<SObJectResult>();
        string recTypefilter = '';
        string recordTypeValue = recordType; //added for ecm-5451
        if(ObjectName == 'Pick_Up_Options__c'){
           // recTypefilter='RecordTypeId ='+'\''+Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Tax Code').getRecordTypeId()+'\'';
            recTypefilter='RecordTypeId ='+'\''+Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get(recordTypeValue).getRecordTypeId()+'\'';
        }
        for(sObject so : Database.Query('Select Id,'+fieldName+' FROM '+ObjectName+' WHERE '+(recTypefilter!=''?recTypefilter+' AND ':'')+fieldName+' LIKE \'%' + value + '%\'')) {
            //Remove country code from Name
            String fieldvalue = (String)so.get(fieldName);
            fieldValue= fieldValue.left(fieldValue.length()-4);
            sObjectResultList.add(new SObjectResult(fieldvalue, so.Id));
        }
        // Sort Wrapper
        sObjectResultList.sort();
        system.debug('sObjectResultList-->'+sObjectResultList);
        return sObjectResultList;
    }
    
    public class SObJectResult implements Comparable{
        @AuraEnabled
        public String recName;
        @AuraEnabled
        public Id recId;
        
        // Constructor
        public SObJectResult(String recNameTemp, Id recIdTemp) {
            recName = recNameTemp;
            recId = recIdTemp;
        }
        // Compare Tax code based on the budget type.
        public Integer compareTo(Object compareTo) {            
            if( this.recName.right(3) < ((SObJectResult)compareTo).recName.right(3)){
                return 0;
            }else if( this.recName.right(3) > ((SObJectResult)compareTo).recName.right(3)){
                return 1;
            }else{
                return -1;
            }
        }
    }
}