/*
* Name: EDGE_DuplicateContactServiceWrapper
* Purpose: This wrapper class is needed to parse Mobile request for Contact
* validation
* History                                                            

VERSION			AUTHOR					DATE				DETAIL
1.0       Sandip Ghosh      12/11/2019        ES20-6244
2.0		  Swagata Mondal     08/21/2023        144596
*/
global class EDGE_DuplicateContactServiceWrapper {
    
    public Boolean hasAnySuggestion{get;set;}
    public Boolean hasOtherErrors{get;set;}
    public List<EDGE_DuplicateContactServiceWrapper.EDGE_ContactDupChkResultWrapper> suggestionList{get;set;}
    
    public class EDGE_ContactDupChkResultWrapper{
        public String GUID{get;set;}
        public Boolean Status{get;set;}
		public String errorCode{get;set;}
        public List<EDGE_ContactWrapper> contacts{get;set;}
    }
    
    public class EDGE_ContactWrapper{
         public String existingContactId{get;set;}
         public String existingContactFirstName{get;set;}
         public String existingContactLastName{get;set;}
         public String existingContactEmail{get;set;}
         public String existingContactPhone{get;set;}
         public String existingContactMobilePhone{get;set;}
         public String existingContactPhonePrefix{get;set;}
         public String existingContactPhoneNumber{get;set;}
         public String existingContactTitle{get;set;}
         public String existingContactSalutation{get;set;}
         public String existingContactOutletRole{get;set;} //144596
    }

}