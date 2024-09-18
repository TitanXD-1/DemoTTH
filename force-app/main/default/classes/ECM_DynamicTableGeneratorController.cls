/*
Name: ECM_DynamicTableGeneratorController
*
Purpose: This is Class for fetch required data for components "ECM_DynamicTableGenerator"
*
*History*                                                            
*                                                            
VERSION    AUTHOR                DATE              DETAIL
1.0      Anivesh Muppa        14/04/2020        Initial Development
2.0      Anivesh Muppa        29/10/2021        ECM-4918- PDF Failing when adding fields to dynamic table
2.1		 Saurav Prasad		  13/12/2022		ECM-6558 : QA Defect_Total Investment Amount is not populating in PDF  
*/ 
public class ECM_DynamicTableGeneratorController {
    @AuraEnabled
    public static Map <String, String> getFieldApiNames(String sobjectName,List<String> selectfields) {
        Schema.SObjectType schemaObjName = Schema.getGlobalDescribe().get(sobjectName);
        system.debug('object='+schemaObjName);
        Map<String, String> fieldConversion = new Map<String, String>{
   		'UOS' => 'UoS Conversion Rate',
        'MAT Override' => 'Annual Volume',
        'MAT UOS'=>'Total UOS',
        'Current LUC'=>'LUC'
        }; 
        Map <String, String> labelToAPIName = new Map <String, String> ();
        Map<String, String> parentAPINames = new Map<String, String> ();        
        try{
            Map<String, Schema.SObjectField> fieldsMap = schemaObjName.getDescribe().fields.getMap();
            if(sobjectName=='ECM_Sales_Driver_Item_Detail__c'){
                parentAPINames = ECM_PDF_Generation_Controller.getParentLabels('ECM_Sales_Driver_Item__c',selectfields,fieldsMap);
            }
            system.debug('list field='+fieldsMap);
            for (Schema.SObjectField field : fieldsMap.values())
            {
                if(selectfields.contains(field.getDescribe().getLabel())){ 
                    system.debug('field=='+field.getDescribe().getLabel());
                    labelToAPIName.put(field.getDescribe().getLabel(), field.getDescribe().getName());                  
                }else if(selectfields.contains(fieldConversion.get(field.getDescribe().getLabel()))){
                    labelToAPIName.put(fieldConversion.get(field.getDescribe().getLabel()), field.getDescribe().getName());
                }
            }
            if(!parentAPINames.isEmpty()){
                for(string parentName : selectfields){
                    if(parentAPINames.containskey(parentName)){
                        labelToAPIName.put(parentName,parentAPINames.get(parentName));
                    }
                }
            }
            
        }catch(Exception ex){
            system.debug('==exception '+ex);
        }
        return labelToAPIName;
    }
    public static List<String> getPickListValuesIntoList(list<String> dtgSet){
       List<String> pickListValuesList= new List<String>();
		Schema.DescribeFieldResult fieldResult = ECM_Dynamic_Table_Generator__c.ECM_Dynamic_Fields__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple){
			if(dtgSet.contains(pickListVal.getLabel())){
				pickListValuesList.add(pickListVal.getLabel());
			}else if(System.Label.ECM_GAS_Market_CountryCodes.contains(Userinfo.getLanguage().toUpperCase()) && dtgSet.contains(pickListVal.getValue())){
                //ECM-6558
                pickListValuesList.add(System.Label.ECM_DynamicTable_DynamicFields_GetValues.containsIgnoreCase(pickListVal.getValue())?pickListVal.getValue():pickListVal.getLabel());
            }else if(dtgSet.contains(pickListVal.getValue())){//added as per ECM-4918
                pickListValuesList.add(pickListVal.getValue());                
            }
		}  
        system.debug('pickListValuesList+'+pickListValuesList);
		return pickListValuesList;
    }
    @AuraEnabled
    Public static lightningTableWrapper getRecords(String sobjectName,List<String> selectfields){
        system.debug('obje'+sobjectName);
        system.debug('selectfields=='+selectfields);
         Map <String, String> labelToAPIName = getFieldApiNames(sobjectName,selectfields);
        system.debug('=='+labelToAPIName);
        string queryStr;
        for(string fieldapi : labelToAPIName.values()){
            queryStr =queryStr==Null? fieldapi:queryStr+','+fieldapi;
        }
        system.debug('===query'+queryStr);
        queryStr = 'SELECT '+queryStr+' FROM '+sobjectName;
        
        lightningTableWrapper ltw = new lightningTableWrapper();
        ltw.total = database.countQuery('Select count() from '+String.escapeSingleQuotes(sobjectName));        
        ltw.sObjectrecords = database.query(queryStr);
        ltw.fieldsapi = labelToAPIName;
        return ltw;
    }
    public class lightningTableWrapper {
        @AuraEnabled
        public Integer page { get;set; }        
        @AuraEnabled
        public Integer total { get;set; }        
        @AuraEnabled
        public List<sObject> sObjectrecords { get;set; }
        @AuraEnabled
        public Map <String, String> fieldsapi { get;set; }
    }
}