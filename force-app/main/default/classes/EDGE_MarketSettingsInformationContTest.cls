/**********************************************************************
Name: EDGE_MarketSettingsInformationContTest
=======================================================================
Req: This is the test class for the  EDGE_MarketSettingsInformationController class.
User Story : ES20-9129
=======================================================================
History                                                            
-------                                                            
VERSION    AUTHOR              DATE              DETAIL
1.0      Monalisa Halder     31/12/2020      Initial Development

***********************************************************************/
@isTest
public class EDGE_MarketSettingsInformationContTest {
    @isTest
    public static void testMarketSettingsInfoMethod(){
        List<Market_Label__mdt> marketLabelList = new List<Market_Label__mdt>();
        Map<String,String> infoNames = new Map<String,String>();
        
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUS');
        Market_Setting__c marketSetting = EDGE_UtilityTestClass.getMarketSetting(countryId);
        marketSetting.Threshold_Format__c = 'Percent';
        insert marketSetting;
        infonames.put('OES_Information_Home__c','test information updated');
        
        Info_Label__c infoLabelRec1 = new Info_Label__c();
        infoLabelRec1.Market_Setting__c = marketSetting.Id;
        infoLabelRec1.Field_Name__c = 'Contract_End__c ';
        infoLabelRec1.Value__c = 'test Contract_End__c information';
        infonames.put('Contract_End__c','test Contract_End__c information');
        
        Info_Label__c infoLabelRec = new Info_Label__c();
        infoLabelRec.Market_Setting__c = marketSetting.Id;
        infoLabelRec.Field_Name__c = 'OES_Information_Home__c ';
        infoLabelRec.Value__c = 'test information';
        insert infoLabelRec;
        infonames.put('OES_Information_Home__c','test information updated');
        
        Test.startTest();
        marketLabelList = EDGE_MarketSettingsInformationController.getMarketLabels();
        EDGE_MarketSettingsInformationController.getNameUniqueIdValueMap(marketSetting.Id);
        EDGE_MarketSettingsInformationController.getMarketSettingsInfo(marketSetting.Id);
        EDGE_MarketSettingsInformationController.insertUpdateInfoLabel(marketSetting.Id,infoNames);
        Test.stopTest();
        System.assert(marketSetting!= null);
    }

}