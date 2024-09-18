/**
* @description GT_PostStoretoTraxBatchTest
* @history                                                            
                                                           
VERSION     AUTHOR                  DATE              DETAIL
1.0         Joshraj Sen          08/06/2023           GT-140 Test Class for coverage of the GT_PostStoretoTraxBatch
*/
@isTest
public class GT_PostStoretoTraxBatchTest
{
    @isTest
    public static void testPostStoreToTraxBatch(){
        Database.executeBatch(new GT_PostStoretoTraxBatch(),200) ;
        System.assert(UserInfo.getUserId()!=null,'Active User');
        GT_BatchPostStoreToTraxBatchScheduler schedular = new GT_BatchPostStoreToTraxBatchScheduler();
        String sch = '0 0 23 * * ?';
        System.schedule('Test Schedular for GT_PostToTrax', sch, schedular);
    }
    
       
   @testSetup
    static void setup(){
        Map<String,Id> geoMap=GT_PostStoretoTraxBatchTest.getGeoMap();
        List<Account> ownerOperator=new List<Account>();
        Account ownerAccount = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        ownerAccount.IsOwner__c=true;
        ownerOperator.add(ownerAccount);
        Account operatorAccount = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        operatorAccount.IsOperator__c=true; 
        ownerOperator.add(operatorAccount);
        insert ownerOperator;
        String countryID=geoMap.get('Country');
        List<Pick_Up_Options__c> pickupOptions=GT_PostStoretoTraxBatchTest.getPickUpOptions(countryID);
        List<Account> outlets=GT_PostStoretoTraxBatchTest.getAccounts(pickupOptions,geoMap,ownerOperator);
        System.debug(LoggingLevel.debug,outlets.size()+' No of Outlets');
        
    }
    static List<Account> getAccounts(List<Pick_Up_Options__c> pickupOptions,Map<String,Id> geoMap,List<Account> ownerOperators){
        List<Account> outlets=new List<Account>();
        Account outlet =EDGE_UtilityTestClass.getOutletRecord();
        outlet.Name='Tes outle classs';
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOptions[0].Id; 
        outlet.Local_Segment1__c=pickupOptions[1].Id;
        outlet.Local_Segment2__c=pickupOptions[2].Id;
        outlet.Status__c='Active';
        outlet.CurrencyIsoCode='GBP';
        outlet.Country__c = geoMap.get('Country');
        outlet.Hub__c = geoMap.get('Hub');
        outlet.Region__c=geoMap.get('Region');
        outlet.Area__c=geoMap.get('Area');
        outlet.Market__c = geoMap.get('Market');
        outlet.Cluster__c= geoMap.get('Cluster');
        outlet.ParentId=ownerOperators[0].Id;
        outlet.Operator__c=ownerOperators[1].Id;
        outlet.Last_Modify_Data_Master__c=System.today();
        outlet.Send_To_Trax__c=true;
        outlets.add(outlet);
        Account outlet2 =EDGE_UtilityTestClass.getOutletRecord();
        outlet2.Name='Tes outle classs2';
        outlet2.Country__c = geoMap.get('Country');
        outlet2.Hub__c = geoMap.get('Hub');
        outlet2.Region__c=geoMap.get('Region');
        outlet2.Area__c=geoMap.get('Area');
        outlet2.Market__c = geoMap.get('Market');
        outlet2.Cluster__c= geoMap.get('Cluster');
        outlet2.Local_Segment_Advanced_Analytics__c='Rurals';
        outlet2.Store_Size__c=pickupOptions[3].Id;
        outlet2.Last_Modify_Data_Master__c=System.today();
        outlet2.Send_To_Trax__c=true;
        outlets.add(outlet2);
        insert outlets;
        return outlets;
    }
    
    
    static List<Pick_Up_Options__c> getPickUpOptions(String countryId)
    {
        List<Pick_Up_Options__c> pickUpOptions=new List<Pick_Up_Options__c>();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickUpOptions.add(pickupOption);
        Pick_Up_Options__c localSegment1 =new Pick_Up_Options__c();
        localSegment1.Name='Europe';
        localSegment1.Type__c='Global Travel Local Segment 1';
        localSegment1.Status__c='Active';
        localSegment1.RecordTypeId=Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Local Segment').getRecordTypeId();
        pickUpOptions.add(localSegment1);
        Pick_Up_Options__c localSegment2 = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        localSegment2.Name='CMD';
        localSegment2.Type__c='Global Travel Local Segment 2';
        localSegment2.RecordTypeId=Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId();
        pickUpOptions.add(localSegment2);
        Pick_Up_Options__c storeSize = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        storeSize.Name='Big';
        storeSize.Type__c='Store Size';
        storeSize.RecordTypeId=Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sector').getRecordTypeId();
        pickUpOptions.add(storeSize);
        insert pickUpOptions;
        return pickUpOptions;
    }
    
    static Map<String,Id> getGeoMap()
    {
        Map<String,Id> geoMap=new Map<String,Id>();
        Geography__c globalRec = EDGE_UtilityTestClass.createGeography('Global');
        globalRec.Name = 'Global3';
        globalRec.Code__c = 'GL3';
        globalRec.RecordTypeId=EDGE_UtilityTestClass.GlobalRecTypeId;
        insert globalRec;
        geoMap.put('Global3',globalRec.Id);
        Geography__c market = EDGE_UtilityTestClass.createGeography('Market');
        market.Name = 'Europe and Turkey';
        market.Code__c = 'EU';
        market.Parent_Geography__c = globalRec.Id;
        market.RecordTypeId=EDGE_UtilityTestClass.marketRecTypeId;
        insert market;
        geoMap.put('Market',market.Id);
        Geography__c hub = EDGE_UtilityTestClass.createGeography('Hub');
        hub.Name = 'Global Travel';
        hub.Code__c = 'GTH';
        hub.Parent_Geography__c = market.Id;
        hub.RecordTypeId=EDGE_UtilityTestClass.HubRecTypeId;
        insert hub;
        geoMap.put('Hub',hub.Id);
        Geography__c cluster = EDGE_UtilityTestClass.createGeography('Cluster');
        cluster.Name = 'Great Britain';
        cluster.Code__c = 'GBC';
        cluster.Parent_Geography__c = hub.Id;
        cluster.RecordTypeId=EDGE_UtilityTestClass.ClusterRecTypeId;
        insert cluster;
        geoMap.put('Cluster',cluster.Id);
        Geography__c country = EDGE_UtilityTestClass.createGeography('Country');
        country.Name = 'Great Britain';
        country.Code__c ='GB';
        country.Parent_Geography__c = cluster.Id;
        country.RecordTypeId=EDGE_UtilityTestClass.CountryRecTypeId;
        insert country;
        geoMap.put('Country',country.Id);
        return geoMap;
    }
}