/**

* @Description: EDGE_QualitySLAProcessHelper

* @Purpose : Quality SLA Process Helper Class for Case

* @History:

* @Version     Developer		   Date			     Story/Purpose

	 1.1       Sudipta           20/09/2021        ES20-11106(updateQualityEntitlementName)
*/
public class EDGE_QualitySLAProcessHelper {
    final static String QualityRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();     
    
    /**

    * @description : updateQualityEntitlementName - Update Case Entitlement based on Case Type
    
    * @return : void
    
    * @param : List<SObject>

	*/
    public static void updateQualityEntitlementName(List<SObject> newItems){
        try{
            //adding all Quality related Recordtype IDs
            Map<String,String> entitlementProcessMap = new Map<String,String>();
            Map<String,String> mapCaseTypeEntitlementProcess = new Map<String,String>();
            
            
            //get MAP of Custom Metadata
            if(Schema.sObjectType.Quality_Case_Entitlement_Configuration__mdt.isAccessible()) { 
                for (Quality_Case_Entitlement_Configuration__mdt cE_obj: [SELECT Case_Type_Name__c,Country_Code__c,Entitlement_Name__c FROM Quality_Case_Entitlement_Configuration__mdt] ){     
                    mapCaseTypeEntitlementProcess.put(cE_obj.Case_Type_Name__c,cE_obj.Entitlement_Name__c);
                }
            }
            //Get Entitlement Record
           
            System.debug('mapCaseTypeEntitlementProcess--'+mapCaseTypeEntitlementProcess);
            for(Entitlement entl: [SELECT id, Name from Entitlement where Status ='Active' 
                                   AND Name IN :mapCaseTypeEntitlementProcess.values()])
            {
            	entitlementProcessMap.put(entl.Name,entl.id);
            }
             System.debug('entitlementProcessMap--'+entitlementProcessMap);
            for(SObject obj :newItems){ 
                Case caseObj = (Case)obj;
                if(caseObj.RecordTypeId == QualityRecordTypeId && caseObj.Status == 'Open' 
                   && entitlementProcessMap != null && entitlementProcessMap.size()>0)
                {
                    String entitleName = mapCaseTypeEntitlementProcess.get(caseObj.Case_Type_Name__c);
                    System.debug('entitleName--'+entitleName);
                    if(entitleName !=null )
                    {
                        Id entId = entitlementProcessMap.get(entitleName);
						if(entId != null){
                            caseObj.EntitlementId = entId;
                        }
                    }
                }            
            }
        }
        catch(Exception e){
            System.debug('Exception Caught in method:updateQualityEntitlementName at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
        }
    }

}