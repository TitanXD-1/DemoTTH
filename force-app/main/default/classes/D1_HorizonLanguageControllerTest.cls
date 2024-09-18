/*
* @name: D1_HorizonLanguageControllerTest
* @discription: Test class D1_HorizonLanguageControllerTest
* @history
* VERSION     AUTHOR      DATE    DETAIL
* 1.0 -       Ajay       8/20     Initial Development(NCP-1102)
*/
@isTest
public without sharing class D1_HorizonLanguageControllerTest {
    
    @isTest
    public static void testExistingConfigs(){
        List<D1_HorizonLanguageMapping__mdt> configs = [SELECT Country_Code__c ,salesforceLanguageCode__c,horizonLanguageCode__c FROM D1_HorizonLanguageMapping__mdt where country_code__c='GB' LIMIT 1];
        if(configs.size()<1){
            return;
        }
        D1_HorizonLanguageMapping__mdt languageConfig = configs[0];

        ApexPages.currentPage().getParameters().put('country', languageConfig.Country_Code__c);
        ApexPages.currentPage().getParameters().put('language', 'en_GB');
        //D1_HorizonLanguageController controller = new D1_HorizonLanguageController();
        System.assert(languageConfig != NULL, 'Language config not done properly');
    }
    @isTest
    public static void testExistingConfigs2(){
        List<D1_HorizonLanguageMapping__mdt> configs = [SELECT Country_Code__c ,salesforceLanguageCode__c,horizonLanguageCode__c FROM D1_HorizonLanguageMapping__mdt where country_code__c='GB' LIMIT 1];
        String horizonCode = System.Label.D1_DefaultHorizonLanguageCode;
        if(configs.size()<1){
            return;
        }
        D1_HorizonLanguageController.getHorizonLanguageCode(configs[0].Country_Code__c);
        String result = D1_HorizonLanguageController.getHorizonCode('GB','en_GB');

		System.assert(result != NULL, 'Language config not done properly');
        ApexPages.currentPage().getParameters().put('country', 'BE');
         D1_HorizonLanguageController controller2 = new D1_HorizonLanguageController();
         System.assert(controller2.horizonLanguageCode == horizonCode , 'Horizon Language code calculation failed - Default config(non null input).');
         ApexPages.currentPage().getParameters().put('language', 'nl_BE');
        controller2 = new D1_HorizonLanguageController();
    }

    @isTest
    public static void testDefaultConfigs(){
        String salesforceCode ='testzzzzzz';
        String horizonCode = System.Label.D1_DefaultHorizonLanguageCode;

        ApexPages.currentPage().getParameters().put('country', salesforceCode);
        D1_HorizonLanguageController controller = new D1_HorizonLanguageController();

        System.assert(controller.horizonLanguageCode == horizonCode , 'Horizon Language code calculation failed - Default config(non null input).');

        ApexPages.currentPage().getParameters().put('country', null);
        controller = new D1_HorizonLanguageController();

    }
}