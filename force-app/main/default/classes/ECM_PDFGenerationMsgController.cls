/*
	@Name: ECM_PDFGenerationMsgController
	@Purpose: This is Class for fetch details on contract Generate
	@PDF file in the linked Addendum Type = T&C, Addendum status = APPROVED
	@History                                                            
	@VERSION    AUTHOR                   DATE              DETAIL
	1.1      	Saurav Paul     14/11/2021       Added for ECM-6212  
*/
public class ECM_PDFGenerationMsgController {
    //Variables
    public String contractId{get; set;} 
    //Constructor    
    public ECM_PDFGenerationMsgController(ApexPages.StandardController stdController) {
        String paramId= System.currentPageReference().getParameters().get('Id');
        contractId = paramId!=null ? paramId : (ID)stdController.getId();
    }
    //page ref for Action
    public PageReference continuePDFGene(){
        PageReference pageRef = 
            new PageReference('/apex/ECM_PDF_Generation?scontrolCaching=1&id='+ contractId+'&addendumId='+''+'&isApproval='+false);
        pageRef.setRedirect(true);
        return pageRef;
    }
}