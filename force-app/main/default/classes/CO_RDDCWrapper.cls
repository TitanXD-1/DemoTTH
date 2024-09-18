/*
@Name: CO_RDDCWrapper

@Purpose: This class is used for RDCC request json and response parsing.

@History                                                              
                                                       
VERSION    	AUTHOR                  DATE            DETAIL
1.0        	Abhishek Shudhalwar     12-01-2023      Initial Development
2.0		   	Jayashree R				24-01-2023		CONS-355
3.0 		Tupesh Bhagat     		21-03-2023      CONS-809
*/

@SuppressWarnings('PMD.ExcessivePublicCount')
public class CO_RDDCWrapper {
    //Added as part of CONS-809//
    public class ScreeningCriteria {
		public Boolean enableOngoingScreening {get;set;} 
	}
    //Added as part of CONS-809//
    public class CO_RDDCToSFResposne{
        public String message;
        public DataWrapper data;
        public String id;
    }
    
    public class DataResponseWrapper
    {
        public String referenceNo;	//500000001
        public String name;	//ABC Corp
        public String riskTier;
        public List<CustomFieldsResponseWrapper> customFields;
    }
     public class CustomFieldsResponseWrapper {
        public String name;	//Customer Income Range
        public String value;	//Middle Class
     }
    
    public class DataWrapper {
        public String referenceNo;	//500000001
        public String name;	//ABC Corp
        public String currencyCR;	//USD
        public String worldCheckGroup;
        public String workflowGroupId;
        public String responsibleParty;	//siadmin @supplierintegrity.com
        public String[] divisions;	//[Operations, IT, Sales]
        public AddressWrapper address;
        public String description;	//This is a description
        public List<OtherNamesWrapper> otherNames;
        public List<CustomFieldsWrapper> customFields;
        public ContactDetailsWrapper contactDetails;
        public QuestionnaireWrapper assignquestionnaire;
        public List<QuestionResponseWrapper> questionnaireResponse;
        public String language;
        /*public String companyType;	//CORP
        public String industryType;	//AHI
        public String organizationSize;	//11-50
        public String businessType;	//PRS
        public String incorporationDate;	//2021-06-18T05:32:07.862Z
        public String revenue;	//10M
        public String liquidationDate;	//2021-06-18T05:32:07.862Z
        public String affiliation;	//SOE
        public String workflowGroupId;	//5fcdb025b61d5bc662ab6b40
        public AssessmentDetailWrapper assessmentDetail;
        public String spendCategory;	//OTS
        public String sourcingMethod;	//DIST_M_SRC
        public String productDesignAgreement;	//OTS
        public String sourcingType;	//MULTI
        public String relationshipVisibility;	//LITTLE_VIS
        public String productImpact;	//COMMODITIZED_PRODUCT
        public String commodityType;	//A3p
        public BankDetailsWrapper[] bankDetails;
        public ContactInformationWrapper contactInformation;
        public CountryAlertsWrapper[] countryAlerts;
        public String status;	//NEW
        public Double overallRiskScore;	//2.277536
        public String riskTier;	//Low
        public String screeningStatus;	//No Results
        public String overallStatus;	//No Results
        public String createTime;	//2021-06-18T05:32:07.862Z
        public String updateTime;	//2021-06-18T05:32:07.862Z
        public boolean autoScreen; //true */
        public ScreeningCriteria screeningCriteria {get;set;}//Added as part of CONS-809
    }

    /*public class AssessmentDetailWrapper {
        public String decisionTime;	//2021-06-18T05:32:07.862Z
        public String nextRenewalTime;	//2021-06-18T05:32:07.862Z
        public String onboardingStartTime;	//2021-06-18T05:32:07.862Z
        public Integer renewalCycle;	//365
    }*/

    public class AddressWrapper {
        //public String addressLine;	//Address Line 1
        //public String city;	//City 1
        public String country;	//US
        //public String postalCode;	//31080
        //public String province;	//Province 1
        //public String region;	//021
    }
    public class CustomFieldsWrapper {
        public String name;	//Customer Income Range
        public Object value;	//Middle Class
        /*public String createTime;	//2021-06-18T05:32:07.862Z
        public String description;	//This is description
        public String id;	//5e83e0aaa5f2a400019e83be
        public OptionsWrapper[] options;
        public Integer orderNumber;	//1
        public String status;	//ACTIVE
        public String type;	//TEXT
        public String updateTime;	//2021-06-18T05:32:07.862Z
        public boolean usePredefinedValues;*/
    }
   /* public class OptionsWrapper {
        public String option;	//Option 1
        public boolean redFlag;
    }
    public class BankDetailsWrapper {
        public String accountNo;	//111-11111111-1
        public String addressLine;	//Address 1
        public String branchName;	//Branch Name
        public String city;	//City 1
        public String country;	//US
        public String name;	//Bank Name
    }*/
    public class OtherNamesWrapper {
        public String name;	//Local Name
        public String countryOfRegistration;	//US
        public String worldCheckGroup;
        public String iwNameType;
        //public String iwNameType;	//Also Known As
       // public String countryOfLocation;	//US
        //public String countryOfBirth;	//US
        //public String citizenship;	//US
        //public String createTime;	//2021-06-18T05:32:07.862Z
        //public String updateTime;	//2021-06-18T05:32:07.862Z
        //public boolean localNameSelected;
    }
    
    public class ContactDetailsWrapper{
        public String firstName;
        public String lastName;
        public ContactInformationWrapper contactInformation;
        public LanguagePreferenceWrapper languagepreference;
    }
    
    public class ContactInformationWrapper {
        public String[] email;
        //public String[] fax;
        //public String[] phoneNumber;
        //public String[] website;
    }
    
    public class LanguagePreferenceWrapper{
        public String languageId;
    }
    
    public class QuestionnaireWrapper{
        public String[] questionnaireNames;
        public String assignee;
        public String questionnaireType;
        public String overallReviewer;
        public String dueDate;
        public String initiatedBy;
        
    }
    
    public class RddcDataError{
        public List<ErrorWrapper> errors;
    }
    
    public class ErrorWrapper{
        public String field;
        public String code;
        public String description;
        
    }
    /*public class CountryAlertsWrapper {
        public String alertMessage;	//string
        public String alertType;	//string
    }*/


    public class CO_ErrorResposneGetDetails{
        public ErrorWrapperGetDetails error;
    }

    public class ErrorWrapperGetDetails{
        public String errorMessage;
        public String errorType;
        public String errorCode;
    }
    
    public class QuestionWrapper{
        public String questionId;
        public Object answers;
    }
    
    public class QuestionResponseWrapper{
        public String tabId;
        public List<QuestionWrapper> questions = new List<QuestionWrapper>();
    }
    
   
   
}