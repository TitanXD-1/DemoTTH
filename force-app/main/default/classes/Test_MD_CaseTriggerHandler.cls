@isTest
public class Test_MD_CaseTriggerHandler {

    @isTest
    public static void test(){
        List<SObject> triggerRecords = new List<SObject>();
        MD_CaseTriggerHandler handler = new MD_CaseTriggerHandler(triggerRecords,triggerRecords);
    }
}