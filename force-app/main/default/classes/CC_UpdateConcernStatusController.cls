public class CC_UpdateConcernStatusController {
    @auraEnabled
    public static CC_Customer_Concern__c getConcernStatusPickVal(string concernId)
    {
        if(!String.isBlank(concernId))
        { 
             CC_Customer_Concern__c concern=[select Id, CC_Status__c,CC_CoQ_Management_time_failure_analysis__c, CC_Cost_of_Quality_Additional_Inspection__c,
                                            CC_Cost_of_Quality_In_process_waste__c,CC_Cost_of_Quality_Rework_reprocessing__c, CC_Cost_of_Quality_Scrap__c,
                                            CC_Cost_of_Quality_Cost_of_Reclaims__c from CC_Customer_Concern__c Where Id =: concernId]; 
            
            return concern;
        }
        return null;
    }
    
   /* @AuraEnabled
    public static Map<String, String> getPicklistvalues(String objectName, String field_apiname,Boolean nullRequired){
        Map<String, String> options = new Map<String, String>();
        
        Map<String,Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
        Map<String, Schema.SObjectField> field_map = gd.get(objectName.toLowerCase()).getDescribe().fields.getMap(); 
        
        List<Schema.PicklistEntry> picklistValues = field_map.get(field_apiname).getDescribe().getPickListValues();
        
        if(nullRequired == true){
            options.put('--None--','--None--');
        }
        for (Schema.PicklistEntry pv : picklistValues) {
            options.put(pv.getValue(), pv.getLabel());
        }
        system.debug('Options :::: ' + options);
        return options;
    }*/
    
    @auraEnabled
    public static String getUpdateConcernStatus(string concernId, CC_Customer_Concern__c ccObj)
    {
        if(!String.isBlank(concernId) && ccObj != null)
        { 
            CC_Customer_Concern__c concern=[select Id, CC_Status__c,CC_CoQ_Management_time_failure_analysis__c, CC_Cost_of_Quality_Additional_Inspection__c,
                                            CC_Cost_of_Quality_In_process_waste__c,CC_Cost_of_Quality_Rework_reprocessing__c, CC_Cost_of_Quality_Scrap__c,
                                            CC_Cost_of_Quality_Cost_of_Reclaims__c from CC_Customer_Concern__c Where Id =: concernId]; 
            
            concern.CC_Status__c 									= 	ccObj.CC_Status__c;
            concern.CC_CoQ_Management_time_failure_analysis__c 		= 	ccObj.CC_CoQ_Management_time_failure_analysis__c;
            concern.CC_Cost_of_Quality_Additional_Inspection__c 	= 	ccObj.CC_Cost_of_Quality_Additional_Inspection__c;
            concern.CC_Cost_of_Quality_In_process_waste__c 			= 	ccObj.CC_Cost_of_Quality_In_process_waste__c;
            concern.CC_Cost_of_Quality_Rework_reprocessing__c 		= 	ccObj.CC_Cost_of_Quality_Rework_reprocessing__c;
            concern.CC_Cost_of_Quality_Scrap__c 					= 	ccObj.CC_Cost_of_Quality_Scrap__c;
            concern.CC_Cost_of_Quality_Cost_of_Reclaims__c 			= 	ccObj.CC_Cost_of_Quality_Cost_of_Reclaims__c;
            //concern.CC_Is_it_a_regulatory_issue__c 					=	ccObj.CC_Is_it_a_regulatory_issue__c;

            update concern;
            return concern.CC_Status__c;
        }
        return null;
    }
    
}