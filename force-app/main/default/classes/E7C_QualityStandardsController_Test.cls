@isTest
public class E7C_QualityStandardsController_Test {
    @isTest static void testMethod1(){
        
        Test.startTest();
        
        E7C_QualityStandardsController.fetchQualityRecords('');
        E7C_QualityStandardsController.fetchQualityRecords('Ireland');
        
        E7C_Media__c mediaRec = new E7C_Media__c();
        mediaRec.Criteria__c = 'C1';
        mediaRec.E7C_Description__c = 'test media';
        mediaRec.E7C_Market__c = 'Ireland';
        mediaRec.E7C_Youtube_URL__c = 'www.testyoutubelink.com';
        
        insert mediaRec;
        
        E7C_QualityStandardsController.fetchQualityRecords('Ireland');
        
        Test.stopTest();
    }
}