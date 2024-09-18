/**********************************************************************
Name: EDGE_SharingUtilTest



***********************************************************************/
@isTest
public class CST_SharingUtilTest {
    
    @isTest
    public static void assignGroupMemberTest(){
        EDGE_UtilityTestClass.createOrgSettings();                
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        Pick_Up_Options__c pckOption = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
		insert pckOption;
		
        Sales_Organisation__c salesOrg = EDGE_UtilityTestClass.getsalesorgRecord(countryId);
        insert salesOrg;
		
        Test.startTest();
        Account accnt = EDGE_UtilityTestClass.getOutletRecord();
        accnt.Outlet_Visit_Prioritisation_Grade__c= pckOption.Id;
        accnt.Sales_Organisation__c= salesOrg.Id;
        insert accnt;
		
        System.assert(accnt != null);
        List<Account> newItems = new List<Account>();
        List<Account> newItems2 = new List<Account>();        
        newItems.add(accnt);
        //newItems2.add(accnt2);
        CST_SharingUtil.validateCreatePermission(newItems, 'Sales_Organisation__c');
        CST_SharingUtil.validateEditPermission(newItems);
        //CST_SharingUtil.generateSharingFromSalesOrg(newItems, 'Sales_Organisation__c', 'Read');
        //CST_SharingUtil.generateSharingFromSalesOrg(newItems, 'Sales_Organisation__c', 'Edit');         
        try{
            Exception exp;
            EDGE_GenericException genericexp = new EDGE_GenericException(exp, newItems[0]); 
        } catch(Exception ex){
            
        }
		Test.stopTest();
    }
	
	
	 @isTest
    public static void assignGroupMemberTest2(){
        EDGE_UtilityTestClass.createOrgSettings();                
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        Pick_Up_Options__c pckOption = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
		insert pckOption;
		
        Sales_Organisation__c salesOrg = EDGE_UtilityTestClass.getsalesorgRecord(countryId);
        insert salesOrg;
		
        Test.startTest();
        Account accnt = EDGE_UtilityTestClass.getOutletRecord();
        accnt.Outlet_Visit_Prioritisation_Grade__c= pckOption.Id;
        accnt.Sales_Organisation__c= salesOrg.Id;
        insert accnt;
		
        System.assert(accnt != null);
        List<Account> newItems = new List<Account>();
        List<Account> newItems2 = new List<Account>();        
        newItems.add(accnt);
        //newItems2.add(accnt2);
        //CST_SharingUtil.validateCreatePermission(newItems, 'Sales_Organisation__c');
        //CST_SharingUtil.validateEditPermission(newItems);
       CST_SharingUtil.generateSharingFromSalesOrg(newItems, 'Sales_Organisation__c', 'Read');
        //CST_SharingUtil.generateSharingFromSalesOrg(newItems, 'Sales_Organisation__c', 'Edit');
        
        Sales_Organisation__c salesOrg2 = EDGE_UtilityTestClass.getsalesorgRecord(countryId);
        salesOrg2.Code__c='BE01';
        insert salesOrg2;
        accnt.Outlet_Visit_Prioritisation_Grade__c= pckOption.Id;
        accnt.Sales_Organisation__c= salesOrg2.Id;
        update accnt;
        
        newItems2.add(accnt);
        CST_SharingUtil.deleteSharingRecords(newItems, newItems2,'Sales_Organisation__c');

        try{
            Exception exp;
            EDGE_GenericException genericexp = new EDGE_GenericException(exp, newItems[0]); 
        } catch(Exception ex){
            
        }
		Test.stopTest();
    }
    
    @isTest
    public static void updateSalesOrg(){
		EDGE_UtilityTestClass.createOrgSettings();                
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        Pick_Up_Options__c pckOption = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
		insert pckOption;
        
		Sales_Organisation__c salesOrg = EDGE_UtilityTestClass.getsalesorgRecord(countryId);
        salesOrg.Company_Code__c = '1234';
        insert salesOrg;
        
       // Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        Product__c product = new Product__c();
        product.Name='Test';
        product.Product_Full_Name__c = 'Test Product 1 full name';
        product.Country__c=countryId;
        insert product;
		
        Test.startTest();
        Account accnt = EDGE_UtilityTestClass.getOutletRecord();
        accnt.Outlet_Visit_Prioritisation_Grade__c= pckOption.Id;
        accnt.Sales_Org__c= salesOrg.Code__c;
        insert accnt;
		
		Approver_Matrix__c appmatrix = EDGE_UtilityTestClass.getApproverMatrixRecord(countryId);
		appmatrix.Sales_Org__c =salesOrg.Code__c;
        insert appmatrix;
        
                
        
       // ECM_Internal_Order__c intord = EDGE_UtilityTestClass.getInternalOrderRecord();
       // intord.Sales_Organisation__c = 	salesOrg.Id;
        ECM_Internal_Order__c intord = new ECM_Internal_Order__c();
        intord.Name='123456789101';
        intord.ECM_Product__c = product.Id;
        intord.ECM_Geography__c = countryId ;
        intord.SAP_Company_Code__c = '1234';
        
        
       // intord.RecordTypeId= Schema.SObjectType.ECM_Internal_Order__c.getRecordTypeInfosByName().get('CST_Internal_Order').getRecordTypeId();
        insert intord;
        List<ECM_Internal_Order__c> newItems = new List<ECM_Internal_Order__c>();
        newItems.add(intord);
        List<ECM_Internal_Order__c> oldItems = new List<ECM_Internal_Order__c>(); 
        oldItems.add(intord);
        

        CST_SharingUtil.updateSalesOrganization(newItems, oldItems,'SAP_Company_Code__c');
        
		Test.stopTest();
		
	}	 
    
    
}