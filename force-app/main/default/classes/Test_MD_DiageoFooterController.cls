@isTest
public class Test_MD_DiageoFooterController {
	
    @isTest static void testGetParameterByNameES(){
        ApexPages.currentPage().getParameters().put('country','ES');
        MD_DiageoFooterController diageoFooter = new MD_DiageoFooterController();
        System.assertEquals(diageoFooter.getParameterByName('country'),'ES');
    }
    
    @isTest static void testGetParameterByNameGB(){
        ApexPages.currentPage().getParameters().put('country','GB');
        MD_DiageoFooterController diageoFooter = new MD_DiageoFooterController();
        System.assertEquals(diageoFooter.getParameterByName('country'),'GB');
    }
}