/**
* @description C360_UnsubrcibeD1CasesonClosedBatch
* @history                                                            

VERSION     AUTHOR                  DATE              DETAIL
1.0			Joshraj Sen       		18/08/2023		  144407 This is class is to Unsubcribe Users in Bulk to closed D1 Cases
*/
@isTest
public class C360_UnsubscribeD1CaseOnClosedTest
{
    @isTest
    public static void testPostStoreToTraxBatch(){
        //Database.executeBatch(new GT_PostStoretoTraxBatch(),200) ;
        Market_Batch_Setting__mdt batchSetting = [Select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c 
                                                  from Market_Batch_Setting__mdt 
                                                  where Batch_Class__c = 'C360_UnsubrcibeD1CasesonClosedBatch'
                                                  and Country_Code__c ='IE'];
        system.assert(batchSetting.Id != null,'Batch Setting Inserted');
        String className = batchSetting.Batch_Class__c;         
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
    }
    
    
    @testSetup
    static void setup(){
        Map<String,Id> geoMap=C360_UnsubscribeD1CaseOnClosedTest.getGeoMap();
        List<Account> ownerOperator=new List<Account>();
        Account ownerAccount = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        ownerAccount.IsOwner__c=true;
        ownerOperator.add(ownerAccount);
        Account operatorAccount = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        operatorAccount.IsOperator__c=true; 
        ownerOperator.add(operatorAccount);
        insert ownerOperator;
        String countryID=geoMap.get('Country');
        List<Pick_Up_Options__c> pickupOptions=C360_UnsubscribeD1CaseOnClosedTest.getPickUpOptions(countryID);
        List<Account> outlets=C360_UnsubscribeD1CaseOnClosedTest.getAccounts(pickupOptions,geoMap,ownerOperator);
        String recordTypeId=Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Diageo One Cases').getRecordTypeId();
        Case cs=D1_TestDataUtility.createCase(recordTypeId, 'Issues with Site','Technical Issues','Test','Open');
        cs.AccountId=outlets[0].Id;
        cs.Origin='Diageo One';
        cs.Type_of_Communication__c='Phone Call';
        cs.Contacted_Date__c=System.now();
        cs.Status='Closed';
        insert cs;
        EntitySubscription es=new EntitySubscription(ParentId=cs.Id,SubscriberId=UserInfo.getUserId());
        insert es;
        
        
        
        
        
        //System.debug(LoggingLevel.debug,outlets.size()+' No of Outlets');
        
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
        hub.Name = 'Island of Ireland';
        hub.Code__c = 'IOIH';
        hub.Parent_Geography__c = market.Id;
        hub.RecordTypeId=EDGE_UtilityTestClass.HubRecTypeId;
        insert hub;
        geoMap.put('Hub',hub.Id);
        Geography__c cluster = EDGE_UtilityTestClass.createGeography('Cluster');
        cluster.Name = 'Ireland';
        cluster.Code__c = 'IOIC';
        cluster.Parent_Geography__c = hub.Id;
        cluster.RecordTypeId=EDGE_UtilityTestClass.ClusterRecTypeId;
        insert cluster;
        geoMap.put('Cluster',cluster.Id);
        Geography__c country = EDGE_UtilityTestClass.createGeography('Country');
        country.Name = 'Republic of Ireland';
        country.Code__c ='IE';
        country.Parent_Geography__c = cluster.Id;
        country.RecordTypeId=EDGE_UtilityTestClass.CountryRecTypeId;
        insert country;
        geoMap.put('Country',country.Id);
        return geoMap;
    }
}