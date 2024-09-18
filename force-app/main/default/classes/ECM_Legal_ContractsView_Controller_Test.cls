/*
 * @Name: ECM_Legal_ContractsView_Controller_Test
 * @Description: This is the test class for ECM_Legal_ContractsView_Controller
 * @History                                                            
                                                         
 VERSION    AUTHOR                DATE              DETAIL
 1.0        -			     	  -        			Initial Development
 1.1        Subhrojit Majumdar    09/02/2022        Development of Reject Addendum logic against ECM-4963
*/ 
@isTest
public class ECM_Legal_ContractsView_Controller_Test 
{
    /**
    * @Name : legalContSubmitTest
	* @description : This method is used to test the acceptance of addendum records in ECM_Legal_ContractsView_Controller class
	*/
    @isTest
    public static void legalContSubmitTest()
    {
        User usr = EDGE_UtilityTestClass.runAsUser('testUser','Legal User');
        usr.Available_Countries__c = 'AU';
        usr.Title='Legal';
        insert usr;

        Test.startTest();
        try
        {
        	System.runAs(usr)
        	{
           		WrapperInst wrapobj = createData();
            	ECM_Addendum__c addendumRec = wrapobj.addendumRec;
            	ECM_Addendum__c addendumObj = wrapobj.addendumObj;
			
            	ECM_Legal_ContractsView_Controller.getAddendumRecs();
            	ECM_Legal_ContractsView_Controller.updateAddendum(addendumRec.id,usr.id);
            	ECM_Legal_ContractsView_Controller.legalContractvalues(addendumRec.id);
            	ECM_Legal_ContractsView_Controller.submitLegalViews(addendumObj);
            	ECM_Legal_ContractsView_Controller.saveDraftAddendum(addendumObj);
            	ECM_Legal_ContractsView_Controller.FilesCheck(addendumRec.id);
            	ECM_Legal_ContractsView_Controller.deleteFile(addendumRec.id);
            	ECM_DeleteExistingFiles.deleteFile(addendumRec.id);
                System.assert(addendumRec != null,'addendumRec should not be null');
        	}
        }catch(Exception e)
        {
            System.debug(LoggingLevel.Debug,e.getMessage());
        }
        Test.stopTest();
    }
    /**
    * @Name : rejectLegalContTest
	* @description : This method is used to test the rejection of addendum records in ECM_Legal_ContractsView_Controller class
	*/
@isTest
    public static void rejectLegalContTest()
    {
        User usr = EDGE_UtilityTestClass.runAsUser('testUser','Legal User');
        usr.Available_Countries__c='AU';
        usr.Title='Legal';
        insert usr;

        Test.startTest();
        try
        {
            System.runAs(usr)
        	{
            	WrapperInst wrapobj = createData();
            	ECM_Addendum__c addendumRec = wrapobj.addendumRec;
            	addendumRec.ECM_Status__c = 'Approved';
            	update addendumRec;
            	ECM_Addendum__c addendumObj;
                addendumObj = wrapobj.addendumObj;
			
            	ECM_Legal_ContractsView_Controller.getAddendumRecs();
            	ECM_Legal_ContractsView_Controller.updateAddendum(addendumRec.id,'');
   
            	ECM_Legal_ContractsView_Controller.rejectAddendum(addendumRec);
                System.assert(addendumRec != null,'addendumRec should not be null');
        	}
        }catch(Exception e)
        {
            System.debug(LoggingLevel.Debug,e.getMessage());
        }
        Test.stopTest();
    }
    /**
    * @Name : createData()
	* @description : This method is used to create test data for testing the methods of ECM_Legal_ContractsView_Controller class
    * @return : returns a Wrapper with a Addendum record and a list of Addendum records
	*/
    public static WrapperInst createData()
    { 
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        
       	Id recordtypeId=Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Business Unit').getRecordTypeId();
        Territory_Hierarchy__c hirarchy1= ECM_UtilityTestClass.getTerritoryHierarchy(recordtypeId, geographyId, null);
        insert hirarchy1;
        
        Id recordtypeId2=Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Sales Area').getRecordTypeId();
        Territory_Hierarchy__c hirarchy2= ECM_UtilityTestClass.getTerritoryHierarchy(recordtypeId2, geographyId, hirarchy1.id);
        insert hirarchy2;
        
        Id recordtypeId3=Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Region').getRecordTypeId();
        Territory_Hierarchy__c hirarchy3= ECM_UtilityTestClass.getTerritoryHierarchy(recordtypeId3, geographyId, hirarchy2.id);
        insert hirarchy3;
        
        Territory__c testterritory = EDGE_UtilityTestClass.getTerritoryRec();
        testterritory.Region__c = hirarchy3.Id;
            insert testterritory;
            

        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.country__c = geographyId;
        insert outlet;

        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);

            insert contractType;
            
            String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();

        Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId); 
        insert objContract;
            
            ECM_Addendum__c addendumRec = new ECM_Addendum__c();
            addendumRec.Name='Test';
        addendumRec.ECM_Contract__c = objContract.Id;
            addendumRec.ECM_Status__c = 'Draft';
        insert addendumRec;
            addendumRec.ECM_New_T_C__c = 'Checking';
        update addendumRec;
            
            ECM_Addendum__c addendumObj = new ECM_Addendum__c();
            addendumObj=[Select id,ECM_Contract__c,ECM_Contract__r.id,ECM_New_T_C__c from ECM_Addendum__c where id =:addendumRec.id];
            
            ContentVersion cv = EDGE_UtilityTestClass.gerConVerRec('Test.jpeg');
            cv.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Direct Customer').getRecordTypeId();
            cv.Content_Type__c = 'Direct Customer';
            cv.Title = 'Test.jpeg';
            insert cv;
            
            Id conDocId = [Select ContentDocumentId from ContentVersion where Id =:cv.Id].ContentDocumentId;
            
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.LinkedEntityId = addendumRec.id;
            cdl.ContentDocumentId = conDocId;
            cdl.ShareType = 'V';
        insert cdl;
            
            
            ContentDocumentLink contentDoc = new ContentDocumentLink();
       
            contentDoc= [Select ContentDocumentId,LinkedEntityId from ContentDocumentLink where LinkedEntityId=: addendumRec.id];
            String contentId = contentDoc.ContentDocumentId;
            String fullFileURL = URL.getSalesforceBaseUrl().toExternalForm();
            String urlDownload;
            urlDownload = fullFileURL+'/sfc/servlet.shepherd/document/download/'+contentId+'?operationsContext=S1';

        WrapperInst wrapObj = new WrapperInst();
        wrapobj.addendumRec = addendumRec;
        wrapobj.addendumObj = addendumObj;
        wrapobj.objContract = objContract;
        return wrapObj;

        }
    class WrapperInst
    {
        ECM_Addendum__c addendumRec{get;set;}
        ECM_Addendum__c addendumObj{get;set;}
       	Contract objContract{get;set;}
    }
}