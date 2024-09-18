/**********************************************************************
Name: EDGE_ApprovalRequestController
=======================================================================

History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0       Aparajita         12/12/2020        ES20-9054   
***********************************************************************/
public class EDGE_ApprovalRequestController{
    
    public ID targetObjectId { get; set; }
    public String getURL {
        get {               
            return URL.getSalesforceBaseUrl().toExternalForm()+'/'+targetObjectId;          
        }           
        private set;
        
    }
}