/**

* @description :  EDGE_MAPTriggerHelperTest

* @purpose : Trigger Helper Class for MarketAssortmentProductTrigger

* Version   Developer          Date          User Story	    Purpose

* 1.1       Preyanka Ghosh   20/05/2019      ES20-1615		Initial development
* 1.2       Aparajita        31/08/2021      ES20-10916		Cover populateProductNameMAP

*/

@isTest
public class EDGE_MAPTriggerHelperTest {
    
    /**

* @description : checkSharingTest - To check the sharing of object and cover populateProductNameMAP method

* @return : void

* @param : void

*/
    @isTest
    public static void checkSharingTest()
    {
        //Creating Org setting
        EDGE_UtilityTestClass.createOrgSettings();
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        Product__c product = EDGE_UtilityTestClass.getProd();
        insert product;
        
        //Creating Market Assortment Product Record
        Market_Assortment_Product__c mAssortProduct = new Market_Assortment_Product__c(isCompetitor__c = False, Market_Assortment__c = countryId);
        mAssortProduct.Product__c = product.Id;
        insert mAssortProduct;
        system.assert(mAssortProduct.Id != null);
        
        Test.startTest();
        
        List<Market_Assortment_Product__Share> mapsList = new List<Market_Assortment_Product__Share>();
        mapsList = [SELECT id, ParentId, UserOrGroupId,RowCause, AccessLevel from Market_Assortment_Product__Share where ParentId =: mAssortProduct.Id];
        
        Geography__c country = [SELECT Id, Code__c, Parent_Geography__c, isDiageoOneEnabled__c FROM Geography__c WHERE Id = :countryId];
        Geography__c secCountry = EDGE_UtilityTestClass.createGeography('Country');
        secCountry.Name = 'Australia Country1';
        secCountry.Code__c = 'AU1';
        secCountry.Parent_Geography__c = country.Parent_Geography__c;
        secCountry.isDiageoOneEnabled__c = false;
        insert secCountry;
        
        mAssortProduct.Market_Assortment__c = secCountry.Id;
        update mAssortProduct;        
        delete mAssortProduct;
        undelete mAssortProduct;
        Test.stopTest();
    }
}