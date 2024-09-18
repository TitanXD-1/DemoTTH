@isTest
public with sharing class CST_PublicGroup_AssignmentTest {
    @isTest
    public static void testBatch(){
        test.StartTest();
            CST_PublicGroup_Assignment batchClass = new CST_PublicGroup_Assignment(); 
            database.executebatch(batchClass);
        test.StopTest();
    }
}