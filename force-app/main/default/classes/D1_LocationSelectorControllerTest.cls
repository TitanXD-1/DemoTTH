/*
* @name: D1_LocationSelectorControllerTest
* @discription: D1_LocationSelectorController  Test Class
* @history
* VERSION     AUTHOR         DATE               DETAIL
* 1.0           -        		-                    -
* 2.0			Rubeena		   25/06/2021		  Test Class Refractor [NCP-3781]
*/

@isTest
public class D1_LocationSelectorControllerTest {
@isTest
    public static void getLocationWithLanguageTest(){
        
        Id countryId = D1_TestDataUtility.setupCountry('GB');
        Geography__c country = [select id,RecordTypeId,Flag_Content_Document_ID__c,Flag_Content_Version_Id__c from Geography__c where id=: countryId];
       
        D1_Setting__c diageoOneSett = D1_TestDataUtility.createD1Settings(country);
        insert diageoOneSett;
		List<D1_LocationSelectorController.LanguageWrapper> languageList = new List<D1_LocationSelectorController.languageWrapper>();
        languageList = D1_LocationSelectorController.getLocationWithLanguage();
        System.assert(languageList != NULL, 'Country not found');
    }
    
}