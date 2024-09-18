/*
 * Class Name : EDGE_CSTApproverMatrixTriggerHelper
 * @description: Approval matrix trigger helper
 * @history
 * VERSION    AUTHOR                DATE              DETAIL
 * 1.0        CST Team  		19/05/2021        Initial Development
*/

public without sharing class EDGE_CSTApproverMatrixTriggerHelper {

	/*
	* @description : updateApproverUser
	* @return : void
	* @param : List<Approver_Matrix__c>
	*/    


     public static void updateApproverUser(List<Approver_Matrix__c> newItems)
     {        
         List<Approver_Matrix__c> listnew = (List<Approver_Matrix__c>) newItems;
         Set<String> appMatId = new Set<String>();
         Map<String, Id> appMatrixUserMap = new Map<String, Id>();
         if(!listnew.isEmpty()){
            for(Approver_Matrix__c appObj : listnew){
                appMatId.add(appObj.Approver_Email__c);                
            }
         }
         if(appMatId !=null){

             for(User usr : [SELECT Id, Email FROM User WHERE Email IN :appMatId]){

                 appMatrixUserMap.put(usr.Email, usr.Id);
             }
         }
         if(!listnew.isEmpty() && !appMatId.isEmpty()){
             for(Approver_Matrix__c appMatrixObj : listnew){
                 if(appMatrixUserMap.containsKey(appMatrixObj.Approver_Email__c)){
                 	String userId= appMatrixUserMap.get(appMatrixObj.Approver_Email__c);
             	 	appMatrixObj.Approver_User__c = userId;
         		}
         	}
      	}
     }    
	/*
	* @description : checkAndGenerateSharingfromSalesOrg
	* @return : void
	* @param : List<Approver_Matrix__c>
	*/
    public static void checkAndGenerateSharingfromSalesOrg(List<Approver_Matrix__c> newItems){
        List<Approver_Matrix__c> lstNewChangeAppMatrix = new List<Approver_Matrix__c>();
        
        for(Approver_Matrix__c  appMatrixObj : newItems){
            //PION:2209 - commenting the if condition to share the pioneer approver matrix records
            //if(appMatrixObj.Approval_Category__c.equals('Customer Spend approval')) 
                lstNewChangeAppMatrix.add(appMatrixObj);
        }
    	if(lstNewChangeAppMatrix != null && lstNewChangeAppMatrix.size()>0){
        	CST_SharingUtil.validateCreatePermission(lstNewChangeAppMatrix, 'CST_Sales_Organisation__c');
        	CST_SharingUtil.generateSharingFromSalesOrg(lstNewChangeAppMatrix, 'CST_Sales_Organisation__c', 'Read');
        	CST_SharingUtil.generateSharingFromSalesOrg(lstNewChangeAppMatrix, 'CST_Sales_Organisation__c', 'Edit'); 
        }
    }
    
    /*
	* @description : validateAndReGenerateSharingfromSalesOrg
	* @return : void
	* @param : List<Approver_Matrix__c>,Map<Id, SObject>
	*/
    public static void validateAndReGenerateSharingfromSalesOrg(List<Approver_Matrix__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Approver_Matrix__c > mapOldItems;
        List<Approver_Matrix__c> lstNewChangeSalesOrg = new List<Approver_Matrix__c>();
        List<Approver_Matrix__c> lstOldChangeSalesOrg = new List<Approver_Matrix__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Approver_Matrix__c>)oldItems;
        }
        
        for(Approver_Matrix__c  objInternalOrderOption : newItems){
            //PION:2209 - modifying the if condition to share the pioneer approver matrix records
            //if(mapOldItems.containsKey(objInternalOrderOption.Id) && objInternalOrderOption.CST_Sales_Organisation__c != mapOldItems.get(objInternalOrderOption.Id).CST_Sales_Organisation__c && objInternalOrderOption.Approval_Category__c.equals('Customer Spend approval')){
            if(mapOldItems.containsKey(objInternalOrderOption.Id) && objInternalOrderOption.CST_Sales_Organisation__c != mapOldItems.get(objInternalOrderOption.Id).CST_Sales_Organisation__c){
                lstNewChangeSalesOrg.add(objInternalOrderOption);
                lstOldChangeSalesOrg.add(mapOldItems.get(objInternalOrderOption.Id));
            }
        }
        
        if(lstNewChangeSalesOrg != null && lstNewChangeSalesOrg.size()>0){
            CST_SharingUtil.validateCreatePermission(lstNewChangeSalesOrg, 'CST_Sales_Organisation__c');
            CST_SharingUtil.updateSharingRecords(lstNewChangeSalesOrg, lstOldChangeSalesOrg, 'CST_Sales_Organisation__c');
            CST_SharingUtil.generateSharingFromSalesOrg(lstNewChangeSalesOrg, 'CST_Sales_Organisation__c', 'Read');
            CST_SharingUtil.generateSharingFromSalesOrg(lstNewChangeSalesOrg, 'CST_Sales_Organisation__c', 'Edit');
        }       
    }    
}