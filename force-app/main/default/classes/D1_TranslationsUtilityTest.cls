/**
 * @name D1_TranslationsUtilityTest
 * @description Test Class for D1_TranslationsUtility
 * @history
 * VERSION          AUTHOR                      DATE                DETAIL
 * 1.0              Gaurav Singh                11/03/2022          Initial Development
 */
@isTest
public class D1_TranslationsUtilityTest {
	@isTest
    public static void testUpdateTranslationsInRecords(){
        User testAdminUser = D1_TestDataUtility.runAsUser('testAdmin','System Administrator'); 
        testAdminUser.Email = 'abc@diageo.com';
        insert testAdminUser;
        
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
            List<sObject> obj = new List<sObject>();
            Test.startTest();
        	obj = D1_TranslationsUtility.updateTranslationsInRecords(products);
            Test.stopTest();
            System.assert(obj != NULL, 'no object to translate');
        }
    }
}