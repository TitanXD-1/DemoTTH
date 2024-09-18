global class CST_PublicGroup_Assignment implements Database.Batchable<sObject> {
    public String query;
    //Retriving the Users of the permission sets which are assigned day before the batch runs.
    global CST_PublicGroup_Assignment() {
        query = 'SELECT AssigneeId from PermissionSetAssignment WHERE isActive = true and Assignee.isActive = true and SystemModstamp=Yesterday'+(Test.isRunningTest()?' LIMIT 200':''); 
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
   
    global void execute(Database.BatchableContext BC, list<PermissionSetAssignment> scope) {
        Set<Id> userIdSet = new Set<Id>();
        for(PermissionSetAssignment permissionSetAss : scope){
            userIdSet.add(permissionSetAss.AssigneeId);
        }
        //Call our method in PNR_SharingUtil class to update the public group
        EDGE_UserTriggerHelper.addUserToCSTGroup(userIdSet);
    }

    global void finish(Database.BatchableContext BC) {

    }
}