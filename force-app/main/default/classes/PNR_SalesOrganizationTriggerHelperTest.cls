/*
 * Class Name : PNR_SalesOrganizationTriggerHelperTest
 * @description: This is Pioneer Sales Organization Trigger Helper Test
 * @history
 * VERSION    AUTHOR                DATE              DETAIL
 * 1.0      Jayashree R 		12/01/2022       Initial Development
*/
@isTest
public class PNR_SalesOrganizationTriggerHelperTest {
    
	/*
	* @description : checkGenerateSharingTest
	* @return : void
	* @param : 
	*/

    @isTest
    public static void checkGenerateSharingTest(){
         //Creating Org setting
        EDGE_UtilityTestClass.createOrgSettings();
        Test.startTest();
        Id countryId = EDGE_UtilityTestClass.setupCountry('SEU');
         //Creating sales organisation Record
        Sales_Organisation__c regGroup = EDGE_UtilityTestClass.getsalesorgRecord(countryId);
        regGroup.RecordTypeId = Schema.sObjectType.Sales_Organisation__c.getRecordTypeInfosByDeveloperName().get('Regional_Group').getRecordTypeId();
        insert regGroup;
        system.assert(regGroup.Id != null);
        Test.stopTest();
    }

    @isTest
    public static void testShareSalesOrgs(){
        EDGE_UtilityTestClass.createOrgSettings();
        
        Id countryId = EDGE_UtilityTestClass.setupCountrySpain('ESP');
        list<Group> gpList            = new list<Group>();
        
         //Creating sales organisation Record
        Sales_Organisation__c regGroup = EDGE_UtilityTestClass.getsalesorgRecord(countryId);
        regGroup.RecordTypeId = Schema.sObjectType.Sales_Organisation__c.getRecordTypeInfosByDeveloperName().get('Regional_Group').getRecordTypeId();
        insert regGroup;
        Sales_Organisation__c regGroup2 = new Sales_Organisation__c();
        regGroup2.RecordTypeId = Schema.sObjectType.Sales_Organisation__c.getRecordTypeInfosByDeveloperName().get('Regional_Group').getRecordTypeId();
        regGroup2.Name = 'Europe';
        regGroup2.Description__c = 'Europe';
        insert regGroup2;
        
         //Creating sales organisation Record
        List<Sales_Organisation__c> soList = new List<Sales_Organisation__c>();
        Sales_Organisation__c so = EDGE_UtilityTestClass.getsalesorgRecord(countryId);
        so.RecordTypeId = Schema.sObjectType.Sales_Organisation__c.getRecordTypeInfosByDeveloperName().get('SalesOrg').getRecordTypeId();
        so.PNR_Regional_Group__c = regGroup.Id;
        so.Code__c = 'AU01';
        soList.add(so);
        Sales_Organisation__c so2 = EDGE_UtilityTestClass.getsalesorgRecord(countryId);
        so2.RecordTypeId = Schema.sObjectType.Sales_Organisation__c.getRecordTypeInfosByDeveloperName().get('SalesOrg').getRecordTypeId();
        so2.PNR_Regional_Group__c = regGroup.Id;
        so2.Code__c = 'NZ01';
       // soList.add(so2);
        insert soList;
        so.PNR_Regional_Group__c = regGroup2.Id;
        update so;
        Test.startTest();
        Case caseRec = new Case();
        caseRec = PNR_TestDataUtility.getDirectDisputesCase(null);
        caseRec.Sales_Org__c = so.Code__c;
        insert caseRec;
        caseRec.Sales_Org__c = so2.Code__c;
        update caseRec;

        
        delete so;
        undelete so;

        Test.stopTest();
    }
    
    @isTest
    public static void testAddUserToPublicGroup(){
        EDGE_UtilityTestClass.createOrgSettings();
       
        Id countryId = EDGE_UtilityTestClass.setupCountrySpain('ESP');
        
        List<Sales_Organisation__c> regGrpList = new List<Sales_Organisation__c>();
        Sales_Organisation__c regGroup1 = new Sales_Organisation__c();
        regGroup1.RecordTypeId = Schema.sObjectType.Sales_Organisation__c.getRecordTypeInfosByDeveloperName().get('Regional_Group').getRecordTypeId();
        regGroup1.Name = 'Europe';
        regGroup1.Description__c = 'Europe';
        regGrpList.add(regGroup1);
        
        Sales_Organisation__c regGroup2 = new Sales_Organisation__c();
        regGroup2.RecordTypeId = Schema.sObjectType.Sales_Organisation__c.getRecordTypeInfosByDeveloperName().get('Regional_Group').getRecordTypeId();
        regGroup2.Name = 'Africa';
        regGroup2.Description__c = 'Africa';
        regGrpList.add(regGroup2);
        insert regGrpList;

        List<Sales_Organisation__c> soList = new List<Sales_Organisation__c>();
        Sales_Organisation__c so = new Sales_Organisation__c();
        so.RecordTypeId = Schema.sObjectType.Sales_Organisation__c.getRecordTypeInfosByDeveloperName().get('SalesOrg').getRecordTypeId();
        so.Name = 'Namibia';
        so.Description__c = 'Namibia';
        so.Code__c = 'NB01';
        so.PNR_Regional_Group__c = regGroup2.Id;
        soList.add(so);
        Sales_Organisation__c so2 = new Sales_Organisation__c();
        so2.RecordTypeId = Schema.sObjectType.Sales_Organisation__c.getRecordTypeInfosByDeveloperName().get('SalesOrg').getRecordTypeId();
        so2.Name = 'Zambia';
        so2.Description__c = 'Zambia';
        so2.Code__c = 'ZB01';
        so2.PNR_Regional_Group__c = regGroup2.Id;
        soList.add(so2);
        
        insert so;
        
        user currentUser = [select id from user where id =: userinfo.getUserId()];
        system.runAs(currentUser){
          	user us = EDGE_UtilityTestClass.runAsUser('SampleUser','PNR_CustomerServiceRep');
        	us.Regional_Group__c = regGroup2.Name;
        	insert us;  
            us.Regional_Group__c = regGroup1.Name;
            update us;
        }
        Test.startTest();
        Id directRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDevelopername().get('PNR_Direct_Customer').getRecordTypeId();
        list<Geography__c> globalRecList = [select id from Geography__c where RecordTypeId=:EDGE_UtilityTestClass.GlobalRecTypeId];
        Geography__c globalRec;
        if(globalRecList.size()>0){
            globalRec = globalRecList[0];
        }
        else{
        globalRec = EDGE_UtilityTestClass.createGeography('Global');
        globalRec.Name = 'Global2';
        globalRec.Code__c = 'GL2';
        globalRec.RecordTypeId=EDGE_UtilityTestClass.GlobalRecTypeId;
        insert globalRec;
        }
        
        Geography__c market = EDGE_UtilityTestClass.createGeography('Market');
        market.Name = 'Latam-Car';
        market.Code__c = 'LATA';
        market.Parent_Geography__c = globalRec.Id;
        market.RecordTypeId=EDGE_UtilityTestClass.marketRecTypeId;
        insert market;
        Geography__c hub = EDGE_UtilityTestClass.createGeography('Hub');
        hub.Name = 'Colombia';
        hub.Code__c = 'COH';
        hub.Parent_Geography__c = market.Id;
        hub.RecordTypeId=EDGE_UtilityTestClass.HubRecTypeId;
        insert hub;
        
        Geography__c cluster = EDGE_UtilityTestClass.createGeography('Cluster');
        cluster.Name = 'Australia Cluster';
        cluster.Code__c = 'AUCT';
        cluster.Parent_Geography__c = hub.Id;
        cluster.RecordTypeId=EDGE_UtilityTestClass.ClusterRecTypeId;
        insert cluster;
        
        Geography__c country = EDGE_UtilityTestClass.createGeography('Country');
        country.Name = 'Colombia';
        country.Code__c = 'COE';
        country.Extended_Country_Code__c = 'CO-COT';
        country.Parent_Geography__c = cluster.Id;
        country.RecordTypeId=EDGE_UtilityTestClass.CountryRecTypeId;
        insert country;
        
        Account cust= PNR_TestDataUtility.getDirectCustomerRec();
        cust.Country__c=country.Id;
        cust.RecordTypeId = directRecTypeId;
        cust.Hub__c = hub.Id;
        cust.Cluster__c = cluster.Id;
        cust.Market__c = market.Id;
        cust.Sales_Org__c =so.Code__c;
        
        insert cust;
        cust.Sales_Org__c = so2.Code__c;
        update cust;
        Test.stopTest();
    }
    
  
}