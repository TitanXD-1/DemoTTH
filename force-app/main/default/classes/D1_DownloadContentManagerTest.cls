/*
 * @name: D1_DownloadContentManagerTest
 * @discription: Test class for D1_DownloadContentManager Class
 * @history                                                            
 * VERSION     AUTHOR              DATE              DETAIL
 * 1.0			 -					-					-
 * 2.0         Rithika             29/06/2021        NCP-3783(Test Class Refactor)
 * 3.0		   Sayan			   30/12/2021		 NCP-5767
 * 4.0		   Kapil Baliyan	   25/08/2022		 NCP-
 **/

@isTest
public without sharing class D1_DownloadContentManagerTest {
    /**
     * @description 
     */    
    @testSetup
    public static void dataSetup(){
        Account directCustomer = D1_TestDataUtility.getDirectCustomer();
        
        D1_TestDataUtility.setUpExternalUser(directCustomer,'Direct Buyer');
        
        D1_Event__c event = D1_TestDataUtility.getEvent();
        D1_Brand__c brand = D1_TestDataUtility.getBrand();

        //Insert Content Assignment
        List<D1_Content_Assignment__c> caList = new List<D1_Content_Assignment__c>();
        D1_Content_Assignment__c ca1 = D1_TestDataUtility.getContentAssignment(event.Id, null, null, 'Christmas'); //Insert Event
        D1_Content_Assignment__c ca2 = D1_TestDataUtility.getContentAssignment(null, brand.Id, null, 'Ciroc'); //Insert Brand

        caList.add(ca1);
        caList.add(ca2);

        insert caList;

        //Insert Download Folder Item
        for(D1_Content_Assignment__c ca : [SELECT Id, Folder_Content_Document_Id__c, Folder_Content_version_Id__c FROM D1_Content_Assignment__c]){
            D1_TestDataUtility.getDownloadFolderItem(ca);
        }
    }
    /**
     * @description 
     */    
    @isTest 
    public static void validatedmethod(){
        String docIdBrand = [SELECT Id FROM D1_Content_Assignment__c WHERE D1_Brand__c!=null LIMIT 1].Id;
        String docIdEvent = [SELECT Id FROM D1_Content_Assignment__c WHERE D1_Event__c!=null LIMIT 1].Id;
        D1_Content_Assignment__c testData = [SELECT Id,Folder_Content_version_Id__c,D1_Brand__r.Name,D1_Event__r.Name,
                                             D1_Brand__r.Category__c,Folder_Link__c,
                      						 Description__c, Count_Download_Folder_Items__c, DCH_Asset_Tags__c 
                                             FROM D1_Content_Assignment__c 
                                             WHERE D1_Brand__c!=null LIMIT 1];
        User eUser = [select id 
                      FROM User 
                      WHERE username ='testclassextuser1@testdomain.com'];
        
        system.runAs(eUser)
        {
            Test.startTest();
            Object obj10 = D1_DownloadContentManager.getDownloadContents();
            System.assert(obj10!=null,'Brand Contents not found');
            List<D1_DownloadContentManager.HeaderContentWrapper> obj1 = D1_DownloadContentManager.getDownloadItemContents(false, 'BRAND', '');
            System.assert(obj1!=null, 'Brand Contents not found');
            List<D1_DownloadContentManager.HeaderContentWrapper> obj2 = D1_DownloadContentManager.getDownloadItemContents(false, 'BRAND', docIdBrand);
            System.assert(obj2!=null, 'Brand Contents not found');
            List<D1_DownloadContentManager.HeaderContentWrapper> obj3 = D1_DownloadContentManager.getDownloadItemContents(true, 'BRAND','');
            System.assert(obj3!=null, 'Occasion Contents not found');
            List<D1_DownloadContentManager.HeaderContentWrapper> obj4 = D1_DownloadContentManager.getDownloadItemContents(false, 'OCCASION', '');
            System.assert(obj4!=null, 'Occasion Contents not found');
            List<D1_DownloadContentManager.HeaderContentWrapper> obj5 = D1_DownloadContentManager.getDownloadItemContents(false, 'OCCASION', docIdEvent);
            System.assert(obj5!=null, 'Brand Contents not found');
            D1_DownloadContentManager.DownloadBannerContentWrapper obj6 = D1_DownloadContentManager.getBannerImageData('BRAND', '');
            System.assert(obj6!=null, 'Occasion Image not found');
            D1_DownloadContentManager.DownloadBannerContentWrapper obj7 = D1_DownloadContentManager.getBannerImageData('OCCASION', '');
            System.assert(obj7!=null, 'Brand Image not found');
            D1_DownloadContentManager.DownloadBannerContentWrapper obj8 = D1_DownloadContentManager.getBannerImageData('BRAND', docIdBrand);
            System.assert(obj8!=null, 'Occasion Image not found');
            D1_DownloadContentManager.DownloadBannerContentWrapper obj9 = D1_DownloadContentManager.getBannerImageData('OCCASION', docIdEvent);
            System.assert(obj9!=null, 'Occasion Image not found'); 
            D1_DownloadContentManager.DownloadItemContentWrapper obj11 = D1_DownloadContentManager.createDownloadItem(testData, 'OCCASION', FALSE);
            System.assert(obj11!=null, 'Occasion not found');
            D1_DownloadContentManager.HeaderContentWrapper obj12 = D1_DownloadContentManager.createDownloadHeaderItem('OCCASION');
            System.assert(obj12!=null, 'Occasion not found');
            Test.stopTest();
        }
        
    }
}