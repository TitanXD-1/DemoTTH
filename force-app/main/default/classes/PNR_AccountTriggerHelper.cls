/**********************************************************************
Name: PNR_AccountTriggerHelper
=======================================================================
Purpose: Trigger Handler Class for Account for Pioneer
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR            DATE              DETAIL
1.0         Saurav Paul       29/04/2020       Initial Development for PION-1500
***********************************************************************/
public with sharing class PNR_AccountTriggerHelper {
/*******************************************************************
Method  : updateProductEnabled
Purpose : This methods used to update Product_Enabled for Pioneer Customer Only
********************************************************************/  
    public static void updateProductEnabled(List<SObject> newItems){
        for(SObject obj :newItems){ 
            Account accObj = (Account)obj;
            if( String.isNotBlank(accObj.AccountSource) && accObj.AccountSource.equalsIgnoreCase(System.Label.PNR_SAP_Pioneer)){
               accObj.Products_Enabled__c  = System.Label.PNR_Pioneer;
               accObj.Pioneer_Enabled__c = true;//NCP-1581
            }
        }
    }
    
    public static void accountSharingUsingApex(Map<id, SObject> newObjectMap, Map<Id, SObject> oldObjectMap, String operation){
        try{
            if(operation == 'insert'){
                PNR_SharingUtil.generateSharingFromSalesOrg(newObjectMap.values(), 'Sales_Org__c', 'add');
            }
            if(operation == 'update'){
                List<SObject> listToRemove = new List<SObject>();
                List<SObject> listToAdd = new List<SObject>();
                for(Id recId: newObjectMap.keyset()){
                    if(newObjectMap.get(recId).get('Sales_Org__c') != oldObjectMap.get(recId).get('Sales_Org__c')){
                        if(oldObjectMap.get(recId).get('Sales_Org__c') != null)
                        {
                            listToRemove.add(oldObjectMap.get(recId));
                        }
                        if(newObjectMap.get(recId).get('Sales_Org__c') != null){
                            listToAdd.add(newObjectMap.get(recId));
                        }
                    }
                }
                if(!listToRemove.isEmpty()){
                    PNR_SharingUtil.generateSharingFromSalesOrg(oldObjectMap.values(), 'Sales_Org__c', 'remove');
                }
                if(!listToAdd.isEmpty()){
                    PNR_SharingUtil.generateSharingFromSalesOrg(newObjectMap.values(), 'Sales_Org__c', 'add');
                }

            }
        }catch(Exception e){
            System.debug('Exception Caught in Before Update of PNR_CaseTriggerHandler in method:shareCasesWithoutAccount at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
        }
    }

}