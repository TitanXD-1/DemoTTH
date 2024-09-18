/**

* @Description : UserTriggerHandler

* @Purpose : Trigger Handler Class for UserTrigger

* @History:

* @Version     Developer            Date            User Story	        

*    1.0      Sagar Barman    		12/02/2019        Initial Development
*	 1.1	  Monalisa Halder	    20/05/2021		  ES20-10013
*	 1.2	  Aparajita             15/06/2021        ES20-10310
*	 1.3	  Aparajita				27/12/2021		  ES20-11673
*	 1.4   	  Sukanya Chatterjee    28/12/2021	      ES20-11674
*    1.5      Sayan Mullick         15/11/2021	      CST Initial Development
*	 1.6	  Sai Kiran 			13/01/2022		  PION-1699
*	 1.7      Jagadeesh Yarra		07/04/2022		  CST-495
 */

public with sharing class UserTriggerHandler implements TriggerHandler{
    
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'UserTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        return triggerDisabled; 
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        D1_UserTriggerHelper.updateCurrency(newItems);
    }

    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_UserTriggerHelper.AddTraxUser(newItems,oldItems);
        EDGE_CSTClaimTriggerHelper.validateApproverUser(newItems,oldItems);
        
        
    }
    
    //Before Delete Trigger Handler   
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }   
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) { 
        System.enqueueJob(new D1_UserTriggerHelperQueueable(null,newItems,'After Insert','UpdateAccountCurrency')); 
        EDGE_UserTriggerHelper.distSalesRepMangerCreation(newItems.values(),null);	// ES20-10013

        EDGE_UserTriggerHelper.checkAndGenerateSharing(newItems.values()); // ES20-11673
        PNR_SharingUtil.addUserToPublicGroup(newItems,null);//PION-1699 
        EDGE_UserTriggerHelper.addUserToPublicGroup(newItems,null);//CST 
        Boolean batchCheck = System.isBatch();
        Boolean futureCheck = System.isFuture();
        if(!(batchCheck || futureCheck)){
        EDGE_UserTriggerHelper.addUserToCSTuserGroup(newItems.keySet());
        }
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        System.enqueueJob(new D1_UserTriggerHelperQueueable(oldItems,newItems,'After Update','AssignUserTerritory')); 
        EDGE_UserTriggerHelper.fetchInactiveDistSRSMFromAccount(newItems.values(),oldItems); //ES20-10310

        EDGE_UserTriggerHelper.validateAndReGenerateSharing(newItems.values(), oldItems); // ES20-11674
        PNR_SharingUtil.addUserToPublicGroup(newItems,oldItems);//PION-1699
        EDGE_UserTriggerHelper.addUserToPublicGroup(newItems,oldItems);//CST
        Boolean batchCheck = System.isBatch();
        Boolean futureCheck = System.isFuture();
        if(!(batchCheck || futureCheck)){
        EDGE_UserTriggerHelper.addUserToCSTuserGroup(newItems.keySet());
        }
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }  
    
    //After Undelete Trigger Handler    
    public void afterUndelete(Map<Id, SObject> oldItems) {
            
        
    }
}