@isTest
public class D1InactiveSiteTest {
    /**
     * @Name : testCreateDocument
	 * @description : This method is used to test the D1InactiveSite() method of the D1InactiveSite class
	 */
    @isTest
    public static void testCreateDocument() {
        // Create the folder and documents
        Test.startTest();
        Folder folder = [SELECT Id FROM Folder WHERE Name = 'Shared Documents' LIMIT 1];
        List<Document> documents = new List<Document> 
        {	
            new Document(Name = 'D1_InactiveImage', FolderId = folder.Id),
            new Document(Name = 'D1_DiageoOneLogo', FolderId = folder.Id),
            new Document(Name = 'D1 MYRIADPRO-SEMIBOLD Font', FolderId = folder.Id)
        };
        insert documents;
               
        D1InactiveSite classObj = new D1InactiveSite();
        Test.stopTest();
		//Assertions 
        System.assert(classObj != null, 'Expected a non-null D1InactiveSite object');
        for (Document doc : documents) {
            System.assert(doc.Id != null, 'Expected all documents to have non-null Ids');
        }
    }
}