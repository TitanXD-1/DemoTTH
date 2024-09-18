/*
Name: EDGE_SharingUtilTest
Req: This is the test class for EDGE_SharingUtil
History                                                                                                              
VERSION       AUTHOR            DATE              DETAIL
1.0         Preyanka Ghosh     17/05/2019      Initial Development
1.1         Aparajita          29/12/2021      ES20-11673(Method:testSharingForUsers)
1.2			Shivam Chauhan	 18/07/2023		142554 - EDGE static code violation for the classes_SFDC_Tech Debt
*/
@isTest
public class EDGE_SharingUtilTest {
    
    @isTest
    public static void assignGroupMemberTest(){
        EDGE_UtilityTestClass.createOrgSettings();
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        KPI_RAG_Threshold__c objKPIRAG = EDGE_UtilityTestClass.getOutletKPIRAG(countryId);
        insert objKPIRAG;
        System.assert(objKPIRAG != null,'objKPIRAG should not be null');
        List<KPI_RAG_Threshold__c> newItems = new List<KPI_RAG_Threshold__c>();
        List<Market_Assortment_Product__c> mapLIst = new List<Market_Assortment_Product__c>(); // added by Sagar        
		Product__c testProduct = EDGE_UtilityTestClass.getProd();
		insert testProduct;
        Market_Assortment_Product__c testMAP = new Market_Assortment_Product__c(Market_Assortment__c=countryId,Product__c=testProduct.Id);
        insert testMAP; 
        mapLIst.add(testMAP);
        
        newItems.add(objKPIRAG);
        Test.startTest();
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Country__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Down', 'Edit');
        EDGE_SharingUtil.updateSharingRecords(newItems, newItems, 'Country__c');
        EDGE_SharingUtil.validateEditPermission(newItems);
        EDGE_SharingUtil.insertProductSharing(mapLIst);
        EDGE_SharingUtil.deleteProductSharing(mapLIst);
        
        try{
            Exception exp;
            EDGE_GenericException genericexp;
            genericexp = new EDGE_GenericException(exp, newItems[0]); 
        } catch(Exception ex){
            System.debug(LoggingLevel.Debug,'excption::'+ex.getMessage());
            
        }
        
        Test.stopTest();
    }
    @isTest
    public static void testSharingForUsers(){
        
        
        //Assignment
        Map<Id,Set<Geography__c>> userGeoMapToInsert  = new Map<Id,Set<Geography__c>>();
        Map<Id,Set<Geography__c>> userGeoMapToDelete  = new Map<Id,Set<Geography__c>>();
        Set<Geography__c> geoSetToInsert = new Set<Geography__c>();
                Set<Geography__c> geoSetToDelete = new Set<Geography__c>();
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        User testSalesRepAU = EDGE_UtilityTestClass.runAsUser('SalesRep','Sales Representative');
        testSalesRepAU.Available_Countries__c = 'AU';
        insert testSalesRepAU;
        system.assert(testSalesRepAU.id!=null,'testSalesRepAU id should not be null');
        Test.startTest();
        //INSERT -> ES20-11673
        Geography__c geoAU = [SELECT Id, Code__c, Sharing_Group_Name__c FROM Geography__c WHERE Id =: countryId];
        geoSetToInsert.add(geoAU);
        userGeoMapToInsert.put(testSalesRepAU.Id,geoSetToInsert);
        EDGE_SharingUtil.createAndDeleteSharingRecords(userGeoMapToInsert, 'Insert');
        
        //UPDATE -> ES20-11674/11675
        testSalesRepAU.Available_Countries__c = 'AU';
        testSalesRepAU.Available_Clusters__c = 'AUCT';
        update testSalesRepAU;
        geoSetToDelete.add(geoAU);
        userGeoMapToDelete.put(testSalesRepAU.id,geoSetToDelete);
        EDGE_SharingUtil.createAndDeleteSharingRecords(userGeoMapToDelete, 'Delete');
        Test.stopTest();
    }
}