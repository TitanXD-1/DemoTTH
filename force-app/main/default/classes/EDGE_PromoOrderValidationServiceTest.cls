/**
* @description EDGE_PromoOrderValidationServiceTest
* @purpose This is the test class for EDGE_PromoOrderValidationService
* @history
* Version  Developer              Date               Purpose
* 1.0      Swaraj Samanta       18/07/2022      Initial Development
* 2.0      Joshraj Sen          08/04/2024      152305 SCA Fix
*/

@isTest
public class EDGE_PromoOrderValidationServiceTest {
    private static String userId = '';
    private static String outletId = '';
    private static List<Id> promoIds = new List<Id>();
    private static Map<Id,Boolean> expectedResult = new Map<Id,Boolean>();
    
    @isTest
    public static void validatePromoOrdersTest(){
        //Setup User 
        User userDetails  = EDGE_UtilityTestClass.runAsUser('SalesRep','Sales Representative');
        insert userDetails;
        userId = userDetails.id;
        
     	Test.startTest();
        //Data Preparation
        createDataForPromotionOrder(userDetails);
        //Request Preparation
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        String requri='services/apexrest/PromoOrderValidationService';
        String reqBody = '{'+
                              '"User_Id" : "'+userId+'",'+
                              '"Outlet_Id" : "'+outletId+'",'+
             				  '"Promotion_List" : '+ '['+ '"'+promoIds.get(0)+'"' + ',' +'"'+promoIds.get(1)+'"' + ',' +'"'+promoIds.get(2)+'"' + ',' +'"'+promoIds.get(3)+'"' + ']'+
            '}';
        req.requestUri =requri;
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(reqBody);
        RestContext.request = req;
        RestContext.response = res;
        
        EDGE_PromoOrderValidationService.validatePromoOrders();
        //Output data
        EDGE_PromoOutletOutputWrapper outputData = (EDGE_PromoOutletOutputWrapper) JSON.deserialize(RestContext.response.responseBody.toString(),EDGE_PromoOutletOutputWrapper.class);
         system.debug(LoggingLevel.Debug,'Available_Promotion_List '+outputData.Available_Promotion_List);
        for (EDGE_PromoAvailabilityWrapper promo:outputData.Available_Promotion_List) {
            system.debug(LoggingLevel.Debug,'promo'+promo);
            system.assertEquals(expectedResult.get(promo.Promotion_Id), promo.Available_for_Ordering,'Match');
        }
        Test.stopTest();
    }
    
    public static void createDataForPromotionOrder(User userObj){  
        //Country Code Setup
        Id countryId = EDGE_UtilityTestClass.setupCountry('ES');
        
        //creation of custom Territory record
        Territory__c terr = new Territory__c();
        terr.Territory_Type__c = 'Service';
        terr.Primary_Sales_Rep__c = userId;
        terr.Country__c = countryId;
        terr.RecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Territory').getRecordTypeId();
        insert terr;

         //creation of custom Territory record
        Territory_Member__c terrMem = new Territory_Member__c();
        terrMem.Territory__c = terr.id;
        terrMem.User__c = userObj.id;
        terrMem.Start_Date__c = Date.today().addDays(-1) ;
        terrMem.Type__c = 'Primary';
        insert terrMem;

        //Outlet Setup
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.BillingStreet = 'Los Blancoas Cafe';
        outlet.BillingCity = 'Madrid';
        outlet.BillingCountry = 'Spain';
        outlet.BillingState = 'Madrid';
        outlet.BillingPostalCode = '5668';
        outlet.BillingCountryCode = 'ES';
        insert  outlet;
        outletId = outlet.id;
        
        //Outlet Member Setup
        Outlet_Member__c omTest = EDGE_UtilityTestClass.getOutletMemberRecord(outlet.Id, userObj.Id, 'Primary'); 
        insert omTest;
        
        //creation of OutletTerritory Record
        Outlet_Territory__c outletTerritory = new Outlet_Territory__c();
        outletTerritory.Territory__c = terr.id;
        outletTerritory.Outlet__c = outlet.id;
        insert outletTerritory; 
        
        ///Setup Of Promotion which is available for Outlet only within limit range
        String priceIncentiveId = Promotion_Master__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Price Incentive Order').getRecordTypeId();
        Promotion_Master__c promo1 = EDGE_UtilityTestClass.getPromotionMasterRec(priceIncentiveId);
        promo1.name = 'PROMO 1' ;
        insert promo1;
       
        
        //Creation Of Outlet Promotion 
        Outlet_Promotion__c outletPromo1 = EDGE_UtilityTestClass.getOutletPromotionRec(promo1.id, outlet.id, 8, 20);
        insert outletPromo1;
        
       ///Setup Of Promotion which is available for Territory and outlet
        String freeProductId = Promotion_Master__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Free Product').getRecordTypeId();
        Promotion_Master__c promo2 = EDGE_UtilityTestClass.getPromotionMasterRec(freeProductId);
        promo2.name = 'PROMO 2' ;
        insert promo2;
        
        //Creation Of Territory Promotion 
        Territory_Promotion__c terrPromo1 = EDGE_UtilityTestClass.getTerritoryPromotionRec(promo2.id, terr.id, 10, 20);
        insert terrPromo1;
         //Creation Of Outlet Promotion 
        Outlet_Promotion__c outletPromo = EDGE_UtilityTestClass.getOutletPromotionRec(promo2.id, outlet.id, 8, 20);
        insert outletPromo;
        
        
        
       ///Setup Of Promotion which is available for Territory & Outlet but exceeded the limit for outlet
        Promotion_Master__c promo3 = EDGE_UtilityTestClass.getPromotionMasterRec(freeProductId);
        promo3.name = 'PROMO 3' ;
        insert promo3;
        
        //Creation Of Outlet Promotion 
        Outlet_Promotion__c outletPromo2 = EDGE_UtilityTestClass.getOutletPromotionRec(promo3.id, outlet.id, 20, 20);
        insert outletPromo2;
        system.debug(LoggingLevel.Debug,'outletPromo2'+outletPromo2.id+''+outletPromo2.Promotion__c+''+outletPromo2.Promotion_Limit__c);
        system.debug(LoggingLevel.Debug,'outletPromo2'+outletPromo2.Outlet__c +''+outletPromo2.Status__c+''+outletPromo2.Promotion_Used__c);
        
        //Creation Of Territory Promotion 
        Territory_Promotion__c terrPromo2 = EDGE_UtilityTestClass.getTerritoryPromotionRec(promo3.id, terr.id, 10, 20);
        insert terrPromo2;
        
        ///Setup Of Promotion which is available for Territory But exceeded the limit
        Promotion_Master__c promo4 = EDGE_UtilityTestClass.getPromotionMasterRec(priceIncentiveId);
        promo4.name = 'PROMO 4' ;
        insert promo4;
        
        //Creation Of Territory Promotion 
        Territory_Promotion__c terrPromo3 = EDGE_UtilityTestClass.getTerritoryPromotionRec(promo4.id, terr.id, 20, 20);
        insert terrPromo3;
        
        //assigning promotion to class list variable and also expected result map variable
         promoIds.add(promo1.id);
         expectedResult.put(promo1.id, true);
         promoIds.add(promo2.id);
         expectedResult.put(promo2.id, true);
         promoIds.add(promo3.id);
         expectedResult.put(promo3.id, false);
         promoIds.add(promo4.id);
         expectedResult.put(promo4.id, false);

    }
 
    
}