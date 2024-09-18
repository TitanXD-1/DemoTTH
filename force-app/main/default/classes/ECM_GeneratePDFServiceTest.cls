/**
* @description :  ECM_GeneratePDFServiceTest
* @purpose : This is serviceclass ,mobile is using it to generate PDF
* @since :
* Version      Developer            		Date          User Story/Purpose
* 1.0		   Anuja					  22/02/2022	 Initial Test cls coverage for ECM_GeneratePDFService
* 2.0		   Subhrojit Majumdar		  10/03/2022	 Added testGeneratePDFServiceLegal() against ECM-5309
*/
@isTest
public class ECM_GeneratePDFServiceTest {
    /**
	 * @Name : testGeneratePDFService()
	 * @Description : This method is used to test doGet() method in ECM_GeneratePDFService class.
	 */
@isTest
public static void testGeneratePDFService(){
    String contId = createData();
    
    Test.startTest();
    RestRequest req = new RestRequest(); 
    RestResponse res = new RestResponse();
    
    req.requestURI = '/services/apexrest/GeneratePDFService'; 
    req.params.put('contractId', contId);
    req.httpMethod = 'GET';
    req.addHeader('Content-Type', 'application/json'); 
    RestContext.request = req;
    RestContext.response = res;
    ContentVersion contVer = ECM_GeneratePDFService.doGet();
    System.assertNotEquals(Null, contVer,'null');
    Test.stopTest();  
   }
    /**
	 * @Name : testGeneratePDFServiceLegal()
	 * @Description : This method is used to test doGet() method for Contracts with addendum records.
	 */
@isTest
public static void testGeneratePDFServiceLegal(){
    String contId = createData();
    
    Contract con = [SELECT ID, Status from Contract where ID=:contId limit 1];
    con.Status = 'Approved';
    update con;
    
    //creating addendum record for contract
    ECM_Addendum__c addendum = ECM_UtilityTestClass.getAddendum(contId);
    addendum.ECM_Status__c='Approved'; 
    addendum.ECM_Addendum_Type__c = 'T&C (Terms & Conditions)';
    insert addendum;
    
    //creating ContentDocument record to link to addendum
    ContentVersion cv = new ContentVersion();
    cv.Title = 'File Preview';
    cv.VersionData = Blob.valueOf(String.valueOf('File Preview'));
    cv.PathOnClient = 'S';
    insert cv;
    
    List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
    //linking addendum to ContentDocument record
    ContentDocumentLink conDocLnkRec = EDGE_UtilityTestClass.getConDocLink (addendum.Id,documents[0].Id);
    insert conDocLnkRec;
    
    Test.startTest();
    RestRequest req = new RestRequest(); 
    RestResponse res = new RestResponse();
    
    req.requestURI = '/services/apexrest/GeneratePDFService'; 
    req.params.put('contractId', contId);
    req.httpMethod = 'GET';
    req.addHeader('Content-Type', 'application/json'); 
    RestContext.request = req;
    RestContext.response = res;
    ContentVersion contVer = ECM_GeneratePDFService.doGet();
    System.assertNotEquals(Null, contVer,'null');
    Test.stopTest();  
   }
    /**
	 * @Name : createData()
	 * @Description : This method is used to generate data to test ECM_GeneratePDFService class.
	 */
     public static String createData(){
         
         Id contrRecTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
         Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
         Contract contr = new Contract();
         //creating account to which contract will be associated
         Account acc = EDGE_UtilityTestClass.getOutletRecord();
         acc.country__c = geographyId;
         acc.Sales_Org__c ='sale';
         acc.SAP_Sold_to__c ='sapsold';
         insert acc;
         
         //creating agreement type with Enable Recall of Contract as False
         ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
         insert contractType;
         
         //creating contract of draft status
         contr = ECM_UtilityTestClass.createContract(acc.Id,contrRecTypeId);        
         contr.ECM_Agreement_Type__c = contractType.Id;
         contr.Status = 'Draft';
         insert contr; 
         system.debug(LoggingLevel.Debug,'@@contr' +contr.id);
        return contr.Id;
     }    
}