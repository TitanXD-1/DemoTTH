public class ECM_PaymentResponseParser {
    public string CreditNoteNumber {get;set;} 
	public string CreditNoteCreationDate {get;set;} 
    public string ResponseMessage {get;set;} 
    
    public ECM_PaymentResponseParser(JSONParser parser){
        while (parser.nextToken() != System.JSONToken.END_OBJECT) {
			if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
				String text = parser.getText();
				if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
					if (text == 'CreditNote Number') {
						CreditNoteNumber = parser.getText();
					} else if (text == 'CreditNote CreationDate') {
						CreditNoteCreationDate = parser.getText();
					} else if (text == 'Response Message') {
						ResponseMessage = parser.getText();
					} else {
						System.debug(LoggingLevel.WARN, 'PNR_CustCreditExpWrapper consuming unrecognized property: '+text);
					//	consumeObject(parser);
					}
				}
			}
		}
        
    }
    /*
{
    "CreditNoteNumber": "600008287",
    "CreditNoteCreationDate": "2020-09-02",
    "ResponseMessage": "SUCCESS:Promotional Credit 600008287 has been saved"
}
*/
    //Dummy Response
    /*public static string getresp(string payId){
        ResponseSAPWrap wrap = new ResponseSAPWrap();
        wrap.status = 'SUCCESS';
        wrap.PaymentId=payId;
        wrap.SAP_CN_Date = String.valueOf(system.today());
        wrap.SAP_CN = '345678';
       return JSON.serialize(wrap);
    } */
    public static ECM_PaymentResponseParser Parser(String json){
        System.JSONParser parser = System.JSON.createParser(json);
		return new ECM_PaymentResponseParser(parser);        
    }
}