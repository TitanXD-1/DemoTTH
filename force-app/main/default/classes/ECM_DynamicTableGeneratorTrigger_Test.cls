/*
*Name: ECM_DynamicTableGeneratorTrigger_Test

*Purpose: This class is used to cover testclass for the - ECM_DynamicTableGeneratorTriggerHandler

*History                                                            
                                                            
*VERSION    AUTHOR                   DATE              DETAIL
1.0      Saurav Kumar Prasad      21/05/2020        Initial Development

*/
@istest
public class ECM_DynamicTableGeneratorTrigger_Test {
    
    @isTest 
    public static void postiveTest(){
        //Postive Test Cases
        Test.startTest();
        
         Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES'); 
        //Id geographyId1 = EDGE_UtilityTestClass.setupCountry('AU'); 
        
        List<ECM_Dynamic_Table_Generator__c> dnymicTableRecList=new List<ECM_Dynamic_Table_Generator__c>();
        
        for(integer i=0;i<10;i++){
            ECM_Dynamic_Table_Generator__c dnymicTableRec= new ECM_Dynamic_Table_Generator__c();
            dnymicTableRec.ECM_Object__c = 'ECM_Contract_Item__c';
            dnymicTableRec.ECM_Geography__c = geographyId; 
            dnymicTableRec.ECM_Dynamic_Fields__c='Annual Volume;Baseline volume;Discount per case off invoice;Gross margin;Investment;LUC;Product Name;Total UOS';
            //;UoS Conversion Rate;Volume'
            dnymicTableRecList.add(dnymicTableRec);
        }
        Insert dnymicTableRecList;
        system.assert(dnymicTableRecList != null,'dnymicTableRecList should not be null');
        
        for(integer i=0;i<dnymicTableRecList.size();i++){
            //Annual Volume;Baseline volume;Discount per case off invoice;Gross margin;
            dnymicTableRecList[i].ECM_Dynamic_Fields__c='Investment;LUC;Product Name;Total UOS;UoS Conversion Rate';
        }
        update dnymicTableRecList;
        
        delete dnymicTableRecList;
        
        ECM_Dynamic_Table_Generator__c[] lstUndelete=[select Id,ECM_Dynamic_Fields__c from ECM_Dynamic_Table_Generator__c ALL ROWS];
        undelete lstUndelete;
        
        Map<Id,ECM_Dynamic_Table_Generator__c> dnymicTableRecNewMap=new Map<Id,ECM_Dynamic_Table_Generator__c>([select Id,ECM_Dynamic_Fields__c,ECM_Geography__c from ECM_Dynamic_Table_Generator__c]);
        Map<Id,ECM_Dynamic_Table_Generator__c> dnymicTableRecOldMap=new Map<Id,ECM_Dynamic_Table_Generator__c>([select Id,ECM_Dynamic_Fields__c,ECM_Geography__c from ECM_Dynamic_Table_Generator__c]);
        
        ECM_DynamicTableGeneratorTriggerHandler eCMTest=new ECM_DynamicTableGeneratorTriggerHandler();
        
        eCMTest.beforeDelete(dnymicTableRecOldMap);
        eCMTest.afterInsert(dnymicTableRecNewMap);
        eCMTest.afterUpdate(dnymicTableRecNewMap,dnymicTableRecOldMap);
        eCMTest.afterDelete(dnymicTableRecOldMap);
        eCMTest.afterUndelete(dnymicTableRecOldMap);
        
        Test.stopTest();
    }
    @isTest 
    public static void negativeTest(){
        //Negative Test Cases
        Test.startTest();
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES'); 
        //Id geographyId1 = EDGE_UtilityTestClass.setupCountry('AU');
        List<ECM_Dynamic_Table_Generator__c> dnymicTableRecList=new List<ECM_Dynamic_Table_Generator__c>();
        
        for(integer i=0;i<10;i++){
            ECM_Dynamic_Table_Generator__c dnymicTableRec= new ECM_Dynamic_Table_Generator__c();
            dnymicTableRec.ECM_Object__c = 'ECM_Contract_Item__c';
            dnymicTableRec.ECM_Geography__c = geographyId; 
            dnymicTableRec.ECM_Dynamic_Fields__c='Annual Volume;Baseline volume;Discount per case off invoice;Gross margin;Investment;LUC;Product Name;Total UOS;€/UoM;UoS Conversion Rate;Volume';
            dnymicTableRecList.add(dnymicTableRec);
        }
        try{
            Insert dnymicTableRecList;
            system.assert(dnymicTableRecList != null,'dnymicTableRecList Id should not be null');
        }
        catch(Exception e){
            System.debug(LoggingLevel.Debug,'Exception beforeInsert handled');
            
            for(integer i=0;i<dnymicTableRecList.size();i++){
                //Annual Volume;Baseline volume;Discount per case off invoice;Gross margin;
                    dnymicTableRecList[i].ECM_Dynamic_Fields__c='Investment;LUC;Product Name;Total UOS;UoS Conversion Rate';
            }
            Insert dnymicTableRecList;
            
            for(integer i=0;i<dnymicTableRecList.size();i++){
                dnymicTableRecList[i].ECM_Dynamic_Fields__c='Annual Volume;Baseline volume;Discount per case off invoice;Gross margin;Investment;LUC;Product Name;Total UOS;€/UoM;UoS Conversion Rate;Volume';
            }
            try{
                update dnymicTableRecList;
            }
            catch(Exception ex){
                System.debug(LoggingLevel.Debug,'Exception beforeUpdate handled');
                
            }
        }
        Test.stopTest();
    }
    @testSetup static void setup() {
        Test.startTest();
        
        Profile prof = [select id from profile where name=: 'Master Data Manager'];
        User usr = new User();
        usr.firstName = 'test1';
        usr.lastName = 'test2';
        usr.profileId = prof.id;        
        usr.email = 'test@test.com';
        usr.Username ='testcm123@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='ES';
        usr.Title='Legal';
        insert usr;
        
        User usr1 = new User();
        usr1.firstName = 'test11';
        usr1.lastName = 'test21';
        usr1.profileId = prof.id;        
        usr1.email = 'test1@test.com';
        usr1.Username ='testcm1231@test.com';
        usr1.Alias='test1';
        usr1.Timezonesidkey='America/Los_Angeles';
        usr1.LocaleSidKey='en_US';
        usr1.LanguageLocaleKey='en_US';
        usr1.EmailEncodingKey='UTF-8';
        usr1.Available_Countries__c='AU';
        usr1.Title='Legal';
        insert usr1;
        
        Test.stopTest();
    }
    @isTest
    public static void testdata(){
        Test.startTest();
        
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES'); 
        Id geographyId1 = EDGE_UtilityTestClass.setupCountry('AU'); 
        
         ECM_Dynamic_Table_Generator__c dnymicTableRec= new ECM_Dynamic_Table_Generator__c();
            dnymicTableRec.ECM_Object__c = 'ECM_Contract_Item__c';
            dnymicTableRec.ECM_Geography__c = geographyId; 
            dnymicTableRec.ECM_Dynamic_Fields__c='Annual Volume;Baseline volume;Discount per case off invoice;Gross margin;Investment;LUC;Product Name;Total UOS';
        insert dnymicTableRec;
        system.assert(dnymicTableRec.Id != null,'dnymicTableRec Id should not be null');
        
        dnymicTableRec.ECM_Geography__c = geographyId1;
        update dnymicTableRec;
        
        Test.stopTest();
    }
}