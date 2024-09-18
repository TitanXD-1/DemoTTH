/*
* @Name: EDGE_UserTerritoryKPIServiceTest


* @Req: This is the test class for the  EDGE_UserTerritoryKPIService class.
* @History

* @VERSION   AUTHOR            DATE              DETAIL
*  1.0       Anand U           18/02/2022        ES20-12140
*/

@isTest
public class EDGE_UserTerritoryKPIServiceTest {

  @isTest
    public static void testdoget(){
        
        User u  = EDGE_UtilityTestClass.runAsUser('SalesRep','Sales Representative');
        insert u;
        system.assert(u.Id != null,'u should not be null');
        Test.startTest();
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            String requri='services/apexrest/UserTerritoryKPIService?userid=';
            requri = requri+ String.valueOf(u.Id);
            req.requestUri =requri;
            req.params.put('userid', u.Id);            
            req.httpMethod = 'GET';
            RestContext.request = req;
            RestContext.response = res;
            EDGE_UserTerritoryKPIService.doGet();
            List<EDGE_UserTerritoryKPIWrapper> userTerritoryWrapper = EDGE_UserTerritoryKPIService.doGet();
          Map<String,Decimal> kpiMap=new Map<String,Decimal>();
            for(EDGE_UserTerritoryKPIWrapper utw : userTerritoryWrapper){
              kpiMap.put(utw.kpiName,utw.kpiValue);    
            }
            //System.assertequals(kpiMap.get('Outlet_Execution_Score__c'),0.00);//16-Feb
            //System.assertequals(kpiMap.get('Minimum_Activation_Standards__c'),0.00);//16-Feb
            //System.assertequals(kpiMap.get('Minimum_Product_Assortment__c'),0.00);
        Test.stopTest();     
    }
}