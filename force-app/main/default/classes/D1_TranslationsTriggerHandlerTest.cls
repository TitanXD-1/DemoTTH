/*
@Name: D1_TranslationsTriggerHandlerTest
@History                                                            
VERSION     AUTHOR            DATE            DETAIL
1.0         Gaurav Singh      18/04/2022      Test Class for D1_TranslationsTriggerHandler
**/
@isTest
public class D1_TranslationsTriggerHandlerTest {
	@isTest
    public static void testValidatePreferredLanguage(){
        Test.startTest();
        User testAdminUser = D1_TestDataUtility.runAsUser('testAdmin','System Administrator'); 
        testAdminUser.Email = 'abc@diageo.com';
        insert testAdminUser;
        
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = True;
        orgSetting.Run_Validation_Rules__c = false;
        insert orgSetting;
        

        system.runAs(testAdminUser){
            D1_TestDataUtility.product2TestData();
            
            List<Product__c> products = [Select id, Name from Product__c];
            List<D1_Translations__c> translations = new List<D1_Translations__c>();
            for( Product__c prod : products ){
                D1_Translations__c translation = new D1_Translations__c(
                    Product__c = prod.Id,
                    Product_Name__c = prod.Name + ' - '+UserInfo.getLanguage(),
                    Language__c = UserInfo.getLanguage()
                );
                translations.add(translation);
            }
            insert translations;
            update translations;
            System.assert(translations != NULL, 'translation failed');
            
            List<D1_Translations__c> duplicateTranslations = new List<D1_Translations__c>();
            for( Product__c prod : products ){
                D1_Translations__c translation = new D1_Translations__c(
                    Product__c = prod.Id,
                    Product_Name__c = prod.Name + ' - '+UserInfo.getLanguage(),
                    Language__c = UserInfo.getLanguage()
                );
                duplicateTranslations.add(translation);
            }
            Test.stopTest();
            
            System.assert(duplicateTranslations != NULL, 'translation failed');
            Database.insert(duplicateTranslations, false);
            List<D1_Translations__c> deleteTransaltionList = [SELECT Id FROM D1_Translations__c ORDER BY createdDate DESC LIMIT 1];
            delete deleteTransaltionList;
            undelete deleteTransaltionList;
        }
    }
}