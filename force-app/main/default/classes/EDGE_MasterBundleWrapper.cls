/*Req: Wrapper class to store Master Bundle details
History                                                            
                                                            
VERSION   AUTHOR                  DATE              DETAIL
1.0		 Rajarshi Lahiri	   05/12/2022		 ES20-13612
2.0		 Rajarshi/shameer	   21/12/2022		 ES20-13646
*/
public class EDGE_MasterBundleWrapper{
        @AuraEnabled
    	public string recordId{get;set;}
        @AuraEnabled
        public string masterBundleName{get;set;}
        @AuraEnabled
        public String description{get;set;}
        @AuraEnabled
    	public string prereqforInstallation{get;set;}
    }