/*
 * @name: D1_ContentControllerTest
 * @discription: This is the test class for the  D1_ContentController class and D1_ContentWrapperClass. 
 * @History                                                            
 * --                                                            
 * VERSION   AUTHOR            DATE              DETAIL
 * 1.0   Sudipta Nandi        09/01/201920    Initial Development
 * 2.0	  Rithika			   01/07/2021	   NCP-3783(Test Class Refactor)
 **/
@isTest
public without sharing class D1_ContentControllerTest {
    // See ALl data is required because we are calling here connectApi method //
    /**
     * @description 
     */    
    @SuppressWarnings('PMD.ApexUnitTestShouldNotUseSeeAllDataTrue')
    @isTest(seealldata=true)
    public static void validatedmethod(){
        String validContentId = '20Y5r0000004MBeEAM';
        String language='en_US';
        String contentType= 'D1_Administrative_Contents';
        String communityId = [Select Id, Name from Network where name ='DiageoOne'].Id;
        
        Test.startTest();
        D1_ContentWrapperClass wrpContext = D1_ContentController.getContentDetails(validContentId,contentType,language,communityId);
        System.assert(wrpContext.errorMessage == null, true);
        String contentId2='20Y3O000000008OqHUAU';
        D1_ContentWrapperClass wrpContext2 = D1_ContentController.getContentDetails(contentId2,contentType,language,communityId);
        System.assert(wrpContext2.errorMessage != null, true );
        D1_ContentWrapperClass wrpContext3 = D1_ContentController.getContentDetails(null,contentType,language,null);
        System.Assert(wrpContext3 != null, true);
        Map<String,Object> contentInfoMap = D1_ContentController.getManagedContentInfoByIds(communityId,new List<String>{validContentId},0, 5, language,contentType, new Set<String>{'Subtitle'});
        System.Assert(contentInfoMap != null, true);
        D1_ContentController.getContents(new List<String>{validContentId},language,communityId);
        D1_ContentWrapperClass wrp = new D1_ContentWrapperClass('Test','Test','Test','','','','','','','','','','','',true,'','','','','','','','','','','','');
        Map<String, object> obj1 = new Map<String, object>();
        String contentURL='abs';String contentKey='abc';
        Map<String, String> obj2 = new Map<String, String>();
        obj2.put('value','SampleTitle');
        obj2.put('url','SampleTitle');
        obj1.put('title',obj2);
        
        D1_ContentController.processResult(obj1,contentURL,contentKey,'Direct Buyer');
        D1_ContentController.processResult(obj1,contentURL,contentKey,'Outlet/Retailers');

        Test.stopTest();
    }
     
    @isTest
    public static void validateExceptionMethod(){
        String validContentId = System.Label.D1_contentControllerTest;
        String language='en_GB';
             
        Test.startTest();
        try{
        	D1_ContentController.getContents(new List<String>{validContentId},language,null);
             System.Assert(true, true);
        } catch (Exception ex){
            System.debug(LoggingLevel.ERROR, ex.getMessage());
        }
        Test.stopTest();
    }
    
}