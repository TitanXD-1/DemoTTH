/**********************************************************************
Name: MarketAssortMentProductTriggerHandlerTest

=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR           DATE            DETAIL
1.0         Saurav Paul		 16/04/2019		 Test Class for MarketAssortmentProductTriggerHandler
***********************************************************************/

@isTest
public class MarketAssortMentProductTriggerTest{
    
    @isTest
    public static void testOpportunity(){ 
        Boolean guidNotNull = false;
        EDGE_UtilityTestClass.createOrgSettings(); 
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUS');
        
        Product__c prod = EDGE_UtilityTestClass.getProd();
        insert prod;
        Market_Assortment_Product__c map1 = new 	Market_Assortment_Product__c();
        map1.Market_Assortment__c= countryId;
        test.startTest();
        
        insert map1;
        Market_Assortment_Product__c map2 = [SELECT Id,GUID__c FROM Market_Assortment_Product__c WHERE ID =: map1.Id];
        if(map2.GUID__c != Null){
            guidNotNull = true;
        }
        system.assert(guidNotNull, TRUE);
        map1.Product__c= prod.id;
        //update market assortment 
        update map1;
        //delete market assortment 
        delete map1;
        //undelete market assortment 
        undelete map1;
        test.stopTest();
        
    }
}