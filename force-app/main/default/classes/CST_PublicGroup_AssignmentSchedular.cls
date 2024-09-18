global with sharing class CST_PublicGroup_AssignmentSchedular implements Schedulable {
    global void execute(SchedulableContext sc) {
        CST_PublicGroup_Assignment batchClass = new CST_PublicGroup_Assignment(); 
        database.executebatch(batchClass);
    }
}