public class MD_ChangePasswordPageController {

    public String disclaimer {get;set;}
    public User currentUser {get;set;}
    public String passwordResetHeader {get;set;}
    public List<MD_PasswordPolicies__mdt> passwordPolicies {get;set;}
    public String passwordPoliciesRegex {get;set;}
	public String oldPassword {get; set { oldPassword = value == null ? value : value.trim(); } }
    public String newPassword {get; set { newPassword = value == null ? value : value.trim(); } }
    public String verifyNewPassword {get; set { verifyNewPassword = value == null ? value : value.trim(); } } 
    public Boolean hasPwdChangeBeenSuccessful {get; set;}   
    
    public MD_ChangePasswordPageController() {
        System.debug('MD - in MD_ChangePasswordPageController.changePassword() method. BEGIN');
        
        Map<String, MD_ChangePasswordPageController.PasswordPolicyWrapper> passwordPoliciesRegexMap = new Map<String, MD_ChangePasswordPageController.PasswordPolicyWrapper>();

        this.currentUser = [SELECT Id, Username, LastPasswordChangeDate FROM User WHERE Id = :UserInfo.getUserId()];

   		this.hasPwdChangeBeenSuccessful = false;
        passwordPolicies = new List<MD_PasswordPolicies__mdt>();
        
        for(MD_PasswordPolicies__mdt pp : [SELECT Id, Label, CustomLabel__c, Regex__c, ApexRegex__c, Order__c
                                           	FROM MD_PasswordPolicies__mdt ORDER BY Order__c ASC]) {
            passwordPolicies.add(pp);
            passwordPoliciesRegexMap.put(pp.Label, new PasswordPolicyWrapper(pp));
        }
        passwordPoliciesRegex = JSON.serialize(passwordPoliciesRegexMap);
        passwordResetHeader = Label.MD_PasswordResetHeader;
        disclaimer = String.format(Label.MD_PasswordResetDisclaimer, new String[]{String.valueOf(System.Today().year())});
        
        System.debug('MD - in MD_ChangePasswordPageController.changePassword() method. END');
   	}
	
    public PageReference changePassword() {
        
        System.debug('MD - in MD_ChangePasswordPageController.changePassword() method. ');
        Pagereference pr = null;

        try {
            if (! isValidPassword()) {
                ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, Label.Site.passwords_dont_match);
                ApexPages.addMessage(msg);
                return null;
            }
            
            if (! passwordApprovesPolicies()) {
                ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, Label.MD_PasswordPoliciesUnnaproved);
                ApexPages.addMessage(msg);
                return null;
            }

            if(Test.isRunningTest()) {
                System.debug('MD - in MD_ChangePasswordPageController.changePassword() method. Test.isRunningTest(): ' + Test.isRunningTest());
            }else {
                System.debug('MD - in MD_ChangePasswordPageController.changePassword() method. Test.isRunningTest(): ' + Test.isRunningTest());
                pr = Site.changePassword(newPassword, verifyNewPassword, null);
            }
        }catch(Exception e) {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage() + ' - ' + e.getCause() + ' - ' + e.getLineNumber());
            ApexPages.addMessage(msg);return null;
        }

        return pr;
    } 
    
    private Boolean isValidPassword() {
        System.debug('MD - in MD_ChangePasswordPageController.isValidPassword() method.');

    	if(newPassword != '' &&  verifyNewPassword != '' && newPassword == verifyNewPassword) {
    		return true;
    	} 
        
        return false ;
	}
	
    @TestVisible
    private Boolean passwordApprovesPolicies () {
        System.debug('MD - in MD_ChangePasswordPageController.passwordApprovesPolicies() method.');

        Boolean policiesApproved = true;

        for(MD_PasswordPolicies__mdt p : passwordPolicies) {
            //if(String.isNotEmpty(p.ApexRegex__c)) {
                Pattern patt = Pattern.compile(p.ApexRegex__c);
                Matcher mat = patt.matcher(newPassword);

                if(! mat.matches()) {
                    System.debug('MD - in MD_ChangePasswordPageController.passwordApprovesPolicies() method. newPassword: ' + newPassword + ' does not approves rexeg: ' + p.ApexRegex__c);
                    policiesApproved = false;
                }
            //}
        }

        if(policiesApproved){
            System.debug('MD - in MD_ChangePasswordPageController.passwordApprovesPolicies() method. policiesApproved');

    		return true;
    	} 
        
        System.debug('MD - in MD_ChangePasswordPageController.passwordApprovesPolicies() method. policies do not Approve');
        return false ;
    }

    public class PasswordPolicyWrapper {
        public String label {get;set;}
        public String regex {get;set;}
        public Boolean status {get;set;}
        
        public PasswordPolicyWrapper(MD_PasswordPolicies__mdt pp) {
            label = pp.Label;
            regex = pp.Regex__c;
            status = false;
        }
    }
}