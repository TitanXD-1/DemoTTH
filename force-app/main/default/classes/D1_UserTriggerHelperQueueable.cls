public class D1_UserTriggerHelperQueueable implements Queueable {
    Map<Id,sObject> oldItemsMap;
    Map<Id,sObject> newItemsMap;
    String triggerContext;
    string methodName;
    
    public D1_UserTriggerHelperQueueable(Map<Id,sObject> oldItemsMap, Map<Id,sObject> newItemsMap, 
                                            String triggerContext,string methodName){
        this.oldItemsMap = oldItemsMap;
        this.newItemsMap = newItemsMap;
        this.triggerContext = triggerContext;
        this.methodName = methodName;
    }

    public void execute(QueueableContext context) {
        if(triggerContext == 'After Insert'){
            if(methodName == 'UpdateAccountCurrency') {
                D1_UserTriggerHelper.updateAccountCurrency(newItemsMap);
                if(!Test.isRunningTest()) {
                    System.enqueueJob(new D1_UserTriggerHelperQueueable(null,newItemsMap,'After Insert','AssignTerritoryGroup')); 
                }
            }  else if(methodName == 'AssignTerritoryGroup') {
                EDGE_UserTriggerHelper.assignUserToTerritories(newItemsMap,null); 
                EDGE_UserTriggerHelper.assignUserToGroup(newItemsMap, null);
            }

        } 
        else if( triggerContext == 'After Update'){
             EDGE_UserTriggerHelper.updateCallPerDayInTerHierarchy(newItemsMap, oldItemsMap);
             EDGE_UserTriggerHelper.assignUserToTerritories(newItemsMap,oldItemsMap);  
             EDGE_UserTriggerHelper.assignUserToGroup(newItemsMap, oldItemsMap);
            
        }
    }
}