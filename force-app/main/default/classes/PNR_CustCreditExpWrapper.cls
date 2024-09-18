/**********************************************************************
  Name: PNR_CustCreditExpWrapper
=======================================================================
Req : US- This wrapper class is used to parse Order Response
=======================================================================
    History                                                            
    -------                                                            
    VERSION   AUTHOR            DATE              DETAIL
     1.0      Saurav Paul     30/07/2019      Initial Development
***********************************************************************/
public class PNR_CustCreditExpWrapper {
	public class AcountRecord {
		public String customerNumber {get;set;} 
		public String salesOrg {get;set;} 
		public String creditControlArea {get;set;} 
		public String accountNumber {get;set;} 
		public String riskCategory {get;set;} 
		public String currencyVal {get;set;} 
		public Double creditLimit {get;set;} 
		public Double creditExposure {get;set;} 
		public Double creditLimitUsed {get;set;} 
		public String termsOfPaymentKey {get;set;} 
		public String descriptionOfPaymentTerms {get;set;} 
		public String lastReviewDate {get;set;} 
		public String rating {get;set;} 

		public AcountRecord(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'customerNumber') {
							customerNumber = parser.getText();
						} else if (text == 'salesOrg') {
							salesOrg = parser.getText();
						} else if (text == 'creditControlArea') {
							creditControlArea = parser.getText();
						} else if (text == 'accountNumber') {
							accountNumber = parser.getText();
						} else if (text == 'riskCategory') {
							riskCategory = parser.getText();
						} else if (text == 'currencyVal') {
							currencyVal = parser.getText();
						} else if (text == 'creditLimit') {
							creditLimit = parser.getDoubleValue();
						} else if (text == 'creditExposure') {
							creditExposure = parser.getDoubleValue();
						} else if (text == 'creditLimitUsed') {
							creditLimitUsed = parser.getDoubleValue();
						} else if (text == 'termsOfPaymentKey') {
							termsOfPaymentKey = parser.getText();
						} else if (text == 'descriptionOfPaymentTerms') {
							descriptionOfPaymentTerms = parser.getText();
						} else if (text == 'lastReviewDate') {
							lastReviewDate = parser.getText();
						} else if (text == 'rating') {
							rating = parser.getText();
						} else {
							System.debug(LoggingLevel.WARN, 'AcountRecord consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	public String status {get;set;} 
	public Integer recordCount {get;set;} 
	public String statusDescription {get;set;} 
	public AccountList accountList {get;set;} 

	public PNR_CustCreditExpWrapper(JSONParser parser) {
		while (parser.nextToken() != System.JSONToken.END_OBJECT) {
			if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
				String text = parser.getText();
				if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
					if (text == 'status') {
						status = parser.getText();
					} else if (text == 'recordCount') {
						recordCount = parser.getIntegerValue();
					} else if (text == 'statusDescription') {
						statusDescription = parser.getText();
					} else if (text == 'accountList') {
						accountList = new AccountList(parser);
					} else {
						System.debug(LoggingLevel.WARN, 'PNR_CustCreditExpWrapper consuming unrecognized property: '+text);
						consumeObject(parser);
					}
				}
			}
		}
	}
	
	public class AccountList {
		public List<AcountRecord> acountRecord {get;set;} 

		public AccountList(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'acountRecord') {
							acountRecord = arrayOfAcountRecord(parser);
						} else {
							System.debug(LoggingLevel.WARN, 'AccountList consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	
	public static PNR_CustCreditExpWrapper parse(String json) {
		System.JSONParser parser = System.JSON.createParser(json);
		return new PNR_CustCreditExpWrapper(parser);
	}
	
	public static void consumeObject(System.JSONParser parser) {
		Integer depth = 0;
		do {
			System.JSONToken curr = parser.getCurrentToken();
			if (curr == System.JSONToken.START_OBJECT || 
				curr == System.JSONToken.START_ARRAY) {
				depth++;
			} else if (curr == System.JSONToken.END_OBJECT ||
				curr == System.JSONToken.END_ARRAY) {
				depth--;
			}
		} while (depth > 0 && parser.nextToken() != null);
	}
	
    private static List<AcountRecord> arrayOfAcountRecord(System.JSONParser p) {
        List<AcountRecord> res = new List<AcountRecord>();
        if (p.getCurrentToken() == null){
            p.nextToken();
        } 
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(new AcountRecord(p));
        }
        return res;
    }
}