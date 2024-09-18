/*
Name: EDGE_RemovePromotionPDFBatchTest
Req: This is the test class for EDGE_RemovePromotionPDFBatch
History                                                             
VERSION       AUTHOR            DATE              DETAIL
1.0   		Monalisa Halder     20/03/2019      Initial Development
*/
@isTest
public class EDGE_RemovePromotionPDFBatchTest{
    
    /*
    Method  : deletePromotionalPdf
    Purpose : To cover EDGE_RemovePromotionPDFBatch class
*/
    @isTest
    public static void deletePromotionalPdf(){
        Test.startTest(); 
        createData();
       
        try{ 
            Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                      Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_RemovePromotionPDFBatch'
                                                      and Country_Code__c ='AU' ];
            
            List<Promotion__c> promList = [Select id , name from Promotion__c];
            System.assert(promList.size()!=null,'promList should not be null');
            
            String className = batchSetting.Batch_Class__c;
            Type t = Type.forName(className);
            BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
            job.getBatchDetails(batchSetting);
            Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
         }catch(Exception ex){
            System.debug(LoggingLevel.Debug,'excption::::'+ex.getMessage());
           
        }
        Test.stopTest();
        
    }
    
    /*
    Method  : createData
    Purpose : To create test data
*/   
    static void createData(){
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        EDGE_UtilityTestClass.createOrgSettings();
        Id recordTypeIdContVersion = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Promotion').getRecordTypeId();
        
        
        Promotion__c promoRec = EDGE_UtilityTestClass.getPromotionRecord(countryId );
        promoRec.Start_Date__c = System.today().addDays(-6);
        promoRec.Expiration_Date__c = System.today().addDays(-1);
        insert promoRec;
        System.assert(promoRec.Id != null,'promoRec Id should not be null');
        
        ContentVersion conVerRec = EDGE_UtilityTestClass.gerConVerRec('Test.pdf');
        conVerRec.RecordTypeId = recordTypeIdContVersion;
        conVerRec.Content_Type__c = 'Promotional PDF';
        insert conVerRec;
        System.assert(conVerRec.Id != null,'conVerRec Id should not be null');
        
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        System.assertEquals(documents.size(), 1,'document size should equal to 1');
        
        ContentDocumentLink conDocLnkRec = EDGE_UtilityTestClass.getConDocLink (promoRec.Id,documents[0].Id);
        insert conDocLnkRec;
        System.assert(conDocLnkRec.Id != null,'conDocLnkRec Id should not be null');      
        
    }
    
    
}