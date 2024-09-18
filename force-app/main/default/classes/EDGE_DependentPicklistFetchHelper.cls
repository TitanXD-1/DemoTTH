/**********************************************************************
	Name: EDGE_DependentPicklistFetchHelper
================================================================================
	Req: The requirement is to build Custom API for mobile to get sObjects' dependent picklist Data
	User Story : ES20-1191
================================================================================
	History                                                            
-------                                                            
    VERSION   AUTHOR                   DATE              DETAIL
	1.0       Anuja Chattopadhyay      23/04/2019       Custom API for mobile to get sObjects' dependent picklist Data    
***********************************************************************/
public inherited sharing class EDGE_DependentPicklistFetchHelper {
    /********************************************************************************************
	Method Name: getDependentMap
	Description : This method returns dependent field values mapped to controlling field values of an object.
	*********************************************************************************************/
    public static Map<String, List<String>> getDependentMap(sObject objDetail, string contrfieldApiName,string depfieldApiName) {
        String controllingField = contrfieldApiName.toLowerCase();
        String dependentField = depfieldApiName.toLowerCase();
        
        Map<String,List<String>> objResults = new Map<String,List<String>>();
        
        Schema.sObjectType objType = objDetail.getSObjectType();
        if (objType==null){
            return objResults;
        }
        
        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
        
        if (!objFieldMap.containsKey(controllingField) || !objFieldMap.containsKey(dependentField)){
            return objResults;     
        }
        
        Schema.SObjectField theField = objFieldMap.get(dependentField);
        Schema.SObjectField ctrlField = objFieldMap.get(controllingField);
        
        List<Schema.PicklistEntry> contrEntries = ctrlField.getDescribe().getPicklistValues();
        List<PicklistEntryWrapper> depEntries = wrapPicklistEntries(theField.getDescribe().getPicklistValues());
        List<String> controllingValues = new List<String>();
        
        for (Schema.PicklistEntry ple : contrEntries) {
            String label = ple.getLabel();
            objResults.put(label, new List<String>());
            controllingValues.add(label);
        }
        
        for (PicklistEntryWrapper plew : depEntries) {
            String label = plew.label;
            String validForBits = base64ToBits(plew.validFor);
            for (Integer i = 0; i < validForBits.length(); i++) {
                String bit = validForBits.mid(i, 1);
                if (bit == '1') {
                    objResults.get(controllingValues.get(i)).add(label);
                }
            }
        }
        return objResults;
        
    }
    
    /********************************************************************************************
    Method Name: decimalToBinary
   	Description : This method converts decimal number to binary.
    *********************************************************************************************/
    public static String decimalToBinary(Integer val) {
        String bits = '';
        while (val > 0) {
            Integer remainder = Math.mod(val, 2);
            val = Integer.valueOf(Math.floor(val / 2));
            bits = String.valueOf(remainder) + bits;
        }
        return bits;
    }
    
    /********************************************************************************************
    Method Name: base64ToBits
    Description : This method returns base64 characters for every binary bits.
	*********************************************************************************************/
    public static String base64ToBits(String validFor) {
        if (String.isEmpty(validFor))
        {
            return '';
        }
        
        String validForBits = '';
        
        for (Integer i = 0; i < validFor.length(); i++) {
            String thisChar = validFor.mid(i, 1);
            Integer val = base64Chars.indexOf(thisChar);
            String bits = decimalToBinary(val).leftPad(6, '0');
            validForBits += bits;
        }
        
        return validForBits;
    }
    
    private static final String BASE64CHARS = '' +
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
        'abcdefghijklmnopqrstuvwxyz' +
        '0123456789+/';
    
    /********************************************************************************************
    Method Name: wrapPicklistEntries
    Description : This method collects valid dependent values against every bits.
	*********************************************************************************************/
    private static List<PicklistEntryWrapper> wrapPicklistEntries(List<Schema.PicklistEntry> pLEs) {
        return (List<PicklistEntryWrapper>)
            JSON.deserialize(JSON.serialize(pLEs), List<PicklistEntryWrapper>.class);
    }
    
    /********************************************************************************************
    Class Name: PicklistEntryWrapper
    Description : This class holds values as a wrapper object.
	*********************************************************************************************/
    public class PicklistEntryWrapper{
        public String active {get;set;}
        public String defaultValue {get;set;}
        public String label {get;set;}
        public String value {get;set;}
        public String validFor {get;set;}
        public PicklistEntryWrapper(){            
        
        }
    }
}