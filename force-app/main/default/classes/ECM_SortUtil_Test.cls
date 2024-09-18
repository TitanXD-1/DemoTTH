/*
@Name: ECM_SortUtil_Test
@Description: This class is used to cover testclass for the  ECM_SortUtil
@History                                                            

*VERSION		AUTHOR					DATE				DETAIL
*1.0		Saurav Prasad			18/10/2023			126383  : [ECM-6905] Product Order on PDF Output 
*/
@isTest
public class ECM_SortUtil_Test {
    
    @isTest
    public static void testSortAscending(){ 
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        List<ECM_Contract_Type__c> listOfContractTypes = new List<ECM_Contract_Type__c>();
        for(Integer i=0;i<3;i++){
            //Contract Mandatory Records : Agreement Type
            ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
            contractType.Name='PromotionalAU - '+i;
            contractType.ECM_Volume_UoM_for_Beer__c = 'EU';
            contractType.ECM_Screen_3_field_configuration__c = 'Product Name;Brand;Category;Volume Target;Rate Per UoM;Investment;Product Growth Strategy';
            contractType.ECM_Expiration_Start_Date_Rule_in_Months__c=Decimal.valueOf(i).setScale(0);
            contractType.ECM_Automatic_approval_amount_threshold__c = 100.11+Decimal.valueOf(i).setScale(0);
            listOfContractTypes.add(contractType);
        }
        for(Integer i=6;i>0;i--){
            //Contract Mandatory Records : Agreement Type
            ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
            contractType.Name='PromotionalAU - '+i;
            contractType.ECM_Volume_UoM_for_Beer__c = 'EU';
            contractType.ECM_Screen_3_field_configuration__c = 'Product Name;Brand;Category;Volume Target;Rate Per UoM;Investment;Product Growth Strategy';
            contractType.ECM_Expiration_Start_Date_Rule_in_Months__c=Decimal.valueOf(i-2).setScale(0);
            contractType.ECM_Automatic_approval_amount_threshold__c = 100.11+Decimal.valueOf(i-10).setScale(0);
            listOfContractTypes.add(contractType);
        }
        for(Integer i=9;i>0;i--){
            //Contract Mandatory Records : Agreement Type
            ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
            contractType.Name='PromotionalAU - '+i;
            contractType.ECM_Volume_UoM_for_Beer__c = 'EU';
            contractType.ECM_Screen_3_field_configuration__c = 'Product Name;Brand;Category;Volume Target;Rate Per UoM;Investment;Product Growth Strategy';
            contractType.ECM_Expiration_Start_Date_Rule_in_Months__c=Decimal.valueOf(i).setScale(0);
            contractType.ECM_Automatic_approval_amount_threshold__c = 100.11+Decimal.valueOf(i).setScale(0);
            listOfContractTypes.add(contractType);
        }
        Insert listOfContractTypes;
        
        System.assert(listOfContractTypes[0].Id != null,'agreement type should not be null');
        
        ECM_SortUtil.SortOrderWrap wrapper = new ECM_SortUtil.SortOrderWrap();
        wrapper.records = listOfContractTypes;
        wrapper.fieldName = 'Name';
        ECM_SortUtil.sortRecords(wrapper, ECM_SortUtil.SortOrder.ASCENDING, ECM_SortUtil.Type.TYPE_STRING);
        wrapper.fieldName = 'ECM_Expiration_Start_Date_Rule_in_Months__c';
        ECM_SortUtil.sortRecords(wrapper, ECM_SortUtil.SortOrder.ASCENDING, ECM_SortUtil.Type.TYPE_INTEGER);
        wrapper.fieldName = 'ECM_Automatic_approval_amount_threshold__c';
        ECM_SortUtil.sortRecords(wrapper, ECM_SortUtil.SortOrder.ASCENDING, ECM_SortUtil.Type.TYPE_DECIMAL);
        
        
    }
    
    @isTest
    public static void testSortDescending(){ 
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        List<ECM_Contract_Type__c> listOfContractTypes = new List<ECM_Contract_Type__c>();
        for(Integer i=0;i<3;i++){
            //Contract Mandatory Records : Agreement Type
            ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
            contractType.Name='PromotionalAU - '+i;
            contractType.ECM_Volume_UoM_for_Beer__c = 'EU';
            contractType.ECM_Screen_3_field_configuration__c = 'Product Name;Brand;Category;Volume Target;Rate Per UoM;Investment;Product Growth Strategy';
            contractType.ECM_Expiration_Start_Date_Rule_in_Months__c=Decimal.valueOf(i+2).setScale(0);
            contractType.ECM_Automatic_approval_amount_threshold__c = 100.11+Decimal.valueOf(i+10).setScale(0);
            listOfContractTypes.add(contractType);
        }
        for(Integer i=6;i>0;i--){
            //Contract Mandatory Records : Agreement Type
            ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
            contractType.Name='PromotionalAU - '+i;
            contractType.ECM_Volume_UoM_for_Beer__c = 'EU';
            contractType.ECM_Screen_3_field_configuration__c = 'Product Name;Brand;Category;Volume Target;Rate Per UoM;Investment;Product Growth Strategy';
            contractType.ECM_Expiration_Start_Date_Rule_in_Months__c=Decimal.valueOf(i).setScale(0);
            contractType.ECM_Automatic_approval_amount_threshold__c = 100.11+Decimal.valueOf(i).setScale(0);
            listOfContractTypes.add(contractType);
        }
        for(Integer i=0;i>9;i--){
            //Contract Mandatory Records : Agreement Type
            ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
            contractType.Name='PromotionalAU - '+i;
            contractType.ECM_Volume_UoM_for_Beer__c = 'EU';
            contractType.ECM_Screen_3_field_configuration__c = 'Product Name;Brand;Category;Volume Target;Rate Per UoM;Investment;Product Growth Strategy';
            contractType.ECM_Expiration_Start_Date_Rule_in_Months__c=Decimal.valueOf(i).setScale(0);
            contractType.ECM_Automatic_approval_amount_threshold__c = 100.11+Decimal.valueOf(i+10).setScale(0);
            listOfContractTypes.add(contractType);
        }
        Insert listOfContractTypes;
        
        System.assert(listOfContractTypes[0].Id != null,'agreement type should not be null');
        
        ECM_SortUtil.SortOrderWrap wrapper = new ECM_SortUtil.SortOrderWrap();
        wrapper.records = listOfContractTypes;
        wrapper.fieldName = 'Name';
        ECM_SortUtil.sortRecords(wrapper, ECM_SortUtil.SortOrder.DESCENDING, ECM_SortUtil.Type.TYPE_STRING);
        wrapper.fieldName = 'ECM_Expiration_Start_Date_Rule_in_Months__c';
        ECM_SortUtil.sortRecords(wrapper, ECM_SortUtil.SortOrder.DESCENDING, ECM_SortUtil.Type.TYPE_INTEGER);
        wrapper.fieldName = 'ECM_Automatic_approval_amount_threshold__c';
        ECM_SortUtil.sortRecords(wrapper, ECM_SortUtil.SortOrder.DESCENDING, ECM_SortUtil.Type.TYPE_DECIMAL);
        
    }
    
    @isTest
    public static void testSortNegative(){ 
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        List<ECM_Contract_Type__c> listOfContractTypes = new List<ECM_Contract_Type__c>();
        for(Integer i=0;i<3;i++){
            //Contract Mandatory Records : Agreement Type
            ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
            contractType.Name='PromotionalAU - '+i;
            contractType.ECM_Volume_UoM_for_Beer__c = 'EU';
            contractType.ECM_Screen_3_field_configuration__c = 'Product Name;Brand;Category;Volume Target;Rate Per UoM;Investment;Product Growth Strategy';
            contractType.ECM_Expiration_Start_Date_Rule_in_Months__c=Decimal.valueOf(i).setScale(0);
            contractType.ECM_Automatic_approval_amount_threshold__c = 100.11+Decimal.valueOf(i).setScale(0);
            listOfContractTypes.add(contractType);
        }
        for(Integer i=5;i>0;i--){
            //Contract Mandatory Records : Agreement Type
            ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
            contractType.Name='PromotionalAU - '+i;
            contractType.ECM_Volume_UoM_for_Beer__c = 'EU';
            contractType.ECM_Screen_3_field_configuration__c = 'Product Name;Brand;Category;Volume Target;Rate Per UoM;Investment;Product Growth Strategy';
            contractType.ECM_Expiration_Start_Date_Rule_in_Months__c=Decimal.valueOf(i).setScale(0);
            contractType.ECM_Automatic_approval_amount_threshold__c = 100.11+Decimal.valueOf(i).setScale(0);
            listOfContractTypes.add(contractType);
        }
        for(Integer i=9;i>0;i--){
            //Contract Mandatory Records : Agreement Type
            ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
            contractType.Name='PromotionalAU - '+i;
            contractType.ECM_Volume_UoM_for_Beer__c = 'EU';
            contractType.ECM_Screen_3_field_configuration__c = 'Product Name;Brand;Category;Volume Target;Rate Per UoM;Investment;Product Growth Strategy';
            contractType.ECM_Expiration_Start_Date_Rule_in_Months__c=Decimal.valueOf(i).setScale(0);
            contractType.ECM_Automatic_approval_amount_threshold__c = 100.11+Decimal.valueOf(i).setScale(0);
            listOfContractTypes.add(contractType);
        }
        Insert listOfContractTypes;
        
        System.assert(listOfContractTypes[0].Id != null,'agreement type should not be null');
        
        ECM_SortUtil.SortOrderWrap wrapper = new ECM_SortUtil.SortOrderWrap();
        wrapper.records = listOfContractTypes;
        wrapper.fieldName = 'ECM_Automatic_approval_amount_threshold__c';
        ECM_SortUtil.sortRecords(wrapper, ECM_SortUtil.SortOrder.DESCENDING, ECM_SortUtil.Type.TYPE_DECIMAL);
        ECM_SortUtil.sortRecords(wrapper, ECM_SortUtil.SortOrder.ASCENDING, ECM_SortUtil.Type.TYPE_INVALID);
        
    }
    
    
}