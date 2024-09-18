/**
 * @name D1InactiveSite
 * @description D1InactiveSite Class for D1InactiveSite page 
 * @history
 * VERSION     AUTHOR           DATE       DETAIL
 * 1.0         Ankit            2/11/20    
**/
public class D1InactiveSite {
    
    public string strURL{get;set;}
    public string logoURL{get;set;}
    public string semiBoldFontURL{get;set;}
    
    /**
     * @description D1InactiveSite
     */    
    public D1InactiveSite() {
        List<Document> lstDocument = [select Id from Document where Name = 'D1_InactiveImage' limit 1];
        if(lstDocument != NULL && lstDocument.size()>0) {
            strURL = '/servlet/servlet.ImageServer?id=' + lstDocument[0].Id;
        }
        List<Document> d1Logo = [select Id from Document where Name = 'D1_DiageoOneLogo' limit 1];
        if(d1Logo != NULL && d1Logo.size()>0) {
            logoURL = '/servlet/servlet.ImageServer?id=' + d1Logo[0].Id;
        }
        List<Document> d1SemiBoldFont = [select Id from Document where Name = 'D1 MYRIADPRO-SEMIBOLD Font' limit 1];
        if(d1SemiBoldFont != NULL && d1SemiBoldFont.size()>0) {
            //semiBoldFontURL = 'https://' + Site.getDomain() + '/DiageoOne' + '/servlet/servlet.FileDownload?file=' + D1semiBoldFont[0].Id + '&oid=' + UserInfo.getOrganizationId();
            semiBoldFontURL = '/servlet/servlet.FileDownload?file=' + d1SemiBoldFont[0].Id + '&oid=' + UserInfo.getOrganizationId();
        }
    }
}