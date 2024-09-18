@isTest
public with sharing class CST_PublicGroup_AssignmentSchedularTest {
    @isTest
    public static void testschedule() {
        Test.StartTest();
        CST_PublicGroup_AssignmentSchedular schedular = new CST_PublicGroup_AssignmentSchedular();
        String sch = '0 0 23 * * ?'; 
        system.schedule('Test Territory Check', sch, schedular); 
        Test.stopTest(); }
}