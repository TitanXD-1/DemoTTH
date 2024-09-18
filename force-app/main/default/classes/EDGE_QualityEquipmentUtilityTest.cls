/*Req: The is the test class for D1_QualityEquipmentUtility
User Story : ES20-13610,ES20-13612,ES20-13611
History                                                            
                                                            
VERSION   AUTHOR                  DATE              DETAIL
1.0     Joshraj,Rajarshi,Swaraj  06/12/2022        ES20-13610,ES20-13612,ES20-13611
*/
@isTest
public class EDGE_QualityEquipmentUtilityTest {

    
    @isTest
    public static void testgetMasterBundlebyCountry(){
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('GB');
        Master_Bundle__c masterBundle = new Master_Bundle__c();
        masterBundle.Name='Test Master Bundle';
        masterBundle.Description__c='Test description';
        masterBundle.Country__c=countryId;
        masterBundle.Active__c=TRUE;
        insert masterBundle;
        System.assert(masterBundle.Id!=null,'Master Bundle Inserted');
        EDGE_QualityEquipmentUtility.getMasterBundlebyCountry('GB');
    }
    
    @isTest
    public static void testgetAssetbyBundle(){
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('GB');
        String qualityAssetRecordTypeId = Asset.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();        
        outlet.BillingStreet = '17 Asian Highway 45';
        outlet.BillingCity = 'Tasmania';
        outlet.BillingCountry = 'Australia';
        outlet.BillingState = 'Tasmania';
        outlet.BillingPostalCode = '5668';
        outlet.BillingCountryCode = 'AU';
        insert  outlet;
        Master_Bundle__c mb=new Master_Bundle__c();
        mb.Country__c=countryId;
        mb.Name='Master Bundle';
        mb.Active__c=true;
        mb.Description__c='This is a Master Bundle';
        mb.Fault_Fixer__c='Test Fault Fixer';
        insert mb;
        Bundle__c bundle1=new Bundle__c();
        bundle1.Name='Bundle 1';
        bundle1.Account__c=outlet.Id;
        bundle1.Master_Bundle__c=mb.Id;
        bundle1.Bundle_Location__c='Bar';
        bundle1.Description__c='This is the 1st Bundle';
        insert bundle1;
        Master_Asset__c masterAsst = new Master_Asset__C();
        masterAsst.Name = 'Test';
        masterAsst.GUID__c = 'TWRFSHJAKSVGG';
        masterAsst.Short_Description__c = 'test';
        masterAsst.Country__c = countryId;
        masterAsst.Priority_Assets__c = true;
        masterAsst.Line_Cleaning_Asset__c = true;
        masterAsst.Active__c = true;
        insert masterAsst;
        Asset asst = new Asset();
        asst.Name = 'Test_Asset';
        asst.GUID__c = 'TWRFSHJAKAFF';
        asst.AccountId = outlet.Id;
        asst.Country__c = countryId;
        asst.Quantity = 2;
        asst.Master_Asset__c = masterAsst.Id;
        asst.InstallDate = null;
        asst.Offset_Day__c = 2;
        asst.Batch_Processed__c = true;
        asst.Asset_Removed__c = false;
        asst.Is_OffsetDay_Changed__c = false;
        asst.RecordTypeId = qualityAssetRecordTypeId;
        asst.Bundle__c=bundle1.Id;
        Insert asst;
        System.assert(asst.Id!=null,'Asset Inserted');
        EDGE_QualityEquipmentUtility.getAssetbyBundle(bundle1.Id);
       
    }
    
     @isTest
    public static void testdoGetBundlesForOutlet(){
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUS');
        System.assert(countryId!=null,'Country Inserted');
        //String qualityAssetRecordTypeId = Asset.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();        
        outlet.BillingStreet = '17 Asian Highway 45';
        outlet.BillingCity = 'Tasmania';
        outlet.BillingCountry = 'Australia';
        outlet.BillingState = 'Tasmania';
        outlet.BillingPostalCode = '5668';
        outlet.BillingCountryCode = 'AU';
        insert  outlet;
        Master_Bundle__c mb=new Master_Bundle__c();
        mb.Country__c=countryId;
        mb.Name='Master Bundle';
        mb.Active__c=true;
        mb.Description__c='This is a Master Bundle';
        mb.Fault_Fixer__c='Test Fault Fixer';
        insert mb;
        List<Bundle__c> bundles=new List<Bundle__c>();
        Bundle__c bundle1=new Bundle__c();
        bundle1.Name='Bundle 1';
        bundle1.Account__c=outlet.Id;
        bundle1.Master_Bundle__c=mb.Id;
        bundle1.Bundle_Location__c='Bar';
        bundle1.Description__c='This is the 1st Bundle';
        bundles.add(bundle1);
        Bundle__c bundle2=new Bundle__c();
        bundle2.Name='Bundle 2';
        bundle2.Account__c=outlet.Id;
        bundle2.Master_Bundle__c=mb.Id;
        bundle2.Bundle_Location__c='Cellar';
        bundle2.Description__c='This is the 2nd Bundle';
        bundles.add(bundle2);
        insert bundles;
        List<EDGE_OutletBundleWrapper> outletBundleWrapper = EDGE_QualityEquipmentUtility.doGetBundlesForOutlet(outlet.Id);
        Assert.isTrue(outletBundleWrapper.size()>0,'Wrapper Generated');
    }
    
}