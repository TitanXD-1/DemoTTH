/*
	@Name: ECM_fileViewerCtrl
	@Purpose: This is Class for fetch details on contract Generate
	@PDF file in the linked Addendum Type = T&C, Addendum status = APPROVED
	@History                                                            
	@VERSION    AUTHOR                   DATE              DETAIL
	1.0      	Veerendra Billakurthi    10/09/2020       Initial Developmemt-ECM-2877
	1.1      	Anuja Chattopadhyay      09/06/2021       Added method getAccessibleProfile for ECM-4535   
	1.1      	Sayan Mullick		     08/07/2021       Added method getAccessibleActiveProfile for ECM-4585
	1.2      	Saurav Paul	      		 08/07/2021       Added for ECM-6212 and ECM-6395
*/


public class ECM_fileViewerCtrl {
    
    public ECM_fileViewerCtrl() {
        
    }
    
    public String contractId{get; set;} 
    public String Urlid{get;set;}
    public String AddendumType{get;set;} 
    public String AddendumStatus{get;set;} 
    public Boolean allowedDraftProfile{get;set;} 
    public Boolean allowedActiveProfile{get;set;} 
    public Boolean allowedCountry{get;set;}
    public Boolean isAmended{get;set;}//ECM-6212
    public Boolean isGB{get;set;}//ECM-6395
    
    public ECM_fileViewerCtrl(ApexPages.StandardController controller){
        fileViewerCtrls();
        
    }
    
    public void fileViewerCtrls(){
        String profileName='';
        list<ContentDocumentLink> ContentDocscheck= new list<ContentDocumentLink>();
        string paramid= System.currentPageReference().getParameters().get('Id');       
        contractId = paramid;
        List<Profile> profileList = [SELECT Id,Name FROM Profile WHERE Id =:UserInfo.getProfileId()];
        profileName= profileList[0].Name;
        allowedDraftProfile = getAccessibleDraftProfile(profileName);//added against ECM-4535
        allowedActiveProfile = getAccessibleActiveProfile(profileName);//added against ECM-4585
        allowedCountry = getallowedCountry(contractId);//added against ECM-4585
        contract con = [SELECT Id,status,ECM_Amended__c,ECM_ContractCountry__c FROM contract WHERE Id=:contractId ];
        isAmended = con.ECM_Amended__c;//ECM-6212
        isGB = String.isNotBlank(con.ECM_ContractCountry__c) && Label.ECM_Amended_PDF_Country.contains(con.ECM_ContractCountry__c)? true : false;//ECM-6395
        if(con.status=='Approved'){
            list <ECM_Addendum__c> addendumId= [Select Id,ECM_Contract__c,ECM_Addendum_Type__c,ECM_Contract__r.Name,ECM_Contract__r.Id,ECM_Contract__r.Owner.Email,ECM_Status__c,ECM_Contract__r.Status 
                                                from ECM_Addendum__c where ECM_Contract__r.Id=:contractId
                                                and
                                                ECM_Contract__r.Status='Approved' and ECM_Status__c='Approved' and ECM_Addendum_Type__c = 'T&C (Terms & Conditions)' limit 1];
            if (addendumId.size()>0){
                for(ECM_Addendum__c add : addendumId){
                    if(add.ECM_Contract__r.status == 'Approved' &&add.ECM_Addendum_Type__c == 'T&C (Terms & Conditions)' && add.ECM_Status__c == 'Approved'){
                        ContentDocscheck = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId=:add.Id limit 1];
                        
                        if(ContentDocscheck.size()>0){
                            Urlid= ContentDocscheck[0].ContentDocumentId;
                            AddendumType=add.ECM_Addendum_Type__c;
                            AddendumStatus=add.ECM_Status__c;
                        }
                    }
                }
            }
        }
    }
    //This method will return true if the logged in user's profile present in the custom label,implemented against ECM-4535  
    public Boolean getAccessibleDraftProfile(String profileName){  
        if(Label.ECM_Draft_Pdf_Enabled_Profile.contains(profileName)){
            return true;
        }
        return false;
    }
    //added against ECM-4585
    public Boolean getAccessibleActiveProfile(String profileName){  
        if(Label.ECM_Active_Pdf_Enabled_Profile.contains(profileName)){
            return true;
        }
        return false;
    }
	/*
     	Added against ECM-4585
		Function Name : getallowedCountry
		Input parameters : Contract Id
		Functionality : Used to check if Render PDF is checked a country.
	*/
    public Boolean getallowedCountry(String contractId){  
        //variables
        List<ECM_Technical_Market_Setting__mdt> mktSetList =  new List<ECM_Technical_Market_Setting__mdt>();
        String countryCode = [SELECT Id, Account.Country_Code__c FROM Contract WHERE Id = :contractId].Account.Country_Code__c;
        mktSetList = [SELECT masterlabel,ECM_Country__c,Render_PDF__c 
                      FROM ECM_Technical_Market_Setting__mdt 
                      WHERE ECM_Country__c =:countryCode];
        if(!mktSetList.isEmpty()){
            return mktSetList[0].Render_PDF__c;
        }else{
            return false;
        }
    } 	     
}