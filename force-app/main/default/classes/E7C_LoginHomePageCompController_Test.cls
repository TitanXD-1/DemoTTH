@isTest
public class E7C_LoginHomePageCompController_Test {

    @isTest static void testMethod1(){
        E7C_Survey_Response__c srRec = new E7C_Survey_Response__c();
        srRec.E7C_Survey_Response_Date__c = system.today().addDays(-5);
        srRec.E7C_Status__c = 'Submitted';
        srRec.OwnerId = UserInfo.getUserId();
        insert srRec;
        
        E7C_LoginHomePageCompController.getLastCompletedSurvey();
    }
}